import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/appointment.dart';
import 'appointment_detail_popup.dart';

class AppointmentTimelineItem extends StatelessWidget {
  final Appointment appointment;

  const AppointmentTimelineItem({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final endTime = appointment.endTime;
    final service = appointment.service;
    final client = appointment.client;
    final status = appointment.status;
    final isCompleted = status == AppointmentStatus.completed;

    // Status styling
    final (statusColor, statusText) = _getStatusStyle(status);
    
    // Card background color: grey for completed, white for others
    final cardColor = isCompleted ? Colors.grey.shade100 : Colors.white;
    final textColor = isCompleted ? Colors.grey.shade600 : Colors.black;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(
                  DateFormat('HH:mm').format(appointment.startTime),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isCompleted ? Colors.grey.shade500 : null,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(endTime),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),

          // Timeline Line
          Container(
            width: 2,
            height: 80,
            color: isCompleted ? Colors.grey.shade300 : statusColor.withAlpha(128),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // Appointment Card with onTap
          Expanded(
            child: GestureDetector(
              onTap: () => AppointmentDetailPopup.show(context, appointment),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isCompleted 
                      ? null 
                      : [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                  border: Border(
                    left: BorderSide(
                      color: isCompleted ? Colors.green : statusColor, 
                      width: 4,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            service?.name ?? 'Service',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                              decoration: isCompleted 
                                  ? TextDecoration.lineThrough 
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted 
                                ? Colors.green.withAlpha(25)
                                : statusColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isCompleted) ...[
                                const Icon(
                                  Icons.check,
                                  size: 10,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 2),
                              ],
                              Text(
                                isCompleted ? 'Done' : statusText,
                                style: TextStyle(
                                  color: isCompleted ? Colors.green : statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            client?.displayName ?? 'Client',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        // Tap indicator
                        Icon(Icons.chevron_right, 
                             size: 18, 
                             color: Colors.grey.shade400),
                      ],
                    ),
                    if (service?.price != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${service!.price}€',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _getStatusStyle(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return (Colors.blue, 'Prochainement');
      case AppointmentStatus.cancelled:
        return (Colors.red, 'Annulé');
      case AppointmentStatus.pending:
        return (Colors.blue, 'Prochainement');
      case AppointmentStatus.completed:
        return (Colors.green, 'Fait');
    }
  }
}
