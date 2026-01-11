import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../shared/models/provider.dart' as models;
import '../../../shared/models/service.dart';
import '../../../shared/providers/appointments_provider.dart';
import '../../../shared/providers/favorites_provider.dart';
import '../../../shared/providers/services_provider.dart';
import '../../../shared/providers/pets_provider.dart';
import '../widgets/booking_calendar.dart';
import '../widgets/booking_bottom_bar.dart';
import '../widgets/info_card.dart';
import '../widgets/section_card.dart';
import '../widgets/service_tile.dart';
import '../widgets/time_slots_grid.dart';
import 'add_pet_screen.dart';

/// Provider details screen with service selection and booking.
class ProviderDetailsScreen extends ConsumerStatefulWidget {
  final models.Provider provider;

  const ProviderDetailsScreen({super.key, required this.provider});

  @override
  ConsumerState<ProviderDetailsScreen> createState() => _ProviderDetailsScreenState();
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
      ref.read(servicesProvider.notifier).loadServicesForProvider(widget.provider.id);
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
    if (_selectedService == null || _selectedDay == null || _selectedSlot == null) return;

    final petId = await _selectPet();
    if (petId == null) return;

    setState(() => _isBooking = true);

    try {
      await ref.read(appointmentsProvider.notifier).createAppointment(
        providerId: widget.provider.id,
        serviceId: _selectedService!.id,
        startTime: DateTime.parse(_selectedSlot!),
        petId: petId,
      );

      if (mounted) {
        await _showSuccessDialog();
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réservation: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  Future<String?> _selectPet() async {
    final pets = await ref.read(petsProvider.future);
    
    if (pets.isEmpty) {
      if (!mounted) return null;
      final shouldAdd = await _showNoPetDialog();
      if (shouldAdd == true && mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddPetScreen()));
      }
      return null;
    }
    
    if (pets.length == 1) return pets.first.id;
    
    if (!mounted) return null;
    return await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pour quel animal ?'),
        children: pets.map((p) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, p.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(p.name, style: const TextStyle(fontSize: 16)),
          ),
        )).toList(),
      ),
    );
  }

  Future<bool?> _showNoPetDialog() => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
        child: const Icon(Icons.pets, size: 48, color: Colors.orange),
      ),
      title: const Text('Aucun animal enregistré', textAlign: TextAlign.center),
      content: const Text('Vous devez d\'abord ajouter un animal.', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter'),
        ),
      ],
    ),
  );

  Future<void> _showSuccessDialog() => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
        child: const Icon(Icons.check_circle, size: 48, color: Colors.green),
      ),
      title: const Text('Rendez-vous confirmé !', textAlign: TextAlign.center),
      content: Text(
        'Merci d\'avoir pris rendez-vous avec ${widget.provider.businessName}.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Retour à l\'accueil')),
      ],
    ),
  );

  Future<void> _toggleFavorite() async {
    final isFav = ref.read(isFavoriteProvider(widget.provider.id));
    try {
      if (isFav) {
        await ref.read(favoritesProvider.notifier).removeFavorite(widget.provider.id);
      } else {
        await ref.read(favoritesProvider.notifier).addFavorite(widget.provider);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = ref.watch(isFavoriteProvider(widget.provider.id));
    final servicesAsync = ref.watch(providerServicesProvider(widget.provider.id));
    final theme = Theme.of(context);
    final provider = widget.provider;

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.businessName),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.red : null),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoCard(
              icon: Icons.location_on,
              iconColor: theme.colorScheme.primary,
              title: 'Adresse',
              content: '${provider.address}\n${provider.city} ${provider.postalCode}',
            ),
            const SizedBox(height: 16),

            if (provider.description.isNotEmpty || provider.tags.isNotEmpty)
              SectionCard(
                title: 'À propos',
                icon: Icons.info_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.description.isNotEmpty)
                      Text(provider.description, style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5)),
                    if (provider.description.isNotEmpty && provider.tags.isNotEmpty) const SizedBox(height: 16),
                    if (provider.tags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: provider.tags.map((tag) => Chip(
                          label: Text(tag),
                          backgroundColor: theme.colorScheme.secondary.withAlpha(50),
                          labelStyle: TextStyle(color: theme.colorScheme.primary),
                          side: BorderSide.none,
                        )).toList(),
                      ),
                  ],
                ),
              ),
            if (provider.description.isNotEmpty || provider.tags.isNotEmpty) const SizedBox(height: 16),

            SectionCard(
              title: 'Nos prestations',
              icon: Icons.content_cut,
              child: servicesAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                error: (e, _) => Text('Erreur: $e'),
                data: (services) => services.isEmpty
                    ? const Text('Aucun service disponible.')
                    : Column(children: services.map((s) => ServiceTile(
                        service: s,
                        isSelected: _selectedService?.id == s.id,
                        onTap: () => setState(() {
                          _selectedService = _selectedService?.id == s.id ? null : s;
                          _selectedSlot = null;
                        }),
                      )).toList()),
              ),
            ),

            if (_selectedService != null) ...[
              const SizedBox(height: 16),
              SectionCard(title: 'Choisir une date', icon: Icons.calendar_month, child: BookingCalendar(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                onDaySelected: _onDaySelected,
              )),
              if (_selectedDay != null) ...[
                const SizedBox(height: 16),
                SectionCard(title: 'Horaires disponibles', icon: Icons.access_time, child: TimeSlotsGrid(
                  providerId: provider.id,
                  serviceId: _selectedService!.id,
                  selectedDate: _selectedDay!,
                  selectedSlot: _selectedSlot,
                  onSlotSelected: (slot) => setState(() => _selectedSlot = slot),
                )),
              ],
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: BookingBottomBar(
        selectedService: _selectedService,
        isBooking: _isBooking,
        selectedSlot: _selectedSlot,
        onBook: _bookAppointment,
      ),
    );
  }
}
