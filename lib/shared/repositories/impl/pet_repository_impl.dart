import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../models/pet.dart';
import '../pet_repository.dart';

/// Implementation of PetRepository using Dio
class PetRepositoryImpl implements PetRepository {
  final Dio _dio;

  PetRepositoryImpl(this._dio);

  @override
  Future<List<Pet>> getMyPets() async {
    final response = await _dio.get('/pets');
    
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => Pet.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<List<Pet>> getUserPets(String userId) async {
    final response = await _dio.get('/pets/user/$userId');
    
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => Pet.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<void> addPet({
    required String name,
    required AnimalType type,
    required String breed,
    required PetSize size,
    required PetCharacter character,
  }) async {
    await _dio.post(
      '/pets',
      data: {
        'name': name,
        'type': type.name,
        'breed': breed,
        'size': size.name,
        'character': character.name,
      },
    );
  }

  @override
  Future<void> deletePet(String id) async {
    await _dio.delete('/pets/$id');
  }

  @override
  Future<String?> getPetNote(String petId) async {
    try {
      final response = await _dio.get('/pets/$petId/note');
      return response.data['note'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updatePetNote(String petId, String note) async {
    await _dio.post(
      '/pets/$petId/note',
      data: {'note': note},
    );
  }
}

/// Provider for PetRepository
final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepositoryImpl(ref.read(apiClientProvider));
});
