import '../../../../l10n/app_localizations.dart';
import '../../../shared/utils/recording_description.dart';
import '../../genre/domain/entities/genre.dart';
import 'file_import_entry.dart';

/// Whether [entry] carries everything an import needs before it can be written.
bool isImportEntryValid(FileImportEntry entry, List<Genre> genres) {
  if (entry.genreId == null || entry.genreId!.isEmpty) return false;
  if (entry.registerId == null || entry.registerId!.isEmpty) return false;
  if (!isDescriptionSufficient(entry.descriptionController.text)) return false;
  final genre = genres.where((g) => g.id == entry.genreId).firstOrNull;
  if (genre != null && genre.subcategories.isNotEmpty) {
    if (entry.subcategoryId == null || entry.subcategoryId!.isEmpty) {
      return false;
    }
  }
  return true;
}

/// Inline message for [entry]'s description field, or null when it says enough.
///
/// Only surfaces once [hasError] is set — the screen flags entries when the
/// user presses save, the same moment the classification fields turn red.
String? descriptionErrorText(
  AppLocalizations l10n,
  FileImportEntry entry,
  bool hasError,
) => hasError && !isDescriptionSufficient(entry.descriptionController.text)
    ? l10n.recording_descriptionTooShort(minDescriptionGraphemes)
    : null;
