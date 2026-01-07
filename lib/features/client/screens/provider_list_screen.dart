import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../../../shared/models/provider.dart' as models;
import '../../../shared/providers/favorites_provider.dart';
import '../../../shared/providers/provider_profile_provider.dart';
import 'provider_details_screen.dart';

class ProviderListScreen extends ConsumerStatefulWidget {
  const ProviderListScreen({super.key});

  @override
  ConsumerState<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends ConsumerState<ProviderListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final BehaviorSubject<String> _searchSubject = BehaviorSubject<String>();
  bool _showFavoritesOnly = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchSubject
        .debounceTime(const Duration(milliseconds: 500))
        .listen((query) {
      setState(() {
        _currentQuery = query;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prestataires Kompagni'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(allProvidersProvider);
              ref.invalidate(favoritesProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _FilterChips(
            showFavoritesOnly: _showFavoritesOnly,
            onFavoritesToggled: (selected) {
              setState(() {
                _showFavoritesOnly = selected;
              });
            },
          ),
          
          // Search Bar
          _SearchBar(
            controller: _searchController,
            onChanged: (value) {
              _searchSubject.add(value);
              setState(() {}); // Update suffix icon state
            },
            onClear: () {
              _searchController.clear();
              _searchSubject.add('');
              setState(() {});
            },
          ),
          
          // Provider List
          Expanded(
            child: _showFavoritesOnly
                ? _FavoritesProviderList(query: _currentQuery)
                : _AllProvidersProviderList(query: _currentQuery),
          ),
        ],
      ),
    );
  }
}

/// Filter chips section
class _FilterChips extends StatelessWidget {
  final bool showFavoritesOnly;
  final ValueChanged<bool> onFavoritesToggled;

  const _FilterChips({
    required this.showFavoritesOnly,
    required this.onFavoritesToggled,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Mes favoris'),
            selected: showFavoritesOnly,
            onSelected: onFavoritesToggled,
          ),
        ],
      ),
    );
  }
}

/// Search bar widget
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Rechercher (nom, ville, service...)',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                )
              : null,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Provider list showing all providers with search
class _AllProvidersProviderList extends ConsumerWidget {
  final String query;

  const _AllProvidersProviderList({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync = query.isEmpty
        ? ref.watch(allProvidersProvider)
        : ref.watch(providerSearchProvider(query));

    return providersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        error: error.toString(),
        onRetry: () => ref.invalidate(allProvidersProvider),
      ),
      data: (providers) {
        if (providers.isEmpty) {
          return const Center(child: Text('Aucun prestataire trouvé.'));
        }
        return _ProviderListView(providers: providers);
      },
    );
  }
}

/// Provider list showing only favorites
class _FavoritesProviderList extends ConsumerWidget {
  final String query;

  const _FavoritesProviderList({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return favoritesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        error: error.toString(),
        onRetry: () => ref.invalidate(favoritesProvider),
      ),
      data: (favorites) {
        // Filter favorites by query if needed
        final filtered = query.isEmpty
            ? favorites
            : favorites.where((p) {
                final q = query.toLowerCase();
                return p.businessName.toLowerCase().contains(q) ||
                    p.city.toLowerCase().contains(q);
              }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('Aucun favori trouvé.'));
        }
        return _ProviderListView(providers: filtered);
      },
    );
  }
}

/// Error state widget
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Erreur : $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

/// Actual list view of providers
class _ProviderListView extends StatelessWidget {
  final List<models.Provider> providers;

  const _ProviderListView({required this.providers});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return _ProviderListTile(provider: provider);
      },
    );
  }
}

/// Individual provider list tile
class _ProviderListTile extends StatelessWidget {
  final models.Provider provider;

  const _ProviderListTile({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          provider.businessName.isNotEmpty
              ? provider.businessName[0].toUpperCase()
              : '?',
        ),
      ),
      title: Text(provider.businessName),
      subtitle: Text('${provider.city} • ${provider.description}'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProviderDetailsScreen(provider: provider),
          ),
        );
      },
    );
  }
}
