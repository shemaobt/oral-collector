/// Whether a local row may be erased because the server no longer has it.
///
/// Only a recording the server acknowledged can be *missing* from it: the
/// upload writes status and server id together, so anything still local,
/// uploading or failed may never have made the round trip and this device may
/// hold the only copy of the audio (ENG-45, after the loss in PR #193).
bool canEraseAsDeletedOnServer({
  required String? serverId,
  required String uploadStatus,
}) =>
    serverId != null &&
    serverId.isNotEmpty &&
    const {'uploaded', 'verified'}.contains(uploadStatus);
