import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/provider.dart';
import '../../../shared/models/service.dart';
import '../../provider/services/service_service.dart';
import '../services/appointment_service.dart';

class ProviderDetailsScreen extends StatefulWidget {
  final Provider provider;

  const ProviderDetailsScreen({super.key, required this.provider});

  @override
  State<ProviderDetailsScreen> createState() => _ProviderDetailsScreenState();
}

class _ProviderDetailsScreenState extends State<ProviderDetailsScreen> {
  final ServiceService _serviceService = ServiceService();
  final AppointmentService _appointmentService = AppointmentService();

  late Future<List<Service>> _servicesFuture;
  Service? _selectedService;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<String> _availableSlots = [];
  String? _selectedSlot;
  bool _isLoadingSlots = false;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _servicesFuture = _serviceService.getServices(widget.provider.id);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedSlot = null;
        _availableSlots = [];
      });

      if (_selectedService != null) {
        _fetchAvailableSlots();
      }
    }
  }

  Future<void> _fetchAvailableSlots() async {
    if (_selectedDay == null || _selectedService == null) return;

    setState(() {
      _isLoadingSlots = true;
    });

    try {
      final slots = await _appointmentService.getAvailableSlots(
        widget.provider.id,
        _selectedService!.id,
        _selectedDay!,
      );
      setState(() {
        _availableSlots = slots;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des créneaux: $e')),
      );
    } finally {
      setState(() {
        _isLoadingSlots = false;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedService == null || _selectedDay == null || _selectedSlot == null) return;

    setState(() {
      _isBooking = true;
    });

    try {
      final datePart = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      // slot is in ISO format full date time
      final startTime = DateTime.parse(_selectedSlot!);

      await _appointmentService.createAppointment(
        providerId: widget.provider.id,
        serviceId: _selectedService!.id,
        startTime: startTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rendez-vous confirmé !'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réservation: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.provider.businessName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.provider.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.provider.address}, ${widget.provider.city} ${widget.provider.postalCode}',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 32),
            const Text(
              'Sélectionnez un service :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Service>>(
              future: _servicesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Erreur : ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Aucun service disponible.');
                }

                return Wrap(
                  spacing: 8.0,
                  children: snapshot.data!.map((service) {
                    final isSelected = _selectedService?.id == service.id;
                    return ChoiceChip(
                      label: Text('${service.name} (${service.price}€)'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedService = selected ? service : null;
                          _selectedSlot = null;
                          _availableSlots = [];
                        });
                        if (selected && _selectedDay != null) {
                          _fetchAvailableSlots();
                        }
                      },
                    );
                  }).toList(),
                );
              },
            ),
            if (_selectedService != null) ...[
              const Divider(height: 32),
              const Text(
                'Choix de la date :',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                calendarFormat: CalendarFormat.twoWeeks,
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              ),
              if (_selectedDay != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Créneaux disponibles :',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_isLoadingSlots)
                  const CircularProgressIndicator()
                else if (_availableSlots.isEmpty)
                  const Text('Aucun créneau disponible ce jour.')
                else
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _availableSlots.map((slotIso) {
                      final dt = DateTime.parse(slotIso);
                      final timeStr = DateFormat('HH:mm').format(dt);
                      final isSelected = _selectedSlot == slotIso;
                      return ChoiceChip(
                        label: Text(timeStr),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedSlot = selected ? slotIso : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
              ],
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isBooking || _selectedSlot == null) ? null : _bookAppointment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isBooking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Confirmer le Rendez-vous'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
