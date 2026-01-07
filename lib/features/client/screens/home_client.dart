import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/models/provider.dart' as models;
import '../../../shared/providers/appointments_provider.dart';
import '../../../shared/providers/favorites_provider.dart';
import '../../../shared/providers/pets_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import 'add_pet_screen.dart';
import 'provider_list_screen.dart';
import 'provider_details_screen.dart';
import 'client_profile_screen.dart';

class HomeClientScreen extends ConsumerStatefulWidget {
  const HomeClientScreen({super.key});

  @override
  ConsumerState<HomeClientScreen> createState() => _HomeClientScreenState();
}

class _HomeClientScreenState extends ConsumerState<HomeClientScreen> {
  bool _showAllHistory = false;

  @override
  void initState() {
    super.initState();
    _checkPets();
  }

  Future<void> _checkPets() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    final hasPets = ref.read(hasPetsProvider);
    hasPets.whenData((hasAny) {
      if (!hasAny && mounted) {
        _showAddPetDialog();
      }
    });
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

  Future<void> _refresh() async {
    ref.invalidate(appointmentsProvider);
    ref.invalidate(favoritesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final String displayName = user?.userMetadata?['first_name'] ??
        user?.userMetadata?['full_name'] ??
        'Compagnon';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
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
                        Navigator.of(context)
                            .push(
                          MaterialPageRoute(
                            builder: (context) => const ProviderListScreen(),
                          ),
                        )
                            .then((_) => _refresh());
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
    final upcomingAsync = ref.watch(upcomingAppointmentsProvider);

    return upcomingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text(
        'Erreur: $error',
        style: const TextStyle(color: Colors.red),
      ),
      data: (upcoming) {
        if (upcoming.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Aucun rendez vous réservé',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: upcoming.length,
          itemBuilder: (context, index) {
            return _AppointmentCard(
              appointment: upcoming[index],
              isNext: true,
              onTap: () => _showAppointmentDetails(upcoming[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildHistorySection() {
    final historyAsync = ref.watch(historyAppointmentsProvider);

    return historyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => Text('Erreur: $error'),
      data: (history) {
        if (history.isEmpty) {
          return const Text(
            'Aucun historique.',
            style: TextStyle(color: Colors.grey),
          );
        }

        final visibleHistory =
            _showAllHistory ? history : history.take(3).toList();

        return Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleHistory.length,
              itemBuilder: (context, index) {
                return _AppointmentCard(appointment: visibleHistory[index]);
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
      await ref.read(appointmentsProvider.notifier).cancelAppointment(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rendez-vous annulé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showAppointmentDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Détails du rendez-vous'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service: ${appointment.service?.name ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Prestataire: ${appointment.provider?.businessName ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text(
              'Date: ${DateFormat('dd/MM/yyyy').format(appointment.startTime)}',
            ),
            Text(
              'Heure: ${DateFormat('HH:mm').format(appointment.startTime)}',
            ),
            const SizedBox(height: 8),
            if (appointment.provider != null)
              Text(
                'Adresse: ${appointment.provider!.address}, ${appointment.provider!.city}',
              ),
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
              _cancelAppointment(appointment.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Annuler le rendez-vous'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesSection() {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mes experts',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        favoritesAsync.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const Text(
            'Erreur chargement favoris',
            style: TextStyle(color: Colors.red),
          ),
          data: (favorites) {
            if (favorites.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.3),
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
              );
            }

            return SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  return _FavoriteProviderCard(
                    provider: favorites[index],
                    onTap: () {
                      Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ProviderDetailsScreen(provider: favorites[index]),
                        ),
                      )
                          .then((_) => _refresh());
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Extracted widget for appointment card
class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool isNext;
  final VoidCallback? onTap;

  const _AppointmentCard({
    required this.appointment,
    this.isNext = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = appointment.status == AppointmentStatus.cancelled;
    final canInteract = isNext && !isCancelled;

    return Card(
      elevation: isNext ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      color: isNext
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : Theme.of(context).cardColor,
      child: InkWell(
        onTap: canInteract ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          title: Text(
            appointment.service?.name ?? 'Service',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appointment.provider?.businessName ?? 'Prestataire'),
              Text(DateFormat('dd/MM/yyyy HH:mm').format(appointment.startTime)),
              if (isCancelled)
                const Text(
                  'ANNULÉ',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          leading: CircleAvatar(
            backgroundColor: isNext
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.calendar_today,
              color: isNext
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Extracted widget for favorite provider card
class _FavoriteProviderCard extends StatelessWidget {
  final models.Provider provider;
  final VoidCallback onTap;

  const _FavoriteProviderCard({
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
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
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
