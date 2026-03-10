import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/invite_dialog.dart';
import '../../auth/data/providers/auth_provider.dart';
import '../../auth/data/providers/role_provider.dart';
import '../data/providers/member_provider.dart';
import '../data/providers/project_provider.dart';
import '../domain/entities/project.dart';
import '../domain/entities/project_member.dart';

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

  /// Whether the current user can manage this project (PM or platform admin).
  bool get _isManager =>
      ref.read(roleNotifierProvider.notifier).canManageProject(widget.projectId);

  @override
  void initState() {
    super.initState();
    _loadProject();
    Future.microtask(() async {
      await ref
          .read(roleNotifierProvider.notifier)
          .fetchRoleForProject(widget.projectId);
      if (!mounted) return;
      // Non-managers cannot access this screen
      if (!_isManager) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have permission to manage this project'),
            backgroundColor: Colors.orange,
          ),
        );
        context.pop();
        return;
      }
      ref
          .read(memberNotifierProvider.notifier)
          .fetchMembers(widget.projectId);
    });
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

  Future<void> _confirmRemoveMember(ProjectMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Remove ${member.displayName ?? member.email} from this project?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(memberNotifierProvider.notifier)
        .removeMember(widget.projectId, member.userId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member removed')),
      );
    } else {
      final error = ref.read(memberNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to remove member'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showInviteDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => InviteDialog(projectId: widget.projectId),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite sent successfully')),
      );
      // Refresh member list
      ref
          .read(memberNotifierProvider.notifier)
          .fetchMembers(widget.projectId);
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
                    // Name field (editable only for managers)
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Project Name',
                        prefixIcon: Icon(LucideIcons.folderOpen),
                      ),
                      readOnly: !_isManager,
                      enabled: _isManager,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Project name is required';
                        }
                        return null;
                      },
                      onChanged: _isManager ? (_) => _onFieldChanged() : null,
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

                    // Description field (editable only for managers)
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(LucideIcons.fileText),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      readOnly: !_isManager,
                      enabled: _isManager,
                      onChanged: _isManager ? (_) => _onFieldChanged() : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Save button (managers only)
            if (_isManager) SizedBox(
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
            if (_isManager) const SizedBox(height: 24),
            if (!_isManager) const SizedBox(height: 16),

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
            const SizedBox(height: 24),

            // Members section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionHeader(title: 'Members'),
                if (_isManager)
                  TextButton.icon(
                    onPressed: _showInviteDialog,
                    icon: const Icon(LucideIcons.userPlus, size: 16),
                    label: const Text('Invite'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _MemberList(
              projectId: widget.projectId,
              onRemove: _isManager ? _confirmRemoveMember : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberList extends ConsumerWidget {
  const _MemberList({
    required this.projectId,
    this.onRemove,
  });

  final String projectId;
  final void Function(ProjectMember member)? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberState = ref.watch(memberNotifierProvider);

    if (memberState.isLoading && memberState.members.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (memberState.members.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No members yet'),
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < memberState.members.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _MemberTile(
              member: memberState.members[i],
              onRemove: onRemove != null
                  ? () => onRemove!(memberState.members[i])
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    this.onRemove,
  });

  final ProjectMember member;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Text(
          (member.displayName ?? member.email)
              .substring(0, 1)
              .toUpperCase(),
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(
        member.displayName ?? member.email,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: member.displayName != null
          ? Text(
              member.email,
              style: theme.textTheme.bodySmall,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoleBadge(role: member.role),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                LucideIcons.userMinus,
                size: 18,
                color: AppColors.error,
              ),
              onPressed: onRemove,
              tooltip: 'Remove member',
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isManager = role == 'project_manager';
    final label = isManager ? 'PM' : 'User';
    final color = isManager ? AppColors.primary : AppColors.info;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
