// ignore_for_file: unused_element, unused_field

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/services/bin_locations_service.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/texts/zerpai_link_text.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/widgets/settings_fixed_header_layout.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

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

const List<Map<String, String>> _kBranchTypes = [
  {'id': 'fofo', 'code': 'FOFO', 'label': 'Franchise Owned Franchise Operated'},
  {'id': 'coco', 'code': 'COCO', 'label': 'Company Owned Company Operated'},
  {
    'id': 'fico',
    'code': 'FICO',
    'label': 'Franchise Invested Company Operated',
  },
  {'id': 'foco', 'code': 'FOCO', 'label': 'Franchise Owned Company Operated'},
];

const List<String> _kMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_kMonths[d.month - 1]} ${d.year}';

class _BranchRow {
  final String id;
  final String systemId;
  final String name;
  final String branchCode;
  final String gstin;
  final String city;
  final String state;
  final String country;
  final bool isActive;
  final bool isPrimary;
  final String branchType;
  final DateTime? subscriptionFrom;
  final DateTime? subscriptionTo;
  final bool isBinLocationsEnabled;
  final int associatedZoneCount;
  final int associatedBinCount;

  const _BranchRow({
    required this.id,
    required this.systemId,
    required this.name,
    required this.branchCode,
    required this.gstin,
    required this.city,
    required this.state,
    required this.country,
    required this.isActive,
    required this.isPrimary,
    required this.branchType,
    this.isBinLocationsEnabled = false,
    this.associatedZoneCount = 0,
    this.associatedBinCount = 0,
    this.subscriptionFrom,
    this.subscriptionTo,
  });

  factory _BranchRow.fromJson(Map<String, dynamic> j) => _BranchRow(
    id: (j['id'] ?? '').toString(),
    systemId: (j['system_id'] ?? '').toString(),
    name: (j['display_name'] ?? j['name'] ?? '').toString(),
    branchCode: (j['branch_code'] ?? j['branch_code'] ?? '').toString(),
    gstin: (j['gstin'] ?? '').toString(),
    city: (j['city'] ?? '').toString(),
    state: (j['state'] ?? '').toString(),
    country: (j['country'] ?? 'India').toString(),
    isActive: j['is_active'] as bool? ?? true,
    isPrimary: j['is_primary'] as bool? ?? false,
    branchType: (j['branch_type'] ?? '').toString(),
    subscriptionFrom: j['subscription_from'] != null
        ? DateTime.tryParse(j['subscription_from'].toString())
        : null,
    subscriptionTo: j['subscription_to'] != null
        ? DateTime.tryParse(j['subscription_to'].toString())
        : null,
  );

  String get addressSummary {
    final parts = <String>[
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (country.isNotEmpty) country,
    ];
    return parts.join(', ');
  }

  String get branchTypeLabel {
    if (branchType.isEmpty) return '';
    final normalized = branchType.toLowerCase();
    return _kBranchTypes.firstWhere(
      (t) => t['id'] == normalized,
      orElse: () => {'code': branchType.toUpperCase()},
    )['code']!;
  }

  String get subscriptionPeriod {
    if (subscriptionFrom == null && subscriptionTo == null) return '';
    if (subscriptionFrom != null && subscriptionTo != null) {
      return '${_fmtDate(subscriptionFrom!)} – ${_fmtDate(subscriptionTo!)}';
    }
    if (subscriptionFrom != null) return 'From ${_fmtDate(subscriptionFrom!)}';
    return 'Until ${_fmtDate(subscriptionTo!)}';
  }

  String get associatedZonesBinsLabel {
    if (associatedZoneCount <= 0) return '—';
    final String zonesLabel = associatedZoneCount == 1 ? 'Zone' : 'Zones';
    final String binsLabel = associatedBinCount == 1 ? 'Bin' : 'Bins';
    return '$associatedZoneCount $zonesLabel / $associatedBinCount $binsLabel';
  }
}

class _ContactOption {
  final String id;
  final String name;
  const _ContactOption({required this.id, required this.name});
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class SettingsBranchesListPage extends ConsumerStatefulWidget {
  const SettingsBranchesListPage({super.key});

  @override
  ConsumerState<SettingsBranchesListPage> createState() =>
      _SettingsBranchesListPageState();
}

class _SettingsBranchesListPageState
    extends ConsumerState<SettingsBranchesListPage> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _expandedBlocks = <String>{'Organization'};

  bool _isLoading = true;
  String? _hoveredId;
  String _organizationName = '';
  List<_BranchRow> _branches = <_BranchRow>[];

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
    return (user?.orgId.isNotEmpty == true) ? user!.orgId : '';
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
        'branches',
        queryParameters: <String, dynamic>{'org_id': orgId},
      );
      if (!mounted) return;
      final List<dynamic> rows = res.success && res.data is List
          ? res.data as List<dynamic>
          : [];
      final rawBranches = rows
          .whereType<Map<String, dynamic>>()
          .where(
            (j) =>
                (j['location_type'] ?? 'business').toString() == 'business',
          )
          .toList();
      final List<String> branchIds = rawBranches
          .map((branch) => (branch['id'] ?? '').toString().trim())
          .where((id) => id.isNotEmpty)
          .toList();
      final summaries = branchIds.isEmpty
          ? <String, BranchZoneBinsSummary>{}
          : await BinLocationsService.instance.getBranchZoneBinsSummaries(
              orgId: orgId,
              branchIds: branchIds,
            );
      setState(() {
        _branches = rawBranches
            .map((branch) {
              final parsed = _BranchRow.fromJson(branch);
              final summary = summaries[parsed.id];
              return _BranchRow(
                id: parsed.id,
                systemId: parsed.systemId,
                name: parsed.name,
                branchCode: parsed.branchCode,
                gstin: parsed.gstin,
                city: parsed.city,
                state: parsed.state,
                country: parsed.country,
                isActive: parsed.isActive,
                isPrimary: parsed.isPrimary,
                branchType: parsed.branchType,
                subscriptionFrom: parsed.subscriptionFrom,
                subscriptionTo: parsed.subscriptionTo,
                isBinLocationsEnabled: summary?.isEnabled ?? false,
                associatedZoneCount: summary?.zoneCount ?? 0,
                associatedBinCount: summary?.binCount ?? 0,
              );
            })
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

  // ─── Sidebar ───────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return SettingsNavigationSidebar(
      currentPath: GoRouterState.of(context).uri.path,
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
    final accentColor = ref.watch(appBrandingProvider).accentColor;
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ??
        '0000000000';
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Branches',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: AppTheme.space4),
              Text(
                'Manage your business branches and office locations.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => context.goNamed(
            AppRoutes.settingsBranchCreate,
            pathParameters: {'orgSystemId': orgSystemId},
          ),
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
            'Add Branch',
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
            Padding(
              padding: const EdgeInsets.all(AppTheme.space32),
              child: ZTableSkeleton(rows: 10, columns: 5),
            )
          else if (_branches.isEmpty)
            _buildEmptyState()
          else
            ..._branches.map(_buildRow),
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
          SizedBox(width: 120, child: Text('SYSTEM ID', style: style)),
          SizedBox(width: 130, child: Text('BRANCH CODE', style: style)),
          Expanded(flex: 3, child: Text('GSTIN', style: style)),
          SizedBox(width: 110, child: Text('BRANCH TYPE', style: style)),
          SizedBox(width: 180, child: Text('ASSOCIATED ZONES / BINS', style: style)),
          Expanded(flex: 3, child: Text('ADDRESS DETAILS', style: style)),
          SizedBox(width: 170, child: Text('SUBSCRIPTION PERIOD', style: style)),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildRow(_BranchRow branch) {
    final bool isHovered = _hoveredId == branch.id;

    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '0000000000';

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredId = branch.id),
      onExit: (_) => setState(() => _hoveredId = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.goNamed(
          AppRoutes.settingsBranchProfile,
          pathParameters: {'orgSystemId': orgSystemId, 'id': branch.id},
        ),
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
                color: branch.isActive
                    ? const Color(0xFF22A95E)
                    : Colors.transparent,
                border: Border.all(
                  color: branch.isActive
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
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      branch.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (branch.isPrimary) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      LucideIcons.star,
                      size: 13,
                      color: Color(0xFFFFC107),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                branch.systemId.isNotEmpty ? branch.systemId : '—',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            // Branch code
            SizedBox(
              width: 130,
              child: Text(
                branch.branchCode.isNotEmpty ? branch.branchCode : '—',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            // GSTIN
            Expanded(
              flex: 3,
              child: branch.gstin.isNotEmpty
                  ? Text(
                      branch.gstin,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    )
                  : const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
            ),
            // Branch Type
            SizedBox(
              width: 110,
              child: branch.branchTypeLabel.isNotEmpty
                  ? Text(
                      branch.branchTypeLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
            ),
            SizedBox(
              width: 180,
              child: branch.associatedZoneCount > 0
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: ZerpaiLinkText(
                        text: branch.associatedZonesBinsLabel,
                        style: const TextStyle(fontSize: 13),
                        onTap: () => context.goNamed(
                          AppRoutes.settingsZones,
                          pathParameters: {
                            'orgSystemId':
                                GoRouterState.of(context)
                                    .pathParameters['orgSystemId'] ??
                                '0000000000',
                          },
                          queryParameters: {
                            'branchId': branch.id,
                            'branchName': branch.name,
                          },
                        ),
                      ),
                    )
                  : const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
            ),
            // Address
            Expanded(
              flex: 3,
              child: Text(
                branch.addressSummary.isNotEmpty ? branch.addressSummary : '—',
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ),
            // Subscription Period
            SizedBox(
              width: 170,
              child: branch.subscriptionPeriod.isNotEmpty
                  ? Text(
                      branch.subscriptionPeriod,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textBody,
                      ),
                    )
                  : const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
            ),
            // Actions
            SizedBox(
              width: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildActionMenu(branch, isHovered),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildActionMenu(_BranchRow branch, bool isHovered) {
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
          final orgSystemId =
              GoRouterState.of(context).pathParameters['orgSystemId'] ??
              '0000000000';
          context.goNamed(
            AppRoutes.settingsBranchEdit,
            pathParameters: {
              'orgSystemId': orgSystemId,
              'id': branch.id,
            },
          );
        }),
        if (branch.gstin.trim().isEmpty)
          buildItem('Associate GSTIN', () => _showAssociateGstinDialog(branch)),
        buildItem('Delete', () => _confirmDelete(branch)),
        buildItem(
          branch.isBinLocationsEnabled
              ? 'Disable bin locations'
              : 'Enable bin locations',
          () => branch.isBinLocationsEnabled
              ? _openDisableBinLocations(branch)
              : _openBinLocations(branch),
        ),
        buildItem(
          'Associate Contacts',
          () => _showAssociateContactsDialog(branch),
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

  Future<void> _showAssociateContactsDialog(_BranchRow branch) async {
    final orgId = _currentOrgId;
    List<_ContactOption> users = [];
    String? selectedUserId;

    try {
      final res = await _apiClient.get(
        'users',
        queryParameters: {'org_id': orgId},
      );
      if (res.success && res.data is List) {
        users = (res.data as List)
            .whereType<Map<String, dynamic>>()
            .map(
              (user) => _ContactOption(
                id: (user['id'] ?? '').toString(),
                name:
                    ((user['name'] ?? user['full_name'] ?? user['email']) ?? '')
                        .toString(),
              ),
            )
            .where((user) => user.id.isNotEmpty && user.name.isNotEmpty)
            .toList();
      }
    } catch (_) {}

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
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
                constraints: const BoxConstraints(maxWidth: 560),
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
                              'Associate Contacts',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
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
                            'Select the primary contact to associate with ${branch.name}. This contact will be used wherever branch-level contact context is needed.',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.55,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space20),
                          const Text(
                            'Contact Name',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textBody,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space6),
                          FormDropdown<String>(
                            items: users.map((user) => user.id).toList(),
                            value: selectedUserId,
                            hint: 'Select contact',
                            allowClear: true,
                            displayStringForValue: (id) {
                              final match = users.firstWhere(
                                (user) => user.id == id,
                                orElse: () => _ContactOption(id: id, name: id),
                              );
                              return match.name;
                            },
                            onChanged: (value) =>
                                setDialogState(() => selectedUserId = value),
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
                              Navigator.pop(ctx);
                              try {
                                final res = await _apiClient.put(
                                  'branches/${branch.id}',
                                  data: {
                                    'org_id': orgId,
                                    'primary_contact_id': selectedUserId,
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
                            onPressed: () => Navigator.pop(ctx),
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

  Future<void> _confirmDelete(_BranchRow branch) async {
    final cancelled = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Branch',
      message: 'Delete "${branch.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (cancelled || !mounted) return;

    try {
      final res = await _apiClient.delete(
        'branches/${branch.id}?org_id=$_currentOrgId',
      );
      if (!mounted) return;
      if (res.success) {
        ZerpaiToast.success(context, 'Branch deleted');
        _load();
      } else {
        ZerpaiToast.error(context, res.message ?? 'Failed to delete branch');
      }
    } catch (_) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to delete branch');
      }
    }
  }

  Future<void> _showAssociateGstinDialog(_BranchRow branch) async {
    final orgId = _currentOrgId;
    final TextEditingController gstinCtrl = TextEditingController(
      text: branch.gstin,
    );
    String? selectedExistingGstin = branch.gstin.isNotEmpty
        ? branch.gstin
        : null;
    final existingGstins =
        _branches
            .where((row) => row.id != branch.id && row.gstin.isNotEmpty)
            .map((row) => row.gstin)
            .toSet()
            .toList()
          ..sort();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: 520,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Associate GSTIN',
                          style: AppTheme.pageTitle.copyWith(fontSize: 18),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(LucideIcons.x, size: 18),
                        color: AppTheme.textSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Update GSTIN for ${branch.name}.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space20),
                  if (existingGstins.isNotEmpty) ...[
                    FormDropdown<String>(
                      items: existingGstins,
                      value: selectedExistingGstin,
                      hint: 'Associate existing GSTIN',
                      onChanged: (value) => setDialogState(() {
                        selectedExistingGstin = value;
                        if (value != null && value.isNotEmpty) {
                          gstinCtrl.text = value;
                        }
                      }),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    const Text(
                      'Or enter a GSTIN manually',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                  ],
                  TextField(
                    controller: gstinCtrl,
                    decoration: InputDecoration(
                      hintText: 'Enter GSTIN',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  Row(
                    children: [
                      Consumer(
                        builder: (_, ref, __) {
                          final accentColor = ref
                              .watch(appBrandingProvider)
                              .accentColor;
                          return ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              try {
                                final res = await _apiClient.put(
                                  'branches/${branch.id}',
                                  data: {
                                    'org_id': orgId,
                                    'gstin': gstinCtrl.text.trim().isEmpty
                                        ? null
                                        : gstinCtrl.text.trim(),
                                  },
                                );
                                if (!mounted) return;
                                if (res.success) {
                                  ZerpaiToast.success(
                                    context,
                                    'GSTIN associated',
                                  );
                                  _load();
                                } else {
                                  ZerpaiToast.error(
                                    context,
                                    res.message ?? 'Failed to update GSTIN',
                                  );
                                }
                              } catch (_) {
                                if (mounted) {
                                  ZerpaiToast.error(
                                    context,
                                    'Failed to update GSTIN',
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Update'),
                          );
                        },
                      ),
                      const SizedBox(width: AppTheme.space12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    gstinCtrl.dispose();
  }

  Future<void> _openBinLocations(_BranchRow branch) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
              constraints: const BoxConstraints(maxWidth: 500),
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
                            'Enable Bin Locations',
                            style: AppTheme.pageTitle.copyWith(fontSize: 16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: AppTheme.textPrimary,
                            ),
                            children: [
                              const TextSpan(
                                text:
                                    'Do you want to enable bin locations for ',
                              ),
                              TextSpan(
                                text: branch.name.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(text: '?'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Bin locations are the smallest unit of space inside a warehouse where goods are stored. Bin location simplifies the process of finding where an item is stored in your warehouse.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.55,
                            color: AppTheme.textSecondary,
                          ),
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
                            if (!mounted) return;
                            await BinLocationsService.instance
                                .ensureDefaultZones(
                                  orgId: _currentOrgId,
                                  branchId: branch.id,
                                  branchName: branch.name,
                                );
                            if (!mounted) return;
                            final orgSystemId =
                                GoRouterState.of(
                                  context,
                                ).pathParameters['orgSystemId'] ??
                                '0000000000';
                            context.goNamed(
                              AppRoutes.settingsZones,
                              pathParameters: {'orgSystemId': orgSystemId},
                              queryParameters: {
                                'branchId': branch.id,
                                'branchName': branch.name,
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Enable',
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
                            side: const BorderSide(color: AppTheme.borderColor),
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
    );
  }

  Future<void> _openDisableBinLocations(_BranchRow branch) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
              constraints: const BoxConstraints(maxWidth: 500),
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
                            'Disable Bin Locations',
                            style: AppTheme.pageTitle.copyWith(fontSize: 16),
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Text(
                      'Disabling bin locations removes all associated zones and bins for this branch. This action is allowed only when every associated bin has zero stock on hand.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: AppTheme.textSecondary,
                      ),
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
                              await BinLocationsService.instance.disableBinLocations(
                                orgId: _currentOrgId,
                                branchId: branch.id,
                              );
                              if (!mounted) return;
                              ZerpaiToast.success(
                                context,
                                'Bin locations disabled for ${branch.name}',
                              );
                              _load();
                            } catch (e) {
                              if (!mounted) return;
                              ZerpaiToast.error(
                                context,
                                e.toString().replaceFirst('Exception: ', ''),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Disable',
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
                            side: const BorderSide(color: AppTheme.borderColor),
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
                LucideIcons.building2,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            const Text(
              'No branches yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            const Text(
              'Add your first branch to manage business locations.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
