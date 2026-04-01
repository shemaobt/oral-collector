import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/auth/providers.dart';
import '../../../shared/widgets/error_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _success = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(widget.token!, _passwordController.text);
      if (mounted) setState(() => _success = true);
    } on Exception catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: widget.token == null || widget.token!.isEmpty
                  ? _buildInvalidToken(colors, theme, l10n)
                  : _success
                  ? _buildSuccess(colors, theme, l10n)
                  : _buildForm(colors, theme, l10n),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvalidToken(
    AppColorSet colors,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.shieldAlert, color: colors.error, size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.auth_invalidResetLink,
          style: theme.textTheme.displayLarge?.copyWith(
            color: colors.foreground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.auth_invalidResetLinkMessage,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.secondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => context.go('/forgot-password'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: theme.textTheme.labelLarge,
            ),
            child: Text(l10n.auth_requestNewLink),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(
            l10n.auth_backToLogin,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(
    AppColorSet colors,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colors.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.checkCircle, color: colors.accent, size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.auth_resetPassword,
          style: theme.textTheme.displayLarge?.copyWith(
            color: colors.foreground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            l10n.auth_resetSuccess,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.secondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: theme.textTheme.labelLarge,
            ),
            child: Text(l10n.auth_signIn),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(
    AppColorSet colors,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(LucideIcons.keyRound, color: colors.accent, size: 28),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.auth_resetPassword,
            style: theme.textTheme.displayLarge?.copyWith(
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.auth_resetPasswordSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            l10n.auth_newPassword,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: l10n.auth_passwordHint,
              prefixIcon: const Icon(LucideIcons.lock, size: 18),
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colors.border,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: colors.secondary,
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.auth_passwordRequired;
              }
              if (value.length < 8) {
                return l10n.auth_passwordTooShort;
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          Text(
            l10n.auth_confirmNewPassword,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: l10n.auth_confirmPasswordHint,
              prefixIcon: const Icon(LucideIcons.shieldCheck, size: 18),
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colors.border,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: colors.secondary,
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.auth_confirmPasswordRequired;
              }
              if (value != _passwordController.text) {
                return l10n.auth_confirmPasswordMismatch;
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleReset(),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: theme.textTheme.labelLarge,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.auth_resetPasswordButton),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: Text(
                l10n.auth_backToLogin,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
