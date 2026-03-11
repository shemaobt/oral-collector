import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Genres & Subcategories',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            FilledButton.icon(
              onPressed: () => _showAddGenreDialog(context, ref),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Genre'),
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
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No genres found')),
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
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Genre'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Genre Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: colors.primary),
            child: const Text('Create'),
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
        ).showSnackBar(const SnackBar(content: Text('Genre created')));
      }
    }

    nameController.dispose();
    descController.dispose();
  }
}
