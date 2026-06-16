import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../features/project/presentation/notifiers/member_notifier.dart';
import '../../features/user/data/user_lookup_provider.dart';
import '../../features/user/data/user_search_repository.dart';
import '../../l10n/app_localizations.dart';
import 'error_snack_bar.dart';
import 'user_avatar.dart';

class InviteDialog extends ConsumerStatefulWidget {
  const InviteDialog({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<InviteDialog> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<UserLookup> _results = [];
  bool _isSearching = false;
  UserLookup? _selectedUser;
  String _selectedRole = 'member';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchUsers(query.trim());
    });
  }

  Future<void> _searchUsers(String query) async {
    try {
      final results = await ref
          .read(userSearchRepositoryProvider)
          .search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectUser(UserLookup user) {
    setState(() {
      _selectedUser = user;
      _searchController.clear();
      _results = [];
    });
  }

  void _clearSelection() {
    setState(() => _selectedUser = null);
  }

  Future<void> _submit() async {
    final user = _selectedUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    final success = await ref
        .read(memberNotifierProvider.notifier)
        .inviteMember(
          projectId: widget.projectId,
          email: user.email,
          role: _selectedRole,
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSubmitting = false);
      final error = ref.read(memberNotifierProvider).error;
      final l10n = AppLocalizations.of(context);
      showErrorSnackBar(context, error ?? l10n.invite_sendFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.invite_title),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedUser == null) ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: l10n.invite_searchLabel,
                  hintText: l10n.invite_searchHint,
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                onChanged: _onSearchChanged,
                autofocus: true,
              ),
              if (_results.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final user = _results[index];
                      return ListTile(
                        dense: true,
                        leading: UserAvatar(
                          radius: 18,
                          avatarUrl: user.avatarUrl,
                          displayName: user.displayName,
                          email: user.email,
                        ),
                        title: Text(
                          user.displayName ?? user.email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: user.displayName != null
                            ? Text(user.email, style: theme.textTheme.bodySmall)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onTap: () => _selectUser(user),
                      );
                    },
                  ),
                ),
              if (!_isSearching &&
                  _results.isEmpty &&
                  _searchController.text.trim().length >= 2)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.invite_noUsersFound,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ] else ...[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors.accent.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  leading: UserAvatar(
                    radius: 20,
                    avatarUrl: _selectedUser!.avatarUrl,
                    displayName: _selectedUser!.displayName,
                    email: _selectedUser!.email,
                  ),
                  title: Text(
                    _selectedUser!.displayName ?? _selectedUser!.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: _selectedUser!.displayName != null
                      ? Text(_selectedUser!.email)
                      : null,
                  trailing: IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: colors.secondary,
                    ),
                    onPressed: _clearSelection,
                    tooltip: l10n.invite_changeUser,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: InputDecoration(labelText: l10n.invite_roleLabel),
                items: [
                  DropdownMenuItem(
                    value: 'member',
                    child: Text(l10n.invite_roleMember),
                  ),
                  DropdownMenuItem(
                    value: 'manager',
                    child: Text(l10n.invite_roleManager),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        ElevatedButton(
          onPressed: _selectedUser != null && !_isSubmitting ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: AppColors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : Text(l10n.invite_sendInvite),
        ),
      ],
    );
  }
}
