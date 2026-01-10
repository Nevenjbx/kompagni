import '../models/pet.dart';

/// Repository interface for pet-related operations
abstract class PetRepository {
  /// Get all pets belonging to the current user
  Future<List<Pet>> getMyPets();

  /// Get pets of a specific user
  Future<List<Pet>> getUserPets(String userId);

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

  /// Get provider note for a pet
  Future<String?> getPetNote(String petId);

  /// Update provider note for a pet
  Future<void> updatePetNote(String petId, String note);
}
