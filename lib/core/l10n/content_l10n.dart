import '../../l10n/app_localizations.dart';

String _slugToTitleCase(String slug) {
  if (!slug.contains('-') && !slug.contains('_')) return slug;
  return slug
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String localizedGenreName(AppLocalizations l10n, String fallback) {
  final direct = _genreNames[fallback]?.call(l10n);
  if (direct != null) return direct;
  final titleCase = _slugToTitleCase(fallback);
  return _genreNames[titleCase]?.call(l10n) ?? titleCase;
}

String localizedGenreDescription(AppLocalizations l10n, String fallback) {
  return _genreDescriptions[fallback]?.call(l10n) ?? fallback;
}

String localizedSubcategoryName(AppLocalizations l10n, String fallback) {
  final direct = _subcategoryNames[fallback]?.call(l10n);
  if (direct != null) return direct;

  final titleCase = _slugToTitleCase(fallback);
  final fromSlug = _subcategoryNames[titleCase]?.call(l10n);
  if (fromSlug != null) return fromSlug;

  return titleCase;
}

String? localizedSubcategoryDescription(AppLocalizations l10n, String name) {
  final direct = _subcategoryDescriptions[name]?.call(l10n);
  if (direct != null) return direct;

  final titleCase = _slugToTitleCase(name);
  return _subcategoryDescriptions[titleCase]?.call(l10n);
}

String localizedRegisterName(AppLocalizations l10n, String fallback) {
  return _registerNames[fallback]?.call(l10n) ?? fallback;
}

final _genreNames = <String, String Function(AppLocalizations)>{
  'Narrative': (l10n) => l10n.genre_narrative,
  'Poetic / Song': (l10n) => l10n.genre_poeticSong,
  'Instructional / Regulatory': (l10n) => l10n.genre_instructional,
  'Oral Discourse': (l10n) => l10n.genre_oralDiscourse,
};

final _genreDescriptions = <String, String Function(AppLocalizations)>{
  'Stories, accounts, and narrative forms of oral tradition': (l10n) =>
      l10n.genre_narrativeDesc,
  'Musical and poetic oral traditions including hymns, laments, and wisdom poetry':
      (l10n) => l10n.genre_poeticSongDesc,
  'Laws, rituals, procedures, and instructional forms': (l10n) =>
      l10n.genre_instructionalDesc,
  'Speeches, teachings, prayers, and discursive oral forms': (l10n) =>
      l10n.genre_oralDiscourseDesc,
};

final _subcategoryNames = <String, String Function(AppLocalizations)>{
  'Historical Narrative': (l10n) => l10n.sub_historicalNarrative,
  'Personal Account / Testimony': (l10n) => l10n.sub_personalAccount,
  'Parable / Illustrative Story': (l10n) => l10n.sub_parable,
  'Origin / Creation Story': (l10n) => l10n.sub_originStory,
  'Legend / Hero Story': (l10n) => l10n.sub_legend,
  'Vision or Dream Narrative': (l10n) => l10n.sub_visionNarrative,
  'Genealogy': (l10n) => l10n.sub_genealogy,
  'Recent Event Report': (l10n) => l10n.sub_eventReport,
  'Hymn / Worship Song': (l10n) => l10n.sub_hymn,
  'Lament': (l10n) => l10n.sub_lament,
  'Funeral Dirge': (l10n) => l10n.sub_funeralDirge,
  'Victory / Celebration Song': (l10n) => l10n.sub_victorySong,
  'Love Song': (l10n) => l10n.sub_loveSong,
  'Mocking / Taunt Song': (l10n) => l10n.sub_tauntSong,
  'Blessing': (l10n) => l10n.sub_blessing,
  'Curse': (l10n) => l10n.sub_curse,
  'Wisdom Poem / Proverb': (l10n) => l10n.sub_wisdomPoem,
  'Didactic Poetry': (l10n) => l10n.sub_didacticPoetry,
  'Law / Legal Code': (l10n) => l10n.sub_legalCode,
  'Ritual / Liturgy': (l10n) => l10n.sub_ritual,
  'Procedure / Instruction': (l10n) => l10n.sub_procedure,
  'List / Inventory': (l10n) => l10n.sub_listInventory,
  'Prophetic Oracle / Speech': (l10n) => l10n.sub_propheticOracle,
  'Exhortation / Sermon': (l10n) => l10n.sub_exhortation,
  'Wisdom Teaching': (l10n) => l10n.sub_wisdomTeaching,
  'Prayer': (l10n) => l10n.sub_prayer,
  'Dialogue': (l10n) => l10n.sub_dialogue,
  'Epistle / Letter': (l10n) => l10n.sub_epistle,
  'Apocalyptic Discourse': (l10n) => l10n.sub_apocalypticDiscourse,
  'Ceremonial Speech': (l10n) => l10n.sub_ceremonialSpeech,
  'Community Memory': (l10n) => l10n.sub_communityMemory,
};

final _subcategoryDescriptions = <String, String Function(AppLocalizations)>{
  'Historical Narrative': (l10n) => l10n.sub_historicalNarrativeDesc,
  'Personal Account / Testimony': (l10n) => l10n.sub_personalAccountDesc,
  'Parable / Illustrative Story': (l10n) => l10n.sub_parableDesc,
  'Origin / Creation Story': (l10n) => l10n.sub_originStoryDesc,
  'Legend / Hero Story': (l10n) => l10n.sub_legendDesc,
  'Vision or Dream Narrative': (l10n) => l10n.sub_visionNarrativeDesc,
  'Genealogy': (l10n) => l10n.sub_genealogyDesc,
  'Recent Event Report': (l10n) => l10n.sub_eventReportDesc,
  'Hymn / Worship Song': (l10n) => l10n.sub_hymnDesc,
  'Lament': (l10n) => l10n.sub_lamentDesc,
  'Funeral Dirge': (l10n) => l10n.sub_funeralDirgeDesc,
  'Victory / Celebration Song': (l10n) => l10n.sub_victorySongDesc,
  'Love Song': (l10n) => l10n.sub_loveSongDesc,
  'Mocking / Taunt Song': (l10n) => l10n.sub_tauntSongDesc,
  'Blessing': (l10n) => l10n.sub_blessingDesc,
  'Curse': (l10n) => l10n.sub_curseDesc,
  'Wisdom Poem / Proverb': (l10n) => l10n.sub_wisdomPoemDesc,
  'Didactic Poetry': (l10n) => l10n.sub_didacticPoetryDesc,
  'Law / Legal Code': (l10n) => l10n.sub_legalCodeDesc,
  'Ritual / Liturgy': (l10n) => l10n.sub_ritualDesc,
  'Procedure / Instruction': (l10n) => l10n.sub_procedureDesc,
  'List / Inventory': (l10n) => l10n.sub_listInventoryDesc,
  'Prophetic Oracle / Speech': (l10n) => l10n.sub_propheticOracleDesc,
  'Exhortation / Sermon': (l10n) => l10n.sub_exhortationDesc,
  'Wisdom Teaching': (l10n) => l10n.sub_wisdomTeachingDesc,
  'Prayer': (l10n) => l10n.sub_prayerDesc,
  'Dialogue': (l10n) => l10n.sub_dialogueDesc,
  'Epistle / Letter': (l10n) => l10n.sub_epistleDesc,
  'Apocalyptic Discourse': (l10n) => l10n.sub_apocalypticDiscourseDesc,
  'Ceremonial Speech': (l10n) => l10n.sub_ceremonialSpeechDesc,
  'Community Memory': (l10n) => l10n.sub_communityMemoryDesc,
};

final _registerNames = <String, String Function(AppLocalizations)>{
  'Intimate': (l10n) => l10n.register_intimate,
  'Informal / Casual': (l10n) => l10n.register_casual,
  'Consultative': (l10n) => l10n.register_consultative,
  'Formal / Official': (l10n) => l10n.register_formal,
  'Ceremonial': (l10n) => l10n.register_ceremonial,
  'Elder / Authority': (l10n) => l10n.register_elderAuthority,
  'Religious / Worship': (l10n) => l10n.register_religiousWorship,
};
