// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appTitle => 'Oral Collector';

  @override
  String get nav_home => 'Nyumbani';

  @override
  String get nav_record => 'Rekodi';

  @override
  String get nav_recordings => 'Rekodi';

  @override
  String get nav_projects => 'Miradi';

  @override
  String get nav_profile => 'Wasifu';

  @override
  String get nav_admin => 'Msimamizi';

  @override
  String get nav_collapse => 'Kunja';

  @override
  String get common_cancel => 'Ghairi';

  @override
  String get common_save => 'Hifadhi';

  @override
  String get common_delete => 'Futa';

  @override
  String get common_remove => 'Ondoa';

  @override
  String get common_create => 'Unda';

  @override
  String get common_continue => 'Endelea';

  @override
  String get common_next => 'Ifuatayo';

  @override
  String get common_retry => 'Jaribu tena';

  @override
  String get common_move => 'Hamisha';

  @override
  String get common_invite => 'Alika';

  @override
  String get common_download => 'Pakua';

  @override
  String get common_clear => 'Futa';

  @override
  String get common_untitled => 'Bila kichwa';

  @override
  String get common_loading => 'Inapakia...';

  @override
  String get auth_oralCollector => 'Oral Collector';

  @override
  String get auth_byShema => 'na Shema';

  @override
  String get auth_heroTagline => 'Hifadhi sauti.\nShiriki hadithi.';

  @override
  String get auth_welcomeBack => 'Karibu\nTena';

  @override
  String get auth_welcome => 'Karibu ';

  @override
  String get auth_back => 'Rudi';

  @override
  String get auth_createWord => 'Unda ';

  @override
  String get auth_createNewline => 'Unda\n';

  @override
  String get auth_account => 'Akaunti';

  @override
  String get auth_signInSubtitle => 'Ingia ili kuendelea kukusanya hadithi.';

  @override
  String get auth_signUpSubtitle =>
      'Jiunge na jumuiya yetu ya wakusanyaji wa hadithi.';

  @override
  String get auth_backToSignIn => 'Rudi kuingia';

  @override
  String get auth_emailLabel => 'Anwani ya Barua Pepe';

  @override
  String get auth_emailHint => 'yako@barua.com';

  @override
  String get auth_emailRequired => 'Tafadhali ingiza barua pepe yako';

  @override
  String get auth_emailInvalid => 'Tafadhali ingiza barua pepe halali';

  @override
  String get auth_passwordLabel => 'Nenosiri';

  @override
  String get auth_passwordHint => 'Angalau herufi 6';

  @override
  String get auth_passwordRequired => 'Tafadhali ingiza nenosiri lako';

  @override
  String get auth_passwordTooShort =>
      'Nenosiri lazima liwe na herufi 6 au zaidi';

  @override
  String get auth_confirmPasswordLabel => 'Thibitisha Nenosiri';

  @override
  String get auth_confirmPasswordHint => 'Ingiza nenosiri tena';

  @override
  String get auth_confirmPasswordRequired =>
      'Tafadhali thibitisha nenosiri lako';

  @override
  String get auth_confirmPasswordMismatch => 'Nenosiri hazilingani';

  @override
  String get auth_nameLabel => 'Jina';

  @override
  String get auth_nameHint => 'Jina lako kamili';

  @override
  String get auth_nameRequired => 'Tafadhali ingiza jina lako la kuonyesha';

  @override
  String get auth_signIn => 'Ingia';

  @override
  String get auth_signUp => 'Jisajili';

  @override
  String get auth_noAccount => 'Huna akaunti? ';

  @override
  String get auth_haveAccount => 'Una akaunti? ';

  @override
  String get auth_continueButton => 'Endelea';

  @override
  String get auth_forgotPassword => 'Umesahau nenosiri?';

  @override
  String get auth_resetPassword => 'Weka Nenosiri Upya';

  @override
  String get auth_forgotPasswordSubtitle =>
      'Ingiza barua pepe yako na tutakutumia kiungo cha kuweka upya.';

  @override
  String get auth_sendResetLink => 'Tuma Kiungo';

  @override
  String get auth_sending => 'Inatuma...';

  @override
  String get auth_checkYourEmail => 'Angalia Barua Pepe Yako';

  @override
  String auth_resetEmailSent(String email) {
    return 'Tumetuma kiungo cha kuweka upya nenosiri kwa $email. Angalia kikasha chako na ufuate kiungo ili kuweka nenosiri jipya.';
  }

  @override
  String get auth_openEmailApp => 'Fungua Barua Pepe';

  @override
  String get auth_resendEmail => 'Tuma Tena';

  @override
  String get auth_backToLogin => 'Rudi kwenye Kuingia';

  @override
  String get auth_newPassword => 'Nenosiri Jipya';

  @override
  String get auth_confirmNewPassword => 'Thibitisha Nenosiri Jipya';

  @override
  String get auth_resetPasswordSubtitle =>
      'Ingiza nenosiri lako jipya hapa chini.';

  @override
  String get auth_resetPasswordButton => 'Weka Nenosiri Upya';

  @override
  String get auth_resetting => 'Inaweka upya...';

  @override
  String get auth_resetSuccess =>
      'Nenosiri limewekwa upya kwa mafanikio! Sasa unaweza kuingia na nenosiri lako jipya.';

  @override
  String get auth_invalidResetLink => 'Kiungo si Sahihi';

  @override
  String get auth_invalidResetLinkMessage =>
      'Kiungo hiki cha kuweka upya nenosiri si sahihi au kimekwisha muda.';

  @override
  String get auth_requestNewLink => 'Omba Kiungo Kipya';

  @override
  String get home_greetingMorning => 'Habari za asubuhi';

  @override
  String get home_greetingAfternoon => 'Habari za mchana';

  @override
  String get home_greetingEvening => 'Habari za jioni';

  @override
  String home_greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get home_subtitle => 'Tushiriki hadithi zako leo';

  @override
  String get home_switchProject => 'Badilisha mradi';

  @override
  String get home_genres => 'Aina';

  @override
  String get home_loadingProjects => 'Inapakia miradi...';

  @override
  String get home_loadingGenres => 'Inapakia aina...';

  @override
  String get home_noGenres => 'Hakuna aina bado';

  @override
  String get home_noProjectTitle => 'Chagua mradi ili kuanza';

  @override
  String get home_browseProjects => 'Tazama Miradi';

  @override
  String get stats_recordings => 'rekodi';

  @override
  String get stats_recorded => 'imerekodwa';

  @override
  String get stats_members => 'wanachama';

  @override
  String get project_switchTitle => 'Badilisha Mradi';

  @override
  String get project_projects => 'Miradi';

  @override
  String get project_subtitle => 'Simamia makusanyo yako';

  @override
  String get project_noProjectsTitle => 'Hakuna miradi bado';

  @override
  String get project_noProjectsSubtitle =>
      'Unda mradi wako wa kwanza ili kuanza kukusanya hadithi za mdomo.';

  @override
  String get project_newProject => 'Mradi Mpya';

  @override
  String get project_projectName => 'Jina la Mradi';

  @override
  String get project_projectNameHint => 'mf. Tafsiri ya Biblia ya Kosrae';

  @override
  String get project_projectNameRequired => 'Jina la mradi linahitajika';

  @override
  String get project_description => 'Maelezo';

  @override
  String get project_descriptionHint => 'Si lazima';

  @override
  String get project_language => 'Lugha';

  @override
  String get project_selectLanguage => 'Chagua lugha';

  @override
  String get project_pleaseSelectLanguage => 'Tafadhali chagua lugha';

  @override
  String get project_createProject => 'Unda Mradi';

  @override
  String get project_selectLanguageTitle => 'Chagua Lugha';

  @override
  String get project_addLanguageTitle => 'Ongeza Lugha';

  @override
  String get project_addLanguageSubtitle => 'Hupati lugha yako? Iongeze hapa.';

  @override
  String get project_languageName => 'Jina la Lugha';

  @override
  String get project_languageNameHint => 'mf. Kikosrae';

  @override
  String get project_languageNameRequired => 'Jina linahitajika';

  @override
  String get project_languageCode => 'Msimbo wa Lugha';

  @override
  String get project_languageCodeHint => 'mf. kos (ISO 639-3)';

  @override
  String get project_languageCodeRequired => 'Msimbo unahitajika';

  @override
  String get project_languageCodeTooLong => 'Msimbo lazima uwe herufi 1-3';

  @override
  String get project_addLanguage => 'Ongeza Lugha';

  @override
  String get project_noLanguagesFound => 'Hakuna lugha iliyopatikana';

  @override
  String get project_addNewLanguage => 'Ongeza lugha mpya';

  @override
  String project_addAsNewLanguage(String query) {
    return 'Ongeza \"$query\" kama lugha mpya';
  }

  @override
  String get project_searchLanguages => 'Tafuta lugha...';

  @override
  String get project_backToList => 'Rudi kwenye orodha';

  @override
  String get projectSettings_title => 'Mipangilio ya Mradi';

  @override
  String get projectSettings_details => 'Maelezo';

  @override
  String get projectSettings_saving => 'Inahifadhi...';

  @override
  String get projectSettings_saveChanges => 'Hifadhi Mabadiliko';

  @override
  String get projectSettings_updated => 'Mradi umesasishwa';

  @override
  String get projectSettings_noPermission =>
      'Huna ruhusa ya kusasisha mradi huu';

  @override
  String get projectSettings_team => 'Timu';

  @override
  String get projectSettings_removeMember => 'Ondoa Mwanachama';

  @override
  String projectSettings_removeMemberConfirm(String name) {
    return 'Ondoa $name kutoka mradi huu?';
  }

  @override
  String get projectSettings_memberRemoved => 'Mwanachama ameondolewa';

  @override
  String get projectSettings_memberRemoveFailed =>
      'Imeshindwa kuondoa mwanachama';

  @override
  String get projectSettings_inviteSent => 'Mwaliko umetumwa';

  @override
  String get projectSettings_noMembers => 'Hakuna wanachama bado';

  @override
  String get recording_selectGenre => 'Chagua Aina';

  @override
  String get recording_selectGenreSubtitle => 'Chagua aina ya hadithi yako';

  @override
  String get recording_selectSubcategory => 'Chagua Aina Ndogo';

  @override
  String get recording_selectSubcategorySubtitle => 'Chagua aina ndogo';

  @override
  String get recording_selectRegister => 'Chagua Rejista';

  @override
  String get recording_selectRegisterSubtitle => 'Chagua rejista ya usemi';

  @override
  String get recording_recordingStep => 'Kurekodi';

  @override
  String get recording_recordingStepSubtitle => 'Nasa hadithi yako';

  @override
  String get recording_reviewStep => 'Kagua Rekodi';

  @override
  String get recording_reviewStepSubtitle => 'Sikiliza na uhifadhi';

  @override
  String get recording_genreNotFound => 'Aina haikupatikana';

  @override
  String get recording_noGenres => 'Hakuna aina zinazopatikana';

  @override
  String get recording_noSubcategories => 'Hakuna aina ndogo zinazopatikana';

  @override
  String get recording_registerDescription =>
      'Chagua rejista ya usemi inayoelezea vizuri toni na utaratibu wa rekodi hii.';

  @override
  String get recording_titleHint => 'Ongeza kichwa (si lazima)';

  @override
  String get recording_descriptionHint => 'Ongeza maelezo mafupi (si lazima)';

  @override
  String get recording_descriptionEmpty => 'Ongeza maelezo';

  @override
  String get recording_saveRecording => 'Hifadhi Rekodi';

  @override
  String get recording_recordAgain => 'Rekodi Tena';

  @override
  String get recording_discard => 'Tupa';

  @override
  String get recording_discardTitle => 'Tupa Rekodi?';

  @override
  String get recording_discardMessage => 'Rekodi hii itafutwa kabisa.';

  @override
  String get recording_saved => 'Rekodi imehifadhiwa';

  @override
  String get recording_notFound => 'Rekodi haikupatikana';

  @override
  String get recording_unknownGenre => 'Aina isiyojulikana';

  @override
  String get recording_splitRecording => 'Gawa Rekodi';

  @override
  String get recording_moveCategory => 'Hamisha Kategoria';

  @override
  String get recording_downloadAudio => 'Pakua Sauti';

  @override
  String get recording_downloadAudioMessage =>
      'Faili ya sauti haipo kwenye kifaa hiki. Ungependa kuipakua ili kuikata?';

  @override
  String recording_downloadFailed(String error) {
    return 'Imeshindwa kupakua: $error';
  }

  @override
  String get recording_audioNotAvailable => 'Faili ya sauti haipatikani';

  @override
  String get recording_deleteTitle => 'Futa Rekodi';

  @override
  String get recording_deleteMessage =>
      'Hii itafuta rekodi hii kabisa kutoka kifaa chako. Ikiwa imepakiwa, pia itaondolewa kwenye seva. Kitendo hiki hakiwezi kutenduliwa.';

  @override
  String get recording_deleteNoPermission => 'Huna ruhusa ya kufuta rekodi hii';

  @override
  String get recording_deleteFailed => 'Imeshindwa kufuta rekodi';

  @override
  String get recording_deleteFailedLocal =>
      'Imeshindwa kufuta kutoka seva. Inafuta kwa ndani.';

  @override
  String get recording_cleaningStatusFailed =>
      'Imeshindwa kusasisha hali ya usafishaji kwenye seva';

  @override
  String get recording_updateNoPermission =>
      'Huna ruhusa ya kusasisha rekodi hii';

  @override
  String get recording_moveNoPermission =>
      'Huna ruhusa ya kuhamisha rekodi hii';

  @override
  String get recording_movedSuccess => 'Rekodi imehamishwa';

  @override
  String get recording_updateFailed => 'Imeshindwa kusasisha kwenye seva';

  @override
  String get recordings_title => 'Rekodi';

  @override
  String get recordings_subtitle => 'Hadithi zako zilizokusanywa';

  @override
  String get recordings_importAudio => 'Ingiza faili ya sauti';

  @override
  String get recordings_selectProject => 'Chagua mradi';

  @override
  String get recordings_selectProjectSubtitle =>
      'Chagua mradi ili kuona rekodi zake';

  @override
  String get recordings_noRecordings => 'Hakuna rekodi bado';

  @override
  String get recordings_noRecordingsSubtitle =>
      'Gusa maikrofoni ili kurekodi hadithi yako ya kwanza, au ingiza faili ya sauti.';

  @override
  String recordings_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'rekodi $count',
      one: 'rekodi 1',
    );
    return '$_temp0';
  }

  @override
  String get recording_statusUploaded => 'Imepakiwa';

  @override
  String get recording_statusUploading => 'Inapakia';

  @override
  String get recording_statusFailed => 'Imeshindwa';

  @override
  String get recording_statusLocal => 'Ya Ndani';

  @override
  String get recordings_clearStale => 'Futa zilizoshindwa';

  @override
  String get recordings_clearStaleMessage =>
      'Hii itafuta kabisa rekodi zote zenye hali ya kupakia iliyoshindwa au iliyokwama kutoka kwenye seva. Kitendo hiki hakiwezi kutenduliwa.';

  @override
  String recordings_clearedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Rekodi $count zimefutwa',
      one: 'Rekodi 1 imefutwa',
      zero: 'Hakuna rekodi za zamani zilizopatikana',
    );
    return '$_temp0';
  }

  @override
  String get recordings_clearFailed => 'Imeshindwa kufuta rekodi';

  @override
  String get trim_title => 'Gawa Rekodi';

  @override
  String get trim_notFound => 'Rekodi haikupatikana';

  @override
  String get trim_audioUrlNotAvailable =>
      'URL ya sauti haipatikani kwa rekodi hii.';

  @override
  String get trim_localNotAvailable =>
      'Faili ya sauti ya ndani haipatikani. Pakua rekodi kwanza.';

  @override
  String get trim_atLeastOneSegment => 'Angalau sehemu moja lazima ihifadhiwe';

  @override
  String get trim_segments => 'Sehemu';

  @override
  String get trim_restoreAll => 'Rejesha zote';

  @override
  String get trim_instructions =>
      'Gusa kwenye wimbi la sauti hapo juu ili kuweka\nalama za kugawa na kugawa rekodi hii';

  @override
  String get trim_splitting => 'Inagawa...';

  @override
  String trim_saveSegments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hifadhi sehemu $count',
      one: 'Hifadhi sehemu 1',
    );
    return '$_temp0';
  }

  @override
  String get trim_addSplitsFirst => 'Ongeza migawanyo kwanza';

  @override
  String trim_savedSegments(int kept, int removed) {
    return 'Imehifadhi sehemu $kept, imeondoa $removed';
  }

  @override
  String trim_splitInto(int count) {
    return 'Gawa kuwa rekodi $count';
  }

  @override
  String get import_title => 'Ingiza Sauti';

  @override
  String get import_selectGenre => 'Chagua Aina';

  @override
  String get import_selectSubcategory => 'Chagua Aina Ndogo';

  @override
  String get import_selectRegister => 'Chagua Rejista';

  @override
  String get import_confirmImport => 'Thibitisha Uingizaji';

  @override
  String get import_analyzing => 'Inachambua faili ya sauti...';

  @override
  String get import_selectFile => 'Chagua faili ya sauti ya kuingiza';

  @override
  String get import_chooseFile => 'Chagua Faili';

  @override
  String get import_accessFailed => 'Haiwezi kufikia faili iliyochaguliwa';

  @override
  String import_pickError(String error) {
    return 'Hitilafu ya kuchagua faili: $error';
  }

  @override
  String import_saveError(String error) {
    return 'Hitilafu ya kuhifadhi faili: $error';
  }

  @override
  String get import_unknownFile => 'Faili isiyojulikana';

  @override
  String get import_importAndSave => 'Ingiza na Uhifadhi';

  @override
  String get moveCategory_title => 'Hamisha Kategoria';

  @override
  String get moveCategory_genre => 'Aina';

  @override
  String get moveCategory_subcategory => 'Aina Ndogo';

  @override
  String get moveCategory_selectSubcategory => 'Chagua aina ndogo';

  @override
  String get cleaning_needsCleaning => 'Inahitaji Usafishaji';

  @override
  String get cleaning_cleaning => 'Inasafisha...';

  @override
  String get cleaning_cleaned => 'Imesafishwa';

  @override
  String get cleaning_cleanFailed => 'Usafishaji Umeshindwa';

  @override
  String get sync_uploading => 'Inapakia...';

  @override
  String sync_pending(int count) {
    return '$count zinasubiri';
  }

  @override
  String get profile_photoUpdated => 'Picha ya wasifu imesasishwa';

  @override
  String profile_photoFailed(String error) {
    return 'Imeshindwa kusasisha picha: $error';
  }

  @override
  String get profile_editName => 'Hariri jina la kuonyesha';

  @override
  String get profile_nameHint => 'Jina lako';

  @override
  String get profile_nameUpdated => 'Jina limesasishwa';

  @override
  String get profile_syncStorage => 'Usawazishaji na Hifadhi';

  @override
  String get profile_about => 'Kuhusu';

  @override
  String get profile_appVersion => 'Toleo la programu';

  @override
  String get profile_byShema => 'Oral Collector na Shema';

  @override
  String get profile_administration => 'Utawala';

  @override
  String get profile_adminDashboard => 'Dashibodi ya Msimamizi';

  @override
  String get profile_adminSubtitle =>
      'Takwimu za mfumo, miradi na usimamizi wa aina';

  @override
  String get profile_account => 'Akaunti';

  @override
  String get profile_logOut => 'Ondoka';

  @override
  String get profile_deleteAccount => 'Futa Akaunti';

  @override
  String get profile_deleteAccountConfirm => 'Thibitisha Kufuta';

  @override
  String get profile_deleteAccountWarning =>
      'Kitendo hiki ni cha kudumu na hakiwezi kutenduliwa. Akaunti yako itafutwa, lakini rekodi zako zilizopakiwa zitahifadhiwa kwa miradi ya lugha.';

  @override
  String get profile_typeDelete => 'Andika DELETE kuthibitisha kufuta akaunti:';

  @override
  String get profile_clearCacheTitle => 'Futa akiba ya ndani?';

  @override
  String get profile_clearCacheMessage =>
      'Hii itafuta rekodi zote zilizohifadhiwa ndani. Rekodi zilizopakiwa kwenye seva hazitaathiriwa.';

  @override
  String get profile_cacheCleared => 'Akiba ya ndani imefutwa';

  @override
  String profile_joinedSuccess(String name) {
    return 'Umejiunga na \"$name\"';
  }

  @override
  String get profile_inviteDeclined => 'Mwaliko umekataliwa';

  @override
  String get profile_language => 'Lugha';

  @override
  String get profile_online => 'Mtandaoni';

  @override
  String get profile_offline => 'Nje ya mtandao';

  @override
  String profile_lastSync(String time) {
    return 'Usawazishaji wa mwisho: $time';
  }

  @override
  String get profile_neverSynced => 'Haijawahi kusawazishwa';

  @override
  String profile_pendingCount(int count) {
    return '$count zinasubiri';
  }

  @override
  String profile_syncingProgress(int percent) {
    return 'Inasawazisha... $percent%';
  }

  @override
  String get profile_syncNow => 'Sawazisha Sasa';

  @override
  String get profile_wifiOnly => 'Pakia kupitia Wi-Fi pekee';

  @override
  String get profile_wifiOnlySubtitle => 'Zuia upakiaji kupitia data ya simu';

  @override
  String get profile_autoRemove => 'Ondoa moja kwa moja baada ya kupakia';

  @override
  String get profile_autoRemoveSubtitle =>
      'Futa faili za ndani baada ya kupakiwa';

  @override
  String get profile_clearCache => 'Futa akiba ya ndani';

  @override
  String get profile_clearCacheSubtitle =>
      'Futa rekodi zote zilizohifadhiwa ndani';

  @override
  String get profile_invitations => 'Mialiko';

  @override
  String get profile_refreshInvitations => 'Onyesha upya mialiko';

  @override
  String get profile_noInvitations => 'Hakuna mialiko inayosubiri';

  @override
  String get profile_roleManager => 'Jukumu: Meneja';

  @override
  String get profile_roleMember => 'Jukumu: Mwanachama';

  @override
  String get profile_decline => 'Kataa';

  @override
  String get profile_accept => 'Kubali';

  @override
  String get profile_storage => 'Hifadhi';

  @override
  String get profile_status => 'Hali';

  @override
  String get profile_pendingLabel => 'Inasubiri';

  @override
  String get admin_title => 'Dashibodi ya Msimamizi';

  @override
  String get admin_overview => 'Muhtasari';

  @override
  String get admin_projects => 'Miradi';

  @override
  String get admin_genres => 'Aina';

  @override
  String get admin_cleaning => 'Usafishaji';

  @override
  String get admin_accessRequired => 'Ufikiaji wa msimamizi unahitajika';

  @override
  String get admin_totalProjects => 'Jumla ya Miradi';

  @override
  String get admin_languages => 'Lugha';

  @override
  String get admin_recordings => 'Rekodi';

  @override
  String get admin_totalHours => 'Jumla ya Masaa';

  @override
  String get admin_activeUsers => 'Watumiaji Hai';

  @override
  String get admin_projectName => 'Jina';

  @override
  String get admin_projectLanguage => 'Lugha';

  @override
  String get admin_projectMembers => 'Wanachama';

  @override
  String get admin_projectRecordings => 'Rekodi';

  @override
  String get admin_projectDuration => 'Muda';

  @override
  String get admin_projectCreated => 'Iliundwa';

  @override
  String get admin_noProjects => 'Hakuna miradi iliyopatikana';

  @override
  String get admin_unknownLanguage => 'Lugha isiyojulikana';

  @override
  String get admin_genresAndSubcategories => 'Aina na Aina Ndogo';

  @override
  String get admin_addGenre => 'Ongeza Aina';

  @override
  String get admin_noGenres => 'Hakuna aina iliyopatikana';

  @override
  String get admin_genreName => 'Jina la Aina';

  @override
  String get admin_required => 'Inahitajika';

  @override
  String get admin_descriptionOptional => 'Maelezo (si lazima)';

  @override
  String get admin_genreCreated => 'Aina imeundwa';

  @override
  String get admin_editGenre => 'Hariri aina';

  @override
  String get admin_deleteGenre => 'Futa aina';

  @override
  String get admin_addSubcategory => 'Ongeza aina ndogo';

  @override
  String get admin_editGenreTitle => 'Hariri Aina';

  @override
  String get admin_genreUpdated => 'Aina imesasishwa';

  @override
  String get admin_deleteGenreTitle => 'Futa Aina';

  @override
  String admin_deleteGenreConfirm(String name) {
    return 'Futa \"$name\" na aina zake ndogo zote?';
  }

  @override
  String get admin_genreDeleted => 'Aina imefutwa';

  @override
  String admin_addSubcategoryTo(String name) {
    return 'Ongeza Aina Ndogo kwa $name';
  }

  @override
  String get admin_subcategoryName => 'Jina la Aina Ndogo';

  @override
  String get admin_subcategoryCreated => 'Aina ndogo imeundwa';

  @override
  String get admin_deleteSubcategory => 'Futa Aina Ndogo';

  @override
  String admin_deleteSubcategoryConfirm(String name) {
    return 'Futa \"$name\"?';
  }

  @override
  String get admin_subcategoryDeleted => 'Aina ndogo imefutwa';

  @override
  String get admin_cleaningQueue => 'Foleni ya Usafishaji wa Sauti';

  @override
  String admin_cleanSelected(int count) {
    return 'Safisha Zilizochaguliwa ($count)';
  }

  @override
  String get admin_refreshCleaning => 'Onyesha upya foleni ya usafishaji';

  @override
  String get admin_cleaningWebOnly =>
      'Usafishaji wa sauti ni kipengele cha wavuti pekee. Michakato ya usafishaji inafanywa kwenye seva.';

  @override
  String get admin_noCleaningRecordings =>
      'Hakuna rekodi zilizowekwa alama za usafishaji';

  @override
  String get admin_cleaningTitle => 'Kichwa';

  @override
  String get admin_cleaningDuration => 'Muda';

  @override
  String get admin_cleaningSize => 'Ukubwa';

  @override
  String get admin_cleaningFormat => 'Muundo';

  @override
  String get admin_cleaningRecorded => 'Imerekodwa';

  @override
  String get admin_cleaningActions => 'Vitendo';

  @override
  String get admin_clean => 'Safisha';

  @override
  String get admin_deselectAll => 'Ondoa Uteuzi Wote';

  @override
  String get admin_selectAll => 'Chagua Zote';

  @override
  String get admin_cleaningTriggered => 'Usafishaji umeanzishwa';

  @override
  String get admin_cleaningFailed => 'Imeshindwa kuanzisha usafishaji';

  @override
  String admin_cleaningPartial(int success, int total) {
    return 'Usafishaji umeanzishwa kwa $success kati ya $total rekodi';
  }

  @override
  String get genre_title => 'Aina';

  @override
  String get genre_notFound => 'Aina haikupatikana';

  @override
  String genre_recordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'rekodi $count',
      one: 'rekodi 1',
    );
    return '$_temp0';
  }

  @override
  String get format_justNow => 'sasa hivi';

  @override
  String format_minutesAgo(int count) {
    return 'dakika $count zilizopita';
  }

  @override
  String format_hoursAgo(int count) {
    return 'saa $count zilizopita';
  }

  @override
  String format_daysAgo(int count) {
    return 'siku $count zilizopita';
  }

  @override
  String format_weeksAgo(int count) {
    return 'wiki $count zilizopita';
  }

  @override
  String format_monthsAgo(int count) {
    return 'miezi $count iliyopita';
  }

  @override
  String format_memberSince(String date) {
    return 'Mwanachama tangu $date';
  }

  @override
  String get format_member => 'Mwanachama';

  @override
  String format_dateAt(String date, String time) {
    return '$date saa $time';
  }

  @override
  String get genre_narrative => 'Simulizi';

  @override
  String get genre_narrativeDesc =>
      'Hadithi, masimulizi, na aina za kusimulia za utamaduni wa mdomo';

  @override
  String get genre_poeticSong => 'Ushairi / Wimbo';

  @override
  String get genre_poeticSongDesc =>
      'Tamaduni za mdomo za muziki na ushairi, ikiwa ni pamoja na nyimbo, maombolezo, na ushairi wa hekima';

  @override
  String get genre_instructional => 'Mafundisho / Kanuni';

  @override
  String get genre_instructionalDesc =>
      'Sheria, ibada, taratibu, na aina za mafundisho';

  @override
  String get genre_oralDiscourse => 'Hotuba ya Mdomo';

  @override
  String get genre_oralDiscourseDesc =>
      'Hotuba, mafundisho, sala, na aina za mazungumzo ya mdomo';

  @override
  String get sub_historicalNarrative => 'Simulizi ya Kihistoria';

  @override
  String get sub_personalAccount => 'Kisa Binafsi / Ushuhuda';

  @override
  String get sub_parable => 'Mfano / Hadithi ya Kufundisha';

  @override
  String get sub_originStory => 'Hadithi ya Asili / Uumbaji';

  @override
  String get sub_legend => 'Hadithi ya Kishujaa';

  @override
  String get sub_visionNarrative => 'Simulizi ya Maono au Ndoto';

  @override
  String get sub_genealogy => 'Nasaba';

  @override
  String get sub_eventReport => 'Ripoti ya Tukio la Hivi Karibuni';

  @override
  String get sub_hymn => 'Wimbo wa Sifa / Ibada';

  @override
  String get sub_lament => 'Maombolezo';

  @override
  String get sub_funeralDirge => 'Wimbo wa Mazishi';

  @override
  String get sub_victorySong => 'Wimbo wa Ushindi / Sherehe';

  @override
  String get sub_loveSong => 'Wimbo wa Mapenzi';

  @override
  String get sub_tauntSong => 'Wimbo wa Kejeli / Dhihaka';

  @override
  String get sub_blessing => 'Baraka';

  @override
  String get sub_curse => 'Laana';

  @override
  String get sub_wisdomPoem => 'Shairi la Hekima / Methali';

  @override
  String get sub_didacticPoetry => 'Ushairi wa Kufundisha';

  @override
  String get sub_legalCode => 'Sheria / Kanuni za Kisheria';

  @override
  String get sub_ritual => 'Ibada / Liturujia';

  @override
  String get sub_procedure => 'Utaratibu / Maagizo';

  @override
  String get sub_listInventory => 'Orodha / Hesabu';

  @override
  String get sub_propheticOracle => 'Unabii / Hotuba ya Kinabii';

  @override
  String get sub_exhortation => 'Mahubiri / Hotuba';

  @override
  String get sub_wisdomTeaching => 'Mafundisho ya Hekima';

  @override
  String get sub_prayer => 'Sala';

  @override
  String get sub_dialogue => 'Mazungumzo';

  @override
  String get sub_epistle => 'Barua / Waraka';

  @override
  String get sub_apocalypticDiscourse => 'Hotuba ya Ufunuo';

  @override
  String get sub_ceremonialSpeech => 'Hotuba ya Sherehe';

  @override
  String get sub_communityMemory => 'Kumbukumbu ya Jumuiya';

  @override
  String get sub_historicalNarrativeDesc =>
      'Masimulizi ya matukio, vita, na wakati muhimu katika historia';

  @override
  String get sub_personalAccountDesc => 'Hadithi binafsi za uzoefu na imani';

  @override
  String get sub_parableDesc =>
      'Hadithi za ishara zinazofundisha masomo ya kimaadili au kiroho';

  @override
  String get sub_originStoryDesc => 'Hadithi kuhusu jinsi mambo yalivyoanza';

  @override
  String get sub_legendDesc =>
      'Masimulizi ya watu wa ajabu na matendo yao makubwa';

  @override
  String get sub_visionNarrativeDesc =>
      'Masimulizi ya maono ya kimungu na ndoto za kinabii';

  @override
  String get sub_genealogyDesc => 'Rekodi za familia na nasaba za mababu';

  @override
  String get sub_eventReportDesc =>
      'Ripoti za matukio ya hivi karibuni katika jumuiya';

  @override
  String get sub_hymnDesc => 'Nyimbo za sifa na ibada kwa Mungu';

  @override
  String get sub_lamentDesc => 'Maneno ya huzuni, maombolezo, na msiba';

  @override
  String get sub_funeralDirgeDesc =>
      'Nyimbo zinazoimbwa wakati wa msiba na mazishi';

  @override
  String get sub_victorySongDesc => 'Nyimbo za kusherehekea ushindi na furaha';

  @override
  String get sub_loveSongDesc => 'Nyimbo za kuonyesha upendo na uaminifu';

  @override
  String get sub_tauntSongDesc =>
      'Nyimbo za kejeli dhidi ya maadui au wasioamini';

  @override
  String get sub_blessingDesc =>
      'Maneno yanayoomba fadhila na ulinzi wa kimungu';

  @override
  String get sub_curseDesc => 'Matamko ya hukumu au matokeo ya kimungu';

  @override
  String get sub_wisdomPoemDesc =>
      'Methali na mashairi yanayotoa hekima ya vitendo';

  @override
  String get sub_didacticPoetryDesc =>
      'Kazi za kishairi zilizoundwa kufundisha na kuelekeza';

  @override
  String get sub_legalCodeDesc => 'Kanuni, sheria, na masharti ya agano';

  @override
  String get sub_ritualDesc => 'Aina za ibada na sherehe takatifu zilizowekwa';

  @override
  String get sub_procedureDesc => 'Maelekezo ya vitendo na hatua kwa hatua';

  @override
  String get sub_listInventoryDesc => 'Orodha, sensa, na rekodi zilizopangwa';

  @override
  String get sub_propheticOracleDesc => 'Ujumbe uliotolewa kwa jina la Mungu';

  @override
  String get sub_exhortationDesc =>
      'Hotuba zinazohimiza hatua ya kimaadili na kiroho';

  @override
  String get sub_wisdomTeachingDesc =>
      'Mafundisho kuhusu kuishi kwa hekima na haki';

  @override
  String get sub_prayerDesc =>
      'Maneno yanayoelekezwa kwa Mungu katika ibada au maombi';

  @override
  String get sub_dialogueDesc => 'Mazungumzo na mabadilishano kati ya watu';

  @override
  String get sub_epistleDesc =>
      'Ujumbe ulioandikwa kwa jumuiya au watu binafsi';

  @override
  String get sub_apocalypticDiscourseDesc =>
      'Ufunuo kuhusu nyakati za mwisho na mpango wa Mungu';

  @override
  String get sub_ceremonialSpeechDesc =>
      'Hotuba rasmi za matukio rasmi au matakatifu';

  @override
  String get sub_communityMemoryDesc =>
      'Kumbukumbu za pamoja zinazohifadhi utambulisho wa kikundi';

  @override
  String get register_intimate => 'Wa Karibu Sana';

  @override
  String get register_casual => 'Isiyo Rasmi / Ya Kawaida';

  @override
  String get register_consultative => 'Ya Kushauriana';

  @override
  String get register_formal => 'Rasmi';

  @override
  String get register_ceremonial => 'Ya Sherehe';

  @override
  String get register_elderAuthority => 'Mzee / Mamlaka';

  @override
  String get register_religiousWorship => 'Ya Kidini / Ibada';

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
  String get locale_englishSub => 'Kiingereza';

  @override
  String get locale_portugueseSub => 'Kireno';

  @override
  String get locale_hindiSub => 'Kihindi';

  @override
  String get locale_koreanSub => 'Kikorea';

  @override
  String get locale_spanishSub => 'Kihispania';

  @override
  String get locale_bahasaSub => 'Kiindonesia';

  @override
  String get locale_frenchSub => 'Kifaransa';

  @override
  String get locale_tokPisinSub => 'Tok Pisin';

  @override
  String get locale_swahiliSub => 'Kiswahili';

  @override
  String get locale_arabicSub => 'Kiarabu';

  @override
  String get locale_chinese => '中文';

  @override
  String get locale_chineseSub => 'Kichina';

  @override
  String get locale_selectLanguage => 'Chagua Lugha Yako';

  @override
  String get locale_selectLanguageSubtitle =>
      'Unaweza kubadilisha hii baadaye katika mipangilio ya wasifu.';

  @override
  String get filter_all => 'Zote';

  @override
  String get filter_pending => 'Zinasubiri';

  @override
  String get filter_uploaded => 'Zimepakiwa';

  @override
  String get filter_needsCleaning => 'Zinahitaji Usafishaji';

  @override
  String get filter_unclassified => 'Haijainishwa';

  @override
  String get filter_allGenres => 'Aina zote';

  @override
  String get detail_duration => 'Muda';

  @override
  String get detail_size => 'Ukubwa';

  @override
  String get detail_format => 'Muundo';

  @override
  String get detail_status => 'Hali';

  @override
  String get detail_upload => 'Pakia';

  @override
  String get detail_uploaded => 'Imepakiwa';

  @override
  String get detail_cleaning => 'Usafishaji';

  @override
  String get detail_recorded => 'Imerekodwa';

  @override
  String get detail_retry => 'Jaribu tena';

  @override
  String get detail_notFlagged => 'Haijawekwa alama';

  @override
  String get detail_uploadStuck => 'Imekwama — gusa Jaribu tena';

  @override
  String get detail_uploading => 'Inapakia...';

  @override
  String get detail_maxRetries => 'Majaribio yamekwisha — gusa Jaribu tena';

  @override
  String get detail_uploadFailed => 'Upakiaji Umeshindwa';

  @override
  String get detail_pendingRetried => 'Inasubiri (imejaribiwa tena)';

  @override
  String get detail_notSynced => 'Haijasawazishwa';

  @override
  String get action_actions => 'Vitendo';

  @override
  String get action_split => 'Gawa';

  @override
  String get action_flagClean => 'Weka Alama Usafishaji';

  @override
  String get action_clearFlag => 'Ondoa Alama';

  @override
  String get action_move => 'Hamisha';

  @override
  String get action_delete => 'Futa';

  @override
  String get projectStats_recordings => 'Rekodi';

  @override
  String get projectStats_duration => 'Muda';

  @override
  String get projectStats_members => 'Wanachama';

  @override
  String get project_active => 'Hai';

  @override
  String get recording_paused => 'Imesimamishwa';

  @override
  String get recording_recording => 'Inarekodi';

  @override
  String get recording_tapToRecord => 'Gusa ili Kurekodi';

  @override
  String get recording_sensitivity => 'Unyeti';

  @override
  String get recording_sensitivityLow => 'Chini';

  @override
  String get recording_sensitivityMed => 'Wastani';

  @override
  String get recording_sensitivityHigh => 'Juu';

  @override
  String get recording_stopRecording => 'Simamisha kurekodi';

  @override
  String get recording_stop => 'Simama';

  @override
  String get recording_resume => 'Endelea';

  @override
  String get recording_pause => 'Simamisha';

  @override
  String get quickRecord_title => 'Rekodi Haraka';

  @override
  String get quickRecord_subtitle => 'Ainisha baadaye';

  @override
  String get quickRecord_classifyLater => 'Ainisha baadaye';

  @override
  String get classify_title => 'Ainisha Rekodi';

  @override
  String get classify_action => 'Ainisha';

  @override
  String get classify_banner =>
      'Rekodi hii inahitaji kuainishwa kabla ya kupakiwa.';

  @override
  String get classify_success => 'Rekodi imeainishwa';

  @override
  String get classify_register => 'Rejista (si lazima)';

  @override
  String get classify_selectRegister => 'Chagua rejista';

  @override
  String get recording_unclassified => 'Haijainishwa';

  @override
  String get fab_quickRecord => 'Haraka';

  @override
  String get fab_normalRecord => 'Rekodi';

  @override
  String get error_network =>
      'Haiwezi kufikia seva. Tafadhali angalia muunganisho wako wa intaneti na ujaribu tena.';

  @override
  String get error_secureConnection =>
      'Muunganisho salama haukuweza kuanzishwa. Tafadhali jaribu tena baadaye.';

  @override
  String get error_timeout =>
      'Ombi limekwisha muda. Tafadhali angalia muunganisho wako na ujaribu tena.';

  @override
  String get error_invalidCredentials =>
      'Barua pepe au nenosiri si sahihi. Tafadhali jaribu tena.';

  @override
  String get error_userNotFound =>
      'Hakuna akaunti iliyopatikana na anwani hiyo ya barua pepe.';

  @override
  String get error_accountExists => 'Akaunti yenye barua pepe hii tayari ipo.';

  @override
  String get error_emailRequired =>
      'Tafadhali ingiza anwani yako ya barua pepe.';

  @override
  String get error_passwordRequired => 'Tafadhali ingiza nenosiri lako.';

  @override
  String get error_signupFailed =>
      'Haikuweza kuunda akaunti yako. Tafadhali angalia maelezo yako na ujaribu tena.';

  @override
  String get error_sessionExpired =>
      'Kikao chako kimeisha muda. Tafadhali ingia tena.';

  @override
  String get error_profileLoadFailed =>
      'Haikuweza kupakia wasifu wako. Tafadhali jaribu tena.';

  @override
  String get error_profileUpdateFailed =>
      'Haikuweza kusasisha wasifu wako. Tafadhali jaribu tena.';

  @override
  String get error_imageUploadFailed =>
      'Haikuweza kupakia picha. Tafadhali jaribu tena.';

  @override
  String get error_notAuthenticated =>
      'Hujaingia. Tafadhali ingia na ujaribu tena.';

  @override
  String get error_noPermission => 'Huna ruhusa ya kufanya kitendo hiki.';

  @override
  String get error_generic =>
      'Kuna tatizo limetokea. Tafadhali jaribu tena baadaye.';
}
