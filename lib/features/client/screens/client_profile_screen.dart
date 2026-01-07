import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayName = user?.userMetadata?['full_name'] ??
        user?.userMetadata?['first_name'] ??
        'Mon Profil';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Compte'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 24),
              
              // Name
              Text(
                displayName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              
              if (user?.email != null) ...[
                const SizedBox(height: 8),
                Text(
                  user!.email!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
              
              const SizedBox(height: 48),
              
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final authService = ref.read(authServiceProvider);
                    await authService.signOut();
                    // Navigation handled by GoRouter auth state listener
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Me déconnecter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
