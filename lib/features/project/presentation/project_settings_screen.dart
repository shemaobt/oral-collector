import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/invite_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../auth/data/providers/role_provider.dart';
import '../data/providers.dart';
import 'notifiers/member_notifier.dart';
import 'notifiers/project_notifier.dart';
import '../domain/entities/project.dart';
import '../domain/entities/project_member.dart';
import 'widgets/member_list.dart';
import 'widgets/project_settings_header.dart';

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

  bool get _isManager => ref
      .read(roleNotifierProvider.notifier)
      .canManageProject(widget.projectId);

  @override
  void initState() {
    super.initState();
    _loadProject();
    Future.microtask(() async {
      await ref
          .read(roleNotifierProvider.notifier)
          .fetchRoleForProject(widget.projectId);
      if (!mounted) return;
      ref.read(memberNotifierProvider.notifier).fetchMembers(widget.projectId);
    });
  }

  Future<void> _loadProject() async {
    final repo = ref.read(projectRepositoryProvider);
    try {
      final results = await Future.wait([
        repo.getProject(widget.projectId),
        repo.getProjectStats(widget.projectId),
      ]);
      if (!mounted) return;

      final project = results[0] as Project;
      final stats = results[1] as Map<String, dynamic>;

      final recordingCount =
          (stats['total_recordings'] as num?)?.toInt() ??
          project.recordingCount;
      final totalDuration =
          (stats['total_duration_seconds'] as num?)?.toDouble() ??
          project.totalDurationSeconds;

      final languages = ref.read(projectNotifierProvider).languages;
      final lang = languages
          .where((l) => l.id == project.languageId)
          .firstOrNull;

      final enriched = Project(
        id: project.id,
        name: project.name,
        languageId: project.languageId,
        languageName: lang?.name ?? project.languageName,
        languageCode: lang?.code ?? project.languageCode,
        description: project.description,
        memberCount: project.memberCount,
        recordingCount: recordingCount,
        totalDurationSeconds: totalDuration,
        createdAt: project.createdAt,
      );

      setState(() {
        _project = enriched;
        _nameController.text = enriched.name;
        _descriptionController.text = enriched.description ?? '';
      });
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.of(context).error,
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

      final updatedState = ref.read(projectNotifierProvider);
      final updated = updatedState.projects
          .where((p) => p.id == widget.projectId)
          .firstOrNull;
      if (updated != null) {
        setState(() {
          _project = updated;
          _isEdited = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).projectSettings_updated),
        ),
      );
    } on ForbiddenException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).projectSettings_noPermission,
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.of(context).error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmRemoveMember(ProjectMember member) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.projectSettings_removeMember),
        content: Text(
          l10n.projectSettings_removeMemberConfirm(
            member.displayName ?? member.email,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.of(context).error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.common_remove),
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
        SnackBar(content: Text(l10n.projectSettings_memberRemoved)),
      );
    } else {
      final error = ref.read(memberNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? l10n.projectSettings_memberRemoveFailed),
          backgroundColor: AppColors.of(context).error,
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
        SnackBar(
          content: Text(
            AppLocalizations.of(context).projectSettings_inviteSent,
          ),
        ),
      );
      ref.read(memberNotifierProvider.notifier).fetchMembers(widget.projectId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final memberState = ref.watch(memberNotifierProvider);
    final memberCount = memberState.members.isNotEmpty
        ? memberState.members.length
        : _project?.memberCount ?? 0;

    if (_project == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
          title: Text(l10n.projectSettings_title),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final detailsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isManager) ...[
          Text(
            l10n.projectSettings_details,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.project_projectName,
              prefixIcon: const Icon(LucideIcons.folderOpen, size: 18),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.project_projectNameRequired;
              }
              return null;
            },
            onChanged: (_) => _onFieldChanged(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: l10n.project_description,
              prefixIcon: const Icon(LucideIcons.fileText, size: 18),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            onChanged: (_) => _onFieldChanged(),
          ),
          const SizedBox(height: 14),
          AnimatedOpacity(
            opacity: _isEdited ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isEdited && !_isSaving ? _save : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.save, size: 16),
                label: Text(
                  _isSaving
                      ? l10n.projectSettings_saving
                      : l10n.projectSettings_saveChanges,
                ),
              ),
            ),
          ),
        ],
      ],
    );

    final teamColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.projectSettings_team,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            if (_isManager)
              TextButton.icon(
                onPressed: _showInviteDialog,
                icon: const Icon(LucideIcons.userPlus, size: 15),
                label: Text(l10n.common_invite),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  textStyle: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        MemberList(
          projectId: widget.projectId,
          onRemove: _isManager ? _confirmRemoveMember : null,
        ),
      ],
    );

    return Scaffold(
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            ProjectSettingsHeader(
              project: _project!,
              memberCount: memberCount,
              onBack: () => context.pop(),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.crossAxisExtent >= 700;

                  if (isWide) {
                    return SliverToBoxAdapter(
                      child: Column(
                        children: [
                          ProjectSettingsStatsRow(
                            project: _project!,
                            memberCount: memberCount,
                          ),
                          const SizedBox(height: 28),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: detailsColumn),
                              const SizedBox(width: 32),
                              Expanded(child: teamColumn),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      ProjectSettingsStatsRow(
                        project: _project!,
                        memberCount: memberCount,
                      ),
                      if (_isManager) ...[
                        const SizedBox(height: 28),
                        detailsColumn,
                      ],
                      const SizedBox(height: 28),
                      teamColumn,
                    ]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
