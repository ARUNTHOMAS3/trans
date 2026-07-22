import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/auth/capability_service.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

class SettingsNavigationEntry {
  final String label;
  final String? route;

  const SettingsNavigationEntry({required this.label, this.route});
}

class SettingsNavigationBlock {
  final String title;
  final List<SettingsNavigationEntry> items;

  const SettingsNavigationBlock({required this.title, required this.items});
}

class SettingsNavigationSection {
  final String title;
  final List<SettingsNavigationBlock> blocks;

  const SettingsNavigationSection({required this.title, required this.blocks});
}

const List<SettingsNavigationSection> kSettingsNavigationSections =
    <SettingsNavigationSection>[
      SettingsNavigationSection(
        title: 'Organization Settings',
        blocks: <SettingsNavigationBlock>[
          SettingsNavigationBlock(
            title: 'Organization',
            items: <SettingsNavigationEntry>[
              SettingsNavigationEntry(
                label: 'Profile',
                route: AppRoutes.settingsOrgProfile,
              ),
              SettingsNavigationEntry(
                label: 'Branding',
                route: AppRoutes.settingsOrgBranding,
              ),
              SettingsNavigationEntry(
                label: 'Branches',
                route: AppRoutes.settingsBranches,
              ),
              SettingsNavigationEntry(
                label: 'Warehouses',
                route: AppRoutes.settingsWarehouses,
              ),
              SettingsNavigationEntry(
                label: 'Approvals',
                route: AppRoutes.settingsApproval,
              ),
              SettingsNavigationEntry(label: 'Manage Subscription'),
            ],
          ),
          SettingsNavigationBlock(
            title: 'Users & Roles',
            items: <SettingsNavigationEntry>[
              SettingsNavigationEntry(
                label: 'Users',
                route: AppRoutes.settingsUsers,
              ),
              SettingsNavigationEntry(
                label: 'Roles',
                route: AppRoutes.settingsRoles,
              ),
            ],
          ),
          SettingsNavigationBlock(
            title: 'Taxes & Compliance',
            items: <SettingsNavigationEntry>[
              SettingsNavigationEntry(
                label: 'Taxes',
                route: AppRoutes.settingsTaxes,
              ),
              SettingsNavigationEntry(
                label: 'Direct Taxes',
                route: AppRoutes.settingsDirectTaxes,
              ),
              SettingsNavigationEntry(
                label: 'e-Way Bills',
                route: AppRoutes.settingsEwayBills,
              ),
              SettingsNavigationEntry(
                label: 'e-Invoicing',
                route: AppRoutes.settingsEinvoicing,
              ),
              SettingsNavigationEntry(label: 'MSME Settings'),
            ],
          ),
          SettingsNavigationBlock(
            title: 'Setup & Configurations',
            items: <SettingsNavigationEntry>[
              SettingsNavigationEntry(
                label: 'General',
                route: AppRoutes.settingsGeneral,
              ),
              SettingsNavigationEntry(
                label: 'Currencies',
                route: AppRoutes.settingsCurrencies,
              ),
              SettingsNavigationEntry(
                label: 'Reminders',
                route: AppRoutes.settingsReminders,
              ),
              SettingsNavigationEntry(label: 'Customer Portal'),
            ],
          ),
          SettingsNavigationBlock(
            title: 'Customization',
            items: <SettingsNavigationEntry>[
              SettingsNavigationEntry(
                label: 'Transaction Number Series',
                route: AppRoutes.settingsTransactionNumberSeries,
              ),
              SettingsNavigationEntry(
                label: 'PDF Templates',
                route: AppRoutes.settingsPdfTemplates,
              ),
              SettingsNavigationEntry(
                label: 'Email Notifications',
                route: AppRoutes.settingsEmailNotifications,
              ),
              SettingsNavigationEntry(label: 'SMS Notifications'),
              SettingsNavigationEntry(
                label: 'Reporting Tags',
                route: AppRoutes.settingsReportingTags,
              ),
              SettingsNavigationEntry(label: 'Web Tabs'),
            ],
          ),
          SettingsNavigationBlock(
            title: 'Automation',
            items: <SettingsNavigationEntry>[
              SettingsNavigationEntry(
                label: 'Workflow Rules',
                route: AppRoutes.settingsWorkflowRules,
              ),
              SettingsNavigationEntry(
                label: 'Workflow Actions',
                route: AppRoutes.settingsWorkflowActions,
              ),
              SettingsNavigationEntry(
                label: 'Workflow Logs',
                route: AppRoutes.settingsWorkflowLogs,
              ),
            ],
          ),
        ],
      ),
      SettingsNavigationSection(
        title: 'Module Settings',
        blocks: <SettingsNavigationBlock>[
          SettingsNavigationBlock(
            title: 'General',
            items: <SettingsNavigationEntry>[
              SettingsNavigationEntry(
                label: 'Customers and Vendors',
                route: AppRoutes.settingsCustomersAndVendors,
              ),
              SettingsNavigationEntry(
                label: 'Items',
                route: AppRoutes.settingsItems,
              ),
            ],
          ),
          SettingsNavigationBlock(
            title: 'Inventory',
            items: <SettingsNavigationEntry>[
              SettingsNavigationEntry(
                label: 'Assemblies',
                route: AppRoutes.assemblies,
              ),
              SettingsNavigationEntry(
                label: 'Inventory Adjustments',
                route: AppRoutes.inventoryAdjustments,
              ),
              SettingsNavigationEntry(
                label: 'Picklists',
                route: AppRoutes.picklists,
              ),
              SettingsNavigationEntry(
                label: 'Packages',
                route: AppRoutes.packages,
              ),
              SettingsNavigationEntry(
                label: 'Shipments',
                route: AppRoutes.settingsShipments,
              ),
              SettingsNavigationEntry(
                label: 'Transfer Orders',
                route: AppRoutes.settingsTransferOrders,
              ),
            ],
          ),
        ],
      ),
    ];

String normalizeSettingsSidebarPath(String path) {
  final parsedPath = Uri.tryParse(path)?.path;
  final pathname = (parsedPath == null || parsedPath.isEmpty)
      ? path.split('?').first.split('#').first
      : parsedPath;
  return pathname.replaceFirst(RegExp(r'^/\d{10,20}(?=/|$)'), '');
}

bool _isBranchScopedSettingsUser(User? user) {
  if (user == null) return false;
  final role = user.role.trim().toLowerCase();
  final activeTenantType = (user.activeTenantType ?? '').trim().toUpperCase();
  return role == 'branch_admin' ||
      role == 'data_entry' ||
      activeTenantType == 'BRANCH' ||
      user.accessibleBranchIds.isNotEmpty;
}

String? _resolveBranchProfileRoute(User? user) {
  if (!_isBranchScopedSettingsUser(user)) return null;
  final branchId =
      ((user?.activeTenantType ?? '').trim().toUpperCase() == 'BRANCH'
          ? user?.activeTenantId?.trim()
          : null) ??
      user?.defaultBusinessBranchId?.trim() ??
      ((user?.accessibleBranchIds.isNotEmpty ?? false)
          ? user!.accessibleBranchIds.first.trim()
          : '');
  if (branchId.isEmpty) return null;
  return '/settings/branches/$branchId/profile';
}

class SettingsNavigationSidebar extends ConsumerStatefulWidget {
  const SettingsNavigationSidebar({super.key, required this.currentPath});

  final String currentPath;

  @override
  ConsumerState<SettingsNavigationSidebar> createState() =>
      _SettingsNavigationSidebarState();
}

class _SettingsNavigationSidebarState
    extends ConsumerState<SettingsNavigationSidebar> {
  String? _expandedBlockKey;

  @override
  void initState() {
    super.initState();
    _expandedBlockKey =
        _activeBlockKeyForCurrentPath() ??
        _blockKey(
          kSettingsNavigationSections.first.title,
          kSettingsNavigationSections.first.blocks.first,
        );
  }

  @override
  void didUpdateWidget(covariant SettingsNavigationSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath != widget.currentPath) {
      final activeBlockKey = _activeBlockKeyForCurrentPath();
      if (activeBlockKey != null) {
        setState(() => _expandedBlockKey = activeBlockKey);
      }
    }
  }

  String _blockKey(String sectionTitle, SettingsNavigationBlock block) {
    return '$sectionTitle::${block.title}';
  }

  String? _activeBlockKeyForCurrentPath() {
    for (final section in kSettingsNavigationSections) {
      for (final block in section.blocks) {
        if (block.items.any(_isEntryActive)) {
          return _blockKey(section.title, block);
        }
      }
    }
    return null;
  }

  bool _isEntryActive(SettingsNavigationEntry entry) {
    final currentPath = normalizeSettingsSidebarPath(widget.currentPath);
    if (entry.label == 'Profile' &&
        currentPath.startsWith('/settings/branches/') &&
        currentPath.endsWith('/profile')) {
      return true;
    }
    final route = entry.route;
    if (route == null) return false;
    return currentPath == route || currentPath.startsWith('$route/');
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = ref.watch(appBrandingProvider).accentColor;
    final user = ref.watch(authUserProvider);
    final canAccessRoles =
        user == null ||
        CapabilityService.canUserAction(
          user,
          'settings.roles.view',
          action: 'view',
        );
    final sections = _visibleSections(canAccessRoles: canAccessRoles);

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(right: BorderSide(color: AppTheme.borderLight)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.space12,
          AppTheme.space20,
          AppTheme.space12,
          AppTheme.space24,
        ),
        children: [
          for (final section in sections) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.space4,
                bottom: AppTheme.space8,
              ),
              child: Text(
                section.title.toUpperCase(),
                style: AppTheme.captionText.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            for (final block in section.blocks)
              _buildSidebarBlock(section.title, block, accentColor),
            const SizedBox(height: AppTheme.space12),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarBlock(
    String sectionTitle,
    SettingsNavigationBlock block,
    Color accentColor,
  ) {
    final blockKey = _blockKey(sectionTitle, block);
    final bool isExpanded = _expandedBlockKey == blockKey;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space4),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedBlockKey = null;
                } else {
                  _expandedBlockKey = blockKey;
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space8,
                vertical: AppTheme.space10,
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(
                    child: Text(
                      block.title,
                      style: AppTheme.bodyText.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.space28,
                right: AppTheme.space8,
                bottom: AppTheme.space6,
              ),
              child: Column(
                children: block.items
                    .map((entry) => _buildSidebarEntry(entry, accentColor))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarEntry(SettingsNavigationEntry entry, Color accentColor) {
    final bool isActive = _isEntryActive(entry);
    final user = ref.read(authUserProvider);

    return InkWell(
      onTap: () {
        final resolvedRoute = entry.label == 'Profile'
            ? (_resolveBranchProfileRoute(user) ?? entry.route)
            : entry.route;
        if (resolvedRoute == null) {
          ZerpaiToast.info(context, '${entry.label} is not available yet');
          return;
        }
        context.go(resolvedRoute);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppTheme.space4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space10,
        ),
        decoration: BoxDecoration(
          color: isActive ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          entry.label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            color: isActive ? AppTheme.backgroundColor : AppTheme.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  List<SettingsNavigationSection> _visibleSections({
    required bool canAccessRoles,
  }) {
    final user = ref.read(authUserProvider);
    final isBranchScopedUser = _isBranchScopedSettingsUser(user);
    final List<SettingsNavigationSection> sections = [];
    for (final section in kSettingsNavigationSections) {
      final List<SettingsNavigationBlock> blocks = [];
      for (final block in section.blocks) {
        var items = block.items;
        if (block.title == 'Organization' && isBranchScopedUser) {
          items = items.where((entry) => entry.label != 'Branches').toList();
        }
        if (block.title == 'Users & Roles' && isBranchScopedUser) {
          items = items.where((entry) => entry.label != 'Roles').toList();
        }
        if (block.title == 'Users & Roles' && !canAccessRoles) {
          items = items.where((entry) => entry.label != 'Roles').toList();
        }
        if (items.isEmpty) continue;
        blocks.add(SettingsNavigationBlock(title: block.title, items: items));
      }
      if (blocks.isEmpty) continue;
      sections.add(
        SettingsNavigationSection(title: section.title, blocks: blocks),
      );
    }
    return sections;
  }
}
