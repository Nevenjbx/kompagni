import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../models/service.dart';
import '../service_repository.dart';

/// Implementation of ServiceRepository using Dio
class ServiceRepositoryImpl implements ServiceRepository {
  final Dio _dio;

  ServiceRepositoryImpl(this._dio);

  @override
  Future<List<Service>> getServices(String providerId) async {
    try {
      final response = await _dio.get(
        '/services',
        queryParameters: {'providerId': providerId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Service.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }

  @override
  Future<void> createService({
    required String name,
    String? description,
    required int duration,
    required double price,
    required String animalType,
  }) async {
    await _dio.post(
      '/services',
      data: {
        'name': name,
        'description': description,
        'duration': duration,
        'price': price,
        'animalType': animalType,
      },
    );
  }

  @override
  Future<void> updateService({
    required String id,
    required String name,
    String? description,
    required int duration,
    required double price,
    required String animalType,
  }) async {
    await _dio.patch(
      '/services/$id',
      data: {
        'name': name,
        'description': description,
        'duration': duration,
        'price': price,
        'animalType': animalType,
      },
    );
  }

  @override
  Future<void> deleteService(String id) async {
    await _dio.delete('/services/$id');
  }
}

/// Provider for ServiceRepository
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepositoryImpl(ref.read(apiClientProvider));
});
