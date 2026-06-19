import '../domain/entities/local_recording_entity.dart';
import '../domain/entities/server_recording.dart';
import 'local_recording_to_entity.dart';
import 'server_to_local_recording.dart';

/// Builds the row-decoupled [LocalRecordingEntity] straight from a
/// [ServerRecording] by composing [serverRecordingToLocal] and
/// [localRecordingToEntity], so the server → entity projection cannot diverge
/// from the row mappers. The trim editor's load path uses this for recordings
/// that live only on the server. See ENG-202.
LocalRecordingEntity serverRecordingToEntity(ServerRecording server) =>
    localRecordingToEntity(serverRecordingToLocal(server));
