import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../client/services/appointment_service.dart';
import '../../auth/services/auth_service.dart';
import '../services/provider_service.dart';
import '../../../shared/models/provider.dart';
import '../../../shared/models/working_hours.dart';
import 'add_service_screen.dart';
import 'edit_account_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  
  final AppointmentService _appointmentService = AppointmentService();
  late Future<List<dynamic>> _appointmentsFuture;

  // Cache profile to avoid flickering title
  late Future<Provider> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Retry logic to handle race conditions during partial signups
  Future<Provider> _loadProfileWithRetry({int retries = 20}) async {
    for (int i = 0; i < retries; i++) {
        try {
          return await ProviderService().getMyProfile();
        } catch (e) {
          if (i == retries - 1) rethrow; // If last retry fails, throw error
          await Future.delayed(const Duration(milliseconds: 200));
        }
    }
    throw Exception('Timeout retrieving profile');
  }

  void _loadData() {
    setState(() {
      _appointmentsFuture = _appointmentService.getMyAppointments();
      _profileFuture = _loadProfileWithRetry();
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthService().signOut();
    // Navigation handled by GoRouter stream
    if (context.mounted) {
       // Optional: show snackbar
    }
  }

  List<dynamic> _filterAppointmentsForSelectedDay(List<dynamic> allAppointments) {
    return allAppointments.where((appt) {
      final dt = DateTime.parse(appt['startTime']);
      return isSameDay(dt, _selectedDay);
    }).toList();
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
            title: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                    child: profileSnapshot.connectionState == ConnectionState.waiting 
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: () {
                             if (!profileSnapshot.hasData) return;
                             Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => EditAccountScreen(provider: profileSnapshot.data!)),
                            ).then((result) {
                               if (result == true) _loadData();
                            });
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Éditer mon compte'),
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
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => AddServiceScreen(service: service)),
                                ).then((_) => _loadData());
                              },
                              borderRadius: BorderRadius.circular(16),
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
                                          // Simple icon based on name or just default
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Agenda du jour',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                         DateFormat('EEE d MMM', 'fr_FR').format(_selectedDay).replaceFirstMapped(RegExp(r'^\w'), (match) => match.group(0)!.toUpperCase()),
                         style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                TableCalendar(
                  firstDay: DateTime.utc(2023, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.week, // Force Week strip
                  startingDayOfWeek: StartingDayOfWeek.monday,
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
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                       if (!profileSnapshot.hasData) return null;
                       // We could add dots here if we pre-fetched allappointments and mapped them to days.
                       // For now, let's keep it simple or strictly follow "working day" indication logic.
                       final workingHours = profileSnapshot.data!.workingHours;
                       final dayIndex = day.weekday % 7; 
                       final wh = workingHours.firstWhere(
                        (element) => element.dayOfWeek == dayIndex, 
                        orElse: () => WorkingHours(dayOfWeek: dayIndex, startTime: '', endTime: '', isClosed: true)
                      );
                      
                      if (wh.isClosed) {
                         // Maybe a small dot to indicate closed? Or nothing.
                         // Let's rely on default styling which is fine.
                         // Or we can gray out the text in defaultBuilder if needed.
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 8),

                FutureBuilder<List<dynamic>>(
                  future: _appointmentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Erreur: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    final allAppts = snapshot.data!;
                    final filteredAppts = _filterAppointmentsForSelectedDay(allAppts);

                    if (filteredAppts.isEmpty) {
                       return _buildEmptyState();
                    }

                    // Sort by time
                    filteredAppts.sort((a, b) => a['startTime'].compareTo(b['startTime']));

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: filteredAppts.length,
                      itemBuilder: (context, index) {
                        final appt = filteredAppts[index];
                        return _buildAppointmentItem(appt);
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
  
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.event_available, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Aucun rendez-vous prévu.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(dynamic appt) {
    final client = appt['client'];
    final service = appt['service'];
    final startTime = DateTime.parse(appt['startTime']);
    final endTime = startTime.add(Duration(minutes: service['duration'] ?? 30));
    final status = appt['status'];
    
    // Status styling
    Color statusColor;
    String statusText;
    switch(status) {
      case 'CONFIRMED':
        statusColor = Colors.green;
        statusText = 'Confirmé';
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        statusText = 'Annulé';
        break;
      case 'PENDING':
        statusColor = Colors.orange;
        statusText = 'En attente';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

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
                  DateFormat('HH:mm').format(startTime),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  DateFormat('HH:mm').format(endTime),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          
          // Timeline Line (Visual flair)
          Container(
             width: 2,
             height: 80,
             color: statusColor.withOpacity(0.5),
             margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // Appointment Card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                ],
                border: Border(left: BorderSide(color: statusColor, width: 4)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        service['name'] ?? 'Service',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
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
                        client['name'] ?? client['email'] ?? 'Client',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                   ),
                   if (service['price'] != null)
                     Padding(
                       padding: const EdgeInsets.only(top: 4),
                       child: Text(
                         '${service['price']}€',
                         style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
}
