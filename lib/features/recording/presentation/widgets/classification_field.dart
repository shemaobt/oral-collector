import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/l10n/content_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../genre/domain/entities/genre.dart';
import '../../../storyteller/domain/entities/storyteller.dart';
import '../../../storyteller/presentation/widgets/storyteller_picker.dart';
import '../../domain/entities/register.dart';

enum _FieldKind { genre, subcategory, register }

class ClassificationField extends StatelessWidget {
  const ClassificationField._({
    super.key,
    required _FieldKind kind,
    required this.value,
    required this.onChanged,
    required this.hasError,
    this.genres,
    this.genreId,
    this.dense = true,
  }) : _kind = kind;

  factory ClassificationField.genre({
    Key? key,
    required String? value,
    required ValueChanged<String?> onChanged,
    required List<Genre> genres,
    bool hasError = false,
    bool dense = true,
  }) {
    return ClassificationField._(
      key: key,
      kind: _FieldKind.genre,
      value: value,
      onChanged: onChanged,
      hasError: hasError,
      genres: genres,
      dense: dense,
    );
  }

  factory ClassificationField.subcategory({
    Key? key,
    required String? value,
    required ValueChanged<String?> onChanged,
    required List<Genre> genres,
    required String? genreId,
    bool hasError = false,
    bool dense = true,
  }) {
    return ClassificationField._(
      key: key,
      kind: _FieldKind.subcategory,
      value: value,
      onChanged: onChanged,
      hasError: hasError,
      genres: genres,
      genreId: genreId,
      dense: dense,
    );
  }

  factory ClassificationField.register({
    Key? key,
    required String? value,
    required ValueChanged<String?> onChanged,
    bool hasError = false,
    bool dense = true,
  }) {
    return ClassificationField._(
      key: key,
      kind: _FieldKind.register,
      value: value,
      onChanged: onChanged,
      hasError: hasError,
      dense: dense,
    );
  }

  final _FieldKind _kind;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool hasError;
  final List<Genre>? genres;
  final String? genreId;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = AppColors.of(context);

    switch (_kind) {
      case _FieldKind.genre:
        return _buildDropdown(
          context: context,
          colors: colors,
          items: (genres ?? [])
              .map(
                (g) => DropdownMenuItem(
                  value: g.id,
                  child: Text(
                    localizedGenreName(l10n, g.name),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          hint: l10n.moveCategory_genre,
          icon: LucideIcons.tag,
        );
      case _FieldKind.subcategory:
        final genre = (genres ?? []).where((g) => g.id == genreId).firstOrNull;
        if (genreId == null) {
          return _buildPlaceholder(
            context,
            colors,
            icon: LucideIcons.tags,
            label: l10n.moveCategory_subcategory,
          );
        }
        if (genre == null || genre.subcategories.isEmpty) {
          return _buildPlaceholder(
            context,
            colors,
            icon: LucideIcons.tags,
            label: '—',
          );
        }
        return _buildDropdown(
          context: context,
          colors: colors,
          items: genre.subcategories
              .map(
                (s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(
                    localizedSubcategoryName(l10n, s.name),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          hint: l10n.moveCategory_subcategory,
          icon: LucideIcons.tags,
        );
      case _FieldKind.register:
        return _buildDropdown(
          context: context,
          colors: colors,
          items: kRegisters
              .map(
                (r) => DropdownMenuItem(
                  value: r.id,
                  child: Text(
                    localizedRegisterName(l10n, r.name),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          hint: l10n.classify_register,
          icon: LucideIcons.mic,
        );
    }
  }

  Widget _buildDropdown({
    required BuildContext context,
    required AppColorSet colors,
    required List<DropdownMenuItem<String>> items,
    required String hint,
    required IconData icon,
  }) {
    final l10n = AppLocalizations.of(context);
    final effective = items.any((i) => i.value == value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: effective,
      isExpanded: true,
      isDense: dense,
      icon: Icon(LucideIcons.chevronDown, size: 16, color: colors.secondary),
      hint: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.secondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              hint,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.foreground.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
      decoration: InputDecoration(
        isDense: dense,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        errorText: hasError ? l10n.import_fieldRequired : null,
        errorStyle: const TextStyle(fontSize: 10, height: 0.8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError
                ? colors.error
                : colors.border.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? colors.error : colors.accent,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.error),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildPlaceholder(
    BuildContext context,
    AppColorSet colors, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceAlt.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: colors.foreground.withValues(alpha: 0.35),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colors.foreground.withValues(alpha: 0.45),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class StorytellerFieldCell extends ConsumerWidget {
  const StorytellerFieldCell({
    super.key,
    required this.projectId,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  final String projectId;
  final Storyteller? selected;
  final ValueChanged<Storyteller?> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!compact) {
      return StorytellerPicker(
        projectId: projectId,
        selected: selected,
        onChanged: onChanged,
      );
    }

    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return InkWell(
      onTap: () async {
        final result = await showStorytellerPickerSheet(
          context,
          projectId: projectId,
        );
        if (result != null) onChanged(result);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.user, size: 14, color: colors.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selected?.name ?? l10n.storyteller_selectHint,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected == null
                      ? colors.foreground.withValues(alpha: 0.45)
                      : colors.foreground,
                  fontWeight: selected == null
                      ? FontWeight.w400
                      : FontWeight.w500,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronDown,
              size: 14,
              color: colors.foreground.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
