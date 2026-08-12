const String kUnclassifiedGenreId = 'unclassified';

// Linha irmã da sentinela de gênero, semeada na mesma migração do servidor. O
// literal coincide, mas são colunas diferentes: não colapse as duas constantes.
const String kUnclassifiedSubcategoryId = 'unclassified';

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

/// Linhas do Drift guardam ausência ora como null, ora como ''; o resto deste
/// arquivo trata os dois como ausente.
String? blankToNull(String? value) =>
    (value == null || value.isEmpty) ? null : value;

// Só o trio inteiro colide: (Formal, Narrativa, Mito) e (Formal, Narrativa,
// Lenda) são um par legítimo. Secundário todo ausente nunca colide, mesmo com
// um primário também todo ausente.
bool secondaryEqualsPrimary({
  required String? primaryRegisterId,
  required String? primaryGenreId,
  required String? primarySubcategoryId,
  required String? secondaryRegisterId,
  required String? secondaryGenreId,
  required String? secondarySubcategoryId,
}) {
  final secondaryRegister = blankToNull(secondaryRegisterId);
  final secondaryGenre = blankToNull(secondaryGenreId);
  final secondarySubcategory = blankToNull(secondarySubcategoryId);
  if (secondaryRegister == null &&
      secondaryGenre == null &&
      secondarySubcategory == null) {
    return false;
  }
  return blankToNull(primaryRegisterId) == secondaryRegister &&
      blankToNull(primaryGenreId) == secondaryGenre &&
      blankToNull(primarySubcategoryId) == secondarySubcategory;
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
