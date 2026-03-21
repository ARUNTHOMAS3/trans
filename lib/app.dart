// FILE: lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_branding_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

class ZerpaiApp extends ConsumerWidget {
  const ZerpaiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appBrandingProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "Zerpai ERP",
      theme: AppTheme.themedWith(branding.accentColor),
      routerConfig: appRouter,
    );
  }
}
