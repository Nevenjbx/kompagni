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
              _cancelAppointment(context, ref, appointment.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Annuler le rendez-vous'),
          ),
        ],
      ),
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
