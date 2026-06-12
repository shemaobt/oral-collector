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

bool recordingHasSecondary({
  required String? secondaryGenreId,
  required String? secondaryRegisterId,
}) =>
    recordingHasSecondaryGenre(secondaryGenreId) ||
    recordingHasSecondaryRegister(secondaryRegisterId);
