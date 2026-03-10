import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/data/providers/role_provider.dart';
import '../../genre/domain/entities/genre.dart';
import '../data/providers/admin_provider.dart';
import '../data/repositories/admin_repository.dart';

/// Admin dashboard with system-wide stats, projects table, and genre management.
/// Desktop-optimized layout with NavigationRail for section switching.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedSection = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // Admin guard
      final isAdmin = ref.read(roleNotifierProvider.notifier).isPlatformAdmin;
      if (!isAdmin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin access required'),
              backgroundColor: Colors.orange,
            ),
          );
          context.pop();
        }
        return;
      }
      ref.read(adminNotifierProvider.notifier).fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminNotifierProvider);
    final isWide = MediaQuery.of(context).size.width >= 800;

    // Listen for errors
    ref.listen<String?>(
      adminNotifierProvider.select((s) => s.error),
      (prev, next) {
        if (next != null && next != prev) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );

    final sections = [
      const _NavItem(icon: LucideIcons.layoutDashboard, label: 'Overview'),
      const _NavItem(icon: LucideIcons.folderOpen, label: 'Projects'),
      const _NavItem(icon: LucideIcons.bookOpen, label: 'Genres'),
    ];

    Widget body;
    if (adminState.isLoading && adminState.stats == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      switch (_selectedSection) {
        case 0:
          body = _OverviewSection(stats: adminState.stats);
        case 1:
          body = _ProjectsSection(projects: adminState.projects);
        case 2:
          body = _GenresSection(
            genres: adminState.genres,
            onRefresh: () =>
                ref.read(adminNotifierProvider.notifier).fetchAll(),
          );
        default:
          body = const SizedBox.shrink();
      }
    }

    if (isWide) {
      // Desktop: NavigationRail + content
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
          title: const Text('Admin Dashboard'),
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedSection,
              onDestinationSelected: (index) {
                setState(() => _selectedSection = index);
              },
              labelType: NavigationRailLabelType.all,
              destinations: sections
                  .map((s) => NavigationRailDestination(
                        icon: Icon(s.icon),
                        label: Text(s.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(adminNotifierProvider.notifier).fetchAll(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile: Segmented buttons + content
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Admin Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminNotifierProvider.notifier).fetchAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section selector
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: sections
                      .asMap()
                      .entries
                      .map((e) => ButtonSegment<int>(
                            value: e.key,
                            label: Text(e.value.label),
                            icon: Icon(e.value.icon, size: 18),
                          ))
                      .toList(),
                  selected: {_selectedSection},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedSection = selection.first);
                  },
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.1),
                    selectedForegroundColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// =============================================================================
// Overview Section — Stats cards
// =============================================================================

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({this.stats});

  final AdminStats? stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatCardData(
        icon: LucideIcons.folderOpen,
        label: 'Total Projects',
        value: '${stats?.totalProjects ?? 0}',
        color: AppColors.primary,
      ),
      _StatCardData(
        icon: LucideIcons.globe,
        label: 'Languages',
        value: '${stats?.totalLanguages ?? 0}',
        color: AppColors.info,
      ),
      _StatCardData(
        icon: LucideIcons.mic,
        label: 'Recordings',
        value: '${stats?.totalRecordings ?? 0}',
        color: AppColors.success,
      ),
      _StatCardData(
        icon: LucideIcons.clock,
        label: 'Total Hours',
        value: (stats?.totalHours ?? 0).toStringAsFixed(1),
        color: AppColors.secondary,
      ),
      _StatCardData(
        icon: LucideIcons.users,
        label: 'Active Users',
        value: '${stats?.activeUsers ?? 0}',
        color: AppColors.primary,
      ),
    ];

    final isWide = MediaQuery.of(context).size.width >= 800;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map((item) => SizedBox(
                width: isWide ? 200 : double.infinity,
                child: _StatCard(data: item),
              ))
          .toList(),
    );
  }
}

class _StatCardData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: data.color.withValues(alpha: 0.1),
              child: Icon(data.icon, color: data.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    data.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Projects Section — Data table
// =============================================================================

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection({required this.projects});

  final List projects;

  String _formatDuration(double totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = ((totalSeconds % 3600) ~/ 60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No projects found')),
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 800;

    if (isWide) {
      // Desktop: wide DataTable
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Language')),
              DataColumn(label: Text('Members'), numeric: true),
              DataColumn(label: Text('Recordings'), numeric: true),
              DataColumn(label: Text('Duration')),
              DataColumn(label: Text('Created')),
            ],
            rows: projects.map((p) {
              return DataRow(cells: [
                DataCell(Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                )),
                DataCell(Text(p.languageName ?? '—')),
                DataCell(Text('${p.memberCount}')),
                DataCell(Text('${p.recordingCount}')),
                DataCell(Text(_formatDuration(p.totalDurationSeconds))),
                DataCell(Text(_formatDate(p.createdAt))),
              ]);
            }).toList(),
          ),
        ),
      );
    }

    // Mobile: Card list
    return Column(
      children: projects.map<Widget>((p) {
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  p.languageName ?? 'Unknown language',
                  style: TextStyle(color: AppColors.secondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniStat(
                        icon: LucideIcons.users, value: '${p.memberCount}'),
                    const SizedBox(width: 16),
                    _MiniStat(
                        icon: LucideIcons.mic, value: '${p.recordingCount}'),
                    const SizedBox(width: 16),
                    _MiniStat(
                        icon: LucideIcons.clock,
                        value: _formatDuration(p.totalDurationSeconds)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 13, color: AppColors.secondary)),
      ],
    );
  }
}

// =============================================================================
// Genres Section — CRUD table for genres and subcategories
// =============================================================================

class _GenresSection extends ConsumerWidget {
  const _GenresSection({required this.genres, required this.onRefresh});

  final List<Genre> genres;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Genres & Subcategories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            FilledButton.icon(
              onPressed: () => _showAddGenreDialog(context, ref),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Genre'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 48),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (genres.isEmpty)
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No genres found')),
            ),
          )
        else
          ...genres.map((genre) => _GenreCard(
                genre: genre,
                onRefresh: onRefresh,
              )),
      ],
    );
  }

  Future<void> _showAddGenreDialog(BuildContext context, WidgetRef ref) async {
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
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await ref.read(adminNotifierProvider.notifier).createGenre(
            name: nameController.text.trim(),
            description: descController.text.trim().isEmpty
                ? null
                : descController.text.trim(),
          );
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Genre created')),
        );
      }
    }

    nameController.dispose();
    descController.dispose();
  }
}

class _GenreCard extends ConsumerWidget {
  const _GenreCard({required this.genre, required this.onRefresh});

  final Genre genre;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Genre header
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(
                    LucideIcons.bookOpen,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        genre.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (genre.description != null)
                        Text(
                          genre.description!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Edit button
                IconButton(
                  icon: Icon(LucideIcons.pencil,
                      size: 18, color: AppColors.secondary),
                  onPressed: () => _showEditDialog(context, ref),
                  tooltip: 'Edit genre',
                ),
                // Delete button
                IconButton(
                  icon:
                      Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                  onPressed: () => _confirmDelete(context, ref),
                  tooltip: 'Delete genre',
                ),
                // Add subcategory
                IconButton(
                  icon: Icon(LucideIcons.plus,
                      size: 18, color: AppColors.primary),
                  onPressed: () => _showAddSubcategoryDialog(context, ref),
                  tooltip: 'Add subcategory',
                ),
              ],
            ),

            // Subcategories list
            if (genre.subcategories.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...genre.subcategories.map((sub) => Padding(
                    padding: const EdgeInsets.only(left: 48, bottom: 4),
                    child: Row(
                      children: [
                        Icon(LucideIcons.cornerDownRight,
                            size: 14, color: AppColors.border),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sub.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.trash2,
                              size: 16, color: AppColors.error),
                          onPressed: () =>
                              _confirmDeleteSubcategory(context, ref, sub.id, sub.name),
                          tooltip: 'Delete subcategory',
                          iconSize: 16,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController(text: genre.name);
    final descController =
        TextEditingController(text: genre.description ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Genre'),
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
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final data = <String, dynamic>{};
      final newName = nameController.text.trim();
      final newDesc = descController.text.trim();

      if (newName != genre.name) data['name'] = newName;
      if (newDesc != (genre.description ?? '')) {
        data['description'] = newDesc.isEmpty ? null : newDesc;
      }

      if (data.isNotEmpty) {
        final success = await ref
            .read(adminNotifierProvider.notifier)
            .updateGenre(genre.id, data);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Genre updated')),
          );
        }
      }
    }

    nameController.dispose();
    descController.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Genre'),
        content: Text('Delete "${genre.name}" and all its subcategories?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(adminNotifierProvider.notifier)
          .deleteGenre(genre.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Genre deleted')),
        );
      }
    }
  }

  Future<void> _showAddSubcategoryDialog(
      BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Subcategory to ${genre.name}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Subcategory Name'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success =
          await ref.read(adminNotifierProvider.notifier).createSubcategory(
                genreId: genre.id,
                name: nameController.text.trim(),
              );
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subcategory created')),
        );
      }
    }

    nameController.dispose();
  }

  Future<void> _confirmDeleteSubcategory(
      BuildContext context, WidgetRef ref, String subId, String subName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subcategory'),
        content: Text('Delete "$subName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(adminNotifierProvider.notifier)
          .deleteSubcategory(subId);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subcategory deleted')),
        );
      }
    }
  }
}
