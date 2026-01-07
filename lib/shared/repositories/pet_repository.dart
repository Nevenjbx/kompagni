import '../models/pet.dart';

/// Repository interface for pet-related operations
abstract class PetRepository {
  /// Get all pets belonging to the current user
  Future<List<Pet>> getMyPets();

  /// Add a new pet
  Future<void> addPet({
    required String name,
    required AnimalType type,
    required String breed,
    required PetSize size,
    required PetCharacter character,
  });

  /// Delete a pet by ID
  Future<void> deletePet(String id);
}
