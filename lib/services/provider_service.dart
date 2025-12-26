import 'package:dio/dio.dart';
import '../models/provider.dart';

class ProviderService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000', // Adjust for Android Emulator: 10.0.2.2
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<List<Provider>> searchProviders({String query = ''}) async {
    try {
      final response = await _dio.get(
        '/providers/search',
        queryParameters: {
          'q': query,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Provider.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load providers');
      }
    } catch (e) {
      // Log error internally if needed
      rethrow;
    }
  }
}
