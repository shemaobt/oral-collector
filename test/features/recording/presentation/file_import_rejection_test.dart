import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/presentation/file_import_rejection.dart';
import 'package:oral_collector/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('single tooLarge uses tooLarge-specific message', () {
    final rejects = [
      const RejectedFile(name: 'big.wav', reason: RejectionReason.tooLarge),
    ];
    final message = localizeRejectionGroup(l10n, rejects);
    expect(message, contains('500 MB'));
    expect(message, contains('big.wav'));
  });

  test('single unsupportedCodec uses codec-specific message', () {
    final rejects = [
      const RejectedFile(
        name: 'voice.wav',
        reason: RejectionReason.unsupportedCodec,
        codec: 'mulaw',
      ),
    ];
    final message = localizeRejectionGroup(l10n, rejects);
    expect(message, contains('unsupported'));
    expect(message, contains('voice.wav'));
    expect(message, contains('PCM WAV or M4A'));
  });

  test('single unreadableContainer uses unreadable message', () {
    final rejects = [
      const RejectedFile(
        name: 'bad.wav',
        reason: RejectionReason.unreadableContainer,
      ),
    ];
    final message = localizeRejectionGroup(l10n, rejects);
    expect(message, contains('unreadable'));
    expect(message, contains('bad.wav'));
  });

  test('mixed reasons fall back to generic message', () {
    final rejects = [
      const RejectedFile(name: 'a.wav', reason: RejectionReason.tooLarge),
      const RejectedFile(
        name: 'b.wav',
        reason: RejectionReason.unreadableContainer,
      ),
    ];
    final message = localizeRejectionGroup(l10n, rejects);
    expect(message, contains('a.wav'));
    expect(message, contains('b.wav'));
  });

  test('empty extension uses generic message', () {
    final rejects = [
      const RejectedFile(
        name: 'weird',
        reason: RejectionReason.unsupportedExtension,
      ),
    ];
    final message = localizeRejectionGroup(l10n, rejects);
    expect(message, contains('weird'));
  });

  test('plural count handled for tooLarge', () {
    final rejects = List.generate(
      3,
      (i) => RejectedFile(name: 'f$i.wav', reason: RejectionReason.tooLarge),
    );
    final message = localizeRejectionGroup(l10n, rejects);
    expect(message, contains('3'));
  });
}
