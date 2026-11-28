import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ShellTab { home, record, recordings, projects, profile, admin }

final tabInUseProvider = StateProvider<ShellTab?>((ref) => null);
