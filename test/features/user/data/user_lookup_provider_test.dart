import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_notifier.dart';
import 'package:oral_collector/features/sync/presentation/notifiers/sync_state.dart';
import 'package:oral_collector/features/user/data/user_lookup_provider.dart';

class _MockClient extends Mock implements AuthenticatedClient {}

class _FakeSyncNotifier extends SyncNotifier {
  _FakeSyncNotifier({required this.initialOnline});

  final bool initialOnline;

  @override
  SyncState build() => SyncState(isOnline: initialOnline);
}

void main() {
  late _MockClient client;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    client = _MockClient();
  });

  group('userLookupProvider — offline', () {
    test('offline returns null without hitting the API', () async {
      final container = ProviderContainer(
        overrides: [
          authenticatedClientProvider.overrideWithValue(client),
          syncNotifierProvider.overrideWith(
            () => _FakeSyncNotifier(initialOnline: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(userLookupProvider('user-1').future);

      expect(result, isNull);
      verifyNever(() => client.get(any()));
    });

    test('online with 200 returns parsed UserLookup', () async {
      when(() => client.get(any())).thenAnswer(
        (_) async => http.Response(
          '{"id":"user-1","email":"alice@example.com","display_name":"Alice","avatar_url":null}',
          200,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authenticatedClientProvider.overrideWithValue(client),
          syncNotifierProvider.overrideWith(
            () => _FakeSyncNotifier(initialOnline: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(userLookupProvider('user-1').future);

      expect(result, isNotNull);
      expect(result!.id, 'user-1');
      expect(result.label, 'Alice');
    });
  });
}
