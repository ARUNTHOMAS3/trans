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
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
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

const List<Map<String, String>> _kBranchTypes = [
  {'id': 'fofo', 'code': 'FOFO', 'label': 'Franchise Owned Franchise Operated'},
  {'id': 'coco', 'code': 'COCO', 'label': 'Company Owned Company Operated'},
  {'id': 'fico', 'code': 'FICO', 'label': 'Franchise Invested Company Operated'},
  {'id': 'foco', 'code': 'FOCO', 'label': 'Franchise Owned Company Operated'},
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

// ─── India phone formatter ────────────────────────────────────────────────────

class _IndiaPhoneFormatter extends TextInputFormatter {
  static const String _prefix = '+91 ';
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text;
    if (!text.startsWith(_prefix)) {
      String digits = text.replaceAll(RegExp(r'\D'), '');
      if (digits.startsWith('91') && digits.length > 10) digits = digits.substring(2);
      if (digits.length > 10) digits = digits.substring(0, 10);
      final result = _prefix + digits;
      return TextEditingValue(text: result, selection: TextSelection.collapsed(offset: result.length));
    }
    String digits = text.substring(_prefix.length).replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);
    final result = _prefix + digits;
    return TextEditingValue(text: result, selection: TextSelection.collapsed(offset: result.length));
  }
}

String _normalizeIndiaPhone(String raw) {
  if (raw.isEmpty) return '+91 ';
  final digits = raw.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
  final stripped = digits.startsWith('91') && digits.length > 10 ? digits.substring(2) : digits;
  return '+91 ${stripped.length > 10 ? stripped.substring(0, 10) : stripped}';
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
    required this.gstin, this.registrationType, this.legalName = '',
    this.tradeName = '', this.registeredOn, this.reverseCharge = false,
    this.importExport = false, this.digitalServices = false,
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
  ConsumerState<SettingsBranchCreatePage> createState() => _SettingsBranchCreatePageState();
}

class _SettingsBranchCreatePageState extends ConsumerState<SettingsBranchCreatePage> {
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
  String? _selectedBranchType;
  DateTime? _subscriptionFrom;
  DateTime? _subscriptionTo;
  final GlobalKey _subFromKey = GlobalKey();
  final GlobalKey _subToKey = GlobalKey();
  // Location access — list of { userId, name, email, role }
  final List<Map<String, String>> _locationUsers = [];
  bool _provideAccessToAll = true;
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

  // Label column width for the two-column row layout
  static const double _labelWidth = 180.0;

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
          _transactionSeries = (res.data as List).cast<Map<String, dynamic>>()
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
        final branchType = d['branch_type']?.toString();
        final logoUrl = d['logo_url']?.toString();
        final gstinStr = (d['gstin'] ?? '').toString();
        final defaultSeriesId = d['default_transaction_series_id']?.toString();
        setState(() {
          _selectedState = _indianStates.contains(stateVal) ? stateVal : null;
          if (branchType != null && branchType.isNotEmpty &&
              _kBranchTypes.any((t) => t['id'] == branchType)) {
            _selectedBranchType = branchType;
          }
          if (logoUrl != null && logoUrl.isNotEmpty) { _logoUrl = logoUrl; _logoOption = 'upload'; }
          if (gstinStr.isNotEmpty) {
            _gstinData = _GstinData(
              gstin: gstinStr, registrationType: d['gstin_registration_type']?.toString(),
              legalName: (d['gstin_legal_name'] ?? '').toString(), tradeName: (d['gstin_trade_name'] ?? '').toString(),
              registeredOn: d['gstin_registered_on']?.toString(),
              reverseCharge: d['gstin_reverse_charge'] == true, importExport: d['gstin_import_export'] == true,
              digitalServices: d['gstin_digital_services'] == true,
            );
          }
          if (defaultSeriesId != null && defaultSeriesId.isNotEmpty) _selectedDefaultSeriesId = defaultSeriesId;
          final subFrom = d['subscription_from']?.toString();
          final subTo = d['subscription_to']?.toString();
          if (subFrom != null && subFrom.isNotEmpty) _subscriptionFrom = DateTime.tryParse(subFrom);
          if (subTo != null && subTo.isNotEmpty) _subscriptionTo = DateTime.tryParse(subTo);
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
        'org_id': orgId, 'location_type': 'business',
        'name': _nameCtrl.text.trim(),
        'outlet_code': _branchCodeCtrl.text.trim().isNotEmpty
            ? _branchCodeCtrl.text.trim().toUpperCase()
            : _nameCtrl.text.trim().toUpperCase().replaceAll(' ', '-'),
        'email': _emailCtrl.text.trim(), 'phone': _phoneCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(), 'attention': _attentionCtrl.text.trim(),
        'address': _streetCtrl.text.trim(), 'address2': _street2Ctrl.text.trim(),
        'city': _cityCtrl.text.trim(), 'state': _selectedState ?? '',
        'pincode': _pincodeCtrl.text.trim(), 'country': 'India',
        if (_selectedBranchType != null) 'branch_type': _selectedBranchType,
        if (_subscriptionFrom != null) 'subscription_from': _subscriptionFrom!.toIso8601String().substring(0, 10),
        if (_subscriptionTo != null) 'subscription_to': _subscriptionTo!.toIso8601String().substring(0, 10),
        'gstin': _gstinData?.gstin ?? '',
        if (_gstinData != null) ...{
          'gstin_registration_type': _gstinData!.registrationType,
          'gstin_legal_name': _gstinData!.legalName, 'gstin_trade_name': _gstinData!.tradeName,
          'gstin_registered_on': _gstinData!.registeredOn,
          'gstin_reverse_charge': _gstinData!.reverseCharge, 'gstin_import_export': _gstinData!.importExport,
          'gstin_digital_services': _gstinData!.digitalServices,
        },
        if (_logoOption == 'upload' && _logoUrl != null) 'logo_url': _logoUrl,
        if (_selectedDefaultSeriesId != null) 'default_transaction_series_id': _selectedDefaultSeriesId,
        'location_users': _locationUsers
            .map((u) => {'user_id': u['userId'], 'role': u['role']})
            .toList(),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isEditing ? 'Edit Branch' : 'Add Branch',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: AppTheme.space24),

                // ── Branch Details ─────────────────────────────────────────
                _buildSectionLabel('Branch Details'),
                const SizedBox(height: AppTheme.space12),
                _buildCard(children: [
                  _buildRow(label: 'Branch name', required: true,
                      child: TextFormField(controller: _nameCtrl, decoration: _dec('e.g. Head Office, Mumbai Branch'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Branch name is required' : null)),
                  _buildDivider(),
                  _buildRow(label: 'Branch code',
                      child: TextFormField(controller: _branchCodeCtrl, decoration: _dec('e.g. MUM-01'),
                          inputFormatters: [LengthLimitingTextInputFormatter(20)])),
                  _buildDivider(),
                  _buildRow(label: 'Email',
                      child: TextFormField(controller: _emailCtrl, decoration: _dec('branch@example.com'), keyboardType: TextInputType.emailAddress)),
                  _buildDivider(),
                  _buildRow(label: 'Phone',
                      child: TextFormField(controller: _phoneCtrl, decoration: _dec('+91 XXXXXXXXXX'),
                          inputFormatters: [_IndiaPhoneFormatter()], keyboardType: TextInputType.phone)),
                  _buildDivider(),
                  _buildRow(label: 'Website',
                      child: TextFormField(controller: _websiteCtrl, decoration: _dec('https://example.com'), keyboardType: TextInputType.url)),
                ]),

                const SizedBox(height: AppTheme.space20),

                // ── Branch Type ────────────────────────────────────────────
                _buildSectionLabel('Branch Type'),
                const SizedBox(height: AppTheme.space12),
                _buildCard(children: [
                  _buildRow(label: 'Branch type',
                      child: FormDropdown<String>(
                        items: [..._kBranchTypes.map((t) => t['id']!), '__manage__'],
                        value: _selectedBranchType,
                        hint: 'Select branch type',
                        displayStringForValue: (id) {
                          if (id == '__manage__') return 'Manage Branch Types';
                          final match = _kBranchTypes.firstWhere((t) => t['id'] == id, orElse: () => {'code': id.toUpperCase(), 'label': ''});
                          return '${match['code']} — ${match['label']}';
                        },
                        onChanged: (v) {
                          if (v == '__manage__') { _showManageBranchTypesDialog(); return; }
                          setState(() => _selectedBranchType = v);
                        },
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

                const SizedBox(height: AppTheme.space20),

                // ── GST Details ────────────────────────────────────────────
                _buildSectionLabel('GST Details'),
                const SizedBox(height: AppTheme.space12),
                _buildCard(children: [_buildGstinField()]),

                const SizedBox(height: AppTheme.space20),

                // ── Branch Logo ────────────────────────────────────────────
                _buildSectionLabel('Branch Logo'),
                const SizedBox(height: AppTheme.space12),
                _buildCard(children: [
                  _buildRow(label: 'Logo',
                      child: FormDropdown<String>(
                        value: _logoOption, items: const ['same', 'upload'],
                        displayStringForValue: (v) => v == 'same' ? 'Same as organization logo' : 'Upload a new logo',
                        onChanged: (v) => setState(() => _logoOption = v ?? 'same'),
                      )),
                  if (_logoOption == 'upload') ...[
                    _buildDivider(),
                    _buildRow(label: 'Upload', child: _buildLogoUpload()),
                  ],
                ]),

                const SizedBox(height: AppTheme.space20),

                // ── Subscription ───────────────────────────────────────────
                _buildSectionLabel('Subscription'),
                const SizedBox(height: AppTheme.space12),
                _buildCard(children: [
                  _buildRow(
                    label: 'From date',
                    child: GestureDetector(
                      key: _subFromKey,
                      onTap: () async {
                        final picked = await ZerpaiDatePicker.show(
                          context,
                          initialDate: _subscriptionFrom ?? DateTime.now(),
                          targetKey: _subFromKey,
                        );
                        if (picked != null) setState(() => _subscriptionFrom = picked);
                      },
                      child: _buildDateField(_subscriptionFrom, 'Select start date'),
                    ),
                  ),
                  _buildDivider(),
                  _buildRow(
                    label: 'To date',
                    child: GestureDetector(
                      key: _subToKey,
                      onTap: () async {
                        final picked = await ZerpaiDatePicker.show(
                          context,
                          initialDate: _subscriptionTo ?? DateTime.now(),
                          firstDate: _subscriptionFrom,
                          targetKey: _subToKey,
                        );
                        if (picked != null) setState(() => _subscriptionTo = picked);
                      },
                      child: _buildDateField(_subscriptionTo, 'Select end date'),
                    ),
                  ),
                ]),

                if (_transactionSeries.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.space20),
                  _buildSectionLabel('Default Transaction Series'),
                  const SizedBox(height: AppTheme.space12),
                  _buildCard(children: [
                    _buildRow(label: 'Default series',
                        child: FormDropdown<String>(
                          items: _transactionSeries.map((s) => s.id).toList(),
                          value: _selectedDefaultSeriesId,
                          hint: 'Select default series',
                          displayStringForValue: (id) => _transactionSeries
                              .firstWhere((s) => s.id == id, orElse: () => _SeriesOption(id: id, name: id)).name,
                          onChanged: (v) => setState(() => _selectedDefaultSeriesId = v),
                        )),
                  ]),
                ],

                const SizedBox(height: AppTheme.space20),

                // ── Location Access ────────────────────────────────────────
                _buildLocationAccessSection(),

                const SizedBox(height: AppTheme.space32),
                _buildActions(),
                const SizedBox(height: AppTheme.space48),
              ],
            ),
          ),
        ),
    );
  }

  // ─── GSTIN ─────────────────────────────────────────────────────────────────

  Widget _buildGstinField() {
    final hasGstin = _gstinData != null;
    if (!hasGstin) {
      return _buildRow(label: 'GSTIN',
          child: OutlinedButton.icon(
            onPressed: _showGstinDialog,
            icon: const Icon(LucideIcons.plus, size: 14),
            label: const Text('Add GSTIN'),
            style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary, side: const BorderSide(color: AppTheme.borderLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
          ));
    }
    return _buildRow(label: 'GSTIN', child: Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space8),
        decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.borderLight)),
        child: Text(_gstinData!.gstin, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary, letterSpacing: 0.5)),
      ),
      if (_gstinData!.registrationType != null) ...[
        const SizedBox(width: AppTheme.space12),
        Expanded(child: Text(
          _kGstRegistrationTypes.firstWhere((t) => t['id'] == _gstinData!.registrationType, orElse: () => {'label': ''})['label'] ?? '',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
      ] else const Spacer(),
      TextButton(onPressed: _showGstinDialog, child: const Text('Edit')),
      TextButton(onPressed: () => setState(() => _gstinData = null),
          style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed), child: const Text('Remove')),
    ]));
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
          child: SizedBox(width: 480,
            child: Padding(padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('GST Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: AppTheme.space20),
                _buildRow(label: 'GSTIN', required: true,
                    child: TextFormField(controller: gstinCtrl, decoration: _dec('15-digit GSTIN'),
                        inputFormatters: [LengthLimitingTextInputFormatter(15), FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]'))],
                        onChanged: (v) { gstinCtrl.value = gstinCtrl.value.copyWith(text: v.toUpperCase(), selection: TextSelection.collapsed(offset: v.length)); })),
                _buildDivider(),
                _buildRow(label: 'Registration type',
                    child: FormDropdown<String>(
                      items: _kGstRegistrationTypes.map((t) => t['id']!).toList(),
                      value: selectedRegType, hint: 'Select type',
                      displayStringForValue: (id) => _kGstRegistrationTypes.firstWhere((t) => t['id'] == id, orElse: () => {'label': id})['label']!,
                      onChanged: (v) => setS(() => selectedRegType = v),
                    )),
                const SizedBox(height: AppTheme.space24),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
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
                    style: ElevatedButton.styleFrom(backgroundColor: ref.read(appBrandingProvider).accentColor,
                        foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                    child: const Text('Save'),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Location access ───────────────────────────────────────────────────────

  Widget _buildLocationAccessSection() {
    final accentColor = ref.watch(appBrandingProvider).accentColor;
    final int count = _locationUsers.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildSectionLabel('Location Access')),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Checkbox(
                    value: _provideAccessToAll,
                    onChanged: (v) => setState(() => _provideAccessToAll = v ?? true),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Provide access to all users',
                    style: TextStyle(fontSize: 12, color: AppTheme.textBody)),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space12),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight)),
          child: _provideAccessToAll
              ? Padding(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Row(children: [
                    const Icon(LucideIcons.users, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: AppTheme.space8),
                    const Expanded(
                      child: Text(
                        'All users in your organization have access to this branch.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                  ]),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status header
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      child: Row(children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: count > 0 ? accentColor : AppTheme.textSecondary),
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              count > 0 ? '$count user${count == 1 ? '' : 's'} selected' : 'No users selected',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: count > 0 ? accentColor : AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              count > 0
                                  ? 'Selected users can create and access transactions for this branch.'
                                  : 'Select the users who can create and access transactions for this branch.',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                    // Column headers
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space16, vertical: AppTheme.space10),
                      decoration: const BoxDecoration(
                          border: Border(
                              top: BorderSide(color: AppTheme.borderLight),
                              bottom: BorderSide(color: AppTheme.borderLight))),
                      child: const Row(children: [
                        Expanded(flex: 3, child: Text('USERS',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary, letterSpacing: 0.5))),
                        Expanded(child: Text('ROLE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary, letterSpacing: 0.5))),
                      ]),
                    ),
                    // User rows
                    for (final user in _locationUsers)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space16, vertical: AppTheme.space12),
                        decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppTheme.borderLight))),
                        child: Row(children: [
                          Expanded(
                            flex: 3,
                            child: Row(children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.bgLight,
                                child: Text(
                                  (user['name'] ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 11,
                                      fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                ),
                              ),
                              const SizedBox(width: AppTheme.space10),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(user['name'] ?? '',
                                      style: const TextStyle(fontSize: 13,
                                          fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                                  Text(user['email'] ?? '',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                ]),
                              ),
                            ]),
                          ),
                          Expanded(
                            child: Text(user['role'] ?? '',
                                style: const TextStyle(fontSize: 13, color: AppTheme.textBody)),
                          ),
                          IconButton(
                            onPressed: () => setState(() =>
                                _locationUsers.removeWhere((u) => u['userId'] == user['userId'])),
                            icon: const Icon(LucideIcons.x, size: 14),
                            color: AppTheme.textSecondary,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ]),
                      ),
                    // Add user button
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.space12),
                      child: OutlinedButton.icon(
                        onPressed: () => ZerpaiToast.info(context, 'User assignment coming soon'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space16, vertical: AppTheme.space10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          side: const BorderSide(color: AppTheme.borderLight),
                        ),
                        icon: const Icon(LucideIcons.userPlus, size: 14),
                        label: const Text('Add User',
                            style: TextStyle(fontSize: 13, color: AppTheme.textBody)),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ─── Manage branch types dialog ────────────────────────────────────────────

  void _showManageBranchTypesDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 560,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Branch Types',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: AppTheme.space4),
                const Text('Reference guide for branch ownership and operation models.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: AppTheme.space20),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderLight),
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space10),
                        decoration: const BoxDecoration(
                            color: AppTheme.bgLight,
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))),
                        child: const Row(children: [
                          SizedBox(width: 64, child: Text('Model', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
                          SizedBox(width: AppTheme.space16),
                          Expanded(child: Text('Full Form', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
                        ]),
                      ),
                      for (int i = 0; i < _kBranchTypes.length; i++) ...[
                        const Divider(height: 1, color: AppTheme.borderLight),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
                          child: Row(children: [
                            SizedBox(
                              width: 64,
                              child: Text(_kBranchTypes[i]['code']!,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                            ),
                            const SizedBox(width: AppTheme.space16),
                            Expanded(
                              child: Text(_kBranchTypes[i]['label']!,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textBody)),
                            ),
                          ]),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Logo upload ───────────────────────────────────────────────────────────

  Widget _buildLogoUpload() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderLight)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload zone / preview
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: _pickLogo,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 96,
                decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderLight)),
                child: _logoPicked != null
                    ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(LucideIcons.image, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: AppTheme.space8),
                        Expanded(
                          child: Text(_logoPicked!.name,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 14, color: AppTheme.errorRed),
                          onPressed: () => setState(() => _logoPicked = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: AppTheme.space8),
                      ])
                    : _logoUrl != null
                        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(LucideIcons.image, size: 20, color: AppTheme.textSecondary),
                            const SizedBox(height: AppTheme.space8),
                            const Text('Logo uploaded', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: AppTheme.space4),
                            Text('Tap to change', style: TextStyle(fontSize: 11, color: ref.watch(appBrandingProvider).accentColor)),
                          ])
                        : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(LucideIcons.upload, size: 20, color: AppTheme.textSecondary),
                            SizedBox(height: AppTheme.space8),
                            Text('Upload your Location Logo',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ]),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          // Info panel
          const Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This logo will be displayed in transaction PDFs and email notifications.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textBody)),
                SizedBox(height: AppTheme.space8),
                Text('Dimensions: 240 × 240 pixels @ 72 DPI',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                SizedBox(height: AppTheme.space4),
                Text('Supported files: jpg, jpeg, png, gif, bmp',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                SizedBox(height: AppTheme.space4),
                Text('Maximum file size: 1MB',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Widget _buildActions() {
    final accentColor = ref.watch(appBrandingProvider).accentColor;
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      TextButton(onPressed: _isSaving ? null : () => context.go(AppRoutes.settingsBranches),
          style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary), child: const Text('Cancel')),
      const SizedBox(width: AppTheme.space12),
      ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: _isSaving
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(_isEditing ? 'Save Changes' : 'Add Branch',
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

  Widget _buildDateField(DateTime? date, String placeholder) {
    final label = date == null
        ? placeholder
        : '${date.day.toString().padLeft(2, '0')} ${_monthNames[date.month - 1]} ${date.year}';
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.borderLight)),
      child: Row(children: [
        Expanded(child: Text(label,
            style: TextStyle(fontSize: 13, color: date == null ? AppTheme.textSecondary : AppTheme.textBody))),
        const Icon(LucideIcons.calendar, size: 14, color: AppTheme.textSecondary),
      ]),
    );
  }

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

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
