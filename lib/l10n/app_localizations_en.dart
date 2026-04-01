// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Oral Collector';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_record => 'Record';

  @override
  String get nav_recordings => 'Recordings';

  @override
  String get nav_projects => 'Projects';

  @override
  String get nav_profile => 'Profile';

  @override
  String get nav_admin => 'Admin';

  @override
  String get nav_collapse => 'Collapse';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_save => 'Save';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_remove => 'Remove';

  @override
  String get common_create => 'Create';

  @override
  String get common_continue => 'Continue';

  @override
  String get common_next => 'Next';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_move => 'Move';

  @override
  String get common_invite => 'Invite';

  @override
  String get common_download => 'Download';

  @override
  String get common_clear => 'Clear';

  @override
  String get common_untitled => 'Untitled';

  @override
  String get common_loading => 'Loading...';

  @override
  String get auth_oralCollector => 'Oral Collector';

  @override
  String get auth_byShema => 'by Shema';

  @override
  String get auth_heroTagline => 'Preserve voices.\nShare stories.';

  @override
  String get auth_welcomeBack => 'Welcome\nBack';

  @override
  String get auth_welcome => 'Welcome ';

  @override
  String get auth_back => 'Back';

  @override
  String get auth_createWord => 'Create ';

  @override
  String get auth_createNewline => 'Create\n';

  @override
  String get auth_account => 'Account';

  @override
  String get auth_signInSubtitle => 'Sign in to continue collecting stories.';

  @override
  String get auth_signUpSubtitle => 'Join our community of story collectors.';

  @override
  String get auth_backToSignIn => 'Back to sign in';

  @override
  String get auth_emailLabel => 'Email Address';

  @override
  String get auth_emailHint => 'your@email.com';

  @override
  String get auth_emailRequired => 'Please enter your email';

  @override
  String get auth_emailInvalid => 'Please enter a valid email';

  @override
  String get auth_passwordLabel => 'Password';

  @override
  String get auth_passwordHint => 'At least 6 characters';

  @override
  String get auth_passwordRequired => 'Please enter your password';

  @override
  String get auth_passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get auth_confirmPasswordLabel => 'Confirm Password';

  @override
  String get auth_confirmPasswordHint => 'Re-enter password';

  @override
  String get auth_confirmPasswordRequired => 'Please confirm your password';

  @override
  String get auth_confirmPasswordMismatch => 'Passwords do not match';

  @override
  String get auth_nameLabel => 'Name';

  @override
  String get auth_nameHint => 'Your full name';

  @override
  String get auth_nameRequired => 'Please enter your display name';

  @override
  String get auth_signIn => 'Sign In';

  @override
  String get auth_signUp => 'Sign Up';

  @override
  String get auth_noAccount => 'Don\'t have an account? ';

  @override
  String get auth_haveAccount => 'Have an account? ';

  @override
  String get auth_continueButton => 'Continue';

  @override
  String get auth_forgotPassword => 'Forgot password?';

  @override
  String get auth_resetPassword => 'Reset Password';

  @override
  String get auth_forgotPasswordSubtitle =>
      'Enter your email and we\'ll send you a reset link.';

  @override
  String get auth_sendResetLink => 'Send Reset Link';

  @override
  String get auth_sending => 'Sending...';

  @override
  String get auth_checkYourEmail => 'Check Your Email';

  @override
  String auth_resetEmailSent(String email) {
    return 'We sent a password reset link to $email. Check your inbox and follow the link to set a new password.';
  }

  @override
  String get auth_openEmailApp => 'Open Email App';

  @override
  String get auth_resendEmail => 'Resend';

  @override
  String get auth_backToLogin => 'Back to Sign In';

  @override
  String get auth_newPassword => 'New Password';

  @override
  String get auth_confirmNewPassword => 'Confirm New Password';

  @override
  String get auth_resetPasswordSubtitle => 'Enter your new password below.';

  @override
  String get auth_resetPasswordButton => 'Reset Password';

  @override
  String get auth_resetting => 'Resetting...';

  @override
  String get auth_resetSuccess =>
      'Password reset successfully! You can now sign in with your new password.';

  @override
  String get auth_invalidResetLink => 'Invalid Reset Link';

  @override
  String get auth_invalidResetLinkMessage =>
      'This password reset link is invalid or has expired.';

  @override
  String get auth_requestNewLink => 'Request a New Link';

  @override
  String get home_greetingMorning => 'Good morning';

  @override
  String get home_greetingAfternoon => 'Good afternoon';

  @override
  String get home_greetingEvening => 'Good evening';

  @override
  String home_greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get home_subtitle => 'Let\'s share your stories today';

  @override
  String get home_switchProject => 'Switch project';

  @override
  String get home_genres => 'Genres';

  @override
  String get home_loadingProjects => 'Loading projects...';

  @override
  String get home_loadingGenres => 'Loading genres...';

  @override
  String get home_noGenres => 'No genres available yet';

  @override
  String get home_noProjectTitle => 'Select a project to get started';

  @override
  String get home_browseProjects => 'Browse Projects';

  @override
  String get stats_recordings => 'recordings';

  @override
  String get stats_recorded => 'recorded';

  @override
  String get stats_members => 'members';

  @override
  String get project_switchTitle => 'Switch Project';

  @override
  String get project_projects => 'Projects';

  @override
  String get project_subtitle => 'Manage your collections';

  @override
  String get project_noProjectsTitle => 'No projects yet';

  @override
  String get project_noProjectsSubtitle =>
      'Create your first project to start collecting oral stories.';

  @override
  String get project_newProject => 'New Project';

  @override
  String get project_projectName => 'Project Name';

  @override
  String get project_projectNameHint => 'e.g. Kosrae Bible Translation';

  @override
  String get project_projectNameRequired => 'Project name is required';

  @override
  String get project_description => 'Description';

  @override
  String get project_descriptionHint => 'Optional';

  @override
  String get project_language => 'Language';

  @override
  String get project_selectLanguage => 'Select a language';

  @override
  String get project_pleaseSelectLanguage => 'Please select a language';

  @override
  String get project_createProject => 'Create Project';

  @override
  String get project_selectLanguageTitle => 'Select Language';

  @override
  String get project_addLanguageTitle => 'Add Language';

  @override
  String get project_addLanguageSubtitle =>
      'Can\'t find your language? Add it here.';

  @override
  String get project_languageName => 'Language Name';

  @override
  String get project_languageNameHint => 'e.g. Kosraean';

  @override
  String get project_languageNameRequired => 'Name is required';

  @override
  String get project_languageCode => 'Language Code';

  @override
  String get project_languageCodeHint => 'e.g. kos (ISO 639-3)';

  @override
  String get project_languageCodeRequired => 'Code is required';

  @override
  String get project_languageCodeTooLong => 'Code must be 1-3 characters';

  @override
  String get project_addLanguage => 'Add Language';

  @override
  String get project_noLanguagesFound => 'No languages found';

  @override
  String get project_addNewLanguage => 'Add new language';

  @override
  String project_addAsNewLanguage(String query) {
    return 'Add \"$query\" as a new language';
  }

  @override
  String get project_searchLanguages => 'Search languages...';

  @override
  String get project_backToList => 'Back to list';

  @override
  String get projectSettings_title => 'Project Settings';

  @override
  String get projectSettings_details => 'Details';

  @override
  String get projectSettings_saving => 'Saving...';

  @override
  String get projectSettings_saveChanges => 'Save Changes';

  @override
  String get projectSettings_updated => 'Project updated';

  @override
  String get projectSettings_noPermission =>
      'You do not have permission to update this project';

  @override
  String get projectSettings_team => 'Team';

  @override
  String get projectSettings_removeMember => 'Remove Member';

  @override
  String projectSettings_removeMemberConfirm(String name) {
    return 'Remove $name from this project?';
  }

  @override
  String get projectSettings_memberRemoved => 'Member removed';

  @override
  String get projectSettings_memberRemoveFailed => 'Failed to remove member';

  @override
  String get projectSettings_inviteSent => 'Invite sent successfully';

  @override
  String get projectSettings_noMembers => 'No members yet';

  @override
  String get recording_selectGenre => 'Select Genre';

  @override
  String get recording_selectGenreSubtitle => 'Choose a genre for your story';

  @override
  String get recording_selectSubcategory => 'Select Subcategory';

  @override
  String get recording_selectSubcategorySubtitle => 'Pick a subcategory';

  @override
  String get recording_selectRegister => 'Select Register';

  @override
  String get recording_selectRegisterSubtitle => 'Choose the speech register';

  @override
  String get recording_recordingStep => 'Recording';

  @override
  String get recording_recordingStepSubtitle => 'Capture your story';

  @override
  String get recording_reviewStep => 'Review Recording';

  @override
  String get recording_reviewStepSubtitle => 'Listen and save';

  @override
  String get recording_genreNotFound => 'Genre not found';

  @override
  String get recording_noGenres => 'No genres available';

  @override
  String get recording_noSubcategories => 'No subcategories available';

  @override
  String get recording_registerDescription =>
      'Choose the speech register that best describes the tone and formality of this recording.';

  @override
  String get recording_titleHint => 'Add a title (optional)';

  @override
  String get recording_saveRecording => 'Save Recording';

  @override
  String get recording_recordAgain => 'Record Again';

  @override
  String get recording_discard => 'Discard';

  @override
  String get recording_discardTitle => 'Discard Recording?';

  @override
  String get recording_discardMessage =>
      'This recording will be permanently deleted.';

  @override
  String get recording_saved => 'Recording saved';

  @override
  String get recording_notFound => 'Recording not found';

  @override
  String get recording_unknownGenre => 'Unknown genre';

  @override
  String get recording_splitRecording => 'Split Recording';

  @override
  String get recording_moveCategory => 'Move Category';

  @override
  String get recording_downloadAudio => 'Download Audio';

  @override
  String get recording_downloadAudioMessage =>
      'The audio file is not stored on this device. Would you like to download it to trim?';

  @override
  String recording_downloadFailed(String error) {
    return 'Failed to download: $error';
  }

  @override
  String get recording_audioNotAvailable => 'Audio file not available';

  @override
  String get recording_deleteTitle => 'Delete Recording';

  @override
  String get recording_deleteMessage =>
      'This will permanently delete this recording from your device. If it has been uploaded, it will also be removed from the server. This action cannot be undone.';

  @override
  String get recording_deleteNoPermission =>
      'You do not have permission to delete this recording';

  @override
  String get recording_deleteFailed => 'Failed to delete recording';

  @override
  String get recording_deleteFailedLocal =>
      'Failed to delete from server. Removing locally.';

  @override
  String get recording_cleaningStatusFailed =>
      'Failed to update cleaning status on server';

  @override
  String get recording_updateNoPermission =>
      'You do not have permission to update this recording';

  @override
  String get recording_moveNoPermission =>
      'You do not have permission to move this recording';

  @override
  String get recording_movedSuccess => 'Recording moved successfully';

  @override
  String get recording_updateFailed => 'Failed to update on server';

  @override
  String get recordings_title => 'Recordings';

  @override
  String get recordings_subtitle => 'Your collected stories';

  @override
  String get recordings_importAudio => 'Import audio file';

  @override
  String get recordings_selectProject => 'Select a project';

  @override
  String get recordings_selectProjectSubtitle =>
      'Choose a project to view its recordings';

  @override
  String get recordings_noRecordings => 'No recordings yet';

  @override
  String get recordings_noRecordingsSubtitle =>
      'Tap the microphone to record your first story, or import an audio file.';

  @override
  String recordings_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recordings',
      one: '1 recording',
    );
    return '$_temp0';
  }

  @override
  String get recording_statusUploaded => 'Uploaded';

  @override
  String get recording_statusUploading => 'Uploading';

  @override
  String get recording_statusFailed => 'Failed';

  @override
  String get recording_statusLocal => 'Local';

  @override
  String get recordings_clearStale => 'Clear failed';

  @override
  String get recordings_clearStaleMessage =>
      'This will permanently delete all recordings with failed or stuck upload status from the server. This cannot be undone.';

  @override
  String recordings_clearedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cleared $count recordings',
      one: 'Cleared 1 recording',
      zero: 'No stale recordings found',
    );
    return '$_temp0';
  }

  @override
  String get recordings_clearFailed => 'Failed to clear recordings';

  @override
  String get trim_title => 'Split Recording';

  @override
  String get trim_notFound => 'Recording not found';

  @override
  String get trim_audioUrlNotAvailable =>
      'Audio URL not available for this recording.';

  @override
  String get trim_localNotAvailable =>
      'Local audio file not available. Download the recording first.';

  @override
  String get trim_atLeastOneSegment => 'At least one segment must be kept';

  @override
  String get trim_segments => 'Segments';

  @override
  String get trim_restoreAll => 'Restore all';

  @override
  String get trim_instructions =>
      'Tap on the waveform above to place\nsplit markers and divide this recording';

  @override
  String get trim_splitting => 'Splitting...';

  @override
  String trim_saveSegments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Save $count segments',
      one: 'Save 1 segment',
    );
    return '$_temp0';
  }

  @override
  String get trim_addSplitsFirst => 'Add splits first';

  @override
  String trim_savedSegments(int kept, int removed) {
    String _temp0 = intl.Intl.pluralLogic(
      kept,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'Saved $kept segment$_temp0, removed $removed';
  }

  @override
  String trim_splitInto(int count) {
    return 'Split into $count recordings';
  }

  @override
  String get import_title => 'Import Audio';

  @override
  String get import_selectGenre => 'Select Genre';

  @override
  String get import_selectSubcategory => 'Select Subcategory';

  @override
  String get import_selectRegister => 'Select Register';

  @override
  String get import_confirmImport => 'Confirm Import';

  @override
  String get import_analyzing => 'Analyzing audio file...';

  @override
  String get import_selectFile => 'Select an audio file to import';

  @override
  String get import_chooseFile => 'Choose File';

  @override
  String get import_accessFailed => 'Could not access selected file';

  @override
  String import_pickError(String error) {
    return 'Error picking file: $error';
  }

  @override
  String import_saveError(String error) {
    return 'Error saving file: $error';
  }

  @override
  String get import_unknownFile => 'Unknown file';

  @override
  String get import_importAndSave => 'Import & Save';

  @override
  String get moveCategory_title => 'Move Category';

  @override
  String get moveCategory_genre => 'Genre';

  @override
  String get moveCategory_subcategory => 'Subcategory';

  @override
  String get moveCategory_selectSubcategory => 'Select subcategory';

  @override
  String get cleaning_needsCleaning => 'Needs Cleaning';

  @override
  String get cleaning_cleaning => 'Cleaning...';

  @override
  String get cleaning_cleaned => 'Cleaned';

  @override
  String get cleaning_cleanFailed => 'Clean Failed';

  @override
  String get sync_uploading => 'Uploading...';

  @override
  String sync_pending(int count) {
    return '$count pending';
  }

  @override
  String get profile_photoUpdated => 'Profile photo updated';

  @override
  String profile_photoFailed(String error) {
    return 'Failed to update photo: $error';
  }

  @override
  String get profile_editName => 'Edit display name';

  @override
  String get profile_nameHint => 'Your name';

  @override
  String get profile_nameUpdated => 'Name updated';

  @override
  String get profile_syncStorage => 'Sync & Storage';

  @override
  String get profile_about => 'About';

  @override
  String get profile_appVersion => 'App version';

  @override
  String get profile_byShema => 'Oral Collector by Shema';

  @override
  String get profile_administration => 'Administration';

  @override
  String get profile_adminDashboard => 'Admin Dashboard';

  @override
  String get profile_adminSubtitle =>
      'System stats, projects & genre management';

  @override
  String get profile_account => 'Account';

  @override
  String get profile_logOut => 'Log Out';

  @override
  String get profile_deleteAccount => 'Delete Account';

  @override
  String get profile_deleteAccountConfirm => 'Confirm Deletion';

  @override
  String get profile_deleteAccountWarning =>
      'This action is permanent and cannot be undone. Your account will be deleted, but your uploaded recordings will be preserved for the language projects.';

  @override
  String get profile_typeDelete => 'Type DELETE to confirm account deletion:';

  @override
  String get profile_clearCacheTitle => 'Clear local cache?';

  @override
  String get profile_clearCacheMessage =>
      'This will delete all locally stored recordings. Uploaded recordings on the server will not be affected.';

  @override
  String get profile_cacheCleared => 'Local cache cleared';

  @override
  String profile_joinedSuccess(String name) {
    return 'Joined \"$name\" successfully';
  }

  @override
  String get profile_inviteDeclined => 'Invite declined';

  @override
  String get profile_language => 'Language';

  @override
  String get profile_online => 'Online';

  @override
  String get profile_offline => 'Offline';

  @override
  String profile_lastSync(String time) {
    return 'Last sync: $time';
  }

  @override
  String get profile_neverSynced => 'Never synced';

  @override
  String profile_pendingCount(int count) {
    return '$count pending';
  }

  @override
  String profile_syncingProgress(int percent) {
    return 'Syncing... $percent%';
  }

  @override
  String get profile_syncNow => 'Sync Now';

  @override
  String get profile_wifiOnly => 'Upload on Wi-Fi only';

  @override
  String get profile_wifiOnlySubtitle => 'Prevent uploads over cellular data';

  @override
  String get profile_autoRemove => 'Auto-remove after upload';

  @override
  String get profile_autoRemoveSubtitle =>
      'Delete local files after successful upload';

  @override
  String get profile_clearCache => 'Clear local cache';

  @override
  String get profile_clearCacheSubtitle =>
      'Delete all locally stored recordings';

  @override
  String get profile_invitations => 'Invitations';

  @override
  String get profile_refreshInvitations => 'Refresh invitations';

  @override
  String get profile_noInvitations => 'No pending invitations';

  @override
  String get profile_roleManager => 'Role: Manager';

  @override
  String get profile_roleMember => 'Role: Member';

  @override
  String get profile_decline => 'Decline';

  @override
  String get profile_accept => 'Accept';

  @override
  String get profile_storage => 'Storage';

  @override
  String get profile_status => 'Status';

  @override
  String get profile_pendingLabel => 'Pending';

  @override
  String get admin_title => 'Admin Dashboard';

  @override
  String get admin_overview => 'Overview';

  @override
  String get admin_projects => 'Projects';

  @override
  String get admin_genres => 'Genres';

  @override
  String get admin_cleaning => 'Cleaning';

  @override
  String get admin_accessRequired => 'Admin access required';

  @override
  String get admin_totalProjects => 'Total Projects';

  @override
  String get admin_languages => 'Languages';

  @override
  String get admin_recordings => 'Recordings';

  @override
  String get admin_totalHours => 'Total Hours';

  @override
  String get admin_activeUsers => 'Active Users';

  @override
  String get admin_projectName => 'Name';

  @override
  String get admin_projectLanguage => 'Language';

  @override
  String get admin_projectMembers => 'Members';

  @override
  String get admin_projectRecordings => 'Recordings';

  @override
  String get admin_projectDuration => 'Duration';

  @override
  String get admin_projectCreated => 'Created';

  @override
  String get admin_noProjects => 'No projects found';

  @override
  String get admin_unknownLanguage => 'Unknown language';

  @override
  String get admin_genresAndSubcategories => 'Genres & Subcategories';

  @override
  String get admin_addGenre => 'Add Genre';

  @override
  String get admin_noGenres => 'No genres found';

  @override
  String get admin_genreName => 'Genre Name';

  @override
  String get admin_required => 'Required';

  @override
  String get admin_descriptionOptional => 'Description (optional)';

  @override
  String get admin_genreCreated => 'Genre created';

  @override
  String get admin_editGenre => 'Edit genre';

  @override
  String get admin_deleteGenre => 'Delete genre';

  @override
  String get admin_addSubcategory => 'Add subcategory';

  @override
  String get admin_editGenreTitle => 'Edit Genre';

  @override
  String get admin_genreUpdated => 'Genre updated';

  @override
  String get admin_deleteGenreTitle => 'Delete Genre';

  @override
  String admin_deleteGenreConfirm(String name) {
    return 'Delete \"$name\" and all its subcategories?';
  }

  @override
  String get admin_genreDeleted => 'Genre deleted';

  @override
  String admin_addSubcategoryTo(String name) {
    return 'Add Subcategory to $name';
  }

  @override
  String get admin_subcategoryName => 'Subcategory Name';

  @override
  String get admin_subcategoryCreated => 'Subcategory created';

  @override
  String get admin_deleteSubcategory => 'Delete Subcategory';

  @override
  String admin_deleteSubcategoryConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get admin_subcategoryDeleted => 'Subcategory deleted';

  @override
  String get admin_cleaningQueue => 'Audio Cleaning Queue';

  @override
  String admin_cleanSelected(int count) {
    return 'Clean Selected ($count)';
  }

  @override
  String get admin_refreshCleaning => 'Refresh cleaning queue';

  @override
  String get admin_cleaningWebOnly =>
      'Audio cleaning is a web-only feature. Cleaning processes run on the server.';

  @override
  String get admin_noCleaningRecordings => 'No recordings flagged for cleaning';

  @override
  String get admin_cleaningTitle => 'Title';

  @override
  String get admin_cleaningDuration => 'Duration';

  @override
  String get admin_cleaningSize => 'Size';

  @override
  String get admin_cleaningFormat => 'Format';

  @override
  String get admin_cleaningRecorded => 'Recorded';

  @override
  String get admin_cleaningActions => 'Actions';

  @override
  String get admin_clean => 'Clean';

  @override
  String get admin_deselectAll => 'Deselect All';

  @override
  String get admin_selectAll => 'Select All';

  @override
  String get admin_cleaningTriggered => 'Cleaning triggered';

  @override
  String get admin_cleaningFailed => 'Failed to trigger cleaning';

  @override
  String admin_cleaningPartial(int success, int total) {
    return 'Cleaning triggered for $success of $total recordings';
  }

  @override
  String get genre_title => 'Genre';

  @override
  String get genre_notFound => 'Genre not found';

  @override
  String genre_recordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recordings',
      one: '1 recording',
    );
    return '$_temp0';
  }

  @override
  String get format_justNow => 'just now';

  @override
  String format_minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String format_hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String format_daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String format_weeksAgo(int count) {
    return '${count}w ago';
  }

  @override
  String format_monthsAgo(int count) {
    return '${count}mo ago';
  }

  @override
  String format_memberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get format_member => 'Member';

  @override
  String format_dateAt(String date, String time) {
    return '$date at $time';
  }

  @override
  String get genre_narrative => 'Narrative';

  @override
  String get genre_narrativeDesc =>
      'Stories, accounts, and narrative forms of oral tradition';

  @override
  String get genre_poeticSong => 'Poetic / Song';

  @override
  String get genre_poeticSongDesc =>
      'Musical and poetic oral traditions including hymns, laments, and wisdom poetry';

  @override
  String get genre_instructional => 'Instructional / Regulatory';

  @override
  String get genre_instructionalDesc =>
      'Laws, rituals, procedures, and instructional forms';

  @override
  String get genre_oralDiscourse => 'Oral Discourse';

  @override
  String get genre_oralDiscourseDesc =>
      'Speeches, teachings, prayers, and discursive oral forms';

  @override
  String get sub_historicalNarrative => 'Historical Narrative';

  @override
  String get sub_personalAccount => 'Personal Account / Testimony';

  @override
  String get sub_parable => 'Parable / Illustrative Story';

  @override
  String get sub_originStory => 'Origin / Creation Story';

  @override
  String get sub_legend => 'Legend / Hero Story';

  @override
  String get sub_visionNarrative => 'Vision or Dream Narrative';

  @override
  String get sub_genealogy => 'Genealogy';

  @override
  String get sub_eventReport => 'Recent Event Report';

  @override
  String get sub_hymn => 'Hymn / Worship Song';

  @override
  String get sub_lament => 'Lament';

  @override
  String get sub_funeralDirge => 'Funeral Dirge';

  @override
  String get sub_victorySong => 'Victory / Celebration Song';

  @override
  String get sub_loveSong => 'Love Song';

  @override
  String get sub_tauntSong => 'Mocking / Taunt Song';

  @override
  String get sub_blessing => 'Blessing';

  @override
  String get sub_curse => 'Curse';

  @override
  String get sub_wisdomPoem => 'Wisdom Poem / Proverb';

  @override
  String get sub_didacticPoetry => 'Didactic Poetry';

  @override
  String get sub_legalCode => 'Law / Legal Code';

  @override
  String get sub_ritual => 'Ritual / Liturgy';

  @override
  String get sub_procedure => 'Procedure / Instruction';

  @override
  String get sub_listInventory => 'List / Inventory';

  @override
  String get sub_propheticOracle => 'Prophetic Oracle / Speech';

  @override
  String get sub_exhortation => 'Exhortation / Sermon';

  @override
  String get sub_wisdomTeaching => 'Wisdom Teaching';

  @override
  String get sub_prayer => 'Prayer';

  @override
  String get sub_dialogue => 'Dialogue';

  @override
  String get sub_epistle => 'Epistle / Letter';

  @override
  String get sub_apocalypticDiscourse => 'Apocalyptic Discourse';

  @override
  String get sub_ceremonialSpeech => 'Ceremonial Speech';

  @override
  String get sub_communityMemory => 'Community Memory';

  @override
  String get sub_historicalNarrativeDesc =>
      'Accounts of events, wars, and key moments in history';

  @override
  String get sub_personalAccountDesc =>
      'First-person stories of personal experiences and faith';

  @override
  String get sub_parableDesc =>
      'Symbolic stories that teach moral or spiritual lessons';

  @override
  String get sub_originStoryDesc => 'Stories about how things came to be';

  @override
  String get sub_legendDesc =>
      'Tales of remarkable people and their great deeds';

  @override
  String get sub_visionNarrativeDesc =>
      'Accounts of divine visions and prophetic dreams';

  @override
  String get sub_genealogyDesc =>
      'Records of family lines and ancestral lineages';

  @override
  String get sub_eventReportDesc =>
      'Reports of recent happenings in the community';

  @override
  String get sub_hymnDesc => 'Songs of praise and worship to God';

  @override
  String get sub_lamentDesc => 'Expressions of grief, sorrow, and mourning';

  @override
  String get sub_funeralDirgeDesc =>
      'Songs performed during mourning and burial ceremonies';

  @override
  String get sub_victorySongDesc =>
      'Songs celebrating triumphs and joyful events';

  @override
  String get sub_loveSongDesc => 'Songs expressing love and devotion';

  @override
  String get sub_tauntSongDesc =>
      'Songs of ridicule aimed at enemies or the unfaithful';

  @override
  String get sub_blessingDesc => 'Words invoking divine favor and protection';

  @override
  String get sub_curseDesc =>
      'Pronouncements of judgment or divine consequence';

  @override
  String get sub_wisdomPoemDesc =>
      'Short sayings and poems conveying practical wisdom';

  @override
  String get sub_didacticPoetryDesc =>
      'Poetic compositions designed to teach and instruct';

  @override
  String get sub_legalCodeDesc => 'Rules, statutes, and covenant regulations';

  @override
  String get sub_ritualDesc =>
      'Prescribed forms of worship and sacred ceremonies';

  @override
  String get sub_procedureDesc =>
      'Step-by-step directions and practical guidelines';

  @override
  String get sub_listInventoryDesc =>
      'Catalogs, censuses, and organized records';

  @override
  String get sub_propheticOracleDesc => 'Messages delivered on behalf of God';

  @override
  String get sub_exhortationDesc =>
      'Speeches urging moral and spiritual action';

  @override
  String get sub_wisdomTeachingDesc =>
      'Instruction on living wisely and righteously';

  @override
  String get sub_prayerDesc => 'Words addressed to God in worship or petition';

  @override
  String get sub_dialogueDesc => 'Conversations and exchanges between people';

  @override
  String get sub_epistleDesc =>
      'Written messages addressed to communities or individuals';

  @override
  String get sub_apocalypticDiscourseDesc =>
      'Revelations about the end times and God\'s plan';

  @override
  String get sub_ceremonialSpeechDesc =>
      'Formal addresses for official or sacred occasions';

  @override
  String get sub_communityMemoryDesc =>
      'Shared recollections that preserve group identity';

  @override
  String get register_intimate => 'Intimate';

  @override
  String get register_casual => 'Informal / Casual';

  @override
  String get register_consultative => 'Consultative';

  @override
  String get register_formal => 'Formal / Official';

  @override
  String get register_ceremonial => 'Ceremonial';

  @override
  String get register_elderAuthority => 'Elder / Authority';

  @override
  String get register_religiousWorship => 'Religious / Worship';

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
  String get locale_englishSub => 'English';

  @override
  String get locale_portugueseSub => 'Portuguese';

  @override
  String get locale_hindiSub => 'Hindi';

  @override
  String get locale_koreanSub => 'Korean';

  @override
  String get locale_spanishSub => 'Spanish';

  @override
  String get locale_bahasaSub => 'Indonesian';

  @override
  String get locale_frenchSub => 'French';

  @override
  String get locale_tokPisinSub => 'Tok Pisin';

  @override
  String get locale_swahiliSub => 'Swahili';

  @override
  String get locale_arabicSub => 'Arabic';

  @override
  String get locale_chinese => '中文';

  @override
  String get locale_chineseSub => 'Chinese';

  @override
  String get locale_selectLanguage => 'Choose Your Language';

  @override
  String get locale_selectLanguageSubtitle =>
      'You can change this later in your profile settings.';

  @override
  String get filter_all => 'All';

  @override
  String get filter_pending => 'Pending';

  @override
  String get filter_uploaded => 'Uploaded';

  @override
  String get filter_needsCleaning => 'Needs Cleaning';

  @override
  String get filter_unclassified => 'Unclassified';

  @override
  String get filter_allGenres => 'All genres';

  @override
  String get detail_duration => 'Duration';

  @override
  String get detail_size => 'Size';

  @override
  String get detail_format => 'Format';

  @override
  String get detail_status => 'Status';

  @override
  String get detail_upload => 'Upload';

  @override
  String get detail_uploaded => 'Uploaded';

  @override
  String get detail_cleaning => 'Cleaning';

  @override
  String get detail_recorded => 'Recorded';

  @override
  String get detail_retry => 'Retry';

  @override
  String get detail_notFlagged => 'Not flagged';

  @override
  String get detail_uploadStuck => 'Stuck — tap Retry';

  @override
  String get detail_uploading => 'Uploading...';

  @override
  String get detail_maxRetries => 'Max retries — tap Retry';

  @override
  String get detail_uploadFailed => 'Upload Failed';

  @override
  String get detail_pendingRetried => 'Pending (retried)';

  @override
  String get detail_notSynced => 'Not synced';

  @override
  String get action_actions => 'Actions';

  @override
  String get action_split => 'Split';

  @override
  String get action_flagClean => 'Flag Clean';

  @override
  String get action_clearFlag => 'Clear Flag';

  @override
  String get action_move => 'Move';

  @override
  String get action_delete => 'Delete';

  @override
  String get projectStats_recordings => 'Recordings';

  @override
  String get projectStats_duration => 'Duration';

  @override
  String get projectStats_members => 'Members';

  @override
  String get project_active => 'Active';

  @override
  String get recording_paused => 'Paused';

  @override
  String get recording_recording => 'Recording';

  @override
  String get recording_tapToRecord => 'Tap to Record';

  @override
  String get recording_sensitivity => 'Sensitivity';

  @override
  String get recording_sensitivityLow => 'Low';

  @override
  String get recording_sensitivityMed => 'Med';

  @override
  String get recording_sensitivityHigh => 'High';

  @override
  String get recording_stopRecording => 'Stop recording';

  @override
  String get recording_stop => 'Stop';

  @override
  String get recording_resume => 'Resume';

  @override
  String get recording_pause => 'Pause';

  @override
  String get quickRecord_title => 'Quick Record';

  @override
  String get quickRecord_subtitle => 'Classify later';

  @override
  String get quickRecord_classifyLater => 'Classify later';

  @override
  String get classify_title => 'Classify Recording';

  @override
  String get classify_action => 'Classify';

  @override
  String get classify_banner =>
      'This recording needs classification before it can be uploaded.';

  @override
  String get classify_success => 'Recording classified';

  @override
  String get classify_register => 'Register (optional)';

  @override
  String get classify_selectRegister => 'Select register';

  @override
  String get recording_unclassified => 'Unclassified';

  @override
  String get fab_quickRecord => 'Quick';

  @override
  String get fab_normalRecord => 'Record';
}
