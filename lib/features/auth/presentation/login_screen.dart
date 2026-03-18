import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/preview_helpers.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/auth/auth_state.dart';
import '../../../../l10n/app_localizations.dart';
import 'widgets/hero_panel.dart';
import 'widgets/login_mobile_hero.dart';
import 'widgets/login_form.dart';

@Preview(name: 'Login Screen', wrapper: previewWrapper)
Widget loginScreenPreview() => const LoginScreen();

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authNotifierProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isWide = MediaQuery.of(context).size.width >= 720;
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: colors.error),
        );
      }
    });

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(flex: 4, child: HeroPanel()),
            Expanded(
              flex: 5,
              child: _buildDesktopForm(authState, colors, l10n),
            ),
          ],
        ),
      );
    }

    return Scaffold(body: _buildMobileLayout(authState, colors, l10n));
  }

  Widget _buildMobileLayout(
    AuthState authState,
    AppColorSet colors,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LoginMobileHero(
            screenHeight: screenHeight,
            topPadding: topPadding,
            theme: theme,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.auth_signInSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.secondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  LoginForm(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    obscurePassword: _obscurePassword,
                    onToggleObscure: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    onLogin: _handleLogin,
                    isLoading: authState.isLoading,
                    colors: colors,
                    theme: theme,
                    onGoToSignup: () => context.go('/signup'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopForm(
    AuthState authState,
    AppColorSet colors,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
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
                          text: l10n.auth_welcome,
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: colors.foreground,
                          ),
                        ),
                        TextSpan(
                          text: l10n.auth_back,
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: colors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.auth_signInSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.secondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  LoginForm(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    obscurePassword: _obscurePassword,
                    onToggleObscure: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    onLogin: _handleLogin,
                    isLoading: authState.isLoading,
                    colors: colors,
                    theme: theme,
                    onGoToSignup: () => context.go('/signup'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
