import '../../../core/errors/app_exception.dart';

/// A caught recording-load error is a genuine "not found" only for HTTP 404.
/// Every other failure (network, timeout, server, parse) must surface as a real
/// error instead of being swallowed and rendered as a missing recording
/// (ENG-140 F21).
bool isRecordingNotFound(Object error) =>
    error is AppException && error.statusCode == 404;
