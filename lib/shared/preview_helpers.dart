import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';

export 'package:flutter/widget_previews.dart' show Preview;

Widget previewWrapper(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

PreviewThemeData previewTheme() => PreviewThemeData(
  materialLight: AppTheme.lightTheme,
  materialDark: AppTheme.darkTheme,
);
