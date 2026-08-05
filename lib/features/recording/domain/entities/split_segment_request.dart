/// One segment in a POST /api/oc/recordings/{id}/split request body. Optional
/// fields are omitted from the wire when null.
class SplitSegmentRequest {
  final double startSeconds;
  final double endSeconds;
  final String? genreId;
  final String? subcategoryId;
  final String? registerId;
  final double? gainDb;

  const SplitSegmentRequest({
    required this.startSeconds,
    required this.endSeconds,
    this.genreId,
    this.subcategoryId,
    this.registerId,
    this.gainDb,
  });

  Map<String, dynamic> toJson() {
    return {
      'start_seconds': startSeconds,
      'end_seconds': endSeconds,
      if (genreId != null) 'genre_id': genreId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      if (registerId != null) 'register_id': registerId,
      if (gainDb != null) 'gain_db': gainDb,
    };
  }
}
