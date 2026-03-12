class SubcategoryStat {
  final String subcategoryId;
  final double totalDurationSeconds;
  final int recordingCount;
  final double? targetHours;

  const SubcategoryStat({
    required this.subcategoryId,
    required this.totalDurationSeconds,
    required this.recordingCount,
    this.targetHours,
  });
}

class GenreStat {
  final String genreId;
  final double totalDurationSeconds;
  final int recordingCount;
  final Map<String, SubcategoryStat> subcategories;

  const GenreStat({
    required this.genreId,
    required this.totalDurationSeconds,
    required this.recordingCount,
    this.subcategories = const {},
  });
}
