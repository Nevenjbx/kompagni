enum PetSize {
  small,
  medium,
  large,
  giant
}

enum PetCharacter {
  happy,
  angry,
  calm,
  scared,
  energetic
}

enum AnimalType {
  dog,
  cat,
  other
}

class Pet {
  final String id;
  final String ownerId;
  final String name;
  final AnimalType type;
  final String breed;
  final PetSize size;
  final PetCharacter character;

  Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.breed,
    required this.size,
    required this.character,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      ownerId: json['ownerId'],
      name: json['name'],
      type: AnimalType.values.firstWhere(
        (e) => e.name.toLowerCase() == json['type'].toString().toLowerCase(),
      ),
      breed: json['breed'],
      size: PetSize.values.firstWhere(
        (e) => e.name.toLowerCase() == json['size'].toString().toLowerCase(),
      ),
      character: PetCharacter.values.firstWhere(
        (e) => e.name.toLowerCase() == json['character'].toString().toLowerCase(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'type': type.toString().split('.').last,
      'breed': breed,
      'size': size.toString().split('.').last,
      'character': character.toString().split('.').last,
    };
  }
}
