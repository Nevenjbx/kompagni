import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/services/auth_service.dart';
import '../services/appointment_service.dart';
import '../services/pet_service.dart';
import 'add_pet_screen.dart';
import 'provider_list_screen.dart';
import 'provider_details_screen.dart';
import '../../client/services/user_service.dart';
import '../../../shared/models/provider.dart';
import 'client_profile_screen.dart';

class HomeClientScreen extends StatefulWidget {
  const HomeClientScreen({super.key});

  @override
  State<HomeClientScreen> createState() => _HomeClientScreenState();
}

class _HomeClientScreenState extends State<HomeClientScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final UserService _userService = UserService();
  late Future<List<dynamic>> _appointmentsFuture;
  late Future<List<Provider>> _favoritesFuture;
  bool _showAllHistory = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = AuthService().currentUser;
    _refreshAppointments();
    _checkPets();
  }

  void _refreshAppointments() {
    setState(() {
      _appointmentsFuture = _appointmentService.getMyAppointments();
      _favoritesFuture = _userService.getFavorites();
    });
  }

  Future<void> _checkPets() async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final pets = await PetService().getMyPets();
      if (pets.isEmpty && mounted) {
        _showAddPetDialog();
      }
    } catch (e) {
      // Fail silently
    }
  }

  void _showAddPetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Bienvenue sur Kompagni !'),
        content: const Text('Commençons par créer le profil de votre compagnon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddPetScreen()),
              );
            },
            child: const Text('Ajouter maintenant'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Attempt to get name from metadata, fallback to email or 'Compagnon'
    final String displayName = _user?.userMetadata?['first_name'] ?? 
                             _user?.userMetadata?['full_name'] ?? 
                             'Compagnon';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refreshAppointments(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Header
                  _buildHeader(displayName),
                  const SizedBox(height: 32),

                  // My Experts (Favorites)
                  _buildFavoritesSection(),
                  const SizedBox(height: 32),

                  // Next Appointment
                  Text(
                    'Prochain rdv',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildNextAppointmentSection(),
                  const SizedBox(height: 32),

                  // Main Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProviderListScreen(),
                          ),
                        ).then((_) => _refreshAppointments());
                      },
                      child: const Text('Prendre rendez-vous'),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Appointment History
                   Text(
                    'Historique des rdv',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildHistorySection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Bonjour $name',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ClientProfileScreen(),
              ),
            );
          },
          icon: const CircleAvatar(
             child: Icon(Icons.person),
          ),
        ),
      ],
    );
  }

  Widget _buildNextAppointmentSection() {
    return FutureBuilder<List<dynamic>>(
      future: _appointmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red));
        }
        
        final appointments = snapshot.data ?? [];
        final now = DateTime.now();
        
        // Filter for future and not cancelled
        final upcoming = appointments.where((appt) {
          final start = DateTime.parse(appt['startTime']);
          return start.isAfter(now) && appt['status'] != 'CANCELLED';
        }).toList();

        // Sort by date
        upcoming.sort((a, b) => DateTime.parse(a['startTime']).compareTo(DateTime.parse(b['startTime'])));

        if (upcoming.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Aucun rendez vous réservé',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: upcoming.length,
          itemBuilder: (context, index) {
            return _buildAppointmentCard(upcoming[index], isNext: true);
          },
        );
      },
    );
  }

  Widget _buildHistorySection() {
     return FutureBuilder<List<dynamic>>(
      future: _appointmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // Loading already shown in next appt section usually
        }
        
        final appointments = snapshot.data ?? [];
        final now = DateTime.now();
        
        // Filter for past OR cancelled
        final history = appointments.where((appt) {
          final start = DateTime.parse(appt['startTime']);
          return start.isBefore(now) || appt['status'] == 'CANCELLED';
        }).toList();

        // Sort by date desc
        history.sort((a, b) => DateTime.parse(b['startTime']).compareTo(DateTime.parse(a['startTime'])));

        if (history.isEmpty) {
           return const Text('Aucun historique.', style: TextStyle(color: Colors.grey));
        }

        final visibleHistory = _showAllHistory ? history : history.take(3).toList();

        return Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleHistory.length,
              itemBuilder: (context, index) {
                return _buildAppointmentCard(visibleHistory[index]);
              },
            ),
            if (history.length > 3)
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAllHistory = !_showAllHistory;
                  });
                },
                child: Text(_showAllHistory ? 'Voir moins' : 'Voir plus'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _cancelAppointment(String id) async {
    try {
      await _appointmentService.cancelAppointment(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rendez-vous annulé')),
        );
      }
      _refreshAppointments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showAppointmentDetails(dynamic appt) {
    final provider = appt['provider'];
    final service = appt['service'];
    final startTime = DateTime.parse(appt['startTime']);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Détails du rendez-vous'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${service['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Prestataire: ${provider['businessName']}'),
            const SizedBox(height: 8),
            Text('Date: ${DateFormat('dd/MM/yyyy').format(startTime)}'),
            Text('Heure: ${DateFormat('HH:mm').format(startTime)}'),
            const SizedBox(height: 8),
            Text('Adresse: ${provider['address'] ?? ''}, ${provider['city']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _cancelAppointment(appt['id']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Annuler le rendez-vous'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic appt, {bool isNext = false}) {
    final provider = appt['provider'];
    final service = appt['service'];
    final startTime = DateTime.parse(appt['startTime']);
    final isCancelled = appt['status'] == 'CANCELLED';

    // Enable interaction only for upcoming, non-cancelled appointments
    final canInteract = isNext && !isCancelled;

    return Card(
      elevation: isNext ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      color: isNext ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : Theme.of(context).cardColor,
      child: InkWell(
        onTap: canInteract ? () => _showAppointmentDetails(appt) : null,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          title: Text(
            service['name'],
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(provider['businessName']),
              Text(DateFormat('dd/MM/yyyy HH:mm').format(startTime)),
              if (isCancelled)
                const Text('ANNULÉ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          leading: CircleAvatar(
             backgroundColor: isNext ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
             child: Icon(Icons.calendar_today, color: isNext ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
  Widget _buildFavoritesSection() {
    return FutureBuilder<List<Provider>>(
      future: _favoritesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
           return const Text('Erreur chargement favoris', style: TextStyle(color: Colors.red));
        }

        final favorites = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mes experts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (favorites.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Pas encore de favoris',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final provider = favorites[index];
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      child: Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                             Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProviderDetailsScreen(provider: provider),
                              ),
                            ).then((_) => _refreshAppointments());
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Text(
                                    provider.businessName.isNotEmpty
                                        ? provider.businessName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  provider.businessName,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  provider.city,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
