import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/environment_config.dart';
import '../../../shared/models/service.dart';

class ServiceService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: EnvironmentConfig.apiUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<List<Service>> getServices(String providerId) async {
    try {
      final response = await _dio.get(
        '/services',
        queryParameters: {'providerId': providerId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Service.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load services');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
          return [];
      }
      rethrow;
    }
  }

  Future<void> createService({
    required String name,
    required String? description,
    required int duration,
    required double price,
    required String animalType,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    try {
      await _dio.post(
        '/services',
        data: {
          'name': name,
          'description': description,
          'duration': duration, // minutes
          'price': price,
          'animalType': animalType,
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
}
