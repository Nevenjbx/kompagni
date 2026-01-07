import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/appointment.dart';
import '../../../shared/providers/appointments_provider.dart';
import '../../../shared/widgets/widgets.dart';

/// Screen displaying all user's appointments (upcoming and past).
/// 
/// Uses Riverpod for state management with proper loading/error handling.
class MyAppointmentsScreen extends ConsumerWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Rendez-vous'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(appointmentsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(appointmentsProvider.notifier).refresh(),
        child: appointmentsAsync.when(
          loading: () => const LoadingView(message: 'Chargement des rendez-vous...'),
          error: (error, _) => ErrorView(
            message: 'Impossible de charger vos rendez-vous',
            details: error.toString(),
            onRetry: () => ref.invalidate(appointmentsProvider),
          ),
          data: (appointments) {
            if (appointments.isEmpty) {
              return const EmptyState(
                icon: Icons.event_busy,
                title: 'Aucun rendez-vous',
                subtitle: 'Réservez votre premier rendez-vous auprès d\'un prestataire',
              );
            }

            // Sort by date, most recent first
            final sorted = List<Appointment>.from(appointments)
              ..sort((a, b) => b.startTime.compareTo(a.startTime));

            return ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                return _AppointmentListTile(
                  appointment: sorted[index],
                  onCancel: () => _cancelAppointment(context, ref, sorted[index]),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _cancelAppointment(
    BuildContext context,
    WidgetRef ref,
    Appointment appointment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler le rendez-vous ?'),
        content: const Text('Voulez-vous vraiment annuler ce rendez-vous ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(appointmentsProvider.notifier).cancelAppointment(appointment.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rendez-vous annulé')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }
}

/// Individual appointment list tile
class _AppointmentListTile extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onCancel;

  const _AppointmentListTile({
    required this.appointment,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = appointment.status == AppointmentStatus.cancelled;
    final isPast = appointment.startTime.isBefore(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(appointment.status).withAlpha(50),
          child: Icon(
            _getStatusIcon(appointment.status),
            color: _getStatusColor(appointment.status),
          ),
        ),
        title: Text(
          appointment.service?.name ?? 'Service',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCancelled ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appointment.provider?.businessName ?? 'Prestataire'),
            Text(
              DateFormat('dd/MM/yyyy à HH:mm').format(appointment.startTime),
              style: TextStyle(
                color: isPast ? Colors.grey : Colors.black87,
              ),
            ),
            _StatusBadge(status: appointment.status),
          ],
        ),
        isThreeLine: true,
        trailing: isCancelled || isPast
            ? null
            : IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                onPressed: onCancel,
              ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.completed:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.pending:
        return Icons.hourglass_empty;
      case AppointmentStatus.completed:
        return Icons.done_all;
    }
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final AppointmentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getColor().withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getLabel(),
        style: TextStyle(
          color: _getColor(),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.completed:
        return Colors.blue;
    }
  }

  String _getLabel() {
    switch (status) {
      case AppointmentStatus.confirmed:
        return 'Confirmé';
      case AppointmentStatus.cancelled:
        return 'Annulé';
      case AppointmentStatus.pending:
        return 'En attente';
      case AppointmentStatus.completed:
        return 'Terminé';
    }
  }
}
