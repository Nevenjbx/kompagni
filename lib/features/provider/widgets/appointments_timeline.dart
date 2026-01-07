import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/providers/appointments_provider.dart';
import 'appointment_timeline_item.dart';

class AppointmentsTimeline extends ConsumerWidget {
  final DateTime selectedDay;
  final List<Appointment> Function(List<Appointment>) filterAppointments;

  const AppointmentsTimeline({
    super.key,
    required this.selectedDay,
    required this.filterAppointments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return appointmentsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(child: Text('Erreur: $error')),
      data: (allAppointments) {
        final filtered = filterAppointments(allAppointments);

        if (filtered.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Icon(Icons.event_available, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Aucun rendez-vous prévu.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        // Sort by time
        filtered.sort((a, b) => a.startTime.compareTo(b.startTime));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return AppointmentTimelineItem(appointment: filtered[index]);
          },
        );
      },
    );
  }
}
