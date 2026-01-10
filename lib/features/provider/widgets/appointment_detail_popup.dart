import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/providers/appointments_provider.dart';
import '../../../shared/repositories/impl/appointment_repository_impl.dart';
import 'pet_info_popup.dart';
import '../../../shared/models/pet.dart';
import '../../../shared/repositories/impl/pet_repository_impl.dart';

/// Popup dialog displaying full appointment details with action buttons
class AppointmentDetailPopup extends ConsumerWidget {
  final Appointment appointment;

  const AppointmentDetailPopup({super.key, required this.appointment});

  /// Show the popup as a modal bottom sheet
  static Future<void> show(BuildContext context, Appointment appointment) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AppointmentDetailPopup(appointment: appointment),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = appointment.client;
    final service = appointment.service;
    final status = appointment.status;
    final isCompleted = status == AppointmentStatus.completed;

    // Status styling
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withAlpha(50),
                child: Icon(Icons.calendar_today, color: statusColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service?.name ?? 'Service',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const Divider(height: 32),

          // Date & Time
          _InfoRow(
            icon: Icons.schedule,
            label: 'Date et heure',
            value: DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR')
                .format(appointment.startTime),
          ),
          _InfoRow(
            icon: Icons.timer,
            label: 'Durée',
            value: '${appointment.durationMinutes} minutes',
          ),

          const SizedBox(height: 16),

          // Client Info
          const Text(
            'Client',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.person,
            label: 'Nom',
            value: client?.displayName ?? 'Non spécifié',
          ),
          if (client?.email != null && client!.email.isNotEmpty)
            _InfoRow(
              icon: Icons.email,
              label: 'Email',
              value: client.email,
              onTap: () => _launchEmail(client.email),
            ),
          if (client?.phoneNumber != null)
            _InfoRow(
              icon: Icons.phone,
              label: 'Téléphone',
              value: client!.phoneNumber!,
              onTap: () => _contactClient(client.phoneNumber!),
            ),

          const SizedBox(height: 16),

          // Price
          if (service?.price != null)
            _InfoRow(
              icon: Icons.euro,
              label: 'Prix',
              value: '${service!.price.toStringAsFixed(2)}€',
            ),

          // Notes
          if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(appointment.notes!),
            ),
          ],

          const SizedBox(height: 24),

          // Action Buttons Row 1: Pet Info
          OutlinedButton.icon(
            onPressed: () => _showPetInfo(context),
            icon: const Icon(Icons.pets),
            label: const Text('Infos du chien'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              foregroundColor: Colors.brown,
              side: const BorderSide(color: Colors.brown),
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons Row 2: Done/Undone
          if (status != AppointmentStatus.cancelled)
            SizedBox(
              width: double.infinity,
              child: isCompleted
                  ? OutlinedButton.icon(
                      onPressed: () => _markAsPending(context, ref),
                      icon: const Icon(Icons.undo),
                      label: const Text('Non fait'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => _markAsCompleted(context, ref),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Terminer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Colors.blue; // Prochainement
      case AppointmentStatus.cancelled:
        return Colors.red; // Annulé
      case AppointmentStatus.pending:
        return Colors.blue; // Prochainement
      case AppointmentStatus.completed:
        return Colors.green; // Fait
    }
  }

  Future<void> _showPetInfo(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final container = ProviderScope.containerOf(context);
      final repository = container.read(petRepositoryProvider);
      
      // Fetch user's pets
      final pets = await repository.getUserPets(appointment.clientId);
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss loading

        if (pets.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun animal trouvé pour ce client')),
          );
        } else if (pets.length == 1) {
          // If only one pet, show it directly
          PetInfoPopup.show(context, pets.first);
        } else {
          // If multiple pets, let user choose
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Choisir un animal'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pets.length,
                  itemBuilder: (context, index) {
                    final pet = pets[index];
                    return ListTile(
                      leading: Icon(
                        pet.type == AnimalType.dog ? Icons.pets : Icons.cruelty_free,
                        color: Colors.brown,
                      ),
                      title: Text(pet.name),
                      subtitle: Text(pet.breed),
                      onTap: () {
                        Navigator.of(context).pop();
                        PetInfoPopup.show(context, pet);
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du chargement des animaux')),
        );
      }
    }
  }

  Future<void> _contactClient(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _markAsCompleted(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      await repository.updateStatus(appointment.id, AppointmentStatus.completed);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous marqué comme terminé'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        ref.invalidate(appointmentsProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsPending(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      await repository.updateStatus(appointment.id, AppointmentStatus.confirmed);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous remis en attente'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
        ref.invalidate(appointmentsProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: onTap != null ? Colors.blue : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: onTap != null ? Colors.blue : null,
                  decoration: onTap != null ? TextDecoration.underline : null,
                  decorationColor: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
