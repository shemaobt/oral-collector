class Subcategory {
  final String id;
  final String genreId;
  final String name;
  final String? description;
  final int sortOrder;

  const Subcategory({
    required this.id,
    required this.genreId,
    required this.name,
    this.description,
    this.sortOrder = 0,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'] as String,
      genreId: json['genre_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class Genre {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final int sortOrder;
  final List<Subcategory> subcategories;

  const Genre({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.sortOrder = 0,
    this.subcategories = const [],
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      subcategories:
          (json['subcategories'] as List<dynamic>?)
              ?.map((sub) => Subcategory.fromJson(sub as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
