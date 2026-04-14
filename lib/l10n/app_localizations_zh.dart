// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Oral Collector';

  @override
  String get nav_home => '首页';

  @override
  String get nav_record => '录音';

  @override
  String get nav_recordings => '录音列表';

  @override
  String get nav_projects => '项目';

  @override
  String get nav_profile => '个人资料';

  @override
  String get nav_admin => '管理';

  @override
  String get nav_collapse => '折叠';

  @override
  String get common_cancel => '取消';

  @override
  String get common_save => '保存';

  @override
  String get common_delete => '删除';

  @override
  String get common_remove => '移除';

  @override
  String get common_create => '创建';

  @override
  String get common_continue => '继续';

  @override
  String get common_next => '下一步';

  @override
  String get common_retry => '重试';

  @override
  String get common_move => '移动';

  @override
  String get common_invite => '邀请';

  @override
  String get common_download => '下载';

  @override
  String get common_clear => '清除';

  @override
  String get common_untitled => '无标题';

  @override
  String get common_loading => '加载中...';

  @override
  String get auth_oralCollector => 'Oral Collector';

  @override
  String get auth_byShema => '由 Shema 提供';

  @override
  String get auth_heroTagline => '保存声音。\n分享故事。';

  @override
  String get auth_welcomeBack => '欢迎\n回来';

  @override
  String get auth_welcome => '欢迎 ';

  @override
  String get auth_back => '回来';

  @override
  String get auth_createWord => '创建 ';

  @override
  String get auth_createNewline => '创建\n';

  @override
  String get auth_account => '账户';

  @override
  String get auth_signInSubtitle => '登录以继续收集故事。';

  @override
  String get auth_signUpSubtitle => '加入我们的故事收集者社区。';

  @override
  String get auth_backToSignIn => '返回登录';

  @override
  String get auth_emailLabel => '电子邮箱';

  @override
  String get auth_emailHint => 'your@email.com';

  @override
  String get auth_emailRequired => '请输入您的电子邮箱';

  @override
  String get auth_emailInvalid => '请输入有效的电子邮箱';

  @override
  String get auth_passwordLabel => '密码';

  @override
  String get auth_passwordHint => '至少6个字符';

  @override
  String get auth_passwordRequired => '请输入您的密码';

  @override
  String get auth_passwordTooShort => '密码至少需要6个字符';

  @override
  String get auth_confirmPasswordLabel => '确认密码';

  @override
  String get auth_confirmPasswordHint => '重新输入密码';

  @override
  String get auth_confirmPasswordRequired => '请确认您的密码';

  @override
  String get auth_confirmPasswordMismatch => '两次输入的密码不一致';

  @override
  String get auth_nameLabel => '姓名';

  @override
  String get auth_nameHint => '您的全名';

  @override
  String get auth_nameRequired => '请输入您的显示名称';

  @override
  String get auth_signIn => '登录';

  @override
  String get auth_signUp => '注册';

  @override
  String get auth_noAccount => '还没有账户？';

  @override
  String get auth_haveAccount => '已有账户？';

  @override
  String get auth_continueButton => '继续';

  @override
  String get auth_forgotPassword => '忘记密码？';

  @override
  String get auth_resetPassword => '重置密码';

  @override
  String get auth_forgotPasswordSubtitle => '输入您的邮箱，我们将向您发送重置链接。';

  @override
  String get auth_sendResetLink => '发送链接';

  @override
  String get auth_sending => '发送中...';

  @override
  String get auth_checkYourEmail => '请查看您的邮箱';

  @override
  String auth_resetEmailSent(String email) {
    return '我们已向 $email 发送了密码重置链接。请查看您的收件箱并点击链接设置新密码。';
  }

  @override
  String get auth_openEmailApp => '打开邮箱';

  @override
  String get auth_resendEmail => '重新发送';

  @override
  String get auth_backToLogin => '返回登录';

  @override
  String get auth_newPassword => '新密码';

  @override
  String get auth_confirmNewPassword => '确认新密码';

  @override
  String get auth_resetPasswordSubtitle => '请在下方输入您的新密码。';

  @override
  String get auth_resetPasswordButton => '重置密码';

  @override
  String get auth_resetting => '重置中...';

  @override
  String get auth_resetSuccess => '密码重置成功！您现在可以使用新密码登录。';

  @override
  String get auth_invalidResetLink => '无效链接';

  @override
  String get auth_invalidResetLinkMessage => '此密码重置链接无效或已过期。';

  @override
  String get auth_requestNewLink => '请求新链接';

  @override
  String get home_greetingMorning => '早上好';

  @override
  String get home_greetingAfternoon => '下午好';

  @override
  String get home_greetingEvening => '晚上好';

  @override
  String home_greetingWithName(String greeting, String name) {
    return '$greeting，$name';
  }

  @override
  String get home_subtitle => '今天来分享您的故事吧';

  @override
  String get home_switchProject => '切换项目';

  @override
  String get home_genres => '体裁';

  @override
  String get home_loadingProjects => '加载项目中...';

  @override
  String get home_loadingGenres => '加载体裁中...';

  @override
  String get home_noGenres => '暂无可用体裁';

  @override
  String get home_noProjectTitle => '选择一个项目以开始';

  @override
  String get home_browseProjects => '浏览项目';

  @override
  String get stats_recordings => '录音';

  @override
  String get stats_recorded => '已录制';

  @override
  String get stats_members => '成员';

  @override
  String get project_switchTitle => '切换项目';

  @override
  String get project_projects => '项目';

  @override
  String get project_subtitle => '管理您的收藏';

  @override
  String get project_noProjectsTitle => '暂无项目';

  @override
  String get project_noProjectsSubtitle => '创建您的第一个项目，开始收集口述故事。';

  @override
  String get project_newProject => '新建项目';

  @override
  String get project_projectName => '项目名称';

  @override
  String get project_projectNameHint => '例如：科斯雷语圣经翻译';

  @override
  String get project_projectNameRequired => '项目名称为必填项';

  @override
  String get project_description => '描述';

  @override
  String get project_descriptionHint => '选填';

  @override
  String get project_language => '语言';

  @override
  String get project_selectLanguage => '选择语言';

  @override
  String get project_pleaseSelectLanguage => '请选择一种语言';

  @override
  String get project_createProject => '创建项目';

  @override
  String get project_selectLanguageTitle => '选择语言';

  @override
  String get project_addLanguageTitle => '添加语言';

  @override
  String get project_addLanguageSubtitle => '找不到您的语言？在这里添加。';

  @override
  String get project_languageName => '语言名称';

  @override
  String get project_languageNameHint => '例如：科斯雷语';

  @override
  String get project_languageNameRequired => '名称为必填项';

  @override
  String get project_languageCode => '语言代码';

  @override
  String get project_languageCodeHint => '例如：kos (ISO 639-3)';

  @override
  String get project_languageCodeRequired => '代码为必填项';

  @override
  String get project_languageCodeTooLong => '代码必须为1-3个字符';

  @override
  String get project_addLanguage => '添加语言';

  @override
  String get project_noLanguagesFound => '未找到语言';

  @override
  String get project_addNewLanguage => '添加新语言';

  @override
  String project_addAsNewLanguage(String query) {
    return '将\"$query\"添加为新语言';
  }

  @override
  String get project_searchLanguages => '搜索语言...';

  @override
  String get project_backToList => '返回列表';

  @override
  String get projectSettings_title => '项目设置';

  @override
  String get projectSettings_details => '详情';

  @override
  String get projectSettings_saving => '保存中...';

  @override
  String get projectSettings_saveChanges => '保存更改';

  @override
  String get projectSettings_updated => '项目已更新';

  @override
  String get projectSettings_noPermission => '您没有权限更新此项目';

  @override
  String get projectSettings_team => '团队';

  @override
  String get projectSettings_removeMember => '移除成员';

  @override
  String projectSettings_removeMemberConfirm(String name) {
    return '确定要将 $name 从此项目中移除吗？';
  }

  @override
  String get projectSettings_memberRemoved => '成员已移除';

  @override
  String get projectSettings_memberRemoveFailed => '移除成员失败';

  @override
  String get projectSettings_inviteSent => '邀请已成功发送';

  @override
  String get projectSettings_noMembers => '暂无成员';

  @override
  String get recording_selectGenre => '选择体裁';

  @override
  String get recording_selectGenreSubtitle => '为您的故事选择一个体裁';

  @override
  String get recording_selectSubcategory => '选择子类别';

  @override
  String get recording_selectSubcategorySubtitle => '选择一个子类别';

  @override
  String get recording_selectRegister => '选择语域';

  @override
  String get recording_selectRegisterSubtitle => '选择语言语域';

  @override
  String get recording_recordingStep => '录音';

  @override
  String get recording_recordingStepSubtitle => '记录您的故事';

  @override
  String get recording_reviewStep => '审听录音';

  @override
  String get recording_reviewStepSubtitle => '试听并保存';

  @override
  String get recording_genreNotFound => '未找到体裁';

  @override
  String get recording_noGenres => '暂无可用体裁';

  @override
  String get recording_noSubcategories => '暂无可用子类别';

  @override
  String get recording_registerDescription => '选择最能描述此录音语气和正式程度的语域。';

  @override
  String get recording_titleHint => '添加标题（选填）';

  @override
  String get recording_descriptionHint => '添加简短描述（选填）';

  @override
  String get recording_descriptionEmpty => '添加描述';

  @override
  String get recording_saveRecording => '保存录音';

  @override
  String get recording_recordAgain => '重新录音';

  @override
  String get recording_discard => '丢弃';

  @override
  String get recording_discardTitle => '丢弃录音？';

  @override
  String get recording_discardMessage => '此录音将被永久删除。';

  @override
  String get recording_saved => '录音已保存';

  @override
  String get recording_notFound => '未找到录音';

  @override
  String get recording_unknownGenre => '未知体裁';

  @override
  String get recording_splitRecording => '编辑录音';

  @override
  String get recording_moveCategory => '移动分类';

  @override
  String get recording_downloadAudio => '下载音频';

  @override
  String get recording_downloadAudioMessage => '音频文件未存储在此设备上。是否要下载以进行剪辑？';

  @override
  String recording_downloadFailed(String error) {
    return '下载失败：$error';
  }

  @override
  String get recording_audioNotAvailable => '音频文件不可用';

  @override
  String get recording_deleteTitle => '删除录音';

  @override
  String get recording_deleteMessage =>
      '此操作将永久删除设备上的录音。如果已上传，服务器上的录音也将被删除。此操作无法撤消。';

  @override
  String get recording_deleteNoPermission => '您没有权限删除此录音';

  @override
  String get recording_deleteFailed => '删除录音失败';

  @override
  String get recording_deleteFailedLocal => '从服务器删除失败。已从本地移除。';

  @override
  String get recording_cleaningStatusFailed => '更新服务器清理状态失败';

  @override
  String get recording_updateNoPermission => '您没有权限更新此录音';

  @override
  String get recording_moveNoPermission => '您没有权限移动此录音';

  @override
  String get recording_movedSuccess => '录音移动成功';

  @override
  String get recording_updateFailed => '更新服务器失败';

  @override
  String get recordings_title => '录音列表';

  @override
  String get recordings_subtitle => '您收集的故事';

  @override
  String get recordings_importAudio => '导入音频文件';

  @override
  String get recordings_selectProject => '选择项目';

  @override
  String get recordings_selectProjectSubtitle => '选择一个项目以查看其录音';

  @override
  String get recordings_noRecordings => '暂无录音';

  @override
  String get recordings_noRecordingsSubtitle => '点击麦克风录制您的第一个故事，或导入音频文件。';

  @override
  String recordings_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条录音',
      one: '1 条录音',
    );
    return '$_temp0';
  }

  @override
  String get recording_statusUploaded => '已上传';

  @override
  String get recording_statusUploading => '上传中';

  @override
  String get recording_statusFailed => '失败';

  @override
  String get recording_statusLocal => '本地';

  @override
  String get recordings_clearStale => '清除失败项';

  @override
  String get recordings_clearStaleMessage =>
      '此操作将永久删除服务器上所有上传失败或卡住的录音。此操作无法撤消。';

  @override
  String recordings_clearedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已清除 $count 条录音',
      one: '已清除 1 条录音',
      zero: '未找到过期录音',
    );
    return '$_temp0';
  }

  @override
  String get recordings_clearFailed => '清除录音失败';

  @override
  String get trim_title => '编辑录音';

  @override
  String get trim_notFound => '未找到录音';

  @override
  String get trim_audioUrlNotAvailable => '此录音的音频 URL 不可用。';

  @override
  String get trim_localNotAvailable => '本地音频文件不可用。请先下载录音。';

  @override
  String get trim_atLeastOneSegment => '至少需要保留一个片段';

  @override
  String get trim_segments => '片段';

  @override
  String get trim_restoreAll => '全部恢复';

  @override
  String get trim_instructions => '点击上方波形图放置\n分割标记来分割此录音';

  @override
  String get trim_splitting => '拆分中...';

  @override
  String trim_saveSegments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '保存 $count 个片段',
      one: '保存 1 个片段',
    );
    return '$_temp0';
  }

  @override
  String get trim_addSplitsFirst => '请先添加分割点';

  @override
  String trim_savedSegments(int kept, int removed) {
    return '已保存 $kept 个片段，移除了 $removed 个';
  }

  @override
  String trim_splitInto(int count) {
    return '拆分为 $count 条录音';
  }

  @override
  String get trim_saveConfirmTitle => '保存更改？';

  @override
  String trim_saveConfirmBody(int count) {
    return '这将用 $count 个片段替换原始录音。此操作无法撤消。';
  }

  @override
  String get trim_inheritLabel => '继承';

  @override
  String get trim_applyToAll => '应用于所有';

  @override
  String get trim_copyFromPrevious => '从上一个复制';

  @override
  String get trim_classifySegment => '分类片段';

  @override
  String get trim_volume => '音量';

  @override
  String get trim_peakClip => '削波';

  @override
  String get trim_boostOnSave => '保存时应用增益';

  @override
  String get import_title => '导入音频';

  @override
  String get import_selectGenre => '选择体裁';

  @override
  String get import_selectSubcategory => '选择子类别';

  @override
  String get import_selectRegister => '选择语域';

  @override
  String get import_confirmImport => '确认导入';

  @override
  String get import_analyzing => '正在分析音频文件...';

  @override
  String get import_selectFile => '选择要导入的音频文件';

  @override
  String get import_chooseFile => '选择文件';

  @override
  String get import_accessFailed => '无法访问所选文件';

  @override
  String import_pickError(String error) {
    return '选择文件出错：$error';
  }

  @override
  String import_saveError(String error) {
    return '保存文件出错：$error';
  }

  @override
  String get import_unknownFile => '未知文件';

  @override
  String get import_importAndSave => '导入并保存';

  @override
  String get import_setForAll => '为所有文件设置';

  @override
  String get import_applyToAll => '应用到全部';

  @override
  String get import_fieldRequired => '必填';

  @override
  String import_validationBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个文件缺少必填字段',
      one: '有 1 个文件缺少必填字段',
    );
    return '$_temp0';
  }

  @override
  String get import_remove => '移除文件';

  @override
  String import_supportedFormats(String formats) {
    return '支持的格式：$formats。不支持或无法读取的文件将被跳过。';
  }

  @override
  String import_rejectedFiles(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已跳过 $count 个不支持或无法读取的文件：$names',
      one: '已跳过 1 个不支持或无法读取的文件：$names',
    );
    return '$_temp0';
  }

  @override
  String import_countFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个文件',
      one: '1 个文件',
    );
    return '$_temp0';
  }

  @override
  String import_importNFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个文件',
      one: '1 个文件',
    );
    return '导入 $_temp0';
  }

  @override
  String get import_emptyFile => '空文件';

  @override
  String get import_compressWav => '将 WAV 压缩为 M4A';

  @override
  String get import_compressWavHint => '~10x 更小，对 ML 流水线无质量损失';

  @override
  String get moveCategory_title => '移动分类';

  @override
  String get moveCategory_genre => '体裁';

  @override
  String get moveCategory_subcategory => '子类别';

  @override
  String get moveCategory_selectSubcategory => '选择子类别';

  @override
  String get cleaning_needsCleaning => '需要清理';

  @override
  String get cleaning_cleaning => '清理中...';

  @override
  String get cleaning_cleaned => '已清理';

  @override
  String get cleaning_cleanFailed => '清理失败';

  @override
  String get sync_uploading => '上传中...';

  @override
  String sync_pending(int count) {
    return '$count 待处理';
  }

  @override
  String get profile_photoUpdated => '头像已更新';

  @override
  String profile_photoFailed(String error) {
    return '更新头像失败：$error';
  }

  @override
  String get profile_editName => '编辑显示名称';

  @override
  String get profile_nameHint => '您的姓名';

  @override
  String get profile_nameUpdated => '名称已更新';

  @override
  String get profile_syncStorage => '同步与存储';

  @override
  String get profile_about => '关于';

  @override
  String get profile_appVersion => '应用版本';

  @override
  String get profile_byShema => 'Oral Collector 由 Shema 提供';

  @override
  String get profile_administration => '管理';

  @override
  String get profile_adminDashboard => '管理面板';

  @override
  String get profile_adminSubtitle => '系统统计、项目和体裁管理';

  @override
  String get profile_account => '账户';

  @override
  String get profile_logOut => '退出登录';

  @override
  String get profile_deleteAccount => '删除账户';

  @override
  String get profile_deleteAccountConfirm => '确认删除';

  @override
  String get profile_deleteAccountWarning =>
      '此操作是永久性的，无法撤消。您的账户将被删除，但已上传的录音将为语言项目保留。';

  @override
  String get profile_typeDelete => '输入 DELETE 以确认删除账户：';

  @override
  String get profile_clearCacheTitle => '清除本地缓存？';

  @override
  String get profile_clearCacheMessage => '此操作将删除所有本地存储的录音。服务器上已上传的录音不会受到影响。';

  @override
  String get profile_cacheCleared => '本地缓存已清除';

  @override
  String profile_joinedSuccess(String name) {
    return '已成功加入\"$name\"';
  }

  @override
  String get profile_inviteDeclined => '邀请已拒绝';

  @override
  String get profile_language => '语言';

  @override
  String get profile_online => '在线';

  @override
  String get profile_offline => '离线';

  @override
  String profile_lastSync(String time) {
    return '上次同步：$time';
  }

  @override
  String get profile_neverSynced => '从未同步';

  @override
  String profile_pendingCount(int count) {
    return '$count 待处理';
  }

  @override
  String profile_syncingProgress(int percent) {
    return '同步中... $percent%';
  }

  @override
  String get profile_syncNow => '立即同步';

  @override
  String get profile_wifiOnly => '仅在 Wi-Fi 下上传';

  @override
  String get profile_wifiOnlySubtitle => '防止通过移动数据上传';

  @override
  String get profile_autoRemove => '上传后自动删除';

  @override
  String get profile_autoRemoveSubtitle => '上传成功后删除本地文件';

  @override
  String get profile_clearCache => '清除本地缓存';

  @override
  String get profile_clearCacheSubtitle => '删除所有本地存储的录音';

  @override
  String get profile_invitations => '邀请';

  @override
  String get profile_refreshInvitations => '刷新邀请';

  @override
  String get profile_noInvitations => '暂无待处理的邀请';

  @override
  String get profile_roleManager => '角色：管理员';

  @override
  String get profile_roleMember => '角色：成员';

  @override
  String get profile_decline => '拒绝';

  @override
  String get profile_accept => '接受';

  @override
  String get profile_storage => '存储';

  @override
  String get profile_status => '状态';

  @override
  String get profile_pendingLabel => '待处理';

  @override
  String get admin_title => '管理面板';

  @override
  String get admin_overview => '概览';

  @override
  String get admin_projects => '项目';

  @override
  String get admin_genres => '体裁';

  @override
  String get admin_cleaning => '清理';

  @override
  String get admin_accessRequired => '需要管理员权限';

  @override
  String get admin_totalProjects => '项目总数';

  @override
  String get admin_languages => '语言';

  @override
  String get admin_recordings => '录音';

  @override
  String get admin_totalHours => '总时长';

  @override
  String get admin_activeUsers => '活跃用户';

  @override
  String get admin_projectName => '名称';

  @override
  String get admin_projectLanguage => '语言';

  @override
  String get admin_projectMembers => '成员';

  @override
  String get admin_projectRecordings => '录音';

  @override
  String get admin_projectDuration => '时长';

  @override
  String get admin_projectCreated => '创建时间';

  @override
  String get admin_noProjects => '未找到项目';

  @override
  String get admin_unknownLanguage => '未知语言';

  @override
  String get admin_genresAndSubcategories => '体裁与子类别';

  @override
  String get admin_addGenre => '添加体裁';

  @override
  String get admin_noGenres => '未找到体裁';

  @override
  String get admin_genreName => '体裁名称';

  @override
  String get admin_required => '必填';

  @override
  String get admin_descriptionOptional => '描述（选填）';

  @override
  String get admin_genreCreated => '体裁已创建';

  @override
  String get admin_editGenre => '编辑体裁';

  @override
  String get admin_deleteGenre => '删除体裁';

  @override
  String get admin_addSubcategory => '添加子类别';

  @override
  String get admin_editGenreTitle => '编辑体裁';

  @override
  String get admin_genreUpdated => '体裁已更新';

  @override
  String get admin_deleteGenreTitle => '删除体裁';

  @override
  String admin_deleteGenreConfirm(String name) {
    return '确定要删除\"$name\"及其所有子类别吗？';
  }

  @override
  String get admin_genreDeleted => '体裁已删除';

  @override
  String admin_addSubcategoryTo(String name) {
    return '向 $name 添加子类别';
  }

  @override
  String get admin_subcategoryName => '子类别名称';

  @override
  String get admin_subcategoryCreated => '子类别已创建';

  @override
  String get admin_deleteSubcategory => '删除子类别';

  @override
  String admin_deleteSubcategoryConfirm(String name) {
    return '确定要删除\"$name\"吗？';
  }

  @override
  String get admin_subcategoryDeleted => '子类别已删除';

  @override
  String get admin_cleaningQueue => '音频清理队列';

  @override
  String admin_cleanSelected(int count) {
    return '清理所选 ($count)';
  }

  @override
  String get admin_refreshCleaning => '刷新清理队列';

  @override
  String get admin_cleaningWebOnly => '音频清理仅限网页端使用。清理过程在服务器上运行。';

  @override
  String get admin_noCleaningRecordings => '没有标记为需要清理的录音';

  @override
  String get admin_cleaningTitle => '标题';

  @override
  String get admin_cleaningDuration => '时长';

  @override
  String get admin_cleaningSize => '大小';

  @override
  String get admin_cleaningFormat => '格式';

  @override
  String get admin_cleaningRecorded => '录制时间';

  @override
  String get admin_cleaningActions => '操作';

  @override
  String get admin_clean => '清理';

  @override
  String get admin_deselectAll => '取消全选';

  @override
  String get admin_selectAll => '全选';

  @override
  String get admin_cleaningTriggered => '清理已触发';

  @override
  String get admin_cleaningFailed => '触发清理失败';

  @override
  String admin_cleaningPartial(int success, int total) {
    return '已触发 $total 条录音中 $success 条的清理';
  }

  @override
  String get genre_title => '体裁';

  @override
  String get genre_notFound => '未找到体裁';

  @override
  String genre_recordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条录音',
      one: '1 条录音',
    );
    return '$_temp0';
  }

  @override
  String get format_justNow => '刚刚';

  @override
  String format_minutesAgo(int count) {
    return '$count分钟前';
  }

  @override
  String format_hoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String format_daysAgo(int count) {
    return '$count天前';
  }

  @override
  String format_weeksAgo(int count) {
    return '$count周前';
  }

  @override
  String format_monthsAgo(int count) {
    return '$count个月前';
  }

  @override
  String format_memberSince(String date) {
    return '加入于 $date';
  }

  @override
  String get format_member => '成员';

  @override
  String format_dateAt(String date, String time) {
    return '$date $time';
  }

  @override
  String get genre_narrative => '叙事';

  @override
  String get genre_narrativeDesc => '故事、记述及口头传统的叙事形式';

  @override
  String get genre_poeticSong => '诗歌 / 歌曲';

  @override
  String get genre_poeticSongDesc => '音乐和诗歌口头传统，包括赞美诗、哀歌和智慧诗';

  @override
  String get genre_instructional => '教导 / 规范';

  @override
  String get genre_instructionalDesc => '律法、仪式、程序和教导形式';

  @override
  String get genre_oralDiscourse => '口头论述';

  @override
  String get genre_oralDiscourseDesc => '演讲、教导、祷告和口头论述形式';

  @override
  String get sub_historicalNarrative => '历史叙事';

  @override
  String get sub_personalAccount => '个人经历 / 见证';

  @override
  String get sub_parable => '比喻 / 寓言故事';

  @override
  String get sub_originStory => '起源 / 创世故事';

  @override
  String get sub_legend => '传说 / 英雄故事';

  @override
  String get sub_visionNarrative => '异象或梦境叙事';

  @override
  String get sub_genealogy => '家谱';

  @override
  String get sub_eventReport => '近期事件报告';

  @override
  String get sub_hymn => '赞美诗 / 敬拜歌曲';

  @override
  String get sub_lament => '哀歌';

  @override
  String get sub_funeralDirge => '丧歌';

  @override
  String get sub_victorySong => '凯歌 / 庆典歌曲';

  @override
  String get sub_loveSong => '情歌';

  @override
  String get sub_tauntSong => '嘲讽歌';

  @override
  String get sub_blessing => '祝福';

  @override
  String get sub_curse => '咒诅';

  @override
  String get sub_wisdomPoem => '智慧诗 / 箴言';

  @override
  String get sub_didacticPoetry => '教诲诗';

  @override
  String get sub_legalCode => '律法 / 法典';

  @override
  String get sub_ritual => '仪式 / 礼拜';

  @override
  String get sub_procedure => '程序 / 指南';

  @override
  String get sub_listInventory => '清单 / 名录';

  @override
  String get sub_propheticOracle => '先知谕言 / 演讲';

  @override
  String get sub_exhortation => '劝勉 / 讲道';

  @override
  String get sub_wisdomTeaching => '智慧教导';

  @override
  String get sub_prayer => '祷告';

  @override
  String get sub_dialogue => '对话';

  @override
  String get sub_epistle => '书信';

  @override
  String get sub_apocalypticDiscourse => '启示论述';

  @override
  String get sub_ceremonialSpeech => '典礼致辞';

  @override
  String get sub_communityMemory => '社区记忆';

  @override
  String get sub_historicalNarrativeDesc => '关于事件、战争和历史关键时刻的记述';

  @override
  String get sub_personalAccountDesc => '第一人称讲述的个人经历和信仰故事';

  @override
  String get sub_parableDesc => '传达道德或属灵教训的象征性故事';

  @override
  String get sub_originStoryDesc => '关于事物起源的故事';

  @override
  String get sub_legendDesc => '讲述杰出人物及其伟大事迹的故事';

  @override
  String get sub_visionNarrativeDesc => '关于神圣异象和先知性梦境的记述';

  @override
  String get sub_genealogyDesc => '家族谱系和祖先血脉的记录';

  @override
  String get sub_eventReportDesc => '社区近期发生事件的报告';

  @override
  String get sub_hymnDesc => '对上帝的赞美和敬拜之歌';

  @override
  String get sub_lamentDesc => '悲伤、哀痛和哀悼的表达';

  @override
  String get sub_funeralDirgeDesc => '在哀悼和安葬仪式中演唱的歌曲';

  @override
  String get sub_victorySongDesc => '庆祝胜利和欢乐事件的歌曲';

  @override
  String get sub_loveSongDesc => '表达爱与奉献的歌曲';

  @override
  String get sub_tauntSongDesc => '嘲讽敌人或不忠者的歌曲';

  @override
  String get sub_blessingDesc => '祈求神圣恩惠和保护的话语';

  @override
  String get sub_curseDesc => '宣告审判或神圣后果的话语';

  @override
  String get sub_wisdomPoemDesc => '传达实用智慧的短语和诗歌';

  @override
  String get sub_didacticPoetryDesc => '旨在教导和训诲的诗歌作品';

  @override
  String get sub_legalCodeDesc => '规则、法规和盟约条例';

  @override
  String get sub_ritualDesc => '规定的敬拜和神圣仪式形式';

  @override
  String get sub_procedureDesc => '分步骤的指导和实用指南';

  @override
  String get sub_listInventoryDesc => '目录、人口普查和有组织的记录';

  @override
  String get sub_propheticOracleDesc => '代表上帝传达的信息';

  @override
  String get sub_exhortationDesc => '敦促道德和属灵行动的演讲';

  @override
  String get sub_wisdomTeachingDesc => '关于智慧和正义生活的教导';

  @override
  String get sub_prayerDesc => '在敬拜或祈求中向上帝说的话';

  @override
  String get sub_dialogueDesc => '人与人之间的对话和交流';

  @override
  String get sub_epistleDesc => '写给社区或个人的书面信息';

  @override
  String get sub_apocalypticDiscourseDesc => '关于末世和上帝计划的启示';

  @override
  String get sub_ceremonialSpeechDesc => '用于正式或神圣场合的致辞';

  @override
  String get sub_communityMemoryDesc => '保存群体认同的共同回忆';

  @override
  String get register_intimate => '亲密';

  @override
  String get register_casual => '非正式 / 随意';

  @override
  String get register_consultative => '咨询式';

  @override
  String get register_formal => '正式 / 官方';

  @override
  String get register_ceremonial => '典礼式';

  @override
  String get register_elderAuthority => '长辈 / 权威';

  @override
  String get register_religiousWorship => '宗教 / 敬拜';

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
  String get locale_englishSub => '英语';

  @override
  String get locale_portugueseSub => '葡萄牙语';

  @override
  String get locale_hindiSub => '印地语';

  @override
  String get locale_koreanSub => '韩语';

  @override
  String get locale_spanishSub => '西班牙语';

  @override
  String get locale_bahasaSub => '印度尼西亚语';

  @override
  String get locale_frenchSub => '法语';

  @override
  String get locale_tokPisinSub => '巴布亚皮钦语';

  @override
  String get locale_swahiliSub => '斯瓦希里语';

  @override
  String get locale_arabicSub => '阿拉伯语';

  @override
  String get locale_chinese => '中文';

  @override
  String get locale_chineseSub => '中文';

  @override
  String get locale_selectLanguage => '选择您的语言';

  @override
  String get locale_selectLanguageSubtitle => '您可以稍后在个人资料设置中更改。';

  @override
  String get filter_all => '全部';

  @override
  String get filter_pending => '待处理';

  @override
  String get filter_uploaded => '已上传';

  @override
  String get filter_needsCleaning => '需要清理';

  @override
  String get filter_unclassified => '未分类';

  @override
  String get filter_allGenres => '所有体裁';

  @override
  String get detail_duration => '时长';

  @override
  String get detail_size => '大小';

  @override
  String get detail_format => '格式';

  @override
  String get detail_status => '状态';

  @override
  String get detail_upload => '上传';

  @override
  String get detail_uploaded => '已上传';

  @override
  String get detail_cleaning => '清理';

  @override
  String get detail_recorded => '录制时间';

  @override
  String get detail_retry => '重试';

  @override
  String get detail_notFlagged => '未标记';

  @override
  String get detail_uploadStuck => '卡住 — 点击重试';

  @override
  String get detail_uploading => '上传中...';

  @override
  String get detail_maxRetries => '已达最大重试次数 — 点击重试';

  @override
  String get detail_uploadFailed => '上传失败';

  @override
  String get detail_pendingRetried => '待处理（已重试）';

  @override
  String get detail_notSynced => '未同步';

  @override
  String get action_actions => '操作';

  @override
  String get action_split => '编辑';

  @override
  String get action_flagClean => '标记清理';

  @override
  String get action_clearFlag => '清除标记';

  @override
  String get action_move => '移动';

  @override
  String get action_delete => '删除';

  @override
  String get projectStats_recordings => '录音';

  @override
  String get projectStats_duration => '时长';

  @override
  String get projectStats_members => '成员';

  @override
  String get project_active => '活跃';

  @override
  String get recording_paused => '已暂停';

  @override
  String get recording_recording => '录音中';

  @override
  String get recording_tapToRecord => '点击录音';

  @override
  String get recording_sensitivity => '灵敏度';

  @override
  String get recording_sensitivityLow => '低';

  @override
  String get recording_sensitivityMed => '中';

  @override
  String get recording_sensitivityHigh => '高';

  @override
  String get recording_stopRecording => '停止录音';

  @override
  String get recording_stop => '停止';

  @override
  String get recording_resume => '继续';

  @override
  String get recording_pause => '暂停';

  @override
  String get quickRecord_title => '快速录音';

  @override
  String get quickRecord_subtitle => '稍后分类';

  @override
  String get quickRecord_classifyLater => '稍后分类';

  @override
  String get classify_title => '分类录音';

  @override
  String get classify_action => '分类';

  @override
  String get classify_banner => '此录音需要分类后才能上传。';

  @override
  String get classify_success => '录音已分类';

  @override
  String get classify_register => '语域';

  @override
  String get classify_selectRegister => '选择语域';

  @override
  String get recording_unclassified => '未分类';

  @override
  String get recording_inputSource => '输入';

  @override
  String get recording_selectMicrophone => '选择麦克风';

  @override
  String get recording_builtInMicrophone => '系统默认';

  @override
  String get recording_micPermissionNeeded => '请允许访问麦克风以查看设备名称';

  @override
  String get recording_micPermissionButton => '授予权限';

  @override
  String get recording_micPermissionDenied => '麦克风权限被拒绝。请在浏览器或系统设置中启用。';

  @override
  String get recording_micPermissionTitle => 'Microphone access needed';

  @override
  String get recording_noDevicesFound => '未找到麦克风';

  @override
  String get recording_storageLowWarnTitle => '存储空间不足';

  @override
  String recording_storageLowWarnBody(int minutes) {
    return '约可录制 $minutes 分钟。是否继续？';
  }

  @override
  String get recording_storageRefuseTitle => '存储空间不足';

  @override
  String get recording_storageRefuseBody => '录音前请释放此设备上的空间。';

  @override
  String recording_storageCriticalBanner(int minutes) {
    return '存储空间紧张 — 约剩 $minutes 分钟。请尽快停止。';
  }

  @override
  String get recording_storageForceStopped => '因存储空间不足停止录音。您的进度已保存。';

  @override
  String recording_savedAt(String time) {
    return '已保存于 $time';
  }

  @override
  String get recording_continuedInBackground => '录音在后台继续';

  @override
  String get recording_continue => '继续';

  @override
  String get recording_cancel => '取消';

  @override
  String get recording_recoverTitle => '恢复中断的录音？';

  @override
  String recording_recoverBody(int minutes) {
    return '我们发现了上次会话中约 $minutes 分钟的音频。';
  }

  @override
  String get recording_recoverButton => '恢复';

  @override
  String get recording_recoverDiscard => '放弃';

  @override
  String get recording_recoverFailedLastSegment => '末尾附近的部分音频无法读取并已跳过。';

  @override
  String get recording_inProgressNotificationTitle => '正在录音';

  @override
  String get recording_inProgressNotificationBody => '点击返回应用';

  @override
  String get profile_defaultMicrophone => '默认麦克风';

  @override
  String get profile_systemDefault => '系统默认';

  @override
  String get settings_deviceStorageTitle => '设备存储';

  @override
  String settings_deviceStorageSubtitle(String used, String free) {
    return '已用 $used · 可用 $free';
  }

  @override
  String get fab_quickRecord => '快速';

  @override
  String get fab_normalRecord => '录音';

  @override
  String get error_network => '无法连接到服务器。请检查您的网络连接并重试。';

  @override
  String get error_secureConnection => '无法建立安全连接。请稍后重试。';

  @override
  String get error_timeout => '请求超时。请检查您的网络连接并重试。';

  @override
  String get error_invalidCredentials => '邮箱或密码不正确。请重试。';

  @override
  String get error_userNotFound => '未找到与该邮箱关联的账户。';

  @override
  String get error_accountExists => '该邮箱已注册账户。';

  @override
  String get error_emailRequired => '请输入您的邮箱地址。';

  @override
  String get error_passwordRequired => '请输入您的密码。';

  @override
  String get error_signupFailed => '无法创建您的账户。请检查您的信息并重试。';

  @override
  String get error_sessionExpired => '您的会话已过期。请重新登录。';

  @override
  String get error_profileLoadFailed => '无法加载您的个人资料。请重试。';

  @override
  String get error_profileUpdateFailed => '无法更新您的个人资料。请重试。';

  @override
  String get error_imageUploadFailed => '无法上传图片。请重试。';

  @override
  String get error_notAuthenticated => '您尚未登录。请登录后重试。';

  @override
  String get error_noPermission => '您没有执行此操作的权限。';

  @override
  String get error_generic => '出了点问题。请稍后重试。';

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
