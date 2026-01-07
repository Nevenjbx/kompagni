import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyAppointmentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historique des rdv',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        historyAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => Text('Erreur: $error'),
          data: (history) {
            if (history.isEmpty) {
              return const Text(
                'Aucun historique.',
                style: TextStyle(color: Colors.grey),
              );
            }

            final visibleHistory =
                _showAllHistory ? history : history.take(3).toList();

            return Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleHistory.length,
                  itemBuilder: (context, index) {
                    return AppointmentCard(appointment: visibleHistory[index]);
                  },
                ),
                if (history.length > 3)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllHistory = !_showAllHistory;
                      });
                    },
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
