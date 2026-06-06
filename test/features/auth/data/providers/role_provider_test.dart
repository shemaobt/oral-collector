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

class _FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    currentUser: User(id: 'u-1', email: 'a@b.com', isPlatformAdmin: false),
  );
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
}
