// ENG-162 codemod: snap off-grid spacing/radius literals to design tokens.
//
// AST-based (package:analyzer, unresolved parse) so it only touches integer/double
// literals that are direct arguments of the spacing/radius constructors — `fontSize`,
// `Icon(size:)`, durations, counts, and literals inside expressions are structurally
// left alone. The snap map and tie-break live in tool/off_grid_snap_policy.dart.
//
// Usage (run from the package root via `fvm dart run`):
//   dart run tool/snap_off_grid.dart [paths...]            # dry-run report (default)
//   dart run tool/snap_off_grid.dart --write [paths...]    # apply edits in place
//   dart run tool/snap_off_grid.dart --verify [paths...]   # exit 1 if any remain
// Default path is lib/.

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'off_grid_snap_policy.dart';

void main(List<String> args) {
  final write = args.contains('--write');
  final verify = args.contains('--verify');
  final paths = args.where((a) => !a.startsWith('--')).toList();
  if (paths.isEmpty) paths.add('lib');

  final files = _collectDartFiles(paths);
  var totalEdits = 0;
  var totalSkips = 0;
  var filesChanged = 0;
  final byValue = <int, int>{};
  final needImport = <String>[];
  final skipReport = <String>[];

  for (final file in files) {
    final src = file.readAsStringSync();
    final result = parseString(content: src, throwIfDiagnostics: false);
    final visitor = _SnapVisitor(result.lineInfo);
    result.unit.accept(visitor);
    final edits = visitor.edits;
    if (edits.isEmpty && visitor.skips.isEmpty) continue;

    final rel = p.relative(file.path);
    if (edits.isNotEmpty) filesChanged++;
    totalEdits += edits.length;
    for (final e in edits) {
      byValue[e.oldValue] = (byValue[e.oldValue] ?? 0) + 1;
    }
    for (final s in visitor.skips) {
      totalSkips++;
      skipReport.add('$rel:${s.line}  ${s.family}  ${s.value} (out-of-policy)');
    }

    final importMissing =
        edits.isNotEmpty && _tokensImportMissing(result.unit, visitor);
    if (importMissing) needImport.add(rel);

    if (!verify) {
      for (final e in edits) {
        stdout.writeln(
          '$rel:${e.line}  ${e.family}  ${e.oldText} -> ${e.replacement}',
        );
      }
    }

    if (write) {
      // (offset, length, replacement) ops — including the import insertion — all
      // keyed off original-source offsets and applied last-offset-first so every
      // earlier offset stays valid regardless of where the import lands.
      final ops = <(int, int, String)>[
        for (final e in edits) (e.offset, e.length, e.replacement),
      ];
      if (importMissing) {
        final (at, text) = _tokensImportEdit(result.unit, file.path);
        ops.add((at, 0, text));
      }
      ops.sort((a, b) => b.$1.compareTo(a.$1));
      var out = src;
      for (final (offset, length, replacement) in ops) {
        out = out.replaceRange(offset, offset + length, replacement);
      }
      file.writeAsStringSync(out);
    }
  }

  if (verify) {
    if (totalSkips > 0) {
      stdout.writeln(
        'note: $totalSkips out-of-policy off-grid literal(s) left as-is '
        '(spacing 36 is not in the approved spacing map).',
      );
    }
    if (totalEdits > 0) {
      stderr.writeln(
        'off-grid literals still present: $totalEdits in-policy site(s) in '
        '$filesChanged file(s).',
      );
      exit(1);
    }
    stdout.writeln('verify OK: all in-policy off-grid literals normalized.');
    return;
  }

  stdout.writeln('\n--- summary ---');
  stdout.writeln(
    'files: $filesChanged   edits: $totalEdits   '
    'skipped(out-of-policy): $totalSkips',
  );
  final keys = byValue.keys.toList()..sort();
  for (final v in keys) {
    stdout.writeln('  $v -> ${byValue[v]} site(s)');
  }
  if (skipReport.isNotEmpty) {
    stdout.writeln('out-of-policy (left as-is):');
    for (final s in skipReport) {
      stdout.writeln('  $s');
    }
  }
  if (needImport.isNotEmpty) {
    stdout.writeln(
      'files needing a tokens.dart import (${needImport.length}):',
    );
    for (final f in needImport) {
      stdout.writeln('  $f');
    }
  }
  if (write) stdout.writeln('(applied)');
}

List<File> _collectDartFiles(List<String> paths) {
  final out = <File>[];
  for (final path in paths) {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.file) {
      out.add(File(path));
    } else if (type == FileSystemEntityType.directory) {
      for (final e in Directory(path).listSync(recursive: true)) {
        if (e is File && e.path.endsWith('.dart')) out.add(e);
      }
    }
  }
  return out.where((f) => !_excluded(f.path)).toList();
}

bool _excluded(String path) {
  final norm = p.normalize(path);
  return norm.endsWith('.g.dart') ||
      norm.endsWith('.freezed.dart') ||
      norm.contains('${p.separator}core${p.separator}theme${p.separator}') ||
      norm.contains('${p.separator}l10n${p.separator}');
}

/// Named arguments that always denote spacing, on any widget (Wrap/Flex/GridView).
const _spacingLabels = {
  'spacing',
  'runSpacing',
  'mainAxisSpacing',
  'crossAxisSpacing',
};

class _Edit {
  _Edit({
    required this.offset,
    required this.length,
    required this.replacement,
    required this.line,
    required this.oldText,
    required this.oldValue,
    required this.family,
  });

  final int offset;
  final int length;
  final String replacement;
  final int line;
  final String oldText;
  final int oldValue;
  final String family; // 'spacing' | 'radius'
}

class _Skip {
  _Skip({required this.line, required this.value, required this.family});
  final int line;
  final int value;
  final String family;
}

class _SnapVisitor extends RecursiveAstVisitor<void> {
  _SnapVisitor(this.lineInfo);

  final LineInfo lineInfo;
  final List<_Edit> edits = [];
  final List<_Skip> skips = [];
  bool usedSpacing = false;
  bool usedRadius = false;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _handle(node.constructorName.toSource(), node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  // Without `const`/`new`, the unresolved parser models constructor calls like
  // `BorderRadius.circular(34)` / `EdgeInsets.all(6)` as method invocations.
  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    final cname = target == null
        ? node.methodName.name
        : '${target.toSource()}.${node.methodName.name}';
    _handle(cname, node.argumentList);
    super.visitMethodInvocation(node);
  }

  void _handle(String cname, ArgumentList argList) {
    final kind = _classify(cname);
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final label = arg.name.label.name;
        if (_spacingLabels.contains(label)) {
          _trySpacing(arg.expression);
        } else if (kind == 'edgeinsets') {
          _trySpacing(arg.expression);
        } else if (kind == 'sizedbox' &&
            (label == 'width' || label == 'height' || label == 'dimension')) {
          _trySpacing(arg.expression);
        }
      } else if (kind == 'radius') {
        _tryRadius(arg);
      } else if (kind == 'edgeinsets' || kind == 'gap' || kind == 'sizedbox') {
        _trySpacing(arg);
      }
    }
  }

  String? _classify(String cname) {
    if (cname == 'Radius.circular' ||
        cname == 'Radius.elliptical' ||
        cname == 'BorderRadius.circular' ||
        cname == 'BorderRadiusDirectional.circular') {
      return 'radius';
    }
    final head = cname.split('.').first;
    if (head == 'EdgeInsets' || head == 'EdgeInsetsDirectional') {
      return 'edgeinsets';
    }
    if (head == 'SizedBox') return 'sizedbox';
    if (head == 'Gap' || head == 'SliverGap' || head == 'MaxGap') return 'gap';
    return null;
  }

  void _trySpacing(Expression e) {
    final v = _offGridIntOf(e);
    if (v == null) return;
    if (!kSpacingSnap.containsKey(v)) {
      _recordSkip(e, v, 'spacing');
      return;
    }
    usedSpacing = true;
    _add(e, v, 'spacing', 'SpacingScale.s${kSpacingSnap[v]}');
  }

  void _tryRadius(Expression e) {
    final v = _offGridIntOf(e);
    if (v == null) return;
    if (!kRadiusSnap.containsKey(v)) {
      _recordSkip(e, v, 'radius');
      return;
    }
    usedRadius = true;
    _add(e, v, 'radius', 'RadiusScale.r${kRadiusSnap[v]}');
  }

  void _recordSkip(Expression e, int value, String family) {
    skips.add(
      _Skip(
        line: lineInfo.getLocation(e.offset).lineNumber,
        value: value,
        family: family,
      ),
    );
  }

  void _add(Expression e, int oldValue, String family, String repl) {
    edits.add(
      _Edit(
        offset: e.offset,
        length: e.length,
        replacement: repl,
        line: lineInfo.getLocation(e.offset).lineNumber,
        oldText: e.toSource(),
        oldValue: oldValue,
        family: family,
      ),
    );
  }

  int? _offGridIntOf(Expression e) {
    if (e is IntegerLiteral && e.value != null) {
      return kOffGridValues.contains(e.value) ? e.value : null;
    }
    if (e is DoubleLiteral) {
      final v = e.value;
      if (v == v.truncateToDouble() && kOffGridValues.contains(v.toInt())) {
        return v.toInt();
      }
    }
    return null;
  }
}

bool _tokensImportMissing(CompilationUnit unit, _SnapVisitor v) {
  var hasTokens = false;
  var hasSpacing = false;
  var hasRadii = false;
  for (final d in unit.directives) {
    if (d is! ImportDirective) continue;
    final uri = d.uri.stringValue ?? '';
    if (uri.endsWith('theme/tokens.dart')) hasTokens = true;
    if (uri.endsWith('theme/app_spacing.dart')) hasSpacing = true;
    if (uri.endsWith('theme/app_radii.dart')) hasRadii = true;
  }
  final spacingOk = !v.usedSpacing || hasTokens || hasSpacing;
  final radiusOk = !v.usedRadius || hasTokens || hasRadii;
  return !(spacingOk && radiusOk);
}

(int, String) _tokensImportEdit(CompilationUnit unit, String filePath) {
  final parts = p.split(filePath);
  final libIdx = parts.lastIndexOf('lib');
  final libDir = p.joinAll(parts.sublist(0, libIdx + 1));
  final relUri = p.relative(
    p.join(libDir, 'core', 'theme', 'tokens.dart'),
    from: p.dirname(filePath),
  );
  final line = "import '$relUri';\n";

  final imports = unit.directives.whereType<ImportDirective>().toList();
  // Insert alphabetically among relative imports; else after the last import.
  ImportDirective? insertBefore;
  ImportDirective? lastRelative;
  for (final imp in imports) {
    final uri = imp.uri.stringValue ?? '';
    if (uri.startsWith('.')) {
      lastRelative = imp;
      if (insertBefore == null && uri.compareTo(relUri) > 0) insertBefore = imp;
    }
  }
  final int at;
  if (insertBefore != null) {
    at = insertBefore.offset;
  } else if (lastRelative != null) {
    at = lastRelative.end + 1; // after the trailing newline
  } else if (imports.isNotEmpty) {
    at = imports.last.end + 1;
  } else {
    at = 0;
  }
  return (at, line);
}
