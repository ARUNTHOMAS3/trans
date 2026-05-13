import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
import 'zerpai_navbar.dart';
import 'package:zerpai_erp/core/layout/zerpai_sidebar.dart';
import 'package:zerpai_erp/core/layout/zerpai_shell_metrics.dart';
import 'package:zerpai_erp/shared/services/sync/global_sync_manager.dart';

Color? _hexToColor(String hex) {
  final clean = hex.replaceAll('#', '').trim();
  if (clean.length != 6) return null;
  final value = int.tryParse('FF$clean', radix: 16);
  return value != null ? Color(value) : null;
}

void _applyBranding(WidgetRef ref, OrgSettings settings) {
  final color = _hexToColor(settings.accentColor) ?? const Color(0xFF22A95E);
  final isDark = settings.themeMode != 'light';
  ref
      .read(appBrandingProvider.notifier)
      .apply(accentColor: color, isDarkPane: isDark);
}

class ZerpaiShell extends ConsumerStatefulWidget {
  final Widget child;

  const ZerpaiShell({super.key, required this.child});

  @override
  ConsumerState<ZerpaiShell> createState() => _ZerpaiShellState();
}

class _ZerpaiShellState extends ConsumerState<ZerpaiShell> {
  bool _isSettingsRoute(BuildContext context) {
    try {
      final matchedLocation = GoRouter.of(
        context,
      ).routerDelegate.currentConfiguration.last.matchedLocation;
      final normalized = matchedLocation.replaceFirst(
        RegExp(r'^/\d{10,20}'),
        '',
      );
      return normalized == '/settings' || normalized.startsWith('/settings/');
    } catch (_) {
      final path = GoRouter.of(context).routeInformationProvider.value.uri.path;
      return RegExp(r'^/\d{10,20}/settings(?:/|$)').hasMatch(path);
    }
  }

  @override
  void initState() {
    super.initState();
    // Apply saved branding immediately if org data is already cached.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(orgSettingsProvider).whenData((settings) {
        if (settings != null) _applyBranding(ref, settings);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Also listen for future changes (e.g. org switch, settings save).
    ref.listen<AsyncValue<OrgSettings?>>(orgSettingsProvider, (_, next) {
      next.whenData((settings) {
        if (settings != null) _applyBranding(ref, settings);
      });
    });

    final bool isSettingsRoute = _isSettingsRoute(context);
    return GlobalSyncManager(
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          if (!isSettingsRoute)
            const SingleActivator(LogicalKeyboardKey.slash): () {
              ZerpaiNavbar.focusGlobalSearch();
            },
        },
        child: Material(
          color: Colors.white,
          child: SafeArea(
            child: ValueListenableBuilder<bool>(
              valueListenable: ZerpaiSidebar.collapsedNotifier,
              builder: (context, isCollapsed, _) {
                final viewportWidth =
                    MediaQuery.maybeOf(context)?.size.width ?? 1440;
                final sidebarWidth = isCollapsed
                    ? ZerpaiSidebar.collapsedWidth
                    : ZerpaiSidebar.expandedWidth;

                return ZerpaiShellMetricsScope(
                  metrics: ZerpaiShellMetrics(
                    isSidebarCollapsed: isCollapsed,
                    sidebarWidth: sidebarWidth,
                    viewportWidth: viewportWidth,
                    contentWidth: viewportWidth - sidebarWidth,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isSettingsRoute)
                        ZerpaiSidebar(onNavigate: (route) => context.go(route)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const ZerpaiNavbar(),
                            Expanded(child: widget.child),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
