import 'package:flutter/material.dart';

/// A reusable empty state widget for when no data is available.
/// 
/// Displays an icon, title, optional subtitle, and optional action button.
/// 
/// Example usage:
/// ```dart
/// EmptyState(
///   icon: Icons.pets,
///   title: 'Aucun animal',
///   subtitle: 'Ajoutez votre premier animal de compagnie',
///   actionLabel: 'Ajouter',
///   onAction: () => Navigator.push(...),
/// )
/// ```
class EmptyState extends StatelessWidget {
  /// Icon to display
  final IconData icon;
  
  /// Main title text
  final String title;
  
  /// Optional subtitle text
  final String? subtitle;
  
  /// Optional action button label
  final String? actionLabel;
  
  /// Optional callback for action button
  final VoidCallback? onAction;
  
  /// Icon color (defaults to grey)
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Colors.grey.shade400;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade700,
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
