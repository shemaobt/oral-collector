import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/auth/providers.dart';
import '../../../shared/widgets/error_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(_emailController.text.trim());
      if (mounted) setState(() => _emailSent = true);
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/login'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _emailSent
                  ? _buildConfirmation(colors, theme, l10n)
                  : _buildForm(colors, theme, l10n),
            ),
          ),
        ),
      ),
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
            l10n.auth_forgotPasswordSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.auth_emailLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: l10n.auth_emailHint,
              prefixIcon: const Icon(LucideIcons.mail, size: 18),
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colors.border,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.auth_emailRequired;
              }
              if (!value.contains('@') || !value.contains('.')) {
                return l10n.auth_emailInvalid;
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleSubmit(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
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
                  : Text(l10n.auth_sendResetLink),
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

  Widget _buildConfirmation(
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
          child: Icon(LucideIcons.mailCheck, color: colors.accent, size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.auth_checkYourEmail,
          style: theme.textTheme.displayLarge?.copyWith(
            color: colors.foreground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            l10n.auth_resetEmailSent(_emailController.text.trim()),
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
          child: OutlinedButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() => _emailSent = false);
                    _handleSubmit();
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.foreground,
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: theme.textTheme.labelLarge,
            ),
            child: Text(l10n.auth_resendEmail),
          ),
        ),
        const SizedBox(height: 24),
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
}
