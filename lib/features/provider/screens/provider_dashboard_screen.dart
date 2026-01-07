import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/models/provider.dart' as models;
import '../../../shared/models/service.dart';
import '../../../shared/models/working_hours.dart';
import '../../../shared/providers/appointments_provider.dart';
import '../../../shared/providers/provider_profile_provider.dart';
import '../../auth/services/auth_service.dart';
import 'add_service_screen.dart';
import 'edit_account_screen.dart';

class ProviderDashboardScreen extends ConsumerStatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  ConsumerState<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState
    extends ConsumerState<ProviderDashboardScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Trigger initial data load
    Future.microtask(() {
      ref.invalidate(providerProfileProvider);
      ref.invalidate(appointmentsProvider);
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthService().signOut();
    // Navigation handled by GoRouter stream
  }

  Future<void> _refresh() async {
    ref.invalidate(providerProfileProvider);
    ref.invalidate(appointmentsProvider);
  }

  List<Appointment> _filterAppointmentsForSelectedDay(
      List<Appointment> allAppointments) {
    return allAppointments.where((appt) {
      return isSameDay(appt.startTime, _selectedDay);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(providerProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Erreur: $error')),
      ),
      data: (profile) {
        final title =
            profile != null ? 'Bienvenue ${profile.businessName}' : 'Bienvenue';

        return Scaffold(
          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refresh,
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _signOut(context),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TOP ACTIONS ---
                  _EditAccountButton(profile: profile),
                  const Divider(),

                  // --- SERVICES ---
                  _ServicesSection(
                    services: profile?.services ?? [],
                    onRefresh: _refresh,
                  ),
                  const Divider(),

                  // --- CALENDAR & APPOINTMENTS ---
                  _CalendarHeader(selectedDay: _selectedDay),
                  _CalendarWidget(
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    workingHours: profile?.workingHours ?? [],
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  _AppointmentsForDay(
                    selectedDay: _selectedDay,
                    filterAppointments: _filterAppointmentsForSelectedDay,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Edit account button widget
class _EditAccountButton extends StatelessWidget {
  final models.Provider? profile;

  const _EditAccountButton({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: profile == null
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .push(
                    MaterialPageRoute(
                      builder: (context) =>
                          EditAccountScreen(provider: profile!),
                    ),
                  )
                      .then((result) {
                    if (result == true) {
                      // Refresh will happen via provider
                    }
                  });
                },
                icon: const Icon(Icons.edit),
                label: const Text('Éditer mon compte'),
              ),
      ),
    );
  }
}

/// Services section with horizontal list
class _ServicesSection extends ConsumerWidget {
  final List<Service> services;
  final VoidCallback onRefresh;

  const _ServicesSection({
    required this.services,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Mes Services',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: services.length + 1, // +1 for add card
            itemBuilder: (context, index) {
              // Render "Add Card" at the end
              if (index == services.length) {
                return _AddServiceCard(onRefresh: onRefresh);
              }

              return _ServiceCard(
                service: services[index],
                onRefresh: onRefresh,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Card for adding a new service
class _AddServiceCard extends StatelessWidget {
  final VoidCallback onRefresh;

  const _AddServiceCard({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        color: Colors.blue.shade50,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (context) => const AddServiceScreen(),
              ),
            )
                .then((_) => onRefresh());
          },
          borderRadius: BorderRadius.circular(16),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, size: 40, color: Colors.blue),
              SizedBox(height: 8),
              Text(
                'Ajouter',
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card for existing service
class _ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onRefresh;

  const _ServiceCard({
    required this.service,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (context) => AddServiceScreen(service: service),
              ),
            )
                .then((_) => onRefresh());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.cut, color: Colors.blue, size: 20),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
  }
}

/// Calendar header showing selected day
class _CalendarHeader extends StatelessWidget {
  final DateTime selectedDay;

  const _CalendarHeader({required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}

/// Calendar widget
class _CalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<WorkingHours> workingHours;
  final void Function(DateTime, DateTime) onDaySelected;

  const _CalendarWidget({
    required this.focusedDay,
    required this.selectedDay,
    required this.workingHours,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
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
    );
  }
}

/// Appointments for selected day
class _AppointmentsForDay extends ConsumerWidget {
  final DateTime selectedDay;
  final List<Appointment> Function(List<Appointment>) filterAppointments;

  const _AppointmentsForDay({
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
          return _EmptyAppointmentsState();
        }

        // Sort by time
        filtered.sort((a, b) => a.startTime.compareTo(b.startTime));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _AppointmentTimelineItem(appointment: filtered[index]);
          },
        );
      },
    );
  }
}

/// Empty state for appointments
class _EmptyAppointmentsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
}

/// Single appointment item in timeline
class _AppointmentTimelineItem extends StatelessWidget {
  final Appointment appointment;

  const _AppointmentTimelineItem({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final endTime = appointment.endTime;
    final service = appointment.service;
    final client = appointment.client;
    final status = appointment.status;

    // Status styling
    final (statusColor, statusText) = _getStatusStyle(status);

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
                  DateFormat('HH:mm').format(appointment.startTime),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(endTime),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),

          // Timeline Line
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
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border(
                  left: BorderSide(color: statusColor, width: 4),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        service?.name ?? 'Service',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
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
                        client?.displayName ?? 'Client',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (service?.price != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${service!.price}€',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
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

  (Color, String) _getStatusStyle(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return (Colors.green, 'Confirmé');
      case AppointmentStatus.cancelled:
        return (Colors.red, 'Annulé');
      case AppointmentStatus.pending:
        return (Colors.orange, 'En attente');
      case AppointmentStatus.completed:
        return (Colors.blue, 'Terminé');
    }
  }
}
