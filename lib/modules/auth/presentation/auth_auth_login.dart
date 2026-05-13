import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/modules/auth/models/auth_state.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

const String _kFallbackOrgSystemId = '0000000000';

class AuthLoginPage extends ConsumerStatefulWidget {
  const AuthLoginPage({super.key});

  @override
  ConsumerState<AuthLoginPage> createState() => _AuthLoginPageState();
}

class _AuthLoginPageState extends ConsumerState<AuthLoginPage> {
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

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    await ref
        .read(authControllerProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is Authenticated && mounted) {
        final routeSystemId = next.user.routeSystemId.isNotEmpty
            ? next.user.routeSystemId
            : (next.user.orgSystemId.isNotEmpty
                ? next.user.orgSystemId
                : _kFallbackOrgSystemId);
        context.go('/$routeSystemId/home');
      }
    });

    final bool isLoading = authState is AuthLoading;
    final String? errorMessage = authState is Unauthenticated
        ? authState.errorMessage
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompact = constraints.maxWidth < 980;
            return Row(
              children: [
                if (!isCompact)
                  Expanded(
                    child: Container(
                      color: AppTheme.sidebarColor,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 64,
                            left: 56,
                            child: _GlowCircle(
                              size: 220,
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.16,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 76,
                            right: 72,
                            child: _GlowCircle(
                              size: 300,
                              color: AppTheme.accentGreen.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(56, 56, 56, 56),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _BrandHeader(),
                                const Spacer(),
                                Text(
                                  'ERP control for branches, inventory, sales, purchases, and accounts.',
                                  style: AppTheme.textPrimaryStyle(
                                    34,
                                    FontWeight.w700,
                                  ).copyWith(
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Sign in with your organization account to continue to the launch workspace.',
                                  style: AppTheme.bodyText.copyWith(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                const _FeatureList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 24 : 48,
                        vertical: 32,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isCompact) ...[
                              const _BrandHeader(compact: true),
                              const SizedBox(height: 28),
                            ],
                            Container(
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
                                child: AutofillGroup(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sign In',
                                        style: AppTheme.textPrimaryStyle(
                                          28,
                                          FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Use your work email and password to access Zerpai ERP.',
                                        style: AppTheme.bodyText.copyWith(
                                          color: AppTheme.textSecondary,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      if (errorMessage != null &&
                                          errorMessage.isNotEmpty) ...[
                                        _ErrorBanner(message: errorMessage),
                                        const SizedBox(height: 16),
                                      ],
                                      CustomTextField(
                                        controller: _emailController,
                                        label: 'Email',
                                        hintText: 'name@company.com',
                                        keyboardType: TextInputType.emailAddress,
                                        forceUppercase: false,
                                        prefixIcon: LucideIcons.mail,
                                        autofillHints: const [
                                          AutofillHints.username,
                                          AutofillHints.email,
                                        ],
                                        validator: (value) {
                                          final text = value?.trim() ?? '';
                                          if (text.isEmpty) {
                                            return 'Enter your email.';
                                          }
                                          final emailRegex = RegExp(
                                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                          );
                                          if (!emailRegex.hasMatch(text)) {
                                            return 'Enter a valid email address.';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      CustomTextField(
                                        controller: _passwordController,
                                        label: 'Password',
                                        hintText: 'Enter password',
                                        obscureText: _obscurePassword,
                                        forceUppercase: false,
                                        prefixIcon: LucideIcons.lock,
                                        autofillHints: const [AutofillHints.password],
                                        suffixWidget: IconButton(
                                          splashRadius: 18,
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                          icon: Icon(
                                            _obscurePassword
                                                ? LucideIcons.eyeOff
                                                : LucideIcons.eye,
                                            size: 18,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        validator: (value) {
                                          if ((value ?? '').isEmpty) {
                                            return 'Enter your password.';
                                          }
                                          return null;
                                        },
                                        onSubmitted: (_) => _submit(),
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: isLoading
                                              ? null
                                              : () => context.go(
                                                  AppRoutes.authForgotPassword,
                                                ),
                                          child: Text(
                                            'Forgot password?',
                                            style: AppTheme.linkText.copyWith(
                                              decoration: TextDecoration.none,
                                              color: AppTheme.primaryBlueDark,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ZButton.primary(
                                          label: 'Sign In',
                                          onPressed: isLoading ? null : _submit,
                                          loading: isLoading,
                                          icon: LucideIcons.logIn,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: AppTheme.bgLight,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppTheme.borderLight,
                                          ),
                                        ),
                                        child: Text(
                                          'Phase 1 launch uses Supabase Auth. Backend token verification and route protection are being wired alongside this screen.',
                                          style: AppTheme.metaHelper.copyWith(
                                            color: AppTheme.textSubtle,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Center(
                              child: Text(
                                '© 2026 Zerpai ERP',
                                style: AppTheme.metaHelper,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final bool compact;

  const _BrandHeader({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 42 : 48,
          height: compact ? 42 : 48,
          decoration: BoxDecoration(
            color: compact
                ? AppTheme.sidebarColor
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: compact
                  ? AppTheme.borderLight
                  : Colors.white.withValues(alpha: 0.16),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '₹',
            style: AppTheme.textPrimaryStyle(24, FontWeight.w800).copyWith(
              color: compact ? AppTheme.accentGreen : Colors.white,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zerpai ERP',
              style: AppTheme.textPrimaryStyle(
                compact ? 20 : 22,
                FontWeight.w700,
              ).copyWith(
                color: compact ? AppTheme.textPrimary : Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Phase 1 Launch Access',
              style: AppTheme.metaHelper.copyWith(
                color: compact
                    ? AppTheme.textSecondary
                    : Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    const items = [
      'Branch and warehouse operations',
      'Sales, purchase, and inventory workflows',
      'Role-scoped access for Admin, HO Admin, and Branch Admin',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      LucideIcons.checkCircle2,
                      size: 18,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTheme.bodyText.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.errorBgBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.alertCircle,
            size: 16,
            color: AppTheme.errorRedDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.replaceFirst('Exception: ', ''),
              style: AppTheme.metaHelper.copyWith(
                color: AppTheme.errorTextDark,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}
