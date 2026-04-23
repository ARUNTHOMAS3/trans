
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class AuthForgotPasswordPage extends ConsumerStatefulWidget {
  const AuthForgotPasswordPage({super.key});

  @override
  ConsumerState<AuthForgotPasswordPage> createState() =>
      _AuthForgotPasswordPageState();
}

class _AuthForgotPasswordPageState
    extends ConsumerState<AuthForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isLoading = true);
    final baseUri = Uri.base;
    final redirectTo = '${baseUri.origin}${AppRoutes.authResetPassword}';
    final success = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordReset(
          _emailController.text.trim(),
          redirectTo: redirectTo,
        );

    if (!mounted) return;
    setState(() {
      _submitted = success;
      _isLoading = false;
    });
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
                        LucideIcons.keyRound,
                        size: 22,
                        color: AppTheme.primaryBlueDark,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Reset Password',
                        style:
                            AppTheme.textPrimaryStyle(28, FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your work email. We will send a reset link to let you set a new password.',
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_submitted) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.infoBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.infoBgBorder),
                          ),
                          child: Text(
                            'Password reset email sent to ${_emailController.text.trim()}. Open the link in that email to continue.',
                            style: AppTheme.metaHelper.copyWith(
                              color: AppTheme.infoTextDark,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'name@company.com',
                        keyboardType: TextInputType.emailAddress,
                        forceUppercase: false,
                        prefixIcon: LucideIcons.mail,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Enter your email.';
                          final emailRegex = RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          );
                          if (!emailRegex.hasMatch(text)) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                        onSubmitted: (_) => _submit(),
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
                              label: 'Request Reset',
                              onPressed: _isLoading ? null : _submit,
                              loading: _isLoading,
                              icon: LucideIcons.send,
                            ),
                          ),
                        ],
                      ),
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
