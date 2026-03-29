import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

const String kSettingsDevOrgId = '00000000-0000-0000-0000-000000000002';

String currentSettingsOrgId(WidgetRef ref) {
  final user = ref.read(authUserProvider);
  return user?.orgId.isNotEmpty == true ? user!.orgId : kSettingsDevOrgId;
}

String currentSettingsOrgName(WidgetRef ref) {
  final user = ref.watch(authUserProvider);
  if (user?.orgName.trim().isNotEmpty == true) {
    return user!.orgName.trim();
  }
  return 'Your Organization';
}

class SettingsUserRecord {
  SettingsUserRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.accessibleLocationCount = 0,
    this.accessibleLocations = const <SettingsLocationRecord>[],
    this.defaultBusinessOutletId,
    this.defaultWarehouseOutletId,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String? createdAt;
  final int accessibleLocationCount;
  final List<SettingsLocationRecord> accessibleLocations;
  final String? defaultBusinessOutletId;
  final String? defaultWarehouseOutletId;

  String get statusLabel => isActive ? 'Active' : 'Inactive';

  String get roleLabel {
    switch (role.trim().toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'manager':
        return 'Manager';
      default:
        return 'Staff';
    }
  }

  factory SettingsUserRecord.fromJson(Map<String, dynamic> json) {
    final accessibleLocations =
        (json['accessible_locations'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (item) => SettingsLocationRecord.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();

    return SettingsUserRecord(
      id: (json['id'] ?? '').toString(),
      name: ((json['name'] ?? json['full_name'] ?? json['email']) ?? '')
          .toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'staff').toString(),
      isActive: json['is_active'] == true,
      createdAt: json['created_at']?.toString(),
      accessibleLocationCount: json['accessible_location_count'] is num
          ? (json['accessible_location_count'] as num).toInt()
          : accessibleLocations.length,
      accessibleLocations: accessibleLocations,
      defaultBusinessOutletId: json['default_business_outlet_id']?.toString(),
      defaultWarehouseOutletId: json['default_warehouse_outlet_id']?.toString(),
    );
  }
}

class SettingsLocationRecord {
  SettingsLocationRecord({
    required this.id,
    required this.name,
    required this.locationType,
    this.parentOutletId,
    this.isPrimary = false,
    this.isActive = true,
    this.isDefaultBusiness = false,
    this.isDefaultWarehouse = false,
  });

  final String id;
  final String name;
  final String locationType;
  final String? parentOutletId;
  final bool isPrimary;
  final bool isActive;
  final bool isDefaultBusiness;
  final bool isDefaultWarehouse;

  bool get isWarehouse => locationType.toLowerCase() == 'warehouse';
  bool get isBusiness => !isWarehouse;
  String get typeLabel => isWarehouse ? 'Warehouse' : 'Business';

  factory SettingsLocationRecord.fromJson(Map<String, dynamic> json) {
    return SettingsLocationRecord(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      locationType: (json['location_type'] ?? 'business').toString(),
      parentOutletId: json['parent_outlet_id']?.toString(),
      isPrimary: json['is_primary'] == true,
      isActive: json['is_active'] != false,
      isDefaultBusiness: json['is_default_business'] == true,
      isDefaultWarehouse: json['is_default_warehouse'] == true,
    );
  }
}

class SettingsRoleRecord {
  const SettingsRoleRecord({
    required this.id,
    required this.label,
    required this.description,
    required this.userCount,
  });

  final String id;
  final String label;
  final String description;
  final int userCount;

  factory SettingsRoleRecord.fromJson(Map<String, dynamic> json) {
    return SettingsRoleRecord(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      userCount: json['user_count'] is num
          ? (json['user_count'] as num).toInt()
          : 0,
    );
  }
}

class SettingsUsersRolesShell extends ConsumerStatefulWidget {
  const SettingsUsersRolesShell({
    super.key,
    required this.activeRoute,
    required this.child,
  });

  final String activeRoute;
  final Widget child;

  @override
  ConsumerState<SettingsUsersRolesShell> createState() =>
      _SettingsUsersRolesShellState();
}

class _SettingsUsersRolesShellState
    extends ConsumerState<SettingsUsersRolesShell> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _expandedBlocks = <String>{'Organization', 'Users & Roles'};

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '',
      useHorizontalPadding: false,
      useTopPadding: false,
      enableBodyScroll: false,
      searchFocusNode: _searchFocusNode,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSidebar(context),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space32,
        AppTheme.space20,
        AppTheme.space32,
        AppTheme.space16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1560),
          child: Row(
            children: [
              SizedBox(
                width: 320,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => context.go(AppRoutes.settings),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: const Icon(
                          LucideIcons.chevronLeft,
                          size: 20,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3EE),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFFED7C3),
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.settings2,
                              color: Color(0xFFF97316),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('All Settings', style: AppTheme.pageTitle),
                                const SizedBox(height: AppTheme.space4),
                                Text(
                                  currentSettingsOrgName(ref),
                                  style: AppTheme.bodyText,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space24),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 360,
                    height: 42,
                    child: SettingsSearchField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      items: <SettingsSearchItem>[
                        SettingsSearchItem(
                          group: 'Users & Roles',
                          label: 'Users',
                          subtitle: 'Organization Settings',
                          onSelected: () => context.go(AppRoutes.settingsUsers),
                        ),
                        SettingsSearchItem(
                          group: 'Users & Roles',
                          label: 'Roles',
                          subtitle: 'Organization Settings',
                          onSelected: () => context.go(AppRoutes.settingsRoles),
                        ),
                      ],
                      onNoMatch: (_) {},
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space24),
              TextButton.icon(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.go(AppRoutes.home);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  backgroundColor: AppTheme.bgLight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                    vertical: AppTheme.space12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  LucideIcons.x,
                  size: 16,
                  color: AppTheme.errorRed,
                ),
                label: const Text('Close Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
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
          for (final section in _navSections) ...[
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
            for (final block in section.blocks) ...[
              _buildBlockHeader(block.title),
              if (_expandedBlocks.contains(block.title))
                ...block.items.map((entry) => _buildNavEntry(context, entry)),
              const SizedBox(height: AppTheme.space8),
            ],
            const SizedBox(height: AppTheme.space8),
          ],
        ],
      ),
    );
  }

  Widget _buildBlockHeader(String title) {
    final expanded = _expandedBlocks.contains(title);
    return InkWell(
      onTap: () {
        setState(() {
          if (expanded) {
            _expandedBlocks.remove(title);
          } else {
            _expandedBlocks.add(title);
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space4,
          vertical: AppTheme.space8,
        ),
        child: Row(
          children: [
            Icon(
              expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: AppTheme.space8),
            Expanded(
              child: Text(
                title,
                style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavEntry(BuildContext context, _SettingsNavEntry entry) {
    final bool isActive = entry.route == widget.activeRoute;
    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.space24, bottom: 4),
      child: InkWell(
        onTap: entry.route == null ? null : () => context.go(entry.route!),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space10,
          ),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.successGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              entry.label,
              style: AppTheme.bodyText.copyWith(
                color: isActive ? Colors.white : AppTheme.textBody,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsNavSection {
  const _SettingsNavSection({required this.title, required this.blocks});

  final String title;
  final List<_SettingsNavBlock> blocks;
}

class _SettingsNavBlock {
  const _SettingsNavBlock({required this.title, required this.items});

  final String title;
  final List<_SettingsNavEntry> items;
}

class _SettingsNavEntry {
  const _SettingsNavEntry({required this.label, this.route});

  final String label;
  final String? route;
}

const List<_SettingsNavSection> _navSections = <_SettingsNavSection>[
  _SettingsNavSection(
    title: 'Organization Settings',
    blocks: <_SettingsNavBlock>[
      _SettingsNavBlock(
        title: 'Organization',
        items: <_SettingsNavEntry>[
          _SettingsNavEntry(
            label: 'Profile',
            route: AppRoutes.settingsOrgProfile,
          ),
          _SettingsNavEntry(
            label: 'Branding',
            route: AppRoutes.settingsOrgBranding,
          ),
          _SettingsNavEntry(
            label: 'Branches',
            route: AppRoutes.settingsBranches,
          ),
          _SettingsNavEntry(
            label: 'Warehouses',
            route: AppRoutes.settingsWarehouses,
          ),
          _SettingsNavEntry(label: 'Approvals'),
          _SettingsNavEntry(label: 'Manage Subscription'),
        ],
      ),
      _SettingsNavBlock(
        title: 'Users & Roles',
        items: <_SettingsNavEntry>[
          _SettingsNavEntry(label: 'Users', route: AppRoutes.settingsUsers),
          _SettingsNavEntry(label: 'Roles', route: AppRoutes.settingsRoles),
          _SettingsNavEntry(label: 'User Preferences'),
        ],
      ),
      _SettingsNavBlock(
        title: 'Taxes & Compliance',
        items: <_SettingsNavEntry>[
          _SettingsNavEntry(label: 'Taxes'),
          _SettingsNavEntry(label: 'Direct Taxes'),
          _SettingsNavEntry(label: 'e-Way Bills'),
          _SettingsNavEntry(label: 'e-Invoicing'),
          _SettingsNavEntry(label: 'MSME Settings'),
        ],
      ),
      _SettingsNavBlock(
        title: 'Setup & Configurations',
        items: <_SettingsNavEntry>[
          _SettingsNavEntry(label: 'General'),
          _SettingsNavEntry(label: 'Currencies'),
          _SettingsNavEntry(label: 'Reminders'),
          _SettingsNavEntry(label: 'Customer Portal'),
        ],
      ),
      _SettingsNavBlock(
        title: 'Customization',
        items: <_SettingsNavEntry>[
          _SettingsNavEntry(label: 'Transaction Number Series'),
          _SettingsNavEntry(label: 'PDF Templates'),
          _SettingsNavEntry(label: 'Email Notifications'),
          _SettingsNavEntry(label: 'SMS Notifications'),
          _SettingsNavEntry(label: 'Reporting Tags'),
          _SettingsNavEntry(label: 'Web Tabs'),
        ],
      ),
      _SettingsNavBlock(
        title: 'Automation',
        items: <_SettingsNavEntry>[
          _SettingsNavEntry(label: 'Workflow Rules'),
          _SettingsNavEntry(label: 'Workflow Actions'),
          _SettingsNavEntry(label: 'Workflow Logs', route: AppRoutes.auditLogs),
        ],
      ),
    ],
  ),
  _SettingsNavSection(
    title: 'Module Settings',
    blocks: <_SettingsNavBlock>[
      _SettingsNavBlock(
        title: 'General',
        items: <_SettingsNavEntry>[
          _SettingsNavEntry(
            label: 'Customers and Vendors',
            route: AppRoutes.salesCustomers,
          ),
          _SettingsNavEntry(label: 'Items', route: AppRoutes.itemsReport),
        ],
      ),
      _SettingsNavBlock(
        title: 'Inventory',
        items: <_SettingsNavEntry>[
          _SettingsNavEntry(label: 'Assemblies', route: AppRoutes.assemblies),
          _SettingsNavEntry(
            label: 'Inventory Adjustments',
            route: AppRoutes.inventoryAdjustments,
          ),
          _SettingsNavEntry(label: 'Picklists', route: AppRoutes.picklists),
          _SettingsNavEntry(label: 'Packages', route: AppRoutes.packages),
          _SettingsNavEntry(label: 'Shipments', route: AppRoutes.shipments),
          _SettingsNavEntry(
            label: 'Transfer Orders',
            route: AppRoutes.transferOrders,
          ),
        ],
      ),
    ],
  ),
];
