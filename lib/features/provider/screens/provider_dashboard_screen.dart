import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../client/services/appointment_service.dart';
import '../../auth/services/auth_service.dart';
import '../services/provider_service.dart';
import '../../../shared/models/provider.dart';
import '../../../shared/models/working_hours.dart';
import '../../auth/screens/login_screen.dart';
import 'add_service_screen.dart';
import 'manage_availability_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String _viewMode = 'DAY'; // 'DAY' or 'WEEK'
  
  final AppointmentService _appointmentService = AppointmentService();
  late Future<List<dynamic>> _appointmentsFuture;

  // Cache profile to avoid flickering title
  late Future<Provider> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _appointmentsFuture = _appointmentService.getMyAppointments();
      _profileFuture = ProviderService().getMyProfile();
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
       Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  List<dynamic> _filterAppointments(List<dynamic> allAppointments) {
    if (_viewMode == 'WEEK') {
      // Show appointments for the week of _focusedDay
      // Start of week (Monday)
      final startOfWeek = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      // Normalize to remove time
      final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final end = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);

      return allAppointments.where((appt) {
        final dt = DateTime.parse(appt['startTime']);
        return dt.isAfter(start) && dt.isBefore(end);
      }).toList();
    } else {
      // 'DAY' - Show only for _selectedDay
      return allAppointments.where((appt) {
        final dt = DateTime.parse(appt['startTime']);
        return isSameDay(dt, _selectedDay);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Provider>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        // Default title if loading
        String title = 'Bienvenue';
        if (profileSnapshot.hasData) {
          title = 'Bienvenue ${profileSnapshot.data!.businessName}';
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _signOut(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TOP ACTIONS ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ManageAvailabilityScreen()),
                        );
                      },
                      icon: const Icon(Icons.schedule),
                      label: const Text('Gérer mes disponibilités'),
                    ),
                  ),
                ),

                const Divider(),
                
                // --- SERVICES ---
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Mes Services',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                
                if (profileSnapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (profileSnapshot.hasData)
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      // +1 for the "Add" card
                      itemCount: profileSnapshot.data!.services.length + 1,
                      itemBuilder: (context, index) {
                        // Render "Add Card" at the end
                        if (index == profileSnapshot.data!.services.length) {
                          return Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              color: Colors.blue.shade50,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: InkWell(
                                onTap: () {
                                   Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const AddServiceScreen()),
                                  ).then((_) => _loadData());
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_circle, size: 40, color: Colors.blue),
                                    SizedBox(height: 8),
                                    Text('Ajouter', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        final service = profileSnapshot.data!.services[index];
                        return Container(
                          width: 140,
                          margin: const EdgeInsets.only(right: 12),
                          child: Card(
                            elevation: 4,
                            shadowColor: Colors.black26,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.cut, color: Colors.blue, size: 20),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${service.price}€ • ${service.duration} min',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const Divider(),

                // --- CALENDAR & APPOINTMENTS ---
                 Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      const Text(
                        'Vos Rendez-vous',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      // Toggle View
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'DAY', label: Text('Jour')),
                          ButtonSegment(value: 'WEEK', label: Text('Semaine')),
                        ],
                        selected: {_viewMode},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _viewMode = newSelection.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                TableCalendar(
                  firstDay: DateTime.utc(2023, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.week,
                  startingDayOfWeek: StartingDayOfWeek.monday, // Start on Monday
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      if (!profileSnapshot.hasData) return null;
                      
                      final workingHours = profileSnapshot.data!.workingHours;
                      // 1=Mon...7=Sun -> 0=Sun...6=Sat
                      final dayIndex = day.weekday % 7; 
                      
                      final wh = workingHours.firstWhere(
                        (element) => element.dayOfWeek == dayIndex, 
                        orElse: () => WorkingHours(dayOfWeek: dayIndex, startTime: '', endTime: '', isClosed: true)
                      );
                      
                      final isWorking = !wh.isClosed;
                      
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isWorking ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isWorking ? Colors.green.shade900 : Colors.grey.shade700,
                          ),
                        ),
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                       final workingHours = profileSnapshot.hasData ? profileSnapshot.data!.workingHours : <WorkingHours>[];
                       final dayIndex = day.weekday % 7;
                       final wh = workingHours.firstWhere(
                        (element) => element.dayOfWeek == dayIndex, 
                        orElse: () => WorkingHours(dayOfWeek: dayIndex, startTime: '', endTime: '', isClosed: true)
                      );
                      final isWorking = !wh.isClosed;

                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isWorking ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                       // Same logic but with a border maybe? 
                       // Or just let selected override it if selected.
                       // For now simplicity:
                       return Container(
                        margin: const EdgeInsets.all(4.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                         child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.blue),
                        ),
                       );
                    }
                  ),
                ),

                const SizedBox(height: 8),

                FutureBuilder<List<dynamic>>(
                  future: _appointmentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Erreur: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Padding(
                         padding: EdgeInsets.all(32.0),
                         child: Text('Aucun rendez-vous.'),
                      ));
                    }

                    final allAppts = snapshot.data!;
                    final filteredAppts = _filterAppointments(allAppts);

                    if (filteredAppts.isEmpty) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Aucun rendez-vous pour cette période.'),
                      ));
                    }

                    // Sort by time
                    filteredAppts.sort((a, b) => a['startTime'].compareTo(b['startTime']));

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredAppts.length,
                      itemBuilder: (context, index) {
                        final appt = filteredAppts[index];
                        final client = appt['client'];
                        final service = appt['service'];
                        final startTime = DateTime.parse(appt['startTime']);

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                               backgroundColor: Colors.deepPurple.shade50,
                               child: Text(
                                 DateFormat('HH:mm').format(startTime),
                                 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                               )
                            ),
                            title: Text(client['name'] ?? client['email'] ?? 'Client'),
                            subtitle: Text(service['name'] ?? 'Service'),
                            trailing: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               decoration: BoxDecoration(
                                 color: appt['status'] == 'CONFIRMED' ? Colors.green.shade100 : Colors.orange.shade100,
                                 borderRadius: BorderRadius.circular(8)
                               ),
                               child: Text(
                                 appt['status'],
                                 style: TextStyle(
                                   color: appt['status'] == 'CONFIRMED' ? Colors.green.shade800 : Colors.orange.shade800,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 12
                                 ),
                               ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
