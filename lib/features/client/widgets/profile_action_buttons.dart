import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

/// Action buttons for profile screen (save, logout, delete)
/// 
/// Extracted from client_profile_screen.dart for better modularity.
class ProfileActionButtons extends ConsumerWidget {
  final bool hasChanges;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  const ProfileActionButtons({
    super.key,
    required this.hasChanges,
    required this.isSaving,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Save Button
        ElevatedButton.icon(
          onPressed: hasChanges && !isSaving ? onSave : null,
          icon: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: const Text('Enregistrer les modifications'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),

        const SizedBox(height: 32),

        // Logout Button
        OutlinedButton.icon(
          onPressed: () async {
            final authService = ref.read(authServiceProvider);
            await authService.signOut();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Me déconnecter'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        const SizedBox(height: 48),
        const Divider(),
        const SizedBox(height: 16),

        // Delete Account
        Center(
          child: TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: const Text(
              'Supprimer mon compte',
              style: TextStyle(color: Colors.red),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
