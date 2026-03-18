import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onLogin,
    required this.isLoading,
    required this.colors,
    required this.theme,
    required this.onGoToSignup,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  final bool isLoading;
  final AppColorSet colors;
  final ThemeData theme;
  final VoidCallback onGoToSignup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.auth_emailLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
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
        ),
        const SizedBox(height: 20),

        Text(
          l10n.auth_passwordLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: passwordController,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
            prefixIcon: const Icon(LucideIcons.lock, size: 18),
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colors.border,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                color: colors.secondary,
                size: 18,
              ),
              onPressed: onToggleObscure,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.auth_passwordRequired;
            }
            if (value.length < 6) {
              return l10n.auth_passwordTooShort;
            }
            return null;
          },
          onFieldSubmitted: (_) => onLogin(),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading ? null : onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: theme.textTheme.labelLarge,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.auth_signIn),
          ),
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.auth_noAccount,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.secondary,
              ),
            ),
            TextButton(
              onPressed: onGoToSignup,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                l10n.auth_signUp,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.accent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
