import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/providers/appointments_provider.dart';
import 'appointment_card.dart';

class AppointmentHistorySection extends ConsumerStatefulWidget {
  const AppointmentHistorySection({super.key});

  @override
  ConsumerState<AppointmentHistorySection> createState() =>
      _AppointmentHistorySectionState();
}

class _AppointmentHistorySectionState
    extends ConsumerState<AppointmentHistorySection> {
  bool _showAllHistory = false;

  void _showAppointmentDetails(BuildContext context, Appointment appointment) {
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
                Icons.history,
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
            _buildDetailRow(context, Icons.content_cut, 'Service', appointment.service?.name ?? 'N/A'),
            const SizedBox(height: 12),
            _buildDetailRow(context, Icons.store, 'Prestataire', appointment.provider?.businessName ?? 'N/A'),
            const SizedBox(height: 12),
            if (appointment.pet != null) ...[
              _buildDetailRow(context, Icons.pets, 'Pour', appointment.pet!.name),
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
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.check_circle,
              'Statut',
              appointment.status.displayName,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
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
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyAppointmentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Historique des rdv', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        historyAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => Text('Erreur: $error'),
          data: (history) {
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
                    final appointment = visibleHistory[index];
                    return AppointmentCard(
                      appointment: appointment,
                      onTap: () => _showAppointmentDetails(context, appointment),
                    );
                  },
                ),
                if (history.length > 3)
                  TextButton(
                    onPressed: () => setState(() => _showAllHistory = !_showAllHistory),
                    child: Text(_showAllHistory ? 'Voir moins' : 'Voir plus'),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
