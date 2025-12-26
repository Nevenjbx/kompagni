import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';
import '../services/auth_service.dart';
import '../services/provider_service.dart';
import '../models/provider.dart'; 
import 'login_screen.dart';
import 'add_service_screen.dart';
import 'manage_availability_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
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

  Future<void> _signOut(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
       Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AddServiceScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter Service'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ManageAvailabilityScreen()),
                      );
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('Disponibilités'),
                  ),
                ],
              ),
            ),

            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mes Services',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            FutureBuilder<Provider>(
              future: ProviderService().getMyProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ));
                } else if (snapshot.hasError) {
                   return Center(child: Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Text('Erreur chargement services'),
                   ));
                } else if (!snapshot.hasData) {
                   return const SizedBox();
                }

                final services = snapshot.data!.services;
                if (services.isEmpty) {
                   return const Center(child: Padding(
                     padding: EdgeInsets.all(16.0),
                     child: Text('Aucun service activé.'),
                   ));
                }

                return SizedBox(
                  height: 160, // Ajuste cette hauteur selon tes besoins
                  child: ListView.builder(
                    // 2. On change la direction du scroll
                    scrollDirection: Axis.horizontal,
                    // On garde un petit padding au début et à la fin pour l'esthétique
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      
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
                                // --- HEADER : Icône Service + Bouton Delete ---
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // L'icône du service
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.cut, color: Colors.blue, size: 20),
                                    ),
                                    
                                    // Le bouton supprimer (InkWell pour un petit effet tactile)
                                    InkWell(
                                      onTap: () async {
                                        await ProviderService().deleteService(service.id);
                                        setState(() {});
                                        print("Supprimer le service ${service.name}");
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.delete_outline_rounded, 
                                          color: Colors.red.withOpacity(0.6), // Rouge discret
                                          size: 20
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // --- BODY : Titre et Prix (Inchangé) ---
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
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
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
                );
              },
            ),
            
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Prochains Rendez-vous',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            FutureBuilder<List<dynamic>>(
              future: _appointmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ));
                } else if (snapshot.hasError) {
                   return Center(child: Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Text('Erreur: ${snapshot.error}'),
                   ));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                   return const Center(child: Padding(
                     padding: EdgeInsets.all(16.0),
                     child: Text('Aucun rendez-vous prévu.'),
                   ));
                }

                final appointments = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appt = appointments[index];
                    final client = appt['client'];
                    final service = appt['service'];
                    final startTime = DateTime.parse(appt['startTime']);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                        title: Text('${client['name'] ?? client['email']}'),
                        subtitle: Text(
                          '${service['name']} \n${DateFormat('dd/MM/yyyy HH:mm').format(startTime)}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          appt['status'],
                          style: TextStyle(
                            color: appt['status'] == 'CONFIRMED' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
