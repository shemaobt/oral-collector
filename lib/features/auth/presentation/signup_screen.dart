import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/preview_helpers.dart';
import '../../../shared/widgets/error_snack_bar.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/auth/auth_state.dart';

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
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        showErrorSnackBar(context, next.error!);
      }
    });

    return Scaffold(
      body: SingleChildScrollView(
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
                      tooltip: 'Back to sign in',
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
                            text: 'Create\n',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                          TextSpan(
                            text: 'Account',
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
                      'Join our community of story collectors.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.secondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Name',
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
                        hintText: 'Your full name',
                        prefixIcon: const Icon(LucideIcons.user, size: 18),
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.border,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your display name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Email Address',
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
                        hintText: 'your@email.com',
                        prefixIcon: const Icon(LucideIcons.mail, size: 18),
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.border,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Password',
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
                        hintText: 'At least 6 characters',
                        prefixIcon: const Icon(LucideIcons.lock, size: 18),
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.border,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
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
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Confirm Password',
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
                        hintText: 'Re-enter password',
                        prefixIcon: const Icon(
                          LucideIcons.shieldCheck,
                          size: 18,
                        ),
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.border,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
                            color: colors.secondary,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
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
                            : const Text('Continue'),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Have an account? ',
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
                            'Sign In',
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
