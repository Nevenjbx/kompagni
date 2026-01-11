import 'package:flutter/material.dart';
import '../../../shared/models/service.dart';

/// Sticky bottom bar for booking confirmation.
class BookingBottomBar extends StatelessWidget {
  final Service? selectedService;
  final bool isBooking;
  final String? selectedSlot;
  final VoidCallback? onBook;

  const BookingBottomBar({
    super.key,
    this.selectedService,
    required this.isBooking,
    this.selectedSlot,
    this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected service summary
            if (selectedService != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      selectedService!.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${selectedService!.price.toStringAsFixed(0)}€',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            // Book button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: (isBooking || selectedSlot == null) ? null : onBook,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isBooking
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        selectedSlot == null 
                            ? 'Sélectionnez un créneau' 
                            : 'Confirmer le rendez-vous',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
