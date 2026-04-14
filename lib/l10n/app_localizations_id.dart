// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Oral Collector';

  @override
  String get nav_home => 'Beranda';

  @override
  String get nav_record => 'Rekam';

  @override
  String get nav_recordings => 'Rekaman';

  @override
  String get nav_projects => 'Proyek';

  @override
  String get nav_profile => 'Profil';

  @override
  String get nav_admin => 'Admin';

  @override
  String get nav_collapse => 'Ciutkan';

  @override
  String get common_cancel => 'Batal';

  @override
  String get common_save => 'Simpan';

  @override
  String get common_delete => 'Hapus';

  @override
  String get common_remove => 'Hapus';

  @override
  String get common_create => 'Buat';

  @override
  String get common_continue => 'Lanjutkan';

  @override
  String get common_next => 'Berikutnya';

  @override
  String get common_retry => 'Coba Lagi';

  @override
  String get common_move => 'Pindahkan';

  @override
  String get common_invite => 'Undang';

  @override
  String get common_download => 'Unduh';

  @override
  String get common_clear => 'Bersihkan';

  @override
  String get common_untitled => 'Tanpa judul';

  @override
  String get common_loading => 'Memuat...';

  @override
  String get auth_oralCollector => 'Oral Collector';

  @override
  String get auth_byShema => 'oleh Shema';

  @override
  String get auth_heroTagline => 'Lestarikan suara.\nBagikan cerita.';

  @override
  String get auth_welcomeBack => 'Selamat\nDatang Kembali';

  @override
  String get auth_welcome => 'Selamat Datang ';

  @override
  String get auth_back => 'Kembali';

  @override
  String get auth_createWord => 'Buat ';

  @override
  String get auth_createNewline => 'Buat\n';

  @override
  String get auth_account => 'Akun';

  @override
  String get auth_signInSubtitle =>
      'Masuk untuk melanjutkan mengumpulkan cerita.';

  @override
  String get auth_signUpSubtitle =>
      'Bergabunglah dengan komunitas pengumpul cerita kami.';

  @override
  String get auth_backToSignIn => 'Kembali ke masuk';

  @override
  String get auth_emailLabel => 'Alamat Email';

  @override
  String get auth_emailHint => 'email@anda.com';

  @override
  String get auth_emailRequired => 'Silakan masukkan email Anda';

  @override
  String get auth_emailInvalid => 'Silakan masukkan email yang valid';

  @override
  String get auth_passwordLabel => 'Kata Sandi';

  @override
  String get auth_passwordHint => 'Minimal 6 karakter';

  @override
  String get auth_passwordRequired => 'Silakan masukkan kata sandi Anda';

  @override
  String get auth_passwordTooShort => 'Kata sandi harus minimal 6 karakter';

  @override
  String get auth_confirmPasswordLabel => 'Konfirmasi Kata Sandi';

  @override
  String get auth_confirmPasswordHint => 'Masukkan ulang kata sandi';

  @override
  String get auth_confirmPasswordRequired =>
      'Silakan konfirmasi kata sandi Anda';

  @override
  String get auth_confirmPasswordMismatch => 'Kata sandi tidak cocok';

  @override
  String get auth_nameLabel => 'Nama';

  @override
  String get auth_nameHint => 'Nama lengkap Anda';

  @override
  String get auth_nameRequired => 'Silakan masukkan nama tampilan Anda';

  @override
  String get auth_signIn => 'Masuk';

  @override
  String get auth_signUp => 'Daftar';

  @override
  String get auth_noAccount => 'Belum punya akun? ';

  @override
  String get auth_haveAccount => 'Sudah punya akun? ';

  @override
  String get auth_continueButton => 'Lanjutkan';

  @override
  String get auth_forgotPassword => 'Lupa kata sandi?';

  @override
  String get auth_resetPassword => 'Atur Ulang Kata Sandi';

  @override
  String get auth_forgotPasswordSubtitle =>
      'Masukkan email Anda dan kami akan mengirimkan tautan pengaturan ulang.';

  @override
  String get auth_sendResetLink => 'Kirim Tautan';

  @override
  String get auth_sending => 'Mengirim...';

  @override
  String get auth_checkYourEmail => 'Periksa Email Anda';

  @override
  String auth_resetEmailSent(String email) {
    return 'Kami mengirimkan tautan pengaturan ulang kata sandi ke $email. Periksa kotak masuk Anda dan ikuti tautan untuk membuat kata sandi baru.';
  }

  @override
  String get auth_openEmailApp => 'Buka Email';

  @override
  String get auth_resendEmail => 'Kirim Ulang';

  @override
  String get auth_backToLogin => 'Kembali ke Login';

  @override
  String get auth_newPassword => 'Kata Sandi Baru';

  @override
  String get auth_confirmNewPassword => 'Konfirmasi Kata Sandi Baru';

  @override
  String get auth_resetPasswordSubtitle =>
      'Masukkan kata sandi baru Anda di bawah.';

  @override
  String get auth_resetPasswordButton => 'Atur Ulang Kata Sandi';

  @override
  String get auth_resetting => 'Mengatur ulang...';

  @override
  String get auth_resetSuccess =>
      'Kata sandi berhasil diatur ulang! Anda sekarang dapat masuk dengan kata sandi baru.';

  @override
  String get auth_invalidResetLink => 'Tautan Tidak Valid';

  @override
  String get auth_invalidResetLinkMessage =>
      'Tautan pengaturan ulang ini tidak valid atau telah kedaluwarsa.';

  @override
  String get auth_requestNewLink => 'Minta Tautan Baru';

  @override
  String get home_greetingMorning => 'Selamat pagi';

  @override
  String get home_greetingAfternoon => 'Selamat siang';

  @override
  String get home_greetingEvening => 'Selamat malam';

  @override
  String home_greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get home_subtitle => 'Mari bagikan cerita Anda hari ini';

  @override
  String get home_switchProject => 'Ganti proyek';

  @override
  String get home_genres => 'Genre';

  @override
  String get home_loadingProjects => 'Memuat proyek...';

  @override
  String get home_loadingGenres => 'Memuat genre...';

  @override
  String get home_noGenres => 'Belum ada genre tersedia';

  @override
  String get home_noProjectTitle => 'Pilih proyek untuk memulai';

  @override
  String get home_browseProjects => 'Jelajahi Proyek';

  @override
  String get stats_recordings => 'rekaman';

  @override
  String get stats_recorded => 'direkam';

  @override
  String get stats_members => 'anggota';

  @override
  String get project_switchTitle => 'Ganti Proyek';

  @override
  String get project_projects => 'Proyek';

  @override
  String get project_subtitle => 'Kelola koleksi Anda';

  @override
  String get project_noProjectsTitle => 'Belum ada proyek';

  @override
  String get project_noProjectsSubtitle =>
      'Buat proyek pertama Anda untuk mulai mengumpulkan cerita lisan.';

  @override
  String get project_newProject => 'Proyek Baru';

  @override
  String get project_projectName => 'Nama Proyek';

  @override
  String get project_projectNameHint => 'mis. Terjemahan Alkitab Kosrae';

  @override
  String get project_projectNameRequired => 'Nama proyek wajib diisi';

  @override
  String get project_description => 'Deskripsi';

  @override
  String get project_descriptionHint => 'Opsional';

  @override
  String get project_language => 'Bahasa';

  @override
  String get project_selectLanguage => 'Pilih bahasa';

  @override
  String get project_pleaseSelectLanguage => 'Silakan pilih bahasa';

  @override
  String get project_createProject => 'Buat Proyek';

  @override
  String get project_selectLanguageTitle => 'Pilih Bahasa';

  @override
  String get project_addLanguageTitle => 'Tambah Bahasa';

  @override
  String get project_addLanguageSubtitle =>
      'Tidak menemukan bahasa Anda? Tambahkan di sini.';

  @override
  String get project_languageName => 'Nama Bahasa';

  @override
  String get project_languageNameHint => 'mis. Kosrae';

  @override
  String get project_languageNameRequired => 'Nama wajib diisi';

  @override
  String get project_languageCode => 'Kode Bahasa';

  @override
  String get project_languageCodeHint => 'mis. kos (ISO 639-3)';

  @override
  String get project_languageCodeRequired => 'Kode wajib diisi';

  @override
  String get project_languageCodeTooLong => 'Kode harus 1-3 karakter';

  @override
  String get project_addLanguage => 'Tambah Bahasa';

  @override
  String get project_noLanguagesFound => 'Tidak ada bahasa ditemukan';

  @override
  String get project_addNewLanguage => 'Tambah bahasa baru';

  @override
  String project_addAsNewLanguage(String query) {
    return 'Tambah \"$query\" sebagai bahasa baru';
  }

  @override
  String get project_searchLanguages => 'Cari bahasa...';

  @override
  String get project_backToList => 'Kembali ke daftar';

  @override
  String get projectSettings_title => 'Pengaturan Proyek';

  @override
  String get projectSettings_details => 'Detail';

  @override
  String get projectSettings_saving => 'Menyimpan...';

  @override
  String get projectSettings_saveChanges => 'Simpan Perubahan';

  @override
  String get projectSettings_updated => 'Proyek diperbarui';

  @override
  String get projectSettings_noPermission =>
      'Anda tidak memiliki izin untuk memperbarui proyek ini';

  @override
  String get projectSettings_team => 'Tim';

  @override
  String get projectSettings_removeMember => 'Hapus Anggota';

  @override
  String projectSettings_removeMemberConfirm(String name) {
    return 'Hapus $name dari proyek ini?';
  }

  @override
  String get projectSettings_memberRemoved => 'Anggota dihapus';

  @override
  String get projectSettings_memberRemoveFailed => 'Gagal menghapus anggota';

  @override
  String get projectSettings_inviteSent => 'Undangan berhasil dikirim';

  @override
  String get projectSettings_noMembers => 'Belum ada anggota';

  @override
  String get recording_selectGenre => 'Pilih Genre';

  @override
  String get recording_selectGenreSubtitle => 'Pilih genre untuk cerita Anda';

  @override
  String get recording_selectSubcategory => 'Pilih Subkategori';

  @override
  String get recording_selectSubcategorySubtitle => 'Pilih subkategori';

  @override
  String get recording_selectRegister => 'Pilih Register';

  @override
  String get recording_selectRegisterSubtitle => 'Pilih register bicara';

  @override
  String get recording_recordingStep => 'Perekaman';

  @override
  String get recording_recordingStepSubtitle => 'Rekam cerita Anda';

  @override
  String get recording_reviewStep => 'Tinjau Rekaman';

  @override
  String get recording_reviewStepSubtitle => 'Dengarkan dan simpan';

  @override
  String get recording_genreNotFound => 'Genre tidak ditemukan';

  @override
  String get recording_noGenres => 'Tidak ada genre tersedia';

  @override
  String get recording_noSubcategories => 'Tidak ada subkategori tersedia';

  @override
  String get recording_registerDescription =>
      'Pilih register bicara yang paling menggambarkan nada dan formalitas rekaman ini.';

  @override
  String get recording_titleHint => 'Tambah judul (opsional)';

  @override
  String get recording_descriptionHint => 'Tambah deskripsi singkat (opsional)';

  @override
  String get recording_descriptionEmpty => 'Tambah deskripsi';

  @override
  String get recording_saveRecording => 'Simpan Rekaman';

  @override
  String get recording_recordAgain => 'Rekam Ulang';

  @override
  String get recording_discard => 'Buang';

  @override
  String get recording_discardTitle => 'Buang Rekaman?';

  @override
  String get recording_discardMessage =>
      'Rekaman ini akan dihapus secara permanen.';

  @override
  String get recording_saved => 'Rekaman disimpan';

  @override
  String get recording_notFound => 'Rekaman tidak ditemukan';

  @override
  String get recording_unknownGenre => 'Genre tidak dikenal';

  @override
  String get recording_splitRecording => 'Bagi Rekaman';

  @override
  String get recording_moveCategory => 'Pindah Kategori';

  @override
  String get recording_downloadAudio => 'Unduh Audio';

  @override
  String get recording_downloadAudioMessage =>
      'File audio tidak tersimpan di perangkat ini. Apakah Anda ingin mengunduhnya untuk memotong?';

  @override
  String recording_downloadFailed(String error) {
    return 'Gagal mengunduh: $error';
  }

  @override
  String get recording_audioNotAvailable => 'File audio tidak tersedia';

  @override
  String get recording_deleteTitle => 'Hapus Rekaman';

  @override
  String get recording_deleteMessage =>
      'Ini akan menghapus rekaman ini secara permanen dari perangkat Anda. Jika sudah diunggah, rekaman juga akan dihapus dari server. Tindakan ini tidak dapat dibatalkan.';

  @override
  String get recording_deleteNoPermission =>
      'Anda tidak memiliki izin untuk menghapus rekaman ini';

  @override
  String get recording_deleteFailed => 'Gagal menghapus rekaman';

  @override
  String get recording_deleteFailedLocal =>
      'Gagal menghapus dari server. Menghapus secara lokal.';

  @override
  String get recording_cleaningStatusFailed =>
      'Gagal memperbarui status pembersihan di server';

  @override
  String get recording_updateNoPermission =>
      'Anda tidak memiliki izin untuk memperbarui rekaman ini';

  @override
  String get recording_moveNoPermission =>
      'Anda tidak memiliki izin untuk memindahkan rekaman ini';

  @override
  String get recording_movedSuccess => 'Rekaman berhasil dipindahkan';

  @override
  String get recording_updateFailed => 'Gagal memperbarui di server';

  @override
  String get recordings_title => 'Rekaman';

  @override
  String get recordings_subtitle => 'Cerita yang Anda kumpulkan';

  @override
  String get recordings_importAudio => 'Impor file audio';

  @override
  String get recordings_selectProject => 'Pilih proyek';

  @override
  String get recordings_selectProjectSubtitle =>
      'Pilih proyek untuk melihat rekamannya';

  @override
  String get recordings_noRecordings => 'Belum ada rekaman';

  @override
  String get recordings_noRecordingsSubtitle =>
      'Ketuk mikrofon untuk merekam cerita pertama Anda, atau impor file audio.';

  @override
  String recordings_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rekaman',
      one: '1 rekaman',
    );
    return '$_temp0';
  }

  @override
  String get recording_statusUploaded => 'Diunggah';

  @override
  String get recording_statusUploading => 'Mengunggah';

  @override
  String get recording_statusFailed => 'Gagal';

  @override
  String get recording_statusLocal => 'Lokal';

  @override
  String get recordings_clearStale => 'Bersihkan yang gagal';

  @override
  String get recordings_clearStaleMessage =>
      'Ini akan menghapus secara permanen semua rekaman dengan status unggahan gagal atau macet dari server. Tindakan ini tidak dapat dibatalkan.';

  @override
  String recordings_clearedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rekaman dibersihkan',
      one: '1 rekaman dibersihkan',
      zero: 'Tidak ada rekaman usang ditemukan',
    );
    return '$_temp0';
  }

  @override
  String get recordings_clearFailed => 'Gagal membersihkan rekaman';

  @override
  String get trim_title => 'Bagi Rekaman';

  @override
  String get trim_notFound => 'Rekaman tidak ditemukan';

  @override
  String get trim_audioUrlNotAvailable =>
      'URL audio tidak tersedia untuk rekaman ini.';

  @override
  String get trim_localNotAvailable =>
      'File audio lokal tidak tersedia. Unduh rekaman terlebih dahulu.';

  @override
  String get trim_atLeastOneSegment =>
      'Setidaknya satu segmen harus dipertahankan';

  @override
  String get trim_segments => 'Segmen';

  @override
  String get trim_restoreAll => 'Pulihkan semua';

  @override
  String get trim_instructions =>
      'Ketuk pada gelombang suara di atas untuk menempatkan\npenanda pembagian dan membagi rekaman ini';

  @override
  String get trim_splitting => 'Membagi...';

  @override
  String trim_saveSegments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Simpan $count segmen',
      one: 'Simpan 1 segmen',
    );
    return '$_temp0';
  }

  @override
  String get trim_addSplitsFirst => 'Tambahkan pembagian terlebih dahulu';

  @override
  String trim_savedSegments(int kept, int removed) {
    return 'Tersimpan $kept segmen, dihapus $removed';
  }

  @override
  String trim_splitInto(int count) {
    return 'Bagi menjadi $count rekaman';
  }

  @override
  String get import_title => 'Impor Audio';

  @override
  String get import_selectGenre => 'Pilih Genre';

  @override
  String get import_selectSubcategory => 'Pilih Subkategori';

  @override
  String get import_selectRegister => 'Pilih Register';

  @override
  String get import_confirmImport => 'Konfirmasi Impor';

  @override
  String get import_analyzing => 'Menganalisis file audio...';

  @override
  String get import_selectFile => 'Pilih file audio untuk diimpor';

  @override
  String get import_chooseFile => 'Pilih File';

  @override
  String get import_accessFailed => 'Tidak dapat mengakses file yang dipilih';

  @override
  String import_pickError(String error) {
    return 'Kesalahan memilih file: $error';
  }

  @override
  String import_saveError(String error) {
    return 'Kesalahan menyimpan file: $error';
  }

  @override
  String get import_unknownFile => 'File tidak dikenal';

  @override
  String get import_importAndSave => 'Impor dan Simpan';

  @override
  String get moveCategory_title => 'Pindah Kategori';

  @override
  String get moveCategory_genre => 'Genre';

  @override
  String get moveCategory_subcategory => 'Subkategori';

  @override
  String get moveCategory_selectSubcategory => 'Pilih subkategori';

  @override
  String get cleaning_needsCleaning => 'Perlu Pembersihan';

  @override
  String get cleaning_cleaning => 'Membersihkan...';

  @override
  String get cleaning_cleaned => 'Bersih';

  @override
  String get cleaning_cleanFailed => 'Pembersihan Gagal';

  @override
  String get sync_uploading => 'Mengunggah...';

  @override
  String sync_pending(int count) {
    return '$count tertunda';
  }

  @override
  String get profile_photoUpdated => 'Foto profil diperbarui';

  @override
  String profile_photoFailed(String error) {
    return 'Gagal memperbarui foto: $error';
  }

  @override
  String get profile_editName => 'Edit nama tampilan';

  @override
  String get profile_nameHint => 'Nama Anda';

  @override
  String get profile_nameUpdated => 'Nama diperbarui';

  @override
  String get profile_syncStorage => 'Sinkronisasi & Penyimpanan';

  @override
  String get profile_about => 'Tentang';

  @override
  String get profile_appVersion => 'Versi aplikasi';

  @override
  String get profile_byShema => 'Oral Collector oleh Shema';

  @override
  String get profile_administration => 'Administrasi';

  @override
  String get profile_adminDashboard => 'Dasbor Admin';

  @override
  String get profile_adminSubtitle =>
      'Statistik sistem, proyek & manajemen genre';

  @override
  String get profile_account => 'Akun';

  @override
  String get profile_logOut => 'Keluar';

  @override
  String get profile_deleteAccount => 'Hapus Akun';

  @override
  String get profile_deleteAccountConfirm => 'Konfirmasi Penghapusan';

  @override
  String get profile_deleteAccountWarning =>
      'Tindakan ini bersifat permanen dan tidak dapat dibatalkan. Akun Anda akan dihapus, tetapi rekaman yang telah diunggah akan dipertahankan untuk proyek bahasa.';

  @override
  String get profile_typeDelete =>
      'Ketik DELETE untuk mengonfirmasi penghapusan akun:';

  @override
  String get profile_clearCacheTitle => 'Bersihkan cache lokal?';

  @override
  String get profile_clearCacheMessage =>
      'Ini akan menghapus semua rekaman yang tersimpan secara lokal. Rekaman yang telah diunggah ke server tidak akan terpengaruh.';

  @override
  String get profile_cacheCleared => 'Cache lokal dibersihkan';

  @override
  String profile_joinedSuccess(String name) {
    return 'Berhasil bergabung dengan \"$name\"';
  }

  @override
  String get profile_inviteDeclined => 'Undangan ditolak';

  @override
  String get profile_language => 'Bahasa';

  @override
  String get profile_online => 'Online';

  @override
  String get profile_offline => 'Offline';

  @override
  String profile_lastSync(String time) {
    return 'Sinkronisasi terakhir: $time';
  }

  @override
  String get profile_neverSynced => 'Belum pernah disinkronkan';

  @override
  String profile_pendingCount(int count) {
    return '$count tertunda';
  }

  @override
  String profile_syncingProgress(int percent) {
    return 'Menyinkronkan... $percent%';
  }

  @override
  String get profile_syncNow => 'Sinkronkan Sekarang';

  @override
  String get profile_wifiOnly => 'Unggah hanya melalui Wi-Fi';

  @override
  String get profile_wifiOnlySubtitle =>
      'Cegah pengunggahan melalui data seluler';

  @override
  String get profile_autoRemove => 'Hapus otomatis setelah unggah';

  @override
  String get profile_autoRemoveSubtitle =>
      'Hapus file lokal setelah pengunggahan berhasil';

  @override
  String get profile_clearCache => 'Bersihkan cache lokal';

  @override
  String get profile_clearCacheSubtitle =>
      'Hapus semua rekaman yang tersimpan secara lokal';

  @override
  String get profile_invitations => 'Undangan';

  @override
  String get profile_refreshInvitations => 'Perbarui undangan';

  @override
  String get profile_noInvitations => 'Tidak ada undangan tertunda';

  @override
  String get profile_roleManager => 'Peran: Manajer';

  @override
  String get profile_roleMember => 'Peran: Anggota';

  @override
  String get profile_decline => 'Tolak';

  @override
  String get profile_accept => 'Terima';

  @override
  String get profile_storage => 'Penyimpanan';

  @override
  String get profile_status => 'Status';

  @override
  String get profile_pendingLabel => 'Tertunda';

  @override
  String get admin_title => 'Dasbor Admin';

  @override
  String get admin_overview => 'Ringkasan';

  @override
  String get admin_projects => 'Proyek';

  @override
  String get admin_genres => 'Genre';

  @override
  String get admin_cleaning => 'Pembersihan';

  @override
  String get admin_accessRequired => 'Diperlukan akses admin';

  @override
  String get admin_totalProjects => 'Total Proyek';

  @override
  String get admin_languages => 'Bahasa';

  @override
  String get admin_recordings => 'Rekaman';

  @override
  String get admin_totalHours => 'Total Jam';

  @override
  String get admin_activeUsers => 'Pengguna Aktif';

  @override
  String get admin_projectName => 'Nama';

  @override
  String get admin_projectLanguage => 'Bahasa';

  @override
  String get admin_projectMembers => 'Anggota';

  @override
  String get admin_projectRecordings => 'Rekaman';

  @override
  String get admin_projectDuration => 'Durasi';

  @override
  String get admin_projectCreated => 'Dibuat';

  @override
  String get admin_noProjects => 'Tidak ada proyek ditemukan';

  @override
  String get admin_unknownLanguage => 'Bahasa tidak dikenal';

  @override
  String get admin_genresAndSubcategories => 'Genre & Subkategori';

  @override
  String get admin_addGenre => 'Tambah Genre';

  @override
  String get admin_noGenres => 'Tidak ada genre ditemukan';

  @override
  String get admin_genreName => 'Nama Genre';

  @override
  String get admin_required => 'Wajib';

  @override
  String get admin_descriptionOptional => 'Deskripsi (opsional)';

  @override
  String get admin_genreCreated => 'Genre dibuat';

  @override
  String get admin_editGenre => 'Edit genre';

  @override
  String get admin_deleteGenre => 'Hapus genre';

  @override
  String get admin_addSubcategory => 'Tambah subkategori';

  @override
  String get admin_editGenreTitle => 'Edit Genre';

  @override
  String get admin_genreUpdated => 'Genre diperbarui';

  @override
  String get admin_deleteGenreTitle => 'Hapus Genre';

  @override
  String admin_deleteGenreConfirm(String name) {
    return 'Hapus \"$name\" dan semua subkategorinya?';
  }

  @override
  String get admin_genreDeleted => 'Genre dihapus';

  @override
  String admin_addSubcategoryTo(String name) {
    return 'Tambah Subkategori ke $name';
  }

  @override
  String get admin_subcategoryName => 'Nama Subkategori';

  @override
  String get admin_subcategoryCreated => 'Subkategori dibuat';

  @override
  String get admin_deleteSubcategory => 'Hapus Subkategori';

  @override
  String admin_deleteSubcategoryConfirm(String name) {
    return 'Hapus \"$name\"?';
  }

  @override
  String get admin_subcategoryDeleted => 'Subkategori dihapus';

  @override
  String get admin_cleaningQueue => 'Antrean Pembersihan Audio';

  @override
  String admin_cleanSelected(int count) {
    return 'Bersihkan Terpilih ($count)';
  }

  @override
  String get admin_refreshCleaning => 'Perbarui antrean pembersihan';

  @override
  String get admin_cleaningWebOnly =>
      'Pembersihan audio adalah fitur khusus web. Proses pembersihan berjalan di server.';

  @override
  String get admin_noCleaningRecordings =>
      'Tidak ada rekaman yang ditandai untuk pembersihan';

  @override
  String get admin_cleaningTitle => 'Judul';

  @override
  String get admin_cleaningDuration => 'Durasi';

  @override
  String get admin_cleaningSize => 'Ukuran';

  @override
  String get admin_cleaningFormat => 'Format';

  @override
  String get admin_cleaningRecorded => 'Direkam';

  @override
  String get admin_cleaningActions => 'Tindakan';

  @override
  String get admin_clean => 'Bersihkan';

  @override
  String get admin_deselectAll => 'Batal Pilih Semua';

  @override
  String get admin_selectAll => 'Pilih Semua';

  @override
  String get admin_cleaningTriggered => 'Pembersihan dimulai';

  @override
  String get admin_cleaningFailed => 'Gagal memulai pembersihan';

  @override
  String admin_cleaningPartial(int success, int total) {
    return 'Pembersihan dimulai untuk $success dari $total rekaman';
  }

  @override
  String get genre_title => 'Genre';

  @override
  String get genre_notFound => 'Genre tidak ditemukan';

  @override
  String genre_recordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rekaman',
      one: '1 rekaman',
    );
    return '$_temp0';
  }

  @override
  String get format_justNow => 'baru saja';

  @override
  String format_minutesAgo(int count) {
    return '${count}m lalu';
  }

  @override
  String format_hoursAgo(int count) {
    return '${count}j lalu';
  }

  @override
  String format_daysAgo(int count) {
    return '${count}h lalu';
  }

  @override
  String format_weeksAgo(int count) {
    return '${count}mg lalu';
  }

  @override
  String format_monthsAgo(int count) {
    return '${count}bl lalu';
  }

  @override
  String format_memberSince(String date) {
    return 'Anggota sejak $date';
  }

  @override
  String get format_member => 'Anggota';

  @override
  String format_dateAt(String date, String time) {
    return '$date pukul $time';
  }

  @override
  String get genre_narrative => 'Naratif';

  @override
  String get genre_narrativeDesc =>
      'Cerita, kisah, dan bentuk naratif dari tradisi lisan';

  @override
  String get genre_poeticSong => 'Puisi / Lagu';

  @override
  String get genre_poeticSongDesc =>
      'Tradisi lisan musikal dan puitis, termasuk himne, ratapan, dan puisi hikmat';

  @override
  String get genre_instructional => 'Instruksional / Regulatif';

  @override
  String get genre_instructionalDesc =>
      'Hukum, ritual, prosedur, dan bentuk instruksional';

  @override
  String get genre_oralDiscourse => 'Wacana Lisan';

  @override
  String get genre_oralDiscourseDesc =>
      'Pidato, pengajaran, doa, dan bentuk wacana lisan';

  @override
  String get sub_historicalNarrative => 'Narasi Sejarah';

  @override
  String get sub_personalAccount => 'Kisah Pribadi / Kesaksian';

  @override
  String get sub_parable => 'Perumpamaan / Cerita Ilustrasi';

  @override
  String get sub_originStory => 'Cerita Asal Usul / Penciptaan';

  @override
  String get sub_legend => 'Legenda / Cerita Pahlawan';

  @override
  String get sub_visionNarrative => 'Narasi Penglihatan atau Mimpi';

  @override
  String get sub_genealogy => 'Silsilah';

  @override
  String get sub_eventReport => 'Laporan Peristiwa Terkini';

  @override
  String get sub_hymn => 'Himne / Lagu Pujian';

  @override
  String get sub_lament => 'Ratapan';

  @override
  String get sub_funeralDirge => 'Nyanyian Pemakaman';

  @override
  String get sub_victorySong => 'Lagu Kemenangan / Perayaan';

  @override
  String get sub_loveSong => 'Lagu Cinta';

  @override
  String get sub_tauntSong => 'Lagu Ejekan / Olok-olok';

  @override
  String get sub_blessing => 'Berkat';

  @override
  String get sub_curse => 'Kutukan';

  @override
  String get sub_wisdomPoem => 'Puisi Hikmat / Amsal';

  @override
  String get sub_didacticPoetry => 'Puisi Didaktis';

  @override
  String get sub_legalCode => 'Hukum / Kode Hukum';

  @override
  String get sub_ritual => 'Ritual / Liturgi';

  @override
  String get sub_procedure => 'Prosedur / Instruksi';

  @override
  String get sub_listInventory => 'Daftar / Inventaris';

  @override
  String get sub_propheticOracle => 'Nubuat / Pidato Profetik';

  @override
  String get sub_exhortation => 'Nasihat / Khotbah';

  @override
  String get sub_wisdomTeaching => 'Pengajaran Hikmat';

  @override
  String get sub_prayer => 'Doa';

  @override
  String get sub_dialogue => 'Dialog';

  @override
  String get sub_epistle => 'Surat / Epistola';

  @override
  String get sub_apocalypticDiscourse => 'Wacana Apokaliptik';

  @override
  String get sub_ceremonialSpeech => 'Pidato Seremonial';

  @override
  String get sub_communityMemory => 'Memori Komunitas';

  @override
  String get sub_historicalNarrativeDesc =>
      'Kisah peristiwa, perang, dan momen penting dalam sejarah';

  @override
  String get sub_personalAccountDesc =>
      'Cerita pribadi tentang pengalaman hidup dan iman';

  @override
  String get sub_parableDesc =>
      'Cerita simbolis yang mengajarkan pelajaran moral atau spiritual';

  @override
  String get sub_originStoryDesc =>
      'Cerita tentang bagaimana segala sesuatu bermula';

  @override
  String get sub_legendDesc =>
      'Kisah tentang orang-orang luar biasa dan perbuatan besar mereka';

  @override
  String get sub_visionNarrativeDesc =>
      'Kisah tentang penglihatan ilahi dan mimpi profetik';

  @override
  String get sub_genealogyDesc => 'Catatan garis keluarga dan silsilah leluhur';

  @override
  String get sub_eventReportDesc => 'Laporan kejadian terkini di komunitas';

  @override
  String get sub_hymnDesc => 'Lagu pujian dan penyembahan kepada Tuhan';

  @override
  String get sub_lamentDesc => 'Ungkapan kesedihan, duka, dan perkabungan';

  @override
  String get sub_funeralDirgeDesc =>
      'Nyanyian yang dibawakan saat upacara berkabung dan pemakaman';

  @override
  String get sub_victorySongDesc =>
      'Lagu yang merayakan kemenangan dan peristiwa gembira';

  @override
  String get sub_loveSongDesc => 'Lagu yang mengungkapkan cinta dan pengabdian';

  @override
  String get sub_tauntSongDesc =>
      'Lagu ejekan yang ditujukan kepada musuh atau orang yang tidak setia';

  @override
  String get sub_blessingDesc =>
      'Kata-kata yang memohon berkat dan perlindungan ilahi';

  @override
  String get sub_curseDesc => 'Pernyataan penghakiman atau konsekuensi ilahi';

  @override
  String get sub_wisdomPoemDesc =>
      'Pepatah dan puisi yang menyampaikan hikmat praktis';

  @override
  String get sub_didacticPoetryDesc =>
      'Komposisi puitis yang dirancang untuk mengajar dan menginstruksikan';

  @override
  String get sub_legalCodeDesc =>
      'Aturan, undang-undang, dan peraturan perjanjian';

  @override
  String get sub_ritualDesc =>
      'Bentuk ibadah dan upacara sakral yang ditetapkan';

  @override
  String get sub_procedureDesc =>
      'Panduan praktis dan petunjuk langkah demi langkah';

  @override
  String get sub_listInventoryDesc =>
      'Katalog, sensus, dan catatan terorganisir';

  @override
  String get sub_propheticOracleDesc =>
      'Pesan yang disampaikan atas nama Tuhan';

  @override
  String get sub_exhortationDesc =>
      'Pidato yang mendorong tindakan moral dan spiritual';

  @override
  String get sub_wisdomTeachingDesc =>
      'Pengajaran tentang hidup dengan bijak dan benar';

  @override
  String get sub_prayerDesc =>
      'Kata-kata yang ditujukan kepada Tuhan dalam ibadah atau permohonan';

  @override
  String get sub_dialogueDesc => 'Percakapan dan pertukaran antara orang-orang';

  @override
  String get sub_epistleDesc =>
      'Pesan tertulis yang ditujukan kepada komunitas atau individu';

  @override
  String get sub_apocalypticDiscourseDesc =>
      'Wahyu tentang akhir zaman dan rencana Tuhan';

  @override
  String get sub_ceremonialSpeechDesc =>
      'Pidato formal untuk acara resmi atau sakral';

  @override
  String get sub_communityMemoryDesc =>
      'Kenangan bersama yang melestarikan identitas kelompok';

  @override
  String get register_intimate => 'Intim';

  @override
  String get register_casual => 'Informal / Santai';

  @override
  String get register_consultative => 'Konsultatif';

  @override
  String get register_formal => 'Formal / Resmi';

  @override
  String get register_ceremonial => 'Seremonial';

  @override
  String get register_elderAuthority => 'Tetua / Otoritas';

  @override
  String get register_religiousWorship => 'Religius / Ibadah';

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
  String get locale_englishSub => 'Inggris';

  @override
  String get locale_portugueseSub => 'Portugis';

  @override
  String get locale_hindiSub => 'Hindi';

  @override
  String get locale_koreanSub => 'Korea';

  @override
  String get locale_spanishSub => 'Spanyol';

  @override
  String get locale_bahasaSub => 'Bahasa Indonesia';

  @override
  String get locale_frenchSub => 'Prancis';

  @override
  String get locale_tokPisinSub => 'Tok Pisin';

  @override
  String get locale_swahiliSub => 'Swahili';

  @override
  String get locale_arabicSub => 'Arab';

  @override
  String get locale_chinese => '中文';

  @override
  String get locale_chineseSub => 'Tionghoa';

  @override
  String get locale_selectLanguage => 'Pilih Bahasa Anda';

  @override
  String get locale_selectLanguageSubtitle =>
      'Anda dapat mengubah ini nanti di pengaturan profil.';

  @override
  String get filter_all => 'Semua';

  @override
  String get filter_pending => 'Tertunda';

  @override
  String get filter_uploaded => 'Diunggah';

  @override
  String get filter_needsCleaning => 'Perlu Pembersihan';

  @override
  String get filter_unclassified => 'Belum diklasifikasi';

  @override
  String get filter_allGenres => 'Semua genre';

  @override
  String get detail_duration => 'Durasi';

  @override
  String get detail_size => 'Ukuran';

  @override
  String get detail_format => 'Format';

  @override
  String get detail_status => 'Status';

  @override
  String get detail_upload => 'Unggah';

  @override
  String get detail_uploaded => 'Diunggah';

  @override
  String get detail_cleaning => 'Pembersihan';

  @override
  String get detail_recorded => 'Direkam';

  @override
  String get detail_retry => 'Coba lagi';

  @override
  String get detail_notFlagged => 'Tidak ditandai';

  @override
  String get detail_uploadStuck => 'Macet — ketuk Coba lagi';

  @override
  String get detail_uploading => 'Mengunggah...';

  @override
  String get detail_maxRetries => 'Maks percobaan — ketuk Coba lagi';

  @override
  String get detail_uploadFailed => 'Unggahan Gagal';

  @override
  String get detail_pendingRetried => 'Tertunda (dicoba lagi)';

  @override
  String get detail_notSynced => 'Belum disinkronkan';

  @override
  String get action_actions => 'Tindakan';

  @override
  String get action_split => 'Bagi';

  @override
  String get action_flagClean => 'Tandai Bersihkan';

  @override
  String get action_clearFlag => 'Hapus Tanda';

  @override
  String get action_move => 'Pindahkan';

  @override
  String get action_delete => 'Hapus';

  @override
  String get projectStats_recordings => 'Rekaman';

  @override
  String get projectStats_duration => 'Durasi';

  @override
  String get projectStats_members => 'Anggota';

  @override
  String get project_active => 'Aktif';

  @override
  String get recording_paused => 'Dijeda';

  @override
  String get recording_recording => 'Merekam';

  @override
  String get recording_tapToRecord => 'Ketuk untuk Merekam';

  @override
  String get recording_sensitivity => 'Sensitivitas';

  @override
  String get recording_sensitivityLow => 'Rendah';

  @override
  String get recording_sensitivityMed => 'Sedang';

  @override
  String get recording_sensitivityHigh => 'Tinggi';

  @override
  String get recording_stopRecording => 'Hentikan perekaman';

  @override
  String get recording_stop => 'Berhenti';

  @override
  String get recording_resume => 'Lanjutkan';

  @override
  String get recording_pause => 'Jeda';

  @override
  String get quickRecord_title => 'Rekam Cepat';

  @override
  String get quickRecord_subtitle => 'Klasifikasi nanti';

  @override
  String get quickRecord_classifyLater => 'Klasifikasi nanti';

  @override
  String get classify_title => 'Klasifikasi Rekaman';

  @override
  String get classify_action => 'Klasifikasi';

  @override
  String get classify_banner =>
      'Rekaman ini perlu diklasifikasi sebelum dapat diunggah.';

  @override
  String get classify_success => 'Rekaman diklasifikasi';

  @override
  String get classify_register => 'Register (opsional)';

  @override
  String get classify_selectRegister => 'Pilih register';

  @override
  String get recording_unclassified => 'Belum diklasifikasi';

  @override
  String get fab_quickRecord => 'Cepat';

  @override
  String get fab_normalRecord => 'Rekam';

  @override
  String get error_network =>
      'Tidak dapat menghubungi server. Periksa koneksi internet Anda dan coba lagi.';

  @override
  String get error_secureConnection =>
      'Koneksi aman tidak dapat dibuat. Silakan coba lagi nanti.';

  @override
  String get error_timeout =>
      'Permintaan telah habis waktu. Periksa koneksi Anda dan coba lagi.';

  @override
  String get error_invalidCredentials =>
      'Email atau kata sandi salah. Silakan coba lagi.';

  @override
  String get error_userNotFound =>
      'Tidak ditemukan akun dengan alamat email tersebut.';

  @override
  String get error_accountExists => 'Akun dengan email ini sudah ada.';

  @override
  String get error_emailRequired => 'Silakan masukkan alamat email Anda.';

  @override
  String get error_passwordRequired => 'Silakan masukkan kata sandi Anda.';

  @override
  String get error_signupFailed =>
      'Tidak dapat membuat akun Anda. Periksa detail Anda dan coba lagi.';

  @override
  String get error_sessionExpired =>
      'Sesi Anda telah berakhir. Silakan masuk kembali.';

  @override
  String get error_profileLoadFailed =>
      'Tidak dapat memuat profil Anda. Silakan coba lagi.';

  @override
  String get error_profileUpdateFailed =>
      'Tidak dapat memperbarui profil Anda. Silakan coba lagi.';

  @override
  String get error_imageUploadFailed =>
      'Tidak dapat mengunggah gambar. Silakan coba lagi.';

  @override
  String get error_notAuthenticated =>
      'Anda belum masuk. Silakan masuk dan coba lagi.';

  @override
  String get error_noPermission =>
      'Anda tidak memiliki izin untuk melakukan tindakan ini.';

  @override
  String get error_generic => 'Terjadi kesalahan. Silakan coba lagi nanti.';
}
