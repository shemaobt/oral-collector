import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../sync/presentation/notifiers/sync_notifier.dart';
import '../data/providers.dart';
import '../domain/repositories/project_repository.dart';
import 'notifiers/project_notifier.dart';
import '../domain/entities/language.dart';

Future<bool?> showCreateProjectSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (_) => const _CreateProjectSheet(),
  );
}

class _CreateProjectSheet extends ConsumerStatefulWidget {
  const _CreateProjectSheet();

  @override
  ConsumerState<_CreateProjectSheet> createState() =>
      _CreateProjectSheetState();
}

class _CreateProjectSheetState extends ConsumerState<_CreateProjectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  Language? _selectedLanguage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(syncNotifierProvider).isOnline) {
        ref.read(projectNotifierProvider.notifier).fetchLanguages();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickLanguage() async {
    final languages = ref.read(projectNotifierProvider).languages;
    final result = await showModalBottomSheet<Language>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) => _LanguagePickerSheet(
        languages: languages,
        selected: _selectedLanguage,
        projectRepo: ref.read(projectRepositoryProvider),
        onLanguageCreated: (lang) {
          final current = ref.read(projectNotifierProvider).languages;
          ref.read(projectNotifierProvider.notifier).setLanguages([
            ...current,
            lang,
          ]);
        },
      ),
    );
    if (result != null) {
      setState(() => _selectedLanguage = result);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLanguage == null) {
      showErrorSnackBar(context, 'Please select a language');
      return;
    }

    setState(() => _isSubmitting = true);

    await ref
        .read(projectNotifierProvider.notifier)
        .createProject(
          name: _nameController.text.trim(),
          languageId: _selectedLanguage!.id,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
        );

    if (!mounted) return;

    final error = ref.read(projectNotifierProvider).error;
    if (error != null) {
      setState(() => _isSubmitting = false);
      showErrorSnackBar(context, error);
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    final bottomPadding = keyboardInset > 0
        ? keyboardInset + 16
        : AppShell.scrollBottomPadding;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(l10n.project_newProject, style: theme.textTheme.titleLarge),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.project_projectName,
                  hintText: l10n.project_projectNameHint,
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.project_projectNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _pickLanguage,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.project_language,
                    suffixIcon: const Icon(LucideIcons.chevronRight, size: 18),
                    errorText: null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _selectedLanguage != null
                      ? Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedLanguage!.name,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _selectedLanguage!.code.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.accent,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          l10n.project_selectLanguage,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.secondary.withValues(alpha: 0.5),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.project_description,
                  hintText: l10n.project_descriptionHint,
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(l10n.common_cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.project_createProject),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguagePickerSheet extends StatefulWidget {
  const _LanguagePickerSheet({
    required this.languages,
    required this.selected,
    required this.projectRepo,
    required this.onLanguageCreated,
  });

  final List<Language> languages;
  final Language? selected;
  final ProjectRepository projectRepo;
  final void Function(Language) onLanguageCreated;

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  bool _isAddingNew = false;
  final _newNameController = TextEditingController();
  final _newCodeController = TextEditingController();
  final _addFormKey = GlobalKey<FormState>();
  bool _isCreatingLanguage = false;

  @override
  void dispose() {
    _searchController.dispose();
    _newNameController.dispose();
    _newCodeController.dispose();
    super.dispose();
  }

  List<Language> get _filtered {
    if (_query.isEmpty) return widget.languages;
    final q = _query.toLowerCase();
    return widget.languages.where((l) {
      return l.name.toLowerCase().contains(q) ||
          l.code.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _createLanguage() async {
    if (!_addFormKey.currentState!.validate()) return;

    setState(() => _isCreatingLanguage = true);

    try {
      final lang = await widget.projectRepo.createLanguage(
        name: _newNameController.text.trim(),
        code: _newCodeController.text.trim().toLowerCase(),
      );
      widget.onLanguageCreated(lang);
      if (!mounted) return;
      Navigator.of(context).pop(lang);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isCreatingLanguage = false);
      showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final filtered = _filtered;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final navBarPadding = keyboardInset > 0
        ? keyboardInset + 16
        : AppShell.scrollBottomPadding;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isAddingNew
                        ? l10n.project_addLanguageTitle
                        : l10n.project_selectLanguageTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (_isAddingNew)
                  IconButton(
                    onPressed: () => setState(() => _isAddingNew = false),
                    icon: const Icon(LucideIcons.arrowLeft, size: 20),
                    tooltip: l10n.project_backToList,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_isAddingNew) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, navBarPadding),
              child: Form(
                key: _addFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.project_addLanguageSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newNameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: l10n.project_languageName,
                        hintText: l10n.project_languageNameHint,
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.project_languageNameRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newCodeController,
                      decoration: InputDecoration(
                        labelText: l10n.project_languageCode,
                        hintText: l10n.project_languageCodeHint,
                      ),
                      textCapitalization: TextCapitalization.none,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _createLanguage(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.project_languageCodeRequired;
                        }
                        if (v.trim().length > 3) {
                          return l10n.project_languageCodeTooLong;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCreatingLanguage ? null : _createLanguage,
                        child: _isCreatingLanguage
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.project_addLanguage),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.project_searchLanguages,
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),

            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.globe,
                            size: 36,
                            color: colors.secondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.project_noLanguagesFound,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.secondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              _newNameController.text = _query;
                              setState(() => _isAddingNew = true);
                            },
                            icon: const Icon(LucideIcons.plus, size: 16),
                            label: Text(l10n.project_addAsNewLanguage(_query)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.only(bottom: navBarPadding),
                      itemCount: filtered.length + 1,
                      itemBuilder: (context, index) {
                        if (index == filtered.length) {
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                LucideIcons.plus,
                                size: 18,
                                color: colors.info,
                              ),
                            ),
                            title: Text(
                              l10n.project_addNewLanguage,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () => setState(() => _isAddingNew = true),
                          );
                        }

                        final lang = filtered[index];
                        final isSelected = widget.selected?.id == lang.id;

                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.accent.withValues(alpha: 0.12)
                                  : colors.surfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                lang.code.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: isSelected
                                      ? colors.accent
                                      : colors.secondary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            lang.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  LucideIcons.check,
                                  size: 18,
                                  color: colors.accent,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(lang),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
