import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, LengthLimitingTextInputFormatter, TextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/services/storage_service.dart';
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

const List<Map<String, String>> _kGstRegistrationTypes = [
  {'id': 'registered_regular', 'label': 'Registered Business - Regular'},
  {'id': 'composition', 'label': 'Composition Scheme'},
  {'id': 'unregistered', 'label': 'Unregistered Business'},
  {'id': 'consumer', 'label': 'Consumer'},
  {'id': 'overseas', 'label': 'Overseas'},
  {'id': 'sez', 'label': 'Special Economic Zone'},
  {'id': 'deemed_export', 'label': 'Deemed Export'},
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
        _NavEntry(label: 'Users'),
        _NavEntry(label: 'Roles'),
        _NavEntry(label: 'User Preferences'),
      ]),
      _NavBlock(title: 'Taxes & Compliance', items: <_NavEntry>[
        _NavEntry(label: 'Taxes'),
        _NavEntry(label: 'Direct Taxes'),
        _NavEntry(label: 'e-Way Bills'),
        _NavEntry(label: 'e-Invoicing'),
        _NavEntry(label: 'MSME Settings'),
      ]),
      _NavBlock(title: 'Setup & Configurations', items: <_NavEntry>[
        _NavEntry(label: 'General'),
        _NavEntry(label: 'Currencies'),
        _NavEntry(label: 'Reminders'),
        _NavEntry(label: 'Customer Portal'),
      ]),
      _NavBlock(title: 'Customization', items: <_NavEntry>[
        _NavEntry(label: 'Transaction Number Series'),
        _NavEntry(label: 'PDF Templates'),
        _NavEntry(label: 'Email Notifications'),
        _NavEntry(label: 'SMS Notifications'),
        _NavEntry(label: 'Reporting Tags'),
        _NavEntry(label: 'Web Tabs'),
      ]),
      _NavBlock(title: 'Automation', items: <_NavEntry>[
        _NavEntry(label: 'Workflow Rules'),
        _NavEntry(label: 'Workflow Actions'),
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

// ─── India phone formatter ────────────────────────────────────────────────────

class _IndiaPhoneFormatter extends TextInputFormatter {
  static const String _prefix = '+91 ';
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    if (!text.startsWith(_prefix)) {
      String digits = text.replaceAll(RegExp(r'\D'), '');
      if (digits.startsWith('91') && digits.length > 10) digits = digits.substring(2);
      if (digits.length > 10) digits = digits.substring(0, 10);
      final result = _prefix + digits;
      return TextEditingValue(
          text: result, selection: TextSelection.collapsed(offset: result.length));
    }
    String digits = text.substring(_prefix.length).replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);
    final result = _prefix + digits;
    return TextEditingValue(
        text: result, selection: TextSelection.collapsed(offset: result.length));
  }
}

String _normalizeIndiaPhone(String raw) {
  if (raw.isEmpty) return '+91 ';
  final digits = raw.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
  final stripped = digits.startsWith('91') && digits.length > 10 ? digits.substring(2) : digits;
  final limited = stripped.length > 10 ? stripped.substring(0, 10) : stripped;
  return '+91 $limited';
}

// ─── GSTIN data ───────────────────────────────────────────────────────────────

class _GstinData {
  final String gstin;
  final String? registrationType;
  final String legalName;
  final String tradeName;
  final String? registeredOn;
  final bool reverseCharge;
  final bool importExport;
  final bool digitalServices;
  const _GstinData({
    required this.gstin,
    this.registrationType,
    this.legalName = '',
    this.tradeName = '',
    this.registeredOn,
    this.reverseCharge = false,
    this.importExport = false,
    this.digitalServices = false,
  });
}

class _SeriesOption {
  final String id;
  final String name;
  const _SeriesOption({required this.id, required this.name});
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class SettingsBranchCreatePage extends ConsumerStatefulWidget {
  final String? branchId;
  const SettingsBranchCreatePage({super.key, this.branchId});

  @override
  ConsumerState<SettingsBranchCreatePage> createState() =>
      _SettingsBranchCreatePageState();
}

class _SettingsBranchCreatePageState
    extends ConsumerState<SettingsBranchCreatePage> {
  final ApiClient _apiClient = ApiClient();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _branchCodeCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _websiteCtrl = TextEditingController();
  final TextEditingController _attentionCtrl = TextEditingController();
  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _street2Ctrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();

  String? _selectedState;
  bool _isPrimary = false;
  bool _isSaving = false;
  bool _isLoading = false;
  String _organizationName = '';
  String _logoOption = 'same';
  PlatformFile? _logoPicked;
  String? _logoUrl;
  _GstinData? _gstinData;
  List<_SeriesOption> _transactionSeries = [];
  String? _selectedDefaultSeriesId;
  final Set<String> _expandedBlocks = <String>{'Organization'};

  bool get _isEditing => widget.branchId != null;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = '+91 ';
    _loadOrgName();
    _loadTransactionSeries();
    if (_isEditing) _loadExisting();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _nameCtrl.dispose();
    _branchCodeCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _attentionCtrl.dispose();
    _streetCtrl.dispose();
    _street2Ctrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrgName() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final res = await _apiClient.get('lookups/org/$orgId');
      if (!mounted) return;
      setState(() {
        _organizationName = res.success && res.data is Map<String, dynamic>
            ? ((res.data as Map<String, dynamic>)['name'] ?? user?.orgName ?? '').toString().trim()
            : user?.orgName ?? '';
      });
    } catch (_) {}
  }

  Future<void> _loadTransactionSeries() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final res = await _apiClient.get('transaction-series', queryParameters: {'org_id': orgId});
      if (!mounted) return;
      if (res.success && res.data is List) {
        setState(() {
          _transactionSeries = (res.data as List)
              .cast<Map<String, dynamic>>()
              .map((s) => _SeriesOption(id: s['id'].toString(), name: (s['name'] ?? s['series_name'] ?? '').toString()))
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
      final res = await _apiClient.get('outlets/${widget.branchId}', queryParameters: {'org_id': orgId});
      if (!mounted) return;
      if (res.success && res.data is Map<String, dynamic>) {
        final d = res.data as Map<String, dynamic>;
        _nameCtrl.text = (d['name'] ?? '').toString();
        _branchCodeCtrl.text = (d['outlet_code'] ?? '').toString();
        _emailCtrl.text = (d['email'] ?? '').toString();
        _phoneCtrl.text = _normalizeIndiaPhone((d['phone'] ?? '').toString());
        _websiteCtrl.text = (d['website'] ?? '').toString();
        _attentionCtrl.text = (d['attention'] ?? '').toString();
        _streetCtrl.text = (d['address'] ?? '').toString();
        _street2Ctrl.text = (d['address2'] ?? '').toString();
        _cityCtrl.text = (d['city'] ?? '').toString();
        _pincodeCtrl.text = (d['pincode'] ?? '').toString();
        final stateVal = (d['state'] ?? '').toString();
        final logoUrl = d['logo_url']?.toString();
        final gstinStr = (d['gstin'] ?? '').toString();
        final defaultSeriesId = d['default_transaction_series_id']?.toString();
        setState(() {
          _selectedState = _indianStates.contains(stateVal) ? stateVal : null;
          _isPrimary = d['is_primary'] as bool? ?? false;
          if (logoUrl != null && logoUrl.isNotEmpty) { _logoUrl = logoUrl; _logoOption = 'upload'; }
          if (gstinStr.isNotEmpty) {
            _gstinData = _GstinData(
              gstin: gstinStr,
              registrationType: d['gstin_registration_type']?.toString(),
              legalName: (d['gstin_legal_name'] ?? '').toString(),
              tradeName: (d['gstin_trade_name'] ?? '').toString(),
              registeredOn: d['gstin_registered_on']?.toString(),
              reverseCharge: d['gstin_reverse_charge'] == true,
              importExport: d['gstin_import_export'] == true,
              digitalServices: d['gstin_digital_services'] == true,
            );
          }
          if (defaultSeriesId != null && defaultSeriesId.isNotEmpty) _selectedDefaultSeriesId = defaultSeriesId;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp'], withData: true);
    if (result != null && result.files.isNotEmpty) setState(() => _logoPicked = result.files.first);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final nameCheck = await ref.read(apiClientProvider).get('outlets', queryParameters: {'org_id': orgId});
      if (nameCheck.success && nameCheck.data is List) {
        final trimmed = _nameCtrl.text.trim().toLowerCase();
        final duplicate = (nameCheck.data as List).any((o) {
          final isSelf = widget.branchId != null && o['id']?.toString() == widget.branchId;
          return !isSelf && (o['name'] ?? '').toString().toLowerCase() == trimmed;
        });
        if (duplicate) {
          setState(() => _isSaving = false);
          if (mounted) ZerpaiToast.error(context, 'A branch with this name already exists.');
          return;
        }
      }
      if (_logoPicked != null) {
        final url = await StorageService().uploadLocationLogo(_logoPicked!);
        if (url != null) _logoUrl = url;
      }
      final body = <String, dynamic>{
        'org_id': orgId,
        'location_type': 'business',
        'name': _nameCtrl.text.trim(),
        'outlet_code': _branchCodeCtrl.text.trim().isNotEmpty
            ? _branchCodeCtrl.text.trim().toUpperCase()
            : _nameCtrl.text.trim().toUpperCase().replaceAll(' ', '-'),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'attention': _attentionCtrl.text.trim(),
        'address': _streetCtrl.text.trim(),
        'address2': _street2Ctrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _selectedState ?? '',
        'pincode': _pincodeCtrl.text.trim(),
        'country': 'India',
        'is_primary': _isPrimary,
        'gstin': _gstinData?.gstin ?? '',
        if (_gstinData != null) ...{
          'gstin_registration_type': _gstinData!.registrationType,
          'gstin_legal_name': _gstinData!.legalName,
          'gstin_trade_name': _gstinData!.tradeName,
          'gstin_registered_on': _gstinData!.registeredOn,
          'gstin_reverse_charge': _gstinData!.reverseCharge,
          'gstin_import_export': _gstinData!.importExport,
          'gstin_digital_services': _gstinData!.digitalServices,
        },
        if (_logoOption == 'upload' && _logoUrl != null) 'logo_url': _logoUrl,
        if (_selectedDefaultSeriesId != null)
          'default_transaction_series_id': _selectedDefaultSeriesId,
      };
      final apiClient = ref.read(apiClientProvider);
      final res = _isEditing
          ? await apiClient.put('outlets/${widget.branchId}', data: body)
          : await apiClient.post('outlets', data: body);
      if (!mounted) return;
      if (res.success) {
        ZerpaiToast.success(context, _isEditing ? 'Branch updated successfully.' : 'Branch created successfully.');
        context.go(AppRoutes.settingsBranches);
      } else {
        ZerpaiToast.error(context, (res.message?.isNotEmpty == true) ? res.message! : 'Failed to save branch.');
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
                children: [_buildSidebar(), Expanded(child: _buildBody())],
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
      padding: const EdgeInsets.fromLTRB(AppTheme.space32, AppTheme.space20, AppTheme.space32, AppTheme.space16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppTheme.borderLight))),
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
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
                        child: const Icon(LucideIcons.chevronLeft, size: 20, color: AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: const Color(0xFFFFF3EE), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFED7C3))),
                            child: const Icon(LucideIcons.settings2, color: Color(0xFFF97316), size: 22),
                          ),
                          const SizedBox(width: AppTheme.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('All Settings', style: AppTheme.pageTitle),
                                const SizedBox(height: AppTheme.space4),
                                Text(_organizationName.isNotEmpty ? _organizationName : 'Your Organization',
                                    style: AppTheme.bodyText, overflow: TextOverflow.ellipsis),
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
                    width: 360, height: 42,
                    child: SettingsSearchField(
                      items: const <SettingsSearchItem>[],
                      focusNode: _searchFocusNode,
                      controller: _searchController,
                      onQueryChanged: (_) {},
                      onNoMatch: (q) => ZerpaiToast.info(context, 'No settings matched "$q"'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space24),
              TextButton.icon(
                onPressed: () => context.go(AppRoutes.settings),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary, backgroundColor: AppTheme.bgLight,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final String currentPath = GoRouterState.of(context).uri.path.replaceFirst(RegExp(r'^/\d{10,20}'), '');
    return Container(
      width: 240,
      decoration: const BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: AppTheme.borderLight))),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppTheme.space12, AppTheme.space20, AppTheme.space12, AppTheme.space24),
        children: [
          for (final section in _navSections) ...[
            Padding(
              padding: const EdgeInsets.only(left: AppTheme.space4, bottom: AppTheme.space8),
              child: Text(section.title.toUpperCase(),
                  style: AppTheme.captionText.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
            ),
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
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) _expandedBlocks.remove(block.title);
              else _expandedBlocks.add(block.title);
            }),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: AppTheme.space10),
              child: Row(
                children: [
                  Icon(isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: AppTheme.space8),
                  Expanded(child: Text(block.title, style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: AppTheme.space28, right: AppTheme.space8, bottom: AppTheme.space6),
              child: Column(children: block.items.map((e) => _buildSidebarEntry(e, currentPath)).toList()),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarEntry(_NavEntry entry, String currentPath) {
    final bool isActive = entry.route != null &&
        (entry.route == currentPath ||
            (entry.route == AppRoutes.settingsBranches &&
                (currentPath.startsWith('/settings/branches/create') ||
                    (currentPath.contains('/settings/branches/') && currentPath.contains('/edit')))));
    final Color accentColor = ref.watch(appBrandingProvider).accentColor;
    return InkWell(
      onTap: () {
        if (entry.route == null) { ZerpaiToast.info(context, '${entry.label} is not available yet'); return; }
        context.go(entry.route!);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppTheme.space4),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space10),
        decoration: BoxDecoration(color: isActive ? accentColor : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Text(entry.label,
            style: AppTheme.bodyText.copyWith(fontSize: 13, color: isActive ? Colors.white : AppTheme.textPrimary, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
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
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isEditing ? 'Edit Branch' : 'Add Branch',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: AppTheme.space24),
                _buildSectionLabel('Branch Details'),
                const SizedBox(height: AppTheme.space12),
                _buildCard(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: _buildTextField(label: 'Branch name', required: true, controller: _nameCtrl, hint: 'e.g. Head Office, Mumbai Branch',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Branch name is required' : null)),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(flex: 2, child: _buildTextField(label: 'Branch code', controller: _branchCodeCtrl, hint: 'e.g. MUM-01',
                        inputFormatters: [LengthLimitingTextInputFormatter(20)])),
                  ]),
                  const SizedBox(height: AppTheme.space12),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _buildTextField(label: 'Email', controller: _emailCtrl, hint: 'branch@example.com', keyboardType: TextInputType.emailAddress)),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(child: _buildTextField(label: 'Phone', controller: _phoneCtrl, hint: '+91 XXXXXXXXXX',
                        inputFormatters: [_IndiaPhoneFormatter()], keyboardType: TextInputType.phone)),
                  ]),
                  const SizedBox(height: AppTheme.space12),
                  _buildTextField(label: 'Website', controller: _websiteCtrl, hint: 'https://example.com', keyboardType: TextInputType.url),
                  const SizedBox(height: AppTheme.space12),
                  Row(children: [
                    SizedBox(width: 18, height: 18,
                        child: Checkbox(value: _isPrimary, onChanged: (v) => setState(() => _isPrimary = v ?? false),
                            activeColor: ref.watch(appBrandingProvider).accentColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)))),
                    const SizedBox(width: AppTheme.space8),
                    const Text('Set as primary branch', style: TextStyle(fontSize: 13, color: AppTheme.textBody)),
                  ]),
                ]),
                const SizedBox(height: AppTheme.space20),
                _buildSectionLabel('Address'),
                const SizedBox(height: AppTheme.space12),
                _buildCard(children: [
                  _buildTextField(label: 'Attention', controller: _attentionCtrl, hint: 'Attention'),
                  const SizedBox(height: AppTheme.space12),
                  _buildTextField(label: 'Street 1', controller: _streetCtrl, hint: 'Street 1'),
                  const SizedBox(height: AppTheme.space12),
                  _buildTextField(label: 'Street 2', controller: _street2Ctrl, hint: 'Street 2'),
                  const SizedBox(height: AppTheme.space12),
                  _buildTextField(label: 'City', controller: _cityCtrl, hint: 'City'),
                  const SizedBox(height: AppTheme.space12),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildLabel('State / Union Territory'),
                      const SizedBox(height: AppTheme.space6),
                      FormDropdown<String>(items: _indianStates, value: _selectedState, hint: 'Select state',
                          onChanged: (v) => setState(() => _selectedState = v)),
                    ])),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(child: _buildTextField(label: 'Pin Code', controller: _pincodeCtrl, hint: '560001',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)])),
                  ]),
                  const SizedBox(height: AppTheme.space12),
                  _buildLabel('Country'),
                  const SizedBox(height: AppTheme.space6),
                  _buildStaticDropdown('India'),
                ]),
                const SizedBox(height: AppTheme.space20),
                _buildSectionLabel('GST Details'),
                const SizedBox(height: AppTheme.space12),
                _buildCard(children: [_buildGstinField()]),
                const SizedBox(height: AppTheme.space20),
                _buildSectionLabel('Branch Logo'),
                const SizedBox(height: AppTheme.space12),
                _buildCard(children: [_buildLogoSection()]),
                if (_transactionSeries.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.space20),
                  _buildSectionLabel('Default Transaction Series'),
                  const SizedBox(height: AppTheme.space12),
                  _buildCard(children: [
                    _buildLabel('Default transaction series'),
                    const SizedBox(height: AppTheme.space6),
                    FormDropdown<String>(
                      items: _transactionSeries.map((s) => s.id).toList(),
                      value: _selectedDefaultSeriesId,
                      hint: 'Select default series',
                      displayStringForValue: (id) => _transactionSeries
                          .firstWhere((s) => s.id == id, orElse: () => _SeriesOption(id: id, name: id)).name,
                      onChanged: (v) => setState(() => _selectedDefaultSeriesId = v),
                    ),
                  ]),
                ],
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

  // ─── GSTIN field ───────────────────────────────────────────────────────────

  Widget _buildGstinField() {
    final hasGstin = _gstinData != null;
    if (!hasGstin) {
      return OutlinedButton.icon(
        onPressed: _showGstinDialog,
        icon: const Icon(LucideIcons.plus, size: 14),
        label: const Text('Add GSTIN'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          side: const BorderSide(color: AppTheme.borderLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      );
    }
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space8),
          decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.borderLight)),
          child: Text(_gstinData!.gstin,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, letterSpacing: 0.5)),
        ),
        const SizedBox(width: AppTheme.space12),
        if (_gstinData!.registrationType != null)
          Text(
            _kGstRegistrationTypes.firstWhere((t) => t['id'] == _gstinData!.registrationType, orElse: () => {'label': ''})['label'] ?? '',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        const Spacer(),
        TextButton(onPressed: _showGstinDialog, child: const Text('Edit')),
        TextButton(onPressed: () => setState(() => _gstinData = null),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed), child: const Text('Remove')),
      ],
    );
  }

  void _showGstinDialog() {
    final gstinCtrl = TextEditingController(text: _gstinData?.gstin ?? '');
    String? selectedRegType = _gstinData?.registrationType;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: 480,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GST Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: AppTheme.space20),
                  _buildLabel('GSTIN', required: true),
                  const SizedBox(height: AppTheme.space6),
                  TextFormField(
                    controller: gstinCtrl,
                    decoration: _inputDecoration('15-digit GSTIN'),
                    inputFormatters: [LengthLimitingTextInputFormatter(15), FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]'))],
                    onChanged: (v) { gstinCtrl.value = gstinCtrl.value.copyWith(text: v.toUpperCase(), selection: TextSelection.collapsed(offset: v.length)); },
                  ),
                  const SizedBox(height: AppTheme.space16),
                  _buildLabel('GST registration type'),
                  const SizedBox(height: AppTheme.space6),
                  FormDropdown<String>(
                    items: _kGstRegistrationTypes.map((t) => t['id']!).toList(),
                    value: selectedRegType,
                    hint: 'Select type',
                    displayStringForValue: (id) => _kGstRegistrationTypes.firstWhere((t) => t['id'] == id, orElse: () => {'label': id})['label']!,
                    onChanged: (v) => setS(() => selectedRegType = v),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      const SizedBox(width: AppTheme.space8),
                      ElevatedButton(
                        onPressed: () {
                          final gstin = gstinCtrl.text.trim().toUpperCase();
                          if (gstin.isEmpty) { Navigator.pop(ctx); return; }
                          setState(() {
                            _gstinData = _GstinData(
                              gstin: gstin, registrationType: selectedRegType,
                              legalName: _gstinData?.legalName ?? '', tradeName: _gstinData?.tradeName ?? '',
                              registeredOn: _gstinData?.registeredOn, reverseCharge: _gstinData?.reverseCharge ?? false,
                              importExport: _gstinData?.importExport ?? false, digitalServices: _gstinData?.digitalServices ?? false,
                            );
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ref.read(appBrandingProvider).accentColor, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('Save'),
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

  // ─── Logo section ──────────────────────────────────────────────────────────

  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormDropdown<String>(
          value: _logoOption,
          items: const ['same', 'upload'],
          displayStringForValue: (v) => v == 'same' ? 'Same as organization logo' : 'Upload a new logo',
          onChanged: (v) => setState(() => _logoOption = v ?? 'same'),
        ),
        if (_logoOption == 'upload') ...[
          const SizedBox(height: AppTheme.space12),
          if (_logoPicked != null)
            Row(children: [
              const Icon(LucideIcons.image, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: AppTheme.space8),
              Text(_logoPicked!.name, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
              const SizedBox(width: AppTheme.space8),
              InkWell(onTap: () => setState(() => _logoPicked = null), child: const Icon(LucideIcons.x, size: 14, color: AppTheme.errorRed)),
            ])
          else if (_logoUrl != null)
            Row(children: [
              const Icon(LucideIcons.image, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: AppTheme.space8),
              const Text('Logo uploaded', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(width: AppTheme.space8),
              TextButton(onPressed: _pickLogo, child: const Text('Change')),
            ])
          else
            OutlinedButton.icon(
              onPressed: _pickLogo,
              icon: const Icon(LucideIcons.upload, size: 14),
              label: const Text('Upload logo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.borderLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
        ],
      ],
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Widget _buildActions() {
    final accentColor = ref.watch(appBrandingProvider).accentColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isSaving ? null : () => context.go(AppRoutes.settingsBranches),
          style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: AppTheme.space12),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_isEditing ? 'Save Changes' : 'Add Branch',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ],
    );
  }

  // ─── Shared helpers ────────────────────────────────────────────────────────

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.3));
  }

  Widget _buildLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textBody),
        children: required ? const [TextSpan(text: ' *', style: TextStyle(color: AppTheme.errorRed))] : null,
      ),
    );
  }

  Widget _buildStaticDropdown(String value) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppTheme.borderLight)),
      child: Row(children: [
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textBody))),
        const Icon(LucideIcons.chevronDown, size: 14, color: AppTheme.textSecondary),
      ]),
    );
  }

  Widget _buildTextField({
    required String label,
    bool required = false,
    required TextEditingController controller,
    String hint = '',
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        const SizedBox(height: AppTheme.space6),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration(hint),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
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
