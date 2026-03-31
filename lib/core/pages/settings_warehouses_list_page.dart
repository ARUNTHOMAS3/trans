import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/widgets/settings_fixed_header_layout.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

const String _kDevOrgId = '00000000-0000-0000-0000-000000000002';

// ─── Sidebar nav ──────────────────────────────────────────────────────────────

class _NavSection {
  final String title;
  final List<_NavBlock> blocks;
  const _NavSection({required this.title, required this.blocks});
}

class _NavBlock {
  final String title;
  final List<_NavEntry> items;
  const _NavBlock({required this.title, required this.items});
}

class _NavEntry {
  final String label;
  final String? route;
  const _NavEntry({required this.label, this.route});
}

const List<_NavSection> _navSections = <_NavSection>[
  _NavSection(
    title: 'Organization Settings',
    blocks: <_NavBlock>[
      _NavBlock(
        title: 'Organization',
        items: <_NavEntry>[
          _NavEntry(label: 'Profile', route: AppRoutes.settingsOrgProfile),
          _NavEntry(label: 'Branding', route: AppRoutes.settingsOrgBranding),
          _NavEntry(label: 'Branches', route: AppRoutes.settingsBranches),
          _NavEntry(label: 'Warehouses', route: AppRoutes.settingsWarehouses),
          _NavEntry(label: 'Approvals'),
          _NavEntry(label: 'Manage Subscription'),
        ],
      ),
      _NavBlock(
        title: 'Users & Roles',
        items: <_NavEntry>[
          _NavEntry(label: 'Users', route: AppRoutes.settingsUsers),
          _NavEntry(label: 'Roles', route: AppRoutes.settingsRoles),
          _NavEntry(label: 'User Preferences'),
        ],
      ),
      _NavBlock(
        title: 'Taxes & Compliance',
        items: <_NavEntry>[
          _NavEntry(label: 'Taxes'),
          _NavEntry(label: 'Direct Taxes'),
          _NavEntry(label: 'e-Way Bills'),
          _NavEntry(label: 'e-Invoicing'),
          _NavEntry(label: 'MSME Settings'),
        ],
      ),
      _NavBlock(
        title: 'Setup & Configurations',
        items: <_NavEntry>[
          _NavEntry(label: 'General'),
          _NavEntry(label: 'Currencies'),
          _NavEntry(label: 'Reminders'),
          _NavEntry(label: 'Customer Portal'),
        ],
      ),
      _NavBlock(
        title: 'Customization',
        items: <_NavEntry>[
          _NavEntry(label: 'Transaction Number Series'),
          _NavEntry(label: 'PDF Templates'),
          _NavEntry(label: 'Email Notifications'),
          _NavEntry(label: 'SMS Notifications'),
          _NavEntry(label: 'Reporting Tags'),
          _NavEntry(label: 'Web Tabs'),
        ],
      ),
      _NavBlock(
        title: 'Automation',
        items: <_NavEntry>[
          _NavEntry(label: 'Workflow Rules'),
          _NavEntry(label: 'Workflow Actions'),
          _NavEntry(label: 'Workflow Logs', route: AppRoutes.auditLogs),
        ],
      ),
    ],
  ),
  _NavSection(
    title: 'Module Settings',
    blocks: <_NavBlock>[
      _NavBlock(
        title: 'General',
        items: <_NavEntry>[
          _NavEntry(
            label: 'Customers and Vendors',
            route: AppRoutes.salesCustomers,
          ),
          _NavEntry(label: 'Items', route: AppRoutes.itemsReport),
        ],
      ),
    ],
  ),
];

// ─── Model ────────────────────────────────────────────────────────────────────

class _WarehouseRow {
  final String id;
  final String name;
  final String warehouseCode;
  final String parentBranchName;
  final String? customerId;
  final String? vendorId;
  final String customerName;
  final String vendorName;
  final String city;
  final String state;
  final String country;
  final bool isActive;

  const _WarehouseRow({
    required this.id,
    required this.name,
    required this.warehouseCode,
    required this.parentBranchName,
    required this.customerId,
    required this.vendorId,
    required this.customerName,
    required this.vendorName,
    required this.city,
    required this.state,
    required this.country,
    required this.isActive,
  });

  factory _WarehouseRow.fromJson(
    Map<String, dynamic> j,
    Map<String, String> branchNames,
  ) => _WarehouseRow(
    id: (j['id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    warehouseCode: (j['warehouse_code'] ?? '').toString(),
    parentBranchName: (j['parent_branch_name'] ?? '').toString().isNotEmpty
        ? (j['parent_branch_name'] ?? '').toString()
        : '—',
    customerId: (j['customer_id'] ?? '').toString().trim().isNotEmpty
        ? (j['customer_id'] ?? '').toString().trim()
        : null,
    vendorId: (j['vendor_id'] ?? '').toString().trim().isNotEmpty
        ? (j['vendor_id'] ?? '').toString().trim()
        : null,
    customerName: (j['customer_name'] ?? '').toString().trim(),
    vendorName: (j['vendor_name'] ?? '').toString().trim(),
    city: (j['city'] ?? '').toString(),
    state: (j['state'] ?? '').toString(),
    country: (j['country'] ?? 'India').toString(),
    isActive: j['is_active'] as bool? ?? true,
  );

  String get addressSummary {
    final parts = <String>[
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (country.isNotEmpty) country,
    ];
    return parts.join(', ');
  }
}

class _ContactOption {
  final String id;
  final String name;
  const _ContactOption({required this.id, required this.name});
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class SettingsWarehousesListPage extends ConsumerStatefulWidget {
  const SettingsWarehousesListPage({super.key});

  @override
  ConsumerState<SettingsWarehousesListPage> createState() =>
      _SettingsWarehousesListPageState();
}

class _SettingsWarehousesListPageState
    extends ConsumerState<SettingsWarehousesListPage> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _expandedBlocks = <String>{'Organization'};

  bool _isLoading = true;
  String? _hoveredId;
  String _organizationName = '';
  List<_WarehouseRow> _warehouses = <_WarehouseRow>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String get _currentOrgId {
    final user = ref.read(authUserProvider);
    return (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
  }

  _ContactOption? _findContactById(List<_ContactOption> items, String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authUserProvider);
      final orgId = _currentOrgId;

      final orgRes = await _apiClient.get('lookups/org/$orgId');
      if (!mounted) return;
      if (orgRes.success && orgRes.data is Map<String, dynamic>) {
        _organizationName =
            ((orgRes.data as Map<String, dynamic>)['name'] ??
                    user?.orgName ??
                    '')
                .toString()
                .trim();
      } else {
        _organizationName = user?.orgName ?? '';
      }

      final res = await _apiClient.get(
        'warehouses-settings',
        queryParameters: <String, dynamic>{'org_id': orgId},
      );
      if (!mounted) return;
      final List<dynamic> all = res.success && res.data is List
          ? res.data as List<dynamic>
          : [];

      setState(() {
        _warehouses = all
            .whereType<Map<String, dynamic>>()
            .map((j) => _WarehouseRow.fromJson(j, const {}))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
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
        color: AppTheme.bgLight,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSidebar(),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top bar ───────────────────────────────────────────────────────────────

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
                                  _organizationName.isNotEmpty
                                      ? _organizationName
                                      : 'Your Organization',
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
                      items: const <SettingsSearchItem>[],
                      focusNode: _searchFocusNode,
                      controller: _searchController,
                      onQueryChanged: (_) {},
                      onNoMatch: (q) =>
                          ZerpaiToast.info(context, 'No settings matched "$q"'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space24),
              TextButton.icon(
                onPressed: () => context.go(AppRoutes.settings),
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

  // ─── Sidebar ───────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    final String currentPath = GoRouterState.of(
      context,
    ).uri.path.replaceFirst(RegExp(r'^/\d{10,20}'), '');

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
            for (final block in section.blocks)
              _buildSidebarBlock(block, currentPath),
            const SizedBox(height: AppTheme.space12),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarBlock(_NavBlock block, String currentPath) {
    final bool hasActiveChild = block.items.any(
      (item) => item.route == currentPath,
    );
    final bool isExpanded =
        _expandedBlocks.contains(block.title) || hasActiveChild;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space4),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedBlocks.remove(block.title);
              } else {
                _expandedBlocks.add(block.title);
              }
            }),
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
                    .map((e) => _buildSidebarEntry(e, currentPath))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarEntry(_NavEntry entry, String currentPath) {
    final bool isActive = entry.route == currentPath;
    final Color accentColor = ref.watch(appBrandingProvider).accentColor;

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

  // ─── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return SettingsFixedHeaderLayout(
      maxWidth: double.infinity,
      header: _buildHeader(),
      body: _buildTable(),
    );
  }

  Widget _buildHeader() {
    final accentColor = ref.watch(appBrandingProvider).accentColor;
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Warehouses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: AppTheme.space4),
              Text(
                'Manage your warehouse and storage locations.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => context.go(AppRoutes.settingsWarehouseCreate),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space20,
              vertical: AppTheme.space12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text(
            'Add Warehouse',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppTheme.space32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_warehouses.isEmpty)
            _buildEmptyState()
          else
            ..._warehouses.map(_buildRow),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
      letterSpacing: 0.4,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 20),
          SizedBox(width: AppTheme.space12),
          Expanded(flex: 4, child: Text('NAME', style: style)),
          SizedBox(width: 180, child: Text('WAREHOUSE CODE', style: style)),
          Expanded(flex: 3, child: Text('PARENT BRANCH', style: style)),
          Expanded(flex: 4, child: Text('ADDRESS DETAILS', style: style)),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildRow(_WarehouseRow warehouse) {
    final bool isHovered = _hoveredId == warehouse.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredId = warehouse.id),
      onExit: (_) => setState(() => _hoveredId = null),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space20,
          vertical: AppTheme.space14,
        ),
        decoration: BoxDecoration(
          color: isHovered ? AppTheme.bgLight : Colors.white,
          border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: warehouse.isActive
                    ? const Color(0xFF22A95E)
                    : Colors.transparent,
                border: Border.all(
                  color: warehouse.isActive
                      ? const Color(0xFF22A95E)
                      : AppTheme.textSecondary,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            // Name
            Expanded(
              flex: 4,
              child: Text(
                warehouse.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            // Warehouse code
            SizedBox(
              width: 180,
              child: Text(
                warehouse.warehouseCode.isNotEmpty
                    ? warehouse.warehouseCode
                    : '—',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            // Parent branch
            Expanded(
              flex: 3,
              child: Text(
                warehouse.parentBranchName,
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ),
            // Address
            Expanded(
              flex: 4,
              child: Text(
                warehouse.addressSummary.isNotEmpty
                    ? warehouse.addressSummary
                    : '—',
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ),
            // Actions
            SizedBox(
              width: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildActionMenu(warehouse, isHovered),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenu(_WarehouseRow warehouse, bool isHovered) {
    final Color accentColor = ref.watch(appBrandingProvider).accentColor;
    final MenuController controller = MenuController();

    MenuItemButton buildItem(String label, VoidCallback onPressed) {
      return MenuItemButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return AppTheme.primaryBlue;
            }
            return Colors.white;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return Colors.white;
            }
            return AppTheme.textPrimary;
          }),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          minimumSize: WidgetStateProperty.all(const Size(170, 40)),
        ),
        onPressed: () {
          controller.close();
          onPressed();
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return MenuAnchor(
      controller: controller,
      crossAxisUnconstrained: false,
      alignmentOffset: const Offset(-154, 8),
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        surfaceTintColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(8),
        padding: WidgetStateProperty.all(const EdgeInsets.all(8)),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppTheme.borderLight),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      menuChildren: [
        buildItem('Edit', () {
          context.go(
            AppRoutes.settingsWarehouseEdit.replaceFirst(':id', warehouse.id),
          );
        }),
        buildItem(
          warehouse.isActive ? 'Mark as Inactive' : 'Mark as Active',
          () => _toggleWarehouseActive(warehouse),
        ),
        buildItem('Delete', () => _confirmDelete(warehouse)),
        buildItem(
          warehouse.isActive ? 'Disable bin locations' : 'Enable bin locations',
          () => _openBinLocations(warehouse),
        ),
        buildItem(
          'Associate Contacts',
          () => _showAssociateContactsDialog(warehouse),
        ),
      ],
      builder: (context, menuController, child) {
        return IconButton(
          onPressed: () {
            if (menuController.isOpen) {
              menuController.close();
            } else {
              menuController.open();
            }
          },
          splashRadius: 18,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: isHovered
                ? Icon(
                    LucideIcons.chevronDown,
                    key: const ValueKey('chevron'),
                    size: 16,
                    color: accentColor,
                  )
                : const Icon(
                    LucideIcons.moreHorizontal,
                    key: ValueKey('dots'),
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
          ),
        );
      },
    );
  }

  Future<void> _toggleWarehouseActive(_WarehouseRow warehouse) async {
    final nextActive = !warehouse.isActive;
    try {
      final res = await _apiClient.put(
        'warehouses-settings/${warehouse.id}',
        data: {'org_id': _currentOrgId, 'is_active': nextActive},
      );
      if (!mounted) return;
      if (res.success) {
        ZerpaiToast.success(
          context,
          nextActive
              ? 'Warehouse marked as active'
              : 'Warehouse marked as inactive',
        );
        _load();
      } else {
        ZerpaiToast.error(
          context,
          res.message ?? 'Failed to update warehouse status',
        );
      }
    } catch (_) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to update warehouse status');
      }
    }
  }

  Future<void> _confirmDelete(_WarehouseRow warehouse) async {
    final cancelled = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Warehouse',
      message: 'Delete "${warehouse.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (cancelled || !mounted) return;

    try {
      final res = await _apiClient.delete(
        'warehouses-settings/${warehouse.id}?org_id=$_currentOrgId',
      );
      if (!mounted) return;
      if (res.success) {
        ZerpaiToast.success(context, 'Warehouse deleted');
        _load();
      } else {
        ZerpaiToast.error(context, res.message ?? 'Failed to delete warehouse');
      }
    } catch (_) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to delete warehouse');
      }
    }
  }

  Future<void> _openBinLocations(_WarehouseRow warehouse) async {
    await _showTopCenteredWarehouseDialog(
      title: warehouse.isActive
          ? 'Disable Bin Locations'
          : 'Enable Bin Locations',
      body: Text(
        warehouse.isActive
            ? 'Do you want to disable bin locations for ${warehouse.name}? Bin locations are managed from Locations settings.'
            : 'Do you want to enable bin locations for ${warehouse.name}? Bin locations are managed from Locations settings.',
        style: const TextStyle(
          fontSize: 14,
          height: 1.55,
          color: AppTheme.textSecondary,
        ),
      ),
      confirmLabel: 'Open Locations',
      onConfirm: () async {
        if (!mounted) return;
        context.go(AppRoutes.settingsLocations);
      },
    );
  }

  Future<void> _showAssociateContactsDialog(_WarehouseRow warehouse) async {
    final orgId = _currentOrgId;
    List<_ContactOption> customers = [];
    List<_ContactOption> vendors = [];
    String? selectedCustomerId = warehouse.customerId;
    String? selectedVendorId = warehouse.vendorId;

    try {
      final res = await _apiClient.get(
        'accountant/contacts',
        queryParameters: {'orgId': orgId},
      );
      if (res.success && res.data is List) {
        final contacts = (res.data as List).whereType<Map<String, dynamic>>();
        customers = contacts
            .where(
              (item) =>
                  ((item['contact_type'] ?? item['type']) ?? '')
                      .toString()
                      .trim()
                      .toLowerCase() ==
                  'customer',
            )
            .map(
              (item) => _ContactOption(
                id: (item['id'] ?? '').toString(),
                name: ((item['displayName'] ?? item['display_name']) ?? '')
                    .toString(),
              ),
            )
            .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
            .toList();
        vendors = contacts
            .where(
              (item) =>
                  ((item['contact_type'] ?? item['type']) ?? '')
                      .toString()
                      .trim()
                      .toLowerCase() ==
                  'vendor',
            )
            .map(
              (item) => _ContactOption(
                id: (item['id'] ?? '').toString(),
                name: ((item['displayName'] ?? item['display_name']) ?? '')
                    .toString(),
              ),
            )
            .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
            .toList();
      }
    } catch (_) {}

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final accentColor = ref.watch(appBrandingProvider).accentColor;
          return SafeArea(
            child: Dialog(
              alignment: Alignment.topCenter,
              insetPadding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 18, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Associate Customer and Vendor',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(LucideIcons.x, size: 18),
                            color: AppTheme.errorRed,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'The customer and vendor you select here will be used for warehouse transfer flows tied to ${warehouse.name}.',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.55,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space20),
                          const Text(
                            'Customer Name',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textBody,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space6),
                          FormDropdown<_ContactOption>(
                            value: _findContactById(
                              customers,
                              selectedCustomerId,
                            ),
                            items: customers,
                            displayStringForValue: (c) => c.name,
                            hint: 'Select customer',
                            allowClear: true,
                            onChanged: (c) => setDialogState(
                              () => selectedCustomerId = c?.id,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space16),
                          const Text(
                            'Vendor Name',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textBody,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space6),
                          FormDropdown<_ContactOption>(
                            value: _findContactById(vendors, selectedVendorId),
                            items: vendors,
                            displayStringForValue: (v) => v.name,
                            hint: 'Select a Vendor',
                            allowClear: true,
                            onChanged: (v) =>
                                setDialogState(() => selectedVendorId = v?.id),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.of(dialogContext).pop();
                              try {
                                final res = await _apiClient.put(
                                  'warehouses-settings/${warehouse.id}',
                                  data: {
                                    'org_id': orgId,
                                    'customer_id': selectedCustomerId,
                                    'vendor_id': selectedVendorId,
                                  },
                                );
                                if (!mounted) return;
                                if (res.success) {
                                  ZerpaiToast.success(
                                    context,
                                    'Contacts associated',
                                  );
                                  _load();
                                } else {
                                  ZerpaiToast.error(
                                    context,
                                    res.message ??
                                        'Failed to associate contacts',
                                  );
                                }
                              } catch (_) {
                                if (mounted) {
                                  ZerpaiToast.error(
                                    context,
                                    'Failed to associate contacts',
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text(
                              'Update',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space12),
                          OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textPrimary,
                              side: const BorderSide(
                                color: AppTheme.borderColor,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showTopCenteredWarehouseDialog({
    required String title,
    required Widget body,
    required String confirmLabel,
    required Future<void> Function() onConfirm,
    String cancelLabel = 'Cancel',
    double maxWidth = 560,
  }) async {
    final accentColor = ref.read(appBrandingProvider).accentColor;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return SafeArea(
          child: Dialog(
            alignment: Alignment.topCenter,
            insetPadding: EdgeInsets.zero,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 18, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(LucideIcons.x, size: 18),
                          color: AppTheme.errorRed,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.borderLight),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: body,
                  ),
                  const Divider(height: 1, color: AppTheme.borderLight),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            await onConfirm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            confirmLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(color: AppTheme.borderColor),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            cancelLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space32),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.infoBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                LucideIcons.warehouse,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            const Text(
              'No warehouses yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            const Text(
              'Add your first warehouse to manage storage locations.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
