import 'package:flutter/widgets.dart';

class PrintedShadowScope extends InheritedWidget {
  const PrintedShadowScope({super.key, required super.child});

  static bool paints(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PrintedShadowScope>() != null;

  @override
  bool updateShouldNotify(PrintedShadowScope old) => false;
}
