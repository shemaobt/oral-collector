/// Partial-update body for PATCH /api/oc/recordings/{id}. A null field is
/// omitted from the wire (left untouched); [clearSecondary] sends an explicit
/// null for the three secondary-classification keys to clear them.
class UpdateRecordingRequest {
  final String? title;
  final String? description;
  final String? genreId;
  final String? subcategoryId;
  final String? registerId;
  final String? secondaryGenreId;
  final String? secondarySubcategoryId;
  final String? secondaryRegisterId;
  final bool clearSecondary;
  final String? storytellerId;
  final String? cleaningStatus;
  final double? durationSeconds;
  final int? fileSizeBytes;

  const UpdateRecordingRequest({
    this.title,
    this.description,
    this.genreId,
    this.subcategoryId,
    this.registerId,
    this.secondaryGenreId,
    this.secondarySubcategoryId,
    this.secondaryRegisterId,
    this.clearSecondary = false,
    this.storytellerId,
    this.cleaningStatus,
    this.durationSeconds,
    this.fileSizeBytes,
  });

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (genreId != null) body['genre_id'] = genreId;
    if (subcategoryId != null) body['subcategory_id'] = subcategoryId;
    if (registerId != null) body['register_id'] = registerId;
    if (clearSecondary) {
      body['secondary_genre_id'] = null;
      body['secondary_subcategory_id'] = null;
      body['secondary_register_id'] = null;
    } else {
      if (secondaryGenreId != null) {
        body['secondary_genre_id'] = secondaryGenreId;
      }
      if (secondarySubcategoryId != null) {
        body['secondary_subcategory_id'] = secondarySubcategoryId;
      }
      if (secondaryRegisterId != null) {
        body['secondary_register_id'] = secondaryRegisterId;
      }
    }
    if (storytellerId != null) body['storyteller_id'] = storytellerId;
    if (cleaningStatus != null) body['cleaning_status'] = cleaningStatus;
    if (durationSeconds != null) body['duration_seconds'] = durationSeconds;
    if (fileSizeBytes != null) body['file_size_bytes'] = fileSizeBytes;
    return body;
  }
}
