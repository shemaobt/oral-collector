class Language {
  final String id;
  final String name;
  final String code;

  const Language({required this.id, required this.name, required this.code});

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}
