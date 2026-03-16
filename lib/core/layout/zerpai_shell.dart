import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'zerpai_navbar.dart';
import 'package:zerpai_erp/core/layout/zerpai_sidebar.dart';
import 'package:zerpai_erp/shared/services/sync/global_sync_manager.dart';

class ZerpaiShell extends StatelessWidget {
  final Widget child;

  const ZerpaiShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlobalSyncManager(
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ZerpaiSidebar(
                onNavigate: (route) => context.go(route),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ZerpaiNavbar(),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
