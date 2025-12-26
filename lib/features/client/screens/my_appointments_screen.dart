import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  late Future<List<dynamic>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    setState(() {
      _appointmentsFuture = _appointmentService.getMyAppointments();
    });
  }

  Future<void> _cancelAppointment(String id) async {
    try {
      await _appointmentService.cancelAppointment(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous annulé')),
      );
      _loadAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Rendez-vous')),
      body: FutureBuilder<List<dynamic>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun rendez-vous trouvé.'));
          }

          final appointments = snapshot.data!;
          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appt = appointments[index];
              final provider = appt['provider'];
              final service = appt['service'];
              final startTime = DateTime.parse(appt['startTime']);
              final status = appt['status'];
              final isCancelled = status == 'CANCELLED';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.event, color: Colors.blue),
                  title: Text(service['name']),
                  subtitle: Text(
                    '${provider['businessName']}\n${DateFormat('dd/MM/yyyy HH:mm').format(startTime)}',
                  ),
                  isThreeLine: true,
                  trailing: isCancelled
                      ? const Text('ANNULÉ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                      : IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Annuler le rendez-vous ?'),
                              content: const Text('Voulez-vous vraiment annuler ce rendez-vous ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Non'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _cancelAppointment(appt['id']);
                                  },
                                  child: const Text('Oui'),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
