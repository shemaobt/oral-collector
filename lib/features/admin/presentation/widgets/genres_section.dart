import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../genre/domain/entities/genre.dart';
import '../notifiers/admin_notifier.dart';
import 'admin_genre_card.dart';

class GenresSection extends ConsumerWidget {
  const GenresSection({
    super.key,
    required this.genres,
    required this.onRefresh,
  });

  final List<Genre> genres;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.admin_genresAndSubcategories,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            FilledButton.icon(
              onPressed: () => _showAddGenreDialog(context, ref),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(l10n.admin_addGenre),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                minimumSize: const Size(0, 48),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (genres.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(l10n.admin_noGenres)),
            ),
          )
        else
          ...genres.map(
            (genre) => AdminGenreCard(genre: genre, onRefresh: onRefresh),
          ),
      ],
    );
  }

  Future<void> _showAddGenreDialog(BuildContext context, WidgetRef ref) async {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.admin_addGenre),
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
              const SizedBox(height: 12),
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
            child: Text(l10n.common_create),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await ref
          .read(adminNotifierProvider.notifier)
          .createGenre(
            name: nameController.text.trim(),
            description: descController.text.trim().isEmpty
                ? null
                : descController.text.trim(),
          );
      if (success && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.admin_genreCreated)));
      }
    }

    nameController.dispose();
    descController.dispose();
  }
}
