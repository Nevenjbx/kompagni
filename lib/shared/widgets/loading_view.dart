import 'package:flutter/material.dart';

/// A consistent loading indicator widget.
/// 
/// Provides a centered circular progress indicator with optional message.
/// 
/// Example usage:
/// ```dart
/// LoadingView(message: 'Chargement des données...')
/// ```
class LoadingView extends StatelessWidget {
  /// Optional message to display below the spinner
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
