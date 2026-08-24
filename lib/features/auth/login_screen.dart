import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/design_tokens.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/animated_button.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/guest_provider.dart';

/// Login screen with glassmorphic card design.
class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onSignUpTap;
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onSignUpTap,
    required this.onLoginSuccess,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGuestLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) widget.onLoginSuccess();
    } catch (e) {
      setState(() {
        _errorMessage = AuthService.parseSignInError(e);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() {
      _isGuestLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(guestModeProvider.notifier).enableGuestMode();
      if (mounted) widget.onLoginSuccess();
    } catch (e) {
      setState(() {
        _errorMessage = _parseGuestAuthError(e.toString());
      });
    } finally {
      if (mounted) setState(() => _isGuestLoading = false);
    }
  }

  String _parseAuthError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (error.contains('Email not confirmed')) {
      return 'Please verify your email address first.';
    }
    if (error.contains('Too many requests')) {
      return 'Too many attempts. Please try again later.';
    }
    return 'Something went wrong. Please try again.';
  }

  String _parseGuestAuthError(String error) {
    if (error.contains('Anonymous sign-ins are disabled')) {
      return 'Guest sign-in is not available right now.';
    }
    if (error.contains('Too many requests')) {
      return 'Too many attempts. Please try again later.';
    }
    return 'Could not sign in as guest. Please try again.';
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.surfaceDark,
                    const Color(0xFF0A2818),
                    AppColors.surfaceDark,
                  ]
                : [
                    AppColors.surfaceLight,
                    const Color(0xFFD1FAE5),
                    const Color(0xFFECFDF5),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                // ── Header ──
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withAlpha(51),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 400.ms,
                    ),

                const SizedBox(height: AppSpacing.lg),

                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  'Sign in to continue tracking your finances',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: 40),

                // ── Glass Card Form ──
                GlassCard(
                  borderRadius: AppRadius.xxl,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error message
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            margin:
                                const EdgeInsets.only(bottom: AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer
                                  .withAlpha(179),
                              borderRadius: AppRadius.lgAll,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    size: 20,
                                    color: theme.colorScheme.error),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          validator: _validateEmail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'you@example.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          validator: _validatePassword,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: '••••••••',
                            prefixIcon:
                                const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              _showForgotPasswordDialog(context);
                            },
                            child: const Text('Forgot Password?'),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Login button
                        SizedBox(
                          height: 56,
                          child: AnimatedElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color:
                                          theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : const Text('Sign In'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(
                        begin: 0.15,
                        end: 0,
                        delay: 400.ms,
                        duration: 500.ms),

                const SizedBox(height: AppSpacing.xl),

                // ── Sign Up Link ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onSignUpTap,
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Divider with "or" ──
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.outlineVariant.withAlpha(128),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg),
                      child: Text(
                        'or',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withAlpha(128),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: theme.colorScheme.outlineVariant.withAlpha(128),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                const SizedBox(height: AppSpacing.lg),

                // ── Continue as Guest Button ──
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed:
                        _isGuestLoading ? null : _handleGuestLogin,
                    icon: _isGuestLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : Icon(
                            Icons.person_outline_rounded,
                            color: theme.colorScheme.primary,
                          ),
                    label: Text(
                      _isGuestLoading
                          ? 'Signing in...'
                          : 'Continue as Guest',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color:
                            theme.colorScheme.primary.withAlpha(128),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.xlAll,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

                const SizedBox(height: AppSpacing.sm),

                // ── Guest disclaimer ──
                Text(
                  'No account needed — your data stays on this device session.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(102),
                    fontSize: 11,
                  ),
                ).animate().fadeIn(delay: 750.ms, duration: 400.ms),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a password reset link.'),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'you@example.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                try {
                  await AuthService.resetPassword(email: email);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Could not send reset email. Please try again.'),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }
}
