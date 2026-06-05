import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class AuthResetPasswordPage extends StatefulWidget {
  const AuthResetPasswordPage({super.key});

  @override
  State<AuthResetPasswordPage> createState() => _AuthResetPasswordPageState();
}

class _AuthResetPasswordPageState extends State<AuthResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _resendEmailController = TextEditingController();
  StreamSubscription<AuthState>? _authSubscription;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _recoveryReady = false;
  bool _isLoading = false;
  bool _showResendSection = false;
  bool _isResending = false;
  String? _message;
  String? _errorMessage;
  String? _resendMessage;

  @override
  void initState() {
    super.initState();
    _bootstrapRecoverySessionFromUrl();
    final auth = Supabase.instance.client.auth;
    _recoveryReady = auth.currentSession != null;

    _authSubscription = auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      if (event.event == AuthChangeEvent.passwordRecovery ||
          event.session != null) {
        setState(() {
          _recoveryReady = true;
          _errorMessage = null;
        });
      }
    });
  }

  Future<void> _bootstrapRecoverySessionFromUrl() async {
    final auth = Supabase.instance.client.auth;
    final uri = Uri.base;

    // Supabase recovery links may arrive as either:
    // 1) query params (?code=...&type=recovery) or
    // 2) hash fragment (#access_token=...&refresh_token=...&type=recovery)
    try {
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        await auth.exchangeCodeForSession(code);
      }
    } catch (_) {
      // Ignore here; UI will show actionable state below.
    }

    try {
      final fragment = uri.fragment;
      if (fragment.isNotEmpty) {
        final fragmentParams = Uri.splitQueryString(fragment);
        final accessToken = fragmentParams['access_token'];
        final refreshToken = fragmentParams['refresh_token'];

        if ((accessToken?.isNotEmpty == true) &&
            (refreshToken?.isNotEmpty == true)) {
          await auth.setSession(refreshToken!);
        }
      }
    } catch (_) {
      // Ignore here; UI will show actionable state below.
    }

    if (!mounted) return;
    setState(() {
      _recoveryReady = auth.currentSession != null;
      if (!_recoveryReady) {
        _errorMessage =
            'Reset link is invalid or expired. Request a new password reset email.';
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _resendEmailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return false;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _resendResetLink() async {
    final email = _resendEmailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() {
        _resendMessage = null;
        _errorMessage = 'Enter a valid email address to resend the reset link.';
      });
      return;
    }

    setState(() {
      _isResending = true;
      _resendMessage = null;
      _errorMessage = null;
    });

    try {
      final redirectTo = '${Uri.base.origin}${AppRoutes.authResetPassword}';
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo,
      );

      if (!mounted) return;
      setState(() {
        _resendMessage = 'Reset email sent to $email. Check your inbox.';
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Unable to resend reset email right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _message = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      if (!mounted) return;
      setState(() {
        _message = 'Your password has been updated. Sign in with the new password.';
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Unable to update the password. Open the reset link again and retry.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 30,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.shieldCheck,
                        size: 22,
                        color: AppTheme.primaryBlueDark,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Set New Password',
                        style: AppTheme.textPrimaryStyle(28, FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _recoveryReady
                            ? 'Enter a new password for your Zerpai ERP account.'
                            : 'Open this page from the password reset email to continue.',
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_message != null) ...[
                        _InfoBanner(message: _message!),
                        const SizedBox(height: 16),
                      ],
                      if (_errorMessage != null) ...[
                        _ErrorBanner(message: _errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      if (!_recoveryReady) ...[
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showResendSection = !_showResendSection;
                                  _resendMessage = null;
                                });
                              },
                              child: Text(
                                _showResendSection
                                    ? 'Hide resend option'
                                    : 'Resend reset link',
                              ),
                            ),
                          ],
                        ),
                        if (_showResendSection) ...[
                          CustomTextField(
                            controller: _resendEmailController,
                            label: 'Email',
                            hintText: 'name@company.com',
                            keyboardType: TextInputType.emailAddress,
                            forceUppercase: false,
                            prefixIcon: LucideIcons.mail,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ZButton.primary(
                                  label: 'Send Reset Link',
                                  onPressed:
                                      _isResending ? null : _resendResetLink,
                                  loading: _isResending,
                                  icon: LucideIcons.send,
                                ),
                              ),
                            ],
                          ),
                          if (_resendMessage != null) ...[
                            const SizedBox(height: 10),
                            _InfoBanner(message: _resendMessage!),
                          ],
                        ],
                        const SizedBox(height: 16),
                      ],
                      CustomTextField(
                        controller: _passwordController,
                        label: 'New Password',
                        hintText: 'Enter new password',
                        obscureText: _obscurePassword,
                        forceUppercase: false,
                        prefixIcon: LucideIcons.lock,
                        suffixWidget: IconButton(
                          splashRadius: 18,
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? LucideIcons.eye
                                : LucideIcons.eyeOff,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        validator: (value) {
                          final text = value ?? '';
                          if (text.isEmpty) return 'Enter a new password.';
                          if (text.length < 8) {
                            return 'Password must be at least 8 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hintText: 'Re-enter new password',
                        obscureText: _obscureConfirmPassword,
                        forceUppercase: false,
                        prefixIcon: LucideIcons.lock,
                        suffixWidget: IconButton(
                          splashRadius: 18,
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? LucideIcons.eye
                                : LucideIcons.eyeOff,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        validator: (value) {
                          final text = value ?? '';
                          if (text.isEmpty) return 'Confirm your new password.';
                          if (text != _passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          ZButton.secondary(
                            label: 'Back',
                            onPressed: () => context.go(AppRoutes.authLogin),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ZButton.primary(
                              label: 'Update Password',
                              onPressed:
                                  (!_recoveryReady || _isLoading) ? null : _submit,
                              loading: _isLoading,
                              icon: LucideIcons.check,
                            ),
                          ),
                        ],
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.go(AppRoutes.authLogin),
                            child: const Text('Go to Sign In'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Text(
        message,
        style: AppTheme.metaHelper.copyWith(
          color: const Color(0xFFB42318),
          height: 1.45,
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.infoBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.infoBgBorder),
      ),
      child: Text(
        message,
        style: AppTheme.metaHelper.copyWith(
          color: AppTheme.infoTextDark,
          height: 1.45,
        ),
      ),
    );
  }
}
