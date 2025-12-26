class Provider {
  final String id;
  final String businessName;
  final String description;
  final String address;
  final String city;
  final String postalCode;
  final double? latitude;
  final double? longitude;

  Provider({
    required this.id,
    required this.businessName,
    required this.description,
    required this.address,
    required this.city,
    required this.postalCode,
    this.latitude,
    this.longitude,
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
    );
  }
}
