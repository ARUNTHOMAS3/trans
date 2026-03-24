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
  ref.read(appBrandingProvider.notifier).apply(accentColor: color, isDarkPane: isDark);
}

class ZerpaiShell extends ConsumerStatefulWidget {
  final Widget child;

  const ZerpaiShell({super.key, required this.child});

  @override
  ConsumerState<ZerpaiShell> createState() => _ZerpaiShellState();
}

class _ZerpaiShellState extends ConsumerState<ZerpaiShell> {
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

    final uri = GoRouterState.of(context).uri;
    final String path = uri.path;
    final bool isSettingsRoute = RegExp(r'^/\d{10,20}/settings(?:/|$)')
        .hasMatch(path);
    final currentOrgSystemId = RegExp(r'^/(\d{10,20})(?:/|$)')
        .firstMatch(path)
        ?.group(1);
    final resolvedOrgSystemId = ref.watch(orgSettingsProvider).whenOrNull(
      data: (settings) => settings?.systemId.trim(),
    );

    if (currentOrgSystemId != null &&
        resolvedOrgSystemId != null &&
        resolvedOrgSystemId.isNotEmpty &&
        resolvedOrgSystemId != currentOrgSystemId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final replacementUri = uri.replace(
          path: path.replaceFirst(
            '/$currentOrgSystemId',
            '/$resolvedOrgSystemId',
          ),
        );
        if (replacementUri.toString() != uri.toString()) {
          context.go(replacementUri.toString());
        }
      });
    }

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
                            if (!isSettingsRoute) const ZerpaiNavbar(),
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
