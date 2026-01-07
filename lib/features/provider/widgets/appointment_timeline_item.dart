import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/appointment.dart';

class AppointmentTimelineItem extends StatelessWidget {
  final Appointment appointment;

  const AppointmentTimelineItem({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    final endTime = appointment.endTime;
    final service = appointment.service;
    final client = appointment.client;
    final status = appointment.status;

    // Status styling
    final (statusColor, statusText) = _getStatusStyle(status);

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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
            color: statusColor.withAlpha(128),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // Appointment Card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border(
                  left: BorderSide(color: statusColor, width: 4),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        service?.name ?? 'Service',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        client?.displayName ?? 'Client',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
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
        ],
      ),
    );
  }

  (Color, String) _getStatusStyle(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return (Colors.green, 'Confirmé');
      case AppointmentStatus.cancelled:
        return (Colors.red, 'Annulé');
      case AppointmentStatus.pending:
        return (Colors.orange, 'En attente');
      case AppointmentStatus.completed:
        return (Colors.blue, 'Terminé');
    }
  }
}
