import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressResult {
  final String displayName;
  final String street;
  final String city;
  final String postalCode;
  final double lat;
  final double lon;

  AddressResult({
    required this.displayName,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.lat,
    required this.lon,
  });

  factory AddressResult.fromJson(Map<String, dynamic> json, {String? queryNumber}) {
    final address = json['address'] ?? {};
    final streetName = address['road'] ?? address['pedestrian'] ?? '';
    // Use API house number, fallback to query number if matching street
    final houseNumber = address['house_number'] ?? queryNumber ?? '';
    final city = address['city'] ?? address['town'] ?? address['village'] ?? '';
    final postalCode = address['postcode'] ?? '';
    
    final streetFull = houseNumber.isNotEmpty ? '$houseNumber $streetName' : streetName;
    
    String formattedName = streetFull;
    if (city.isNotEmpty) formattedName += ', $city';
    if (postalCode.isNotEmpty) formattedName += ' ($postalCode)';

    return AddressResult(
      displayName: formattedName,
      street: streetFull,
      city: city,
      postalCode: postalCode,
      lat: double.tryParse(json['lat'] ?? '0') ?? 0.0,
      lon: double.tryParse(json['lon'] ?? '0') ?? 0.0,
    );
  }
}

class AddressService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<List<AddressResult>> searchAddress(String query) async {
    if (query.length < 3) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?q=$query&format=json&addressdetails=1&limit=5&countrycodes=fr'),
        headers: {
          'User-Agent': 'KompagniApp/1.0', // Required by Nominatim
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Extract number from query if present (e.g. "10 ", "10 bis ")
        String? queryNumber;
        final numberMatch = RegExp(r'^(\d+(?:[\s-]?(?:bis|ter|quater|[a-zA-Z]))?)\s+').firstMatch(query);
        if (numberMatch != null) {
          queryNumber = numberMatch.group(1);
        }

        return data.map((item) => AddressResult.fromJson(item, queryNumber: queryNumber)).toList();
      }
    } catch (e) {
      // print('Error searching address: $e');
    }
    return [];
  }
}
