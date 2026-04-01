// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Oral Collector';

  @override
  String get nav_home => 'Inicio';

  @override
  String get nav_record => 'Grabar';

  @override
  String get nav_recordings => 'Grabaciones';

  @override
  String get nav_projects => 'Proyectos';

  @override
  String get nav_profile => 'Perfil';

  @override
  String get nav_admin => 'Admin';

  @override
  String get nav_collapse => 'Contraer';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_save => 'Guardar';

  @override
  String get common_delete => 'Eliminar';

  @override
  String get common_remove => 'Quitar';

  @override
  String get common_create => 'Crear';

  @override
  String get common_continue => 'Continuar';

  @override
  String get common_next => 'Siguiente';

  @override
  String get common_retry => 'Reintentar';

  @override
  String get common_move => 'Mover';

  @override
  String get common_invite => 'Invitar';

  @override
  String get common_download => 'Descargar';

  @override
  String get common_clear => 'Limpiar';

  @override
  String get common_untitled => 'Sin título';

  @override
  String get common_loading => 'Cargando...';

  @override
  String get auth_oralCollector => 'Oral Collector';

  @override
  String get auth_byShema => 'por Shema';

  @override
  String get auth_heroTagline => 'Preserva voces.\nComparte historias.';

  @override
  String get auth_welcomeBack => 'Bienvenido\nde Nuevo';

  @override
  String get auth_welcome => 'Bienvenido ';

  @override
  String get auth_back => 'Volver';

  @override
  String get auth_createWord => 'Crear ';

  @override
  String get auth_createNewline => 'Crear\n';

  @override
  String get auth_account => 'Cuenta';

  @override
  String get auth_signInSubtitle =>
      'Inicia sesión para seguir recopilando historias.';

  @override
  String get auth_signUpSubtitle =>
      'Únete a nuestra comunidad de recopiladores de historias.';

  @override
  String get auth_backToSignIn => 'Volver a iniciar sesión';

  @override
  String get auth_emailLabel => 'Correo Electrónico';

  @override
  String get auth_emailHint => 'tu@correo.com';

  @override
  String get auth_emailRequired => 'Por favor, ingresa tu correo electrónico';

  @override
  String get auth_emailInvalid =>
      'Por favor, ingresa un correo electrónico válido';

  @override
  String get auth_passwordLabel => 'Contraseña';

  @override
  String get auth_passwordHint => 'Al menos 6 caracteres';

  @override
  String get auth_passwordRequired => 'Por favor, ingresa tu contraseña';

  @override
  String get auth_passwordTooShort =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get auth_confirmPasswordLabel => 'Confirmar Contraseña';

  @override
  String get auth_confirmPasswordHint => 'Vuelve a escribir la contraseña';

  @override
  String get auth_confirmPasswordRequired =>
      'Por favor, confirma tu contraseña';

  @override
  String get auth_confirmPasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get auth_nameLabel => 'Nombre';

  @override
  String get auth_nameHint => 'Tu nombre completo';

  @override
  String get auth_nameRequired => 'Por favor, ingresa tu nombre para mostrar';

  @override
  String get auth_signIn => 'Iniciar Sesión';

  @override
  String get auth_signUp => 'Registrarse';

  @override
  String get auth_noAccount => '¿No tienes una cuenta? ';

  @override
  String get auth_haveAccount => '¿Ya tienes una cuenta? ';

  @override
  String get auth_continueButton => 'Continuar';

  @override
  String get home_greetingMorning => 'Buenos días';

  @override
  String get home_greetingAfternoon => 'Buenas tardes';

  @override
  String get home_greetingEvening => 'Buenas noches';

  @override
  String home_greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get home_subtitle => 'Compartamos tus historias hoy';

  @override
  String get home_switchProject => 'Cambiar proyecto';

  @override
  String get home_genres => 'Géneros';

  @override
  String get home_loadingProjects => 'Cargando proyectos...';

  @override
  String get home_loadingGenres => 'Cargando géneros...';

  @override
  String get home_noGenres => 'Aún no hay géneros disponibles';

  @override
  String get home_noProjectTitle => 'Selecciona un proyecto para comenzar';

  @override
  String get home_browseProjects => 'Explorar Proyectos';

  @override
  String get stats_recordings => 'grabaciones';

  @override
  String get stats_recorded => 'grabado';

  @override
  String get stats_members => 'miembros';

  @override
  String get project_switchTitle => 'Cambiar Proyecto';

  @override
  String get project_projects => 'Proyectos';

  @override
  String get project_subtitle => 'Gestiona tus colecciones';

  @override
  String get project_noProjectsTitle => 'Aún no hay proyectos';

  @override
  String get project_noProjectsSubtitle =>
      'Crea tu primer proyecto para empezar a recopilar historias orales.';

  @override
  String get project_newProject => 'Nuevo Proyecto';

  @override
  String get project_projectName => 'Nombre del Proyecto';

  @override
  String get project_projectNameHint => 'ej. Traducción Bíblica Kosrae';

  @override
  String get project_projectNameRequired =>
      'El nombre del proyecto es obligatorio';

  @override
  String get project_description => 'Descripción';

  @override
  String get project_descriptionHint => 'Opcional';

  @override
  String get project_language => 'Idioma';

  @override
  String get project_selectLanguage => 'Selecciona un idioma';

  @override
  String get project_pleaseSelectLanguage => 'Por favor, selecciona un idioma';

  @override
  String get project_createProject => 'Crear Proyecto';

  @override
  String get project_selectLanguageTitle => 'Seleccionar Idioma';

  @override
  String get project_addLanguageTitle => 'Agregar Idioma';

  @override
  String get project_addLanguageSubtitle =>
      '¿No encuentras tu idioma? Agrégalo aquí.';

  @override
  String get project_languageName => 'Nombre del Idioma';

  @override
  String get project_languageNameHint => 'ej. Kosraeano';

  @override
  String get project_languageNameRequired => 'El nombre es obligatorio';

  @override
  String get project_languageCode => 'Código del Idioma';

  @override
  String get project_languageCodeHint => 'ej. kos (ISO 639-3)';

  @override
  String get project_languageCodeRequired => 'El código es obligatorio';

  @override
  String get project_languageCodeTooLong =>
      'El código debe tener de 1 a 3 caracteres';

  @override
  String get project_addLanguage => 'Agregar Idioma';

  @override
  String get project_noLanguagesFound => 'No se encontraron idiomas';

  @override
  String get project_addNewLanguage => 'Agregar nuevo idioma';

  @override
  String project_addAsNewLanguage(String query) {
    return 'Agregar \"$query\" como nuevo idioma';
  }

  @override
  String get project_searchLanguages => 'Buscar idiomas...';

  @override
  String get project_backToList => 'Volver a la lista';

  @override
  String get projectSettings_title => 'Configuración del Proyecto';

  @override
  String get projectSettings_details => 'Detalles';

  @override
  String get projectSettings_saving => 'Guardando...';

  @override
  String get projectSettings_saveChanges => 'Guardar Cambios';

  @override
  String get projectSettings_updated => 'Proyecto actualizado';

  @override
  String get projectSettings_noPermission =>
      'No tienes permiso para actualizar este proyecto';

  @override
  String get projectSettings_team => 'Equipo';

  @override
  String get projectSettings_removeMember => 'Quitar Miembro';

  @override
  String projectSettings_removeMemberConfirm(String name) {
    return '¿Quitar a $name de este proyecto?';
  }

  @override
  String get projectSettings_memberRemoved => 'Miembro eliminado';

  @override
  String get projectSettings_memberRemoveFailed => 'Error al eliminar miembro';

  @override
  String get projectSettings_inviteSent => 'Invitación enviada con éxito';

  @override
  String get projectSettings_noMembers => 'Aún no hay miembros';

  @override
  String get recording_selectGenre => 'Seleccionar Género';

  @override
  String get recording_selectGenreSubtitle =>
      'Elige un género para tu historia';

  @override
  String get recording_selectSubcategory => 'Seleccionar Subcategoría';

  @override
  String get recording_selectSubcategorySubtitle => 'Elige una subcategoría';

  @override
  String get recording_selectRegister => 'Seleccionar Registro';

  @override
  String get recording_selectRegisterSubtitle => 'Elige el registro de habla';

  @override
  String get recording_recordingStep => 'Grabación';

  @override
  String get recording_recordingStepSubtitle => 'Captura tu historia';

  @override
  String get recording_reviewStep => 'Revisar Grabación';

  @override
  String get recording_reviewStepSubtitle => 'Escucha y guarda';

  @override
  String get recording_genreNotFound => 'Género no encontrado';

  @override
  String get recording_noGenres => 'No hay géneros disponibles';

  @override
  String get recording_noSubcategories => 'No hay subcategorías disponibles';

  @override
  String get recording_registerDescription =>
      'Elige el registro de habla que mejor describa el tono y la formalidad de esta grabación.';

  @override
  String get recording_titleHint => 'Agregar un título (opcional)';

  @override
  String get recording_saveRecording => 'Guardar Grabación';

  @override
  String get recording_recordAgain => 'Grabar de Nuevo';

  @override
  String get recording_discard => 'Descartar';

  @override
  String get recording_discardTitle => '¿Descartar Grabación?';

  @override
  String get recording_discardMessage =>
      'Esta grabación será eliminada permanentemente.';

  @override
  String get recording_saved => 'Grabación guardada';

  @override
  String get recording_notFound => 'Grabación no encontrada';

  @override
  String get recording_unknownGenre => 'Género desconocido';

  @override
  String get recording_splitRecording => 'Dividir Grabación';

  @override
  String get recording_moveCategory => 'Mover Categoría';

  @override
  String get recording_downloadAudio => 'Descargar Audio';

  @override
  String get recording_downloadAudioMessage =>
      'El archivo de audio no está almacenado en este dispositivo. ¿Deseas descargarlo para recortar?';

  @override
  String recording_downloadFailed(String error) {
    return 'Error al descargar: $error';
  }

  @override
  String get recording_audioNotAvailable => 'Archivo de audio no disponible';

  @override
  String get recording_deleteTitle => 'Eliminar Grabación';

  @override
  String get recording_deleteMessage =>
      'Esto eliminará permanentemente esta grabación de tu dispositivo. Si ya fue subida, también se eliminará del servidor. Esta acción no se puede deshacer.';

  @override
  String get recording_deleteNoPermission =>
      'No tienes permiso para eliminar esta grabación';

  @override
  String get recording_deleteFailed => 'Error al eliminar grabación';

  @override
  String get recording_deleteFailedLocal =>
      'Error al eliminar del servidor. Eliminando localmente.';

  @override
  String get recording_cleaningStatusFailed =>
      'Error al actualizar el estado de limpieza en el servidor';

  @override
  String get recording_updateNoPermission =>
      'No tienes permiso para actualizar esta grabación';

  @override
  String get recording_moveNoPermission =>
      'No tienes permiso para mover esta grabación';

  @override
  String get recording_movedSuccess => 'Grabación movida con éxito';

  @override
  String get recording_updateFailed => 'Error al actualizar en el servidor';

  @override
  String get recordings_title => 'Grabaciones';

  @override
  String get recordings_subtitle => 'Tus historias recopiladas';

  @override
  String get recordings_importAudio => 'Importar archivo de audio';

  @override
  String get recordings_selectProject => 'Selecciona un proyecto';

  @override
  String get recordings_selectProjectSubtitle =>
      'Elige un proyecto para ver sus grabaciones';

  @override
  String get recordings_noRecordings => 'Aún no hay grabaciones';

  @override
  String get recordings_noRecordingsSubtitle =>
      'Toca el micrófono para grabar tu primera historia, o importa un archivo de audio.';

  @override
  String recordings_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grabaciones',
      one: '1 grabación',
    );
    return '$_temp0';
  }

  @override
  String get recording_statusUploaded => 'Subido';

  @override
  String get recording_statusUploading => 'Subiendo';

  @override
  String get recording_statusFailed => 'Fallido';

  @override
  String get recording_statusLocal => 'Local';

  @override
  String get recordings_clearStale => 'Limpiar fallidos';

  @override
  String get recordings_clearStaleMessage =>
      'Esto eliminará permanentemente todas las grabaciones con estado de subida fallido o atascado del servidor. Esta acción no se puede deshacer.';

  @override
  String recordings_clearedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se limpiaron $count grabaciones',
      one: 'Se limpió 1 grabación',
      zero: 'No se encontraron grabaciones obsoletas',
    );
    return '$_temp0';
  }

  @override
  String get recordings_clearFailed => 'Error al limpiar grabaciones';

  @override
  String get trim_title => 'Dividir Grabación';

  @override
  String get trim_notFound => 'Grabación no encontrada';

  @override
  String get trim_audioUrlNotAvailable =>
      'URL de audio no disponible para esta grabación.';

  @override
  String get trim_localNotAvailable =>
      'Archivo de audio local no disponible. Descarga la grabación primero.';

  @override
  String get trim_atLeastOneSegment => 'Se debe conservar al menos un segmento';

  @override
  String get trim_segments => 'Segmentos';

  @override
  String get trim_restoreAll => 'Restaurar todos';

  @override
  String get trim_instructions =>
      'Toca en la forma de onda de arriba para colocar\nmarcadores de división y dividir esta grabación';

  @override
  String get trim_splitting => 'Dividiendo...';

  @override
  String trim_saveSegments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Guardar $count segmentos',
      one: 'Guardar 1 segmento',
    );
    return '$_temp0';
  }

  @override
  String get trim_addSplitsFirst => 'Agrega divisiones primero';

  @override
  String trim_savedSegments(int kept, int removed) {
    String _temp0 = intl.Intl.pluralLogic(
      kept,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'Se guardaron $kept segmento$_temp0, se eliminaron $removed';
  }

  @override
  String trim_splitInto(int count) {
    return 'Dividir en $count grabaciones';
  }

  @override
  String get import_title => 'Importar Audio';

  @override
  String get import_selectGenre => 'Seleccionar Género';

  @override
  String get import_selectSubcategory => 'Seleccionar Subcategoría';

  @override
  String get import_selectRegister => 'Seleccionar Registro';

  @override
  String get import_confirmImport => 'Confirmar Importación';

  @override
  String get import_analyzing => 'Analizando archivo de audio...';

  @override
  String get import_selectFile =>
      'Selecciona un archivo de audio para importar';

  @override
  String get import_chooseFile => 'Elegir Archivo';

  @override
  String get import_accessFailed =>
      'No se pudo acceder al archivo seleccionado';

  @override
  String import_pickError(String error) {
    return 'Error al seleccionar archivo: $error';
  }

  @override
  String import_saveError(String error) {
    return 'Error al guardar archivo: $error';
  }

  @override
  String get import_unknownFile => 'Archivo desconocido';

  @override
  String get import_importAndSave => 'Importar y Guardar';

  @override
  String get moveCategory_title => 'Mover Categoría';

  @override
  String get moveCategory_genre => 'Género';

  @override
  String get moveCategory_subcategory => 'Subcategoría';

  @override
  String get moveCategory_selectSubcategory => 'Seleccionar subcategoría';

  @override
  String get cleaning_needsCleaning => 'Necesita Limpieza';

  @override
  String get cleaning_cleaning => 'Limpiando...';

  @override
  String get cleaning_cleaned => 'Limpio';

  @override
  String get cleaning_cleanFailed => 'Falló la Limpieza';

  @override
  String get sync_uploading => 'Subiendo...';

  @override
  String sync_pending(int count) {
    return '$count pendiente(s)';
  }

  @override
  String get profile_photoUpdated => 'Foto de perfil actualizada';

  @override
  String profile_photoFailed(String error) {
    return 'Error al actualizar foto: $error';
  }

  @override
  String get profile_editName => 'Editar nombre para mostrar';

  @override
  String get profile_nameHint => 'Tu nombre';

  @override
  String get profile_nameUpdated => 'Nombre actualizado';

  @override
  String get profile_syncStorage => 'Sincronización y Almacenamiento';

  @override
  String get profile_about => 'Acerca de';

  @override
  String get profile_appVersion => 'Versión de la app';

  @override
  String get profile_byShema => 'Oral Collector por Shema';

  @override
  String get profile_administration => 'Administración';

  @override
  String get profile_adminDashboard => 'Panel de Admin';

  @override
  String get profile_adminSubtitle =>
      'Estadísticas del sistema, proyectos y gestión de géneros';

  @override
  String get profile_account => 'Cuenta';

  @override
  String get profile_logOut => 'Cerrar Sesión';

  @override
  String get profile_deleteAccount => 'Eliminar Cuenta';

  @override
  String get profile_deleteAccountConfirm => 'Confirmar Eliminación';

  @override
  String get profile_deleteAccountWarning =>
      'Esta acción es permanente y no se puede deshacer. Tu cuenta será eliminada, pero tus grabaciones subidas se conservarán para los proyectos de idiomas.';

  @override
  String get profile_typeDelete =>
      'Escribe DELETE para confirmar la eliminación de la cuenta:';

  @override
  String get profile_clearCacheTitle => '¿Limpiar caché local?';

  @override
  String get profile_clearCacheMessage =>
      'Esto eliminará todas las grabaciones almacenadas localmente. Las grabaciones subidas al servidor no se verán afectadas.';

  @override
  String get profile_cacheCleared => 'Caché local limpiado';

  @override
  String profile_joinedSuccess(String name) {
    return 'Te uniste a \"$name\" con éxito';
  }

  @override
  String get profile_inviteDeclined => 'Invitación rechazada';

  @override
  String get profile_language => 'Idioma';

  @override
  String get profile_online => 'En línea';

  @override
  String get profile_offline => 'Sin conexión';

  @override
  String profile_lastSync(String time) {
    return 'Última sincronización: $time';
  }

  @override
  String get profile_neverSynced => 'Nunca sincronizado';

  @override
  String profile_pendingCount(int count) {
    return '$count pendiente(s)';
  }

  @override
  String profile_syncingProgress(int percent) {
    return 'Sincronizando... $percent%';
  }

  @override
  String get profile_syncNow => 'Sincronizar Ahora';

  @override
  String get profile_wifiOnly => 'Subir solo por Wi-Fi';

  @override
  String get profile_wifiOnlySubtitle => 'Evitar subidas por datos móviles';

  @override
  String get profile_autoRemove => 'Eliminar automáticamente después de subir';

  @override
  String get profile_autoRemoveSubtitle =>
      'Eliminar archivos locales después de subida exitosa';

  @override
  String get profile_clearCache => 'Limpiar caché local';

  @override
  String get profile_clearCacheSubtitle =>
      'Eliminar todas las grabaciones almacenadas localmente';

  @override
  String get profile_invitations => 'Invitaciones';

  @override
  String get profile_refreshInvitations => 'Actualizar invitaciones';

  @override
  String get profile_noInvitations => 'No hay invitaciones pendientes';

  @override
  String get profile_roleManager => 'Rol: Gerente';

  @override
  String get profile_roleMember => 'Rol: Miembro';

  @override
  String get profile_decline => 'Rechazar';

  @override
  String get profile_accept => 'Aceptar';

  @override
  String get profile_storage => 'Almacenamiento';

  @override
  String get profile_status => 'Estado';

  @override
  String get profile_pendingLabel => 'Pendiente';

  @override
  String get admin_title => 'Panel de Admin';

  @override
  String get admin_overview => 'Resumen';

  @override
  String get admin_projects => 'Proyectos';

  @override
  String get admin_genres => 'Géneros';

  @override
  String get admin_cleaning => 'Limpieza';

  @override
  String get admin_accessRequired => 'Se requiere acceso de administrador';

  @override
  String get admin_totalProjects => 'Total de Proyectos';

  @override
  String get admin_languages => 'Idiomas';

  @override
  String get admin_recordings => 'Grabaciones';

  @override
  String get admin_totalHours => 'Total de Horas';

  @override
  String get admin_activeUsers => 'Usuarios Activos';

  @override
  String get admin_projectName => 'Nombre';

  @override
  String get admin_projectLanguage => 'Idioma';

  @override
  String get admin_projectMembers => 'Miembros';

  @override
  String get admin_projectRecordings => 'Grabaciones';

  @override
  String get admin_projectDuration => 'Duración';

  @override
  String get admin_projectCreated => 'Creado';

  @override
  String get admin_noProjects => 'No se encontraron proyectos';

  @override
  String get admin_unknownLanguage => 'Idioma desconocido';

  @override
  String get admin_genresAndSubcategories => 'Géneros y Subcategorías';

  @override
  String get admin_addGenre => 'Agregar Género';

  @override
  String get admin_noGenres => 'No se encontraron géneros';

  @override
  String get admin_genreName => 'Nombre del Género';

  @override
  String get admin_required => 'Obligatorio';

  @override
  String get admin_descriptionOptional => 'Descripción (opcional)';

  @override
  String get admin_genreCreated => 'Género creado';

  @override
  String get admin_editGenre => 'Editar género';

  @override
  String get admin_deleteGenre => 'Eliminar género';

  @override
  String get admin_addSubcategory => 'Agregar subcategoría';

  @override
  String get admin_editGenreTitle => 'Editar Género';

  @override
  String get admin_genreUpdated => 'Género actualizado';

  @override
  String get admin_deleteGenreTitle => 'Eliminar Género';

  @override
  String admin_deleteGenreConfirm(String name) {
    return '¿Eliminar \"$name\" y todas sus subcategorías?';
  }

  @override
  String get admin_genreDeleted => 'Género eliminado';

  @override
  String admin_addSubcategoryTo(String name) {
    return 'Agregar Subcategoría a $name';
  }

  @override
  String get admin_subcategoryName => 'Nombre de la Subcategoría';

  @override
  String get admin_subcategoryCreated => 'Subcategoría creada';

  @override
  String get admin_deleteSubcategory => 'Eliminar Subcategoría';

  @override
  String admin_deleteSubcategoryConfirm(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String get admin_subcategoryDeleted => 'Subcategoría eliminada';

  @override
  String get admin_cleaningQueue => 'Cola de Limpieza de Audio';

  @override
  String admin_cleanSelected(int count) {
    return 'Limpiar Seleccionados ($count)';
  }

  @override
  String get admin_refreshCleaning => 'Actualizar cola de limpieza';

  @override
  String get admin_cleaningWebOnly =>
      'La limpieza de audio es una función exclusiva de la web. Los procesos de limpieza se ejecutan en el servidor.';

  @override
  String get admin_noCleaningRecordings =>
      'No hay grabaciones marcadas para limpieza';

  @override
  String get admin_cleaningTitle => 'Título';

  @override
  String get admin_cleaningDuration => 'Duración';

  @override
  String get admin_cleaningSize => 'Tamaño';

  @override
  String get admin_cleaningFormat => 'Formato';

  @override
  String get admin_cleaningRecorded => 'Grabado';

  @override
  String get admin_cleaningActions => 'Acciones';

  @override
  String get admin_clean => 'Limpiar';

  @override
  String get admin_deselectAll => 'Deseleccionar Todos';

  @override
  String get admin_selectAll => 'Seleccionar Todos';

  @override
  String get admin_cleaningTriggered => 'Limpieza iniciada';

  @override
  String get admin_cleaningFailed => 'Error al iniciar limpieza';

  @override
  String admin_cleaningPartial(int success, int total) {
    return 'Limpieza iniciada para $success de $total grabaciones';
  }

  @override
  String get genre_title => 'Género';

  @override
  String get genre_notFound => 'Género no encontrado';

  @override
  String genre_recordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grabaciones',
      one: '1 grabación',
    );
    return '$_temp0';
  }

  @override
  String get format_justNow => 'justo ahora';

  @override
  String format_minutesAgo(int count) {
    return 'hace ${count}min';
  }

  @override
  String format_hoursAgo(int count) {
    return 'hace ${count}h';
  }

  @override
  String format_daysAgo(int count) {
    return 'hace ${count}d';
  }

  @override
  String format_weeksAgo(int count) {
    return 'hace ${count}sem';
  }

  @override
  String format_monthsAgo(int count) {
    return 'hace ${count}m';
  }

  @override
  String format_memberSince(String date) {
    return 'Miembro desde $date';
  }

  @override
  String get format_member => 'Miembro';

  @override
  String format_dateAt(String date, String time) {
    return '$date a las $time';
  }

  @override
  String get genre_narrative => 'Narrativa';

  @override
  String get genre_narrativeDesc =>
      'Historias, relatos y formas narrativas de la tradición oral';

  @override
  String get genre_poeticSong => 'Poético / Canción';

  @override
  String get genre_poeticSongDesc =>
      'Tradiciones orales musicales y poéticas, incluyendo himnos, lamentos y poesía sapiencial';

  @override
  String get genre_instructional => 'Instructivo / Normativo';

  @override
  String get genre_instructionalDesc =>
      'Leyes, rituales, procedimientos y formas instructivas';

  @override
  String get genre_oralDiscourse => 'Discurso Oral';

  @override
  String get genre_oralDiscourseDesc =>
      'Discursos, enseñanzas, oraciones y formas discursivas orales';

  @override
  String get sub_historicalNarrative => 'Narrativa Histórica';

  @override
  String get sub_personalAccount => 'Relato Personal / Testimonio';

  @override
  String get sub_parable => 'Parábola / Historia Ilustrativa';

  @override
  String get sub_originStory => 'Historia de Origen / Creación';

  @override
  String get sub_legend => 'Leyenda / Historia de Héroe';

  @override
  String get sub_visionNarrative => 'Narrativa de Visión o Sueño';

  @override
  String get sub_genealogy => 'Genealogía';

  @override
  String get sub_eventReport => 'Reporte de Evento Reciente';

  @override
  String get sub_hymn => 'Himno / Canto de Adoración';

  @override
  String get sub_lament => 'Lamento';

  @override
  String get sub_funeralDirge => 'Canto Fúnebre';

  @override
  String get sub_victorySong => 'Canto de Victoria / Celebración';

  @override
  String get sub_loveSong => 'Canto de Amor';

  @override
  String get sub_tauntSong => 'Canto de Burla / Escarnio';

  @override
  String get sub_blessing => 'Bendición';

  @override
  String get sub_curse => 'Maldición';

  @override
  String get sub_wisdomPoem => 'Poema de Sabiduría / Proverbio';

  @override
  String get sub_didacticPoetry => 'Poesía Didáctica';

  @override
  String get sub_legalCode => 'Ley / Código Legal';

  @override
  String get sub_ritual => 'Ritual / Liturgia';

  @override
  String get sub_procedure => 'Procedimiento / Instrucción';

  @override
  String get sub_listInventory => 'Lista / Inventario';

  @override
  String get sub_propheticOracle => 'Oráculo Profético / Discurso';

  @override
  String get sub_exhortation => 'Exhortación / Sermón';

  @override
  String get sub_wisdomTeaching => 'Enseñanza Sapiencial';

  @override
  String get sub_prayer => 'Oración';

  @override
  String get sub_dialogue => 'Diálogo';

  @override
  String get sub_epistle => 'Epístola / Carta';

  @override
  String get sub_apocalypticDiscourse => 'Discurso Apocalíptico';

  @override
  String get sub_ceremonialSpeech => 'Discurso Ceremonial';

  @override
  String get sub_communityMemory => 'Memoria Comunitaria';

  @override
  String get sub_historicalNarrativeDesc =>
      'Relatos de acontecimientos, guerras y momentos clave de la historia';

  @override
  String get sub_personalAccountDesc =>
      'Historias personales de experiencias vividas y de fe';

  @override
  String get sub_parableDesc =>
      'Historias simbólicas que enseñan lecciones morales o espirituales';

  @override
  String get sub_originStoryDesc => 'Historias sobre cómo surgieron las cosas';

  @override
  String get sub_legendDesc =>
      'Relatos de personas notables y sus grandes hazañas';

  @override
  String get sub_visionNarrativeDesc =>
      'Relatos de visiones divinas y sueños proféticos';

  @override
  String get sub_genealogyDesc =>
      'Registros de líneas familiares y linajes ancestrales';

  @override
  String get sub_eventReportDesc =>
      'Reportes de acontecimientos recientes en la comunidad';

  @override
  String get sub_hymnDesc => 'Cantos de alabanza y adoración a Dios';

  @override
  String get sub_lamentDesc => 'Expresiones de dolor, tristeza y duelo';

  @override
  String get sub_funeralDirgeDesc =>
      'Cantos realizados durante ceremonias de duelo y sepultura';

  @override
  String get sub_victorySongDesc =>
      'Cantos que celebran triunfos y eventos alegres';

  @override
  String get sub_loveSongDesc => 'Cantos que expresan amor y devoción';

  @override
  String get sub_tauntSongDesc =>
      'Cantos de burla dirigidos a enemigos o infieles';

  @override
  String get sub_blessingDesc =>
      'Palabras que invocan favor y protección divina';

  @override
  String get sub_curseDesc =>
      'Pronunciamientos de juicio o consecuencia divina';

  @override
  String get sub_wisdomPoemDesc =>
      'Dichos y poemas que transmiten sabiduría práctica';

  @override
  String get sub_didacticPoetryDesc =>
      'Composiciones poéticas destinadas a enseñar e instruir';

  @override
  String get sub_legalCodeDesc => 'Reglas, estatutos y regulaciones de alianza';

  @override
  String get sub_ritualDesc =>
      'Formas prescritas de adoración y ceremonias sagradas';

  @override
  String get sub_procedureDesc =>
      'Orientaciones prácticas y direcciones paso a paso';

  @override
  String get sub_listInventoryDesc =>
      'Catálogos, censos y registros organizados';

  @override
  String get sub_propheticOracleDesc => 'Mensajes entregados en nombre de Dios';

  @override
  String get sub_exhortationDesc =>
      'Discursos que exhortan a la acción moral y espiritual';

  @override
  String get sub_wisdomTeachingDesc =>
      'Instrucción sobre vivir con sabiduría y rectitud';

  @override
  String get sub_prayerDesc =>
      'Palabras dirigidas a Dios en adoración o petición';

  @override
  String get sub_dialogueDesc => 'Conversaciones e intercambios entre personas';

  @override
  String get sub_epistleDesc =>
      'Mensajes escritos dirigidos a comunidades o individuos';

  @override
  String get sub_apocalypticDiscourseDesc =>
      'Revelaciones sobre los últimos tiempos y el plan de Dios';

  @override
  String get sub_ceremonialSpeechDesc =>
      'Discursos formales para ocasiones oficiales o sagradas';

  @override
  String get sub_communityMemoryDesc =>
      'Recuerdos compartidos que preservan la identidad del grupo';

  @override
  String get register_intimate => 'Íntimo';

  @override
  String get register_casual => 'Informal / Casual';

  @override
  String get register_consultative => 'Consultivo';

  @override
  String get register_formal => 'Formal / Oficial';

  @override
  String get register_ceremonial => 'Ceremonial';

  @override
  String get register_elderAuthority => 'Anciano / Autoridad';

  @override
  String get register_religiousWorship => 'Religioso / Culto';

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
  String get locale_englishSub => 'Inglés';

  @override
  String get locale_portugueseSub => 'Portugués';

  @override
  String get locale_hindiSub => 'Hindi';

  @override
  String get locale_koreanSub => 'Coreano';

  @override
  String get locale_spanishSub => 'Español';

  @override
  String get locale_bahasaSub => 'Indonesio';

  @override
  String get locale_frenchSub => 'Francés';

  @override
  String get locale_tokPisinSub => 'Tok Pisin';

  @override
  String get locale_swahiliSub => 'Suajili';

  @override
  String get locale_arabicSub => 'Árabe';

  @override
  String get locale_chinese => '中文';

  @override
  String get locale_chineseSub => 'Chino';

  @override
  String get locale_selectLanguage => 'Elige Tu Idioma';

  @override
  String get locale_selectLanguageSubtitle =>
      'Puedes cambiar esto más tarde en la configuración de tu perfil.';

  @override
  String get filter_all => 'Todos';

  @override
  String get filter_pending => 'Pendientes';

  @override
  String get filter_uploaded => 'Subidos';

  @override
  String get filter_needsCleaning => 'Necesita Limpieza';

  @override
  String get filter_unclassified => 'Sin clasificar';

  @override
  String get filter_allGenres => 'Todos los géneros';

  @override
  String get detail_duration => 'Duración';

  @override
  String get detail_size => 'Tamaño';

  @override
  String get detail_format => 'Formato';

  @override
  String get detail_status => 'Estado';

  @override
  String get detail_upload => 'Subida';

  @override
  String get detail_uploaded => 'Subido';

  @override
  String get detail_cleaning => 'Limpieza';

  @override
  String get detail_recorded => 'Grabado';

  @override
  String get detail_retry => 'Reintentar';

  @override
  String get detail_notFlagged => 'No marcado';

  @override
  String get detail_uploadStuck => 'Atascado — toca Reintentar';

  @override
  String get detail_uploading => 'Subiendo...';

  @override
  String get detail_maxRetries => 'Máx. de reintentos — toca Reintentar';

  @override
  String get detail_uploadFailed => 'Subida Fallida';

  @override
  String get detail_pendingRetried => 'Pendiente (reintentado)';

  @override
  String get detail_notSynced => 'No sincronizado';

  @override
  String get action_actions => 'Acciones';

  @override
  String get action_split => 'Dividir';

  @override
  String get action_flagClean => 'Marcar Limpieza';

  @override
  String get action_clearFlag => 'Quitar Marca';

  @override
  String get action_move => 'Mover';

  @override
  String get action_delete => 'Eliminar';

  @override
  String get projectStats_recordings => 'Grabaciones';

  @override
  String get projectStats_duration => 'Duración';

  @override
  String get projectStats_members => 'Miembros';

  @override
  String get project_active => 'Activo';

  @override
  String get recording_paused => 'Pausado';

  @override
  String get recording_recording => 'Grabando';

  @override
  String get recording_tapToRecord => 'Toca para Grabar';

  @override
  String get recording_sensitivity => 'Sensibilidad';

  @override
  String get recording_sensitivityLow => 'Baja';

  @override
  String get recording_sensitivityMed => 'Media';

  @override
  String get recording_sensitivityHigh => 'Alta';

  @override
  String get recording_stopRecording => 'Detener grabación';

  @override
  String get recording_stop => 'Detener';

  @override
  String get recording_resume => 'Reanudar';

  @override
  String get recording_pause => 'Pausar';

  @override
  String get quickRecord_title => 'Grabación Rápida';

  @override
  String get quickRecord_subtitle => 'Clasificar después';

  @override
  String get quickRecord_classifyLater => 'Clasificar después';

  @override
  String get classify_title => 'Clasificar Grabación';

  @override
  String get classify_action => 'Clasificar';

  @override
  String get classify_banner =>
      'Esta grabación necesita ser clasificada antes de poder subirla.';

  @override
  String get classify_success => 'Grabación clasificada';

  @override
  String get classify_register => 'Registro (opcional)';

  @override
  String get classify_selectRegister => 'Seleccionar registro';

  @override
  String get recording_unclassified => 'Sin clasificar';

  @override
  String get fab_quickRecord => 'Rápido';

  @override
  String get fab_normalRecord => 'Grabar';
}
