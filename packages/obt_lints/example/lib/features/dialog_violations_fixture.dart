import 'package:flutter/material.dart';

void opensRaw(BuildContext context) {
  // expect_lint: avoid_raw_dialog
  showDialog<void>(context: context, builder: (_) => const SizedBox());
  // expect_lint: avoid_raw_dialog
  showGeneralDialog<void>(
    context: context,
    pageBuilder: (_, _, _) => const SizedBox(),
  );
  // expect_lint: avoid_raw_dialog
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => const SizedBox(),
  );
  // expect_lint: avoid_raw_dialog
  showBottomSheet(context: context, builder: (_) => const SizedBox());
}

void showDialog2(BuildContext context) {}

void opensBenign(BuildContext context) {
  showDialog2(context);
}
