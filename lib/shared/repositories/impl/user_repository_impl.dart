import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../models/provider.dart' as models;
import '../user_repository.dart';

/// Implementation of UserRepository using Dio
/// 
/// This consolidates the previously duplicated UserService files
class UserRepositoryImpl implements UserRepository {
  final Dio _dio;

  UserRepositoryImpl(this._dio);

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _dio.get('/users/me');
      
      if (response.data == null || 
          (response.data is String && (response.data as String).isEmpty)) {
        return null;
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // If 404, user doesn't exist in backend yet
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> syncUser({
    required String role,
    String? name,
    String? phoneNumber,
    Map<String, dynamic>? providerProfile,
    List<String>? tags,
  }) async {
    await _dio.post(
      '/users/sync',
      data: {
        'role': role,
        'name': name,
        'phoneNumber': phoneNumber,
        'providerProfile': providerProfile != null
            ? {...providerProfile, 'tags': tags}
            : null,
      },
    );
  }

  @override
  Future<void> updateUser(Map<String, dynamic> data) async {
    await _dio.patch('/users/me', data: data);
  }

  @override
  Future<void> deleteAccount() async {
    await _dio.delete('/users/me');
  }

  @override
  Future<void> addFavorite(String providerId) async {
    await _dio.post('/users/favorites/$providerId');
  }

  @override
  Future<void> removeFavorite(String providerId) async {
    await _dio.delete('/users/favorites/$providerId');
  }

  @override
  Future<List<models.Provider>> getFavorites() async {
    final response = await _dio.get('/users/favorites');
    
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => models.Provider.fromJson(json)).toList();
    }
    return [];
  }
}

/// Provider for UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.read(apiClientProvider));
});
