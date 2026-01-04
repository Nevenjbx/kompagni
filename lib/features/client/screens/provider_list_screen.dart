import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import '../../../shared/models/provider.dart';
import '../../provider/services/provider_service.dart';
import 'provider_details_screen.dart';

class ProviderListScreen extends StatefulWidget {
  const ProviderListScreen({super.key});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  final ProviderService _providerService = ProviderService();
  late Future<List<Provider>> _providersFuture;
  final TextEditingController _searchController = TextEditingController();
  final BehaviorSubject<String> _searchSubject = BehaviorSubject<String>();

  @override
  void initState() {
    super.initState();
    _providersFuture = _providerService.searchProviders();
    _searchSubject
        .debounceTime(const Duration(milliseconds: 500))
        .listen((query) {
      _performSearch(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchSubject.close();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _providersFuture = _providerService.searchProviders(query: query);
    });
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
              // Also clear search when refreshing manually if desired, or just refresh current search
              _performSearch(_searchController.text);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher (nom, ville, service...)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchSubject.add('');
                          setState(() {}); // Update suffix icon state
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                _searchSubject.add(value);
                setState(() {}); // Update suffix icon state
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Provider>>(
              future: _providersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Erreur : ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _performSearch(_searchController.text);
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucun prestataire trouvé.'));
                }

                final providers = snapshot.data!;
                return ListView.builder(
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(provider.businessName.isNotEmpty
                            ? provider.businessName[0].toUpperCase()
                            : '?'),
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
