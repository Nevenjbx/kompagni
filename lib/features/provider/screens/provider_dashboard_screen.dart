import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart'; // Needed for isSameDay
import '../../../shared/models/appointment.dart';
import '../../../shared/providers/appointments_provider.dart';
import '../../../shared/providers/provider_profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/services_carousel.dart';
import '../widgets/calendar_section.dart';
import '../widgets/appointments_timeline.dart';

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
    await ref.read(authServiceProvider).signOut();
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
                  DashboardHeader(profile: profile),
                  const Divider(),

                  // --- SERVICES ---
                  ServicesCarousel(
                    services: profile?.services ?? [],
                    onRefresh: _refresh,
                  ),
                  const Divider(),

                  // --- CALENDAR & APPOINTMENTS ---
                  CalendarSection(
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
                  AppointmentsTimeline(
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
