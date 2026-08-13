/// Whether the server demonstrably holds this recording.
///
/// The upload writes status and server id together, so anything still local,
/// uploading or failed may never have made the round trip and this device may
/// hold the only copy of the audio (ENG-45, after the loss in PR #193).
///
/// Two callers ask this same factual question for different reasons, and it is
/// deliberately one definition: the heal paths pair it with a confirmed 404
/// before erasing a row (only a recording the server acknowledged can be
/// *missing* from it), and `SyncNotifier.clearLocalCache` uses it alone to
/// decide which local copies are safe to discard (ENG-407). Cloning the
/// condition for the second caller was rejected — a predicate that guards
/// against losing audio drifts the moment there are two of it.
bool serverHasRecording({
  required String? serverId,
  required String uploadStatus,
}) =>
    serverId != null &&
    serverId.isNotEmpty &&
    const {'uploaded', 'verified'}.contains(uploadStatus);
