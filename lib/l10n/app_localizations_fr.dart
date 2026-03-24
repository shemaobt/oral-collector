// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Oral Collector';

  @override
  String get nav_home => 'Accueil';

  @override
  String get nav_record => 'Enregistrer';

  @override
  String get nav_recordings => 'Enregistrements';

  @override
  String get nav_projects => 'Projets';

  @override
  String get nav_profile => 'Profil';

  @override
  String get nav_admin => 'Admin';

  @override
  String get nav_collapse => 'Réduire';

  @override
  String get common_cancel => 'Annuler';

  @override
  String get common_save => 'Enregistrer';

  @override
  String get common_delete => 'Supprimer';

  @override
  String get common_remove => 'Retirer';

  @override
  String get common_create => 'Créer';

  @override
  String get common_continue => 'Continuer';

  @override
  String get common_next => 'Suivant';

  @override
  String get common_retry => 'Réessayer';

  @override
  String get common_move => 'Déplacer';

  @override
  String get common_invite => 'Inviter';

  @override
  String get common_download => 'Télécharger';

  @override
  String get common_clear => 'Effacer';

  @override
  String get common_untitled => 'Sans titre';

  @override
  String get common_loading => 'Chargement...';

  @override
  String get auth_oralCollector => 'Oral Collector';

  @override
  String get auth_byShema => 'par Shema';

  @override
  String get auth_heroTagline => 'Préservez les voix.\nPartagez les histoires.';

  @override
  String get auth_welcomeBack => 'Content de\nvous revoir';

  @override
  String get auth_welcome => 'Bienvenue ';

  @override
  String get auth_back => 'Retour';

  @override
  String get auth_createWord => 'Créer ';

  @override
  String get auth_createNewline => 'Créer\n';

  @override
  String get auth_account => 'Compte';

  @override
  String get auth_signInSubtitle =>
      'Connectez-vous pour continuer à collecter des histoires.';

  @override
  String get auth_signUpSubtitle =>
      'Rejoignez notre communauté de collecteurs d\'histoires.';

  @override
  String get auth_backToSignIn => 'Retour à la connexion';

  @override
  String get auth_emailLabel => 'Adresse E-mail';

  @override
  String get auth_emailHint => 'votre@email.com';

  @override
  String get auth_emailRequired => 'Veuillez entrer votre e-mail';

  @override
  String get auth_emailInvalid => 'Veuillez entrer un e-mail valide';

  @override
  String get auth_passwordLabel => 'Mot de passe';

  @override
  String get auth_passwordHint => 'Au moins 6 caractères';

  @override
  String get auth_passwordRequired => 'Veuillez entrer votre mot de passe';

  @override
  String get auth_passwordTooShort =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get auth_confirmPasswordLabel => 'Confirmer le Mot de Passe';

  @override
  String get auth_confirmPasswordHint => 'Retapez le mot de passe';

  @override
  String get auth_confirmPasswordRequired =>
      'Veuillez confirmer votre mot de passe';

  @override
  String get auth_confirmPasswordMismatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get auth_nameLabel => 'Nom';

  @override
  String get auth_nameHint => 'Votre nom complet';

  @override
  String get auth_nameRequired => 'Veuillez entrer votre nom d\'affichage';

  @override
  String get auth_signIn => 'Se Connecter';

  @override
  String get auth_signUp => 'S\'inscrire';

  @override
  String get auth_noAccount => 'Vous n\'avez pas de compte ? ';

  @override
  String get auth_haveAccount => 'Vous avez déjà un compte ? ';

  @override
  String get auth_continueButton => 'Continuer';

  @override
  String get home_greetingMorning => 'Bonjour';

  @override
  String get home_greetingAfternoon => 'Bon après-midi';

  @override
  String get home_greetingEvening => 'Bonsoir';

  @override
  String home_greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get home_subtitle => 'Partageons vos histoires aujourd\'hui';

  @override
  String get home_switchProject => 'Changer de projet';

  @override
  String get home_genres => 'Genres';

  @override
  String get home_loadingProjects => 'Chargement des projets...';

  @override
  String get home_loadingGenres => 'Chargement des genres...';

  @override
  String get home_noGenres => 'Aucun genre disponible pour le moment';

  @override
  String get home_noProjectTitle => 'Sélectionnez un projet pour commencer';

  @override
  String get home_browseProjects => 'Parcourir les Projets';

  @override
  String get stats_recordings => 'enregistrements';

  @override
  String get stats_recorded => 'enregistré';

  @override
  String get stats_members => 'membres';

  @override
  String get project_switchTitle => 'Changer de Projet';

  @override
  String get project_projects => 'Projets';

  @override
  String get project_subtitle => 'Gérez vos collections';

  @override
  String get project_noProjectsTitle => 'Aucun projet pour le moment';

  @override
  String get project_noProjectsSubtitle =>
      'Créez votre premier projet pour commencer à collecter des histoires orales.';

  @override
  String get project_newProject => 'Nouveau Projet';

  @override
  String get project_projectName => 'Nom du Projet';

  @override
  String get project_projectNameHint => 'ex. Traduction Biblique Kosrae';

  @override
  String get project_projectNameRequired => 'Le nom du projet est requis';

  @override
  String get project_description => 'Description';

  @override
  String get project_descriptionHint => 'Facultatif';

  @override
  String get project_language => 'Langue';

  @override
  String get project_selectLanguage => 'Sélectionnez une langue';

  @override
  String get project_pleaseSelectLanguage => 'Veuillez sélectionner une langue';

  @override
  String get project_createProject => 'Créer le Projet';

  @override
  String get project_selectLanguageTitle => 'Sélectionner la Langue';

  @override
  String get project_addLanguageTitle => 'Ajouter une Langue';

  @override
  String get project_addLanguageSubtitle =>
      'Vous ne trouvez pas votre langue ? Ajoutez-la ici.';

  @override
  String get project_languageName => 'Nom de la Langue';

  @override
  String get project_languageNameHint => 'ex. Kosraéen';

  @override
  String get project_languageNameRequired => 'Le nom est requis';

  @override
  String get project_languageCode => 'Code de la Langue';

  @override
  String get project_languageCodeHint => 'ex. kos (ISO 639-3)';

  @override
  String get project_languageCodeRequired => 'Le code est requis';

  @override
  String get project_languageCodeTooLong =>
      'Le code doit contenir 1 à 3 caractères';

  @override
  String get project_addLanguage => 'Ajouter la Langue';

  @override
  String get project_noLanguagesFound => 'Aucune langue trouvée';

  @override
  String get project_addNewLanguage => 'Ajouter une nouvelle langue';

  @override
  String project_addAsNewLanguage(String query) {
    return 'Ajouter \"$query\" comme nouvelle langue';
  }

  @override
  String get project_searchLanguages => 'Rechercher des langues...';

  @override
  String get project_backToList => 'Retour à la liste';

  @override
  String get projectSettings_title => 'Paramètres du Projet';

  @override
  String get projectSettings_details => 'Détails';

  @override
  String get projectSettings_saving => 'Enregistrement...';

  @override
  String get projectSettings_saveChanges => 'Enregistrer les Modifications';

  @override
  String get projectSettings_updated => 'Projet mis à jour';

  @override
  String get projectSettings_noPermission =>
      'Vous n\'avez pas la permission de mettre à jour ce projet';

  @override
  String get projectSettings_team => 'Équipe';

  @override
  String get projectSettings_removeMember => 'Retirer le Membre';

  @override
  String projectSettings_removeMemberConfirm(String name) {
    return 'Retirer $name de ce projet ?';
  }

  @override
  String get projectSettings_memberRemoved => 'Membre retiré';

  @override
  String get projectSettings_memberRemoveFailed => 'Échec du retrait du membre';

  @override
  String get projectSettings_inviteSent => 'Invitation envoyée avec succès';

  @override
  String get projectSettings_noMembers => 'Aucun membre pour le moment';

  @override
  String get recording_selectGenre => 'Sélectionner le Genre';

  @override
  String get recording_selectGenreSubtitle =>
      'Choisissez un genre pour votre histoire';

  @override
  String get recording_selectSubcategory => 'Sélectionner la Sous-catégorie';

  @override
  String get recording_selectSubcategorySubtitle =>
      'Choisissez une sous-catégorie';

  @override
  String get recording_selectRegister => 'Sélectionner le Registre';

  @override
  String get recording_selectRegisterSubtitle =>
      'Choisissez le registre de parole';

  @override
  String get recording_recordingStep => 'Enregistrement';

  @override
  String get recording_recordingStepSubtitle => 'Capturez votre histoire';

  @override
  String get recording_reviewStep => 'Réviser l\'Enregistrement';

  @override
  String get recording_reviewStepSubtitle => 'Écoutez et sauvegardez';

  @override
  String get recording_genreNotFound => 'Genre introuvable';

  @override
  String get recording_noGenres => 'Aucun genre disponible';

  @override
  String get recording_noSubcategories => 'Aucune sous-catégorie disponible';

  @override
  String get recording_registerDescription =>
      'Choisissez le registre de parole qui décrit le mieux le ton et la formalité de cet enregistrement.';

  @override
  String get recording_titleHint => 'Ajouter un titre (facultatif)';

  @override
  String get recording_saveRecording => 'Sauvegarder l\'Enregistrement';

  @override
  String get recording_recordAgain => 'Enregistrer à Nouveau';

  @override
  String get recording_discard => 'Abandonner';

  @override
  String get recording_discardTitle => 'Abandonner l\'Enregistrement ?';

  @override
  String get recording_discardMessage =>
      'Cet enregistrement sera définitivement supprimé.';

  @override
  String get recording_saved => 'Enregistrement sauvegardé';

  @override
  String get recording_notFound => 'Enregistrement introuvable';

  @override
  String get recording_unknownGenre => 'Genre inconnu';

  @override
  String get recording_splitRecording => 'Diviser l\'Enregistrement';

  @override
  String get recording_moveCategory => 'Déplacer la Catégorie';

  @override
  String get recording_downloadAudio => 'Télécharger l\'Audio';

  @override
  String get recording_downloadAudioMessage =>
      'Le fichier audio n\'est pas stocké sur cet appareil. Voulez-vous le télécharger pour le découper ?';

  @override
  String recording_downloadFailed(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String get recording_audioNotAvailable => 'Fichier audio non disponible';

  @override
  String get recording_deleteTitle => 'Supprimer l\'Enregistrement';

  @override
  String get recording_deleteMessage =>
      'Cela supprimera définitivement cet enregistrement de votre appareil. S\'il a été téléversé, il sera également supprimé du serveur. Cette action est irréversible.';

  @override
  String get recording_deleteNoPermission =>
      'Vous n\'avez pas la permission de supprimer cet enregistrement';

  @override
  String get recording_deleteFailed =>
      'Échec de la suppression de l\'enregistrement';

  @override
  String get recording_deleteFailedLocal =>
      'Échec de la suppression du serveur. Suppression locale.';

  @override
  String get recording_cleaningStatusFailed =>
      'Échec de la mise à jour du statut de nettoyage sur le serveur';

  @override
  String get recording_updateNoPermission =>
      'Vous n\'avez pas la permission de mettre à jour cet enregistrement';

  @override
  String get recording_moveNoPermission =>
      'Vous n\'avez pas la permission de déplacer cet enregistrement';

  @override
  String get recording_movedSuccess => 'Enregistrement déplacé avec succès';

  @override
  String get recording_updateFailed => 'Échec de la mise à jour sur le serveur';

  @override
  String get recordings_title => 'Enregistrements';

  @override
  String get recordings_subtitle => 'Vos histoires collectées';

  @override
  String get recordings_importAudio => 'Importer un fichier audio';

  @override
  String get recordings_selectProject => 'Sélectionnez un projet';

  @override
  String get recordings_selectProjectSubtitle =>
      'Choisissez un projet pour voir ses enregistrements';

  @override
  String get recordings_noRecordings => 'Aucun enregistrement pour le moment';

  @override
  String get recordings_noRecordingsSubtitle =>
      'Appuyez sur le micro pour enregistrer votre première histoire, ou importez un fichier audio.';

  @override
  String recordings_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enregistrements',
      one: '1 enregistrement',
    );
    return '$_temp0';
  }

  @override
  String get recording_statusUploaded => 'Téléversé';

  @override
  String get recording_statusUploading => 'Téléversement';

  @override
  String get recording_statusFailed => 'Échoué';

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
  String get trim_title => 'Diviser l\'Enregistrement';

  @override
  String get trim_notFound => 'Enregistrement introuvable';

  @override
  String get trim_audioUrlNotAvailable =>
      'URL audio non disponible pour cet enregistrement.';

  @override
  String get trim_localNotAvailable =>
      'Fichier audio local non disponible. Téléchargez l\'enregistrement d\'abord.';

  @override
  String get trim_atLeastOneSegment => 'Au moins un segment doit être conservé';

  @override
  String get trim_segments => 'Segments';

  @override
  String get trim_restoreAll => 'Tout restaurer';

  @override
  String get trim_instructions =>
      'Appuyez sur la forme d\'onde ci-dessus pour placer\ndes marqueurs de division et diviser cet enregistrement';

  @override
  String get trim_splitting => 'Division en cours...';

  @override
  String trim_saveSegments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sauvegarder $count segments',
      one: 'Sauvegarder 1 segment',
    );
    return '$_temp0';
  }

  @override
  String get trim_addSplitsFirst => 'Ajoutez d\'abord des divisions';

  @override
  String trim_savedSegments(int kept, int removed) {
    String _temp0 = intl.Intl.pluralLogic(
      kept,
      locale: localeName,
      other: 's sauvegardés',
      one: ' sauvegardé',
    );
    return '$kept segment$_temp0, $removed supprimé(s)';
  }

  @override
  String trim_splitInto(int count) {
    return 'Diviser en $count enregistrements';
  }

  @override
  String get import_title => 'Importer l\'Audio';

  @override
  String get import_selectGenre => 'Sélectionner le Genre';

  @override
  String get import_selectSubcategory => 'Sélectionner la Sous-catégorie';

  @override
  String get import_selectRegister => 'Sélectionner le Registre';

  @override
  String get import_confirmImport => 'Confirmer l\'Importation';

  @override
  String get import_analyzing => 'Analyse du fichier audio...';

  @override
  String get import_selectFile => 'Sélectionnez un fichier audio à importer';

  @override
  String get import_chooseFile => 'Choisir un Fichier';

  @override
  String get import_accessFailed =>
      'Impossible d\'accéder au fichier sélectionné';

  @override
  String import_pickError(String error) {
    return 'Erreur de sélection du fichier : $error';
  }

  @override
  String import_saveError(String error) {
    return 'Erreur de sauvegarde du fichier : $error';
  }

  @override
  String get import_unknownFile => 'Fichier inconnu';

  @override
  String get import_importAndSave => 'Importer et Sauvegarder';

  @override
  String get moveCategory_title => 'Déplacer la Catégorie';

  @override
  String get moveCategory_genre => 'Genre';

  @override
  String get moveCategory_subcategory => 'Sous-catégorie';

  @override
  String get moveCategory_selectSubcategory => 'Sélectionner la sous-catégorie';

  @override
  String get cleaning_needsCleaning => 'Nécessite un Nettoyage';

  @override
  String get cleaning_cleaning => 'Nettoyage...';

  @override
  String get cleaning_cleaned => 'Nettoyé';

  @override
  String get cleaning_cleanFailed => 'Échec du Nettoyage';

  @override
  String get sync_uploading => 'Téléversement...';

  @override
  String sync_pending(int count) {
    return '$count en attente';
  }

  @override
  String get profile_photoUpdated => 'Photo de profil mise à jour';

  @override
  String profile_photoFailed(String error) {
    return 'Échec de la mise à jour de la photo : $error';
  }

  @override
  String get profile_editName => 'Modifier le nom d\'affichage';

  @override
  String get profile_nameHint => 'Votre nom';

  @override
  String get profile_nameUpdated => 'Nom mis à jour';

  @override
  String get profile_syncStorage => 'Synchronisation et Stockage';

  @override
  String get profile_about => 'À propos';

  @override
  String get profile_appVersion => 'Version de l\'app';

  @override
  String get profile_byShema => 'Oral Collector par Shema';

  @override
  String get profile_administration => 'Administration';

  @override
  String get profile_adminDashboard => 'Tableau de Bord Admin';

  @override
  String get profile_adminSubtitle =>
      'Statistiques système, projets et gestion des genres';

  @override
  String get profile_account => 'Compte';

  @override
  String get profile_logOut => 'Se Déconnecter';

  @override
  String get profile_clearCacheTitle => 'Effacer le cache local ?';

  @override
  String get profile_clearCacheMessage =>
      'Cela supprimera tous les enregistrements stockés localement. Les enregistrements téléversés sur le serveur ne seront pas affectés.';

  @override
  String get profile_cacheCleared => 'Cache local effacé';

  @override
  String profile_joinedSuccess(String name) {
    return 'Rejoint \"$name\" avec succès';
  }

  @override
  String get profile_inviteDeclined => 'Invitation refusée';

  @override
  String get profile_language => 'Langue';

  @override
  String get profile_online => 'En ligne';

  @override
  String get profile_offline => 'Hors ligne';

  @override
  String profile_lastSync(String time) {
    return 'Dernière synchronisation : $time';
  }

  @override
  String get profile_neverSynced => 'Jamais synchronisé';

  @override
  String profile_pendingCount(int count) {
    return '$count en attente';
  }

  @override
  String profile_syncingProgress(int percent) {
    return 'Synchronisation... $percent%';
  }

  @override
  String get profile_syncNow => 'Synchroniser Maintenant';

  @override
  String get profile_wifiOnly => 'Téléverser uniquement en Wi-Fi';

  @override
  String get profile_wifiOnlySubtitle =>
      'Empêcher les téléversements via les données mobiles';

  @override
  String get profile_autoRemove =>
      'Supprimer automatiquement après téléversement';

  @override
  String get profile_autoRemoveSubtitle =>
      'Supprimer les fichiers locaux après un téléversement réussi';

  @override
  String get profile_clearCache => 'Effacer le cache local';

  @override
  String get profile_clearCacheSubtitle =>
      'Supprimer tous les enregistrements stockés localement';

  @override
  String get profile_invitations => 'Invitations';

  @override
  String get profile_refreshInvitations => 'Actualiser les invitations';

  @override
  String get profile_noInvitations => 'Aucune invitation en attente';

  @override
  String get profile_roleManager => 'Rôle : Gestionnaire';

  @override
  String get profile_roleMember => 'Rôle : Membre';

  @override
  String get profile_decline => 'Refuser';

  @override
  String get profile_accept => 'Accepter';

  @override
  String get profile_storage => 'Stockage';

  @override
  String get profile_status => 'Statut';

  @override
  String get profile_pendingLabel => 'En attente';

  @override
  String get admin_title => 'Tableau de Bord Admin';

  @override
  String get admin_overview => 'Aperçu';

  @override
  String get admin_projects => 'Projets';

  @override
  String get admin_genres => 'Genres';

  @override
  String get admin_cleaning => 'Nettoyage';

  @override
  String get admin_accessRequired => 'Accès administrateur requis';

  @override
  String get admin_totalProjects => 'Total des Projets';

  @override
  String get admin_languages => 'Langues';

  @override
  String get admin_recordings => 'Enregistrements';

  @override
  String get admin_totalHours => 'Total des Heures';

  @override
  String get admin_activeUsers => 'Utilisateurs Actifs';

  @override
  String get admin_projectName => 'Nom';

  @override
  String get admin_projectLanguage => 'Langue';

  @override
  String get admin_projectMembers => 'Membres';

  @override
  String get admin_projectRecordings => 'Enregistrements';

  @override
  String get admin_projectDuration => 'Durée';

  @override
  String get admin_projectCreated => 'Créé';

  @override
  String get admin_noProjects => 'Aucun projet trouvé';

  @override
  String get admin_unknownLanguage => 'Langue inconnue';

  @override
  String get admin_genresAndSubcategories => 'Genres et Sous-catégories';

  @override
  String get admin_addGenre => 'Ajouter un Genre';

  @override
  String get admin_noGenres => 'Aucun genre trouvé';

  @override
  String get admin_genreName => 'Nom du Genre';

  @override
  String get admin_required => 'Requis';

  @override
  String get admin_descriptionOptional => 'Description (facultatif)';

  @override
  String get admin_genreCreated => 'Genre créé';

  @override
  String get admin_editGenre => 'Modifier le genre';

  @override
  String get admin_deleteGenre => 'Supprimer le genre';

  @override
  String get admin_addSubcategory => 'Ajouter une sous-catégorie';

  @override
  String get admin_editGenreTitle => 'Modifier le Genre';

  @override
  String get admin_genreUpdated => 'Genre mis à jour';

  @override
  String get admin_deleteGenreTitle => 'Supprimer le Genre';

  @override
  String admin_deleteGenreConfirm(String name) {
    return 'Supprimer \"$name\" et toutes ses sous-catégories ?';
  }

  @override
  String get admin_genreDeleted => 'Genre supprimé';

  @override
  String admin_addSubcategoryTo(String name) {
    return 'Ajouter une Sous-catégorie à $name';
  }

  @override
  String get admin_subcategoryName => 'Nom de la Sous-catégorie';

  @override
  String get admin_subcategoryCreated => 'Sous-catégorie créée';

  @override
  String get admin_deleteSubcategory => 'Supprimer la Sous-catégorie';

  @override
  String admin_deleteSubcategoryConfirm(String name) {
    return 'Supprimer \"$name\" ?';
  }

  @override
  String get admin_subcategoryDeleted => 'Sous-catégorie supprimée';

  @override
  String get admin_cleaningQueue => 'File de Nettoyage Audio';

  @override
  String admin_cleanSelected(int count) {
    return 'Nettoyer la Sélection ($count)';
  }

  @override
  String get admin_refreshCleaning => 'Actualiser la file de nettoyage';

  @override
  String get admin_cleaningWebOnly =>
      'Le nettoyage audio est une fonctionnalité web uniquement. Les processus de nettoyage s\'exécutent sur le serveur.';

  @override
  String get admin_noCleaningRecordings =>
      'Aucun enregistrement signalé pour nettoyage';

  @override
  String get admin_cleaningTitle => 'Titre';

  @override
  String get admin_cleaningDuration => 'Durée';

  @override
  String get admin_cleaningSize => 'Taille';

  @override
  String get admin_cleaningFormat => 'Format';

  @override
  String get admin_cleaningRecorded => 'Enregistré';

  @override
  String get admin_cleaningActions => 'Actions';

  @override
  String get admin_clean => 'Nettoyer';

  @override
  String get admin_deselectAll => 'Tout Désélectionner';

  @override
  String get admin_selectAll => 'Tout Sélectionner';

  @override
  String get admin_cleaningTriggered => 'Nettoyage déclenché';

  @override
  String get admin_cleaningFailed => 'Échec du déclenchement du nettoyage';

  @override
  String admin_cleaningPartial(int success, int total) {
    return 'Nettoyage déclenché pour $success sur $total enregistrements';
  }

  @override
  String get genre_title => 'Genre';

  @override
  String get genre_notFound => 'Genre introuvable';

  @override
  String genre_recordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enregistrements',
      one: '1 enregistrement',
    );
    return '$_temp0';
  }

  @override
  String get format_justNow => 'à l\'instant';

  @override
  String format_minutesAgo(int count) {
    return 'il y a ${count}min';
  }

  @override
  String format_hoursAgo(int count) {
    return 'il y a ${count}h';
  }

  @override
  String format_daysAgo(int count) {
    return 'il y a ${count}j';
  }

  @override
  String format_weeksAgo(int count) {
    return 'il y a ${count}sem';
  }

  @override
  String format_monthsAgo(int count) {
    return 'il y a ${count}m';
  }

  @override
  String format_memberSince(String date) {
    return 'Membre depuis $date';
  }

  @override
  String get format_member => 'Membre';

  @override
  String format_dateAt(String date, String time) {
    return '$date à $time';
  }

  @override
  String get genre_narrative => 'Narratif';

  @override
  String get genre_narrativeDesc =>
      'Histoires, récits et formes narratives de la tradition orale';

  @override
  String get genre_poeticSong => 'Poétique / Chant';

  @override
  String get genre_poeticSongDesc =>
      'Traditions orales musicales et poétiques, incluant hymnes, lamentations et poésie de sagesse';

  @override
  String get genre_instructional => 'Instructif / Réglementaire';

  @override
  String get genre_instructionalDesc =>
      'Lois, rituels, procédures et formes instructives';

  @override
  String get genre_oralDiscourse => 'Discours Oral';

  @override
  String get genre_oralDiscourseDesc =>
      'Discours, enseignements, prières et formes discursives orales';

  @override
  String get sub_historicalNarrative => 'Récit Historique';

  @override
  String get sub_personalAccount => 'Récit Personnel / Témoignage';

  @override
  String get sub_parable => 'Parabole / Histoire Illustrative';

  @override
  String get sub_originStory => 'Récit des Origines / Création';

  @override
  String get sub_legend => 'Légende / Récit de Héros';

  @override
  String get sub_visionNarrative => 'Récit de Vision ou de Rêve';

  @override
  String get sub_genealogy => 'Généalogie';

  @override
  String get sub_eventReport => 'Rapport d\'Événement Récent';

  @override
  String get sub_hymn => 'Hymne / Chant d\'Adoration';

  @override
  String get sub_lament => 'Lamentation';

  @override
  String get sub_funeralDirge => 'Chant Funèbre';

  @override
  String get sub_victorySong => 'Chant de Victoire / Célébration';

  @override
  String get sub_loveSong => 'Chant d\'Amour';

  @override
  String get sub_tauntSong => 'Chant Moqueur / de Raillerie';

  @override
  String get sub_blessing => 'Bénédiction';

  @override
  String get sub_curse => 'Malédiction';

  @override
  String get sub_wisdomPoem => 'Poème de Sagesse / Proverbe';

  @override
  String get sub_didacticPoetry => 'Poésie Didactique';

  @override
  String get sub_legalCode => 'Loi / Code Juridique';

  @override
  String get sub_ritual => 'Rituel / Liturgie';

  @override
  String get sub_procedure => 'Procédure / Instruction';

  @override
  String get sub_listInventory => 'Liste / Inventaire';

  @override
  String get sub_propheticOracle => 'Oracle Prophétique / Discours';

  @override
  String get sub_exhortation => 'Exhortation / Sermon';

  @override
  String get sub_wisdomTeaching => 'Enseignement de Sagesse';

  @override
  String get sub_prayer => 'Prière';

  @override
  String get sub_dialogue => 'Dialogue';

  @override
  String get sub_epistle => 'Épître / Lettre';

  @override
  String get sub_apocalypticDiscourse => 'Discours Apocalyptique';

  @override
  String get sub_ceremonialSpeech => 'Discours Cérémoniel';

  @override
  String get sub_communityMemory => 'Mémoire Communautaire';

  @override
  String get sub_historicalNarrativeDesc =>
      'Récits d\'événements, de guerres et de moments clés de l\'histoire';

  @override
  String get sub_personalAccountDesc =>
      'Histoires personnelles d\'expériences vécues et de foi';

  @override
  String get sub_parableDesc =>
      'Histoires symboliques qui enseignent des leçons morales ou spirituelles';

  @override
  String get sub_originStoryDesc => 'Histoires sur l\'origine des choses';

  @override
  String get sub_legendDesc =>
      'Récits de personnes remarquables et de leurs grands exploits';

  @override
  String get sub_visionNarrativeDesc =>
      'Récits de visions divines et de rêves prophétiques';

  @override
  String get sub_genealogyDesc =>
      'Archives des lignées familiales et ancestrales';

  @override
  String get sub_eventReportDesc =>
      'Rapports d\'événements récents dans la communauté';

  @override
  String get sub_hymnDesc => 'Chants de louange et d\'adoration à Dieu';

  @override
  String get sub_lamentDesc =>
      'Expressions de chagrin, de tristesse et de deuil';

  @override
  String get sub_funeralDirgeDesc =>
      'Chants interprétés lors des cérémonies de deuil et d\'enterrement';

  @override
  String get sub_victorySongDesc =>
      'Chants célébrant les triomphes et les événements joyeux';

  @override
  String get sub_loveSongDesc => 'Chants exprimant l\'amour et la dévotion';

  @override
  String get sub_tauntSongDesc =>
      'Chants de moquerie envers les ennemis ou les infidèles';

  @override
  String get sub_blessingDesc =>
      'Paroles invoquant la faveur et la protection divine';

  @override
  String get sub_curseDesc =>
      'Proclamations de jugement ou de conséquence divine';

  @override
  String get sub_wisdomPoemDesc =>
      'Dictons et poèmes transmettant une sagesse pratique';

  @override
  String get sub_didacticPoetryDesc =>
      'Compositions poétiques destinées à enseigner et instruire';

  @override
  String get sub_legalCodeDesc =>
      'Règles, statuts et réglementations d\'alliance';

  @override
  String get sub_ritualDesc =>
      'Formes prescrites de culte et cérémonies sacrées';

  @override
  String get sub_procedureDesc =>
      'Directives pratiques et instructions étape par étape';

  @override
  String get sub_listInventoryDesc =>
      'Catalogues, recensements et registres organisés';

  @override
  String get sub_propheticOracleDesc => 'Messages délivrés au nom de Dieu';

  @override
  String get sub_exhortationDesc =>
      'Discours exhortant à l\'action morale et spirituelle';

  @override
  String get sub_wisdomTeachingDesc =>
      'Enseignement sur la vie sage et vertueuse';

  @override
  String get sub_prayerDesc =>
      'Paroles adressées à Dieu dans l\'adoration ou la supplication';

  @override
  String get sub_dialogueDesc => 'Conversations et échanges entre personnes';

  @override
  String get sub_epistleDesc =>
      'Messages écrits adressés à des communautés ou des individus';

  @override
  String get sub_apocalypticDiscourseDesc =>
      'Révélations sur les derniers temps et le plan de Dieu';

  @override
  String get sub_ceremonialSpeechDesc =>
      'Discours formels pour des occasions officielles ou sacrées';

  @override
  String get sub_communityMemoryDesc =>
      'Souvenirs partagés qui préservent l\'identité du groupe';

  @override
  String get register_intimate => 'Intime';

  @override
  String get register_casual => 'Informel / Familier';

  @override
  String get register_consultative => 'Consultatif';

  @override
  String get register_formal => 'Formel / Officiel';

  @override
  String get register_ceremonial => 'Cérémoniel';

  @override
  String get register_elderAuthority => 'Ancien / Autorité';

  @override
  String get register_religiousWorship => 'Religieux / Culte';

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
  String get locale_englishSub => 'Anglais';

  @override
  String get locale_portugueseSub => 'Portugais';

  @override
  String get locale_hindiSub => 'Hindi';

  @override
  String get locale_koreanSub => 'Coréen';

  @override
  String get locale_spanishSub => 'Espagnol';

  @override
  String get locale_bahasaSub => 'Indonésien';

  @override
  String get locale_frenchSub => 'Français';

  @override
  String get locale_tokPisinSub => 'Tok Pisin';

  @override
  String get locale_swahiliSub => 'Swahili';

  @override
  String get locale_arabicSub => 'Arabe';

  @override
  String get locale_selectLanguage => 'Choisissez Votre Langue';

  @override
  String get locale_selectLanguageSubtitle =>
      'Vous pourrez changer cela plus tard dans les paramètres de votre profil.';

  @override
  String get filter_all => 'Tous';

  @override
  String get filter_pending => 'En attente';

  @override
  String get filter_uploaded => 'Téléversés';

  @override
  String get filter_needsCleaning => 'Nécessite un Nettoyage';

  @override
  String get filter_allGenres => 'Tous les genres';

  @override
  String get detail_duration => 'Durée';

  @override
  String get detail_size => 'Taille';

  @override
  String get detail_format => 'Format';

  @override
  String get detail_status => 'Statut';

  @override
  String get detail_upload => 'Téléversement';

  @override
  String get detail_uploaded => 'Téléversé';

  @override
  String get detail_cleaning => 'Nettoyage';

  @override
  String get detail_recorded => 'Enregistré';

  @override
  String get detail_retry => 'Réessayer';

  @override
  String get detail_notFlagged => 'Non signalé';

  @override
  String get detail_uploadStuck => 'Bloqué — appuyez sur Réessayer';

  @override
  String get detail_uploading => 'Téléversement...';

  @override
  String get detail_maxRetries => 'Max. de tentatives — appuyez sur Réessayer';

  @override
  String get detail_uploadFailed => 'Échec du Téléversement';

  @override
  String get detail_pendingRetried => 'En attente (réessayé)';

  @override
  String get detail_notSynced => 'Non synchronisé';

  @override
  String get action_actions => 'Actions';

  @override
  String get action_split => 'Diviser';

  @override
  String get action_flagClean => 'Signaler Nettoyage';

  @override
  String get action_clearFlag => 'Retirer le Signalement';

  @override
  String get action_move => 'Déplacer';

  @override
  String get action_delete => 'Supprimer';

  @override
  String get projectStats_recordings => 'Enregistrements';

  @override
  String get projectStats_duration => 'Durée';

  @override
  String get projectStats_members => 'Membres';

  @override
  String get project_active => 'Actif';

  @override
  String get recording_paused => 'En pause';

  @override
  String get recording_recording => 'Enregistrement';

  @override
  String get recording_tapToRecord => 'Appuyez pour Enregistrer';

  @override
  String get recording_sensitivity => 'Sensibilité';

  @override
  String get recording_sensitivityLow => 'Basse';

  @override
  String get recording_sensitivityMed => 'Moy';

  @override
  String get recording_sensitivityHigh => 'Haute';

  @override
  String get recording_stopRecording => 'Arrêter l\'enregistrement';

  @override
  String get recording_stop => 'Arrêter';

  @override
  String get recording_resume => 'Reprendre';

  @override
  String get recording_pause => 'Pause';
}
