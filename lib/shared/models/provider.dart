import 'service.dart';
import 'working_hours.dart';

class Provider {
  final String id;
  final String businessName;
  final String description;
  final String address;
  final String city;
  final String postalCode;
  final double? latitude;
  final double? longitude;
  final List<String> tags;
  final List<Service> services;
  final List<WorkingHours> workingHours;

  Provider({
    required this.id,
    required this.businessName,
    required this.description,
    required this.address,
    required this.city,
    required this.postalCode,
    this.latitude,
    this.longitude,
    this.tags = const [],
    this.services = const [],
    this.workingHours = const [],
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    return Provider(
      id: json['id'] ?? '',
      businessName: json['businessName'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      postalCode: json['postalCode'] ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => Service.fromJson(e))
              .toList() ??
          [],
      workingHours: (json['workingHours'] as List<dynamic>?)
              ?.map((e) => WorkingHours.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessName': businessName,
      'description': description,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'tags': tags,
      'services': services.map((s) => s.toJson()).toList(),
      'workingHours': workingHours.map((wh) => wh.toJson()).toList(),
    };
  }

  Provider copyWith({
    String? id,
    String? businessName,
    String? description,
    String? address,
    String? city,
    String? postalCode,
    double? latitude,
    double? longitude,
    List<String>? tags,
    List<Service>? services,
    List<WorkingHours>? workingHours,
  }) {
    return Provider(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tags: tags ?? this.tags,
      services: services ?? this.services,
      workingHours: workingHours ?? this.workingHours,
    );
  }
}
