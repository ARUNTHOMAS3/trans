import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
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
    ],
  ),
];

// ─── Model ────────────────────────────────────────────────────────────────────

const List<Map<String, String>> _kBranchTypes = [
  {'id': 'fofo', 'code': 'FOFO', 'label': 'Franchise Owned Franchise Operated'},
  {'id': 'coco', 'code': 'COCO', 'label': 'Company Owned Company Operated'},
  {'id': 'fico', 'code': 'FICO', 'label': 'Franchise Invested Company Operated'},
  {'id': 'foco', 'code': 'FOCO', 'label': 'Franchise Owned Company Operated'},
];

const List<String> _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_kMonths[d.month - 1]} ${d.year}';

class _BranchRow {
  final String id;
  final String name;
  final String outletCode;
  final String gstin;
  final String city;
  final String state;
  final String country;
  final bool isActive;
  final bool isPrimary;
  final String branchType;
  final DateTime? subscriptionFrom;
  final DateTime? subscriptionTo;

  const _BranchRow({
    required this.id,
    required this.name,
    required this.outletCode,
    required this.gstin,
    required this.city,
    required this.state,
    required this.country,
    required this.isActive,
    required this.isPrimary,
    required this.branchType,
    this.subscriptionFrom,
    this.subscriptionTo,
  });

  factory _BranchRow.fromJson(Map<String, dynamic> j) => _BranchRow(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        outletCode: (j['outlet_code'] ?? '').toString(),
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
    return _kBranchTypes
        .firstWhere((t) => t['id'] == branchType, orElse: () => {'code': branchType.toUpperCase()})['code']!;
  }

  String get subscriptionPeriod {
    if (subscriptionFrom == null && subscriptionTo == null) return '';
    if (subscriptionFrom != null && subscriptionTo != null) {
      return '${_fmtDate(subscriptionFrom!)} – ${_fmtDate(subscriptionTo!)}';
    }
    if (subscriptionFrom != null) return 'From ${_fmtDate(subscriptionFrom!)}';
    return 'Until ${_fmtDate(subscriptionTo!)}';
  }
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

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authUserProvider);
      final orgId =
          (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;

      final orgRes = await _apiClient.get('lookups/org/$orgId');
      if (!mounted) return;
      if (orgRes.success && orgRes.data is Map<String, dynamic>) {
        _organizationName =
            ((orgRes.data as Map<String, dynamic>)['name'] ?? user?.orgName ?? '')
                .toString()
                .trim();
      } else {
        _organizationName = user?.orgName ?? '';
      }

      final res = await _apiClient.get(
        'outlets',
        queryParameters: <String, dynamic>{
          'org_id': orgId,
          'location_type': 'business',
        },
      );
      if (!mounted) return;
      final List<dynamic> rows =
          res.success && res.data is List ? res.data as List<dynamic> : [];
      setState(() {
        _branches = rows
            .whereType<Map<String, dynamic>>()
            .where((j) =>
                (j['location_type'] ?? 'business').toString() == 'business')
            .map(_BranchRow.fromJson)
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
                        child: const Icon(LucideIcons.chevronLeft,
                            size: 20, color: AppTheme.textPrimary),
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
                              border:
                                  Border.all(color: const Color(0xFFFED7C3)),
                            ),
                            child: const Icon(LucideIcons.settings2,
                                color: Color(0xFFF97316), size: 22),
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
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(LucideIcons.x,
                    size: 16, color: AppTheme.errorRed),
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
                  left: AppTheme.space4, bottom: AppTheme.space8),
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
                      style: AppTheme.bodyText
                          .copyWith(fontWeight: FontWeight.w600),
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
            _buildHeader(),
            const SizedBox(height: AppTheme.space24),
            _buildTable(),
          ],
        ),
      ),
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
          onPressed: () => context.go(AppRoutes.settingsBranchCreate),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space20,
              vertical: AppTheme.space12,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Add Branch',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
          horizontal: AppTheme.space20, vertical: AppTheme.space12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 20),
          SizedBox(width: AppTheme.space12),
          Expanded(flex: 3, child: Text('NAME', style: style)),
          Expanded(flex: 2, child: Text('BRANCH CODE', style: style)),
          Expanded(flex: 2, child: Text('GSTIN', style: style)),
          Expanded(flex: 2, child: Text('BRANCH TYPE', style: style)),
          Expanded(flex: 2, child: Text('ADDRESS DETAILS', style: style)),
          Expanded(flex: 3, child: Text('SUBSCRIPTION PERIOD', style: style)),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildRow(_BranchRow branch) {
    final bool isHovered = _hoveredId == branch.id;
    final Color accentColor = ref.watch(appBrandingProvider).accentColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredId = branch.id),
      onExit: (_) => setState(() => _hoveredId = null),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space20, vertical: AppTheme.space14),
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
              flex: 3,
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
                    const Icon(LucideIcons.star,
                        size: 13, color: Color(0xFFFFC107)),
                  ],
                ],
              ),
            ),
            // Branch code
            Expanded(
              flex: 2,
              child: Text(
                branch.outletCode.isNotEmpty ? branch.outletCode : '—',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
            // GSTIN
            Expanded(
              flex: 2,
              child: branch.gstin.isNotEmpty
                  ? Text(branch.gstin,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textPrimary))
                  : GestureDetector(
                      onTap: () =>
                          ZerpaiToast.info(context, 'Coming soon'),
                      child: Text(
                        'Associate GSTIN >',
                        style: TextStyle(
                          fontSize: 13,
                          color: accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
            ),
            // Branch Type
            Expanded(
              flex: 2,
              child: branch.branchTypeLabel.isNotEmpty
                  ? Text(branch.branchTypeLabel,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500))
                  : const Text('—', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ),
            // Address
            Expanded(
              flex: 2,
              child: Text(
                branch.addressSummary.isNotEmpty ? branch.addressSummary : '—',
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ),
            // Subscription Period
            Expanded(
              flex: 3,
              child: branch.subscriptionPeriod.isNotEmpty
                  ? Text(branch.subscriptionPeriod,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textBody))
                  : const Text('—', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ),
            // Actions
            SizedBox(
              width: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: isHovered
                          ? Icon(LucideIcons.chevronDown,
                              key: const ValueKey('chevron'),
                              size: 16,
                              color: accentColor)
                          : const Icon(LucideIcons.moreHorizontal,
                              key: ValueKey('dots'),
                              size: 16,
                              color: AppTheme.textSecondary),
                    ),
                    itemBuilder: (_) => <PopupMenuEntry<String>>[
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.go(AppRoutes.settingsBranchEdit
                            .replaceFirst(':id', branch.id));
                      } else {
                        ZerpaiToast.info(context, 'Coming soon');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
              child: const Icon(LucideIcons.building2,
                  color: AppTheme.primaryBlue, size: 24),
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
