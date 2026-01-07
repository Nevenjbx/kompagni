import 'package:flutter/material.dart';
import '../../../shared/models/working_hours.dart';

class DayAvailabilityCard extends StatelessWidget {
  final String dayName;
  final WorkingHours workingHours;
  final ValueChanged<bool> onClosedChanged;
  final ValueChanged<String> onStartTimeChanged;
  final ValueChanged<String> onEndTimeChanged;
  final ValueChanged<String> onBreakStartChanged;
  final ValueChanged<String> onBreakEndChanged;

  const DayAvailabilityCard({
    super.key,
    required this.dayName,
    required this.workingHours,
    required this.onClosedChanged,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    required this.onBreakStartChanged,
    required this.onBreakEndChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Header row with day name and toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: !workingHours.isClosed,
                  onChanged: (val) => onClosedChanged(!val),
                ),
              ],
            ),

            // Time inputs (only if not closed)
            if (!workingHours.isClosed) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: workingHours.startTime,
                      decoration: const InputDecoration(
                        labelText: 'Début (HH:mm)',
                      ),
                      onChanged: onStartTimeChanged,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: workingHours.endTime,
                      decoration: const InputDecoration(
                        labelText: 'Fin (HH:mm)',
                      ),
                      onChanged: onEndTimeChanged,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: workingHours.breakStartTime,
                        decoration: const InputDecoration(
                          labelText: 'Début Pause (optionel)',
                          hintText: '12:00',
                        ),
                        onChanged: onBreakStartChanged,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: workingHours.breakEndTime,
                        decoration: const InputDecoration(
                          labelText: 'Fin Pause',
                          hintText: '13:00',
                        ),
                        onChanged: onBreakEndChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
