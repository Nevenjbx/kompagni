import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/working_hours.dart';
import '../../../shared/providers/provider_profile_provider.dart';

class ManageAvailabilityScreen extends ConsumerStatefulWidget {
  const ManageAvailabilityScreen({super.key});

  @override
  ConsumerState<ManageAvailabilityScreen> createState() =>
      _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState
    extends ConsumerState<ManageAvailabilityScreen> {
  bool _isLoading = false;
  bool _hasLoaded = false;

  // Initialize with default 9-5 MF
  List<WorkingHours> _workingHours = List.generate(7, (index) {
    return WorkingHours(
      dayOfWeek: index,
      startTime: '09:00',
      endTime: '17:00',
      isClosed: index == 0 || index == 6, // Close weekends by default
    );
  });

  static const _dayNames = [
    'Dimanche',
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi'
  ];

  // Display order: Mon(1) ... Sat(6), Sun(0)
  static const _displayOrder = [1, 2, 3, 4, 5, 6, 0];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profileAsync = await ref.read(providerProfileProvider.future);
      if (profileAsync != null && mounted) {
        final fetchedMap = {
          for (var wh in profileAsync.workingHours) wh.dayOfWeek: wh
        };

        setState(() {
          _workingHours = List.generate(7, (index) {
            final existing = fetchedMap[index];
            if (existing != null) {
              return WorkingHours(
                dayOfWeek: index,
                startTime: existing.startTime,
                endTime: existing.endTime,
                isClosed: false,
                breakStartTime: existing.breakStartTime,
                breakEndTime: existing.breakEndTime,
              );
            } else {
              return WorkingHours(
                dayOfWeek: index,
                startTime: '09:00',
                endTime: '17:00',
                isClosed: true,
              );
            }
          });
          _hasLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(providerProfileProvider.notifier)
          .updateWorkingHours(_workingHours);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disponibilités mises à jour !')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateWorkingHours(int index, WorkingHours newValue) {
    setState(() {
      _workingHours[index] = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gérer mes disponibilités')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._displayOrder.map((dayIndex) {
                  final wh =
                      _workingHours.firstWhere((w) => w.dayOfWeek == dayIndex);
                  final listIndex = _workingHours.indexOf(wh);

                  return _DayCard(
                    dayName: _dayNames[dayIndex],
                    workingHours: wh,
                    onClosedChanged: (isClosed) {
                      _updateWorkingHours(
                        listIndex,
                        WorkingHours(
                          dayOfWeek: wh.dayOfWeek,
                          startTime: wh.startTime,
                          endTime: wh.endTime,
                          isClosed: isClosed,
                          breakStartTime: wh.breakStartTime,
                          breakEndTime: wh.breakEndTime,
                        ),
                      );
                    },
                    onStartTimeChanged: (value) {
                      _updateWorkingHours(
                        listIndex,
                        WorkingHours(
                          dayOfWeek: wh.dayOfWeek,
                          startTime: value,
                          endTime: wh.endTime,
                          isClosed: false,
                          breakStartTime: wh.breakStartTime,
                          breakEndTime: wh.breakEndTime,
                        ),
                      );
                    },
                    onEndTimeChanged: (value) {
                      _updateWorkingHours(
                        listIndex,
                        WorkingHours(
                          dayOfWeek: wh.dayOfWeek,
                          startTime: wh.startTime,
                          endTime: value,
                          isClosed: false,
                          breakStartTime: wh.breakStartTime,
                          breakEndTime: wh.breakEndTime,
                        ),
                      );
                    },
                    onBreakStartChanged: (value) {
                      _updateWorkingHours(
                        listIndex,
                        WorkingHours(
                          dayOfWeek: wh.dayOfWeek,
                          startTime: wh.startTime,
                          endTime: wh.endTime,
                          isClosed: false,
                          breakStartTime: value,
                          breakEndTime: wh.breakEndTime,
                        ),
                      );
                    },
                    onBreakEndChanged: (value) {
                      _updateWorkingHours(
                        listIndex,
                        WorkingHours(
                          dayOfWeek: wh.dayOfWeek,
                          startTime: wh.startTime,
                          endTime: wh.endTime,
                          isClosed: false,
                          breakStartTime: wh.breakStartTime,
                          breakEndTime: value,
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
    );
  }
}

/// Card widget for a single day
class _DayCard extends StatelessWidget {
  final String dayName;
  final WorkingHours workingHours;
  final ValueChanged<bool> onClosedChanged;
  final ValueChanged<String> onStartTimeChanged;
  final ValueChanged<String> onEndTimeChanged;
  final ValueChanged<String> onBreakStartChanged;
  final ValueChanged<String> onBreakEndChanged;

  const _DayCard({
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
