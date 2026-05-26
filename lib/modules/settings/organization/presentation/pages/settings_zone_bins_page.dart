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
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
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

class SettingsZoneBinsPage extends ConsumerStatefulWidget {
  final String zoneId;
  final String? branchId;
  final String? branchName;
  final String? warehouseId;
  final String? warehouseName;
  final String zoneName;

  const SettingsZoneBinsPage({
    super.key,
    required this.zoneId,
    this.branchId,
    this.branchName,
    this.warehouseId,
    this.warehouseName,
    required this.zoneName,
  });

  @override
  ConsumerState<SettingsZoneBinsPage> createState() =>
      _SettingsZoneBinsPageState();
}

class _SettingsZoneBinsPageState extends ConsumerState<SettingsZoneBinsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _expandedBlocks = <String>{'Organization'};
  final Set<String> _selectedBinIds = <String>{};

  bool _isLoading = true;
  String _organizationName = '';
  String? _hoveredBinId;
  int _page = 1;
  int _pageSize = 100;
  int _totalCount = 0;
  ZoneRecord? _zone;
  List<BinRecord> _bins = <BinRecord>[];

  String get _currentOrgId {
    final user = ref.read(authUserProvider);
    return (user?.orgId.isNotEmpty == true)
        ? user!.orgId
        : '00000000-0000-0000-0000-000000000002';
  }

  String get _currentZoneName => _zone?.zoneName.trim().isNotEmpty == true
      ? _zone!.zoneName
      : widget.zoneName;

  bool get _isWarehouseScope => (widget.warehouseId ?? '').trim().isNotEmpty;

  String get _currentScopeId => _isWarehouseScope
      ? widget.warehouseId!.trim()
      : (widget.branchId ?? '').trim();

  String get _currentScopeName => _isWarehouseScope
      ? (widget.warehouseName ?? '').trim()
      : (widget.branchName ?? '').trim();

  int get _startRange => _totalCount == 0 ? 0 : ((_page - 1) * _pageSize) + 1;

  int get _endRange => _totalCount == 0
      ? 0
      : (_startRange + _bins.length - 1).clamp(0, _totalCount);

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

  bool get _allCurrentPageSelected =>
      _bins.isNotEmpty &&
      _bins.every((bin) => _selectedBinIds.contains(bin.id));

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

  bool _isLocationsPath(String currentPath) {
    return currentPath == AppRoutes.settingsLocations ||
        currentPath == AppRoutes.settingsZones ||
        currentPath == AppRoutes.settingsZonesCreate ||
        currentPath.startsWith('/settings/zones/');
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final user = ref.read(authUserProvider);
    final String orgName = (user?.orgName ?? '').trim();
    try {
      final result = await BinLocationsService.instance.getBins(
        orgId: _currentOrgId,
        branchId: _currentScopeId,
        zoneId: widget.zoneId,
        page: _page,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _organizationName = orgName.isNotEmpty ? orgName : 'Your Organization';
        _zone = result.zone;
        _bins = result.items;
        _totalCount = result.totalCount;
        _page = result.page;
        _pageSize = result.pageSize;
        _selectedBinIds.removeWhere((id) => !_bins.any((bin) => bin.id == id));
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _organizationName = orgName.isNotEmpty ? orgName : 'Your Organization';
        _isLoading = false;
      });
      ZerpaiToast.error(context, 'Failed to load bins');
    }
  }

  Future<void> _changePage(int nextPage) async {
    if (nextPage < 1) return;
    setState(() => _page = nextPage);
    await _load();
  }

  Future<void> _changePageSize(int nextPageSize) async {
    if (_pageSize == nextPageSize) return;
    setState(() {
      _pageSize = nextPageSize;
      _page = 1;
    });
    await _load();
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

  Widget _buildSidebar() {
    return SettingsNavigationSidebar(
      currentPath: GoRouterState.of(context).uri.path,
    );
  }

  Widget _buildSidebarBlock(_NavBlock block, String currentPath) {
    final bool hasActiveChild = block.items.any((item) {
      if (item.route == AppRoutes.settingsLocations &&
          _isLocationsPath(currentPath)) {
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
            _isLocationsPath(currentPath));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space32,
            AppTheme.space32,
            AppTheme.space32,
            AppTheme.space24,
          ),
          child: _buildHeader(),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space32,
              0,
              AppTheme.space32,
              AppTheme.space20,
            ),
            child: _buildTable(),
          ),
        ),
      ],
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
                  AppRoutes.settingsZones,
                  pathParameters: {
                    'orgSystemId':
                        GoRouterState.of(
                          context,
                        ).pathParameters['orgSystemId'] ??
                        '0000000000',
                  },
                  queryParameters: _scopeQueryParameters(),
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
                  '$_currentZoneName / Bins',
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
          onPressed: _isLoading ? null : () => _showBinDialog(),
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
          if (_selectedBinIds.isNotEmpty) _buildBulkActionsBar(),
          _buildTableHeader(),
          Expanded(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppTheme.space32),
                    child: ZTableSkeleton(rows: 6, columns: 4),
                  )
                : _bins.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(AppTheme.space32),
                    child: Text(
                      'No bins found',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _bins.length,
                    itemBuilder: (context, index) => _buildRow(_bins[index]),
                  ),
          ),
          if (!_isLoading) _buildPaginationFooter(),
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
          _buildHoverMenuItem(value: 'delete', label: 'Delete'),
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
      letterSpacing: 0.4,
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
            width: 28,
            child: Checkbox(
              value: _allCurrentPageSelected,
              onChanged: _bins.isEmpty
                  ? null
                  : (value) {
                      setState(() {
                        if (value == true) {
                          _selectedBinIds.addAll(_bins.map((bin) => bin.id));
                        } else {
                          _selectedBinIds.removeAll(_bins.map((bin) => bin.id));
                        }
                      });
                    },
            ),
          ),
          const Expanded(flex: 5, child: Text('BIN', style: style)),
          const Expanded(flex: 2, child: Text('STATUS', style: style)),
          const Expanded(flex: 2, child: Text('STOCK ON HAND', style: style)),
          const SizedBox(width: 64),
        ],
      ),
    );
  }

  Widget _buildRow(BinRecord bin) {
    final bool isHovered = _hoveredBinId == bin.id;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredBinId = bin.id),
      onExit: (_) {
        if (_hoveredBinId == bin.id) {
          setState(() => _hoveredBinId = null);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space18,
          vertical: AppTheme.space10,
        ),
        decoration: BoxDecoration(
          color: isHovered ? const Color(0xFFF7F9FC) : Colors.white,
          border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Checkbox(
                value: _selectedBinIds.contains(bin.id),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedBinIds.add(bin.id);
                    } else {
                      _selectedBinIds.remove(bin.id);
                    }
                  });
                },
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                bin.name,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                bin.status,
                style: TextStyle(
                  fontSize: 12.5,
                  color: bin.status == 'Inactive'
                      ? AppTheme.textSecondary
                      : const Color(0xFF1CA351),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                bin.stockOnHand.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            SizedBox(
              width: 64,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: isHovered ? 1 : 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => _showBinDialog(bin: bin),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 28,
                        height: 28,
                      ),
                      icon: const Icon(
                        LucideIcons.pencil,
                        size: 14,
                        color: AppTheme.primaryBlue,
                      ),
                      splashRadius: 16,
                    ),
                    IconButton(
                      onPressed: () => _confirmDeleteBin(bin),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 28,
                        height: 28,
                      ),
                      icon: const Icon(
                        LucideIcons.trash2,
                        size: 14,
                        color: AppTheme.errorRed,
                      ),
                      splashRadius: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationFooter() {
    final bool canGoPrevious = _page > 1;
    final bool canGoNext = _endRange < _totalCount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Text(
            'Total Count: $_totalCount',
            style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
          ),
          const Spacer(),
          PopupMenuButton<int>(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            onSelected: _changePageSize,
            itemBuilder: (context) => const [
              PopupMenuItem<int>(value: 10, child: Text('10 per page')),
              PopupMenuItem<int>(value: 25, child: Text('25 per page')),
              PopupMenuItem<int>(value: 50, child: Text('50 per page')),
              PopupMenuItem<int>(value: 100, child: Text('100 per page')),
              PopupMenuItem<int>(value: 200, child: Text('200 per page')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFCFCFD),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_pageSize per page',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    LucideIcons.chevronDown,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$_startRange - $_endRange',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: canGoPrevious ? () => _changePage(_page - 1) : null,
            icon: const Icon(LucideIcons.chevronLeft, size: 16),
            splashRadius: 16,
          ),
          IconButton(
            onPressed: canGoNext ? () => _changePage(_page + 1) : null,
            icon: const Icon(LucideIcons.chevronRight, size: 16),
            splashRadius: 16,
          ),
        ],
      ),
    );
  }

  Future<void> _showBinDialog({BinRecord? bin}) async {
    final TextEditingController nameController = TextEditingController(
      text: bin?.name ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: bin?.description ?? '',
    );
    String? nameError;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final String trimmedName = nameController.text.trim();
              if (trimmedName.isEmpty) {
                setDialogState(() => nameError = 'Name is required');
                return;
              }
              setDialogState(() {
                isSaving = true;
                nameError = null;
              });
              try {
                if (bin == null) {
                  await BinLocationsService.instance.createBin(
                    zoneId: widget.zoneId,
                    orgId: _currentOrgId,
                    branchId: _currentScopeId,
                    name: trimmedName,
                    description: descriptionController.text.trim(),
                  );
                } else {
                  await BinLocationsService.instance.updateBin(
                    binId: bin.id,
                    orgId: _currentOrgId,
                    branchId: _currentScopeId,
                    name: trimmedName,
                    description: descriptionController.text.trim(),
                  );
                }
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                ZerpaiToast.success(
                  context,
                  bin == null ? 'Bin created' : 'Bin updated',
                );
                await _load();
              } catch (_) {
                if (!mounted) return;
                setDialogState(() => isSaving = false);
                ZerpaiToast.error(
                  context,
                  bin == null ? 'Failed to create bin' : 'Failed to update bin',
                );
              }
            }

            return Dialog(
              alignment: Alignment.topCenter,
              insetPadding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Bin location details',
                              style: AppTheme.pageTitle.copyWith(fontSize: 18),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(
                              LucideIcons.x,
                              size: 18,
                              color: AppTheme.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      child: Column(
                        children: [
                          _buildDialogField(
                            label: 'Name',
                            required: true,
                            child: TextField(
                              controller: nameController,
                              decoration: _dialogInputDecoration(
                                hintText: 'Enter bin name',
                                errorText: nameError,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDialogField(
                            label: 'Description',
                            child: TextField(
                              controller: descriptionController,
                              minLines: 4,
                              maxLines: 4,
                              decoration: _dialogInputDecoration(
                                hintText: 'Enter description',
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: isSaving ? null : submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: Text(isSaving ? 'Saving...' : 'Save'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.of(dialogContext).pop(),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    nameController.dispose();
    descriptionController.dispose();
  }

  InputDecoration _dialogInputDecoration({
    required String hintText,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.primaryBlue),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.errorRed),
      ),
    );
  }

  Widget _buildDialogField({
    required String label,
    bool required = false,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: RichText(
              text: TextSpan(
                text: label,
                style: TextStyle(
                  fontSize: 13,
                  color: required ? AppTheme.errorRed : AppTheme.textBody,
                  fontWeight: FontWeight.w500,
                ),
                children: required
                    ? const [TextSpan(text: '*')]
                    : const <InlineSpan>[],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Future<void> _confirmDeleteBin(BinRecord bin) async {
    final bool cancelled = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete bin',
      message: 'Are you sure about deleting this bin?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (cancelled) return;
    try {
      await BinLocationsService.instance.deleteBin(
        binId: bin.id,
        orgId: _currentOrgId,
        branchId: _currentScopeId,
      );
      if (!mounted) return;
      ZerpaiToast.success(context, 'Bin deleted');
      if (_bins.length == 1 && _page > 1) {
        _page -= 1;
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to delete bin');
      }
    }
  }

  Future<void> _runBulkAction(String action) async {
    if (_selectedBinIds.isEmpty) return;
    if (action == 'delete') {
      final bool cancelled = await showZerpaiConfirmationDialog(
        context,
        title: 'Delete bins',
        message: 'Are you sure about deleting the selected bins?',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
        variant: ZerpaiConfirmationVariant.danger,
      );
      if (cancelled) return;
    }
    try {
      await BinLocationsService.instance.bulkAction(
        orgId: _currentOrgId,
        branchId: _currentScopeId,
        binIds: _selectedBinIds.toList(),
        action: action,
      );
      if (!mounted) return;
      setState(() => _selectedBinIds.clear());
      ZerpaiToast.success(context, 'Bulk action applied');
      await _load();
    } catch (_) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to apply bulk action');
      }
    }
  }
}
