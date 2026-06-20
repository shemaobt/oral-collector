import '../../../../core/serialization/safe_read.dart';

enum StorytellerSex {
  male('male'),
  female('female'),
  unknown('unknown');

  const StorytellerSex(this.wire);

  /// String exata de servidor/DB. Byte-idêntica ao encoding `name` legado para
  /// [male]/[female].
  final String wire;

  String toWire() => wire;

  /// Tolerante: um valor de wire não reconhecido vira [unknown] em vez de lançar.
  /// Um enum desconhecido não pode escapar do `on Exception` e blankar uma tela.
  static StorytellerSex fromWire(String value) {
    for (final v in StorytellerSex.values) {
      if (v.wire == value) return v;
    }
    return StorytellerSex.unknown;
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
  final String? createdByUserId;
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
    this.createdByUserId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Storyteller.fromJson(Map<String, dynamic> json) {
    return Storyteller(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      sex: StorytellerSex.fromWire(readString(json, 'sex')),
      age: (json['age'] as num?)?.toInt(),
      location: json['location'] as String?,
      dialect: json['dialect'] as String?,
      externalAcceptanceConfirmed:
          json['external_acceptance_confirmed'] as bool? ?? false,
      createdByUserId: json['created_by_user_id'] as String?,
      createdAt: readDate(json, 'created_at'),
      updatedAt: readDateOrNull(json, 'updated_at'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'name': name,
    'sex': sex.toWire(),
    'age': age,
    'location': location,
    'dialect': dialect,
    'external_acceptance_confirmed': externalAcceptanceConfirmed,
    'created_by_user_id': createdByUserId,
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
      createdByUserId: createdByUserId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
