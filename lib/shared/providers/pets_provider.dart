import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/pet.dart';
import '../../shared/repositories/impl/pet_repository_impl.dart';

/// Provider for managing user's pets state
/// 
/// Usage in widgets:
/// ```dart
/// final petsAsync = ref.watch(petsProvider);
/// petsAsync.when(...);
/// ```
final petsProvider = AsyncNotifierProvider<PetsNotifier, List<Pet>>(() {
  return PetsNotifier();
});

class PetsNotifier extends AsyncNotifier<List<Pet>> {
  @override
  Future<List<Pet>> build() async {
    return _fetchPets();
  }

  Future<List<Pet>> _fetchPets() async {
    final repository = ref.read(petRepositoryProvider);
    return repository.getMyPets();
  }

  /// Refresh the pets list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPets());
  }

  /// Add a new pet and refresh the list
  Future<void> addPet({
    required String name,
    required AnimalType type,
    required String breed,
    required PetSize size,
    required PetCharacter character,
  }) async {
    final repository = ref.read(petRepositoryProvider);
    await repository.addPet(
      name: name,
      type: type,
      breed: breed,
      size: size,
      character: character,
    );
    await refresh();
  }

  /// Delete a pet and refresh the list
  Future<void> deletePet(String id) async {
    final repository = ref.read(petRepositoryProvider);
    await repository.deletePet(id);
    await refresh();
  }
}

/// Provider that checks if user has any pets
final hasPetsProvider = Provider<AsyncValue<bool>>((ref) {
  final petsAsync = ref.watch(petsProvider);
  return petsAsync.whenData((pets) => pets.isNotEmpty);
});
