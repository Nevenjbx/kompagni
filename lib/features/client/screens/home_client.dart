import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/appointments_provider.dart';
import '../../../shared/providers/favorites_provider.dart';
import '../../../shared/providers/pets_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'add_pet_screen.dart';
import '../widgets/home_header.dart';
import '../widgets/favorites_section.dart';
import '../widgets/next_appointment_section.dart';
import '../widgets/book_appointment_button.dart';
import '../widgets/appointment_history_section.dart';

class HomeClientScreen extends ConsumerStatefulWidget {
  const HomeClientScreen({super.key});

  @override
  ConsumerState<HomeClientScreen> createState() => _HomeClientScreenState();
}

class _HomeClientScreenState extends ConsumerState<HomeClientScreen> {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.brown.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.pets, size: 48, color: Colors.brown),
        ),
        title: const Text(
          'Bienvenue sur Kompagni !',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Pour pouvoir prendre rendez-vous avec nos experts, '
          'veuillez d\'abord créer le profil de votre compagnon.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Plus tard'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddPetScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter mon animal'),
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
                  HomeHeader(displayName: displayName),
                  const SizedBox(height: 32),

                  // My Experts (Favorites)
                  FavoritesSection(onRefresh: _refresh),
                  const SizedBox(height: 32),

                  // Next Appointment
                  NextAppointmentSection(onRefresh: _refresh),
                  const SizedBox(height: 32),

                  // Main Button
                  BookAppointmentButton(onRefresh: _refresh),
                  const SizedBox(height: 32),

                  // Appointment History
                  const AppointmentHistorySection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
