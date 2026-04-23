import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
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
              SettingsNavigationEntry(label: 'Approvals'),
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
              SettingsNavigationEntry(label: 'User Preferences'),
            ],
          ),
          SettingsNavigationBlock(
            title: 'Taxes & Compliance',
            items: <SettingsNavigationEntry>[
              SettingsNavigationEntry(label: 'Taxes'),
              SettingsNavigationEntry(label: 'Direct Taxes'),
              SettingsNavigationEntry(label: 'e-Way Bills'),
              SettingsNavigationEntry(label: 'e-Invoicing'),
              SettingsNavigationEntry(label: 'MSME Settings'),
            ],
          ),
          SettingsNavigationBlock(
            title: 'Setup & Configurations',
            items: <SettingsNavigationEntry>[
              SettingsNavigationEntry(label: 'General'),
              SettingsNavigationEntry(label: 'Currencies'),
              SettingsNavigationEntry(label: 'Reminders'),
              SettingsNavigationEntry(label: 'Customer Portal'),
            ],
          ),
          SettingsNavigationBlock(
            title: 'Customization',
            items: <SettingsNavigationEntry>[
              SettingsNavigationEntry(label: 'Transaction Number Series'),
              SettingsNavigationEntry(label: 'PDF Templates'),
              SettingsNavigationEntry(label: 'Email Notifications'),
              SettingsNavigationEntry(label: 'SMS Notifications'),
              SettingsNavigationEntry(label: 'Reporting Tags'),
              SettingsNavigationEntry(label: 'Web Tabs'),
            ],
          ),
          SettingsNavigationBlock(
            title: 'Automation',
            items: <SettingsNavigationEntry>[
              SettingsNavigationEntry(label: 'Workflow Rules'),
              SettingsNavigationEntry(label: 'Workflow Actions'),
              SettingsNavigationEntry(
                label: 'Workflow Logs',
                route: AppRoutes.auditLogs,
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
                route: AppRoutes.salesCustomers,
              ),
              SettingsNavigationEntry(
                label: 'Items',
                route: AppRoutes.itemsReport,
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
                route: AppRoutes.shipments,
              ),
              SettingsNavigationEntry(
                label: 'Transfer Orders',
                route: AppRoutes.transferOrders,
              ),
            ],
          ),
        ],
      ),
    ];

String normalizeSettingsSidebarPath(String path) {
  return path.replaceFirst(RegExp(r'^/\d{10,20}'), '');
}

class SettingsNavigationSidebar extends ConsumerStatefulWidget {
  const SettingsNavigationSidebar({
    super.key,
    required this.currentPath,
  });

  final String currentPath;

  @override
  ConsumerState<SettingsNavigationSidebar> createState() =>
      _SettingsNavigationSidebarState();
}

class _SettingsNavigationSidebarState
    extends ConsumerState<SettingsNavigationSidebar> {
  late final Set<String> _expandedBlocks;

  @override
  void initState() {
    super.initState();
    _expandedBlocks = <String>{'Organization'};
    for (final section in kSettingsNavigationSections) {
      for (final block in section.blocks) {
        if (block.items.any(_isEntryActive)) {
          _expandedBlocks.add(block.title);
        }
      }
    }
  }

  bool _isEntryActive(SettingsNavigationEntry entry) {
    final route = entry.route;
    if (route == null) return false;
    final currentPath = normalizeSettingsSidebarPath(widget.currentPath);
    return currentPath == route || currentPath.startsWith('$route/');
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = ref.watch(appBrandingProvider).accentColor;

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Colors.white,
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
          for (final section in kSettingsNavigationSections) ...[
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
              _buildSidebarBlock(block, accentColor),
            const SizedBox(height: AppTheme.space12),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarBlock(
    SettingsNavigationBlock block,
    Color accentColor,
  ) {
    final bool hasActiveChild = block.items.any(_isEntryActive);
    final bool isExpanded =
        _expandedBlocks.contains(block.title) || hasActiveChild;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space4),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedBlocks.remove(block.title);
                } else {
                  _expandedBlocks.add(block.title);
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

    return InkWell(
      onTap: () {
        if (entry.route == null) {
          ZerpaiToast.info(context, '${entry.label} is not available yet');
          return;
        }
        context.go(entry.route!);
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
            color: isActive ? Colors.white : AppTheme.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
