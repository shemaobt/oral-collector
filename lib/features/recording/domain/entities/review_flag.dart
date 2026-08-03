import 'dart:convert';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/serialization/parse_list.dart';
import '../../../../core/serialization/safe_read.dart';

/// One thing a recording still owes, as the server reports it (ENG-374).
///
/// [code] and [origin] are free strings, not enums, because the server may
/// start sending a code this build has never heard of. Value equality is
/// hand-written so a list of these compares by content — the recording entity
/// rides a `.distinct()` stream that would otherwise rebuild on every emission.
class ReviewFlag {
  final String code;
  final String origin;

  const ReviewFlag({required this.code, required this.origin});

  factory ReviewFlag.fromJson(Map<String, dynamic> json) => ReviewFlag(
    code: readString(json, 'code'),
    origin: readString(json, 'origin'),
  );

  Map<String, dynamic> toJson() => {'code': code, 'origin': origin};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewFlag && other.code == code && other.origin == origin);

  @override
  int get hashCode => Object.hash(code, origin);
}

/// Reads the flags back off a Drift row. A row written by an older build, or
/// one whose text is no longer valid JSON, reads as "owes nothing" rather than
/// taking the recording down with it — the flags are advisory, and losing them
/// must not cost the user the recording.
///
/// Unlike every other `parseList` call site, this one passes no `onSkip`
/// reporter (ENG-166). The repository that reads the row holds only the
/// database, and threading an `ErrorReporter` down to it for a corrupted-row
/// read is a wide change for a narrow signal. The omission is deliberate, not
/// an oversight.
List<ReviewFlag> decodeReviewFlags(String json) {
  if (json.isEmpty) return const [];
  try {
    return List.unmodifiable(
      parseList(
        jsonDecode(json),
        ReviewFlag.fromJson,
        context: 'LocalRecording.reviewFlags',
      ),
    );
  } on FormatException {
    return const [];
  } on ParseException {
    return const [];
  }
}

String encodeReviewFlags(List<ReviewFlag> flags) =>
    jsonEncode(flags.map((f) => f.toJson()).toList());
