import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ShellTab { home, record, recordings, projects, profile, admin }

final tabInUseProvider = StateProvider<ShellTab?>((ref) => null);

void onReturnTo(WidgetRef ref, ShellTab tab, void Function() refresh) {
  ref.listen(tabInUseProvider, (was, now) {
    if (was != null && now == tab) refresh();
  });
}
