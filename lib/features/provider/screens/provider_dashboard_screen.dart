import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../auth/services/auth_service.dart';
import '../../../shared/providers/service_providers.dart';
import '../../../shared/models/provider.dart';
import '../../../shared/models/working_hours.dart';
import 'add_service_screen.dart';
import 'edit_account_screen.dart';

// Create a provider for dashboard data to handle "loading" states better.
// We can use a FutureProvider.family or just fetch inside the widget for now, 
// but sticking to "ref.read" as per remediation plan for services.
// Ideally, we'd have a `providerDashboardController` but let's do the minimal invasive fix first:
// use ConsumerStatefulWidget and service providers.

class ProviderDashboardScreen extends ConsumerStatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  ConsumerState<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends ConsumerState<ProviderDashboardScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  late Future<List<dynamic>> _appointmentsFuture;
  late Future<Provider> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _appointmentsFuture = ref.read(appointmentServiceProvider).getMyAppointments();
      _profileFuture = ref.read(providerServiceProvider).getMyProfile();
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthService().signOut();
    // Navigation handled by GoRouter stream
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
                    child: ElevatedButton.icon(
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
                      itemCount: profileSnapshot.data!.services.length + 1,
                      itemBuilder: (context, index) {
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
                  calendarFormat: CalendarFormat.week,
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
          
          Container(
             width: 2,
             height: 80,
             color: statusColor.withOpacity(0.5),
             margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

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
