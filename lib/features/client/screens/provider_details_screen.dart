import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/provider.dart' as models;
import '../../../shared/models/service.dart';
import '../../../shared/providers/appointments_provider.dart';
import '../../../shared/providers/favorites_provider.dart';
import '../../../shared/providers/services_provider.dart';

class ProviderDetailsScreen extends ConsumerStatefulWidget {
  final models.Provider provider;

  const ProviderDetailsScreen({super.key, required this.provider});

  @override
  ConsumerState<ProviderDetailsScreen> createState() =>
      _ProviderDetailsScreenState();
}

class _ProviderDetailsScreenState extends ConsumerState<ProviderDetailsScreen> {
  Service? _selectedService;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedSlot;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    // Load services for this provider
    Future.microtask(() {
      ref
          .read(servicesProvider.notifier)
          .loadServicesForProvider(widget.provider.id);
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedSlot = null;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedService == null ||
        _selectedDay == null ||
        _selectedSlot == null) return;

    setState(() {
      _isBooking = true;
    });

    try {
      final startTime = DateTime.parse(_selectedSlot!);

      await ref.read(appointmentsProvider.notifier).createAppointment(
            providerId: widget.provider.id,
            serviceId: _selectedService!.id,
            startTime: startTime,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous confirmé !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur réservation: $e'),
            backgroundColor: Colors.red,
          ),
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

  Future<void> _toggleFavorite() async {
    final notifier = ref.read(favoritesProvider.notifier);
    final isFavorite = ref.read(isFavoriteProvider(widget.provider.id));

    try {
      if (isFavorite) {
        await notifier.removeFavorite(widget.provider.id);
      } else {
        await notifier.addFavorite(widget.provider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = ref.watch(isFavoriteProvider(widget.provider.id));
    final servicesAsync = ref.watch(providerServicesProvider(widget.provider.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.provider.businessName),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Info
            _ProviderInfoSection(provider: widget.provider),
            const Divider(height: 32),

            // Services Selection
            const Text(
              'Sélectionnez un service :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _ServicesListSection(
              servicesAsync: servicesAsync,
              selectedService: _selectedService,
              onServiceSelected: (service) {
                setState(() {
                  _selectedService =
                      _selectedService?.id == service.id ? null : service;
                  _selectedSlot = null;
                });
              },
            ),

            // Calendar and Slots (only if service selected)
            if (_selectedService != null) ...[
              const Divider(height: 32),
              _CalendarSection(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                onDaySelected: _onDaySelected,
              ),
              if (_selectedDay != null) ...[
                const SizedBox(height: 16),
                _SlotsSection(
                  providerId: widget.provider.id,
                  serviceId: _selectedService!.id,
                  selectedDate: _selectedDay!,
                  selectedSlot: _selectedSlot,
                  onSlotSelected: (slot) {
                    setState(() {
                      _selectedSlot = slot;
                    });
                  },
                ),
              ],
            ],

            const SizedBox(height: 32),

            // Book Button
            _BookButton(
              isBooking: _isBooking,
              isEnabled: _selectedSlot != null,
              onPressed: _bookAppointment,
            ),
          ],
        ),
      ),
    );
  }
}

/// Provider info section
class _ProviderInfoSection extends StatelessWidget {
  final models.Provider provider;

  const _ProviderInfoSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          provider.description,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          '${provider.address}, ${provider.city} ${provider.postalCode}',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

/// Services list section
class _ServicesListSection extends StatelessWidget {
  final AsyncValue<List<Service>> servicesAsync;
  final Service? selectedService;
  final void Function(Service) onServiceSelected;

  const _ServicesListSection({
    required this.servicesAsync,
    required this.selectedService,
    required this.onServiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return servicesAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('Erreur : $error'),
      data: (services) {
        if (services.isEmpty) {
          return const Text('Aucun service disponible.');
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final service = services[index];
            final isSelected = selectedService?.id == service.id;

            return _ServiceSelectionCard(
              service: service,
              isSelected: isSelected,
              onTap: () => onServiceSelected(service),
            );
          },
        );
      },
    );
  }
}

/// Service selection card
class _ServiceSelectionCard extends StatelessWidget {
  final Service service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceSelectionCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? Colors.blue[50] : Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      service.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    '${service.price}€',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${service.duration} min',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              if (service.description != null &&
                  service.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  service.description!,
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Calendar section
class _CalendarSection extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime, DateTime) onDaySelected;

  const _CalendarSection({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choix de la date :',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(const Duration(days: 90)),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,
          calendarFormat: CalendarFormat.twoWeeks,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
      ],
    );
  }
}

/// Available slots section
class _SlotsSection extends ConsumerWidget {
  final String providerId;
  final String serviceId;
  final DateTime selectedDate;
  final String? selectedSlot;
  final void Function(String?) onSlotSelected;

  const _SlotsSection({
    required this.providerId,
    required this.serviceId,
    required this.selectedDate,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsParams = AvailableSlotsParams(
      providerId: providerId,
      serviceId: serviceId,
      date: selectedDate,
    );
    final slotsAsync = ref.watch(availableSlotsProvider(slotsParams));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Créneaux disponibles :',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        slotsAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('Erreur: $error'),
          data: (slots) {
            if (slots.isEmpty) {
              return const Text('Aucun créneau disponible ce jour.');
            }

            return Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: slots.map((slotIso) {
                final dt = DateTime.parse(slotIso);
                final timeStr = DateFormat('HH:mm').format(dt);
                final isSelected = selectedSlot == slotIso;

                return ChoiceChip(
                  label: Text(timeStr),
                  selected: isSelected,
                  onSelected: (selected) {
                    onSlotSelected(selected ? slotIso : null);
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

/// Book appointment button
class _BookButton extends StatelessWidget {
  final bool isBooking;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _BookButton({
    required this.isBooking,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (isBooking || !isEnabled) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isBooking
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Confirmer le Rendez-vous'),
      ),
    );
  }
}
