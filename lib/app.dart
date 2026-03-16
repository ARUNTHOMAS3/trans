// FILE: lib/app.dart
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

// Import the centralized router
import 'core/routing/app_router.dart';

class ZerpaiApp extends StatelessWidget {
  const ZerpaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "Zerpai ERP",

      // Theme configuration
      theme: AppTheme.lightTheme,

      // Use GoRouter configuration
      routerConfig: appRouter,
    );
  }
}
