import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oral_collector/shared/widgets/hand_cut_rect.dart';

Color noticeFill(WidgetTester tester, String sentence) =>
    (tester
                .widget<CustomPaint>(
                  find
                      .ancestor(
                        of: find.text(sentence),
                        matching: find.byWidgetPredicate(
                          (w) =>
                              w is CustomPaint &&
                              w.painter is HandCutRectPainter,
                        ),
                      )
                      .first,
                )
                .painter!
            as HandCutRectPainter)
        .fill;
