import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/appointments_provider.dart';

class TimeSlotsGrid extends ConsumerWidget {
  final String providerId;
  final String serviceId;
  final DateTime selectedDate;
  final String? selectedSlot;
  final void Function(String?) onSlotSelected;

  const TimeSlotsGrid({
    super.key,
    required this.providerId,
    required this.serviceId,
    required this.selectedDate,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsParams = AvailableSlotsParams(
      providerId: providerId,
      serviceId: serviceId,
      date: selectedDate,
    );
    final slotsAsync = ref.watch(availableSlotsProvider(slotsParams));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Créneaux disponibles :',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        slotsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('Erreur: $error'),
          data: (slots) {
            if (slots.isEmpty) {
              return const Text('Aucun créneau disponible ce jour.');
            }

            return Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: slots.map((slotIso) {
                final dt = DateTime.parse(slotIso);
                final timeStr = DateFormat('HH:mm').format(dt);
                final isSelected = selectedSlot == slotIso;

                return ChoiceChip(
                  label: Text(timeStr),
                  selected: isSelected,
                  onSelected: (selected) {
                    onSlotSelected(selected ? slotIso : null);
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
