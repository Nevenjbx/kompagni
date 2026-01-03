import 'package:flutter/material.dart';
import '../../../shared/models/provider.dart';
import '../../provider/services/provider_service.dart';
import '../../auth/services/auth_service.dart';
import 'provider_details_screen.dart';
import 'my_appointments_screen.dart';
import 'my_pets_screen.dart';
import 'add_pet_screen.dart';
import '../../client/services/pet_service.dart';

class HomeClientScreen extends StatefulWidget {
  const HomeClientScreen({super.key});

  @override
  State<HomeClientScreen> createState() => _HomeClientScreenState();
}

class _HomeClientScreenState extends State<HomeClientScreen> {
  final ProviderService _providerService = ProviderService();
  late Future<List<Provider>> _providersFuture;

  @override
  void initState() {
    super.initState();
    _providersFuture = _providerService.searchProviders();
    _checkPets();
  }

  Future<void> _checkPets() async {
    // Small delay to allow initial build
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final pets = await PetService().getMyPets();
      if (pets.isEmpty && mounted) {
        _showAddPetDialog();
      }
    } catch (e) {
      // Fail silently for onboarding check
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

  Future<void> _signOut() async {
    await AuthService().signOut();
    // Navigation handled by GoRouter stream
    if (mounted) {
       // Optional: show snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prestataires Kompagni'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pets),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MyPetsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MyAppointmentsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _providersFuture = _providerService.searchProviders();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: FutureBuilder<List<Provider>>(
        future: _providersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur : ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _providersFuture = _providerService.searchProviders();
                      });
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun prestataire trouvé.'));
          }

          final providers = snapshot.data!;
          return ListView.builder(
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(provider.businessName.isNotEmpty
                      ? provider.businessName[0].toUpperCase()
                      : '?'),
                ),
                title: Text(provider.businessName),
                subtitle: Text('${provider.city} • ${provider.description}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProviderDetailsScreen(provider: provider),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
