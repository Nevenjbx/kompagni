import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/pet.dart';
import '../../../shared/providers/pets_provider.dart';
import '../../../shared/widgets/widgets.dart';
import 'add_pet_screen.dart';

/// Screen displaying the user's pets list.
/// 
/// Uses Riverpod for state management with proper loading/error handling.
class MyPetsScreen extends ConsumerWidget {
  const MyPetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Animaux'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(petsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddPetScreen()),
          );
          ref.invalidate(petsProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(petsProvider.notifier).refresh(),
        child: petsAsync.when(
          loading: () => const LoadingView(message: 'Chargement de vos animaux...'),
          error: (error, _) => ErrorView(
            message: 'Impossible de charger vos animaux',
            details: error.toString(),
            onRetry: () => ref.invalidate(petsProvider),
          ),
          data: (pets) {
            if (pets.isEmpty) {
              return const EmptyState(
                icon: Icons.pets,
                title: 'Aucun animal',
                subtitle: 'Ajoutez votre premier compagnon en appuyant sur le bouton +',
              );
            }

            return ListView.builder(
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                return _PetCard(
                  pet: pet,
                  onDelete: () => _confirmDelete(context, ref, pet),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Pet pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet animal ?'),
        content: Text('Voulez-vous vraiment supprimer ${pet.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(petsProvider.notifier).deletePet(pet.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${pet.name} supprimé')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }
}

/// Card displaying a single pet's information
class _PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onDelete;

  const _PetCard({
    required this.pet,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(pet.type).withAlpha(50),
          child: Icon(_getTypeIcon(pet.type), color: _getTypeColor(pet.type)),
        ),
        title: Text(
          pet.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${pet.breed} • ${_getSizeLabel(pet.size)} • ${_getCharacterLabel(pet.character)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }

  IconData _getTypeIcon(AnimalType type) {
    switch (type) {
      case AnimalType.dog:
        return Icons.pets;
      case AnimalType.cat:
        return Icons.catching_pokemon;
      case AnimalType.other:
        return Icons.cruelty_free;
    }
  }

  Color _getTypeColor(AnimalType type) {
    switch (type) {
      case AnimalType.dog:
        return Colors.brown;
      case AnimalType.cat:
        return Colors.orange;
      case AnimalType.other:
        return Colors.teal;
    }
  }

  String _getSizeLabel(PetSize size) {
    switch (size) {
      case PetSize.small:
        return 'Petit';
      case PetSize.medium:
        return 'Moyen';
      case PetSize.large:
        return 'Grand';
      case PetSize.giant:
        return 'Géant';
    }
  }

  String _getCharacterLabel(PetCharacter character) {
    switch (character) {
      case PetCharacter.happy:
        return 'Joyeux';
      case PetCharacter.angry:
        return 'Énervé';
      case PetCharacter.calm:
        return 'Calme';
      case PetCharacter.scared:
        return 'Peureux';
      case PetCharacter.energetic:
        return 'Énergique';
    }
  }
}
