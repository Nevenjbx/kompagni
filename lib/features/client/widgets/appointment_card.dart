import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/appointment.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool isNext;
  final VoidCallback? onTap;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.isNext = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = appointment.status == AppointmentStatus.cancelled;
    // Allow interaction if onTap is provided and not cancelled
    final canInteract = onTap != null && !isCancelled;

    return Card(
      elevation: isNext ? 0 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      color: isNext
          ? Theme.of(context).colorScheme.primaryContainer.withAlpha(76)
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
