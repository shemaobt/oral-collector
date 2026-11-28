import 'package:flutter/material.dart';

void sheetHelperMayOpenRaw(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => const SizedBox(),
  );
  Scaffold.of(context).showBottomSheet((_) => const SizedBox());
}
