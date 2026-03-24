// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Oral Collector';

  @override
  String get nav_home => 'Início';

  @override
  String get nav_record => 'Gravar';

  @override
  String get nav_recordings => 'Gravações';

  @override
  String get nav_projects => 'Projetos';

  @override
  String get nav_profile => 'Perfil';

  @override
  String get nav_admin => 'Admin';

  @override
  String get nav_collapse => 'Recolher';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_save => 'Salvar';

  @override
  String get common_delete => 'Excluir';

  @override
  String get common_remove => 'Remover';

  @override
  String get common_create => 'Criar';

  @override
  String get common_continue => 'Continuar';

  @override
  String get common_next => 'Próximo';

  @override
  String get common_retry => 'Tentar novamente';

  @override
  String get common_move => 'Mover';

  @override
  String get common_invite => 'Convidar';

  @override
  String get common_download => 'Baixar';

  @override
  String get common_clear => 'Limpar';

  @override
  String get common_untitled => 'Sem título';

  @override
  String get common_loading => 'Carregando...';

  @override
  String get auth_oralCollector => 'Oral Collector';

  @override
  String get auth_byShema => 'por Shema';

  @override
  String get auth_heroTagline => 'Preserve vozes.\nCompartilhe histórias.';

  @override
  String get auth_welcomeBack => 'Bem-vindo\nde Volta';

  @override
  String get auth_welcome => 'Bem-vindo ';

  @override
  String get auth_back => 'Voltar';

  @override
  String get auth_createWord => 'Criar ';

  @override
  String get auth_createNewline => 'Criar\n';

  @override
  String get auth_account => 'Conta';

  @override
  String get auth_signInSubtitle =>
      'Faça login para continuar coletando histórias.';

  @override
  String get auth_signUpSubtitle =>
      'Junte-se à nossa comunidade de coletores de histórias.';

  @override
  String get auth_backToSignIn => 'Voltar para login';

  @override
  String get auth_emailLabel => 'Endereço de E-mail';

  @override
  String get auth_emailHint => 'seu@email.com';

  @override
  String get auth_emailRequired => 'Por favor, insira seu e-mail';

  @override
  String get auth_emailInvalid => 'Por favor, insira um e-mail válido';

  @override
  String get auth_passwordLabel => 'Senha';

  @override
  String get auth_passwordHint => 'No mínimo 6 caracteres';

  @override
  String get auth_passwordRequired => 'Por favor, insira sua senha';

  @override
  String get auth_passwordTooShort => 'A senha deve ter no mínimo 6 caracteres';

  @override
  String get auth_confirmPasswordLabel => 'Confirmar Senha';

  @override
  String get auth_confirmPasswordHint => 'Digite a senha novamente';

  @override
  String get auth_confirmPasswordRequired => 'Por favor, confirme sua senha';

  @override
  String get auth_confirmPasswordMismatch => 'As senhas não coincidem';

  @override
  String get auth_nameLabel => 'Nome';

  @override
  String get auth_nameHint => 'Seu nome completo';

  @override
  String get auth_nameRequired => 'Por favor, insira seu nome de exibição';

  @override
  String get auth_signIn => 'Entrar';

  @override
  String get auth_signUp => 'Cadastrar';

  @override
  String get auth_noAccount => 'Não tem uma conta? ';

  @override
  String get auth_haveAccount => 'Já tem uma conta? ';

  @override
  String get auth_continueButton => 'Continuar';

  @override
  String get home_greetingMorning => 'Bom dia';

  @override
  String get home_greetingAfternoon => 'Boa tarde';

  @override
  String get home_greetingEvening => 'Boa noite';

  @override
  String home_greetingWithName(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get home_subtitle => 'Vamos compartilhar suas histórias hoje';

  @override
  String get home_switchProject => 'Trocar projeto';

  @override
  String get home_genres => 'Gêneros';

  @override
  String get home_loadingProjects => 'Carregando projetos...';

  @override
  String get home_loadingGenres => 'Carregando gêneros...';

  @override
  String get home_noGenres => 'Nenhum gênero disponível ainda';

  @override
  String get home_noProjectTitle => 'Selecione um projeto para começar';

  @override
  String get home_browseProjects => 'Explorar Projetos';

  @override
  String get stats_recordings => 'gravações';

  @override
  String get stats_recorded => 'gravado';

  @override
  String get stats_members => 'membros';

  @override
  String get project_switchTitle => 'Trocar Projeto';

  @override
  String get project_projects => 'Projetos';

  @override
  String get project_subtitle => 'Gerencie suas coleções';

  @override
  String get project_noProjectsTitle => 'Nenhum projeto ainda';

  @override
  String get project_noProjectsSubtitle =>
      'Crie seu primeiro projeto para começar a coletar histórias orais.';

  @override
  String get project_newProject => 'Novo Projeto';

  @override
  String get project_projectName => 'Nome do Projeto';

  @override
  String get project_projectNameHint => 'ex. Tradução Bíblica Kosrae';

  @override
  String get project_projectNameRequired => 'O nome do projeto é obrigatório';

  @override
  String get project_description => 'Descrição';

  @override
  String get project_descriptionHint => 'Opcional';

  @override
  String get project_language => 'Idioma';

  @override
  String get project_selectLanguage => 'Selecione um idioma';

  @override
  String get project_pleaseSelectLanguage => 'Por favor, selecione um idioma';

  @override
  String get project_createProject => 'Criar Projeto';

  @override
  String get project_selectLanguageTitle => 'Selecionar Idioma';

  @override
  String get project_addLanguageTitle => 'Adicionar Idioma';

  @override
  String get project_addLanguageSubtitle =>
      'Não encontrou seu idioma? Adicione aqui.';

  @override
  String get project_languageName => 'Nome do Idioma';

  @override
  String get project_languageNameHint => 'ex. Kosraeano';

  @override
  String get project_languageNameRequired => 'O nome é obrigatório';

  @override
  String get project_languageCode => 'Código do Idioma';

  @override
  String get project_languageCodeHint => 'ex. kos (ISO 639-3)';

  @override
  String get project_languageCodeRequired => 'O código é obrigatório';

  @override
  String get project_languageCodeTooLong =>
      'O código deve ter de 1 a 3 caracteres';

  @override
  String get project_addLanguage => 'Adicionar Idioma';

  @override
  String get project_noLanguagesFound => 'Nenhum idioma encontrado';

  @override
  String get project_addNewLanguage => 'Adicionar novo idioma';

  @override
  String project_addAsNewLanguage(String query) {
    return 'Adicionar \"$query\" como novo idioma';
  }

  @override
  String get project_searchLanguages => 'Buscar idiomas...';

  @override
  String get project_backToList => 'Voltar para lista';

  @override
  String get projectSettings_title => 'Configurações do Projeto';

  @override
  String get projectSettings_details => 'Detalhes';

  @override
  String get projectSettings_saving => 'Salvando...';

  @override
  String get projectSettings_saveChanges => 'Salvar Alterações';

  @override
  String get projectSettings_updated => 'Projeto atualizado';

  @override
  String get projectSettings_noPermission =>
      'Você não tem permissão para atualizar este projeto';

  @override
  String get projectSettings_team => 'Equipe';

  @override
  String get projectSettings_removeMember => 'Remover Membro';

  @override
  String projectSettings_removeMemberConfirm(String name) {
    return 'Remover $name deste projeto?';
  }

  @override
  String get projectSettings_memberRemoved => 'Membro removido';

  @override
  String get projectSettings_memberRemoveFailed => 'Falha ao remover membro';

  @override
  String get projectSettings_inviteSent => 'Convite enviado com sucesso';

  @override
  String get projectSettings_noMembers => 'Nenhum membro ainda';

  @override
  String get recording_selectGenre => 'Selecionar Gênero';

  @override
  String get recording_selectGenreSubtitle =>
      'Escolha um gênero para sua história';

  @override
  String get recording_selectSubcategory => 'Selecionar Subcategoria';

  @override
  String get recording_selectSubcategorySubtitle => 'Escolha uma subcategoria';

  @override
  String get recording_selectRegister => 'Selecionar Registro';

  @override
  String get recording_selectRegisterSubtitle => 'Escolha o registro de fala';

  @override
  String get recording_recordingStep => 'Gravação';

  @override
  String get recording_recordingStepSubtitle => 'Capture sua história';

  @override
  String get recording_reviewStep => 'Revisar Gravação';

  @override
  String get recording_reviewStepSubtitle => 'Ouça e salve';

  @override
  String get recording_genreNotFound => 'Gênero não encontrado';

  @override
  String get recording_noGenres => 'Nenhum gênero disponível';

  @override
  String get recording_noSubcategories => 'Nenhuma subcategoria disponível';

  @override
  String get recording_registerDescription =>
      'Escolha o registro de fala que melhor descreve o tom e a formalidade desta gravação.';

  @override
  String get recording_titleHint => 'Adicionar um título (opcional)';

  @override
  String get recording_saveRecording => 'Salvar Gravação';

  @override
  String get recording_recordAgain => 'Gravar Novamente';

  @override
  String get recording_discard => 'Descartar';

  @override
  String get recording_discardTitle => 'Descartar Gravação?';

  @override
  String get recording_discardMessage =>
      'Esta gravação será excluída permanentemente.';

  @override
  String get recording_saved => 'Gravação salva';

  @override
  String get recording_notFound => 'Gravação não encontrada';

  @override
  String get recording_unknownGenre => 'Gênero desconhecido';

  @override
  String get recording_splitRecording => 'Dividir Gravação';

  @override
  String get recording_moveCategory => 'Mover Categoria';

  @override
  String get recording_downloadAudio => 'Baixar Áudio';

  @override
  String get recording_downloadAudioMessage =>
      'O arquivo de áudio não está armazenado neste dispositivo. Deseja baixá-lo para cortar?';

  @override
  String recording_downloadFailed(String error) {
    return 'Falha ao baixar: $error';
  }

  @override
  String get recording_audioNotAvailable => 'Arquivo de áudio não disponível';

  @override
  String get recording_deleteTitle => 'Excluir Gravação';

  @override
  String get recording_deleteMessage =>
      'Isso excluirá permanentemente esta gravação do seu dispositivo. Se ela já foi enviada, também será removida do servidor. Esta ação não pode ser desfeita.';

  @override
  String get recording_deleteNoPermission =>
      'Você não tem permissão para excluir esta gravação';

  @override
  String get recording_deleteFailed => 'Falha ao excluir gravação';

  @override
  String get recording_deleteFailedLocal =>
      'Falha ao excluir do servidor. Removendo localmente.';

  @override
  String get recording_cleaningStatusFailed =>
      'Falha ao atualizar status de limpeza no servidor';

  @override
  String get recording_updateNoPermission =>
      'Você não tem permissão para atualizar esta gravação';

  @override
  String get recording_moveNoPermission =>
      'Você não tem permissão para mover esta gravação';

  @override
  String get recording_movedSuccess => 'Gravação movida com sucesso';

  @override
  String get recording_updateFailed => 'Falha ao atualizar no servidor';

  @override
  String get recordings_title => 'Gravações';

  @override
  String get recordings_subtitle => 'Suas histórias coletadas';

  @override
  String get recordings_importAudio => 'Importar arquivo de áudio';

  @override
  String get recordings_selectProject => 'Selecione um projeto';

  @override
  String get recordings_selectProjectSubtitle =>
      'Escolha um projeto para ver suas gravações';

  @override
  String get recordings_noRecordings => 'Nenhuma gravação ainda';

  @override
  String get recordings_noRecordingsSubtitle =>
      'Toque no microfone para gravar sua primeira história, ou importe um arquivo de áudio.';

  @override
  String recordings_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gravações',
      one: '1 gravação',
    );
    return '$_temp0';
  }

  @override
  String get recording_statusUploaded => 'Enviado';

  @override
  String get recording_statusUploading => 'Enviando';

  @override
  String get recording_statusFailed => 'Falha';

  @override
  String get recording_statusLocal => 'Local';

  @override
  String get trim_title => 'Dividir Gravação';

  @override
  String get trim_notFound => 'Gravação não encontrada';

  @override
  String get trim_audioUrlNotAvailable =>
      'URL do áudio não disponível para esta gravação.';

  @override
  String get trim_localNotAvailable =>
      'Arquivo de áudio local não disponível. Baixe a gravação primeiro.';

  @override
  String get trim_atLeastOneSegment =>
      'Pelo menos um segmento deve ser mantido';

  @override
  String get trim_segments => 'Segmentos';

  @override
  String get trim_restoreAll => 'Restaurar todos';

  @override
  String get trim_instructions =>
      'Toque na forma de onda acima para posicionar\nmarcadores de divisão e dividir esta gravação';

  @override
  String get trim_splitting => 'Dividindo...';

  @override
  String trim_saveSegments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Salvar $count segmentos',
      one: 'Salvar 1 segmento',
    );
    return '$_temp0';
  }

  @override
  String get trim_addSplitsFirst => 'Adicione divisões primeiro';

  @override
  String trim_savedSegments(int kept, int removed) {
    String _temp0 = intl.Intl.pluralLogic(
      kept,
      locale: localeName,
      other: 's',
      one: '',
    );
    return 'Salvou $kept segmento$_temp0, removeu $removed';
  }

  @override
  String trim_splitInto(int count) {
    return 'Dividir em $count gravações';
  }

  @override
  String get import_title => 'Importar Áudio';

  @override
  String get import_selectGenre => 'Selecionar Gênero';

  @override
  String get import_selectSubcategory => 'Selecionar Subcategoria';

  @override
  String get import_selectRegister => 'Selecionar Registro';

  @override
  String get import_confirmImport => 'Confirmar Importação';

  @override
  String get import_analyzing => 'Analisando arquivo de áudio...';

  @override
  String get import_selectFile => 'Selecione um arquivo de áudio para importar';

  @override
  String get import_chooseFile => 'Escolher Arquivo';

  @override
  String get import_accessFailed =>
      'Não foi possível acessar o arquivo selecionado';

  @override
  String import_pickError(String error) {
    return 'Erro ao selecionar arquivo: $error';
  }

  @override
  String import_saveError(String error) {
    return 'Erro ao salvar arquivo: $error';
  }

  @override
  String get import_unknownFile => 'Arquivo desconhecido';

  @override
  String get import_importAndSave => 'Importar e Salvar';

  @override
  String get moveCategory_title => 'Mover Categoria';

  @override
  String get moveCategory_genre => 'Gênero';

  @override
  String get moveCategory_subcategory => 'Subcategoria';

  @override
  String get moveCategory_selectSubcategory => 'Selecionar subcategoria';

  @override
  String get cleaning_needsCleaning => 'Precisa de Limpeza';

  @override
  String get cleaning_cleaning => 'Limpando...';

  @override
  String get cleaning_cleaned => 'Limpo';

  @override
  String get cleaning_cleanFailed => 'Falha na Limpeza';

  @override
  String get sync_uploading => 'Enviando...';

  @override
  String sync_pending(int count) {
    return '$count pendente(s)';
  }

  @override
  String get profile_photoUpdated => 'Foto de perfil atualizada';

  @override
  String profile_photoFailed(String error) {
    return 'Falha ao atualizar foto: $error';
  }

  @override
  String get profile_editName => 'Editar nome de exibição';

  @override
  String get profile_nameHint => 'Seu nome';

  @override
  String get profile_nameUpdated => 'Nome atualizado';

  @override
  String get profile_syncStorage => 'Sincronização e Armazenamento';

  @override
  String get profile_about => 'Sobre';

  @override
  String get profile_appVersion => 'Versão do app';

  @override
  String get profile_byShema => 'Oral Collector por Shema';

  @override
  String get profile_administration => 'Administração';

  @override
  String get profile_adminDashboard => 'Painel do Admin';

  @override
  String get profile_adminSubtitle =>
      'Estatísticas do sistema, projetos e gerenciamento de gêneros';

  @override
  String get profile_account => 'Conta';

  @override
  String get profile_logOut => 'Sair';

  @override
  String get profile_clearCacheTitle => 'Limpar cache local?';

  @override
  String get profile_clearCacheMessage =>
      'Isso excluirá todas as gravações armazenadas localmente. As gravações enviadas ao servidor não serão afetadas.';

  @override
  String get profile_cacheCleared => 'Cache local limpo';

  @override
  String profile_joinedSuccess(String name) {
    return 'Entrou em \"$name\" com sucesso';
  }

  @override
  String get profile_inviteDeclined => 'Convite recusado';

  @override
  String get profile_language => 'Idioma';

  @override
  String get profile_online => 'Online';

  @override
  String get profile_offline => 'Offline';

  @override
  String profile_lastSync(String time) {
    return 'Última sincronização: $time';
  }

  @override
  String get profile_neverSynced => 'Nunca sincronizado';

  @override
  String profile_pendingCount(int count) {
    return '$count pendente(s)';
  }

  @override
  String profile_syncingProgress(int percent) {
    return 'Sincronizando... $percent%';
  }

  @override
  String get profile_syncNow => 'Sincronizar Agora';

  @override
  String get profile_wifiOnly => 'Enviar apenas por Wi-Fi';

  @override
  String get profile_wifiOnlySubtitle => 'Impedir envios por dados móveis';

  @override
  String get profile_autoRemove => 'Remover automaticamente após envio';

  @override
  String get profile_autoRemoveSubtitle =>
      'Excluir arquivos locais após envio bem-sucedido';

  @override
  String get profile_clearCache => 'Limpar cache local';

  @override
  String get profile_clearCacheSubtitle =>
      'Excluir todas as gravações armazenadas localmente';

  @override
  String get profile_invitations => 'Convites';

  @override
  String get profile_refreshInvitations => 'Atualizar convites';

  @override
  String get profile_noInvitations => 'Nenhum convite pendente';

  @override
  String get profile_roleManager => 'Função: Gerente';

  @override
  String get profile_roleMember => 'Função: Membro';

  @override
  String get profile_decline => 'Recusar';

  @override
  String get profile_accept => 'Aceitar';

  @override
  String get profile_storage => 'Armazenamento';

  @override
  String get profile_status => 'Status';

  @override
  String get profile_pendingLabel => 'Pendente';

  @override
  String get admin_title => 'Painel do Admin';

  @override
  String get admin_overview => 'Visão Geral';

  @override
  String get admin_projects => 'Projetos';

  @override
  String get admin_genres => 'Gêneros';

  @override
  String get admin_cleaning => 'Limpeza';

  @override
  String get admin_accessRequired => 'Acesso de administrador necessário';

  @override
  String get admin_totalProjects => 'Total de Projetos';

  @override
  String get admin_languages => 'Idiomas';

  @override
  String get admin_recordings => 'Gravações';

  @override
  String get admin_totalHours => 'Total de Horas';

  @override
  String get admin_activeUsers => 'Usuários Ativos';

  @override
  String get admin_projectName => 'Nome';

  @override
  String get admin_projectLanguage => 'Idioma';

  @override
  String get admin_projectMembers => 'Membros';

  @override
  String get admin_projectRecordings => 'Gravações';

  @override
  String get admin_projectDuration => 'Duração';

  @override
  String get admin_projectCreated => 'Criado em';

  @override
  String get admin_noProjects => 'Nenhum projeto encontrado';

  @override
  String get admin_unknownLanguage => 'Idioma desconhecido';

  @override
  String get admin_genresAndSubcategories => 'Gêneros e Subcategorias';

  @override
  String get admin_addGenre => 'Adicionar Gênero';

  @override
  String get admin_noGenres => 'Nenhum gênero encontrado';

  @override
  String get admin_genreName => 'Nome do Gênero';

  @override
  String get admin_required => 'Obrigatório';

  @override
  String get admin_descriptionOptional => 'Descrição (opcional)';

  @override
  String get admin_genreCreated => 'Gênero criado';

  @override
  String get admin_editGenre => 'Editar gênero';

  @override
  String get admin_deleteGenre => 'Excluir gênero';

  @override
  String get admin_addSubcategory => 'Adicionar subcategoria';

  @override
  String get admin_editGenreTitle => 'Editar Gênero';

  @override
  String get admin_genreUpdated => 'Gênero atualizado';

  @override
  String get admin_deleteGenreTitle => 'Excluir Gênero';

  @override
  String admin_deleteGenreConfirm(String name) {
    return 'Excluir \"$name\" e todas as suas subcategorias?';
  }

  @override
  String get admin_genreDeleted => 'Gênero excluído';

  @override
  String admin_addSubcategoryTo(String name) {
    return 'Adicionar Subcategoria a $name';
  }

  @override
  String get admin_subcategoryName => 'Nome da Subcategoria';

  @override
  String get admin_subcategoryCreated => 'Subcategoria criada';

  @override
  String get admin_deleteSubcategory => 'Excluir Subcategoria';

  @override
  String admin_deleteSubcategoryConfirm(String name) {
    return 'Excluir \"$name\"?';
  }

  @override
  String get admin_subcategoryDeleted => 'Subcategoria excluída';

  @override
  String get admin_cleaningQueue => 'Fila de Limpeza de Áudio';

  @override
  String admin_cleanSelected(int count) {
    return 'Limpar Selecionados ($count)';
  }

  @override
  String get admin_refreshCleaning => 'Atualizar fila de limpeza';

  @override
  String get admin_cleaningWebOnly =>
      'A limpeza de áudio é um recurso exclusivo para web. Os processos de limpeza são executados no servidor.';

  @override
  String get admin_noCleaningRecordings =>
      'Nenhuma gravação marcada para limpeza';

  @override
  String get admin_cleaningTitle => 'Título';

  @override
  String get admin_cleaningDuration => 'Duração';

  @override
  String get admin_cleaningSize => 'Tamanho';

  @override
  String get admin_cleaningFormat => 'Formato';

  @override
  String get admin_cleaningRecorded => 'Gravado em';

  @override
  String get admin_cleaningActions => 'Ações';

  @override
  String get admin_clean => 'Limpar';

  @override
  String get admin_deselectAll => 'Desmarcar Todos';

  @override
  String get admin_selectAll => 'Selecionar Todos';

  @override
  String get admin_cleaningTriggered => 'Limpeza iniciada';

  @override
  String get admin_cleaningFailed => 'Falha ao iniciar limpeza';

  @override
  String admin_cleaningPartial(int success, int total) {
    return 'Limpeza iniciada para $success de $total gravações';
  }

  @override
  String get genre_title => 'Gênero';

  @override
  String get genre_notFound => 'Gênero não encontrado';

  @override
  String genre_recordingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gravações',
      one: '1 gravação',
    );
    return '$_temp0';
  }

  @override
  String get format_justNow => 'agora mesmo';

  @override
  String format_minutesAgo(int count) {
    return '${count}min atrás';
  }

  @override
  String format_hoursAgo(int count) {
    return '${count}h atrás';
  }

  @override
  String format_daysAgo(int count) {
    return '${count}d atrás';
  }

  @override
  String format_weeksAgo(int count) {
    return '${count}sem atrás';
  }

  @override
  String format_monthsAgo(int count) {
    return '${count}m atrás';
  }

  @override
  String format_memberSince(String date) {
    return 'Membro desde $date';
  }

  @override
  String get format_member => 'Membro';

  @override
  String format_dateAt(String date, String time) {
    return '$date às $time';
  }

  @override
  String get genre_narrative => 'Narrativa';

  @override
  String get genre_narrativeDesc =>
      'Histórias, relatos e formas narrativas da tradição oral';

  @override
  String get genre_poeticSong => 'Poético / Canção';

  @override
  String get genre_poeticSongDesc =>
      'Tradições orais musicais e poéticas, incluindo hinos, lamentos e poesia sapiencial';

  @override
  String get genre_instructional => 'Instrucional / Regulatório';

  @override
  String get genre_instructionalDesc =>
      'Leis, rituais, procedimentos e formas instrucionais';

  @override
  String get genre_oralDiscourse => 'Discurso Oral';

  @override
  String get genre_oralDiscourseDesc =>
      'Discursos, ensinamentos, orações e formas discursivas orais';

  @override
  String get sub_historicalNarrative => 'Narrativa Histórica';

  @override
  String get sub_personalAccount => 'Relato Pessoal / Testemunho';

  @override
  String get sub_parable => 'Parábola / História Ilustrativa';

  @override
  String get sub_originStory => 'História de Origem / Criação';

  @override
  String get sub_legend => 'Lenda / História de Herói';

  @override
  String get sub_visionNarrative => 'Narrativa de Visão ou Sonho';

  @override
  String get sub_genealogy => 'Genealogia';

  @override
  String get sub_eventReport => 'Relato de Evento Recente';

  @override
  String get sub_hymn => 'Hino / Cântico de Adoração';

  @override
  String get sub_lament => 'Lamento';

  @override
  String get sub_funeralDirge => 'Canto Fúnebre';

  @override
  String get sub_victorySong => 'Cântico de Vitória / Celebração';

  @override
  String get sub_loveSong => 'Cântico de Amor';

  @override
  String get sub_tauntSong => 'Cântico de Escárnio / Zombaria';

  @override
  String get sub_blessing => 'Bênção';

  @override
  String get sub_curse => 'Maldição';

  @override
  String get sub_wisdomPoem => 'Poema Sapiencial / Provérbio';

  @override
  String get sub_didacticPoetry => 'Poesia Didática';

  @override
  String get sub_legalCode => 'Lei / Código Legal';

  @override
  String get sub_ritual => 'Ritual / Liturgia';

  @override
  String get sub_procedure => 'Procedimento / Instrução';

  @override
  String get sub_listInventory => 'Lista / Inventário';

  @override
  String get sub_propheticOracle => 'Oráculo Profético / Discurso';

  @override
  String get sub_exhortation => 'Exortação / Sermão';

  @override
  String get sub_wisdomTeaching => 'Ensino Sapiencial';

  @override
  String get sub_prayer => 'Oração';

  @override
  String get sub_dialogue => 'Diálogo';

  @override
  String get sub_epistle => 'Epístola / Carta';

  @override
  String get sub_apocalypticDiscourse => 'Discurso Apocalíptico';

  @override
  String get sub_ceremonialSpeech => 'Discurso Cerimonial';

  @override
  String get sub_communityMemory => 'Memória Comunitária';

  @override
  String get sub_historicalNarrativeDesc =>
      'Relatos de acontecimentos, guerras e momentos-chave da história';

  @override
  String get sub_personalAccountDesc =>
      'Histórias pessoais de experiências vividas e de fé';

  @override
  String get sub_parableDesc =>
      'Histórias simbólicas que ensinam lições morais ou espirituais';

  @override
  String get sub_originStoryDesc => 'Histórias sobre como as coisas surgiram';

  @override
  String get sub_legendDesc =>
      'Relatos de pessoas notáveis e seus grandes feitos';

  @override
  String get sub_visionNarrativeDesc =>
      'Relatos de visões divinas e sonhos proféticos';

  @override
  String get sub_genealogyDesc =>
      'Registros de linhas familiares e linhagens ancestrais';

  @override
  String get sub_eventReportDesc =>
      'Relatos de acontecimentos recentes na comunidade';

  @override
  String get sub_hymnDesc => 'Cânticos de louvor e adoração a Deus';

  @override
  String get sub_lamentDesc => 'Expressões de dor, tristeza e luto';

  @override
  String get sub_funeralDirgeDesc =>
      'Cânticos realizados durante cerimônias de luto e sepultamento';

  @override
  String get sub_victorySongDesc =>
      'Cânticos que celebram triunfos e eventos alegres';

  @override
  String get sub_loveSongDesc => 'Cânticos que expressam amor e devoção';

  @override
  String get sub_tauntSongDesc =>
      'Cânticos de escárnio dirigidos a inimigos ou infiéis';

  @override
  String get sub_blessingDesc => 'Palavras que invocam favor e proteção divina';

  @override
  String get sub_curseDesc =>
      'Pronunciamentos de julgamento ou consequência divina';

  @override
  String get sub_wisdomPoemDesc =>
      'Ditados e poemas que transmitem sabedoria prática';

  @override
  String get sub_didacticPoetryDesc =>
      'Composições poéticas destinadas a ensinar e instruir';

  @override
  String get sub_legalCodeDesc => 'Regras, estatutos e regulamentos de aliança';

  @override
  String get sub_ritualDesc =>
      'Formas prescritas de adoração e cerimônias sagradas';

  @override
  String get sub_procedureDesc =>
      'Orientações práticas e direções passo a passo';

  @override
  String get sub_listInventoryDesc =>
      'Catálogos, censos e registros organizados';

  @override
  String get sub_propheticOracleDesc => 'Mensagens entregues em nome de Deus';

  @override
  String get sub_exhortationDesc =>
      'Discursos que exortam à ação moral e espiritual';

  @override
  String get sub_wisdomTeachingDesc =>
      'Instrução sobre viver com sabedoria e retidão';

  @override
  String get sub_prayerDesc =>
      'Palavras dirigidas a Deus em adoração ou petição';

  @override
  String get sub_dialogueDesc => 'Conversas e trocas entre pessoas';

  @override
  String get sub_epistleDesc =>
      'Mensagens escritas dirigidas a comunidades ou indivíduos';

  @override
  String get sub_apocalypticDiscourseDesc =>
      'Revelações sobre os últimos tempos e o plano de Deus';

  @override
  String get sub_ceremonialSpeechDesc =>
      'Discursos formais para ocasiões oficiais ou sagradas';

  @override
  String get sub_communityMemoryDesc =>
      'Recordações compartilhadas que preservam a identidade do grupo';

  @override
  String get register_intimate => 'Íntimo';

  @override
  String get register_casual => 'Informal / Casual';

  @override
  String get register_consultative => 'Consultivo';

  @override
  String get register_formal => 'Formal / Oficial';

  @override
  String get register_ceremonial => 'Cerimonial';

  @override
  String get register_elderAuthority => 'Ancião / Autoridade';

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
  String get locale_englishSub => 'Inglês';

  @override
  String get locale_portugueseSub => 'Português';

  @override
  String get locale_hindiSub => 'Hindi';

  @override
  String get locale_koreanSub => 'Coreano';

  @override
  String get locale_spanishSub => 'Espanhol';

  @override
  String get locale_bahasaSub => 'Indonésio';

  @override
  String get locale_frenchSub => 'Francês';

  @override
  String get locale_tokPisinSub => 'Tok Pisin';

  @override
  String get locale_swahiliSub => 'Suaíli';

  @override
  String get locale_arabicSub => 'Árabe';

  @override
  String get locale_selectLanguage => 'Escolha Seu Idioma';

  @override
  String get locale_selectLanguageSubtitle =>
      'Você pode alterar isso mais tarde nas configurações do perfil.';

  @override
  String get filter_all => 'Todos';

  @override
  String get filter_pending => 'Pendentes';

  @override
  String get filter_uploaded => 'Enviados';

  @override
  String get filter_needsCleaning => 'Precisa de Limpeza';

  @override
  String get filter_allGenres => 'Todos os gêneros';

  @override
  String get detail_duration => 'Duração';

  @override
  String get detail_size => 'Tamanho';

  @override
  String get detail_format => 'Formato';

  @override
  String get detail_status => 'Status';

  @override
  String get detail_upload => 'Envio';

  @override
  String get detail_uploaded => 'Enviado';

  @override
  String get detail_cleaning => 'Limpeza';

  @override
  String get detail_recorded => 'Gravado';

  @override
  String get detail_retry => 'Tentar novamente';

  @override
  String get detail_notFlagged => 'Não marcado';

  @override
  String get detail_uploadStuck => 'Travado — toque em Tentar novamente';

  @override
  String get detail_uploading => 'Enviando...';

  @override
  String get detail_maxRetries =>
      'Máx. de tentativas — toque em Tentar novamente';

  @override
  String get detail_uploadFailed => 'Falha no Envio';

  @override
  String get detail_pendingRetried => 'Pendente (tentado novamente)';

  @override
  String get detail_notSynced => 'Não sincronizado';

  @override
  String get action_actions => 'Ações';

  @override
  String get action_split => 'Dividir';

  @override
  String get action_flagClean => 'Marcar para Limpeza';

  @override
  String get action_clearFlag => 'Remover Marcação';

  @override
  String get action_move => 'Mover';

  @override
  String get action_delete => 'Excluir';

  @override
  String get projectStats_recordings => 'Gravações';

  @override
  String get projectStats_duration => 'Duração';

  @override
  String get projectStats_members => 'Membros';

  @override
  String get project_active => 'Ativo';

  @override
  String get recording_paused => 'Pausado';

  @override
  String get recording_recording => 'Gravando';

  @override
  String get recording_tapToRecord => 'Toque para Gravar';

  @override
  String get recording_sensitivity => 'Sensibilidade';

  @override
  String get recording_sensitivityLow => 'Baixa';

  @override
  String get recording_sensitivityMed => 'Média';

  @override
  String get recording_sensitivityHigh => 'Alta';

  @override
  String get recording_stopRecording => 'Parar gravação';

  @override
  String get recording_stop => 'Parar';

  @override
  String get recording_resume => 'Retomar';

  @override
  String get recording_pause => 'Pausar';
}
