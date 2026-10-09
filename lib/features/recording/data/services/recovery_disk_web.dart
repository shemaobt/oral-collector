import '../../../../core/database/app_database.dart';
import '../repositories/recording_session_repository.dart';

typedef DocumentsPathResolver = Future<String> Function();

/// No navegador não existe nenhuma das duas coisas que esta classe faz.
///
/// Os segmentos são do gravador segmentado, que é do aparelho: no navegador a
/// captura produz um blob único, escrito no armazenamento de uma vez no stop.
/// Não há arquivo em voo com cabeçalho por consertar, e não há diretório para
/// listar — o armazenamento é um keyspace plano cuja única leitura é a da
/// faxina.
///
/// As respostas são as honestas para "não há nenhum", não desistências: uma
/// sessão do navegador é decidida pela âncora, e a âncora é consultada pelo
/// mesmo predicado nas duas plataformas.
class RecoveryDisk {
  const RecoveryDisk({DocumentsPathResolver? documentsPath});

  Future<void> repairInFlightSegments(
    RecordingSession session,
    RecordingSessionRepository repo,
  ) async {}

  Future<bool> hasOrphanSegmentFiles(String sessionId) async => false;
}
