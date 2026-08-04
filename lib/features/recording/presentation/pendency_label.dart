import '../../../l10n/app_localizations.dart';
import '../domain/entities/review_pendency.dart';

/// What to call [kind] in front of the user.
///
/// Shared because the project screen's pendency breakdown and the recordings
/// list's filter chip name the same three things, and two switches over one
/// closed enum drift apart one label at a time.
///
/// It lives here rather than beside [PendencyKind] itself: the domain owns what
/// a pendency *is* and which wire code names it, and neither of those knows
/// what language the reader speaks. Putting a translated string in `domain/`
/// would drag `AppLocalizations` — and Flutter with it — into the one layer
/// ADR-0011 keeps free of infrastructure.
///
/// `RecordingCard`'s footer keeps its own version: it collapses two or more
/// pendencies into a count, which is a different sentence, not a different name.
String pendencyLabel(AppLocalizations l10n, PendencyKind kind) =>
    switch (kind) {
      PendencyKind.classification => l10n.recording_pendencyClassification,
      PendencyKind.description => l10n.recording_pendencyDescription,
      PendencyKind.storyteller => l10n.recording_pendencyStoryteller,
    };
