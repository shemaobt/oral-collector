enum StorytellerSex {
  male,
  female;

  String toJson() => name;

  static StorytellerSex fromJson(String value) {
    switch (value) {
      case 'male':
        return StorytellerSex.male;
      case 'female':
        return StorytellerSex.female;
      default:
        throw ArgumentError('Unknown StorytellerSex: $value');
    }
  }
}

class Storyteller {
  final String id;
  final String projectId;
  final String name;
  final StorytellerSex sex;
  final int? age;
  final String? location;
  final String? dialect;
  final bool externalAcceptanceConfirmed;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Storyteller({
    required this.id,
    required this.projectId,
    required this.name,
    required this.sex,
    this.age,
    this.location,
    this.dialect,
    required this.externalAcceptanceConfirmed,
    required this.createdAt,
    this.updatedAt,
  });

  factory Storyteller.fromJson(Map<String, dynamic> json) {
    return Storyteller(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      sex: StorytellerSex.fromJson(json['sex'] as String),
      age: (json['age'] as num?)?.toInt(),
      location: json['location'] as String?,
      dialect: json['dialect'] as String?,
      externalAcceptanceConfirmed:
          json['external_acceptance_confirmed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'name': name,
    'sex': sex.toJson(),
    'age': age,
    'location': location,
    'dialect': dialect,
    'external_acceptance_confirmed': externalAcceptanceConfirmed,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  Storyteller copyWith({
    String? name,
    StorytellerSex? sex,
    int? age,
    String? location,
    String? dialect,
  }) {
    return Storyteller(
      id: id,
      projectId: projectId,
      name: name ?? this.name,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      location: location ?? this.location,
      dialect: dialect ?? this.dialect,
      externalAcceptanceConfirmed: externalAcceptanceConfirmed,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
