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
  _FakeSyncNotifier({required bool initialOnline})
    : _initialOnline = initialOnline;

  final bool _initialOnline;

  @override
  SyncState build() => SyncState(isOnline: _initialOnline);

  void setOnline(bool online) {
    state = state.copyWith(isOnline: online);
  }
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

  group('userLookupProvider — connectivity transitions', () {
    test(
      'once resolved online, going offline does NOT invalidate the cached value',
      () async {
        when(() => client.get(any())).thenAnswer(
          (_) async => http.Response(
            '{"id":"user-1","email":"alice@example.com","display_name":"Alice","avatar_url":null}',
            200,
          ),
        );

        final fakeSync = _FakeSyncNotifier(initialOnline: true);
        final container = ProviderContainer(
          overrides: [
            authenticatedClientProvider.overrideWithValue(client),
            syncNotifierProvider.overrideWith(() => fakeSync),
          ],
        );
        addTearDown(container.dispose);

        final first = await container.read(userLookupProvider('user-1').future);
        expect(first?.id, 'user-1');
        verify(() => client.get(any())).called(1);

        // Going offline must NOT rebuild the provider.
        fakeSync.setOnline(false);
        await Future<void>.delayed(Duration.zero);

        final cached = container.read(userLookupProvider('user-1'));
        expect(
          cached.value?.id,
          'user-1',
          reason: 'cached value should survive online → offline transition',
        );
        verifyNoMoreInteractions(client);
      },
    );

    test(
      'going offline → online invalidates the provider and re-fetches',
      () async {
        when(() => client.get(any())).thenAnswer(
          (_) async => http.Response(
            '{"id":"user-1","email":"alice@example.com","display_name":"Alice","avatar_url":null}',
            200,
          ),
        );

        final fakeSync = _FakeSyncNotifier(initialOnline: false);
        final container = ProviderContainer(
          overrides: [
            authenticatedClientProvider.overrideWithValue(client),
            syncNotifierProvider.overrideWith(() => fakeSync),
          ],
        );
        addTearDown(container.dispose);

        // Keep the provider alive across rebuilds.
        final sub = container.listen(
          userLookupProvider('user-1'),
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        final first = await container.read(userLookupProvider('user-1').future);
        expect(first, isNull);
        verifyNever(() => client.get(any()));

        // Flip online — listener inside the provider should invalidate self.
        fakeSync.setOnline(true);
        await Future<void>.delayed(Duration.zero);

        final second = await container.read(
          userLookupProvider('user-1').future,
        );
        expect(second?.id, 'user-1');
        verify(() => client.get(any())).called(1);
      },
    );
  });
}
