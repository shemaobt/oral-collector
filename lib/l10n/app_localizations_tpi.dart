// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tok Pisin (`tpi`).
class AppLocalizationsTpi extends AppLocalizations {
  AppLocalizationsTpi([String locale = 'tpi']) : super(locale);

  @override
  String get appTitle => 'Oral Collector';

  @override
  String get nav_home => 'Haus';

  @override
  String get nav_record => 'Rekodim';

  @override
  String get nav_recordings => 'Ol Rekoding';

  @override
  String get nav_projects => 'Ol Projek';

  @override
  String get nav_profile => 'Profail';

  @override
  String get nav_admin => 'Admin';

  @override
  String get nav_collapse => 'Pasim';

  @override
  String get common_cancel => 'Lusim';

  @override
  String get common_save => 'Sevim';

  @override
  String get common_delete => 'Rausim';

  @override
  String get common_remove => 'Rausim';

  @override
  String get common_create => 'Wokim';

  @override
  String get common_continue => 'Go het';

  @override
  String get common_next => 'Neks';

  @override
  String get common_retry => 'Traim gen';

  @override
  String get common_move => 'Muvim';

  @override
  String get common_invite => 'Singautim';

  @override
  String get common_download => 'Kisim i kam daun';

  @override
  String get common_clear => 'Klinim';

  @override
  String get common_untitled => 'I no gat nem';

  @override
  String get common_loading => 'Lodim...';

  @override
  String get auth_oralCollector => 'Oral Collector';

  @override
  String get auth_byShema => 'long Shema';

  @override
  String get auth_heroTagline => 'Lukautim ol vois.\nSerim ol stori.';

  @override
  String get auth_welcomeBack => 'Welkam\nBek';

  @override
  String get auth_welcome => 'Welkam ';

  @override
  String get auth_back => 'Go bek';

  @override
  String get auth_createWord => 'Wokim ';

  @override
  String get auth_createNewline => 'Wokim\n';

  @override
  String get auth_account => 'Akaun';

  @override
  String get auth_signInSubtitle => 'Sainim in bilong kisim moa stori.';

  @override
  String get auth_signUpSubtitle =>
      'Joinim komuniti bilong ol man i bungim stori.';

  @override
  String get auth_backToSignIn => 'Go bek long sain in';

  @override
  String get auth_emailLabel => 'Imel Adres';

  @override
  String get auth_emailHint => 'yu@imel.com';

  @override
  String get auth_emailRequired => 'Plis putim imel bilong yu';

  @override
  String get auth_emailInvalid => 'Plis putim wanpela stretpela imel';

  @override
  String get auth_passwordLabel => 'Paswod';

  @override
  String get auth_passwordHint => '6-pela leta o moa';

  @override
  String get auth_passwordRequired => 'Plis putim paswod bilong yu';

  @override
  String get auth_passwordTooShort => 'Paswod i mas gat 6-pela leta o moa';

  @override
  String get auth_confirmPasswordLabel => 'Konfemim Paswod';

  @override
  String get auth_confirmPasswordHint => 'Putim paswod gen';

  @override
  String get auth_confirmPasswordRequired => 'Plis konfemim paswod bilong yu';

  @override
  String get auth_confirmPasswordMismatch => 'Ol paswod i no wankain';

  @override
  String get auth_nameLabel => 'Nem';

  @override
  String get auth_nameHint => 'Ful nem bilong yu';

  @override
  String get auth_nameRequired => 'Plis putim nem bilong yu';

  @override
  String get auth_signIn => 'Sain In';

  @override
  String get auth_signUp => 'Rejista';

  @override
  String get auth_noAccount => 'Yu no gat akaun? ';

  @override
  String get auth_haveAccount => 'Yu gat akaun pinis? ';

  @override
  String get auth_continueButton => 'Go het';

  @override
  String get home_greetingMorning => 'Moning tru';

  @override
  String get home_greetingAfternoon => 'Apinun tru';

  @override
  String get home_greetingEvening => 'Gut nait';

  @override
  String home_greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get home_subtitle => 'Yumi serim ol stori bilong yu tude';

  @override
  String get home_switchProject => 'Senisim projek';

  @override
  String get home_genres => 'Ol Kain';

  @override
  String get home_loadingProjects => 'Lodim ol projek...';

  @override
  String get home_loadingGenres => 'Lodim ol kain...';

  @override
  String get home_noGenres => 'I no gat kain i stap yet';

  @override
  String get home_noProjectTitle => 'Makim wanpela projek bilong stat';

  @override
  String get home_browseProjects => 'Lukim Ol Projek';

  @override
  String get stats_recordings => 'ol rekoding';

  @override
  String get stats_recorded => 'rekodim pinis';

  @override
  String get stats_members => 'ol memba';

  @override
  String get project_switchTitle => 'Senisim Projek';

  @override
  String get project_projects => 'Ol Projek';

  @override
  String get project_subtitle => 'Lukautim ol koleksen bilong yu';

  @override
  String get project_noProjectsTitle => 'I no gat projek yet';

  @override
  String get project_noProjectsSubtitle =>
      'Wokim fes projek bilong yu bilong stat bungim ol stori.';

  @override
  String get project_newProject => 'Nupela Projek';

  @override
  String get project_projectName => 'Nem bilong Projek';

  @override
  String get project_projectNameHint => 'olsem. Kosrae Baibel Tanim Tok';

  @override
  String get project_projectNameRequired => 'Nem bilong projek i mas i stap';

  @override
  String get project_description => 'Tok piksa';

  @override
  String get project_descriptionHint => 'Sapos yu laik';

  @override
  String get project_language => 'Tokples';

  @override
  String get project_selectLanguage => 'Makim wanpela tokples';

  @override
  String get project_pleaseSelectLanguage => 'Plis makim wanpela tokples';

  @override
  String get project_createProject => 'Wokim Projek';

  @override
  String get project_selectLanguageTitle => 'Makim Tokples';

  @override
  String get project_addLanguageTitle => 'Putim Tokples';

  @override
  String get project_addLanguageSubtitle =>
      'Yu no painim tokples bilong yu? Putim hia.';

  @override
  String get project_languageName => 'Nem bilong Tokples';

  @override
  String get project_languageNameHint => 'olsem. Kosrae';

  @override
  String get project_languageNameRequired => 'Nem i mas i stap';

  @override
  String get project_languageCode => 'Kod bilong Tokples';

  @override
  String get project_languageCodeHint => 'olsem. kos (ISO 639-3)';

  @override
  String get project_languageCodeRequired => 'Kod i mas i stap';

  @override
  String get project_languageCodeTooLong => 'Kod i mas gat 1 inap 3 leta';

  @override
  String get project_addLanguage => 'Putim Tokples';

  @override
  String get project_noLanguagesFound => 'I no painim tokples';

  @override
  String get project_addNewLanguage => 'Putim nupela tokples';

  @override
  String project_addAsNewLanguage(String query) {
    return 'Putim \"$query\" olsem nupela tokples';
  }

  @override
  String get project_searchLanguages => 'Painim ol tokples...';

  @override
  String get project_backToList => 'Go bek long lis';

  @override
  String get projectSettings_title => 'Seting bilong Projek';

  @override
  String get projectSettings_details => 'Ol Deteil';

  @override
  String get projectSettings_saving => 'Sevim...';

  @override
  String get projectSettings_saveChanges => 'Sevim Ol Senis';

  @override
  String get projectSettings_updated => 'Projek i apdet pinis';

  @override
  String get projectSettings_noPermission =>
      'Yu no gat pemisin bilong apdet dispela projek';

  @override
  String get projectSettings_team => 'Tim';

  @override
  String get projectSettings_removeMember => 'Rausim Memba';

  @override
  String projectSettings_removeMemberConfirm(String name) {
    return 'Rausim $name long dispela projek?';
  }

  @override
  String get projectSettings_memberRemoved => 'Memba i raus pinis';

  @override
  String get projectSettings_memberRemoveFailed => 'No inap rausim memba';

  @override
  String get projectSettings_inviteSent => 'Invitesen i salim pinis';

  @override
  String get projectSettings_noMembers => 'I no gat memba yet';

  @override
  String get recording_selectGenre => 'Makim Kain';

  @override
  String get recording_selectGenreSubtitle =>
      'Makim wanpela kain bilong stori bilong yu';

  @override
  String get recording_selectSubcategory => 'Makim Sabkategori';

  @override
  String get recording_selectSubcategorySubtitle => 'Makim wanpela sabkategori';

  @override
  String get recording_selectRegister => 'Makim Rejista';

  @override
  String get recording_selectRegisterSubtitle => 'Makim pasin bilong toktok';

  @override
  String get recording_recordingStep => 'Rekodim';

  @override
  String get recording_recordingStepSubtitle => 'Rekodim stori bilong yu';

  @override
  String get recording_reviewStep => 'Lukim Rekoding';

  @override
  String get recording_reviewStepSubtitle => 'Harim na sevim';

  @override
  String get recording_genreNotFound => 'Kain i no stap';

  @override
  String get recording_noGenres => 'I no gat kain i stap';

  @override
  String get recording_noSubcategories => 'I no gat sabkategori i stap';

  @override
  String get recording_registerDescription =>
      'Makim pasin bilong toktok we i stret long ton na fomol bilong dispela rekoding.';

  @override
  String get recording_titleHint => 'Putim nem (sapos yu laik)';

  @override
  String get recording_saveRecording => 'Sevim Rekoding';

  @override
  String get recording_recordAgain => 'Rekodim Gen';

  @override
  String get recording_discard => 'Tromoi';

  @override
  String get recording_discardTitle => 'Tromoi Rekoding?';

  @override
  String get recording_discardMessage => 'Dispela rekoding bai lus olgeta.';

  @override
  String get recording_saved => 'Rekoding i sev pinis';

  @override
  String get recording_notFound => 'Rekoding i no stap';

  @override
  String get recording_unknownGenre => 'Kain i no save';

  @override
  String get recording_splitRecording => 'Brukim Rekoding';

  @override
  String get recording_moveCategory => 'Muvim Kategori';

  @override
  String get recording_downloadAudio => 'Kisim Audio i Kam Daun';

  @override
  String get recording_downloadAudioMessage =>
      'Audio fail i no stap long dispela divais. Yu laik kisim i kam daun bilong katim?';

  @override
  String recording_downloadFailed(String error) {
    return 'No inap kisim i kam daun: $error';
  }

  @override
  String get recording_audioNotAvailable => 'Audio fail i no stap';

  @override
  String get recording_deleteTitle => 'Rausim Rekoding';

  @override
  String get recording_deleteMessage =>
      'Dispela bai rausim dispela rekoding olgeta long divais bilong yu. Sapos em i go antap pinis, em bai lus long seva tu. Dispela aksen i no inap senisim bek.';

  @override
  String get recording_deleteNoPermission =>
      'Yu no gat pemisin bilong rausim dispela rekoding';

  @override
  String get recording_deleteFailed => 'No inap rausim rekoding';

  @override
  String get recording_deleteFailedLocal =>
      'No inap rausim long seva. Rausim long lokal.';

  @override
  String get recording_cleaningStatusFailed =>
      'No inap apdet klining stetas long seva';

  @override
  String get recording_updateNoPermission =>
      'Yu no gat pemisin bilong apdet dispela rekoding';

  @override
  String get recording_moveNoPermission =>
      'Yu no gat pemisin bilong muvim dispela rekoding';

  @override
  String get recording_movedSuccess => 'Rekoding i muv pinis';

  @override
  String get recording_updateFailed => 'No inap apdet long seva';

  @override
  String get recordings_title => 'Ol Rekoding';

  @override
  String get recordings_subtitle => 'Ol stori yu bungim';

  @override
  String get recordings_importAudio => 'Importim audio fail';

  @override
  String get recordings_selectProject => 'Makim wanpela projek';

  @override
  String get recordings_selectProjectSubtitle =>
      'Makim wanpela projek bilong lukim ol rekoding';

  @override
  String get recordings_noRecordings => 'I no gat rekoding yet';

  @override
  String get recordings_noRecordingsSubtitle =>
      'Presim maikorofon bilong rekodim fes stori bilong yu, o importim wanpela audio fail.';

  @override
  String recordings_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rekoding',
      one: '1 rekoding',
    );
    return '$_temp0';
  }

  @override
  String get recording_statusUploaded => 'Go antap pinis';

  @override
  String get recording_statusUploading => 'I go antap';

  @override
  String get recording_statusFailed => 'No inap';

  @override
  String get recording_statusLocal => 'Lokal';

  @override
  String get recordings_clearStale => 'Klinim ol i pundaun';

  @override
  String get recordings_clearStaleMessage =>
      'Dispela bai rausim olgeta rekoding we i pundaun o i pas long salim i go antap long seva. Dispela aksen i no inap senisim bek.';

  @override
  String recordings_clearedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Klinim $count rekoding',
      one: 'Klinim 1 rekoding',
      zero: 'I no painim ol olpela rekoding',
    );
    return '$_temp0';
  }

  @override
  String get recordings_clearFailed => 'No inap klinim ol rekoding';

  @override
  String get trim_title => 'Brukim Rekoding';

  @override
  String get trim_notFound => 'Rekoding i no stap';

  @override
  String get trim_audioUrlNotAvailable =>
      'Audio URL i no stap bilong dispela rekoding.';

  @override
  String get trim_localNotAvailable =>
      'Lokal audio fail i no stap. Kisim rekoding i kam daun pastaim.';

  @override
  String get trim_atLeastOneSegment => 'Wanpela segment i mas stap';

  @override
  String get trim_segments => 'Ol Segment';

  @override
  String get trim_restoreAll => 'Stretim bek olgeta';

  @override
  String get trim_instructions =>
      'Presim long wevfom antap bilong putim\nol maka bilong brukim dispela rekoding';

  @override
  String get trim_splitting => 'Brukim...';

  @override
  String trim_saveSegments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sevim $count segment',
      one: 'Sevim 1 segment',
    );
    return '$_temp0';
  }

  @override
  String get trim_addSplitsFirst => 'Putim ol brukim pastaim';

  @override
  String trim_savedSegments(int kept, int removed) {
    return 'Sevim $kept segment, rausim $removed';
  }

  @override
  String trim_splitInto(int count) {
    return 'Brukim i go long $count rekoding';
  }

  @override
  String get import_title => 'Importim Audio';

  @override
  String get import_selectGenre => 'Makim Kain';

  @override
  String get import_selectSubcategory => 'Makim Sabkategori';

  @override
  String get import_selectRegister => 'Makim Rejista';

  @override
  String get import_confirmImport => 'Konfemim Import';

  @override
  String get import_analyzing => 'Lukluk gut long audio fail...';

  @override
  String get import_selectFile => 'Makim wanpela audio fail bilong importim';

  @override
  String get import_chooseFile => 'Makim Fail';

  @override
  String get import_accessFailed => 'No inap opim fail yu makim';

  @override
  String import_pickError(String error) {
    return 'Hevi long makim fail: $error';
  }

  @override
  String import_saveError(String error) {
    return 'Hevi long sevim fail: $error';
  }

  @override
  String get import_unknownFile => 'Fail i no save';

  @override
  String get import_importAndSave => 'Importim na Sevim';

  @override
  String get moveCategory_title => 'Muvim Kategori';

  @override
  String get moveCategory_genre => 'Kain';

  @override
  String get moveCategory_subcategory => 'Sabkategori';

  @override
  String get moveCategory_selectSubcategory => 'Makim sabkategori';

  @override
  String get cleaning_needsCleaning => 'I Nidim Klining';

  @override
  String get cleaning_cleaning => 'Klinim...';

  @override
  String get cleaning_cleaned => 'Klin pinis';

  @override
  String get cleaning_cleanFailed => 'Klining i pundaun';

  @override
  String get sync_uploading => 'I go antap...';

  @override
  String sync_pending(int count) {
    return '$count i wet';
  }

  @override
  String get profile_photoUpdated => 'Profail foto i apdet pinis';

  @override
  String profile_photoFailed(String error) {
    return 'No inap apdet foto: $error';
  }

  @override
  String get profile_editName => 'Senisim nem bilong yu';

  @override
  String get profile_nameHint => 'Nem bilong yu';

  @override
  String get profile_nameUpdated => 'Nem i apdet pinis';

  @override
  String get profile_syncStorage => 'Singk na Storis';

  @override
  String get profile_about => 'Tok piksa';

  @override
  String get profile_appVersion => 'Vesen bilong ep';

  @override
  String get profile_byShema => 'Oral Collector long Shema';

  @override
  String get profile_administration => 'Administresen';

  @override
  String get profile_adminDashboard => 'Admin Dasbot';

  @override
  String get profile_adminSubtitle =>
      'Sistem stets, ol projek na lukautim ol kain';

  @override
  String get profile_account => 'Akaun';

  @override
  String get profile_logOut => 'Lusim';

  @override
  String get profile_deleteAccount => 'Rausim Akaun';

  @override
  String get profile_deleteAccountConfirm => 'Orait Long Rausim';

  @override
  String get profile_deleteAccountWarning =>
      'Dispela samting i stap oltaim na yu no inap senisim bek. Akaun bilong yu bai lus, tasol ol rekoding yu bin salim bai stap yet long ol projek bilong tok ples.';

  @override
  String get profile_typeDelete =>
      'Taitim DELETE bilong orait long rausim akaun:';

  @override
  String get profile_clearCacheTitle => 'Klinim lokal kes?';

  @override
  String get profile_clearCacheMessage =>
      'Dispela bai rausim olgeta rekoding i stap long lokal. Ol rekoding i go antap pinis long seva bai i stap.';

  @override
  String get profile_cacheCleared => 'Lokal kes i klin pinis';

  @override
  String profile_joinedSuccess(String name) {
    return 'Join long \"$name\" pinis';
  }

  @override
  String get profile_inviteDeclined => 'Invitesen i no orait';

  @override
  String get profile_language => 'Tokples';

  @override
  String get profile_online => 'Onlain';

  @override
  String get profile_offline => 'Oflain';

  @override
  String profile_lastSync(String time) {
    return 'Las singk: $time';
  }

  @override
  String get profile_neverSynced => 'I no singk yet';

  @override
  String profile_pendingCount(int count) {
    return '$count i wet';
  }

  @override
  String profile_syncingProgress(int percent) {
    return 'Singkim... $percent%';
  }

  @override
  String get profile_syncNow => 'Singkim Nau';

  @override
  String get profile_wifiOnly => 'Salim long Wi-Fi tasol';

  @override
  String get profile_wifiOnlySubtitle => 'No ken salim long mobal data';

  @override
  String get profile_autoRemove => 'Rausim otomatik bihain long salim';

  @override
  String get profile_autoRemoveSubtitle =>
      'Rausim lokal fail bihain long i go antap pinis';

  @override
  String get profile_clearCache => 'Klinim lokal kes';

  @override
  String get profile_clearCacheSubtitle => 'Rausim olgeta lokal rekoding';

  @override
  String get profile_invitations => 'Ol Invitesen';

  @override
  String get profile_refreshInvitations => 'Rifresim ol invitesen';

  @override
  String get profile_noInvitations => 'I no gat invitesen i wet';

  @override
  String get profile_roleManager => 'Rol: Maneja';

  @override
  String get profile_roleMember => 'Rol: Memba';

  @override
  String get profile_decline => 'No laik';

  @override
  String get profile_accept => 'Orait';

  @override
  String get profile_storage => 'Storis';

  @override
  String get profile_status => 'Stetas';

  @override
  String get profile_pendingLabel => 'I wet';

  @override
  String get admin_title => 'Admin Dasbot';

  @override
  String get admin_overview => 'Ova Viu';

  @override
  String get admin_projects => 'Ol Projek';

  @override
  String get admin_genres => 'Ol Kain';

  @override
  String get admin_cleaning => 'Klining';

  @override
  String get admin_accessRequired => 'Admin akses i nidim';

  @override
  String get admin_totalProjects => 'Olgeta Projek';

  @override
  String get admin_languages => 'Ol Tokples';

  @override
  String get admin_recordings => 'Ol Rekoding';

  @override
  String get admin_totalHours => 'Olgeta Aua';

  @override
  String get admin_activeUsers => 'Ol Aktiv Yusa';

  @override
  String get admin_projectName => 'Nem';

  @override
  String get admin_projectLanguage => 'Tokples';

  @override
  String get admin_projectMembers => 'Ol Memba';

  @override
  String get admin_projectRecordings => 'Ol Rekoding';

  @override
  String get admin_projectDuration => 'Hamas longpela taim';

  @override
  String get admin_projectCreated => 'Wokim long';

  @override
  String get admin_noProjects => 'I no painim projek';

  @override
  String get admin_unknownLanguage => 'Tokples i no save';

  @override
  String get admin_genresAndSubcategories => 'Ol Kain na Sabkategori';

  @override
  String get admin_addGenre => 'Putim Kain';

  @override
  String get admin_noGenres => 'I no painim kain';

  @override
  String get admin_genreName => 'Nem bilong Kain';

  @override
  String get admin_required => 'I mas i stap';

  @override
  String get admin_descriptionOptional => 'Tok piksa (sapos yu laik)';

  @override
  String get admin_genreCreated => 'Kain i wokim pinis';

  @override
  String get admin_editGenre => 'Senisim kain';

  @override
  String get admin_deleteGenre => 'Rausim kain';

  @override
  String get admin_addSubcategory => 'Putim sabkategori';

  @override
  String get admin_editGenreTitle => 'Senisim Kain';

  @override
  String get admin_genreUpdated => 'Kain i apdet pinis';

  @override
  String get admin_deleteGenreTitle => 'Rausim Kain';

  @override
  String admin_deleteGenreConfirm(String name) {
    return 'Rausim \"$name\" na olgeta sabkategori bilong em?';
  }

  @override
  String get admin_genreDeleted => 'Kain i raus pinis';

  @override
  String admin_addSubcategoryTo(String name) {
    return 'Putim Sabkategori long $name';
  }

  @override
  String get admin_subcategoryName => 'Nem bilong Sabkategori';

  @override
  String get admin_subcategoryCreated => 'Sabkategori i wokim pinis';

  @override
  String get admin_deleteSubcategory => 'Rausim Sabkategori';

  @override
  String admin_deleteSubcategoryConfirm(String name) {
    return 'Rausim \"$name\"?';
  }

  @override
  String get admin_subcategoryDeleted => 'Sabkategori i raus pinis';

  @override
  String get admin_cleaningQueue => 'Klu bilong Klinim Audio';

  @override
  String admin_cleanSelected(int count) {
    return 'Klinim Ol i Makim ($count)';
  }

  @override
  String get admin_refreshCleaning => 'Rifresim klu bilong klining';

  @override
  String get admin_cleaningWebOnly =>
      'Klining bilong audio em bilong web tasol. Klining proses i ran long seva.';

  @override
  String get admin_noCleaningRecordings =>
      'I no gat rekoding i makim bilong klining';

  @override
  String get admin_cleaningTitle => 'Nem';

  @override
  String get admin_cleaningDuration => 'Hamas longpela taim';

  @override
  String get admin_cleaningSize => 'Sais';

  @override
  String get admin_cleaningFormat => 'Fomet';

  @override
  String get admin_cleaningRecorded => 'Rekodim long';

  @override
  String get admin_cleaningActions => 'Ol Aksen';

  @override
  String get admin_clean => 'Klinim';

  @override
  String get admin_deselectAll => 'Rausim makim olgeta';

  @override
  String get admin_selectAll => 'Makim Olgeta';

  @override
  String get admin_cleaningTriggered => 'Klining i stat';

  @override
  String get admin_cleaningFailed => 'Klining i no inap stat';

  @override
  String admin_cleaningPartial(int success, int total) {
    return 'Klining i stat long $success bilong $total rekoding';
  }

  @override
  String get genre_title => 'Kain';

  @override
  String get genre_notFound => 'Kain i no stap';

  @override
  String genre_recordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rekoding',
      one: '1 rekoding',
    );
    return '$_temp0';
  }

  @override
  String get format_justNow => 'nau tasol';

  @override
  String format_minutesAgo(int count) {
    return '${count}m i go pinis';
  }

  @override
  String format_hoursAgo(int count) {
    return '${count}h i go pinis';
  }

  @override
  String format_daysAgo(int count) {
    return '${count}d i go pinis';
  }

  @override
  String format_weeksAgo(int count) {
    return '${count}w i go pinis';
  }

  @override
  String format_monthsAgo(int count) {
    return '${count}m i go pinis';
  }

  @override
  String format_memberSince(String date) {
    return 'Memba stat long $date';
  }

  @override
  String get format_member => 'Memba';

  @override
  String format_dateAt(String date, String time) {
    return '$date long $time';
  }

  @override
  String get genre_narrative => 'Stori';

  @override
  String get genre_narrativeDesc =>
      'Ol stori, tok save, na ol pasin bilong tokim stori long maus';

  @override
  String get genre_poeticSong => 'Poem / Singsing';

  @override
  String get genre_poeticSongDesc =>
      'Ol singsing na poem bilong maus, olsem ol him, singsing sori, na tok piksa bilong save';

  @override
  String get genre_instructional => 'Skulim / Lo';

  @override
  String get genre_instructionalDesc =>
      'Ol lo, pasin bilong lotu, wei bilong mekim, na ol skulim';

  @override
  String get genre_oralDiscourse => 'Tok bilong Maus';

  @override
  String get genre_oralDiscourseDesc =>
      'Ol toktok, skulim, beten, na ol kain tok bilong maus';

  @override
  String get sub_historicalNarrative => 'Stori bilong Bipo';

  @override
  String get sub_personalAccount => 'Stori bilong Mi Yet / Witnes';

  @override
  String get sub_parable => 'Tok Piksa / Stori bilong Skulim';

  @override
  String get sub_originStory => 'Stori bilong Stat / Kamapim';

  @override
  String get sub_legend => 'Stori bilong Bikman';

  @override
  String get sub_visionNarrative => 'Stori bilong Visen o Driman';

  @override
  String get sub_genealogy => 'Lain bilong Tumbuna';

  @override
  String get sub_eventReport => 'Ripot bilong Samting i Kamap';

  @override
  String get sub_hymn => 'Him / Singsing bilong Lotu';

  @override
  String get sub_lament => 'Singsing Sori';

  @override
  String get sub_funeralDirge => 'Singsing bilong Man i Dai';

  @override
  String get sub_victorySong => 'Singsing bilong Win / Amamas';

  @override
  String get sub_loveSong => 'Singsing bilong Laikim';

  @override
  String get sub_tauntSong => 'Singsing bilong Tok Bilas';

  @override
  String get sub_blessing => 'Blesing';

  @override
  String get sub_curse => 'Tok Nogut';

  @override
  String get sub_wisdomPoem => 'Poem bilong Save / Tok Piksa';

  @override
  String get sub_didacticPoetry => 'Poem bilong Skulim';

  @override
  String get sub_legalCode => 'Lo / Rul';

  @override
  String get sub_ritual => 'Pasin bilong Lotu';

  @override
  String get sub_procedure => 'Wei bilong Mekim';

  @override
  String get sub_listInventory => 'Lis / Kaunim';

  @override
  String get sub_propheticOracle => 'Tok Profet / Toktok';

  @override
  String get sub_exhortation => 'Tok Strongim / Tok Save';

  @override
  String get sub_wisdomTeaching => 'Skulim bilong Save';

  @override
  String get sub_prayer => 'Beten';

  @override
  String get sub_dialogue => 'Toktok';

  @override
  String get sub_epistle => 'Pas / Leta';

  @override
  String get sub_apocalypticDiscourse => 'Tok bilong Las De';

  @override
  String get sub_ceremonialSpeech => 'Tok bilong Seremoni';

  @override
  String get sub_communityMemory => 'Tingting bilong Komuniti';

  @override
  String get sub_historicalNarrativeDesc =>
      'Ol stori bilong ol samting i kamap bipo, ol pait, na ol bikpela taim';

  @override
  String get sub_personalAccountDesc =>
      'Ol stori bilong laip bilong mi yet na bilip';

  @override
  String get sub_parableDesc => 'Ol tok piksa bilong skulim gutpela pasin';

  @override
  String get sub_originStoryDesc =>
      'Ol stori bilong olsem wanem ol samting i kamap';

  @override
  String get sub_legendDesc =>
      'Ol stori bilong ol bikman na ol bikpela wok bilong ol';

  @override
  String get sub_visionNarrativeDesc =>
      'Ol stori bilong ol visen na driman bilong God';

  @override
  String get sub_genealogyDesc =>
      'Ol rekod bilong lain bilong famili na tumbuna';

  @override
  String get sub_eventReportDesc =>
      'Ol ripot bilong ol samting i kamap nau tasol long komuniti';

  @override
  String get sub_hymnDesc => 'Ol singsing bilong litimapim na lotu long God';

  @override
  String get sub_lamentDesc => 'Ol tok bilong sori, bel hevi, na krai';

  @override
  String get sub_funeralDirgeDesc =>
      'Ol singsing bilong taim bilong krai na planim man i dai';

  @override
  String get sub_victorySongDesc => 'Ol singsing bilong amamas na win';

  @override
  String get sub_loveSongDesc => 'Ol singsing bilong soim laikim';

  @override
  String get sub_tauntSongDesc => 'Ol singsing bilong tok bilas long ol birua';

  @override
  String get sub_blessingDesc =>
      'Ol tok bilong askim God long gutpela pasin na lukautim';

  @override
  String get sub_curseDesc => 'Ol tok bilong jajmen na hevi bilong God';

  @override
  String get sub_wisdomPoemDesc => 'Ol sotpela tok na poem bilong givim save';

  @override
  String get sub_didacticPoetryDesc =>
      'Ol poem i wokim bilong skulim na givim save';

  @override
  String get sub_legalCodeDesc => 'Ol rul, lo, na ol tok bilong kontrak';

  @override
  String get sub_ritualDesc => 'Ol pasin bilong lotu na ol seremoni bilong God';

  @override
  String get sub_procedureDesc =>
      'Ol stret tok na wei bilong mekim step balong step';

  @override
  String get sub_listInventoryDesc => 'Ol lis, kaunim man, na ol rekod';

  @override
  String get sub_propheticOracleDesc => 'Ol tok i kam long nem bilong God';

  @override
  String get sub_exhortationDesc =>
      'Ol toktok bilong strongim man long gutpela pasin';

  @override
  String get sub_wisdomTeachingDesc =>
      'Skulim bilong sindaun gut na stretpela laip';

  @override
  String get sub_prayerDesc => 'Ol tok i go long God long lotu o askim';

  @override
  String get sub_dialogueDesc => 'Ol toktok namel long ol man';

  @override
  String get sub_epistleDesc => 'Ol pas i go long ol komuniti o wan wan man';

  @override
  String get sub_apocalypticDiscourseDesc =>
      'Ol tok i soim las taim na plen bilong God';

  @override
  String get sub_ceremonialSpeechDesc => 'Ol bikpela tok bilong ol seremoni';

  @override
  String get sub_communityMemoryDesc =>
      'Ol tingting bilong komuniti i lukautim hu ol i stap';

  @override
  String get register_intimate => 'Klostu tru';

  @override
  String get register_casual => 'Nating nating';

  @override
  String get register_consultative => 'Askim tingting';

  @override
  String get register_formal => 'Fomol';

  @override
  String get register_ceremonial => 'Bilong Seremoni';

  @override
  String get register_elderAuthority => 'Bikman / Hetman';

  @override
  String get register_religiousWorship => 'Bilong Lotu';

  @override
  String get locale_english => 'English';

  @override
  String get locale_portuguese => 'Português';

  @override
  String get locale_hindi => 'हिन्दी';

  @override
  String get locale_korean => '한국어';

  @override
  String get locale_spanish => 'Español';

  @override
  String get locale_bahasa => 'Bahasa Indonesia';

  @override
  String get locale_french => 'Français';

  @override
  String get locale_tokPisin => 'Tok Pisin';

  @override
  String get locale_swahili => 'Kiswahili';

  @override
  String get locale_arabic => 'العربية';

  @override
  String get locale_englishSub => 'Tokples Inglis';

  @override
  String get locale_portugueseSub => 'Tokples Potugis';

  @override
  String get locale_hindiSub => 'Tokples Hindi';

  @override
  String get locale_koreanSub => 'Tokples Korian';

  @override
  String get locale_spanishSub => 'Tokples Spaenis';

  @override
  String get locale_bahasaSub => 'Tokples Indonisia';

  @override
  String get locale_frenchSub => 'Tokples Frens';

  @override
  String get locale_tokPisinSub => 'Tok Pisin';

  @override
  String get locale_swahiliSub => 'Tokples Swahili';

  @override
  String get locale_arabicSub => 'Tokples Arabik';

  @override
  String get locale_chinese => '中文';

  @override
  String get locale_chineseSub => 'Saina';

  @override
  String get locale_selectLanguage => 'Makim Tokples bilong Yu';

  @override
  String get locale_selectLanguageSubtitle =>
      'Yu ken senisim dispela bihain long profail seting.';

  @override
  String get filter_all => 'Olgeta';

  @override
  String get filter_pending => 'I wet';

  @override
  String get filter_uploaded => 'Go antap pinis';

  @override
  String get filter_needsCleaning => 'I Nidim Klining';

  @override
  String get filter_unclassified => 'I no makim kain yet';

  @override
  String get filter_allGenres => 'Olgeta kain';

  @override
  String get detail_duration => 'Hamas longpela taim';

  @override
  String get detail_size => 'Sais';

  @override
  String get detail_format => 'Fomet';

  @override
  String get detail_status => 'Stetas';

  @override
  String get detail_upload => 'Salim i go antap';

  @override
  String get detail_uploaded => 'Go antap pinis';

  @override
  String get detail_cleaning => 'Klining';

  @override
  String get detail_recorded => 'Rekodim long';

  @override
  String get detail_retry => 'Traim gen';

  @override
  String get detail_notFlagged => 'I no makim';

  @override
  String get detail_uploadStuck => 'I pas — presim Traim gen';

  @override
  String get detail_uploading => 'I go antap...';

  @override
  String get detail_maxRetries => 'Maks traim — presim Traim gen';

  @override
  String get detail_uploadFailed => 'Salim i go antap i pundaun';

  @override
  String get detail_pendingRetried => 'I wet (traim gen pinis)';

  @override
  String get detail_notSynced => 'I no singk yet';

  @override
  String get action_actions => 'Ol Aksen';

  @override
  String get action_split => 'Brukim';

  @override
  String get action_flagClean => 'Makim Klinim';

  @override
  String get action_clearFlag => 'Rausim Makim';

  @override
  String get action_move => 'Muvim';

  @override
  String get action_delete => 'Rausim';

  @override
  String get projectStats_recordings => 'Ol Rekoding';

  @override
  String get projectStats_duration => 'Hamas longpela taim';

  @override
  String get projectStats_members => 'Ol Memba';

  @override
  String get project_active => 'Aktiv';

  @override
  String get recording_paused => 'I stop';

  @override
  String get recording_recording => 'Rekodim';

  @override
  String get recording_tapToRecord => 'Presim bilong Rekodim';

  @override
  String get recording_sensitivity => 'Sensitiviti';

  @override
  String get recording_sensitivityLow => 'Lo';

  @override
  String get recording_sensitivityMed => 'Namel';

  @override
  String get recording_sensitivityHigh => 'Antap';

  @override
  String get recording_stopRecording => 'Stopim rekodim';

  @override
  String get recording_stop => 'Stop';

  @override
  String get recording_resume => 'Stat gen';

  @override
  String get recording_pause => 'Stopim liklik';

  @override
  String get quickRecord_title => 'Rekodim Hariap';

  @override
  String get quickRecord_subtitle => 'Makim kain bihain';

  @override
  String get quickRecord_classifyLater => 'Makim kain bihain';

  @override
  String get classify_title => 'Makim Kain bilong Rekoding';

  @override
  String get classify_action => 'Makim Kain';

  @override
  String get classify_banner =>
      'Dispela rekoding i mas gat kain pastaim bilong salim i go antap.';

  @override
  String get classify_success => 'Rekoding i gat kain pinis';

  @override
  String get classify_register => 'Rejista (sapos yu laik)';

  @override
  String get classify_selectRegister => 'Makim rejista';

  @override
  String get recording_unclassified => 'I no makim kain yet';

  @override
  String get fab_quickRecord => 'Hariap';

  @override
  String get fab_normalRecord => 'Rekodim';
}
