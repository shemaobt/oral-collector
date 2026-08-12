import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/l10n/content_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../genre/domain/entities/genre.dart';
import '../../../genre/domain/entities/genre_update.dart';
import '../notifiers/admin_notifier.dart';

class AdminGenreCard extends ConsumerWidget {
  const AdminGenreCard({
    super.key,
    required this.genre,
    required this.onRefresh,
  });

  final Genre genre;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RadiusScale.r16),
      ),
      margin: const EdgeInsets.only(bottom: SpacingScale.s12),
      child: Padding(
        padding: const EdgeInsets.all(SpacingScale.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  child: Icon(
                    LucideIcons.bookOpen,
                    size: 18,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: SpacingScale.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizedGenreName(l10n, genre.name, id: genre.id),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (genre.description != null)
                        Text(
                          localizedGenreDescription(l10n, genre.description!),
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                IconButton(
                  icon: Icon(
                    LucideIcons.pencil,
                    size: 18,
                    color: colors.secondary,
                  ),
                  onPressed: () => _showEditDialog(context, ref),
                  tooltip: l10n.admin_editGenre,
                ),

                IconButton(
                  icon: Icon(LucideIcons.trash2, size: 18, color: colors.error),
                  onPressed: () => _confirmDelete(context, ref),
                  tooltip: l10n.admin_deleteGenre,
                ),

                IconButton(
                  icon: Icon(LucideIcons.plus, size: 18, color: colors.primary),
                  onPressed: () => _showAddSubcategoryDialog(context, ref),
                  tooltip: l10n.admin_addSubcategory,
                ),
              ],
            ),

            if (genre.subcategories.isNotEmpty) ...[
              const SizedBox(height: SpacingScale.s8),
              const Divider(height: 1),
              const SizedBox(height: SpacingScale.s8),
              ...genre.subcategories.map(
                (sub) => Padding(
                  padding: const EdgeInsets.only(
                    left: SpacingScale.s48,
                    bottom: SpacingScale.s4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.cornerDownRight,
                        size: 14,
                        color: colors.border,
                      ),
                      const SizedBox(width: SpacingScale.s8),
                      Expanded(
                        child: Text(
                          localizedSubcategoryName(l10n, sub.name, id: sub.id),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: colors.error,
                        ),
                        onPressed: () => _confirmDeleteSubcategory(
                          context,
                          ref,
                          sub.id,
                          localizedSubcategoryName(l10n, sub.name, id: sub.id),
                        ),
                        tooltip: l10n.admin_deleteSubcategory,
                        iconSize: 16,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: genre.name);
    final descController = TextEditingController(text: genre.description ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.admin_editGenreTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.admin_genreName),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.admin_required
                    : null,
              ),
              const SizedBox(height: SpacingScale.s12),
              TextFormField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: l10n.admin_descriptionOptional,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: colors.primary),
            child: Text(l10n.common_save),
          ),
        ],
      ),
    );

    if (result == true) {
      final newName = nameController.text.trim();
      final newDesc = descController.text.trim();
      final descChanged = newDesc != (genre.description ?? '');

      final update = GenreUpdate(
        name: newName != genre.name ? newName : null,
        description: descChanged && newDesc.isNotEmpty ? newDesc : null,
        clearDescription: descChanged && newDesc.isEmpty,
      );

      if (!update.isEmpty) {
        final success = await ref
            .read(adminNotifierProvider.notifier)
            .updateGenre(genre.id, update);
        if (success && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.admin_genreUpdated)));
        }
      }
    }

    nameController.dispose();
    descController.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.admin_deleteGenreTitle),
        content: Text(l10n.admin_deleteGenreConfirm(genre.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(adminNotifierProvider.notifier)
          .deleteGenre(genre.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.admin_genreDeleted)));
      }
    }
  }

  Future<void> _showAddSubcategoryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.admin_addSubcategoryTo(genre.name)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: InputDecoration(labelText: l10n.admin_subcategoryName),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.admin_required : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.of(context).primary,
            ),
            child: Text(l10n.common_create),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await ref
          .read(adminNotifierProvider.notifier)
          .createSubcategory(
            genreId: genre.id,
            name: nameController.text.trim(),
          );
      if (success && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.admin_subcategoryCreated)));
      }
    }

    nameController.dispose();
  }

  Future<void> _confirmDeleteSubcategory(
    BuildContext context,
    WidgetRef ref,
    String subId,
    String subName,
  ) async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.admin_deleteSubcategory),
        content: Text(l10n.admin_deleteSubcategoryConfirm(subName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(adminNotifierProvider.notifier)
          .deleteSubcategory(subId);
      if (success && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.admin_subcategoryDeleted)));
      }
    }
  }
}
