const String kUnclassifiedGenreId = 'unclassified';

// "Sem gênero" significa exatamente a sentinela; um id qualquer (mesmo vazio)
// conta como gênero. Registros não têm sentinela — só presença não-vazia.
bool recordingHasGenre(String genreId) => genreId != kUnclassifiedGenreId;

bool recordingHasRegister(String? registerId) =>
    registerId != null && registerId.isNotEmpty;

bool recordingIsUnclassified({
  required String genreId,
  required String? registerId,
}) => !recordingHasGenre(genreId) || !recordingHasRegister(registerId);

bool recordingIsClassified({
  required String genreId,
  required String? registerId,
}) => recordingHasGenre(genreId) && recordingHasRegister(registerId);

bool recordingHasSecondaryGenre(String? secondaryGenreId) =>
    secondaryGenreId != null &&
    secondaryGenreId.isNotEmpty &&
    secondaryGenreId != kUnclassifiedGenreId;

bool recordingHasSecondaryRegister(String? secondaryRegisterId) =>
    secondaryRegisterId != null && secondaryRegisterId.isNotEmpty;

// Só o trio inteiro colide: (Formal, Narrativa, Mito) e (Formal, Narrativa,
// Lenda) são um par legítimo. Secundário todo nulo nunca colide, mesmo com um
// primário também todo nulo.
bool secondaryEqualsPrimary({
  required String? primaryRegisterId,
  required String? primaryGenreId,
  required String? primarySubcategoryId,
  required String? secondaryRegisterId,
  required String? secondaryGenreId,
  required String? secondarySubcategoryId,
}) {
  if (secondaryRegisterId == null &&
      secondaryGenreId == null &&
      secondarySubcategoryId == null) {
    return false;
  }
  return primaryRegisterId == secondaryRegisterId &&
      primaryGenreId == secondaryGenreId &&
      primarySubcategoryId == secondarySubcategoryId;
}

class SegmentClassificationCollisionException implements Exception {
  const SegmentClassificationCollisionException(this.segmentId);

  final String segmentId;

  @override
  String toString() =>
      'SegmentClassificationCollisionException(segment: $segmentId)';
}

bool recordingHasSecondary({
  required String? secondaryGenreId,
  required String? secondaryRegisterId,
}) =>
    recordingHasSecondaryGenre(secondaryGenreId) ||
    recordingHasSecondaryRegister(secondaryRegisterId);
