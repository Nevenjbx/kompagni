import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/working_hours.dart';

class CalendarSection extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<WorkingHours> workingHours;
  final void Function(DateTime, DateTime) onDaySelected;

  const CalendarSection({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.workingHours,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Agenda du jour',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('EEE d MMM', 'fr_FR')
                    .format(selectedDay)
                    .replaceFirstMapped(
                      RegExp(r'^\w'),
                      (match) => match.group(0)!.toUpperCase(),
                    ),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        TableCalendar(
          firstDay: DateTime.utc(2023, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDay,
          calendarFormat: CalendarFormat.week,
          startingDayOfWeek: StartingDayOfWeek.monday,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          calendarStyle: const CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
