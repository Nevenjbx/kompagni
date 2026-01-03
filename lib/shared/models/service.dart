class Service {
  final String id;
  final String providerId;
  final String name;
  final String? description;
  final int duration;
  final double price;
  final String animalType;

  Service({
    required this.id,
    required this.providerId,
    required this.name,
    this.description,
    required this.duration,
    required this.price,
    this.animalType = 'DOG',
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? '',
      providerId: json['providerId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      duration: json['duration'] is int ? json['duration'] : int.parse(json['duration'].toString()),
      price: json['price'] is double ? json['price'] : double.parse(json['price'].toString()),
      animalType: json['animalType'] ?? 'DOG',
    );
  }
}
