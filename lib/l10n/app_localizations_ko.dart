// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Oral Collector';

  @override
  String get nav_home => '홈';

  @override
  String get nav_record => '녹음';

  @override
  String get nav_recordings => '녹음 목록';

  @override
  String get nav_projects => '프로젝트';

  @override
  String get nav_profile => '프로필';

  @override
  String get nav_admin => '관리';

  @override
  String get nav_collapse => '접기';

  @override
  String get common_cancel => '취소';

  @override
  String get common_save => '저장';

  @override
  String get common_delete => '삭제';

  @override
  String get common_remove => '제거';

  @override
  String get common_create => '만들기';

  @override
  String get common_continue => '계속';

  @override
  String get common_next => '다음';

  @override
  String get common_retry => '재시도';

  @override
  String get common_move => '이동';

  @override
  String get common_invite => '초대';

  @override
  String get common_download => '다운로드';

  @override
  String get common_clear => '지우기';

  @override
  String get common_untitled => '제목 없음';

  @override
  String get common_loading => '로딩 중...';

  @override
  String get auth_oralCollector => 'Oral Collector';

  @override
  String get auth_byShema => 'by Shema';

  @override
  String get auth_heroTagline => '목소리를 보존하고\n이야기를 나누세요.';

  @override
  String get auth_welcomeBack => '다시 오신 것을\n환영합니다';

  @override
  String get auth_welcome => '환영합니다 ';

  @override
  String get auth_back => '뒤로';

  @override
  String get auth_createWord => '만들기 ';

  @override
  String get auth_createNewline => '만들기\n';

  @override
  String get auth_account => '계정';

  @override
  String get auth_signInSubtitle => '이야기를 계속 수집하려면 로그인하세요.';

  @override
  String get auth_signUpSubtitle => '이야기 수집 커뮤니티에 참여하세요.';

  @override
  String get auth_backToSignIn => '로그인으로 돌아가기';

  @override
  String get auth_emailLabel => '이메일 주소';

  @override
  String get auth_emailHint => 'your@email.com';

  @override
  String get auth_emailRequired => '이메일을 입력해 주세요';

  @override
  String get auth_emailInvalid => '유효한 이메일을 입력해 주세요';

  @override
  String get auth_passwordLabel => '비밀번호';

  @override
  String get auth_passwordHint => '6자 이상';

  @override
  String get auth_passwordRequired => '비밀번호를 입력해 주세요';

  @override
  String get auth_passwordTooShort => '비밀번호는 6자 이상이어야 합니다';

  @override
  String get auth_confirmPasswordLabel => '비밀번호 확인';

  @override
  String get auth_confirmPasswordHint => '비밀번호 재입력';

  @override
  String get auth_confirmPasswordRequired => '비밀번호를 확인해 주세요';

  @override
  String get auth_confirmPasswordMismatch => '비밀번호가 일치하지 않습니다';

  @override
  String get auth_nameLabel => '이름';

  @override
  String get auth_nameHint => '이름을 입력하세요';

  @override
  String get auth_nameRequired => '표시 이름을 입력해 주세요';

  @override
  String get auth_signIn => '로그인';

  @override
  String get auth_signUp => '회원가입';

  @override
  String get auth_noAccount => '계정이 없으신가요? ';

  @override
  String get auth_haveAccount => '이미 계정이 있으신가요? ';

  @override
  String get auth_continueButton => '계속';

  @override
  String get auth_forgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get auth_resetPassword => '비밀번호 재설정';

  @override
  String get auth_forgotPasswordSubtitle => '이메일을 입력하시면 재설정 링크를 보내드립니다.';

  @override
  String get auth_sendResetLink => '링크 보내기';

  @override
  String get auth_sending => '전송 중...';

  @override
  String get auth_checkYourEmail => '이메일을 확인하세요';

  @override
  String auth_resetEmailSent(String email) {
    return '$email로 비밀번호 재설정 링크를 보냈습니다. 받은 편지함을 확인하고 링크를 따라 새 비밀번호를 설정하세요.';
  }

  @override
  String get auth_openEmailApp => '이메일 열기';

  @override
  String get auth_resendEmail => '재전송';

  @override
  String get auth_backToLogin => '로그인으로 돌아가기';

  @override
  String get auth_newPassword => '새 비밀번호';

  @override
  String get auth_confirmNewPassword => '새 비밀번호 확인';

  @override
  String get auth_resetPasswordSubtitle => '아래에 새 비밀번호를 입력하세요.';

  @override
  String get auth_resetPasswordButton => '비밀번호 재설정';

  @override
  String get auth_resetting => '재설정 중...';

  @override
  String get auth_resetSuccess => '비밀번호가 성공적으로 재설정되었습니다! 새 비밀번호로 로그인할 수 있습니다.';

  @override
  String get auth_invalidResetLink => '유효하지 않은 링크';

  @override
  String get auth_invalidResetLinkMessage => '이 비밀번호 재설정 링크가 유효하지 않거나 만료되었습니다.';

  @override
  String get auth_requestNewLink => '새 링크 요청';

  @override
  String get home_greetingMorning => '좋은 아침입니다';

  @override
  String get home_greetingAfternoon => '좋은 오후입니다';

  @override
  String get home_greetingEvening => '좋은 저녁입니다';

  @override
  String home_greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get home_subtitle => '오늘 이야기를 나눠 보세요';

  @override
  String get home_switchProject => '프로젝트 전환';

  @override
  String get home_genres => '장르';

  @override
  String get home_loadingProjects => '프로젝트 로딩 중...';

  @override
  String get home_loadingGenres => '장르 로딩 중...';

  @override
  String get home_noGenres => '아직 사용 가능한 장르가 없습니다';

  @override
  String get home_noProjectTitle => '시작하려면 프로젝트를 선택하세요';

  @override
  String get home_browseProjects => '프로젝트 둘러보기';

  @override
  String get stats_recordings => '녹음';

  @override
  String get stats_recorded => '녹음됨';

  @override
  String get stats_members => '구성원';

  @override
  String get project_switchTitle => '프로젝트 전환';

  @override
  String get project_projects => '프로젝트';

  @override
  String get project_subtitle => '컬렉션 관리';

  @override
  String get project_noProjectsTitle => '프로젝트가 아직 없습니다';

  @override
  String get project_noProjectsSubtitle => '구전 이야기 수집을 시작하려면 첫 번째 프로젝트를 만드세요.';

  @override
  String get project_newProject => '새 프로젝트';

  @override
  String get project_projectName => '프로젝트 이름';

  @override
  String get project_projectNameHint => '예: 코스라에 성경 번역';

  @override
  String get project_projectNameRequired => '프로젝트 이름은 필수입니다';

  @override
  String get project_description => '설명';

  @override
  String get project_descriptionHint => '선택 사항';

  @override
  String get project_language => '언어';

  @override
  String get project_selectLanguage => '언어 선택';

  @override
  String get project_pleaseSelectLanguage => '언어를 선택해 주세요';

  @override
  String get project_createProject => '프로젝트 만들기';

  @override
  String get project_selectLanguageTitle => '언어 선택';

  @override
  String get project_addLanguageTitle => '언어 추가';

  @override
  String get project_addLanguageSubtitle => '찾는 언어가 없나요? 여기에서 추가하세요.';

  @override
  String get project_languageName => '언어 이름';

  @override
  String get project_languageNameHint => '예: 코스라에어';

  @override
  String get project_languageNameRequired => '이름은 필수입니다';

  @override
  String get project_languageCode => '언어 코드';

  @override
  String get project_languageCodeHint => '예: kos (ISO 639-3)';

  @override
  String get project_languageCodeRequired => '코드는 필수입니다';

  @override
  String get project_languageCodeTooLong => '코드는 1~3자여야 합니다';

  @override
  String get project_addLanguage => '언어 추가';

  @override
  String get project_noLanguagesFound => '언어를 찾을 수 없습니다';

  @override
  String get project_addNewLanguage => '새 언어 추가';

  @override
  String project_addAsNewLanguage(String query) {
    return '\"$query\"을(를) 새 언어로 추가';
  }

  @override
  String get project_searchLanguages => '언어 검색...';

  @override
  String get project_backToList => '목록으로 돌아가기';

  @override
  String get projectSettings_title => '프로젝트 설정';

  @override
  String get projectSettings_details => '세부 정보';

  @override
  String get projectSettings_saving => '저장 중...';

  @override
  String get projectSettings_saveChanges => '변경 사항 저장';

  @override
  String get projectSettings_updated => '프로젝트가 업데이트되었습니다';

  @override
  String get projectSettings_noPermission => '이 프로젝트를 업데이트할 권한이 없습니다';

  @override
  String get projectSettings_team => '팀';

  @override
  String get projectSettings_removeMember => '구성원 제거';

  @override
  String projectSettings_removeMemberConfirm(String name) {
    return '이 프로젝트에서 $name을(를) 제거하시겠습니까?';
  }

  @override
  String get projectSettings_memberRemoved => '구성원이 제거되었습니다';

  @override
  String get projectSettings_memberRemoveFailed => '구성원 제거에 실패했습니다';

  @override
  String get projectSettings_inviteSent => '초대가 전송되었습니다';

  @override
  String get projectSettings_noMembers => '아직 구성원이 없습니다';

  @override
  String get recording_selectGenre => '장르 선택';

  @override
  String get recording_selectGenreSubtitle => '이야기의 장르를 선택하세요';

  @override
  String get recording_selectSubcategory => '하위 분류 선택';

  @override
  String get recording_selectSubcategorySubtitle => '하위 분류를 선택하세요';

  @override
  String get recording_selectRegister => '언어 사용역 선택';

  @override
  String get recording_selectRegisterSubtitle => '언어 사용역을 선택하세요';

  @override
  String get recording_recordingStep => '녹음';

  @override
  String get recording_recordingStepSubtitle => '이야기를 녹음하세요';

  @override
  String get recording_reviewStep => '녹음 검토';

  @override
  String get recording_reviewStepSubtitle => '듣고 저장하세요';

  @override
  String get recording_genreNotFound => '장르를 찾을 수 없습니다';

  @override
  String get recording_noGenres => '사용 가능한 장르가 없습니다';

  @override
  String get recording_noSubcategories => '사용 가능한 하위 분류가 없습니다';

  @override
  String get recording_registerDescription =>
      '이 녹음의 어조와 격식 수준을 가장 잘 나타내는 언어 사용역을 선택하세요.';

  @override
  String get recording_titleHint => '제목 추가 (선택 사항)';

  @override
  String get recording_descriptionHint => '짧은 설명 추가 (선택 사항)';

  @override
  String get recording_descriptionEmpty => '설명 추가';

  @override
  String get recording_saveRecording => '녹음 저장';

  @override
  String get recording_recordAgain => '다시 녹음';

  @override
  String get recording_discard => '삭제';

  @override
  String get recording_discardTitle => '녹음을 삭제하시겠습니까?';

  @override
  String get recording_discardMessage => '이 녹음은 영구적으로 삭제됩니다.';

  @override
  String get recording_saved => '녹음이 저장되었습니다';

  @override
  String get recording_notFound => '녹음을 찾을 수 없습니다';

  @override
  String get recording_unknownGenre => '알 수 없는 장르';

  @override
  String get recording_splitRecording => '녹음 편집';

  @override
  String get recording_moveCategory => '분류 이동';

  @override
  String get recording_downloadAudio => '오디오 다운로드';

  @override
  String get recording_downloadAudioMessage =>
      '오디오 파일이 이 기기에 저장되어 있지 않습니다. 자르기 위해 다운로드하시겠습니까?';

  @override
  String recording_downloadFailed(String error) {
    return '다운로드 실패: $error';
  }

  @override
  String get recording_audioNotAvailable => '오디오 파일을 사용할 수 없습니다';

  @override
  String get recording_deleteTitle => '녹음 삭제';

  @override
  String get recording_deleteMessage =>
      '이 녹음은 기기에서 영구적으로 삭제됩니다. 업로드된 경우 서버에서도 제거됩니다. 이 작업은 취소할 수 없습니다.';

  @override
  String get recording_deleteNoPermission => '이 녹음을 삭제할 권한이 없습니다';

  @override
  String get recording_deleteFailed => '녹음 삭제에 실패했습니다';

  @override
  String get recording_deleteFailedLocal => '서버에서 삭제하지 못했습니다. 로컬에서 제거합니다.';

  @override
  String get recording_cleaningStatusFailed => '서버에서 클리닝 상태를 업데이트하지 못했습니다';

  @override
  String get recording_updateNoPermission => '이 녹음을 업데이트할 권한이 없습니다';

  @override
  String get recording_moveNoPermission => '이 녹음을 이동할 권한이 없습니다';

  @override
  String get recording_movedSuccess => '녹음이 성공적으로 이동되었습니다';

  @override
  String get recording_updateFailed => '서버에서 업데이트하지 못했습니다';

  @override
  String get recordings_title => '녹음 목록';

  @override
  String get recordings_subtitle => '수집한 이야기들';

  @override
  String get recordings_importAudio => '오디오 파일 가져오기';

  @override
  String get recordings_selectProject => '프로젝트 선택';

  @override
  String get recordings_selectProjectSubtitle => '녹음을 보려면 프로젝트를 선택하세요';

  @override
  String get recordings_noRecordings => '녹음이 아직 없습니다';

  @override
  String get recordings_noRecordingsSubtitle =>
      '마이크를 탭하여 첫 번째 이야기를 녹음하거나 오디오 파일을 가져오세요.';

  @override
  String recordings_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '녹음 $count개',
      one: '녹음 1개',
    );
    return '$_temp0';
  }

  @override
  String get recording_statusUploaded => '업로드됨';

  @override
  String get recording_statusUploading => '업로드 중';

  @override
  String get recording_statusFailed => '실패';

  @override
  String get recording_statusLocal => '로컬';

  @override
  String get recordings_clearStale => '실패 항목 삭제';

  @override
  String get recordings_clearStaleMessage =>
      '서버에서 업로드 실패 또는 멈춘 상태의 모든 녹음을 영구적으로 삭제합니다. 이 작업은 취소할 수 없습니다.';

  @override
  String recordings_clearedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '녹음 $count개 삭제됨',
      one: '녹음 1개 삭제됨',
      zero: '오래된 녹음이 없습니다',
    );
    return '$_temp0';
  }

  @override
  String get recordings_clearFailed => '녹음 삭제에 실패했습니다';

  @override
  String get trim_title => '녹음 편집';

  @override
  String get trim_notFound => '녹음을 찾을 수 없습니다';

  @override
  String get trim_audioUrlNotAvailable => '이 녹음의 오디오 URL을 사용할 수 없습니다.';

  @override
  String get trim_localNotAvailable => '로컬 오디오 파일을 사용할 수 없습니다. 먼저 녹음을 다운로드하세요.';

  @override
  String get trim_atLeastOneSegment => '최소 한 개의 세그먼트를 유지해야 합니다';

  @override
  String get trim_segments => '세그먼트';

  @override
  String get trim_restoreAll => '모두 복원';

  @override
  String get trim_instructions => '위의 파형을 탭하여 분할 지점을\n설정하고 이 녹음을 나누세요';

  @override
  String get trim_splitting => '분할 중...';

  @override
  String trim_saveSegments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '세그먼트 $count개 저장',
      one: '세그먼트 1개 저장',
    );
    return '$_temp0';
  }

  @override
  String get trim_addSplitsFirst => '먼저 분할 지점을 추가하세요';

  @override
  String trim_savedSegments(int kept, int removed) {
    return '세그먼트 $kept개 저장, $removed개 제거';
  }

  @override
  String trim_splitInto(int count) {
    return '$count개 녹음으로 분할';
  }

  @override
  String get trim_saveConfirmTitle => '변경 사항을 저장하시겠습니까?';

  @override
  String trim_saveConfirmBody(int count) {
    return '원본 녹음을 $count개의 세그먼트로 대체합니다. 이 작업은 취소할 수 없습니다.';
  }

  @override
  String get trim_inheritLabel => '상속';

  @override
  String get trim_applyToAll => '모두에 적용';

  @override
  String get trim_copyFromPrevious => '이전에서 복사';

  @override
  String get trim_classifySegment => '세그먼트 분류';

  @override
  String get trim_volume => '볼륨';

  @override
  String get trim_peakClip => '클리핑';

  @override
  String get trim_boostOnSave => '저장 시 부스트 적용';

  @override
  String get import_title => '오디오 가져오기';

  @override
  String get import_selectGenre => '장르 선택';

  @override
  String get import_selectSubcategory => '하위 분류 선택';

  @override
  String get import_selectRegister => '사용역 선택';

  @override
  String get import_confirmImport => '가져오기 확인';

  @override
  String get import_analyzing => '오디오 파일 분석 중...';

  @override
  String get import_selectFile => '가져올 오디오 파일을 선택하세요';

  @override
  String get import_chooseFile => '파일 선택';

  @override
  String get import_accessFailed => '선택한 파일에 접근할 수 없습니다';

  @override
  String import_pickError(String error) {
    return '파일 선택 오류: $error';
  }

  @override
  String import_saveError(String error) {
    return '파일 저장 오류: $error';
  }

  @override
  String get import_unknownFile => '알 수 없는 파일';

  @override
  String get import_importAndSave => '가져오기 및 저장';

  @override
  String get import_setForAll => '모든 파일에 설정';

  @override
  String get import_applyToAll => '모두에 적용';

  @override
  String get import_fieldRequired => '필수';

  @override
  String import_validationBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 파일에 필수 항목이 누락됨',
      one: '1개 파일에 필수 항목이 누락됨',
    );
    return '$_temp0';
  }

  @override
  String get import_remove => '파일 제거';

  @override
  String import_supportedFormats(String formats) {
    return '지원되는 형식: $formats. 지원되지 않거나 읽을 수 없는 파일은 건너뜁니다.';
  }

  @override
  String import_rejectedFiles(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '지원되지 않거나 읽을 수 없는 파일 $count개 건너뜀: $names',
      one: '지원되지 않거나 읽을 수 없는 파일 1개 건너뜀: $names',
    );
    return '$_temp0';
  }

  @override
  String import_countFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 파일',
      one: '1개 파일',
    );
    return '$_temp0';
  }

  @override
  String import_importNFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 파일',
      one: '1개 파일',
    );
    return '$_temp0 가져오기';
  }

  @override
  String get import_emptyFile => '빈 파일';

  @override
  String get import_compressWav => 'WAV을 M4A로 압축';

  @override
  String get import_compressWavHint => '~10x 작음, ML 파이프라인에 품질 손실 없음';

  @override
  String get moveCategory_title => '분류 이동';

  @override
  String get moveCategory_genre => '장르';

  @override
  String get moveCategory_subcategory => '하위 분류';

  @override
  String get moveCategory_selectSubcategory => '하위 분류 선택';

  @override
  String get cleaning_needsCleaning => '클리닝 필요';

  @override
  String get cleaning_cleaning => '클리닝 중...';

  @override
  String get cleaning_cleaned => '클리닝 완료';

  @override
  String get cleaning_cleanFailed => '클리닝 실패';

  @override
  String get sync_uploading => '업로드 중...';

  @override
  String sync_pending(int count) {
    return '$count개 대기 중';
  }

  @override
  String get profile_photoUpdated => '프로필 사진이 업데이트되었습니다';

  @override
  String profile_photoFailed(String error) {
    return '사진 업데이트 실패: $error';
  }

  @override
  String get profile_editName => '표시 이름 편집';

  @override
  String get profile_nameHint => '이름';

  @override
  String get profile_nameUpdated => '이름이 업데이트되었습니다';

  @override
  String get profile_syncStorage => '동기화 및 저장소';

  @override
  String get profile_about => '정보';

  @override
  String get profile_appVersion => '앱 버전';

  @override
  String get profile_byShema => 'Oral Collector by Shema';

  @override
  String get profile_administration => '관리';

  @override
  String get profile_adminDashboard => '관리자 대시보드';

  @override
  String get profile_adminSubtitle => '시스템 통계, 프로젝트 및 장르 관리';

  @override
  String get profile_account => '계정';

  @override
  String get profile_logOut => '로그아웃';

  @override
  String get profile_deleteAccount => '계정 삭제';

  @override
  String get profile_deleteAccountConfirm => '삭제 확인';

  @override
  String get profile_deleteAccountWarning =>
      '이 작업은 영구적이며 취소할 수 없습니다. 계정은 삭제되지만 업로드된 녹음은 언어 프로젝트를 위해 보존됩니다.';

  @override
  String get profile_typeDelete => '계정 삭제를 확인하려면 DELETE를 입력하세요:';

  @override
  String get profile_clearCacheTitle => '로컬 캐시를 삭제하시겠습니까?';

  @override
  String get profile_clearCacheMessage =>
      '로컬에 저장된 모든 녹음이 삭제됩니다. 서버에 업로드된 녹음에는 영향이 없습니다.';

  @override
  String get profile_cacheCleared => '로컬 캐시가 삭제되었습니다';

  @override
  String profile_joinedSuccess(String name) {
    return '\"$name\"에 성공적으로 참여했습니다';
  }

  @override
  String get profile_inviteDeclined => '초대가 거절되었습니다';

  @override
  String get profile_language => '언어';

  @override
  String get profile_online => '온라인';

  @override
  String get profile_offline => '오프라인';

  @override
  String profile_lastSync(String time) {
    return '마지막 동기화: $time';
  }

  @override
  String get profile_neverSynced => '동기화한 적 없음';

  @override
  String profile_pendingCount(int count) {
    return '$count개 대기 중';
  }

  @override
  String profile_syncingProgress(int percent) {
    return '동기화 중... $percent%';
  }

  @override
  String get profile_syncNow => '지금 동기화';

  @override
  String get profile_wifiOnly => 'Wi-Fi에서만 업로드';

  @override
  String get profile_wifiOnlySubtitle => '모바일 데이터를 통한 업로드 방지';

  @override
  String get profile_autoRemove => '업로드 후 자동 삭제';

  @override
  String get profile_autoRemoveSubtitle => '업로드 성공 후 로컬 파일 삭제';

  @override
  String get profile_clearCache => '로컬 캐시 삭제';

  @override
  String get profile_clearCacheSubtitle => '로컬에 저장된 모든 녹음 삭제';

  @override
  String get profile_invitations => '초대';

  @override
  String get profile_refreshInvitations => '초대 새로고침';

  @override
  String get profile_noInvitations => '대기 중인 초대가 없습니다';

  @override
  String get profile_roleManager => '역할: 관리자';

  @override
  String get profile_roleMember => '역할: 구성원';

  @override
  String get profile_decline => '거절';

  @override
  String get profile_accept => '수락';

  @override
  String get profile_storage => '저장소';

  @override
  String get profile_status => '상태';

  @override
  String get profile_pendingLabel => '대기 중';

  @override
  String get admin_title => '관리자 대시보드';

  @override
  String get admin_overview => '개요';

  @override
  String get admin_projects => '프로젝트';

  @override
  String get admin_genres => '장르';

  @override
  String get admin_cleaning => '클리닝';

  @override
  String get admin_accessRequired => '관리자 권한이 필요합니다';

  @override
  String get admin_totalProjects => '총 프로젝트';

  @override
  String get admin_languages => '언어';

  @override
  String get admin_recordings => '녹음';

  @override
  String get admin_totalHours => '총 시간';

  @override
  String get admin_activeUsers => '활성 사용자';

  @override
  String get admin_projectName => '이름';

  @override
  String get admin_projectLanguage => '언어';

  @override
  String get admin_projectMembers => '구성원';

  @override
  String get admin_projectRecordings => '녹음';

  @override
  String get admin_projectDuration => '기간';

  @override
  String get admin_projectCreated => '생성일';

  @override
  String get admin_noProjects => '프로젝트를 찾을 수 없습니다';

  @override
  String get admin_unknownLanguage => '알 수 없는 언어';

  @override
  String get admin_genresAndSubcategories => '장르 및 하위 분류';

  @override
  String get admin_addGenre => '장르 추가';

  @override
  String get admin_noGenres => '장르를 찾을 수 없습니다';

  @override
  String get admin_genreName => '장르 이름';

  @override
  String get admin_required => '필수';

  @override
  String get admin_descriptionOptional => '설명 (선택 사항)';

  @override
  String get admin_genreCreated => '장르가 생성되었습니다';

  @override
  String get admin_editGenre => '장르 편집';

  @override
  String get admin_deleteGenre => '장르 삭제';

  @override
  String get admin_addSubcategory => '하위 분류 추가';

  @override
  String get admin_editGenreTitle => '장르 편집';

  @override
  String get admin_genreUpdated => '장르가 업데이트되었습니다';

  @override
  String get admin_deleteGenreTitle => '장르 삭제';

  @override
  String admin_deleteGenreConfirm(String name) {
    return '\"$name\" 및 모든 하위 분류를 삭제하시겠습니까?';
  }

  @override
  String get admin_genreDeleted => '장르가 삭제되었습니다';

  @override
  String admin_addSubcategoryTo(String name) {
    return '$name에 하위 분류 추가';
  }

  @override
  String get admin_subcategoryName => '하위 분류 이름';

  @override
  String get admin_subcategoryCreated => '하위 분류가 생성되었습니다';

  @override
  String get admin_deleteSubcategory => '하위 분류 삭제';

  @override
  String admin_deleteSubcategoryConfirm(String name) {
    return '\"$name\"을(를) 삭제하시겠습니까?';
  }

  @override
  String get admin_subcategoryDeleted => '하위 분류가 삭제되었습니다';

  @override
  String get admin_cleaningQueue => '오디오 클리닝 대기열';

  @override
  String admin_cleanSelected(int count) {
    return '선택 항목 클리닝 ($count)';
  }

  @override
  String get admin_refreshCleaning => '클리닝 대기열 새로고침';

  @override
  String get admin_cleaningWebOnly =>
      '오디오 클리닝은 웹 전용 기능입니다. 클리닝 작업은 서버에서 실행됩니다.';

  @override
  String get admin_noCleaningRecordings => '클리닝이 필요한 녹음이 없습니다';

  @override
  String get admin_cleaningTitle => '제목';

  @override
  String get admin_cleaningDuration => '길이';

  @override
  String get admin_cleaningSize => '크기';

  @override
  String get admin_cleaningFormat => '형식';

  @override
  String get admin_cleaningRecorded => '녹음일';

  @override
  String get admin_cleaningActions => '작업';

  @override
  String get admin_clean => '클리닝';

  @override
  String get admin_deselectAll => '전체 선택 해제';

  @override
  String get admin_selectAll => '전체 선택';

  @override
  String get admin_cleaningTriggered => '클리닝이 시작되었습니다';

  @override
  String get admin_cleaningFailed => '클리닝 시작에 실패했습니다';

  @override
  String admin_cleaningPartial(int success, int total) {
    return '$total개 녹음 중 $success개 클리닝이 시작되었습니다';
  }

  @override
  String get genre_title => '장르';

  @override
  String get genre_notFound => '장르를 찾을 수 없습니다';

  @override
  String genre_recordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '녹음 $count개',
      one: '녹음 1개',
    );
    return '$_temp0';
  }

  @override
  String get format_justNow => '방금 전';

  @override
  String format_minutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String format_hoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String format_daysAgo(int count) {
    return '$count일 전';
  }

  @override
  String format_weeksAgo(int count) {
    return '$count주 전';
  }

  @override
  String format_monthsAgo(int count) {
    return '$count개월 전';
  }

  @override
  String format_memberSince(String date) {
    return '$date부터 구성원';
  }

  @override
  String get format_member => '구성원';

  @override
  String format_dateAt(String date, String time) {
    return '$date $time';
  }

  @override
  String get genre_narrative => '서사';

  @override
  String get genre_narrativeDesc => '구전 전통의 이야기, 기록 및 서사적 형태';

  @override
  String get genre_poeticSong => '시 / 노래';

  @override
  String get genre_poeticSongDesc => '찬송, 애가, 지혜 시를 포함한 음악적, 시적 구전 전통';

  @override
  String get genre_instructional => '교훈적 / 규범적';

  @override
  String get genre_instructionalDesc => '법률, 의식, 절차 및 교훈적 형태';

  @override
  String get genre_oralDiscourse => '구술 담화';

  @override
  String get genre_oralDiscourseDesc => '연설, 가르침, 기도 및 담론적 구술 형태';

  @override
  String get sub_historicalNarrative => '역사 서사';

  @override
  String get sub_personalAccount => '개인 기록 / 간증';

  @override
  String get sub_parable => '비유 / 교훈적 이야기';

  @override
  String get sub_originStory => '기원 / 창조 이야기';

  @override
  String get sub_legend => '전설 / 영웅 이야기';

  @override
  String get sub_visionNarrative => '환상 또는 꿈 서사';

  @override
  String get sub_genealogy => '족보';

  @override
  String get sub_eventReport => '최근 사건 보고';

  @override
  String get sub_hymn => '찬송 / 예배 노래';

  @override
  String get sub_lament => '애가';

  @override
  String get sub_funeralDirge => '장례 만가';

  @override
  String get sub_victorySong => '승리 / 축하 노래';

  @override
  String get sub_loveSong => '사랑 노래';

  @override
  String get sub_tauntSong => '조롱 / 풍자 노래';

  @override
  String get sub_blessing => '축복';

  @override
  String get sub_curse => '저주';

  @override
  String get sub_wisdomPoem => '지혜 시 / 잠언';

  @override
  String get sub_didacticPoetry => '교훈시';

  @override
  String get sub_legalCode => '법률 / 법전';

  @override
  String get sub_ritual => '의식 / 전례';

  @override
  String get sub_procedure => '절차 / 지침';

  @override
  String get sub_listInventory => '목록 / 명부';

  @override
  String get sub_propheticOracle => '예언적 신탁 / 연설';

  @override
  String get sub_exhortation => '권면 / 설교';

  @override
  String get sub_wisdomTeaching => '지혜 가르침';

  @override
  String get sub_prayer => '기도';

  @override
  String get sub_dialogue => '대화';

  @override
  String get sub_epistle => '서신 / 편지';

  @override
  String get sub_apocalypticDiscourse => '묵시적 담화';

  @override
  String get sub_ceremonialSpeech => '의식 연설';

  @override
  String get sub_communityMemory => '공동체 기억';

  @override
  String get sub_historicalNarrativeDesc => '역사 속 사건, 전쟁, 주요 순간에 대한 기록';

  @override
  String get sub_personalAccountDesc => '개인적 경험과 신앙에 대한 1인칭 이야기';

  @override
  String get sub_parableDesc => '도덕적 또는 영적 교훈을 가르치는 상징적 이야기';

  @override
  String get sub_originStoryDesc => '사물의 기원에 대한 이야기';

  @override
  String get sub_legendDesc => '뛰어난 인물과 그들의 위대한 업적에 대한 이야기';

  @override
  String get sub_visionNarrativeDesc => '신성한 환상과 예언적 꿈에 대한 기록';

  @override
  String get sub_genealogyDesc => '가계와 조상의 혈통 기록';

  @override
  String get sub_eventReportDesc => '공동체의 최근 사건에 대한 보고';

  @override
  String get sub_hymnDesc => '하나님께 드리는 찬양과 예배의 노래';

  @override
  String get sub_lamentDesc => '슬픔, 비탄, 애도의 표현';

  @override
  String get sub_funeralDirgeDesc => '애도와 장례 의식에서 부르는 노래';

  @override
  String get sub_victorySongDesc => '승리와 기쁜 사건을 축하하는 노래';

  @override
  String get sub_loveSongDesc => '사랑과 헌신을 표현하는 노래';

  @override
  String get sub_tauntSongDesc => '적이나 불신자를 겨냥한 조롱의 노래';

  @override
  String get sub_blessingDesc => '신의 은총과 보호를 구하는 말씀';

  @override
  String get sub_curseDesc => '심판이나 신적 결과의 선언';

  @override
  String get sub_wisdomPoemDesc => '실용적 지혜를 전하는 격언과 시';

  @override
  String get sub_didacticPoetryDesc => '가르침과 교훈을 위해 지어진 시적 작품';

  @override
  String get sub_legalCodeDesc => '규칙, 법령, 언약 규정';

  @override
  String get sub_ritualDesc => '예배와 신성한 의식의 규정된 형식';

  @override
  String get sub_procedureDesc => '단계별 지시와 실용적 지침';

  @override
  String get sub_listInventoryDesc => '목록, 인구조사, 정리된 기록';

  @override
  String get sub_propheticOracleDesc => '하나님을 대신하여 전하는 메시지';

  @override
  String get sub_exhortationDesc => '도덕적·영적 행동을 촉구하는 연설';

  @override
  String get sub_wisdomTeachingDesc => '지혜롭고 의롭게 사는 법에 대한 가르침';

  @override
  String get sub_prayerDesc => '예배나 간구로 하나님께 드리는 말씀';

  @override
  String get sub_dialogueDesc => '사람들 간의 대화와 소통';

  @override
  String get sub_epistleDesc => '공동체나 개인에게 보낸 서면 메시지';

  @override
  String get sub_apocalypticDiscourseDesc => '종말과 하나님의 계획에 대한 계시';

  @override
  String get sub_ceremonialSpeechDesc => '공식적이거나 신성한 행사를 위한 격식 연설';

  @override
  String get sub_communityMemoryDesc => '집단 정체성을 보존하는 공유된 기억';

  @override
  String get register_intimate => '친밀한';

  @override
  String get register_casual => '비격식적 / 일상적';

  @override
  String get register_consultative => '상담적';

  @override
  String get register_formal => '격식적 / 공식적';

  @override
  String get register_ceremonial => '의례적';

  @override
  String get register_elderAuthority => '어른 / 권위적';

  @override
  String get register_religiousWorship => '종교적 / 예배';

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
  String get locale_englishSub => '영어';

  @override
  String get locale_portugueseSub => '포르투갈어';

  @override
  String get locale_hindiSub => '힌디어';

  @override
  String get locale_koreanSub => '한국어';

  @override
  String get locale_spanishSub => '스페인어';

  @override
  String get locale_bahasaSub => '인도네시아어';

  @override
  String get locale_frenchSub => '프랑스어';

  @override
  String get locale_tokPisinSub => '톡 피신';

  @override
  String get locale_swahiliSub => '스와힐리어';

  @override
  String get locale_arabicSub => '아랍어';

  @override
  String get locale_chinese => '中文';

  @override
  String get locale_chineseSub => '중국어';

  @override
  String get locale_selectLanguage => '언어를 선택하세요';

  @override
  String get locale_selectLanguageSubtitle => '프로필 설정에서 나중에 변경할 수 있습니다.';

  @override
  String get filter_all => '전체';

  @override
  String get filter_pending => '대기 중';

  @override
  String get filter_uploaded => '업로드됨';

  @override
  String get filter_needsCleaning => '클리닝 필요';

  @override
  String get filter_unclassified => '미분류';

  @override
  String get filter_allGenres => '모든 장르';

  @override
  String get detail_duration => '길이';

  @override
  String get detail_size => '크기';

  @override
  String get detail_format => '형식';

  @override
  String get detail_status => '상태';

  @override
  String get detail_upload => '업로드';

  @override
  String get detail_uploaded => '업로드됨';

  @override
  String get detail_cleaning => '클리닝';

  @override
  String get detail_recorded => '녹음일';

  @override
  String get detail_retry => '재시도';

  @override
  String get detail_notFlagged => '미표시';

  @override
  String get detail_uploadStuck => '멈춤 — 재시도를 탭하세요';

  @override
  String get detail_uploading => '업로드 중...';

  @override
  String get detail_maxRetries => '최대 재시도 — 재시도를 탭하세요';

  @override
  String get detail_uploadFailed => '업로드 실패';

  @override
  String get detail_pendingRetried => '대기 중 (재시도됨)';

  @override
  String get detail_notSynced => '동기화되지 않음';

  @override
  String get action_actions => '작업';

  @override
  String get action_split => '편집';

  @override
  String get action_flagClean => '클리닝 표시';

  @override
  String get action_clearFlag => '표시 해제';

  @override
  String get action_move => '이동';

  @override
  String get action_delete => '삭제';

  @override
  String get projectStats_recordings => '녹음';

  @override
  String get projectStats_duration => '길이';

  @override
  String get projectStats_members => '구성원';

  @override
  String get project_active => '활성';

  @override
  String get recording_paused => '일시정지됨';

  @override
  String get recording_recording => '녹음 중';

  @override
  String get recording_tapToRecord => '탭하여 녹음';

  @override
  String get recording_sensitivity => '감도';

  @override
  String get recording_sensitivityLow => '낮음';

  @override
  String get recording_sensitivityMed => '중간';

  @override
  String get recording_sensitivityHigh => '높음';

  @override
  String get recording_stopRecording => '녹음 중지';

  @override
  String get recording_stop => '중지';

  @override
  String get recording_resume => '재개';

  @override
  String get recording_pause => '일시정지';

  @override
  String get quickRecord_title => '빠른 녹음';

  @override
  String get quickRecord_subtitle => '나중에 분류';

  @override
  String get quickRecord_classifyLater => '나중에 분류';

  @override
  String get classify_title => '녹음 분류';

  @override
  String get classify_action => '분류';

  @override
  String get classify_banner => '이 녹음은 업로드하기 전에 분류해야 합니다.';

  @override
  String get classify_success => '녹음이 분류되었습니다';

  @override
  String get classify_register => '사용역';

  @override
  String get classify_selectRegister => '사용역 선택';

  @override
  String get recording_unclassified => '미분류';

  @override
  String get recording_inputSource => '입력';

  @override
  String get recording_selectMicrophone => '마이크 선택';

  @override
  String get recording_builtInMicrophone => '시스템 기본값';

  @override
  String get recording_micPermissionNeeded => '장치 이름을 보려면 마이크 액세스를 허용하세요';

  @override
  String get recording_micPermissionButton => '권한 부여';

  @override
  String get recording_micPermissionDenied =>
      '마이크 권한이 거부되었습니다. 브라우저 또는 시스템 설정에서 활성화하세요.';

  @override
  String get recording_micPermissionTitle => 'Microphone access needed';

  @override
  String get recording_noDevicesFound => '마이크를 찾을 수 없습니다';

  @override
  String get recording_storageLowWarnTitle => '저장 공간 부족';

  @override
  String recording_storageLowWarnBody(int minutes) {
    return '약 $minutes분의 녹음이 가능합니다. 계속하시겠습니까?';
  }

  @override
  String get recording_storageRefuseTitle => '저장 공간이 충분하지 않습니다';

  @override
  String get recording_storageRefuseBody => '녹음 전에 이 기기의 공간을 확보하세요.';

  @override
  String recording_storageCriticalBanner(int minutes) {
    return '저장 공간이 위험합니다 — 약 $minutes분 남았습니다. 곧 중지하세요.';
  }

  @override
  String get recording_storageForceStopped =>
      '저장 공간이 부족하여 녹음이 중지되었습니다. 진행 상황이 저장되었습니다.';

  @override
  String recording_savedAt(String time) {
    return '$time에 저장됨';
  }

  @override
  String get recording_continuedInBackground => '녹음이 백그라운드에서 계속되었습니다';

  @override
  String get recording_continue => '계속';

  @override
  String get recording_cancel => '취소';

  @override
  String get recording_recoverTitle => '중단된 녹음을 복구하시겠습니까?';

  @override
  String recording_recoverBody(int minutes) {
    return '이전 세션에서 약 $minutes분의 오디오를 발견했습니다.';
  }

  @override
  String get recording_recoverButton => '복구';

  @override
  String get recording_recoverDiscard => '버리기';

  @override
  String get recording_recoverFailedLastSegment =>
      '끝부분의 일부 오디오를 읽을 수 없어 건너뛰었습니다.';

  @override
  String get recording_inProgressNotificationTitle => '녹음 중';

  @override
  String get recording_inProgressNotificationBody => '탭하여 앱으로 돌아가기';

  @override
  String get profile_defaultMicrophone => '기본 마이크';

  @override
  String get profile_systemDefault => '시스템 기본값';

  @override
  String get settings_deviceStorageTitle => '기기 저장 공간';

  @override
  String settings_deviceStorageSubtitle(String used, String free) {
    return '사용 $used · 여유 $free';
  }

  @override
  String get fab_quickRecord => '빠른';

  @override
  String get fab_normalRecord => '녹음';

  @override
  String get error_network => '서버에 연결할 수 없습니다. 인터넷 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get error_secureConnection => '보안 연결을 설정할 수 없습니다. 나중에 다시 시도해 주세요.';

  @override
  String get error_timeout => '요청 시간이 초과되었습니다. 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get error_invalidCredentials => '이메일 또는 비밀번호가 올바르지 않습니다. 다시 시도해 주세요.';

  @override
  String get error_userNotFound => '해당 이메일 주소로 등록된 계정이 없습니다.';

  @override
  String get error_accountExists => '이 이메일로 등록된 계정이 이미 존재합니다.';

  @override
  String get error_emailRequired => '이메일 주소를 입력해 주세요.';

  @override
  String get error_passwordRequired => '비밀번호를 입력해 주세요.';

  @override
  String get error_signupFailed => '계정을 만들 수 없습니다. 정보를 확인하고 다시 시도해 주세요.';

  @override
  String get error_sessionExpired => '세션이 만료되었습니다. 다시 로그인해 주세요.';

  @override
  String get error_profileLoadFailed => '프로필을 불러올 수 없습니다. 다시 시도해 주세요.';

  @override
  String get error_profileUpdateFailed => '프로필을 업데이트할 수 없습니다. 다시 시도해 주세요.';

  @override
  String get error_imageUploadFailed => '이미지를 업로드할 수 없습니다. 다시 시도해 주세요.';

  @override
  String get error_notAuthenticated => '로그인되지 않았습니다. 로그인 후 다시 시도해 주세요.';

  @override
  String get error_noPermission => '이 작업을 수행할 권한이 없습니다.';

  @override
  String get error_generic => '문제가 발생했습니다. 나중에 다시 시도해 주세요.';

  @override
  String get common_close => 'Close';

  @override
  String get storyteller_title => 'Storytellers';

  @override
  String get storyteller_singular => 'Storyteller';

  @override
  String get storyteller_manageAction => 'Manage storytellers';

  @override
  String get storyteller_addNew => 'Add storyteller';

  @override
  String get storyteller_createTitle => 'New storyteller';

  @override
  String get storyteller_editTitle => 'Edit storyteller';

  @override
  String get storyteller_speakerName => 'Speaker name';

  @override
  String get storyteller_sex => 'Sex';

  @override
  String get storyteller_sexMale => 'Male';

  @override
  String get storyteller_sexFemale => 'Female';

  @override
  String get storyteller_age => 'Age';

  @override
  String get storyteller_location => 'Location';

  @override
  String get storyteller_dialect => 'Dialect';

  @override
  String get storyteller_externalAcceptanceTitle =>
      'External acceptance validation';

  @override
  String get storyteller_externalAcceptanceDescription =>
      'I confirm that external acceptance validation has been performed for this speaker.';

  @override
  String get storyteller_externalAcceptanceInfo =>
      'Before registering a storyteller, the project manager must obtain the speaker\'s consent outside the app (for example, through a signed release form or recorded verbal agreement). This checkbox records that this step was completed.';

  @override
  String get storyteller_createRequiresConnection =>
      'Creating a storyteller requires an internet connection.';

  @override
  String get storyteller_deleteTitle => 'Delete storyteller?';

  @override
  String get storyteller_deleteMessage =>
      'Recordings previously assigned to this storyteller will show as unassigned.';

  @override
  String get storyteller_noneAssigned => 'No storyteller assigned';

  @override
  String get storyteller_unknown => 'Unknown storyteller';

  @override
  String get storyteller_selectHint => 'Pick a storyteller';

  @override
  String get storyteller_required => 'A storyteller is required';

  @override
  String get storyteller_searchPlaceholder => 'Search storytellers';

  @override
  String get storyteller_empty => 'No storytellers yet';

  @override
  String get storyteller_emptyDescription =>
      'Create a storyteller for the project to assign to recordings.';

  @override
  String get storyteller_offlineNoCache =>
      'Storytellers haven\'t been synced yet. Connect to the internet to load them.';

  @override
  String get storyteller_assign => 'Assign';

  @override
  String get storyteller_reassign => 'Reassign';

  @override
  String get storyteller_ageValidator => 'Enter an age between 1 and 120';

  @override
  String storyteller_ageYearsShort(int age) {
    return '${age}y';
  }

  @override
  String get filters_buttonLabel => 'Filters';

  @override
  String get filters_sheetTitle => 'Filter recordings';

  @override
  String get filters_sectionStatus => 'Upload status';

  @override
  String get filters_sectionGenre => 'Genre';

  @override
  String get filters_sectionStoryteller => 'Storyteller';

  @override
  String get filters_sectionUser => 'Recorded by';

  @override
  String get filter_apply => 'Apply';

  @override
  String get filter_reset => 'Reset';

  @override
  String get filter_clearAll => 'Clear all';

  @override
  String filter_countActive(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString filters',
      one: '1 filter',
    );
    return '$_temp0';
  }

  @override
  String get filter_userAll => 'Any user';

  @override
  String get filter_storytellerAll => 'Any storyteller';

  @override
  String get filter_genreAll => 'Any genre';

  @override
  String get detail_recordedBy => 'Recorded by';

  @override
  String get detail_storyteller => 'Storyteller';

  @override
  String get recording_unknownUser => 'Unknown user';
}
