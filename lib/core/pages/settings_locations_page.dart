import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/widgets/settings_search_field.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

const String _kDevOrgId = '00000000-0000-0000-0000-000000000002';

// ─── Nav data (mirrors other settings pages) ─────────────────────────────────

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
          _NavEntry(label: 'Locations', route: AppRoutes.settingsLocations),
          _NavEntry(label: 'Approvals'),
          _NavEntry(label: 'Manage Subscription'),
        ],
      ),
      _NavBlock(
        title: 'Users & Roles',
        items: <_NavEntry>[
          _NavEntry(label: 'Users'),
          _NavEntry(label: 'Roles'),
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
          _NavEntry(label: 'Customers and Vendors', route: AppRoutes.salesCustomers),
          _NavEntry(label: 'Items', route: AppRoutes.itemsReport),
        ],
      ),
      _NavBlock(
        title: 'Inventory',
        items: <_NavEntry>[
          _NavEntry(label: 'Assemblies', route: AppRoutes.assemblies),
          _NavEntry(label: 'Inventory Adjustments', route: AppRoutes.inventoryAdjustments),
          _NavEntry(label: 'Picklists', route: AppRoutes.picklists),
          _NavEntry(label: 'Packages', route: AppRoutes.packages),
          _NavEntry(label: 'Shipments', route: AppRoutes.shipments),
          _NavEntry(label: 'Transfer Orders', route: AppRoutes.transferOrders),
        ],
      ),
    ],
  ),
];

// ─── Model ────────────────────────────────────────────────────────────────────

class _OutletRow {
  final String id;
  final String name;
  final String outletCode;
  final String gstin;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final bool isActive;
  final String locationType; // 'business' | 'warehouse'

  const _OutletRow({
    required this.id,
    required this.name,
    required this.outletCode,
    required this.gstin,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.isActive,
    required this.locationType,
  });

  factory _OutletRow.fromJson(Map<String, dynamic> j) => _OutletRow(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        outletCode: (j['outlet_code'] ?? '').toString(),
        gstin: (j['gstin'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        address: (j['address'] ?? '').toString(),
        city: (j['city'] ?? '').toString(),
        state: (j['state'] ?? '').toString(),
        country: (j['country'] ?? 'India').toString(),
        pincode: (j['pincode'] ?? '').toString(),
        isActive: j['is_active'] as bool? ?? true,
        locationType: (j['location_type'] ?? 'business').toString(),
      );

  bool get isWarehouse => locationType == 'warehouse';

  String get addressSummary {
    final parts = <String>[
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (country.isNotEmpty) country,
    ];
    return parts.join(', ');
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class SettingsLocationsPage extends ConsumerStatefulWidget {
  const SettingsLocationsPage({super.key});

  @override
  ConsumerState<SettingsLocationsPage> createState() =>
      _SettingsLocationsPageState();
}

class _SettingsLocationsPageState extends ConsumerState<SettingsLocationsPage> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _expandedBlocks = <String>{'Organization'};

  bool _isLoading = true;
  String? _hoveredOutletId;
  String? _error;
  String _organizationName = '';
  List<_OutletRow> _outlets = <_OutletRow>[];

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

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = ref.read(authUserProvider);
      final String orgId =
          (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;

      // Load org name for the top bar
      final orgRes = await _apiClient.get('/lookups/org/$orgId');
      if (!mounted) return;
      if (orgRes.success && orgRes.data is Map<String, dynamic>) {
        _organizationName =
            ((orgRes.data as Map<String, dynamic>)['name'] ?? user?.orgName ?? '')
                .toString()
                .trim();
      } else {
        _organizationName = user?.orgName ?? '';
      }

      // Load outlets
      final outletsRes = await _apiClient.get(
        '/outlets',
        queryParameters: <String, dynamic>{'org_id': orgId},
      );
      if (!mounted) return;
      final List<dynamic> rows = outletsRes.success && outletsRes.data is List
          ? outletsRes.data as List<dynamic>
          : <dynamic>[];
      setState(() {
        _outlets = rows
            .whereType<Map<String, dynamic>>()
            .map(_OutletRow.fromJson)
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _outlets = <_OutletRow>[];
      });
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
                              border: Border.all(color: const Color(0xFFFED7C3)),
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
                icon: const Icon(LucideIcons.x, size: 16, color: AppTheme.errorRed),
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
    final String currentPath = GoRouterState.of(context)
        .uri
        .path
        .replaceFirst(RegExp(r'^/\d{10,20}'), '');

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
    final bool hasActiveChild =
        block.items.any((item) => item.route == currentPath);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBodyHeader(),
            const SizedBox(height: AppTheme.space24),
            _buildTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyHeader() {
    final accentColor = ref.watch(appBrandingProvider).accentColor;
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Locations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: AppTheme.space4),
              Text(
                'Manage your business locations and warehouses.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => context.go(AppRoutes.settingsLocationsCreate),
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
            'Add Location',
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
          else if (_error != null)
            _buildErrorState()
          else if (_outlets.isEmpty)
            _buildEmptyState()
          else
            ..._outlets.map(_buildTableRow),
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
          SizedBox(width: 20), // status dot column
          SizedBox(width: AppTheme.space12),
          Expanded(flex: 3, child: Text('NAME', style: style)),
          Expanded(flex: 2, child: Text('GSTIN', style: style)),
          Expanded(flex: 2, child: Text('DEFAULT TRANSACTION SERIES', style: style)),
          Expanded(flex: 1, child: Text('TYPE', style: style)),
          Expanded(flex: 1, child: Text('ASSOCIATED ZONES', style: style)),
          Expanded(flex: 2, child: Text('ADDRESS DETAILS', style: style)),
          SizedBox(width: 56), // actions + active badge
        ],
      ),
    );
  }

  Widget _buildTableRow(_OutletRow outlet) {
    final bool isHovered = _hoveredOutletId == outlet.id;
    final Color accentColor = ref.watch(appBrandingProvider).accentColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredOutletId = outlet.id),
      onExit: (_) => setState(() => _hoveredOutletId = null),
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
          // Active status dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: outlet.isActive ? const Color(0xFF22A95E) : Colors.transparent,
              border: Border.all(
                color: outlet.isActive
                    ? const Color(0xFF22A95E)
                    : AppTheme.textSecondary,
                width: 1.5,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space12),

          // Name
          Expanded(
            flex: 3,
            child: Text(
              outlet.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // GSTIN
          Expanded(
            flex: 2,
            child: Text(
              outlet.gstin.isNotEmpty ? outlet.gstin : '—',
              style: TextStyle(
                fontSize: 13,
                color: outlet.gstin.isNotEmpty
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
              ),
            ),
          ),

          // Default Transaction Series (placeholder)
          const Expanded(
            flex: 2,
            child: Text(
              '—',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),

          // Type
          Expanded(
            flex: 1,
            child: Text(
              outlet.isWarehouse ? 'Warehouse' : 'Business',
              style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
            ),
          ),

          // Associated Zones (placeholder)
          const Expanded(
            flex: 1,
            child: Text(
              '—',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),

          // Address
          Expanded(
            flex: 2,
            child: Text(
              outlet.addressSummary.isNotEmpty ? outlet.addressSummary : '—',
              style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
            ),
          ),

          // Actions + active badge
          SizedBox(
            width: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (outlet.isActive)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22A95E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.check, size: 12, color: Colors.white),
                  ),
                PopupMenuButton<String>(
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
                  itemBuilder: (_) => _buildMenuItems(outlet),
                  onSelected: (value) => _onMenuSelected(value, outlet),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(_OutletRow outlet) {
    return <PopupMenuEntry<String>>[
      const PopupMenuItem(value: 'edit', child: Text('Edit')),
      if (!outlet.isWarehouse && outlet.gstin.isEmpty)
        const PopupMenuItem(value: 'associate_gstin', child: Text('Associate GSTIN')),
      if (!outlet.isActive)
        const PopupMenuItem(value: 'mark_active', child: Text('Mark as Active')),
      if (outlet.isActive && outlet.isWarehouse)
        const PopupMenuItem(value: 'mark_inactive', child: Text('Mark as Inactive')),
      const PopupMenuItem(value: 'delete', child: Text('Delete')),
      const PopupMenuItem(value: 'bin_locations', child: Text('Enable bin locations')),
      if (!outlet.isWarehouse)
        const PopupMenuItem(value: 'associate_contacts', child: Text('Associate Contacts')),
    ];
  }

  void _onMenuSelected(String value, _OutletRow outlet) {
    switch (value) {
      case 'edit':
        context.go(
          AppRoutes.settingsLocationsEdit.replaceFirst(':id', outlet.id),
        );
      case 'delete':
        _confirmDelete(outlet);
      case 'mark_active':
      case 'mark_inactive':
      case 'associate_gstin':
      case 'bin_locations':
      case 'associate_contacts':
        ZerpaiToast.info(context, 'Coming soon');
    }
  }

  Future<void> _confirmDelete(_OutletRow outlet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Location'),
        content: Text('Delete "${outlet.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final res = await _apiClient.delete(
        '/outlets/${outlet.id}?org_id=$orgId',
      );
      if (!mounted) return;
      if (res.success) {
        ZerpaiToast.success(context, 'Location deleted');
        _load();
      } else {
        ZerpaiToast.error(context, res.message ?? 'Failed to delete');
      }
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to delete location');
    }
  }

  Widget _buildEmptyState() {
    final accentColor = ref.watch(appBrandingProvider).accentColor;
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space48),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(LucideIcons.mapPin, size: 24, color: accentColor),
            ),
            const SizedBox(height: AppTheme.space16),
            const Text(
              'No locations yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            const Text(
              'Add your first business location or warehouse.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: AppTheme.space20),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.settingsLocationsCreate),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add Location'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space32),
      child: Center(
        child: Column(
          children: [
            const Icon(LucideIcons.alertCircle, size: 32, color: AppTheme.errorRed),
            const SizedBox(height: AppTheme.space12),
            Text(
              _error ?? 'Failed to load locations',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppTheme.space12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
