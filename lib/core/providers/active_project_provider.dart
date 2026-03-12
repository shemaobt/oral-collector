import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/project/domain/entities/project.dart';
import '../../features/project/presentation/notifiers/project_notifier.dart';

final activeProjectProvider = Provider<Project?>((ref) {
  return ref.watch(
    projectNotifierProvider.select((state) => state.activeProject),
  );
});
