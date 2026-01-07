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
}

/// Provider for PetRepository
final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepositoryImpl(ref.read(apiClientProvider));
});
