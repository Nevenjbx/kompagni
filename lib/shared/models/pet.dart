enum PetSize {
  SMALL,
  MEDIUM,
  LARGE,
  GIANT
}

enum PetCharacter {
  HAPPY,
  ANGRY,
  CALM,
  SCARED,
  ENERGETIC
}

enum AnimalType {
  DOG,
  CAT,
  OTHER
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
      type: AnimalType.values.firstWhere((e) => e.toString() == 'AnimalType.${json['type']}'),
      breed: json['breed'],
      size: PetSize.values.firstWhere((e) => e.toString() == 'PetSize.${json['size']}'),
      character: PetCharacter.values.firstWhere((e) => e.toString() == 'PetCharacter.${json['character']}'),
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
