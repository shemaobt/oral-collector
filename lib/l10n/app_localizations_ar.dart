// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Oral Collector';

  @override
  String get nav_home => 'الرئيسية';

  @override
  String get nav_record => 'تسجيل';

  @override
  String get nav_recordings => 'التسجيلات';

  @override
  String get nav_projects => 'المشاريع';

  @override
  String get nav_profile => 'الملف الشخصي';

  @override
  String get nav_admin => 'المشرف';

  @override
  String get nav_collapse => 'طي';

  @override
  String get common_cancel => 'إلغاء';

  @override
  String get common_save => 'حفظ';

  @override
  String get common_delete => 'حذف';

  @override
  String get common_remove => 'إزالة';

  @override
  String get common_create => 'إنشاء';

  @override
  String get common_continue => 'متابعة';

  @override
  String get common_next => 'التالي';

  @override
  String get common_retry => 'إعادة المحاولة';

  @override
  String get common_move => 'نقل';

  @override
  String get common_invite => 'دعوة';

  @override
  String get common_download => 'تحميل';

  @override
  String get common_clear => 'مسح';

  @override
  String get common_untitled => 'بدون عنوان';

  @override
  String get common_loading => 'جارٍ التحميل...';

  @override
  String get auth_oralCollector => 'Oral Collector';

  @override
  String get auth_byShema => 'من Shema';

  @override
  String get auth_heroTagline => 'احفظ الأصوات.\nشارك القصص.';

  @override
  String get auth_welcomeBack => 'مرحباً\nبعودتك';

  @override
  String get auth_welcome => 'مرحباً ';

  @override
  String get auth_back => 'رجوع';

  @override
  String get auth_createWord => 'إنشاء ';

  @override
  String get auth_createNewline => 'إنشاء\n';

  @override
  String get auth_account => 'حساب';

  @override
  String get auth_signInSubtitle => 'سجّل الدخول لمتابعة جمع القصص.';

  @override
  String get auth_signUpSubtitle => 'انضم إلى مجتمعنا من جامعي القصص.';

  @override
  String get auth_backToSignIn => 'العودة لتسجيل الدخول';

  @override
  String get auth_emailLabel => 'البريد الإلكتروني';

  @override
  String get auth_emailHint => 'بريدك@الإلكتروني.com';

  @override
  String get auth_emailRequired => 'يرجى إدخال بريدك الإلكتروني';

  @override
  String get auth_emailInvalid => 'يرجى إدخال بريد إلكتروني صالح';

  @override
  String get auth_passwordLabel => 'كلمة المرور';

  @override
  String get auth_passwordHint => '٦ أحرف على الأقل';

  @override
  String get auth_passwordRequired => 'يرجى إدخال كلمة المرور';

  @override
  String get auth_passwordTooShort =>
      'يجب أن تتكون كلمة المرور من ٦ أحرف على الأقل';

  @override
  String get auth_confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get auth_confirmPasswordHint => 'أعد إدخال كلمة المرور';

  @override
  String get auth_confirmPasswordRequired => 'يرجى تأكيد كلمة المرور';

  @override
  String get auth_confirmPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get auth_nameLabel => 'الاسم';

  @override
  String get auth_nameHint => 'اسمك الكامل';

  @override
  String get auth_nameRequired => 'يرجى إدخال اسم العرض';

  @override
  String get auth_signIn => 'تسجيل الدخول';

  @override
  String get auth_signUp => 'إنشاء حساب';

  @override
  String get auth_noAccount => 'ليس لديك حساب؟ ';

  @override
  String get auth_haveAccount => 'لديك حساب بالفعل؟ ';

  @override
  String get auth_continueButton => 'متابعة';

  @override
  String get home_greetingMorning => 'صباح الخير';

  @override
  String get home_greetingAfternoon => 'مساء الخير';

  @override
  String get home_greetingEvening => 'مساء الخير';

  @override
  String home_greetingWithName(String greeting, String name) {
    return '$greeting، $name';
  }

  @override
  String get home_subtitle => 'لنشارك قصصك اليوم';

  @override
  String get home_switchProject => 'تبديل المشروع';

  @override
  String get home_genres => 'الأنواع';

  @override
  String get home_loadingProjects => 'جارٍ تحميل المشاريع...';

  @override
  String get home_loadingGenres => 'جارٍ تحميل الأنواع...';

  @override
  String get home_noGenres => 'لا توجد أنواع متاحة بعد';

  @override
  String get home_noProjectTitle => 'اختر مشروعاً للبدء';

  @override
  String get home_browseProjects => 'تصفح المشاريع';

  @override
  String get stats_recordings => 'تسجيلات';

  @override
  String get stats_recorded => 'مسجّل';

  @override
  String get stats_members => 'أعضاء';

  @override
  String get project_switchTitle => 'تبديل المشروع';

  @override
  String get project_projects => 'المشاريع';

  @override
  String get project_subtitle => 'إدارة مجموعاتك';

  @override
  String get project_noProjectsTitle => 'لا توجد مشاريع بعد';

  @override
  String get project_noProjectsSubtitle =>
      'أنشئ مشروعك الأول لبدء جمع القصص الشفهية.';

  @override
  String get project_newProject => 'مشروع جديد';

  @override
  String get project_projectName => 'اسم المشروع';

  @override
  String get project_projectNameHint => 'مثال: ترجمة الكتاب المقدس كوسراي';

  @override
  String get project_projectNameRequired => 'اسم المشروع مطلوب';

  @override
  String get project_description => 'الوصف';

  @override
  String get project_descriptionHint => 'اختياري';

  @override
  String get project_language => 'اللغة';

  @override
  String get project_selectLanguage => 'اختر لغة';

  @override
  String get project_pleaseSelectLanguage => 'يرجى اختيار لغة';

  @override
  String get project_createProject => 'إنشاء المشروع';

  @override
  String get project_selectLanguageTitle => 'اختيار اللغة';

  @override
  String get project_addLanguageTitle => 'إضافة لغة';

  @override
  String get project_addLanguageSubtitle => 'لم تجد لغتك؟ أضفها هنا.';

  @override
  String get project_languageName => 'اسم اللغة';

  @override
  String get project_languageNameHint => 'مثال: كوسراي';

  @override
  String get project_languageNameRequired => 'الاسم مطلوب';

  @override
  String get project_languageCode => 'رمز اللغة';

  @override
  String get project_languageCodeHint => 'مثال: kos (ISO 639-3)';

  @override
  String get project_languageCodeRequired => 'الرمز مطلوب';

  @override
  String get project_languageCodeTooLong => 'يجب أن يكون الرمز من ١ إلى ٣ أحرف';

  @override
  String get project_addLanguage => 'إضافة اللغة';

  @override
  String get project_noLanguagesFound => 'لم يتم العثور على لغات';

  @override
  String get project_addNewLanguage => 'إضافة لغة جديدة';

  @override
  String project_addAsNewLanguage(String query) {
    return 'إضافة \"$query\" كلغة جديدة';
  }

  @override
  String get project_searchLanguages => 'البحث عن لغات...';

  @override
  String get project_backToList => 'العودة إلى القائمة';

  @override
  String get projectSettings_title => 'إعدادات المشروع';

  @override
  String get projectSettings_details => 'التفاصيل';

  @override
  String get projectSettings_saving => 'جارٍ الحفظ...';

  @override
  String get projectSettings_saveChanges => 'حفظ التغييرات';

  @override
  String get projectSettings_updated => 'تم تحديث المشروع';

  @override
  String get projectSettings_noPermission =>
      'ليس لديك صلاحية لتحديث هذا المشروع';

  @override
  String get projectSettings_team => 'الفريق';

  @override
  String get projectSettings_removeMember => 'إزالة العضو';

  @override
  String projectSettings_removeMemberConfirm(String name) {
    return 'إزالة $name من هذا المشروع؟';
  }

  @override
  String get projectSettings_memberRemoved => 'تمت إزالة العضو';

  @override
  String get projectSettings_memberRemoveFailed => 'فشل في إزالة العضو';

  @override
  String get projectSettings_inviteSent => 'تم إرسال الدعوة بنجاح';

  @override
  String get projectSettings_noMembers => 'لا يوجد أعضاء بعد';

  @override
  String get recording_selectGenre => 'اختيار النوع';

  @override
  String get recording_selectGenreSubtitle => 'اختر نوعاً لقصتك';

  @override
  String get recording_selectSubcategory => 'اختيار الفئة الفرعية';

  @override
  String get recording_selectSubcategorySubtitle => 'اختر فئة فرعية';

  @override
  String get recording_selectRegister => 'اختيار السجل';

  @override
  String get recording_selectRegisterSubtitle => 'اختر سجل الكلام';

  @override
  String get recording_recordingStep => 'التسجيل';

  @override
  String get recording_recordingStepSubtitle => 'سجّل قصتك';

  @override
  String get recording_reviewStep => 'مراجعة التسجيل';

  @override
  String get recording_reviewStepSubtitle => 'استمع واحفظ';

  @override
  String get recording_genreNotFound => 'النوع غير موجود';

  @override
  String get recording_noGenres => 'لا توجد أنواع متاحة';

  @override
  String get recording_noSubcategories => 'لا توجد فئات فرعية متاحة';

  @override
  String get recording_registerDescription =>
      'اختر سجل الكلام الذي يصف أفضل نبرة وشكلية هذا التسجيل.';

  @override
  String get recording_titleHint => 'أضف عنواناً (اختياري)';

  @override
  String get recording_saveRecording => 'حفظ التسجيل';

  @override
  String get recording_recordAgain => 'إعادة التسجيل';

  @override
  String get recording_discard => 'تجاهل';

  @override
  String get recording_discardTitle => 'تجاهل التسجيل؟';

  @override
  String get recording_discardMessage => 'سيتم حذف هذا التسجيل نهائياً.';

  @override
  String get recording_saved => 'تم حفظ التسجيل';

  @override
  String get recording_notFound => 'التسجيل غير موجود';

  @override
  String get recording_unknownGenre => 'نوع غير معروف';

  @override
  String get recording_splitRecording => 'تقسيم التسجيل';

  @override
  String get recording_moveCategory => 'نقل الفئة';

  @override
  String get recording_downloadAudio => 'تحميل الصوت';

  @override
  String get recording_downloadAudioMessage =>
      'ملف الصوت غير مخزن على هذا الجهاز. هل تريد تحميله للقص؟';

  @override
  String recording_downloadFailed(String error) {
    return 'فشل التحميل: $error';
  }

  @override
  String get recording_audioNotAvailable => 'ملف الصوت غير متاح';

  @override
  String get recording_deleteTitle => 'حذف التسجيل';

  @override
  String get recording_deleteMessage =>
      'سيؤدي هذا إلى حذف هذا التسجيل نهائياً من جهازك. إذا تم رفعه، فسيتم حذفه من الخادم أيضاً. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get recording_deleteNoPermission => 'ليس لديك صلاحية لحذف هذا التسجيل';

  @override
  String get recording_deleteFailed => 'فشل في حذف التسجيل';

  @override
  String get recording_deleteFailedLocal =>
      'فشل الحذف من الخادم. جارٍ الحذف محلياً.';

  @override
  String get recording_cleaningStatusFailed =>
      'فشل في تحديث حالة التنظيف على الخادم';

  @override
  String get recording_updateNoPermission =>
      'ليس لديك صلاحية لتحديث هذا التسجيل';

  @override
  String get recording_moveNoPermission => 'ليس لديك صلاحية لنقل هذا التسجيل';

  @override
  String get recording_movedSuccess => 'تم نقل التسجيل بنجاح';

  @override
  String get recording_updateFailed => 'فشل في التحديث على الخادم';

  @override
  String get recordings_title => 'التسجيلات';

  @override
  String get recordings_subtitle => 'قصصك المجمّعة';

  @override
  String get recordings_importAudio => 'استيراد ملف صوتي';

  @override
  String get recordings_selectProject => 'اختر مشروعاً';

  @override
  String get recordings_selectProjectSubtitle => 'اختر مشروعاً لعرض تسجيلاته';

  @override
  String get recordings_noRecordings => 'لا توجد تسجيلات بعد';

  @override
  String get recordings_noRecordingsSubtitle =>
      'انقر على الميكروفون لتسجيل أول قصة لك، أو استورد ملفاً صوتياً.';

  @override
  String recordings_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تسجيلات',
      one: 'تسجيل واحد',
    );
    return '$_temp0';
  }

  @override
  String get recording_statusUploaded => 'تم الرفع';

  @override
  String get recording_statusUploading => 'جارٍ الرفع';

  @override
  String get recording_statusFailed => 'فشل';

  @override
  String get recording_statusLocal => 'محلي';

  @override
  String get trim_title => 'تقسيم التسجيل';

  @override
  String get trim_notFound => 'التسجيل غير موجود';

  @override
  String get trim_audioUrlNotAvailable => 'رابط الصوت غير متاح لهذا التسجيل.';

  @override
  String get trim_localNotAvailable =>
      'ملف الصوت المحلي غير متاح. قم بتحميل التسجيل أولاً.';

  @override
  String get trim_atLeastOneSegment => 'يجب الاحتفاظ بمقطع واحد على الأقل';

  @override
  String get trim_segments => 'المقاطع';

  @override
  String get trim_restoreAll => 'استعادة الكل';

  @override
  String get trim_instructions =>
      'انقر على شكل الموجة أعلاه لوضع\nعلامات التقسيم وتقسيم هذا التسجيل';

  @override
  String get trim_splitting => 'جارٍ التقسيم...';

  @override
  String trim_saveSegments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حفظ $count مقاطع',
      one: 'حفظ مقطع واحد',
    );
    return '$_temp0';
  }

  @override
  String get trim_addSplitsFirst => 'أضف تقسيمات أولاً';

  @override
  String trim_savedSegments(int kept, int removed) {
    return 'تم حفظ $kept مقطع، وإزالة $removed';
  }

  @override
  String trim_splitInto(int count) {
    return 'تقسيم إلى $count تسجيلات';
  }

  @override
  String get import_title => 'استيراد الصوت';

  @override
  String get import_selectGenre => 'اختيار النوع';

  @override
  String get import_selectSubcategory => 'اختيار الفئة الفرعية';

  @override
  String get import_selectRegister => 'اختيار السجل';

  @override
  String get import_confirmImport => 'تأكيد الاستيراد';

  @override
  String get import_analyzing => 'جارٍ تحليل ملف الصوت...';

  @override
  String get import_selectFile => 'اختر ملفاً صوتياً للاستيراد';

  @override
  String get import_chooseFile => 'اختيار ملف';

  @override
  String get import_accessFailed => 'تعذر الوصول إلى الملف المحدد';

  @override
  String import_pickError(String error) {
    return 'خطأ في اختيار الملف: $error';
  }

  @override
  String import_saveError(String error) {
    return 'خطأ في حفظ الملف: $error';
  }

  @override
  String get import_unknownFile => 'ملف غير معروف';

  @override
  String get import_importAndSave => 'استيراد وحفظ';

  @override
  String get moveCategory_title => 'نقل الفئة';

  @override
  String get moveCategory_genre => 'النوع';

  @override
  String get moveCategory_subcategory => 'الفئة الفرعية';

  @override
  String get moveCategory_selectSubcategory => 'اختيار الفئة الفرعية';

  @override
  String get cleaning_needsCleaning => 'يحتاج تنظيف';

  @override
  String get cleaning_cleaning => 'جارٍ التنظيف...';

  @override
  String get cleaning_cleaned => 'تم التنظيف';

  @override
  String get cleaning_cleanFailed => 'فشل التنظيف';

  @override
  String get sync_uploading => 'جارٍ الرفع...';

  @override
  String sync_pending(int count) {
    return '$count قيد الانتظار';
  }

  @override
  String get profile_photoUpdated => 'تم تحديث صورة الملف الشخصي';

  @override
  String profile_photoFailed(String error) {
    return 'فشل في تحديث الصورة: $error';
  }

  @override
  String get profile_editName => 'تعديل اسم العرض';

  @override
  String get profile_nameHint => 'اسمك';

  @override
  String get profile_nameUpdated => 'تم تحديث الاسم';

  @override
  String get profile_syncStorage => 'المزامنة والتخزين';

  @override
  String get profile_about => 'حول';

  @override
  String get profile_appVersion => 'إصدار التطبيق';

  @override
  String get profile_byShema => 'Oral Collector من Shema';

  @override
  String get profile_administration => 'الإدارة';

  @override
  String get profile_adminDashboard => 'لوحة المشرف';

  @override
  String get profile_adminSubtitle =>
      'إحصائيات النظام والمشاريع وإدارة الأنواع';

  @override
  String get profile_account => 'الحساب';

  @override
  String get profile_logOut => 'تسجيل الخروج';

  @override
  String get profile_clearCacheTitle => 'مسح الذاكرة المؤقتة المحلية؟';

  @override
  String get profile_clearCacheMessage =>
      'سيؤدي هذا إلى حذف جميع التسجيلات المخزنة محلياً. لن تتأثر التسجيلات المرفوعة على الخادم.';

  @override
  String get profile_cacheCleared => 'تم مسح الذاكرة المؤقتة المحلية';

  @override
  String profile_joinedSuccess(String name) {
    return 'انضممت إلى \"$name\" بنجاح';
  }

  @override
  String get profile_inviteDeclined => 'تم رفض الدعوة';

  @override
  String get profile_language => 'اللغة';

  @override
  String get profile_online => 'متصل';

  @override
  String get profile_offline => 'غير متصل';

  @override
  String profile_lastSync(String time) {
    return 'آخر مزامنة: $time';
  }

  @override
  String get profile_neverSynced => 'لم تتم المزامنة أبداً';

  @override
  String profile_pendingCount(int count) {
    return '$count قيد الانتظار';
  }

  @override
  String profile_syncingProgress(int percent) {
    return 'جارٍ المزامنة... $percent٪';
  }

  @override
  String get profile_syncNow => 'مزامنة الآن';

  @override
  String get profile_wifiOnly => 'الرفع عبر Wi-Fi فقط';

  @override
  String get profile_wifiOnlySubtitle => 'منع الرفع عبر بيانات الجوال';

  @override
  String get profile_autoRemove => 'إزالة تلقائية بعد الرفع';

  @override
  String get profile_autoRemoveSubtitle =>
      'حذف الملفات المحلية بعد الرفع الناجح';

  @override
  String get profile_clearCache => 'مسح الذاكرة المؤقتة المحلية';

  @override
  String get profile_clearCacheSubtitle => 'حذف جميع التسجيلات المخزنة محلياً';

  @override
  String get profile_invitations => 'الدعوات';

  @override
  String get profile_refreshInvitations => 'تحديث الدعوات';

  @override
  String get profile_noInvitations => 'لا توجد دعوات معلقة';

  @override
  String get profile_roleManager => 'الدور: مدير';

  @override
  String get profile_roleMember => 'الدور: عضو';

  @override
  String get profile_decline => 'رفض';

  @override
  String get profile_accept => 'قبول';

  @override
  String get profile_storage => 'التخزين';

  @override
  String get profile_status => 'الحالة';

  @override
  String get profile_pendingLabel => 'قيد الانتظار';

  @override
  String get admin_title => 'لوحة المشرف';

  @override
  String get admin_overview => 'نظرة عامة';

  @override
  String get admin_projects => 'المشاريع';

  @override
  String get admin_genres => 'الأنواع';

  @override
  String get admin_cleaning => 'التنظيف';

  @override
  String get admin_accessRequired => 'مطلوب صلاحية المشرف';

  @override
  String get admin_totalProjects => 'إجمالي المشاريع';

  @override
  String get admin_languages => 'اللغات';

  @override
  String get admin_recordings => 'التسجيلات';

  @override
  String get admin_totalHours => 'إجمالي الساعات';

  @override
  String get admin_activeUsers => 'المستخدمون النشطون';

  @override
  String get admin_projectName => 'الاسم';

  @override
  String get admin_projectLanguage => 'اللغة';

  @override
  String get admin_projectMembers => 'الأعضاء';

  @override
  String get admin_projectRecordings => 'التسجيلات';

  @override
  String get admin_projectDuration => 'المدة';

  @override
  String get admin_projectCreated => 'تاريخ الإنشاء';

  @override
  String get admin_noProjects => 'لم يتم العثور على مشاريع';

  @override
  String get admin_unknownLanguage => 'لغة غير معروفة';

  @override
  String get admin_genresAndSubcategories => 'الأنواع والفئات الفرعية';

  @override
  String get admin_addGenre => 'إضافة نوع';

  @override
  String get admin_noGenres => 'لم يتم العثور على أنواع';

  @override
  String get admin_genreName => 'اسم النوع';

  @override
  String get admin_required => 'مطلوب';

  @override
  String get admin_descriptionOptional => 'الوصف (اختياري)';

  @override
  String get admin_genreCreated => 'تم إنشاء النوع';

  @override
  String get admin_editGenre => 'تعديل النوع';

  @override
  String get admin_deleteGenre => 'حذف النوع';

  @override
  String get admin_addSubcategory => 'إضافة فئة فرعية';

  @override
  String get admin_editGenreTitle => 'تعديل النوع';

  @override
  String get admin_genreUpdated => 'تم تحديث النوع';

  @override
  String get admin_deleteGenreTitle => 'حذف النوع';

  @override
  String admin_deleteGenreConfirm(String name) {
    return 'حذف \"$name\" وجميع فئاته الفرعية؟';
  }

  @override
  String get admin_genreDeleted => 'تم حذف النوع';

  @override
  String admin_addSubcategoryTo(String name) {
    return 'إضافة فئة فرعية إلى $name';
  }

  @override
  String get admin_subcategoryName => 'اسم الفئة الفرعية';

  @override
  String get admin_subcategoryCreated => 'تم إنشاء الفئة الفرعية';

  @override
  String get admin_deleteSubcategory => 'حذف الفئة الفرعية';

  @override
  String admin_deleteSubcategoryConfirm(String name) {
    return 'حذف \"$name\"؟';
  }

  @override
  String get admin_subcategoryDeleted => 'تم حذف الفئة الفرعية';

  @override
  String get admin_cleaningQueue => 'قائمة انتظار تنظيف الصوت';

  @override
  String admin_cleanSelected(int count) {
    return 'تنظيف المحدد ($count)';
  }

  @override
  String get admin_refreshCleaning => 'تحديث قائمة التنظيف';

  @override
  String get admin_cleaningWebOnly =>
      'تنظيف الصوت ميزة للويب فقط. عمليات التنظيف تعمل على الخادم.';

  @override
  String get admin_noCleaningRecordings => 'لا توجد تسجيلات مُعلّمة للتنظيف';

  @override
  String get admin_cleaningTitle => 'العنوان';

  @override
  String get admin_cleaningDuration => 'المدة';

  @override
  String get admin_cleaningSize => 'الحجم';

  @override
  String get admin_cleaningFormat => 'الصيغة';

  @override
  String get admin_cleaningRecorded => 'تاريخ التسجيل';

  @override
  String get admin_cleaningActions => 'الإجراءات';

  @override
  String get admin_clean => 'تنظيف';

  @override
  String get admin_deselectAll => 'إلغاء تحديد الكل';

  @override
  String get admin_selectAll => 'تحديد الكل';

  @override
  String get admin_cleaningTriggered => 'تم بدء التنظيف';

  @override
  String get admin_cleaningFailed => 'فشل في بدء التنظيف';

  @override
  String admin_cleaningPartial(int success, int total) {
    return 'تم بدء التنظيف لـ $success من $total تسجيلات';
  }

  @override
  String get genre_title => 'النوع';

  @override
  String get genre_notFound => 'النوع غير موجود';

  @override
  String genre_recordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تسجيلات',
      one: 'تسجيل واحد',
    );
    return '$_temp0';
  }

  @override
  String get format_justNow => 'الآن';

  @override
  String format_minutesAgo(int count) {
    return 'منذ $count د';
  }

  @override
  String format_hoursAgo(int count) {
    return 'منذ $count س';
  }

  @override
  String format_daysAgo(int count) {
    return 'منذ $count ي';
  }

  @override
  String format_weeksAgo(int count) {
    return 'منذ $count أ';
  }

  @override
  String format_monthsAgo(int count) {
    return 'منذ $count ش';
  }

  @override
  String format_memberSince(String date) {
    return 'عضو منذ $date';
  }

  @override
  String get format_member => 'عضو';

  @override
  String format_dateAt(String date, String time) {
    return '$date الساعة $time';
  }

  @override
  String get genre_narrative => 'سردي';

  @override
  String get genre_narrativeDesc =>
      'القصص والروايات والأشكال السردية من التراث الشفهي';

  @override
  String get genre_poeticSong => 'شعر / أغنية';

  @override
  String get genre_poeticSongDesc =>
      'التقاليد الشفهية الموسيقية والشعرية بما في ذلك التراتيل والمراثي وشعر الحكمة';

  @override
  String get genre_instructional => 'تعليمي / تنظيمي';

  @override
  String get genre_instructionalDesc =>
      'القوانين والطقوس والإجراءات والأشكال التعليمية';

  @override
  String get genre_oralDiscourse => 'الخطاب الشفهي';

  @override
  String get genre_oralDiscourseDesc =>
      'الخطب والتعاليم والصلوات والأشكال الخطابية الشفهية';

  @override
  String get sub_historicalNarrative => 'سرد تاريخي';

  @override
  String get sub_personalAccount => 'رواية شخصية / شهادة';

  @override
  String get sub_parable => 'مثل / قصة توضيحية';

  @override
  String get sub_originStory => 'قصة الأصل / الخلق';

  @override
  String get sub_legend => 'أسطورة / قصة بطل';

  @override
  String get sub_visionNarrative => 'سرد رؤيا أو حلم';

  @override
  String get sub_genealogy => 'سلسلة أنساب';

  @override
  String get sub_eventReport => 'تقرير حدث حديث';

  @override
  String get sub_hymn => 'ترنيمة / نشيد عبادة';

  @override
  String get sub_lament => 'رثاء';

  @override
  String get sub_funeralDirge => 'نشيد جنائزي';

  @override
  String get sub_victorySong => 'نشيد نصر / احتفال';

  @override
  String get sub_loveSong => 'أغنية حب';

  @override
  String get sub_tauntSong => 'أغنية سخرية / استهزاء';

  @override
  String get sub_blessing => 'بركة';

  @override
  String get sub_curse => 'لعنة';

  @override
  String get sub_wisdomPoem => 'قصيدة حكمة / مثل';

  @override
  String get sub_didacticPoetry => 'شعر تعليمي';

  @override
  String get sub_legalCode => 'قانون / تشريع';

  @override
  String get sub_ritual => 'طقس / ليتورجيا';

  @override
  String get sub_procedure => 'إجراء / تعليمات';

  @override
  String get sub_listInventory => 'قائمة / جرد';

  @override
  String get sub_propheticOracle => 'نبوءة / خطاب نبوي';

  @override
  String get sub_exhortation => 'وعظ / خطبة';

  @override
  String get sub_wisdomTeaching => 'تعليم الحكمة';

  @override
  String get sub_prayer => 'صلاة';

  @override
  String get sub_dialogue => 'حوار';

  @override
  String get sub_epistle => 'رسالة';

  @override
  String get sub_apocalypticDiscourse => 'خطاب نهاية الأزمنة';

  @override
  String get sub_ceremonialSpeech => 'خطاب احتفالي';

  @override
  String get sub_communityMemory => 'ذاكرة المجتمع';

  @override
  String get sub_historicalNarrativeDesc =>
      'روايات الأحداث والحروب واللحظات المفصلية في التاريخ';

  @override
  String get sub_personalAccountDesc =>
      'قصص شخصية عن التجارب الحياتية والإيمان';

  @override
  String get sub_parableDesc => 'قصص رمزية تُعلّم دروساً أخلاقية أو روحية';

  @override
  String get sub_originStoryDesc => 'قصص عن كيفية نشأة الأشياء';

  @override
  String get sub_legendDesc => 'حكايات أشخاص بارزين وأعمالهم العظيمة';

  @override
  String get sub_visionNarrativeDesc => 'روايات الرؤى الإلهية والأحلام النبوية';

  @override
  String get sub_genealogyDesc => 'سجلات سلالات العائلات والأنساب';

  @override
  String get sub_eventReportDesc => 'تقارير الأحداث الأخيرة في المجتمع';

  @override
  String get sub_hymnDesc => 'أناشيد التسبيح والعبادة لله';

  @override
  String get sub_lamentDesc => 'تعبيرات الحزن والأسى والحداد';

  @override
  String get sub_funeralDirgeDesc => 'أناشيد تُؤدّى أثناء مراسم الحداد والدفن';

  @override
  String get sub_victorySongDesc =>
      'أناشيد الاحتفال بالانتصارات والمناسبات السعيدة';

  @override
  String get sub_loveSongDesc => 'أغانٍ تعبّر عن الحب والإخلاص';

  @override
  String get sub_tauntSongDesc => 'أغانٍ ساخرة موجهة للأعداء أو غير المؤمنين';

  @override
  String get sub_blessingDesc => 'كلمات تستدعي الرعاية والحماية الإلهية';

  @override
  String get sub_curseDesc => 'إعلانات الحكم أو العاقبة الإلهية';

  @override
  String get sub_wisdomPoemDesc => 'أمثال وقصائد تنقل الحكمة العملية';

  @override
  String get sub_didacticPoetryDesc => 'أعمال شعرية مصممة للتعليم والإرشاد';

  @override
  String get sub_legalCodeDesc => 'القواعد والأنظمة ولوائح العهد';

  @override
  String get sub_ritualDesc => 'أشكال العبادة والاحتفالات المقدسة المحددة';

  @override
  String get sub_procedureDesc => 'إرشادات عملية وتوجيهات خطوة بخطوة';

  @override
  String get sub_listInventoryDesc => 'فهارس وتعدادات وسجلات منظمة';

  @override
  String get sub_propheticOracleDesc => 'رسائل مُقدّمة باسم الله';

  @override
  String get sub_exhortationDesc => 'خطب تحث على العمل الأخلاقي والروحي';

  @override
  String get sub_wisdomTeachingDesc => 'تعليم حول العيش بحكمة واستقامة';

  @override
  String get sub_prayerDesc => 'كلمات موجهة لله في العبادة أو الدعاء';

  @override
  String get sub_dialogueDesc => 'محادثات وتبادلات بين الأشخاص';

  @override
  String get sub_epistleDesc => 'رسائل مكتوبة موجهة للمجتمعات أو الأفراد';

  @override
  String get sub_apocalypticDiscourseDesc =>
      'إعلانات عن نهاية الأزمنة وخطة الله';

  @override
  String get sub_ceremonialSpeechDesc =>
      'خطب رسمية للمناسبات الرسمية أو المقدسة';

  @override
  String get sub_communityMemoryDesc => 'ذكريات مشتركة تحفظ هوية المجموعة';

  @override
  String get register_intimate => 'حميمي';

  @override
  String get register_casual => 'غير رسمي / عادي';

  @override
  String get register_consultative => 'استشاري';

  @override
  String get register_formal => 'رسمي';

  @override
  String get register_ceremonial => 'احتفالي';

  @override
  String get register_elderAuthority => 'كبير / ذو سلطة';

  @override
  String get register_religiousWorship => 'ديني / عبادي';

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
  String get locale_englishSub => 'الإنجليزية';

  @override
  String get locale_portugueseSub => 'البرتغالية';

  @override
  String get locale_hindiSub => 'الهندية';

  @override
  String get locale_koreanSub => 'الكورية';

  @override
  String get locale_spanishSub => 'الإسبانية';

  @override
  String get locale_bahasaSub => 'الإندونيسية';

  @override
  String get locale_frenchSub => 'الفرنسية';

  @override
  String get locale_tokPisinSub => 'توك بيسين';

  @override
  String get locale_swahiliSub => 'السواحيلية';

  @override
  String get locale_arabicSub => 'العربية';

  @override
  String get locale_selectLanguage => 'اختر لغتك';

  @override
  String get locale_selectLanguageSubtitle =>
      'يمكنك تغيير هذا لاحقاً في إعدادات ملفك الشخصي.';

  @override
  String get filter_all => 'الكل';

  @override
  String get filter_pending => 'قيد الانتظار';

  @override
  String get filter_uploaded => 'تم الرفع';

  @override
  String get filter_needsCleaning => 'يحتاج تنظيف';

  @override
  String get filter_allGenres => 'جميع الأنواع';

  @override
  String get detail_duration => 'المدة';

  @override
  String get detail_size => 'الحجم';

  @override
  String get detail_format => 'الصيغة';

  @override
  String get detail_status => 'الحالة';

  @override
  String get detail_upload => 'الرفع';

  @override
  String get detail_uploaded => 'تم الرفع';

  @override
  String get detail_cleaning => 'التنظيف';

  @override
  String get detail_recorded => 'تاريخ التسجيل';

  @override
  String get detail_retry => 'إعادة المحاولة';

  @override
  String get detail_notFlagged => 'غير مُعلّم';

  @override
  String get detail_uploadStuck => 'متوقف — انقر إعادة المحاولة';

  @override
  String get detail_uploading => 'جارٍ الرفع...';

  @override
  String get detail_maxRetries => 'أقصى محاولات — انقر إعادة المحاولة';

  @override
  String get detail_uploadFailed => 'فشل الرفع';

  @override
  String get detail_pendingRetried => 'قيد الانتظار (أُعيدت المحاولة)';

  @override
  String get detail_notSynced => 'غير مُزامن';

  @override
  String get action_actions => 'الإجراءات';

  @override
  String get action_split => 'تقسيم';

  @override
  String get action_flagClean => 'تعليم للتنظيف';

  @override
  String get action_clearFlag => 'إزالة التعليم';

  @override
  String get action_move => 'نقل';

  @override
  String get action_delete => 'حذف';

  @override
  String get projectStats_recordings => 'التسجيلات';

  @override
  String get projectStats_duration => 'المدة';

  @override
  String get projectStats_members => 'الأعضاء';

  @override
  String get project_active => 'نشط';

  @override
  String get recording_paused => 'متوقف مؤقتاً';

  @override
  String get recording_recording => 'جارٍ التسجيل';

  @override
  String get recording_tapToRecord => 'انقر للتسجيل';

  @override
  String get recording_sensitivity => 'الحساسية';

  @override
  String get recording_sensitivityLow => 'منخفض';

  @override
  String get recording_sensitivityMed => 'متوسط';

  @override
  String get recording_sensitivityHigh => 'مرتفع';

  @override
  String get recording_stopRecording => 'إيقاف التسجيل';

  @override
  String get recording_stop => 'إيقاف';

  @override
  String get recording_resume => 'استئناف';

  @override
  String get recording_pause => 'إيقاف مؤقت';
}
