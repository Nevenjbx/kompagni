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
  final Set<String> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    _searchSubject.debounceTime(const Duration(milliseconds: 400)).listen((query) {
      setState(() => _currentQuery = query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchSubject.close();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  List<models.Provider> _filterByTags(List<models.Provider> providers) {
    if (_selectedTags.isEmpty) return providers;
    return providers.where((p) =>
      _selectedTags.any((tag) =>
        p.tags.any((t) => t.toLowerCase().contains(tag.toLowerCase()))
      )
    ).toList();
  }

  /// Check if provider matches all keywords in search query
  /// Searches: businessName, city, description, tags, service names
  bool _matchesSearch(models.Provider provider, String query) {
    if (query.isEmpty) return true;
    
    // Split query into keywords
    final keywords = query.toLowerCase().split(RegExp(r'\s+')).where((k) => k.isNotEmpty).toList();
    if (keywords.isEmpty) return true;
    
    // Build searchable text from all fields
    final searchableText = [
      provider.businessName,
      provider.city,
      provider.description,
      provider.postalCode,
      ...provider.tags,
    ].join(' ').toLowerCase();
    
    // Check if ALL keywords match
    return keywords.every((keyword) => searchableText.contains(keyword));
  }

  /// Build tag chips from actual provider tags
  List<Widget> _buildAvailableTagChips(ThemeData theme) {
    // Get providers based on current view
    final List<models.Provider> providers;
    if (_showFavoritesOnly) {
      final favAsync = ref.watch(favoritesProvider);
      providers = favAsync.maybeWhen(data: (d) => d, orElse: () => <models.Provider>[]);
    } else {
      final provAsync = ref.watch(allProvidersProvider);
      providers = provAsync.maybeWhen(data: (d) => d, orElse: () => <models.Provider>[]);
    }
    
    // Get all unique tags from current providers
    final availableTags = <String>{};
    for (final p in providers) {
      availableTags.addAll(p.tags);
    }
    
    // Build chips for each unique tag
    return availableTags.map((tag) {
      final isSelected = _selectedTags.contains(tag);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilterChip(
          label: Text(tag),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (_) => _toggleTag(tag),
          selectedColor: theme.colorScheme.secondary.withAlpha(80),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trouver un expert'),
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un prestataire...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchSubject.add('');
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                _searchSubject.add(v);
                setState(() {});
              },
            ),
          ),

          // Tag Filter Chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // Favorites chip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: _showFavoritesOnly ? Colors.red : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        const Text('Favoris'),
                      ],
                    ),
                    selected: _showFavoritesOnly,
                    showCheckmark: false,
                    onSelected: (v) => setState(() => _showFavoritesOnly = v),
                    selectedColor: theme.colorScheme.secondary.withAlpha(80),
                  ),
                ),
                // Category chips - only show if providers have these tags
                ..._buildAvailableTagChips(theme),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Provider List
          Expanded(
            child: _showFavoritesOnly
                ? _buildFavoritesList()
                : _buildAllProvidersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAllProvidersList() {
    final providersAsync = ref.watch(allProvidersProvider);

    return providersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(error: e.toString(), onRetry: () => ref.invalidate(allProvidersProvider)),
      data: (providers) {
        // Apply search filter first
        var filtered = _currentQuery.isEmpty 
            ? providers 
            : providers.where((p) => _matchesSearch(p, _currentQuery)).toList();
        // Then apply tag filter
        filtered = _filterByTags(filtered);
        if (filtered.isEmpty) {
          return _EmptyState(message: _selectedTags.isEmpty && _currentQuery.isEmpty 
              ? 'Aucun prestataire trouvé' 
              : 'Aucun résultat pour ces critères');
        }
        return _ProviderGrid(providers: filtered);
      },
    );
  }

  Widget _buildFavoritesList() {
    final favoritesAsync = ref.watch(favoritesProvider);

    return favoritesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(error: e.toString(), onRetry: () => ref.invalidate(favoritesProvider)),
      data: (favorites) {
        var filtered = _filterByTags(favorites);
        if (_currentQuery.isNotEmpty) {
          filtered = filtered.where((p) => _matchesSearch(p, _currentQuery)).toList();
        }
        if (filtered.isEmpty) {
          return const _EmptyState(message: 'Aucun favori trouvé', icon: Icons.favorite_border);
        }
        return _ProviderGrid(providers: filtered);
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({required this.message, this.icon = Icons.search_off});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }
}

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
          Text('Erreur: $error'),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Réessayer')),
        ],
      ),
    );
  }
}

class _ProviderGrid extends StatelessWidget {
  final List<models.Provider> providers;

  const _ProviderGrid({required this.providers});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: providers.length,
      itemBuilder: (context, index) => _ProviderCard(provider: providers[index]),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final models.Provider provider;

  const _ProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProviderDetailsScreen(provider: provider)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  provider.businessName.isNotEmpty ? provider.businessName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.businessName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            provider.city,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (provider.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: provider.tags.take(3).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
