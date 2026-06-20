import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/avoid_hardcoded_color.dart';
import 'src/avoid_material_colors.dart';
import 'src/avoid_raw_print.dart';

PluginBase createPlugin() => _ObtLints();

class _ObtLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
    AvoidHardcodedColor(),
    AvoidMaterialColors(),
    AvoidRawPrint(),
  ];
}
