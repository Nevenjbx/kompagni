import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/environment_config.dart';
import '../../../shared/models/pet.dart';

class PetService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: EnvironmentConfig.apiUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<List<Pet>> getMyPets() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    try {
      final response = await _dio.get(
        '/pets',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Pet.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load pets');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addPet({
    required String name,
    required AnimalType type,
    required String breed,
    required PetSize size,
    required PetCharacter character,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    try {
      await _dio.post(
        '/pets',
        data: {
          'name': name,
          'type': type.toString().split('.').last,
          'breed': breed,
          'size': size.toString().split('.').last,
          'character': character.toString().split('.').last,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
          },
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePet(String id) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    try {
      await _dio.delete(
        '/pets/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
          },
        ),
      );
    } catch (e) {
      rethrow;
    }
  }
}
