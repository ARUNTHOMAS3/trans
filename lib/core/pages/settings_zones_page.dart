// ignore_for_file: unused_element, unused_field

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/services/bin_locations_service.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/settings_fixed_header_layout.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

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
          _NavEntry(label: 'Locations', route: AppRoutes.settingsLocations),
          _NavEntry(label: 'Approvals'),
          _NavEntry(label: 'Manage Subscription'),
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

class SettingsZonesPage extends ConsumerStatefulWidget {
  final String? branchId;
  final String? branchName;
  final String? warehouseId;
  final String? warehouseName;

  const SettingsZonesPage({
    super.key,
    this.branchId,
    this.branchName,
    this.warehouseId,
    this.warehouseName,
  });

  @override
  ConsumerState<SettingsZonesPage> createState() => _SettingsZonesPageState();
}

class _SettingsZonesPageState extends ConsumerState<SettingsZonesPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _expandedBlocks = <String>{'Organization'};
  final Set<String> _selectedZoneIds = <String>{};

  bool _isLoading = true;
  String _organizationName = '';
  List<ZoneRecord> _zones = <ZoneRecord>[];

  String get _currentOrgId {
    final user = ref.read(authUserProvider);
    return (user?.orgId.isNotEmpty == true)
        ? user!.orgId
        : '00000000-0000-0000-0000-000000000002';
  }

  bool get _isWarehouseScope => (widget.warehouseId ?? '').trim().isNotEmpty;

  String get _currentScopeId => _isWarehouseScope
      ? widget.warehouseId!.trim()
      : (widget.branchId ?? '').trim();

  String get _currentScopeName => _isWarehouseScope
      ? (widget.warehouseName ?? '').trim()
      : (widget.branchName ?? '').trim();

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
    setState(() => _isLoading = true);
    final user = ref.read(authUserProvider);
    final String orgName = (user?.orgName ?? '').trim();
    final String orgId = _currentOrgId;
    List<ZoneRecord> zones = <ZoneRecord>[];
    if (_currentScopeId.isNotEmpty) {
      zones = await BinLocationsService.instance.getZones(
        orgId: orgId,
        branchId: _currentScopeId,
      );
      if (zones.isEmpty) {
        zones = await BinLocationsService.instance.ensureDefaultZones(
          orgId: orgId,
          branchId: _currentScopeId,
          branchName: _currentScopeName,
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _organizationName = orgName.isNotEmpty ? orgName : 'Your Organization';
      _zones = zones;
      _selectedZoneIds.removeWhere(
        (selectedId) => !_zones.any((zone) => zone.id == selectedId),
      );
      _isLoading = false;
    });
  }

  bool get _hasZones => _zones.isNotEmpty;

  bool get _isAllSelected =>
      _hasZones && _selectedZoneIds.length == _zones.length;

  bool get _isPartiallySelected =>
      _selectedZoneIds.isNotEmpty && _selectedZoneIds.length < _zones.length;

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedZoneIds
          ..clear()
          ..addAll(_zones.map((zone) => zone.id));
      } else {
        _selectedZoneIds.clear();
      }
    });
  }

  void _toggleZoneSelection(String zoneId, bool? value) {
    setState(() {
      if (value == true) {
        _selectedZoneIds.add(zoneId);
      } else {
        _selectedZoneIds.remove(zoneId);
      }
    });
  }

  Future<void> _runBulkAction(String action) async {
    final targetIds = _selectedZoneIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    if (targetIds.isEmpty) {
      ZerpaiToast.info(context, 'Select at least one zone');
      return;
    }
    try {
      await BinLocationsService.instance.bulkZoneAction(
        orgId: _currentOrgId,
        branchId: _currentScopeId,
        zoneIds: targetIds,
        action: action,
      );
      if (!mounted) return;
      ZerpaiToast.success(context, 'Zone action completed');
      setState(() => _selectedZoneIds.clear());
      await _load();
    } catch (error) {
      if (!mounted) return;
      final raw = error.toString();
      final message = raw
          .replaceFirst('Exception: ', '')
          .replaceFirst('Error: ', '')
          .trim();
      ZerpaiToast.error(context, message.isEmpty ? 'Failed to apply zone action' : message);
    }
  }

  Map<String, String> _scopeQueryParameters({String? zoneName}) {
    final params = <String, String>{};
    if (_isWarehouseScope) {
      params['warehouseId'] = _currentScopeId;
      params['warehouseName'] = _currentScopeName;
    } else {
      params['branchId'] = _currentScopeId;
      params['branchName'] = _currentScopeName;
    }
    if (zoneName != null && zoneName.isNotEmpty) {
      params['zoneName'] = zoneName;
    }
    return params;
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
                                  _organizationName,
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
                  backgroundColor: Colors.white,
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

  Widget _buildSidebar() {
    return SettingsNavigationSidebar(
      currentPath: GoRouterState.of(context).uri.path,
    );
  }

  Widget _buildSidebarBlock(_NavBlock block, String currentPath) {
    final bool hasActiveChild = block.items.any((item) {
      if (item.route == AppRoutes.settingsLocations &&
          (currentPath == AppRoutes.settingsZones ||
              currentPath == AppRoutes.settingsZonesCreate ||
              currentPath.startsWith('/settings/zones/'))) {
        return true;
      }
      return item.route == currentPath;
    });
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
    final bool isActive =
        entry.route == currentPath ||
        (entry.route == AppRoutes.settingsLocations &&
            (currentPath == AppRoutes.settingsZones ||
                currentPath == AppRoutes.settingsZonesCreate ||
                currentPath.startsWith('/settings/zones/')));
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

  Widget _buildBody() {
    return SettingsFixedHeaderLayout(
      maxWidth: double.infinity,
      headerPadding: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        AppTheme.space20,
        AppTheme.space20,
        AppTheme.space16,
      ),
      bodyPadding: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        0,
        AppTheme.space20,
        AppTheme.space24,
      ),
      header: _buildHeader(),
      body: _buildTable(),
    );
  }

  Widget _buildHeader() {
    final Color accentColor = ref.watch(appBrandingProvider).accentColor;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.goNamed(
                  AppRoutes.settingsLocations,
                  pathParameters: {
                    'orgSystemId':
                        GoRouterState.of(
                          context,
                        ).pathParameters['orgSystemId'] ??
                        '0000000000',
                  },
                ),
                splashRadius: 18,
                icon: const Icon(
                  LucideIcons.chevronLeft,
                  size: 18,
                  color: AppTheme.primaryBlue,
                ),
              ),
              Expanded(
                child: Text(
                  '${_currentScopeName.isNotEmpty ? _currentScopeName : 'Location'} / Zones',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _currentScopeId.isEmpty
              ? () => ZerpaiToast.info(
                  context,
                  'Select a location before creating bin locations',
                )
              : () => context.goNamed(
                  AppRoutes.settingsZonesCreate,
                  pathParameters: {
                    'orgSystemId':
                        GoRouterState.of(
                          context,
                        ).pathParameters['orgSystemId'] ??
                        '0000000000',
                  },
                  queryParameters: _scopeQueryParameters(),
                ),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space18,
              vertical: AppTheme.space12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text(
            'New',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        ElevatedButton.icon(
          onPressed: () =>
              ZerpaiToast.info(context, 'Bin import is coming soon'),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space18,
              vertical: AppTheme.space12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(LucideIcons.download, size: 16),
          label: const Text(
            'Import Bins',
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedZoneIds.isNotEmpty) _buildBulkActionsBar(),
          _buildTableHeader(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppTheme.space32),
              child: ZTableSkeleton(rows: 3, columns: 4),
            )
          else
            ..._zones.map(_buildRow),
        ],
      ),
    );
  }

  Widget _buildBulkActionsBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: PopupMenuButton<String>(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        onSelected: _runBulkAction,
        itemBuilder: (context) => [
          _buildHoverMenuItem(value: 'mark_active', label: 'Mark as Active'),
          _buildHoverMenuItem(
            value: 'mark_inactive',
            label: 'Mark as Inactive',
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Bulk Actions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(width: 6),
              Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildHoverMenuItem({
    required String value,
    required String label,
  }) {
    bool isHovered = false;

    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      child: StatefulBuilder(
        builder: (context, setItemState) {
          final backgroundColor = isHovered
              ? AppTheme.infoBlue
              : Colors.transparent;
          final textColor = isHovered ? Colors.white : AppTheme.textPrimary;

          return MouseRegion(
            onEnter: (_) => setItemState(() => isHovered = true),
            onExit: (_) => setItemState(() => isHovered = false),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: backgroundColor,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: isHovered ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableHeader() {
    const TextStyle style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppTheme.textSecondary,
      letterSpacing: 0.25,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space18,
        vertical: AppTheme.space10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFDFE),
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Checkbox(
              value: !_hasZones
                  ? false
                  : _isAllSelected
                  ? true
                  : _isPartiallySelected
                  ? null
                  : false,
              tristate: true,
              onChanged: _hasZones ? _toggleSelectAll : null,
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.primaryBlue;
                }
                return Colors.white;
              }),
              side: const BorderSide(color: AppTheme.textSecondary),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const Expanded(flex: 3, child: Text('ZONE NAME', style: style)),
          const Expanded(flex: 2, child: Text('STATUS', style: style)),
          const Expanded(
            flex: 3,
            child: Text('STRUCTURE LAYOUT', style: style),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(ZoneRecord zone) {
    final bool isSelected = _selectedZoneIds.contains(zone.id);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space18,
        vertical: AppTheme.space10,
      ),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF7FAFF) : Colors.white,
        border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Checkbox(
              value: isSelected,
              onChanged: (value) => _toggleZoneSelection(zone.id, value),
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppTheme.primaryBlue;
                }
                return Colors.white;
              }),
              side: const BorderSide(color: AppTheme.textSecondary),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => context.goNamed(
                  AppRoutes.settingsZoneBins,
                  pathParameters: {
                    'orgSystemId':
                        GoRouterState.of(
                          context,
                        ).pathParameters['orgSystemId'] ??
                        '0000000000',
                    'zoneId': zone.id,
                  },
                  queryParameters: _scopeQueryParameters(
                    zoneName: zone.zoneName,
                  ),
                ),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.space4,
                    horizontal: AppTheme.space2,
                  ),
                  child: Text(
                    zone.zoneName,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              zone.status,
              style: TextStyle(
                fontSize: 12.5,
                color: zone.status.trim().toLowerCase() == 'active'
                    ? const Color(0xFF1CA351)
                    : AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space8,
                vertical: AppTheme.space6,
              ),
              child: Text(
                zone.structureLayout,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textBody,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
