import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// What a person typed on the confirmation screen before the recording's fate
/// was decided. Not domain data: it is never queried, never synced, and is
/// gone the moment the recording is saved or discarded.
class ConfirmationDraft {
  const ConfirmationDraft({
    required this.title,
    required this.description,
    required this.storytellerId,
  });

  final String title;
  final String description;
  final String? storytellerId;

  /// Nothing worth surviving a process death.
  bool get isBlank =>
      title.isEmpty && description.isEmpty && storytellerId == null;

  Map<String, dynamic> _toJson() => {
    'title': title,
    'description': description,
    'storytellerId': storytellerId,
  };

  static ConfirmationDraft? _fromJson(Map<String, dynamic> json) {
    final draft = ConfirmationDraft(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      storytellerId: json['storytellerId'] as String?,
    );
    return draft.isBlank ? null : draft;
  }
}

/// Keeps confirmation-screen drafts alive across the death of the process.
///
/// Keyed by the recording's audio path — the only identity the confirmation
/// form and the crash-recovery screen already share, on both platforms, and it
/// carries the instant of creation so it is not reused. A single global key
/// would survive process death just as well and be strictly worse: the next
/// recording would open wearing the previous one's title (ENG-518).
///
/// [SharedPreferences] rather than a table: a draft is efemeral and unqueried,
/// so a schema migration would buy nothing, and `shared_preferences_web` backs
/// the same API with `localStorage`, which outlives the browser tab exactly as
/// the native store outlives the process.
class ConfirmationDraftStore {
  const ConfirmationDraftStore();

  static const _keyPrefix = 'com.shema.oralCollector.confirmation_draft.';

  static String _keyFor(String audioPath) => '$_keyPrefix$audioPath';

  Future<void> write(String audioPath, ConfirmationDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(audioPath);
    if (draft.isBlank) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, jsonEncode(draft._toJson()));
  }

  Future<ConfirmationDraft?> read(String audioPath) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(audioPath));
    if (raw == null) return null;
    // A draft is disposable: unreadable stored text opens an empty form rather
    // than taking the screen down with it.
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return ConfirmationDraft._fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  Future<void> clear(String audioPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(audioPath));
  }
}
