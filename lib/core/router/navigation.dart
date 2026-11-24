import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/recording/presentation/notifiers/recording_session_notifier.dart';

Future<T?> openScreen<T>(BuildContext context, WidgetRef ref, String location) {
  if (ref.read(isWebPlatformProvider)) {
    context.go(location);
    return Future.value();
  }
  return context.push<T>(location);
}

void popOrGo(BuildContext context, String fallback) {
  if (context.canPop()) {
    unawaited(Navigator.of(context).maybePop());
  } else {
    context.go(fallback);
  }
}
