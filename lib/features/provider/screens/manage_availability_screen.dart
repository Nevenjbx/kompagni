import 'package:flutter/material.dart';
import '../../../shared/models/working_hours.dart';
import '../services/provider_service.dart';

class ManageAvailabilityScreen extends StatefulWidget {
  const ManageAvailabilityScreen({super.key});

  @override
  State<ManageAvailabilityScreen> createState() => _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  final _providerService = ProviderService();
  bool _isLoading = false;

  // Initialize with default 9-5 MF
  // Initialize with default 9-5 MF
  List<WorkingHours> _workingHours = List.generate(7, (index) {
    return WorkingHours(
      dayOfWeek: index, // 0=Sun, 1=Mon, ..., 6=Sat.
      startTime: '09:00',
      endTime: '17:00',
      isClosed: index == 0 || index == 6, // Close weekends by default
    );
  });

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final provider = await _providerService.getMyProfile();
      if (mounted) {
        setState(() {
          // Merge fetched hours into default structure
          // The backend might return only open days or all days depending on implementation.
          // Usually "updateWorkingHours" sends only open days.
          // We iterate over our default 7 days list and update if we find a match.
          
          // First, reset all to closed if we assume backend returns *only* open days?
          // Or backend returns all?
          // ProviderService.updateWorkingHours sends ".where((wh) => !wh.isClosed)".
          // So backend likely stores only non-closed hours.
          // Therefore, any day NOT in the response should be considered closed.
          
          // Reset all to closed first to be safe, or just update matches.
          // Better approach:
          // 1. Create a map of fetched hours by dayOfWeek.
          // 2. Iterate 0..6. If in map, use it (isClosed=false). If not, use default (isClosed=true).
          
          final fetchedMap = {
            for (var wh in provider.workingHours) wh.dayOfWeek: wh
          };
          
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
               // Not in DB -> Closed
               return WorkingHours(
                 dayOfWeek: index,
                 startTime: '09:00',
                 endTime: '17:00',
                 isClosed: true,
               );
             }
          });
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
      await _providerService.updateWorkingHours(_workingHours);
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

  @override
  Widget build(BuildContext context) {
    // Reorder for UI: Mon(1) ... Sat(6), Sun(0)
    final displayOrder = [1, 2, 3, 4, 5, 6, 0];
    final dayNames = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];

    return Scaffold(
      appBar: AppBar(title: const Text('Gérer mes disponibilités')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...displayOrder.map((dayIndex) {
                  final wh = _workingHours.firstWhere((w) => w.dayOfWeek == dayIndex);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(dayNames[dayIndex], style: const TextStyle(fontWeight: FontWeight.bold)),
                              Switch(
                                value: !wh.isClosed,
                                onChanged: (val) {
                                  setState(() {
                                    final idx = _workingHours.indexOf(wh);
                                    _workingHours[idx] = WorkingHours(
                                      dayOfWeek: wh.dayOfWeek,
                                      startTime: wh.startTime,
                                      endTime: wh.endTime,
                                      isClosed: !val,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                          if (!wh.isClosed)
                             Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: wh.startTime,
                                    decoration: const InputDecoration(labelText: 'Début (HH:mm)'),
                                    onChanged: (v) {
                                       final idx = _workingHours.indexOf(wh);
                                       _workingHours[idx] = WorkingHours(dayOfWeek: wh.dayOfWeek, startTime: v, endTime: wh.endTime, isClosed: false);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: wh.endTime,
                                    decoration: const InputDecoration(labelText: 'Fin (HH:mm)'),
                                    onChanged: (v) {
                                       final idx = _workingHours.indexOf(wh);
                                       _workingHours[idx] = WorkingHours(dayOfWeek: wh.dayOfWeek, startTime: wh.startTime, endTime: v, isClosed: false);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          if (!wh.isClosed)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: wh.breakStartTime,
                                      decoration: const InputDecoration(labelText: 'Début Pause (optionel)', hintText: '12:00'),
                                      onChanged: (v) {
                                         final idx = _workingHours.indexOf(wh);
                                         _workingHours[idx] = WorkingHours(
                                            dayOfWeek: wh.dayOfWeek,
                                            startTime: wh.startTime,
                                            endTime: wh.endTime,
                                            isClosed: false,
                                            breakStartTime: v,
                                            breakEndTime: wh.breakEndTime
                                         );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: wh.breakEndTime,
                                      decoration: const InputDecoration(labelText: 'Fin Pause', hintText: '13:00'),
                                      onChanged: (v) {
                                         final idx = _workingHours.indexOf(wh);
                                         _workingHours[idx] = WorkingHours(
                                            dayOfWeek: wh.dayOfWeek,
                                            startTime: wh.startTime,
                                            endTime: wh.endTime,
                                            isClosed: false,
                                            breakStartTime: wh.breakStartTime,
                                            breakEndTime: v
                                         );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
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
