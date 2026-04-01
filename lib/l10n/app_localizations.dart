import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_sw.dart';
import 'app_localizations_tpi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('ko'),
    Locale('pt'),
    Locale('sw'),
    Locale('tpi'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Oral Collector'**
  String get appTitle;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get nav_record;

  /// No description provided for @nav_recordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get nav_recordings;

  /// No description provided for @nav_projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get nav_projects;

  /// No description provided for @nav_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get nav_profile;

  /// No description provided for @nav_admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get nav_admin;

  /// No description provided for @nav_collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get nav_collapse;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get common_remove;

  /// No description provided for @common_create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get common_create;

  /// No description provided for @common_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get common_continue;

  /// No description provided for @common_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get common_next;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get common_move;

  /// No description provided for @common_invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get common_invite;

  /// No description provided for @common_download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get common_download;

  /// No description provided for @common_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get common_clear;

  /// No description provided for @common_untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get common_untitled;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get common_loading;

  /// No description provided for @auth_oralCollector.
  ///
  /// In en, this message translates to:
  /// **'Oral Collector'**
  String get auth_oralCollector;

  /// No description provided for @auth_byShema.
  ///
  /// In en, this message translates to:
  /// **'by Shema'**
  String get auth_byShema;

  /// No description provided for @auth_heroTagline.
  ///
  /// In en, this message translates to:
  /// **'Preserve voices.\nShare stories.'**
  String get auth_heroTagline;

  /// No description provided for @auth_welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome\nBack'**
  String get auth_welcomeBack;

  /// No description provided for @auth_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome '**
  String get auth_welcome;

  /// No description provided for @auth_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get auth_back;

  /// No description provided for @auth_createWord.
  ///
  /// In en, this message translates to:
  /// **'Create '**
  String get auth_createWord;

  /// No description provided for @auth_createNewline.
  ///
  /// In en, this message translates to:
  /// **'Create\n'**
  String get auth_createNewline;

  /// No description provided for @auth_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get auth_account;

  /// No description provided for @auth_signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue collecting stories.'**
  String get auth_signInSubtitle;

  /// No description provided for @auth_signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join our community of story collectors.'**
  String get auth_signUpSubtitle;

  /// No description provided for @auth_backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get auth_backToSignIn;

  /// No description provided for @auth_emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get auth_emailLabel;

  /// No description provided for @auth_emailHint.
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get auth_emailHint;

  /// No description provided for @auth_emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get auth_emailRequired;

  /// No description provided for @auth_emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get auth_emailInvalid;

  /// No description provided for @auth_passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_passwordLabel;

  /// No description provided for @auth_passwordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get auth_passwordHint;

  /// No description provided for @auth_passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get auth_passwordRequired;

  /// No description provided for @auth_passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get auth_passwordTooShort;

  /// No description provided for @auth_confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get auth_confirmPasswordLabel;

  /// No description provided for @auth_confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get auth_confirmPasswordHint;

  /// No description provided for @auth_confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get auth_confirmPasswordRequired;

  /// No description provided for @auth_confirmPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get auth_confirmPasswordMismatch;

  /// No description provided for @auth_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get auth_nameLabel;

  /// No description provided for @auth_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Your full name'**
  String get auth_nameHint;

  /// No description provided for @auth_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your display name'**
  String get auth_nameRequired;

  /// No description provided for @auth_signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get auth_signIn;

  /// No description provided for @auth_signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get auth_signUp;

  /// No description provided for @auth_noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get auth_noAccount;

  /// No description provided for @auth_haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Have an account? '**
  String get auth_haveAccount;

  /// No description provided for @auth_continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get auth_continueButton;

  /// No description provided for @home_greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get home_greetingMorning;

  /// No description provided for @home_greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get home_greetingAfternoon;

  /// No description provided for @home_greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get home_greetingEvening;

  /// No description provided for @home_greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String home_greetingWithName(String greeting, String name);

  /// No description provided for @home_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s share your stories today'**
  String get home_subtitle;

  /// No description provided for @home_switchProject.
  ///
  /// In en, this message translates to:
  /// **'Switch project'**
  String get home_switchProject;

  /// No description provided for @home_genres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get home_genres;

  /// No description provided for @home_loadingProjects.
  ///
  /// In en, this message translates to:
  /// **'Loading projects...'**
  String get home_loadingProjects;

  /// No description provided for @home_loadingGenres.
  ///
  /// In en, this message translates to:
  /// **'Loading genres...'**
  String get home_loadingGenres;

  /// No description provided for @home_noGenres.
  ///
  /// In en, this message translates to:
  /// **'No genres available yet'**
  String get home_noGenres;

  /// No description provided for @home_noProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a project to get started'**
  String get home_noProjectTitle;

  /// No description provided for @home_browseProjects.
  ///
  /// In en, this message translates to:
  /// **'Browse Projects'**
  String get home_browseProjects;

  /// No description provided for @stats_recordings.
  ///
  /// In en, this message translates to:
  /// **'recordings'**
  String get stats_recordings;

  /// No description provided for @stats_recorded.
  ///
  /// In en, this message translates to:
  /// **'recorded'**
  String get stats_recorded;

  /// No description provided for @stats_members.
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get stats_members;

  /// No description provided for @project_switchTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch Project'**
  String get project_switchTitle;

  /// No description provided for @project_projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get project_projects;

  /// No description provided for @project_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your collections'**
  String get project_subtitle;

  /// No description provided for @project_noProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get project_noProjectsTitle;

  /// No description provided for @project_noProjectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first project to start collecting oral stories.'**
  String get project_noProjectsSubtitle;

  /// No description provided for @project_newProject.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get project_newProject;

  /// No description provided for @project_projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get project_projectName;

  /// No description provided for @project_projectNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kosrae Bible Translation'**
  String get project_projectNameHint;

  /// No description provided for @project_projectNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Project name is required'**
  String get project_projectNameRequired;

  /// No description provided for @project_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get project_description;

  /// No description provided for @project_descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get project_descriptionHint;

  /// No description provided for @project_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get project_language;

  /// No description provided for @project_selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select a language'**
  String get project_selectLanguage;

  /// No description provided for @project_pleaseSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Please select a language'**
  String get project_pleaseSelectLanguage;

  /// No description provided for @project_createProject.
  ///
  /// In en, this message translates to:
  /// **'Create Project'**
  String get project_createProject;

  /// No description provided for @project_selectLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get project_selectLanguageTitle;

  /// No description provided for @project_addLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Language'**
  String get project_addLanguageTitle;

  /// No description provided for @project_addLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find your language? Add it here.'**
  String get project_addLanguageSubtitle;

  /// No description provided for @project_languageName.
  ///
  /// In en, this message translates to:
  /// **'Language Name'**
  String get project_languageName;

  /// No description provided for @project_languageNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kosraean'**
  String get project_languageNameHint;

  /// No description provided for @project_languageNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get project_languageNameRequired;

  /// No description provided for @project_languageCode.
  ///
  /// In en, this message translates to:
  /// **'Language Code'**
  String get project_languageCode;

  /// No description provided for @project_languageCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. kos (ISO 639-3)'**
  String get project_languageCodeHint;

  /// No description provided for @project_languageCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Code is required'**
  String get project_languageCodeRequired;

  /// No description provided for @project_languageCodeTooLong.
  ///
  /// In en, this message translates to:
  /// **'Code must be 1-3 characters'**
  String get project_languageCodeTooLong;

  /// No description provided for @project_addLanguage.
  ///
  /// In en, this message translates to:
  /// **'Add Language'**
  String get project_addLanguage;

  /// No description provided for @project_noLanguagesFound.
  ///
  /// In en, this message translates to:
  /// **'No languages found'**
  String get project_noLanguagesFound;

  /// No description provided for @project_addNewLanguage.
  ///
  /// In en, this message translates to:
  /// **'Add new language'**
  String get project_addNewLanguage;

  /// No description provided for @project_addAsNewLanguage.
  ///
  /// In en, this message translates to:
  /// **'Add \"{query}\" as a new language'**
  String project_addAsNewLanguage(String query);

  /// No description provided for @project_searchLanguages.
  ///
  /// In en, this message translates to:
  /// **'Search languages...'**
  String get project_searchLanguages;

  /// No description provided for @project_backToList.
  ///
  /// In en, this message translates to:
  /// **'Back to list'**
  String get project_backToList;

  /// No description provided for @projectSettings_title.
  ///
  /// In en, this message translates to:
  /// **'Project Settings'**
  String get projectSettings_title;

  /// No description provided for @projectSettings_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get projectSettings_details;

  /// No description provided for @projectSettings_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get projectSettings_saving;

  /// No description provided for @projectSettings_saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get projectSettings_saveChanges;

  /// No description provided for @projectSettings_updated.
  ///
  /// In en, this message translates to:
  /// **'Project updated'**
  String get projectSettings_updated;

  /// No description provided for @projectSettings_noPermission.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to update this project'**
  String get projectSettings_noPermission;

  /// No description provided for @projectSettings_team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get projectSettings_team;

  /// No description provided for @projectSettings_removeMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get projectSettings_removeMember;

  /// No description provided for @projectSettings_removeMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this project?'**
  String projectSettings_removeMemberConfirm(String name);

  /// No description provided for @projectSettings_memberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed'**
  String get projectSettings_memberRemoved;

  /// No description provided for @projectSettings_memberRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove member'**
  String get projectSettings_memberRemoveFailed;

  /// No description provided for @projectSettings_inviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invite sent successfully'**
  String get projectSettings_inviteSent;

  /// No description provided for @projectSettings_noMembers.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get projectSettings_noMembers;

  /// No description provided for @recording_selectGenre.
  ///
  /// In en, this message translates to:
  /// **'Select Genre'**
  String get recording_selectGenre;

  /// No description provided for @recording_selectGenreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a genre for your story'**
  String get recording_selectGenreSubtitle;

  /// No description provided for @recording_selectSubcategory.
  ///
  /// In en, this message translates to:
  /// **'Select Subcategory'**
  String get recording_selectSubcategory;

  /// No description provided for @recording_selectSubcategorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a subcategory'**
  String get recording_selectSubcategorySubtitle;

  /// No description provided for @recording_selectRegister.
  ///
  /// In en, this message translates to:
  /// **'Select Register'**
  String get recording_selectRegister;

  /// No description provided for @recording_selectRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the speech register'**
  String get recording_selectRegisterSubtitle;

  /// No description provided for @recording_recordingStep.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recording_recordingStep;

  /// No description provided for @recording_recordingStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture your story'**
  String get recording_recordingStepSubtitle;

  /// No description provided for @recording_reviewStep.
  ///
  /// In en, this message translates to:
  /// **'Review Recording'**
  String get recording_reviewStep;

  /// No description provided for @recording_reviewStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Listen and save'**
  String get recording_reviewStepSubtitle;

  /// No description provided for @recording_genreNotFound.
  ///
  /// In en, this message translates to:
  /// **'Genre not found'**
  String get recording_genreNotFound;

  /// No description provided for @recording_noGenres.
  ///
  /// In en, this message translates to:
  /// **'No genres available'**
  String get recording_noGenres;

  /// No description provided for @recording_noSubcategories.
  ///
  /// In en, this message translates to:
  /// **'No subcategories available'**
  String get recording_noSubcategories;

  /// No description provided for @recording_registerDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the speech register that best describes the tone and formality of this recording.'**
  String get recording_registerDescription;

  /// No description provided for @recording_titleHint.
  ///
  /// In en, this message translates to:
  /// **'Add a title (optional)'**
  String get recording_titleHint;

  /// No description provided for @recording_saveRecording.
  ///
  /// In en, this message translates to:
  /// **'Save Recording'**
  String get recording_saveRecording;

  /// No description provided for @recording_recordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record Again'**
  String get recording_recordAgain;

  /// No description provided for @recording_discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get recording_discard;

  /// No description provided for @recording_discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard Recording?'**
  String get recording_discardTitle;

  /// No description provided for @recording_discardMessage.
  ///
  /// In en, this message translates to:
  /// **'This recording will be permanently deleted.'**
  String get recording_discardMessage;

  /// No description provided for @recording_saved.
  ///
  /// In en, this message translates to:
  /// **'Recording saved'**
  String get recording_saved;

  /// No description provided for @recording_notFound.
  ///
  /// In en, this message translates to:
  /// **'Recording not found'**
  String get recording_notFound;

  /// No description provided for @recording_unknownGenre.
  ///
  /// In en, this message translates to:
  /// **'Unknown genre'**
  String get recording_unknownGenre;

  /// No description provided for @recording_splitRecording.
  ///
  /// In en, this message translates to:
  /// **'Split Recording'**
  String get recording_splitRecording;

  /// No description provided for @recording_moveCategory.
  ///
  /// In en, this message translates to:
  /// **'Move Category'**
  String get recording_moveCategory;

  /// No description provided for @recording_downloadAudio.
  ///
  /// In en, this message translates to:
  /// **'Download Audio'**
  String get recording_downloadAudio;

  /// No description provided for @recording_downloadAudioMessage.
  ///
  /// In en, this message translates to:
  /// **'The audio file is not stored on this device. Would you like to download it to trim?'**
  String get recording_downloadAudioMessage;

  /// No description provided for @recording_downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download: {error}'**
  String recording_downloadFailed(String error);

  /// No description provided for @recording_audioNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Audio file not available'**
  String get recording_audioNotAvailable;

  /// No description provided for @recording_deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Recording'**
  String get recording_deleteTitle;

  /// No description provided for @recording_deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this recording from your device. If it has been uploaded, it will also be removed from the server. This action cannot be undone.'**
  String get recording_deleteMessage;

  /// No description provided for @recording_deleteNoPermission.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to delete this recording'**
  String get recording_deleteNoPermission;

  /// No description provided for @recording_deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete recording'**
  String get recording_deleteFailed;

  /// No description provided for @recording_deleteFailedLocal.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete from server. Removing locally.'**
  String get recording_deleteFailedLocal;

  /// No description provided for @recording_cleaningStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update cleaning status on server'**
  String get recording_cleaningStatusFailed;

  /// No description provided for @recording_updateNoPermission.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to update this recording'**
  String get recording_updateNoPermission;

  /// No description provided for @recording_moveNoPermission.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to move this recording'**
  String get recording_moveNoPermission;

  /// No description provided for @recording_movedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Recording moved successfully'**
  String get recording_movedSuccess;

  /// No description provided for @recording_updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update on server'**
  String get recording_updateFailed;

  /// No description provided for @recordings_title.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get recordings_title;

  /// No description provided for @recordings_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your collected stories'**
  String get recordings_subtitle;

  /// No description provided for @recordings_importAudio.
  ///
  /// In en, this message translates to:
  /// **'Import audio file'**
  String get recordings_importAudio;

  /// No description provided for @recordings_selectProject.
  ///
  /// In en, this message translates to:
  /// **'Select a project'**
  String get recordings_selectProject;

  /// No description provided for @recordings_selectProjectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a project to view its recordings'**
  String get recordings_selectProjectSubtitle;

  /// No description provided for @recordings_noRecordings.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet'**
  String get recordings_noRecordings;

  /// No description provided for @recordings_noRecordingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone to record your first story, or import an audio file.'**
  String get recordings_noRecordingsSubtitle;

  /// No description provided for @recordings_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recording} other{{count} recordings}}'**
  String recordings_count(int count);

  /// No description provided for @recording_statusUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get recording_statusUploaded;

  /// No description provided for @recording_statusUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get recording_statusUploading;

  /// No description provided for @recording_statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get recording_statusFailed;

  /// No description provided for @recording_statusLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get recording_statusLocal;

  /// No description provided for @recordings_clearStale.
  ///
  /// In en, this message translates to:
  /// **'Clear failed'**
  String get recordings_clearStale;

  /// No description provided for @recordings_clearStaleMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all recordings with failed or stuck upload status from the server. This cannot be undone.'**
  String get recordings_clearStaleMessage;

  /// No description provided for @recordings_clearedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No stale recordings found} =1{Cleared 1 recording} other{Cleared {count} recordings}}'**
  String recordings_clearedCount(int count);

  /// No description provided for @recordings_clearFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear recordings'**
  String get recordings_clearFailed;

  /// No description provided for @trim_title.
  ///
  /// In en, this message translates to:
  /// **'Split Recording'**
  String get trim_title;

  /// No description provided for @trim_notFound.
  ///
  /// In en, this message translates to:
  /// **'Recording not found'**
  String get trim_notFound;

  /// No description provided for @trim_audioUrlNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Audio URL not available for this recording.'**
  String get trim_audioUrlNotAvailable;

  /// No description provided for @trim_localNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Local audio file not available. Download the recording first.'**
  String get trim_localNotAvailable;

  /// No description provided for @trim_atLeastOneSegment.
  ///
  /// In en, this message translates to:
  /// **'At least one segment must be kept'**
  String get trim_atLeastOneSegment;

  /// No description provided for @trim_segments.
  ///
  /// In en, this message translates to:
  /// **'Segments'**
  String get trim_segments;

  /// No description provided for @trim_restoreAll.
  ///
  /// In en, this message translates to:
  /// **'Restore all'**
  String get trim_restoreAll;

  /// No description provided for @trim_instructions.
  ///
  /// In en, this message translates to:
  /// **'Tap on the waveform above to place\nsplit markers and divide this recording'**
  String get trim_instructions;

  /// No description provided for @trim_splitting.
  ///
  /// In en, this message translates to:
  /// **'Splitting...'**
  String get trim_splitting;

  /// No description provided for @trim_saveSegments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Save 1 segment} other{Save {count} segments}}'**
  String trim_saveSegments(int count);

  /// No description provided for @trim_addSplitsFirst.
  ///
  /// In en, this message translates to:
  /// **'Add splits first'**
  String get trim_addSplitsFirst;

  /// No description provided for @trim_savedSegments.
  ///
  /// In en, this message translates to:
  /// **'Saved {kept} segment{kept, plural, =1{} other{s}}, removed {removed}'**
  String trim_savedSegments(int kept, int removed);

  /// No description provided for @trim_splitInto.
  ///
  /// In en, this message translates to:
  /// **'Split into {count} recordings'**
  String trim_splitInto(int count);

  /// No description provided for @import_title.
  ///
  /// In en, this message translates to:
  /// **'Import Audio'**
  String get import_title;

  /// No description provided for @import_selectGenre.
  ///
  /// In en, this message translates to:
  /// **'Select Genre'**
  String get import_selectGenre;

  /// No description provided for @import_selectSubcategory.
  ///
  /// In en, this message translates to:
  /// **'Select Subcategory'**
  String get import_selectSubcategory;

  /// No description provided for @import_selectRegister.
  ///
  /// In en, this message translates to:
  /// **'Select Register'**
  String get import_selectRegister;

  /// No description provided for @import_confirmImport.
  ///
  /// In en, this message translates to:
  /// **'Confirm Import'**
  String get import_confirmImport;

  /// No description provided for @import_analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing audio file...'**
  String get import_analyzing;

  /// No description provided for @import_selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select an audio file to import'**
  String get import_selectFile;

  /// No description provided for @import_chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get import_chooseFile;

  /// No description provided for @import_accessFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not access selected file'**
  String get import_accessFailed;

  /// No description provided for @import_pickError.
  ///
  /// In en, this message translates to:
  /// **'Error picking file: {error}'**
  String import_pickError(String error);

  /// No description provided for @import_saveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving file: {error}'**
  String import_saveError(String error);

  /// No description provided for @import_unknownFile.
  ///
  /// In en, this message translates to:
  /// **'Unknown file'**
  String get import_unknownFile;

  /// No description provided for @import_importAndSave.
  ///
  /// In en, this message translates to:
  /// **'Import & Save'**
  String get import_importAndSave;

  /// No description provided for @moveCategory_title.
  ///
  /// In en, this message translates to:
  /// **'Move Category'**
  String get moveCategory_title;

  /// No description provided for @moveCategory_genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get moveCategory_genre;

  /// No description provided for @moveCategory_subcategory.
  ///
  /// In en, this message translates to:
  /// **'Subcategory'**
  String get moveCategory_subcategory;

  /// No description provided for @moveCategory_selectSubcategory.
  ///
  /// In en, this message translates to:
  /// **'Select subcategory'**
  String get moveCategory_selectSubcategory;

  /// No description provided for @cleaning_needsCleaning.
  ///
  /// In en, this message translates to:
  /// **'Needs Cleaning'**
  String get cleaning_needsCleaning;

  /// No description provided for @cleaning_cleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning...'**
  String get cleaning_cleaning;

  /// No description provided for @cleaning_cleaned.
  ///
  /// In en, this message translates to:
  /// **'Cleaned'**
  String get cleaning_cleaned;

  /// No description provided for @cleaning_cleanFailed.
  ///
  /// In en, this message translates to:
  /// **'Clean Failed'**
  String get cleaning_cleanFailed;

  /// No description provided for @sync_uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get sync_uploading;

  /// No description provided for @sync_pending.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String sync_pending(int count);

  /// No description provided for @profile_photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profile_photoUpdated;

  /// No description provided for @profile_photoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update photo: {error}'**
  String profile_photoFailed(String error);

  /// No description provided for @profile_editName.
  ///
  /// In en, this message translates to:
  /// **'Edit display name'**
  String get profile_editName;

  /// No description provided for @profile_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get profile_nameHint;

  /// No description provided for @profile_nameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Name updated'**
  String get profile_nameUpdated;

  /// No description provided for @profile_syncStorage.
  ///
  /// In en, this message translates to:
  /// **'Sync & Storage'**
  String get profile_syncStorage;

  /// No description provided for @profile_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profile_about;

  /// No description provided for @profile_appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get profile_appVersion;

  /// No description provided for @profile_byShema.
  ///
  /// In en, this message translates to:
  /// **'Oral Collector by Shema'**
  String get profile_byShema;

  /// No description provided for @profile_administration.
  ///
  /// In en, this message translates to:
  /// **'Administration'**
  String get profile_administration;

  /// No description provided for @profile_adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get profile_adminDashboard;

  /// No description provided for @profile_adminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System stats, projects & genre management'**
  String get profile_adminSubtitle;

  /// No description provided for @profile_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profile_account;

  /// No description provided for @profile_logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profile_logOut;

  /// No description provided for @profile_deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get profile_deleteAccount;

  /// No description provided for @profile_deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get profile_deleteAccountConfirm;

  /// No description provided for @profile_deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone. Your account will be deleted, but your uploaded recordings will be preserved for the language projects.'**
  String get profile_deleteAccountWarning;

  /// No description provided for @profile_typeDelete.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm account deletion:'**
  String get profile_typeDelete;

  /// No description provided for @profile_clearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear local cache?'**
  String get profile_clearCacheTitle;

  /// No description provided for @profile_clearCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'This will delete all locally stored recordings. Uploaded recordings on the server will not be affected.'**
  String get profile_clearCacheMessage;

  /// No description provided for @profile_cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Local cache cleared'**
  String get profile_cacheCleared;

  /// No description provided for @profile_joinedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Joined \"{name}\" successfully'**
  String profile_joinedSuccess(String name);

  /// No description provided for @profile_inviteDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invite declined'**
  String get profile_inviteDeclined;

  /// No description provided for @profile_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profile_language;

  /// No description provided for @profile_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get profile_online;

  /// No description provided for @profile_offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get profile_offline;

  /// No description provided for @profile_lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {time}'**
  String profile_lastSync(String time);

  /// No description provided for @profile_neverSynced.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get profile_neverSynced;

  /// No description provided for @profile_pendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String profile_pendingCount(int count);

  /// No description provided for @profile_syncingProgress.
  ///
  /// In en, this message translates to:
  /// **'Syncing... {percent}%'**
  String profile_syncingProgress(int percent);

  /// No description provided for @profile_syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get profile_syncNow;

  /// No description provided for @profile_wifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Upload on Wi-Fi only'**
  String get profile_wifiOnly;

  /// No description provided for @profile_wifiOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prevent uploads over cellular data'**
  String get profile_wifiOnlySubtitle;

  /// No description provided for @profile_autoRemove.
  ///
  /// In en, this message translates to:
  /// **'Auto-remove after upload'**
  String get profile_autoRemove;

  /// No description provided for @profile_autoRemoveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete local files after successful upload'**
  String get profile_autoRemoveSubtitle;

  /// No description provided for @profile_clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear local cache'**
  String get profile_clearCache;

  /// No description provided for @profile_clearCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all locally stored recordings'**
  String get profile_clearCacheSubtitle;

  /// No description provided for @profile_invitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get profile_invitations;

  /// No description provided for @profile_refreshInvitations.
  ///
  /// In en, this message translates to:
  /// **'Refresh invitations'**
  String get profile_refreshInvitations;

  /// No description provided for @profile_noInvitations.
  ///
  /// In en, this message translates to:
  /// **'No pending invitations'**
  String get profile_noInvitations;

  /// No description provided for @profile_roleManager.
  ///
  /// In en, this message translates to:
  /// **'Role: Manager'**
  String get profile_roleManager;

  /// No description provided for @profile_roleMember.
  ///
  /// In en, this message translates to:
  /// **'Role: Member'**
  String get profile_roleMember;

  /// No description provided for @profile_decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get profile_decline;

  /// No description provided for @profile_accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get profile_accept;

  /// No description provided for @profile_storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get profile_storage;

  /// No description provided for @profile_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get profile_status;

  /// No description provided for @profile_pendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get profile_pendingLabel;

  /// No description provided for @admin_title.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get admin_title;

  /// No description provided for @admin_overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get admin_overview;

  /// No description provided for @admin_projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get admin_projects;

  /// No description provided for @admin_genres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get admin_genres;

  /// No description provided for @admin_cleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get admin_cleaning;

  /// No description provided for @admin_accessRequired.
  ///
  /// In en, this message translates to:
  /// **'Admin access required'**
  String get admin_accessRequired;

  /// No description provided for @admin_totalProjects.
  ///
  /// In en, this message translates to:
  /// **'Total Projects'**
  String get admin_totalProjects;

  /// No description provided for @admin_languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get admin_languages;

  /// No description provided for @admin_recordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get admin_recordings;

  /// No description provided for @admin_totalHours.
  ///
  /// In en, this message translates to:
  /// **'Total Hours'**
  String get admin_totalHours;

  /// No description provided for @admin_activeUsers.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get admin_activeUsers;

  /// No description provided for @admin_projectName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get admin_projectName;

  /// No description provided for @admin_projectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get admin_projectLanguage;

  /// No description provided for @admin_projectMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get admin_projectMembers;

  /// No description provided for @admin_projectRecordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get admin_projectRecordings;

  /// No description provided for @admin_projectDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get admin_projectDuration;

  /// No description provided for @admin_projectCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get admin_projectCreated;

  /// No description provided for @admin_noProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects found'**
  String get admin_noProjects;

  /// No description provided for @admin_unknownLanguage.
  ///
  /// In en, this message translates to:
  /// **'Unknown language'**
  String get admin_unknownLanguage;

  /// No description provided for @admin_genresAndSubcategories.
  ///
  /// In en, this message translates to:
  /// **'Genres & Subcategories'**
  String get admin_genresAndSubcategories;

  /// No description provided for @admin_addGenre.
  ///
  /// In en, this message translates to:
  /// **'Add Genre'**
  String get admin_addGenre;

  /// No description provided for @admin_noGenres.
  ///
  /// In en, this message translates to:
  /// **'No genres found'**
  String get admin_noGenres;

  /// No description provided for @admin_genreName.
  ///
  /// In en, this message translates to:
  /// **'Genre Name'**
  String get admin_genreName;

  /// No description provided for @admin_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get admin_required;

  /// No description provided for @admin_descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get admin_descriptionOptional;

  /// No description provided for @admin_genreCreated.
  ///
  /// In en, this message translates to:
  /// **'Genre created'**
  String get admin_genreCreated;

  /// No description provided for @admin_editGenre.
  ///
  /// In en, this message translates to:
  /// **'Edit genre'**
  String get admin_editGenre;

  /// No description provided for @admin_deleteGenre.
  ///
  /// In en, this message translates to:
  /// **'Delete genre'**
  String get admin_deleteGenre;

  /// No description provided for @admin_addSubcategory.
  ///
  /// In en, this message translates to:
  /// **'Add subcategory'**
  String get admin_addSubcategory;

  /// No description provided for @admin_editGenreTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Genre'**
  String get admin_editGenreTitle;

  /// No description provided for @admin_genreUpdated.
  ///
  /// In en, this message translates to:
  /// **'Genre updated'**
  String get admin_genreUpdated;

  /// No description provided for @admin_deleteGenreTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Genre'**
  String get admin_deleteGenreTitle;

  /// No description provided for @admin_deleteGenreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and all its subcategories?'**
  String admin_deleteGenreConfirm(String name);

  /// No description provided for @admin_genreDeleted.
  ///
  /// In en, this message translates to:
  /// **'Genre deleted'**
  String get admin_genreDeleted;

  /// No description provided for @admin_addSubcategoryTo.
  ///
  /// In en, this message translates to:
  /// **'Add Subcategory to {name}'**
  String admin_addSubcategoryTo(String name);

  /// No description provided for @admin_subcategoryName.
  ///
  /// In en, this message translates to:
  /// **'Subcategory Name'**
  String get admin_subcategoryName;

  /// No description provided for @admin_subcategoryCreated.
  ///
  /// In en, this message translates to:
  /// **'Subcategory created'**
  String get admin_subcategoryCreated;

  /// No description provided for @admin_deleteSubcategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Subcategory'**
  String get admin_deleteSubcategory;

  /// No description provided for @admin_deleteSubcategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String admin_deleteSubcategoryConfirm(String name);

  /// No description provided for @admin_subcategoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Subcategory deleted'**
  String get admin_subcategoryDeleted;

  /// No description provided for @admin_cleaningQueue.
  ///
  /// In en, this message translates to:
  /// **'Audio Cleaning Queue'**
  String get admin_cleaningQueue;

  /// No description provided for @admin_cleanSelected.
  ///
  /// In en, this message translates to:
  /// **'Clean Selected ({count})'**
  String admin_cleanSelected(int count);

  /// No description provided for @admin_refreshCleaning.
  ///
  /// In en, this message translates to:
  /// **'Refresh cleaning queue'**
  String get admin_refreshCleaning;

  /// No description provided for @admin_cleaningWebOnly.
  ///
  /// In en, this message translates to:
  /// **'Audio cleaning is a web-only feature. Cleaning processes run on the server.'**
  String get admin_cleaningWebOnly;

  /// No description provided for @admin_noCleaningRecordings.
  ///
  /// In en, this message translates to:
  /// **'No recordings flagged for cleaning'**
  String get admin_noCleaningRecordings;

  /// No description provided for @admin_cleaningTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get admin_cleaningTitle;

  /// No description provided for @admin_cleaningDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get admin_cleaningDuration;

  /// No description provided for @admin_cleaningSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get admin_cleaningSize;

  /// No description provided for @admin_cleaningFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get admin_cleaningFormat;

  /// No description provided for @admin_cleaningRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get admin_cleaningRecorded;

  /// No description provided for @admin_cleaningActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get admin_cleaningActions;

  /// No description provided for @admin_clean.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get admin_clean;

  /// No description provided for @admin_deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get admin_deselectAll;

  /// No description provided for @admin_selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get admin_selectAll;

  /// No description provided for @admin_cleaningTriggered.
  ///
  /// In en, this message translates to:
  /// **'Cleaning triggered'**
  String get admin_cleaningTriggered;

  /// No description provided for @admin_cleaningFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to trigger cleaning'**
  String get admin_cleaningFailed;

  /// No description provided for @admin_cleaningPartial.
  ///
  /// In en, this message translates to:
  /// **'Cleaning triggered for {success} of {total} recordings'**
  String admin_cleaningPartial(int success, int total);

  /// No description provided for @genre_title.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genre_title;

  /// No description provided for @genre_notFound.
  ///
  /// In en, this message translates to:
  /// **'Genre not found'**
  String get genre_notFound;

  /// No description provided for @genre_recordingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recording} other{{count} recordings}}'**
  String genre_recordingCount(int count);

  /// No description provided for @format_justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get format_justNow;

  /// No description provided for @format_minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String format_minutesAgo(int count);

  /// No description provided for @format_hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String format_hoursAgo(int count);

  /// No description provided for @format_daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String format_daysAgo(int count);

  /// No description provided for @format_weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}w ago'**
  String format_weeksAgo(int count);

  /// No description provided for @format_monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String format_monthsAgo(int count);

  /// No description provided for @format_memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String format_memberSince(String date);

  /// No description provided for @format_member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get format_member;

  /// No description provided for @format_dateAt.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String format_dateAt(String date, String time);

  /// No description provided for @genre_narrative.
  ///
  /// In en, this message translates to:
  /// **'Narrative'**
  String get genre_narrative;

  /// No description provided for @genre_narrativeDesc.
  ///
  /// In en, this message translates to:
  /// **'Stories, accounts, and narrative forms of oral tradition'**
  String get genre_narrativeDesc;

  /// No description provided for @genre_poeticSong.
  ///
  /// In en, this message translates to:
  /// **'Poetic / Song'**
  String get genre_poeticSong;

  /// No description provided for @genre_poeticSongDesc.
  ///
  /// In en, this message translates to:
  /// **'Musical and poetic oral traditions including hymns, laments, and wisdom poetry'**
  String get genre_poeticSongDesc;

  /// No description provided for @genre_instructional.
  ///
  /// In en, this message translates to:
  /// **'Instructional / Regulatory'**
  String get genre_instructional;

  /// No description provided for @genre_instructionalDesc.
  ///
  /// In en, this message translates to:
  /// **'Laws, rituals, procedures, and instructional forms'**
  String get genre_instructionalDesc;

  /// No description provided for @genre_oralDiscourse.
  ///
  /// In en, this message translates to:
  /// **'Oral Discourse'**
  String get genre_oralDiscourse;

  /// No description provided for @genre_oralDiscourseDesc.
  ///
  /// In en, this message translates to:
  /// **'Speeches, teachings, prayers, and discursive oral forms'**
  String get genre_oralDiscourseDesc;

  /// No description provided for @sub_historicalNarrative.
  ///
  /// In en, this message translates to:
  /// **'Historical Narrative'**
  String get sub_historicalNarrative;

  /// No description provided for @sub_personalAccount.
  ///
  /// In en, this message translates to:
  /// **'Personal Account / Testimony'**
  String get sub_personalAccount;

  /// No description provided for @sub_parable.
  ///
  /// In en, this message translates to:
  /// **'Parable / Illustrative Story'**
  String get sub_parable;

  /// No description provided for @sub_originStory.
  ///
  /// In en, this message translates to:
  /// **'Origin / Creation Story'**
  String get sub_originStory;

  /// No description provided for @sub_legend.
  ///
  /// In en, this message translates to:
  /// **'Legend / Hero Story'**
  String get sub_legend;

  /// No description provided for @sub_visionNarrative.
  ///
  /// In en, this message translates to:
  /// **'Vision or Dream Narrative'**
  String get sub_visionNarrative;

  /// No description provided for @sub_genealogy.
  ///
  /// In en, this message translates to:
  /// **'Genealogy'**
  String get sub_genealogy;

  /// No description provided for @sub_eventReport.
  ///
  /// In en, this message translates to:
  /// **'Recent Event Report'**
  String get sub_eventReport;

  /// No description provided for @sub_hymn.
  ///
  /// In en, this message translates to:
  /// **'Hymn / Worship Song'**
  String get sub_hymn;

  /// No description provided for @sub_lament.
  ///
  /// In en, this message translates to:
  /// **'Lament'**
  String get sub_lament;

  /// No description provided for @sub_funeralDirge.
  ///
  /// In en, this message translates to:
  /// **'Funeral Dirge'**
  String get sub_funeralDirge;

  /// No description provided for @sub_victorySong.
  ///
  /// In en, this message translates to:
  /// **'Victory / Celebration Song'**
  String get sub_victorySong;

  /// No description provided for @sub_loveSong.
  ///
  /// In en, this message translates to:
  /// **'Love Song'**
  String get sub_loveSong;

  /// No description provided for @sub_tauntSong.
  ///
  /// In en, this message translates to:
  /// **'Mocking / Taunt Song'**
  String get sub_tauntSong;

  /// No description provided for @sub_blessing.
  ///
  /// In en, this message translates to:
  /// **'Blessing'**
  String get sub_blessing;

  /// No description provided for @sub_curse.
  ///
  /// In en, this message translates to:
  /// **'Curse'**
  String get sub_curse;

  /// No description provided for @sub_wisdomPoem.
  ///
  /// In en, this message translates to:
  /// **'Wisdom Poem / Proverb'**
  String get sub_wisdomPoem;

  /// No description provided for @sub_didacticPoetry.
  ///
  /// In en, this message translates to:
  /// **'Didactic Poetry'**
  String get sub_didacticPoetry;

  /// No description provided for @sub_legalCode.
  ///
  /// In en, this message translates to:
  /// **'Law / Legal Code'**
  String get sub_legalCode;

  /// No description provided for @sub_ritual.
  ///
  /// In en, this message translates to:
  /// **'Ritual / Liturgy'**
  String get sub_ritual;

  /// No description provided for @sub_procedure.
  ///
  /// In en, this message translates to:
  /// **'Procedure / Instruction'**
  String get sub_procedure;

  /// No description provided for @sub_listInventory.
  ///
  /// In en, this message translates to:
  /// **'List / Inventory'**
  String get sub_listInventory;

  /// No description provided for @sub_propheticOracle.
  ///
  /// In en, this message translates to:
  /// **'Prophetic Oracle / Speech'**
  String get sub_propheticOracle;

  /// No description provided for @sub_exhortation.
  ///
  /// In en, this message translates to:
  /// **'Exhortation / Sermon'**
  String get sub_exhortation;

  /// No description provided for @sub_wisdomTeaching.
  ///
  /// In en, this message translates to:
  /// **'Wisdom Teaching'**
  String get sub_wisdomTeaching;

  /// No description provided for @sub_prayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get sub_prayer;

  /// No description provided for @sub_dialogue.
  ///
  /// In en, this message translates to:
  /// **'Dialogue'**
  String get sub_dialogue;

  /// No description provided for @sub_epistle.
  ///
  /// In en, this message translates to:
  /// **'Epistle / Letter'**
  String get sub_epistle;

  /// No description provided for @sub_apocalypticDiscourse.
  ///
  /// In en, this message translates to:
  /// **'Apocalyptic Discourse'**
  String get sub_apocalypticDiscourse;

  /// No description provided for @sub_ceremonialSpeech.
  ///
  /// In en, this message translates to:
  /// **'Ceremonial Speech'**
  String get sub_ceremonialSpeech;

  /// No description provided for @sub_communityMemory.
  ///
  /// In en, this message translates to:
  /// **'Community Memory'**
  String get sub_communityMemory;

  /// No description provided for @sub_historicalNarrativeDesc.
  ///
  /// In en, this message translates to:
  /// **'Accounts of events, wars, and key moments in history'**
  String get sub_historicalNarrativeDesc;

  /// No description provided for @sub_personalAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'First-person stories of personal experiences and faith'**
  String get sub_personalAccountDesc;

  /// No description provided for @sub_parableDesc.
  ///
  /// In en, this message translates to:
  /// **'Symbolic stories that teach moral or spiritual lessons'**
  String get sub_parableDesc;

  /// No description provided for @sub_originStoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Stories about how things came to be'**
  String get sub_originStoryDesc;

  /// No description provided for @sub_legendDesc.
  ///
  /// In en, this message translates to:
  /// **'Tales of remarkable people and their great deeds'**
  String get sub_legendDesc;

  /// No description provided for @sub_visionNarrativeDesc.
  ///
  /// In en, this message translates to:
  /// **'Accounts of divine visions and prophetic dreams'**
  String get sub_visionNarrativeDesc;

  /// No description provided for @sub_genealogyDesc.
  ///
  /// In en, this message translates to:
  /// **'Records of family lines and ancestral lineages'**
  String get sub_genealogyDesc;

  /// No description provided for @sub_eventReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Reports of recent happenings in the community'**
  String get sub_eventReportDesc;

  /// No description provided for @sub_hymnDesc.
  ///
  /// In en, this message translates to:
  /// **'Songs of praise and worship to God'**
  String get sub_hymnDesc;

  /// No description provided for @sub_lamentDesc.
  ///
  /// In en, this message translates to:
  /// **'Expressions of grief, sorrow, and mourning'**
  String get sub_lamentDesc;

  /// No description provided for @sub_funeralDirgeDesc.
  ///
  /// In en, this message translates to:
  /// **'Songs performed during mourning and burial ceremonies'**
  String get sub_funeralDirgeDesc;

  /// No description provided for @sub_victorySongDesc.
  ///
  /// In en, this message translates to:
  /// **'Songs celebrating triumphs and joyful events'**
  String get sub_victorySongDesc;

  /// No description provided for @sub_loveSongDesc.
  ///
  /// In en, this message translates to:
  /// **'Songs expressing love and devotion'**
  String get sub_loveSongDesc;

  /// No description provided for @sub_tauntSongDesc.
  ///
  /// In en, this message translates to:
  /// **'Songs of ridicule aimed at enemies or the unfaithful'**
  String get sub_tauntSongDesc;

  /// No description provided for @sub_blessingDesc.
  ///
  /// In en, this message translates to:
  /// **'Words invoking divine favor and protection'**
  String get sub_blessingDesc;

  /// No description provided for @sub_curseDesc.
  ///
  /// In en, this message translates to:
  /// **'Pronouncements of judgment or divine consequence'**
  String get sub_curseDesc;

  /// No description provided for @sub_wisdomPoemDesc.
  ///
  /// In en, this message translates to:
  /// **'Short sayings and poems conveying practical wisdom'**
  String get sub_wisdomPoemDesc;

  /// No description provided for @sub_didacticPoetryDesc.
  ///
  /// In en, this message translates to:
  /// **'Poetic compositions designed to teach and instruct'**
  String get sub_didacticPoetryDesc;

  /// No description provided for @sub_legalCodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Rules, statutes, and covenant regulations'**
  String get sub_legalCodeDesc;

  /// No description provided for @sub_ritualDesc.
  ///
  /// In en, this message translates to:
  /// **'Prescribed forms of worship and sacred ceremonies'**
  String get sub_ritualDesc;

  /// No description provided for @sub_procedureDesc.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step directions and practical guidelines'**
  String get sub_procedureDesc;

  /// No description provided for @sub_listInventoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Catalogs, censuses, and organized records'**
  String get sub_listInventoryDesc;

  /// No description provided for @sub_propheticOracleDesc.
  ///
  /// In en, this message translates to:
  /// **'Messages delivered on behalf of God'**
  String get sub_propheticOracleDesc;

  /// No description provided for @sub_exhortationDesc.
  ///
  /// In en, this message translates to:
  /// **'Speeches urging moral and spiritual action'**
  String get sub_exhortationDesc;

  /// No description provided for @sub_wisdomTeachingDesc.
  ///
  /// In en, this message translates to:
  /// **'Instruction on living wisely and righteously'**
  String get sub_wisdomTeachingDesc;

  /// No description provided for @sub_prayerDesc.
  ///
  /// In en, this message translates to:
  /// **'Words addressed to God in worship or petition'**
  String get sub_prayerDesc;

  /// No description provided for @sub_dialogueDesc.
  ///
  /// In en, this message translates to:
  /// **'Conversations and exchanges between people'**
  String get sub_dialogueDesc;

  /// No description provided for @sub_epistleDesc.
  ///
  /// In en, this message translates to:
  /// **'Written messages addressed to communities or individuals'**
  String get sub_epistleDesc;

  /// No description provided for @sub_apocalypticDiscourseDesc.
  ///
  /// In en, this message translates to:
  /// **'Revelations about the end times and God\'s plan'**
  String get sub_apocalypticDiscourseDesc;

  /// No description provided for @sub_ceremonialSpeechDesc.
  ///
  /// In en, this message translates to:
  /// **'Formal addresses for official or sacred occasions'**
  String get sub_ceremonialSpeechDesc;

  /// No description provided for @sub_communityMemoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Shared recollections that preserve group identity'**
  String get sub_communityMemoryDesc;

  /// No description provided for @register_intimate.
  ///
  /// In en, this message translates to:
  /// **'Intimate'**
  String get register_intimate;

  /// No description provided for @register_casual.
  ///
  /// In en, this message translates to:
  /// **'Informal / Casual'**
  String get register_casual;

  /// No description provided for @register_consultative.
  ///
  /// In en, this message translates to:
  /// **'Consultative'**
  String get register_consultative;

  /// No description provided for @register_formal.
  ///
  /// In en, this message translates to:
  /// **'Formal / Official'**
  String get register_formal;

  /// No description provided for @register_ceremonial.
  ///
  /// In en, this message translates to:
  /// **'Ceremonial'**
  String get register_ceremonial;

  /// No description provided for @register_elderAuthority.
  ///
  /// In en, this message translates to:
  /// **'Elder / Authority'**
  String get register_elderAuthority;

  /// No description provided for @register_religiousWorship.
  ///
  /// In en, this message translates to:
  /// **'Religious / Worship'**
  String get register_religiousWorship;

  /// No description provided for @locale_english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get locale_english;

  /// No description provided for @locale_portuguese.
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get locale_portuguese;

  /// No description provided for @locale_hindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get locale_hindi;

  /// No description provided for @locale_korean.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get locale_korean;

  /// No description provided for @locale_spanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get locale_spanish;

  /// No description provided for @locale_bahasa.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get locale_bahasa;

  /// No description provided for @locale_french.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get locale_french;

  /// No description provided for @locale_tokPisin.
  ///
  /// In en, this message translates to:
  /// **'Tok Pisin'**
  String get locale_tokPisin;

  /// No description provided for @locale_swahili.
  ///
  /// In en, this message translates to:
  /// **'Kiswahili'**
  String get locale_swahili;

  /// No description provided for @locale_arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get locale_arabic;

  /// No description provided for @locale_englishSub.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get locale_englishSub;

  /// No description provided for @locale_portugueseSub.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get locale_portugueseSub;

  /// No description provided for @locale_hindiSub.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get locale_hindiSub;

  /// No description provided for @locale_koreanSub.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get locale_koreanSub;

  /// No description provided for @locale_spanishSub.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get locale_spanishSub;

  /// No description provided for @locale_bahasaSub.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get locale_bahasaSub;

  /// No description provided for @locale_frenchSub.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get locale_frenchSub;

  /// No description provided for @locale_tokPisinSub.
  ///
  /// In en, this message translates to:
  /// **'Tok Pisin'**
  String get locale_tokPisinSub;

  /// No description provided for @locale_swahiliSub.
  ///
  /// In en, this message translates to:
  /// **'Swahili'**
  String get locale_swahiliSub;

  /// No description provided for @locale_arabicSub.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get locale_arabicSub;

  /// No description provided for @locale_chinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get locale_chinese;

  /// No description provided for @locale_chineseSub.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get locale_chineseSub;

  /// No description provided for @locale_selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get locale_selectLanguage;

  /// No description provided for @locale_selectLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in your profile settings.'**
  String get locale_selectLanguageSubtitle;

  /// No description provided for @filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filter_all;

  /// No description provided for @filter_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get filter_pending;

  /// No description provided for @filter_uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get filter_uploaded;

  /// No description provided for @filter_needsCleaning.
  ///
  /// In en, this message translates to:
  /// **'Needs Cleaning'**
  String get filter_needsCleaning;

  /// No description provided for @filter_unclassified.
  ///
  /// In en, this message translates to:
  /// **'Unclassified'**
  String get filter_unclassified;

  /// No description provided for @filter_allGenres.
  ///
  /// In en, this message translates to:
  /// **'All genres'**
  String get filter_allGenres;

  /// No description provided for @detail_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get detail_duration;

  /// No description provided for @detail_size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get detail_size;

  /// No description provided for @detail_format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get detail_format;

  /// No description provided for @detail_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get detail_status;

  /// No description provided for @detail_upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get detail_upload;

  /// No description provided for @detail_uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get detail_uploaded;

  /// No description provided for @detail_cleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get detail_cleaning;

  /// No description provided for @detail_recorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get detail_recorded;

  /// No description provided for @detail_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get detail_retry;

  /// No description provided for @detail_notFlagged.
  ///
  /// In en, this message translates to:
  /// **'Not flagged'**
  String get detail_notFlagged;

  /// No description provided for @detail_uploadStuck.
  ///
  /// In en, this message translates to:
  /// **'Stuck — tap Retry'**
  String get detail_uploadStuck;

  /// No description provided for @detail_uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get detail_uploading;

  /// No description provided for @detail_maxRetries.
  ///
  /// In en, this message translates to:
  /// **'Max retries — tap Retry'**
  String get detail_maxRetries;

  /// No description provided for @detail_uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload Failed'**
  String get detail_uploadFailed;

  /// No description provided for @detail_pendingRetried.
  ///
  /// In en, this message translates to:
  /// **'Pending (retried)'**
  String get detail_pendingRetried;

  /// No description provided for @detail_notSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced'**
  String get detail_notSynced;

  /// No description provided for @action_actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get action_actions;

  /// No description provided for @action_split.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get action_split;

  /// No description provided for @action_flagClean.
  ///
  /// In en, this message translates to:
  /// **'Flag Clean'**
  String get action_flagClean;

  /// No description provided for @action_clearFlag.
  ///
  /// In en, this message translates to:
  /// **'Clear Flag'**
  String get action_clearFlag;

  /// No description provided for @action_move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get action_move;

  /// No description provided for @action_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get action_delete;

  /// No description provided for @projectStats_recordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get projectStats_recordings;

  /// No description provided for @projectStats_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get projectStats_duration;

  /// No description provided for @projectStats_members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get projectStats_members;

  /// No description provided for @project_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get project_active;

  /// No description provided for @recording_paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get recording_paused;

  /// No description provided for @recording_recording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get recording_recording;

  /// No description provided for @recording_tapToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap to Record'**
  String get recording_tapToRecord;

  /// No description provided for @recording_sensitivity.
  ///
  /// In en, this message translates to:
  /// **'Sensitivity'**
  String get recording_sensitivity;

  /// No description provided for @recording_sensitivityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get recording_sensitivityLow;

  /// No description provided for @recording_sensitivityMed.
  ///
  /// In en, this message translates to:
  /// **'Med'**
  String get recording_sensitivityMed;

  /// No description provided for @recording_sensitivityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get recording_sensitivityHigh;

  /// No description provided for @recording_stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get recording_stopRecording;

  /// No description provided for @recording_stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get recording_stop;

  /// No description provided for @recording_resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get recording_resume;

  /// No description provided for @recording_pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get recording_pause;

  /// No description provided for @quickRecord_title.
  ///
  /// In en, this message translates to:
  /// **'Quick Record'**
  String get quickRecord_title;

  /// No description provided for @quickRecord_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Classify later'**
  String get quickRecord_subtitle;

  /// No description provided for @quickRecord_classifyLater.
  ///
  /// In en, this message translates to:
  /// **'Classify later'**
  String get quickRecord_classifyLater;

  /// No description provided for @classify_title.
  ///
  /// In en, this message translates to:
  /// **'Classify Recording'**
  String get classify_title;

  /// No description provided for @classify_action.
  ///
  /// In en, this message translates to:
  /// **'Classify'**
  String get classify_action;

  /// No description provided for @classify_banner.
  ///
  /// In en, this message translates to:
  /// **'This recording needs classification before it can be uploaded.'**
  String get classify_banner;

  /// No description provided for @classify_success.
  ///
  /// In en, this message translates to:
  /// **'Recording classified'**
  String get classify_success;

  /// No description provided for @classify_register.
  ///
  /// In en, this message translates to:
  /// **'Register (optional)'**
  String get classify_register;

  /// No description provided for @classify_selectRegister.
  ///
  /// In en, this message translates to:
  /// **'Select register'**
  String get classify_selectRegister;

  /// No description provided for @recording_unclassified.
  ///
  /// In en, this message translates to:
  /// **'Unclassified'**
  String get recording_unclassified;

  /// No description provided for @fab_quickRecord.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get fab_quickRecord;

  /// No description provided for @fab_normalRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get fab_normalRecord;

  /// No description provided for @error_network.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the server. Please check your internet connection and try again.'**
  String get error_network;

  /// No description provided for @error_secureConnection.
  ///
  /// In en, this message translates to:
  /// **'A secure connection could not be established. Please try again later.'**
  String get error_secureConnection;

  /// No description provided for @error_timeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Please check your connection and try again.'**
  String get error_timeout;

  /// No description provided for @error_invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please try again.'**
  String get error_invalidCredentials;

  /// No description provided for @error_userNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with that email address.'**
  String get error_userNotFound;

  /// No description provided for @error_accountExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get error_accountExists;

  /// No description provided for @error_emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address.'**
  String get error_emailRequired;

  /// No description provided for @error_passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get error_passwordRequired;

  /// No description provided for @error_signupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create your account. Please check your details and try again.'**
  String get error_signupFailed;

  /// No description provided for @error_sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get error_sessionExpired;

  /// No description provided for @error_profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile. Please try again.'**
  String get error_profileLoadFailed;

  /// No description provided for @error_profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update your profile. Please try again.'**
  String get error_profileUpdateFailed;

  /// No description provided for @error_imageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not upload the image. Please try again.'**
  String get error_imageUploadFailed;

  /// No description provided for @error_notAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'You are not signed in. Please log in and try again.'**
  String get error_notAuthenticated;

  /// No description provided for @error_noPermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action.'**
  String get error_noPermission;

  /// No description provided for @error_generic.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again later.'**
  String get error_generic;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'en',
    'es',
    'fr',
    'hi',
    'id',
    'ko',
    'pt',
    'sw',
    'tpi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'sw':
      return AppLocalizationsSw();
    case 'tpi':
      return AppLocalizationsTpi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
