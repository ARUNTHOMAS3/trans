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
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

const String _kDevOrgId = '00000000-0000-0000-0000-000000000002';

// ─── GSTIN helpers (shared with Associate GSTIN dialog) ──────────────────────

const List<Map<String, String>> _kGstRegTypes = [
  {'id': 'registered_regular', 'label': 'Registered Business - Regular'},
  {'id': 'composition', 'label': 'Composition Scheme'},
  {'id': 'unregistered', 'label': 'Unregistered Business'},
];

InputDecoration _gstDialogInput(String hint) => InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.primaryBlue),
      ),
    );

// ─── Tree connector painter ───────────────────────────────────────────────────

class _TreeLinePainter extends CustomPainter {
  final bool isLastChild;
  const _TreeLinePainter({required this.isLastChild});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.borderColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final midX = size.width * 0.5;
    final midY = size.height * 0.5;
    // Vertical line (top → mid, or full if has more siblings below)
    canvas.drawLine(Offset(midX, 0), Offset(midX, midY), paint);
    if (!isLastChild) {
      canvas.drawLine(Offset(midX, midY), Offset(midX, size.height), paint);
    }
    // Horizontal branch to the right
    canvas.drawLine(Offset(midX, midY), Offset(size.width, midY), paint);
  }

  @override
  bool shouldRepaint(_TreeLinePainter old) => old.isLastChild != isLastChild;
}

// ─── Radio option widget (avoids deprecated Radio.groupValue) ─────────────────

class _RadioOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;

  const _RadioOption({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 18,
            color: selected ? accentColor : AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textBody)),
        ],
      ),
    );
  }
}

Widget _gstDialogRow(
    {required String label, required Widget child, bool req = false}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 180,
        child: Padding(
          padding: const EdgeInsets.only(top: 9),
          child: RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
              children: req
                  ? const [
                      TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppTheme.errorRed))
                    ]
                  : null,
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: child),
    ],
  );
}

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
  final String? parentOutletId;
  final bool isPrimary;

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
    this.parentOutletId,
    this.isPrimary = false,
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
        parentOutletId: j['parent_outlet_id']?.toString(),
        isPrimary: j['is_primary'] as bool? ?? false,
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

class _ContactOption {
  final String id;
  final String name;
  const _ContactOption({required this.id, required this.name});
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
            ..._buildTreeRows(),
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

  List<Widget> _buildTreeRows() {
    final parents = _outlets
        .where((o) => o.parentOutletId == null || o.parentOutletId!.isEmpty)
        .toList();
    final childMap = <String, List<_OutletRow>>{};
    for (final o in _outlets) {
      if (o.parentOutletId != null && o.parentOutletId!.isNotEmpty) {
        childMap.putIfAbsent(o.parentOutletId!, () => []).add(o);
      }
    }
    final rows = <Widget>[];
    for (final parent in parents) {
      final children = childMap[parent.id] ?? [];
      rows.add(_buildTableRow(parent, isChild: false, hasChildren: children.isNotEmpty));
      for (int i = 0; i < children.length; i++) {
        rows.add(_buildTableRow(children[i],
            isChild: true, isLastChild: i == children.length - 1));
      }
    }
    return rows;
  }

  Widget _buildTableRow(_OutletRow outlet,
      {bool isChild = false, bool isLastChild = true, bool hasChildren = false}) {
    final bool isHovered = _hoveredOutletId == outlet.id;
    final Color accentColor = ref.watch(appBrandingProvider).accentColor;

    Widget statusDot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: outlet.isActive ? const Color(0xFF22A95E) : Colors.transparent,
        border: Border.all(
          color: outlet.isActive ? const Color(0xFF22A95E) : AppTheme.textSecondary,
          width: 1.5,
        ),
      ),
    );

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
          // Leading: tree connector for children, status dot for parents
          if (isChild) ...[
            SizedBox(
              width: 22,
              height: 20,
              child: CustomPaint(
                painter: _TreeLinePainter(isLastChild: isLastChild),
              ),
            ),
          ] else ...[
            statusDot,
            const SizedBox(width: AppTheme.space12),
          ],

          // Name
          Expanded(
            flex: 3,
            child: isChild
                ? Row(children: [
                    statusDot,
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                          children: [
                            TextSpan(text: outlet.name),
                            if (outlet.isWarehouse)
                              const TextSpan(
                                text: ' (Warehouse)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ])
                : Row(
                    children: [
                      Flexible(
                        child: Text(
                          outlet.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (outlet.isPrimary) ...[
                        const SizedBox(width: 6),
                        const Icon(LucideIcons.star,
                            size: 13, color: Color(0xFFFFC107)),
                      ],
                    ],
                  ),
          ),

          // GSTIN
          Expanded(
            flex: 2,
            child: outlet.gstin.isNotEmpty
                ? Text(
                    outlet.gstin,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textPrimary),
                  )
                : GestureDetector(
                    onTap: () => _showAssociateGstinDialog(outlet),
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
      case 'bin_locations':
        ZerpaiToast.info(context, 'Coming soon');
      case 'associate_gstin':
        _showAssociateGstinDialog(outlet);
      case 'associate_contacts':
        _showAssociateContactsDialog(outlet);
    }
  }

  Future<void> _showAssociateContactsDialog(_OutletRow outlet) async {
    final user = ref.read(authUserProvider);
    final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;

    // Load customers and vendors in parallel
    List<_ContactOption> customers = [];
    List<_ContactOption> vendors = [];
    String? selectedCustomerId;
    String? selectedVendorId;

    try {
      final results = await Future.wait([
        _apiClient.get('/customers', queryParameters: {'org_id': orgId}),
        _apiClient.get('/vendors', queryParameters: {'org_id': orgId}),
      ]);
      if (!mounted) return;
      if (results[0].success && results[0].data is List) {
        customers = (results[0].data as List)
            .cast<Map<String, dynamic>>()
            .map((c) => _ContactOption(
                  id: c['id'].toString(),
                  name: (c['contact_name'] ?? c['name'] ?? '').toString(),
                ))
            .toList();
      }
      if (results[1].success && results[1].data is List) {
        vendors = (results[1].data as List)
            .cast<Map<String, dynamic>>()
            .map((v) => _ContactOption(
                  id: v['id'].toString(),
                  name: (v['contact_name'] ?? v['name'] ?? '').toString(),
                ))
            .toList();
      }
    } catch (_) {}

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 480,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Associate Customer and Vendor',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
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
                  const SizedBox(height: AppTheme.space12),
                  const Text(
                    'The customer and vendor you select here will be used to create '
                    'the respective invoice and bill for transfer orders created for '
                    'locations having different GSTIN.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),

                  // Customer Name
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
                    value: customers
                        .where((c) => c.id == selectedCustomerId)
                        .firstOrNull,
                    items: customers,
                    displayStringForValue: (c) => c.name,
                    hint: 'Select customer',
                    onChanged: (c) =>
                        setDialogState(() => selectedCustomerId = c?.id),
                  ),
                  const SizedBox(height: AppTheme.space16),

                  // Vendor Name
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
                    value: vendors
                        .where((v) => v.id == selectedVendorId)
                        .firstOrNull,
                    items: vendors,
                    displayStringForValue: (v) => v.name,
                    hint: 'Select a Vendor',
                    onChanged: (v) =>
                        setDialogState(() => selectedVendorId = v?.id),
                  ),
                  const SizedBox(height: AppTheme.space28),

                  // Actions
                  Row(
                    children: [
                      Consumer(
                        builder: (_, ref, __) {
                          final accentColor =
                              ref.watch(appBrandingProvider).accentColor;
                          return ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              try {
                                final res = await _apiClient.patch(
                                  '/outlets/${outlet.id}/contacts?org_id=$orgId',
                                  data: {
                                    'customer_id': selectedCustomerId,
                                    'vendor_id': selectedVendorId,
                                  },
                                );
                                if (!mounted) return;
                                if (res.success) {
                                  ZerpaiToast.success(
                                      context, 'Contacts associated');
                                } else {
                                  ZerpaiToast.error(
                                    context,
                                    res.message ?? 'Failed to associate contacts',
                                  );
                                }
                              } catch (_) {
                                if (mounted) {
                                  ZerpaiToast.error(
                                      context, 'Failed to associate contacts');
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space24,
                                vertical: AppTheme.space12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text(
                              'Update',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: AppTheme.space12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space20,
                            vertical: AppTheme.space12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          side: const BorderSide(color: AppTheme.borderColor),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppTheme.textBody),
                        ),
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
  }

  Future<void> _confirmDelete(_OutletRow outlet) async {
    final user = ref.read(authUserProvider);
    final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;

    // Check if this location has linked transactions before allowing delete
    try {
      final checkRes = await _apiClient.get(
        '/outlets/${outlet.id}/usage',
        queryParameters: {'org_id': orgId},
      );
      if (!mounted) return;
      if (checkRes.success && checkRes.data is Map<String, dynamic>) {
        final hasTransactions =
            (checkRes.data as Map<String, dynamic>)['has_transactions'] == true;
        if (hasTransactions) {
          ZerpaiToast.error(
            context,
            'This location cannot be deleted as it is associated with transactions. '
            'You can however mark the location as inactive.',
          );
          return;
        }
      }
    } catch (_) {
      // Usage check endpoint not available — proceed; delete API will handle
      // FK constraint violations and surface the error via res.message
    }

    if (!mounted) return;
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

  Future<void> _showAssociateGstinDialog(_OutletRow outlet) async {
    final user = ref.read(authUserProvider);
    final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;

    // Local dialog state
    bool addNew = true; // true = Add New GSTIN, false = Associate Existing
    // "Add New" fields
    final gstinCtrl = TextEditingController();
    final legalNameCtrl = TextEditingController();
    final tradeNameCtrl = TextEditingController();
    final regDateCtrl = TextEditingController();
    String? regType;
    bool reverseCharge = false;
    bool importExport = false;
    bool digitalServices = false;
    String? gstinError;
    bool fetching = false;
    String? fetchError;
    // "Associate Existing" field
    String? selectedExistingGstin;
    final existingGstins = _outlets
        .where((o) => o.id != outlet.id && o.gstin.isNotEmpty)
        .map((o) => o.gstin)
        .toSet()
        .toList();

    Future<void> doSave(String gstin, StateSetter setDS) async {
      try {
        final res = await _apiClient.patch(
          '/outlets/${outlet.id}?org_id=$orgId',
          data: {
            'gstin': gstin,
            if (addNew) ...{
              'gstin_registration_type': regType,
              'gstin_legal_name': legalNameCtrl.text.trim(),
              'gstin_trade_name': tradeNameCtrl.text.trim(),
              'gstin_registered_on': regDateCtrl.text.trim(),
              'gstin_reverse_charge': reverseCharge,
              'gstin_import_export': importExport,
              'gstin_digital_services': digitalServices,
            },
          },
        );
        if (!mounted) return;
        if (res.success) {
          ZerpaiToast.success(context, 'GSTIN associated');
          _load();
        } else {
          ZerpaiToast.error(context, res.message ?? 'Failed to update GSTIN');
        }
      } catch (_) {
        if (mounted) ZerpaiToast.error(context, 'Failed to update GSTIN');
      }
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) {
          final accentColor = ref.read(appBrandingProvider).accentColor;

          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Associate GSTIN to ${outlet.name}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(LucideIcons.x,
                              size: 18, color: AppTheme.errorRed),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.borderLight),

                  // Scrollable body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Association Type radios
                          _gstDialogRow(
                            label: 'Association Type',
                            req: true,
                            child: Row(
                              children: [
                                _RadioOption(
                                  label: 'Add New GSTIN & Associate',
                                  selected: addNew,
                                  onTap: () => setDS(() => addNew = true),
                                  accentColor: accentColor,
                                ),
                                const SizedBox(width: 20),
                                _RadioOption(
                                  label: 'Associate Existing GSTIN',
                                  selected: !addNew,
                                  onTap: () => setDS(() => addNew = false),
                                  accentColor: accentColor,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space16),

                          if (!addNew) ...[
                            // ── Associate Existing mode ──
                            _gstDialogRow(
                              label: 'GSTIN',
                              req: true,
                              child: existingGstins.isEmpty
                                  ? const Text(
                                      'No other GSTINs found in your organization.',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary),
                                    )
                                  : FormDropdown<String>(
                                      value: selectedExistingGstin,
                                      items: existingGstins,
                                      displayStringForValue: (g) => g,
                                      hint: 'Select GSTIN',
                                      onChanged: (g) =>
                                          setDS(() => selectedExistingGstin = g),
                                    ),
                            ),
                          ] else ...[
                            // ── Add New GSTIN mode ──
                            _gstDialogRow(
                              label: 'GSTIN',
                              req: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: gstinCtrl,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary),
                                    decoration: _gstDialogInput(
                                        'e.g. 27ABCDE1234F2Z5'),
                                    onChanged: (_) =>
                                        setDS(() => gstinError = null),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          gstinError ?? 'Maximum 15 digits',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: gstinError != null
                                                ? AppTheme.errorRed
                                                : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      if (fetching)
                                        const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 1.5),
                                        )
                                      else
                                        GestureDetector(
                                          onTap: () async {
                                            final gstin = gstinCtrl.text
                                                .trim()
                                                .toUpperCase();
                                            if (gstin.length != 15) {
                                              setDS(() => gstinError =
                                                  'GSTIN must be exactly 15 characters');
                                              return;
                                            }
                                            setDS(() {
                                              fetching = true;
                                              fetchError = null;
                                            });
                                            try {
                                              final res =
                                                  await _apiClient.get(
                                                '/gst/taxpayer-details',
                                                queryParameters: {
                                                  'gstin': gstin
                                                },
                                              );
                                              if (!ctx.mounted) return;
                                              final d = res.data
                                                  as Map<String, dynamic>?;
                                              setDS(() {
                                                legalNameCtrl.text =
                                                    (d?['legalName'] ?? '')
                                                        .toString();
                                                tradeNameCtrl.text =
                                                    (d?['tradeName'] ?? '')
                                                        .toString();
                                                regDateCtrl.text =
                                                    (d?['registeredOn'] ?? '')
                                                        .toString();
                                                if (d?['registrationType'] !=
                                                    null) {
                                                  regType = d!['registrationType']
                                                      .toString();
                                                }
                                                fetching = false;
                                              });
                                            } catch (_) {
                                              if (ctx.mounted) {
                                                setDS(() {
                                                  fetchError =
                                                      'Could not fetch taxpayer details';
                                                  fetching = false;
                                                });
                                              }
                                            }
                                          },
                                          child: const Text(
                                            'Get Taxpayer details',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.primaryBlue,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (fetchError != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(fetchError!,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.errorRed)),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTheme.space16),

                            _gstDialogRow(
                              label: 'Registration Type',
                              child: FormDropdown<Map<String, String>>(
                                value: _kGstRegTypes
                                    .where((t) => t['id'] == regType)
                                    .firstOrNull,
                                items: _kGstRegTypes,
                                displayStringForValue: (t) => t['label'] ?? '',
                                hint: 'Select a Registration Type',
                                onChanged: (t) =>
                                    setDS(() => regType = t?['id']),
                              ),
                            ),
                            const SizedBox(height: AppTheme.space16),

                            _gstDialogRow(
                              label: 'Business Legal Name',
                              child: TextField(
                                controller: legalNameCtrl,
                                decoration: _gstDialogInput('Legal name'),
                                style: const TextStyle(
                                    fontSize: 13, color: AppTheme.textPrimary),
                              ),
                            ),
                            const SizedBox(height: AppTheme.space16),

                            _gstDialogRow(
                              label: 'Business Trade Name',
                              child: TextField(
                                controller: tradeNameCtrl,
                                decoration: _gstDialogInput('Trade name'),
                                style: const TextStyle(
                                    fontSize: 13, color: AppTheme.textPrimary),
                              ),
                            ),
                            const SizedBox(height: AppTheme.space16),

                            _gstDialogRow(
                              label: 'GST Registered On',
                              child: TextField(
                                controller: regDateCtrl,
                                decoration: _gstDialogInput('dd-MM-yyyy'),
                                keyboardType: TextInputType.datetime,
                                style: const TextStyle(
                                    fontSize: 13, color: AppTheme.textPrimary),
                              ),
                            ),
                            const SizedBox(height: AppTheme.space16),

                            _gstDialogRow(
                              label: 'Reverse Charge',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: Checkbox(
                                        value: reverseCharge,
                                        onChanged: (v) => setDS(
                                            () => reverseCharge = v ?? false),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                        'Enable Reverse Charge in Sales transactions',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textBody)),
                                  ]),
                                  const SizedBox(height: 4),
                                  const Text('Know more',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primaryBlue,
                                          decoration:
                                              TextDecoration.underline)),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTheme.space16),

                            _gstDialogRow(
                              label: 'Import / Export',
                              child: Row(children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: Checkbox(
                                    value: importExport,
                                    onChanged: (v) =>
                                        setDS(() => importExport = v ?? false),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                      'My business is involved in SEZ / Overseas Trading',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textBody)),
                                ),
                              ]),
                            ),
                            const SizedBox(height: AppTheme.space16),

                            _gstDialogRow(
                              label: 'Digital Services',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: Checkbox(
                                        value: digitalServices,
                                        onChanged: (v) => setDS(
                                            () => digitalServices = v ?? false),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                          'Track sale of digital services to overseas customers',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textBody)),
                                    ),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(
                                    digitalServices
                                        ? 'If you disable this option, any digital service created by you will be considered as a service.'
                                        : 'Enabling this option will let you record and track export of digital services to individuals.',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 1, color: AppTheme.borderLight),
                  // Footer
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            String gstin;
                            if (addNew) {
                              gstin = gstinCtrl.text.trim().toUpperCase();
                              final rx = RegExp(
                                  r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}Z[A-Z\d]{1}$');
                              if (gstin.isEmpty || !rx.hasMatch(gstin)) {
                                setDS(() => gstinError =
                                    'Enter a valid 15-character GSTIN');
                                return;
                              }
                            } else {
                              if (selectedExistingGstin == null) {
                                ZerpaiToast.info(ctx, 'Select a GSTIN');
                                return;
                              }
                              gstin = selectedExistingGstin!;
                            }
                            Navigator.pop(ctx);
                            await doSave(gstin, setDS);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Save',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            side: const BorderSide(color: AppTheme.borderColor),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(color: AppTheme.textBody)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    gstinCtrl.dispose();
    legalNameCtrl.dispose();
    tradeNameCtrl.dispose();
    regDateCtrl.dispose();
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
