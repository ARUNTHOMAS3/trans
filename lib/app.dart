// FILE: lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/modules/auth/models/auth_state.dart';

import 'core/providers/app_branding_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

class ZerpaiApp extends ConsumerStatefulWidget {
  const ZerpaiApp({super.key});

  @override
  ConsumerState<ZerpaiApp> createState() => _ZerpaiAppState();
}

class _ZerpaiAppState extends ConsumerState<ZerpaiApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(appBrandingProvider);
    final authState = ref.watch(authControllerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "Zerpai ERP",
      theme: AppTheme.themedWith(branding.accentColor),
      routerConfig: appRouter,
      builder: (context, child) {
        if (authState is AuthInitial) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
