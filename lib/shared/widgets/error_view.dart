import 'package:flutter/material.dart';

/// A reusable error view widget with retry functionality.
/// 
/// Displays an error icon, message, and optional retry button.
/// 
/// Example usage:
/// ```dart
/// ErrorView(
///   message: 'Failed to load data',
///   onRetry: () => ref.invalidate(myProvider),
/// )
/// ```
class ErrorView extends StatelessWidget {
  /// The error message to display
  final String message;
  
  /// Optional callback when retry button is pressed
  final VoidCallback? onRetry;
  
  /// Optional detailed error information
  final String? details;
  
  /// Icon to display (defaults to error_outline)
  final IconData icon;
  
  /// Icon color (defaults to red)
  final Color iconColor;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.details,
    this.icon = Icons.error_outline,
    this.iconColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
