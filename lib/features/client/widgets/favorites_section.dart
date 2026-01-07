import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/favorites_provider.dart';
import '../screens/provider_details_screen.dart';
import 'favorite_provider_card.dart';

class FavoritesSection extends ConsumerWidget {
  final VoidCallback onRefresh;

  const FavoritesSection({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mes experts',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        favoritesAsync.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => const Text(
            'Erreur chargement favoris',
            style: TextStyle(color: Colors.red),
          ),
          data: (favorites) {
            if (favorites.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withAlpha(76),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Pas encore de favoris',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  return FavoriteProviderCard(
                    provider: favorites[index],
                    onTap: () {
                      Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ProviderDetailsScreen(provider: favorites[index]),
                        ),
                      )
                          .then((_) => onRefresh());
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
