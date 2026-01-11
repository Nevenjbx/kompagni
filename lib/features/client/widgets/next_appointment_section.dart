import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/providers/appointments_provider.dart';
import 'appointment_card.dart';

class NextAppointmentSection extends ConsumerWidget {
  final VoidCallback onRefresh;

  const NextAppointmentSection({super.key, required this.onRefresh});

  Future<void> _cancelAppointment(
      BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(appointmentsProvider.notifier).cancelAppointment(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rendez-vous annulé')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showAppointmentDetails(
      BuildContext context, WidgetRef ref, Appointment appointment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Détails du rendez-vous', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              context,
              Icons.content_cut,
              'Service',
              appointment.service?.name ?? 'N/A',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.store,
              'Prestataire',
              appointment.provider?.businessName ?? 'N/A',
            ),
             const SizedBox(height: 12),
            if (appointment.pet != null) ...[
              _buildDetailRow(
                context,
                Icons.pets,
                'Pour',
                appointment.pet!.name,
              ),
              const SizedBox(height: 12),
            ],
            _buildDetailRow(
              context,
              Icons.event,
              'Date et Heure',
              '${DateFormat('dd/MM/yyyy').format(appointment.startTime)} à ${DateFormat('HH:mm').format(appointment.startTime)}',
            ),
            if (appointment.provider != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                Icons.location_on,
                'Adresse',
                '${appointment.provider!.address}, ${appointment.provider!.city}',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.of(ctx).pop();
              _cancelAppointment(context, ref, appointment.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
            ),
            child: const Text('Annuler le rendez-vous'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingAppointmentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prochain rdv',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        upcomingAsync.when(
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
                      .withAlpha(76),
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
                return AppointmentCard(
                  appointment: upcoming[index],
                  isNext: true,
                  onTap: () => _showAppointmentDetails(
                      context, ref, upcoming[index]),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
