// Synthetic regression test for the ConsumerStatefulWidget pattern used by
// ConfirmationStep: take ownership of a marker provider in initState, then
// release it in dispose. flutter_riverpod 2.x has two traps a naive impl
// falls into:
//
//   1. `ref.read` inside dispose throws "Cannot use ref after disposed"
//      because Consumer's ref is invalidated *before* State.dispose runs.
//   2. Mutating a provider synchronously in dispose throws "Tried to modify
//      a provider while the widget tree was building" because dispose runs
//      under finalizeTree.
//
// The widget under test mirrors ConfirmationStep's solution (capture the
// StateController in initState, defer the clear with Future.microtask) so a
// regression in the pattern will be caught here even if the integration
// test of ConfirmationStep itself becomes hard to maintain.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _markerProvider = StateProvider<String?>((_) => null);

class _MarkerOwner extends ConsumerStatefulWidget {
  const _MarkerOwner({required this.value});

  final String value;

  @override
  ConsumerState<_MarkerOwner> createState() => _MarkerOwnerState();
}

class _MarkerOwnerState extends ConsumerState<_MarkerOwner> {
  late final StateController<String?> _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(_markerProvider.notifier);
    Future.microtask(() {
      if (!mounted) return;
      _controller.state = widget.value;
    });
  }

  @override
  void dispose() {
    final controller = _controller;
    final owned = widget.value;
    Future.microtask(() {
      if (controller.state == owned) {
        controller.state = null;
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext _) => const SizedBox.shrink();
}

void main() {
  testWidgets(
    'initState taking ownership of a provider does not throw under a '
    'LayoutBuilder (Scaffold)',
    (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: _MarkerOwner(value: 'a')),
          ),
        ),
      );
      // Drain pending microtasks so the deferred state mutation lands.
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(container.read(_markerProvider), 'a');

      // Drain any in-flight microtasks before disposing the container so
      // the addTearDown of a previous container doesn't race a stray clear.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      container.dispose();
    },
  );

  testWidgets(
    'dispose releases the marker without throwing during finalizeTree',
    (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: _MarkerOwner(value: 'b')),
          ),
        ),
      );
      await tester.pump();
      expect(container.read(_markerProvider), 'b');

      // Replace the subtree so the marker owner unmounts and dispose runs
      // under finalizeTree.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
        ),
      );
      // Drain the deferred clear.
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(container.read(_markerProvider), isNull);

      container.dispose();
    },
  );
}
