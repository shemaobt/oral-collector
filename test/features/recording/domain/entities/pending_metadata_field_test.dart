/// The metadata outbox stores *which* fields are owed, never their values
/// (ENG-403), so this codec is the whole persisted vocabulary. It rides a Drift
/// text column, which means it has to survive a row written by another build:
/// a token this build has never heard of, or text that is not JSON at all.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/features/recording/domain/entities/pending_metadata_field.dart';

void main() {
  group('encode/decode', () {
    test('round-trips every field', () {
      final all = PendingMetadataField.values.toSet();
      expect(
        decodePendingMetadataFields(encodePendingMetadataFields(all)),
        all,
      );
    });

    test('encodes to a stable order regardless of insertion order', () {
      // The encoded text lands in a column the watch stream diffs; two rows
      // owing the same fields must read as equal, not merely equivalent.
      const a = {
        PendingMetadataField.cleaningStatus,
        PendingMetadataField.title,
      };
      const b = {
        PendingMetadataField.title,
        PendingMetadataField.cleaningStatus,
      };
      expect(encodePendingMetadataFields(a), encodePendingMetadataFields(b));
    });

    test('the empty set is the default column value', () {
      expect(encodePendingMetadataFields(const {}), '[]');
      expect(decodePendingMetadataFields('[]'), isEmpty);
    });

    test('drops a token this build does not know', () {
      // A newer build may name a field this one cannot send. Dropping it keeps
      // the fields we *can* send instead of failing the whole row.
      expect(decodePendingMetadataFields('["title","teleportation"]'), {
        PendingMetadataField.title,
      });
    });

    test('reads unparseable text as owing nothing', () {
      // Losing the pendency costs one un-pushed edit; throwing here would take
      // the recording down with it on every read.
      expect(decodePendingMetadataFields('not json'), isEmpty);
      expect(decodePendingMetadataFields('{"title":true}'), isEmpty);
      expect(decodePendingMetadataFields(''), isEmpty);
    });
  });
}
