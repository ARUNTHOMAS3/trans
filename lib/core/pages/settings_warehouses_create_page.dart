import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
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

const List<String> _indianStates = <String>[
  'Andaman and Nicobar Islands', 'Andhra Pradesh', 'Arunachal Pradesh',
  'Assam', 'Bihar', 'Chandigarh', 'Chhattisgarh',
  'Dadra and Nagar Haveli and Daman and Diu', 'Delhi', 'Goa', 'Gujarat',
  'Haryana', 'Himachal Pradesh', 'Jammu and Kashmir', 'Jharkhand',
  'Karnataka', 'Kerala', 'Ladakh', 'Lakshadweep', 'Madhya Pradesh',
  'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha',
  'Puducherry', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana',
  'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
];

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
      _NavBlock(title: 'Organization', items: <_NavEntry>[
        _NavEntry(label: 'Profile', route: AppRoutes.settingsOrgProfile),
        _NavEntry(label: 'Branding', route: AppRoutes.settingsOrgBranding),
        _NavEntry(label: 'Branches', route: AppRoutes.settingsBranches),
        _NavEntry(label: 'Warehouses', route: AppRoutes.settingsWarehouses),
        _NavEntry(label: 'Approvals'),
        _NavEntry(label: 'Manage Subscription'),
      ]),
      _NavBlock(title: 'Users & Roles', items: <_NavEntry>[
        _NavEntry(label: 'Users'), _NavEntry(label: 'Roles'), _NavEntry(label: 'User Preferences'),
      ]),
      _NavBlock(title: 'Taxes & Compliance', items: <_NavEntry>[
        _NavEntry(label: 'Taxes'), _NavEntry(label: 'Direct Taxes'),
        _NavEntry(label: 'e-Way Bills'), _NavEntry(label: 'e-Invoicing'), _NavEntry(label: 'MSME Settings'),
      ]),
      _NavBlock(title: 'Setup & Configurations', items: <_NavEntry>[
        _NavEntry(label: 'General'), _NavEntry(label: 'Currencies'),
        _NavEntry(label: 'Reminders'), _NavEntry(label: 'Customer Portal'),
      ]),
      _NavBlock(title: 'Customization', items: <_NavEntry>[
        _NavEntry(label: 'Transaction Number Series'), _NavEntry(label: 'PDF Templates'),
        _NavEntry(label: 'Email Notifications'), _NavEntry(label: 'SMS Notifications'),
        _NavEntry(label: 'Reporting Tags'), _NavEntry(label: 'Web Tabs'),
      ]),
      _NavBlock(title: 'Automation', items: <_NavEntry>[
        _NavEntry(label: 'Workflow Rules'), _NavEntry(label: 'Workflow Actions'),
        _NavEntry(label: 'Workflow Logs', route: AppRoutes.auditLogs),
      ]),
    ],
  ),
  _NavSection(
    title: 'Module Settings',
    blocks: <_NavBlock>[
      _NavBlock(title: 'General', items: <_NavEntry>[
        _NavEntry(label: 'Customers and Vendors', route: AppRoutes.salesCustomers),
        _NavEntry(label: 'Items', route: AppRoutes.itemsReport),
      ]),
    ],
  ),
];

// ─── Branch option ────────────────────────────────────────────────────────────

class _BranchOption {
  final String id;
  final String name;
  const _BranchOption({required this.id, required this.name});
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class SettingsWarehouseCreatePage extends ConsumerStatefulWidget {
  final String? warehouseId;
  const SettingsWarehouseCreatePage({super.key, this.warehouseId});

  @override
  ConsumerState<SettingsWarehouseCreatePage> createState() =>
      _SettingsWarehouseCreatePageState();
}

class _SettingsWarehouseCreatePageState
    extends ConsumerState<SettingsWarehouseCreatePage> {
  final ApiClient _apiClient = ApiClient();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _warehouseCodeCtrl = TextEditingController();
  final TextEditingController _attentionCtrl = TextEditingController();
  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _street2Ctrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();

  String? _selectedState;
  String? _parentBranchId;
  String? _parentBranchError;
  bool _isSaving = false;
  bool _isLoading = false;
  String _organizationName = '';
  List<_BranchOption> _branches = <_BranchOption>[];
  final Set<String> _expandedBlocks = <String>{'Organization'};

  bool get _isEditing => widget.warehouseId != null;

  // Label column width for the two-column row layout
  static const double _labelWidth = 180.0;

  @override
  void initState() {
    super.initState();
    _loadOrgAndBranches();
    if (_isEditing) _loadExisting();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _nameCtrl.dispose();
    _warehouseCodeCtrl.dispose();
    _attentionCtrl.dispose();
    _streetCtrl.dispose();
    _street2Ctrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrgAndBranches() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final orgRes = await _apiClient.get('lookups/org/$orgId');
      if (!mounted) return;
      setState(() {
        _organizationName = orgRes.success && orgRes.data is Map<String, dynamic>
            ? ((orgRes.data as Map<String, dynamic>)['name'] ?? user?.orgName ?? '').toString().trim()
            : user?.orgName ?? '';
      });
      final res = await _apiClient.get('branches', queryParameters: <String, dynamic>{'org_id': orgId});
      if (!mounted) return;
      if (res.success && res.data is List) {
        setState(() {
          _branches = (res.data as List)
              .whereType<Map<String, dynamic>>()
              .map((o) => _BranchOption(id: o['id'].toString(), name: o['name'].toString()))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final res = await _apiClient.get('warehouses-settings/${widget.warehouseId}', queryParameters: {'org_id': orgId});
      if (!mounted) return;
      if (res.success && res.data is Map<String, dynamic>) {
        final d = res.data as Map<String, dynamic>;
        _nameCtrl.text = (d['name'] ?? '').toString();
        _warehouseCodeCtrl.text = (d['warehouse_code'] ?? '').toString();
        _attentionCtrl.text = (d['attention'] ?? '').toString();
        _streetCtrl.text = (d['address_street_1'] ?? '').toString();
        _street2Ctrl.text = (d['address_street_2'] ?? '').toString();
        _cityCtrl.text = (d['city'] ?? '').toString();
        _pincodeCtrl.text = (d['pincode'] ?? '').toString();
        final stateVal = (d['state'] ?? '').toString();
        final parentId = d['branch_id']?.toString();
        setState(() {
          _selectedState = _indianStates.contains(stateVal) ? stateVal : null;
          if (parentId != null && parentId.isNotEmpty) _parentBranchId = parentId;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_parentBranchId == null) {
      setState(() => _parentBranchError = 'Parent branch is required');
      return;
    } else {
      setState(() => _parentBranchError = null);
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final nameCheck = await ref.read(apiClientProvider).get('warehouses-settings', queryParameters: {'org_id': orgId});
      if (nameCheck.success && nameCheck.data is List) {
        final trimmed = _nameCtrl.text.trim().toLowerCase();
        final duplicate = (nameCheck.data as List).any((o) {
          final isSelf = widget.warehouseId != null && o['id']?.toString() == widget.warehouseId;
          return !isSelf && (o['name'] ?? '').toString().toLowerCase() == trimmed;
        });
        if (duplicate) {
          setState(() => _isSaving = false);
          if (mounted) ZerpaiToast.error(context, 'A warehouse with this name already exists.');
          return;
        }
      }
      final body = <String, dynamic>{
        'org_id': orgId,
        'name': _nameCtrl.text.trim(),
        'warehouse_code': _warehouseCodeCtrl.text.trim().isNotEmpty
            ? _warehouseCodeCtrl.text.trim().toUpperCase()
            : _nameCtrl.text.trim().toUpperCase().replaceAll(' ', '-'),
        'branch_id': _parentBranchId,
        'attention': _attentionCtrl.text.trim(),
        'address_street_1': _streetCtrl.text.trim(),
        'address_street_2': _street2Ctrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _selectedState ?? '',
        'pincode': _pincodeCtrl.text.trim(),
        'country': 'India',
      };
      final apiClient = ref.read(apiClientProvider);
      final res = _isEditing
          ? await apiClient.put('warehouses-settings/${widget.warehouseId}', data: body)
          : await apiClient.post('warehouses-settings', data: body);
      if (!mounted) return;
      if (res.success) {
        ZerpaiToast.success(context, _isEditing ? 'Warehouse updated successfully.' : 'Warehouse created successfully.');
        context.go(AppRoutes.settingsWarehouses);
      } else {
        ZerpaiToast.error(context, (res.message?.isNotEmpty == true) ? res.message! : 'Failed to save warehouse.');
      }
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '', useHorizontalPadding: false, useTopPadding: false,
      enableBodyScroll: false, searchFocusNode: _searchFocusNode,
      child: Container(
        color: AppTheme.bgLight,
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_buildSidebar(), Expanded(child: _buildBody())],
            )),
          ],
        ),
      ),
    );
  }

  // ─── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppTheme.space32, AppTheme.space20, AppTheme.space32, AppTheme.space16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppTheme.borderLight))),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1560),
          child: Row(
            children: [
              SizedBox(width: 320, child: Row(children: [
                InkWell(
                  onTap: () => context.go(AppRoutes.settings),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(width: 44, height: 44,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
                      child: const Icon(LucideIcons.chevronLeft, size: 20, color: AppTheme.textPrimary)),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(child: Row(children: [
                  Container(width: 48, height: 48,
                      decoration: BoxDecoration(color: const Color(0xFFFFF3EE), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFED7C3))),
                      child: const Icon(LucideIcons.settings2, color: Color(0xFFF97316), size: 22)),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('All Settings', style: AppTheme.pageTitle),
                    const SizedBox(height: AppTheme.space4),
                    Text(_organizationName.isNotEmpty ? _organizationName : 'Your Organization',
                        style: AppTheme.bodyText, overflow: TextOverflow.ellipsis),
                  ])),
                ])),
              ])),
              const SizedBox(width: AppTheme.space24),
              Expanded(child: Center(child: SizedBox(width: 360, height: 42,
                  child: SettingsSearchField(items: const <SettingsSearchItem>[], focusNode: _searchFocusNode,
                      controller: _searchController, onQueryChanged: (_) {},
                      onNoMatch: (q) => ZerpaiToast.info(context, 'No settings matched "$q"'))))),
              const SizedBox(width: AppTheme.space24),
              TextButton.icon(
                onPressed: () => context.go(AppRoutes.settings),
                style: TextButton.styleFrom(foregroundColor: AppTheme.textPrimary, backgroundColor: AppTheme.bgLight,
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
    final String currentPath = GoRouterState.of(context).uri.path.replaceFirst(RegExp(r'^/\d{10,20}'), '');
    return Container(
      width: 240,
      decoration: const BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: AppTheme.borderLight))),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppTheme.space12, AppTheme.space20, AppTheme.space12, AppTheme.space24),
        children: [
          for (final section in _navSections) ...[
            Padding(padding: const EdgeInsets.only(left: AppTheme.space4, bottom: AppTheme.space8),
                child: Text(section.title.toUpperCase(),
                    style: AppTheme.captionText.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
            for (final block in section.blocks) _buildSidebarBlock(block, currentPath),
            const SizedBox(height: AppTheme.space12),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarBlock(_NavBlock block, String currentPath) {
    final bool hasActiveChild = block.items.any((item) => item.route == currentPath);
    final bool isExpanded = _expandedBlocks.contains(block.title) || hasActiveChild;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space4),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() {
            if (isExpanded) _expandedBlocks.remove(block.title); else _expandedBlocks.add(block.title);
          }),
          borderRadius: BorderRadius.circular(12),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: AppTheme.space10),
              child: Row(children: [
                Icon(isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: AppTheme.space8),
                Expanded(child: Text(block.title, style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600))),
              ])),
        ),
        if (isExpanded)
          Padding(padding: const EdgeInsets.only(left: AppTheme.space28, right: AppTheme.space8, bottom: AppTheme.space6),
              child: Column(children: block.items.map((e) => _buildSidebarEntry(e, currentPath)).toList())),
      ]),
    );
  }

  Widget _buildSidebarEntry(_NavEntry entry, String currentPath) {
    final bool isActive = entry.route != null &&
        (entry.route == currentPath ||
            (entry.route == AppRoutes.settingsWarehouses &&
                (currentPath.startsWith('/settings/warehouses/create') ||
                    (currentPath.contains('/settings/warehouses/') && currentPath.contains('/edit')))));
    final Color accentColor = ref.watch(appBrandingProvider).accentColor;
    return InkWell(
      onTap: () {
        if (entry.route == null) { ZerpaiToast.info(context, '${entry.label} is not available yet'); return; }
        context.go(entry.route!);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity, margin: const EdgeInsets.only(bottom: AppTheme.space4),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space10),
        decoration: BoxDecoration(color: isActive ? accentColor : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Text(entry.label, style: AppTheme.bodyText.copyWith(
            fontSize: 13, color: isActive ? Colors.white : AppTheme.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isEditing ? 'Edit Warehouse' : 'Add Warehouse',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: AppTheme.space24),

                // ── Warehouse Details ──────────────────────────────────────
                _buildSectionLabel('Warehouse Details'),
                const SizedBox(height: AppTheme.space12),
                _buildCard(children: [
                  _buildRow(label: 'Warehouse name', required: true,
                      child: TextFormField(controller: _nameCtrl, decoration: _dec('e.g. Central Warehouse'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Warehouse name is required' : null)),
                  _buildDivider(),
                  _buildRow(label: 'Warehouse code',
                      child: TextFormField(controller: _warehouseCodeCtrl, decoration: _dec('e.g. WH-01'),
                          inputFormatters: [LengthLimitingTextInputFormatter(20)])),
                  _buildDivider(),
                  _buildRow(label: 'Parent branch', required: true,
                      child: FormDropdown<String>(
                        items: _branches.map((b) => b.id).toList(),
                        value: _parentBranchId,
                        hint: 'Select parent branch',
                        displayStringForValue: (id) => _branches.firstWhere((b) => b.id == id, orElse: () => _BranchOption(id: id, name: id)).name,
                        errorText: _parentBranchError,
                        onChanged: (v) => setState(() { _parentBranchId = v; _parentBranchError = null; }),
                      )),
                ]),

                const SizedBox(height: AppTheme.space20),

                // ── Address ────────────────────────────────────────────────
                _buildSectionLabel('Address'),
                const SizedBox(height: AppTheme.space12),
                _buildCard(children: [
                  _buildRow(label: 'Attention',
                      child: TextFormField(controller: _attentionCtrl, decoration: _dec('Attention'))),
                  _buildDivider(),
                  _buildRow(label: 'Street 1',
                      child: TextFormField(controller: _streetCtrl, decoration: _dec('Street 1'))),
                  _buildDivider(),
                  _buildRow(label: 'Street 2',
                      child: TextFormField(controller: _street2Ctrl, decoration: _dec('Street 2'))),
                  _buildDivider(),
                  _buildRow(label: 'City',
                      child: TextFormField(controller: _cityCtrl, decoration: _dec('City'))),
                  _buildDivider(),
                  _buildRow(label: 'State / Union Territory',
                      child: FormDropdown<String>(items: _indianStates, value: _selectedState, hint: 'Select state',
                          onChanged: (v) => setState(() => _selectedState = v))),
                  _buildDivider(),
                  _buildRow(label: 'Pin Code',
                      child: TextFormField(controller: _pincodeCtrl, decoration: _dec('560001'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)])),
                  _buildDivider(),
                  _buildRow(label: 'Country', child: _buildStaticField('India')),
                ]),

                const SizedBox(height: AppTheme.space32),
                _buildActions(),
                const SizedBox(height: AppTheme.space48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Widget _buildActions() {
    final accentColor = ref.watch(appBrandingProvider).accentColor;
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      TextButton(onPressed: _isSaving ? null : () => context.go(AppRoutes.settingsWarehouses),
          style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary), child: const Text('Cancel')),
      const SizedBox(width: AppTheme.space12),
      ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: _isSaving
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(_isEditing ? 'Save Changes' : 'Add Warehouse',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    ]);
  }

  // ─── Shared helpers ────────────────────────────────────────────────────────

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.3));
  }

  Widget _buildRow({required String label, bool required = false, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _labelWidth,
            child: RichText(
              text: TextSpan(
                text: label,
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
                children: required ? const [TextSpan(text: ' *', style: TextStyle(color: AppTheme.errorRed))] : null,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 0, endIndent: 0, color: AppTheme.borderLight);

  Widget _buildStaticField(String value) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
      decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppTheme.borderLight)),
      alignment: Alignment.centerLeft,
      child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.borderLight)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.borderLight)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: ref.watch(appBrandingProvider).accentColor)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.errorRed)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.errorRed)),
    filled: false,
  );
}
