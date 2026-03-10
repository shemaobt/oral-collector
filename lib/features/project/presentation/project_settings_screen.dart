import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../data/providers/project_provider.dart';
import '../domain/entities/project.dart';

/// Project settings screen where project managers can view/edit project details.
class ProjectSettingsScreen extends ConsumerStatefulWidget {
  const ProjectSettingsScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectSettingsScreen> createState() =>
      _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends ConsumerState<ProjectSettingsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isEdited = false;
  bool _isSaving = false;
  Project? _project;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final repo = ref.read(projectRepositoryProvider);
    try {
      final project = await repo.getProject(widget.projectId);
      if (!mounted) return;
      setState(() {
        _project = project;
        _nameController.text = project.name;
        _descriptionController.text = project.description ?? '';
      });
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (_project == null) return;
    final nameChanged = _nameController.text.trim() != _project!.name;
    final descChanged =
        _descriptionController.text.trim() != (_project!.description ?? '');
    setState(() {
      _isEdited = nameChanged || descChanged;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = <String, dynamic>{};
    final newName = _nameController.text.trim();
    final newDesc = _descriptionController.text.trim();

    if (newName != _project!.name) {
      data['name'] = newName;
    }
    if (newDesc != (_project!.description ?? '')) {
      data['description'] = newDesc.isEmpty ? null : newDesc;
    }

    if (data.isEmpty) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      await ref
          .read(projectNotifierProvider.notifier)
          .updateProject(widget.projectId, data);
      if (!mounted) return;

      // Refresh local project data
      final updatedState = ref.read(projectNotifierProvider);
      final updated =
          updatedState.projects.where((p) => p.id == widget.projectId).firstOrNull;
      if (updated != null) {
        setState(() {
          _project = updated;
          _isEdited = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project updated')),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatDuration(double totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = ((totalSeconds % 3600) ~/ 60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_project == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
          title: const Text('Project Settings'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Project Settings'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Project Info section
            _SectionHeader(title: 'Project Info'),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name field (editable)
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Project Name',
                        prefixIcon: Icon(LucideIcons.folderOpen),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Project name is required';
                        }
                        return null;
                      },
                      onChanged: (_) => _onFieldChanged(),
                    ),
                    const SizedBox(height: 16),

                    // Language (read-only)
                    TextFormField(
                      initialValue: _project!.languageName ?? 'Unknown',
                      decoration: const InputDecoration(
                        labelText: 'Language',
                        prefixIcon: Icon(LucideIcons.globe),
                      ),
                      readOnly: true,
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // Description field (editable)
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(LucideIcons.fileText),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      onChanged: (_) => _onFieldChanged(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Save button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isEdited && !_isSaving ? _save : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.border.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Storage section
            _SectionHeader(title: 'Storage'),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      LucideIcons.mic,
                      color: AppColors.primary,
                    ),
                    title: const Text('Recordings'),
                    trailing: Text(
                      '${_project!.recordingCount}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      LucideIcons.clock,
                      color: AppColors.info,
                    ),
                    title: const Text('Total Duration'),
                    trailing: Text(
                      _formatDuration(_project!.totalDurationSeconds),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      LucideIcons.users,
                      color: AppColors.success,
                    ),
                    title: const Text('Members'),
                    trailing: Text(
                      '${_project!.memberCount}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
