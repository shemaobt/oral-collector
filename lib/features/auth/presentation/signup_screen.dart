import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/preview_helpers.dart';
import '../../../shared/widgets/error_snack_bar.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/auth/auth_state.dart';
import '../../../../l10n/app_localizations.dart';
import 'widgets/hero_panel.dart';

@Preview(name: 'Signup Screen', wrapper: previewWrapper)
Widget signupScreenPreview() => const SignupScreen();

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authNotifierProvider.notifier)
        .signup(
          _emailController.text.trim(),
          _passwordController.text,
          displayName: _displayNameController.text.trim().isNotEmpty
              ? _displayNameController.text.trim()
              : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 720;
    final l10n = AppLocalizations.of(context);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        showErrorSnackBar(context, next.error!);
      }
    });

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(flex: 4, child: HeroPanel()),
            Expanded(
              flex: 5,
              child: _buildDesktopForm(authState, colors, theme, l10n),
            ),
          ],
        ),
      );
    }

    return Scaffold(body: _buildMobileLayout(authState, colors, theme, l10n));
  }

  Widget _buildDesktopForm(
    AuthState authState,
    AppColorSet colors,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/app_icon.png',
                      width: 52,
                      height: 52,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l10n.auth_createWord,
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: colors.foreground,
                          ),
                        ),
                        TextSpan(
                          text: l10n.auth_account,
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: colors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.auth_signUpSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.secondary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildFormFields(authState, colors, theme, l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    AuthState authState,
    AppColorSet colors,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: screenHeight * 0.38,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                  child: Image.asset(
                    'assets/hero_woman.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(36),
                        bottomRight: Radius.circular(36),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.55),
                        ],
                        stops: const [0.25, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: topPadding + 12,
                  left: 16,
                  child: IconButton(
                    onPressed: () => context.go('/login'),
                    tooltip: l10n.auth_backToSignIn,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(44, 44),
                    ),
                    icon: const Icon(
                      LucideIcons.arrowLeft,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                Positioned(
                  left: 28,
                  right: 28,
                  bottom: 28,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l10n.auth_createNewline,
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        TextSpan(
                          text: l10n.auth_account,
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: const Color(0xFFFFB380),
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.auth_signUpSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.secondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildFormFields(authState, colors, theme, l10n),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(
    AuthState authState,
    AppColorSet colors,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.auth_nameLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _displayNameController,
          textInputAction: TextInputAction.next,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: l10n.auth_nameHint,
            prefixIcon: const Icon(LucideIcons.user, size: 18),
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colors.border,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.auth_nameRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
        Text(
          l10n.auth_passwordLabel,
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
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
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
        ),
        const SizedBox(height: 16),
        Text(
          l10n.auth_confirmPasswordLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.foreground,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
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
                _obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                color: colors.secondary,
                size: 18,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
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
          onFieldSubmitted: (_) => _handleSignup(),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: authState.isLoading ? null : _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: theme.textTheme.labelLarge,
            ),
            child: authState.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.auth_continueButton),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.auth_haveAccount,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.secondary,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/login'),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                l10n.auth_signIn,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
