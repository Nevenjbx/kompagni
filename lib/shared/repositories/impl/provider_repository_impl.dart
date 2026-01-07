import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../models/provider.dart' as models;
import '../../models/working_hours.dart';
import '../provider_repository.dart';

/// Implementation of ProviderRepository using Dio
class ProviderRepositoryImpl implements ProviderRepository {
  final Dio _dio;

  ProviderRepositoryImpl(this._dio);

  @override
  Future<List<models.Provider>> searchProviders({String query = ''}) async {
    final response = await _dio.get(
      '/providers/search',
      queryParameters: {'q': query},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => models.Provider.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<models.Provider> getMyProfile() async {
    final response = await _dio.get('/providers/me');
    return models.Provider.fromJson(response.data);
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _dio.patch('/providers/me', data: data);
  }

  @override
  Future<void> updateWorkingHours(List<WorkingHours> workingHours) async {
    await _dio.put(
      '/providers/me/working-hours',
      data: workingHours
          .where((wh) => !wh.isClosed)
          .map((wh) => wh.toJson())
          .toList(),
    );
  }
}

/// Provider for ProviderRepository
final providerRepositoryProvider = Provider<ProviderRepository>((ref) {
  return ProviderRepositoryImpl(ref.read(apiClientProvider));
});

