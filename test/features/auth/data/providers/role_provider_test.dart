import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:oral_collector/core/auth/auth_notifier.dart';
import 'package:oral_collector/core/auth/auth_state.dart';
import 'package:oral_collector/core/network/authenticated_client.dart';
import 'package:oral_collector/features/auth/data/providers/role_provider.dart';
import 'package:oral_collector/features/auth/domain/entities/user.dart';

class _MockClient extends Mock implements AuthenticatedClient {}

const _nonAdminAuthState = AuthState(
  currentUser: User(id: 'u-1', email: 'a@b.com', isPlatformAdmin: false),
);

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier([this._initial = _nonAdminAuthState]);

  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

void main() {
  late _MockClient client;

  setUp(() {
    client = _MockClient();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        authenticatedClientProvider.overrideWithValue(client),
        authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  ProviderContainer containerWith({required bool admin}) {
    final container = ProviderContainer(
      overrides: [
        authenticatedClientProvider.overrideWithValue(client),
        authNotifierProvider.overrideWith(
          () => _FakeAuthNotifier(
            AuthState(
              currentUser: User(
                id: 'u-1',
                email: 'a@b.com',
                isPlatformAdmin: admin,
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('parses project roles from a well-formed response', () async {
    when(() => client.get(any())).thenAnswer(
      (_) async => http.Response('{"project_roles": {"p-1": "manager"}}', 200),
    );
    final container = makeContainer();

    await container.read(roleNotifierProvider.notifier).fetchRolesForProjects([
      'p-1',
    ]);

    final state = container.read(roleNotifierProvider);
    expect(state.projectRoles, {'p-1': 'manager'});
    expect(state.isProjectManager('p-1'), isTrue);
  });

  test('degrades to empty roles without throwing when a role value is '
      'malformed', () async {
    when(() => client.get(any())).thenAnswer(
      (_) async => http.Response('{"project_roles": {"p-1": 123}}', 200),
    );
    final container = makeContainer();

    await container.read(roleNotifierProvider.notifier).fetchRolesForProjects([
      'p-1',
    ]);

    final state = container.read(roleNotifierProvider);
    expect(state.projectRoles, isEmpty);
    expect(state.isProjectManager('p-1'), isFalse);
  });

  group('isPlatformAdminProvider', () {
    test('is true when the authenticated user is a platform admin', () {
      final container = containerWith(admin: true);
      expect(container.read(isPlatformAdminProvider), isTrue);
    });

    test('is false when the authenticated user is not a platform admin', () {
      final container = containerWith(admin: false);
      expect(container.read(isPlatformAdminProvider), isFalse);
    });

    test('is false when no user is authenticated', () {
      final container = ProviderContainer(
        overrides: [
          authenticatedClientProvider.overrideWithValue(client),
          authNotifierProvider.overrideWith(
            () => _FakeAuthNotifier(const AuthState()),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(isPlatformAdminProvider), isFalse);
    });
  });

  group('canCreateProjectProvider', () {
    test('is true for a platform admin even without any project roles', () {
      final container = containerWith(admin: true);
      expect(container.read(canCreateProjectProvider), isTrue);
    });

    test('is true for a non-admin who manages at least one project', () async {
      when(() => client.get(any())).thenAnswer(
        (_) async =>
            http.Response('{"project_roles": {"p-1": "manager"}}', 200),
      );
      final container = containerWith(admin: false);
      await container.read(roleNotifierProvider.notifier).fetchRolesForProjects(
        ['p-1'],
      );
      expect(container.read(canCreateProjectProvider), isTrue);
    });

    test('is false for a non-admin with no manager role', () {
      final container = containerWith(admin: false);
      expect(container.read(canCreateProjectProvider), isFalse);
    });
  });
}
