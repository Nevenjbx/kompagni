import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../shared/models/provider.dart' as models;
import '../../../shared/models/service.dart';
import '../../../shared/providers/appointments_provider.dart';
import '../../../shared/providers/favorites_provider.dart';
import '../../../shared/providers/services_provider.dart';
import '../widgets/provider_info_section.dart';
import '../widgets/service_selection_card.dart';
import '../widgets/booking_calendar.dart';
import '../widgets/time_slots_grid.dart';

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
        _selectedSlot == null) {
      return;
    }

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
    final servicesAsync =
        ref.watch(providerServicesProvider(widget.provider.id));

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
            ProviderInfoSection(provider: widget.provider),
            const Divider(height: 32),

            // Services Selection
            const Text(
              'Sélectionnez un service :',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildServicesSection(servicesAsync),

            // Calendar and Slots (only if service selected)
            if (_selectedService != null) ...[
              const Divider(height: 32),
              BookingCalendar(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                onDaySelected: _onDaySelected,
              ),
              if (_selectedDay != null) ...[
                const SizedBox(height: 16),
                TimeSlotsGrid(
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_isBooking || _selectedSlot == null) ? null : _bookAppointment,
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

  Widget _buildServicesSection(AsyncValue<List<Service>> servicesAsync) {
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
            final isSelected = _selectedService?.id == service.id;

            return ServiceSelectionCard(
              service: service,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedService =
                      _selectedService?.id == service.id ? null : service;
                  _selectedSlot = null;
                });
              },
            );
          },
        );
      },
    );
  }
}
