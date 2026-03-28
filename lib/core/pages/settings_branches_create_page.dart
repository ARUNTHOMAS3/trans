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
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/form_row.dart';
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

const List<Map<String, String>> _kInitialBusinessTypes = [
  {'id': 'fofo', 'code': 'FOFO', 'label': 'Franchise Owned Franchise Operated'},
  {'id': 'coco', 'code': 'COCO', 'label': 'Company Owned Company Operated'},
  {'id': 'fico', 'code': 'FICO', 'label': 'Franchise Invested Company Operated'},
  {'id': 'foco', 'code': 'FOCO', 'label': 'Franchise Owned Company Operated'},
];

const List<Map<String, String>> _kSeriesModules = [
  {'id': 'invoice',          'label': 'Invoice'},
  {'id': 'credit_note',      'label': 'Credit Note'},
  {'id': 'sales_order',      'label': 'Sales Order'},
  {'id': 'purchase_order',   'label': 'Purchase Order'},
  {'id': 'customer_payment', 'label': 'Customer Payment'},
  {'id': 'vendor_payment',   'label': 'Vendor Payment'},
  {'id': 'delivery_challan', 'label': 'Delivery Challan'},
  {'id': 'bill_of_supply',   'label': 'Bill of Supply'},
  {'id': 'retainer_invoice', 'label': 'Retainer Invoice'},
  {'id': 'self_invoice',     'label': 'Self-Invoice'},
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

const double _kWideBranchSectionWidth = 730.0;

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

// ─── Data classes ─────────────────────────────────────────────────────────────

class _GstinData {
  final String gstin;
  final String? registrationType;
  final String legalName;
  final String tradeName;
  final String? registeredOn;
  final bool reverseCharge;
  final bool importExport;
  final String? importExportAccountId;
  final bool digitalServices;
  const _GstinData({
    required this.gstin, this.registrationType, this.legalName = '',
    this.tradeName = '', this.registeredOn, this.reverseCharge = false,
    this.importExport = false, this.importExportAccountId,
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
  ConsumerState<SettingsBranchCreatePage> createState() => _SettingsBranchCreatePageState();
}

class _SettingsBranchCreatePageState extends ConsumerState<SettingsBranchCreatePage> {
  final ApiClient _apiClient = ApiClient();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // ── Text controllers ──────────────────────────────────────────────────────
  final TextEditingController _nameCtrl      = TextEditingController();
  final TextEditingController _branchCodeCtrl = TextEditingController();
  final TextEditingController _emailCtrl     = TextEditingController();
  final TextEditingController _phoneCtrl     = TextEditingController();
  final TextEditingController _websiteCtrl   = TextEditingController();
  final TextEditingController _attentionCtrl = TextEditingController();
  final TextEditingController _streetCtrl    = TextEditingController();
  final TextEditingController _street2Ctrl   = TextEditingController();
  final TextEditingController _cityCtrl      = TextEditingController();
  final TextEditingController _pincodeCtrl   = TextEditingController();
  final TextEditingController _faxCtrl       = TextEditingController();

  // ── Dropdown state ────────────────────────────────────────────────────────
  String? _selectedState;
  String? _selectedBusinessType;
  late final List<Map<String, String>> _businessTypes;
  String _orgCountry = 'India';
  List<String> _stateOptions = _indianStates;

  // ── Child location ────────────────────────────────────────────────────────
  bool _isChildLocation = false;
  String? _parentBranchId;
  List<Map<String, dynamic>> _availableBranches = [];

  // ── Subscription ──────────────────────────────────────────────────────────
  DateTime? _subscriptionFrom;
  DateTime? _subscriptionTo;
  final GlobalKey _subFromKey = GlobalKey();
  final GlobalKey _subToKey   = GlobalKey();

  // ── Location access ───────────────────────────────────────────────────────
  final List<Map<String, String>> _locationUsers = [];
  bool _provideAccessToAll = true;

  // ── Logo ──────────────────────────────────────────────────────────────────
  String _logoOption = 'same';
  PlatformFile? _logoPicked;
  String? _logoUrl;

  // ── GST ───────────────────────────────────────────────────────────────────
  _GstinData? _gstinData;
  List<String> _orgGstins = [];

  // ── Primary contact ───────────────────────────────────────────────────────
  String? _primaryContactId;
  List<Map<String, dynamic>> _orgUsers = [];

  // ── Transaction series ────────────────────────────────────────────────────
  List<_SeriesOption> _transactionSeries = [];
  final List<String> _selectedTransactionSeriesIds = [];
  String? _selectedDefaultSeriesId;

  // ── Misc ──────────────────────────────────────────────────────────────────
  bool _isSaving  = false;
  bool _isLoading = false;
  String _organizationName = '';
  final Set<String> _expandedBlocks = <String>{'Organization'};

  bool get _isEditing => widget.branchId != null;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _businessTypes = _kInitialBusinessTypes
        .map((type) => Map<String, String>.from(type))
        .toList();
    _phoneCtrl.text = '+91 ';
    _loadOrgName();
    _loadTransactionSeries();
    _loadOrgBranchData();
    _loadOrgUsers();
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
    _faxCtrl.dispose();
    super.dispose();
  }

  // ─── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadOrgName() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final res = await _apiClient.get('lookups/org/$orgId');
      if (!mounted) return;

      String orgCountry = 'India';
      List<String> stateOptions = _indianStates;
      String orgName = user?.orgName ?? '';

      if (res.success && res.data is Map<String, dynamic>) {
        final orgData = res.data as Map<String, dynamic>;
        orgName = ((orgData['name'] ?? user?.orgName ?? '')).toString().trim();
        final countryName = (orgData['country'] ?? '').toString().trim();
        orgCountry = countryName.isNotEmpty ? countryName : 'India';

        final isIndia = orgCountry.toLowerCase() == 'india';
        if (!isIndia && countryName.isNotEmpty) {
          final countriesRes = await _apiClient.get('lookups/countries');
          if (countriesRes.success && countriesRes.data is List) {
            final match = (countriesRes.data as List)
                .whereType<Map<String, dynamic>>()
                .firstWhere(
                  (c) => (c['name'] ?? '').toString().toLowerCase() == orgCountry.toLowerCase(),
                  orElse: () => <String, dynamic>{},
                );
            final countryId = (match['id'] ?? '').toString();
            if (countryId.isNotEmpty) {
              final statesRes = await _apiClient.get('lookups/states', queryParameters: {'countryId': countryId});
              if (statesRes.success && statesRes.data is List) {
                stateOptions = (statesRes.data as List)
                    .whereType<Map<String, dynamic>>()
                    .map((s) => (s['name'] ?? '').toString())
                    .where((n) => n.isNotEmpty)
                    .toList();
              }
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _organizationName = orgName;
        _orgCountry = orgCountry;
        _stateOptions = stateOptions.isNotEmpty ? stateOptions : _indianStates;
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

  /// Loads branches for parent-branch selector and collects org-level GSTINs.
  Future<void> _loadOrgBranchData() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final res = await _apiClient.get('branches', queryParameters: {'org_id': orgId});
      if (!mounted) return;
      if (res.success && res.data is List) {
        final all = (res.data as List).cast<Map<String, dynamic>>();
        final gstins = all
            .map((b) => (b['gstin'] ?? '').toString().trim())
            .where((g) => g.isNotEmpty)
            .toSet()
            .toList();
        setState(() {
          _availableBranches = all
              .where((b) => b['id']?.toString() != widget.branchId)
              .toList();
          _orgGstins = gstins;
        });
      }
    } catch (_) {}
  }

  /// Loads org users for the Primary Contact selector.
  Future<void> _loadOrgUsers() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final res = await _apiClient.get('users', queryParameters: {'org_id': orgId});
      if (!mounted) return;
      if (res.success && res.data is List) {
        setState(() => _orgUsers = (res.data as List).cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final res = await _apiClient.get('branches/${widget.branchId}', queryParameters: {'org_id': orgId});
      if (!mounted) return;
      if (res.success && res.data is Map<String, dynamic>) {
        final d = res.data as Map<String, dynamic>;
        _nameCtrl.text        = (d['name'] ?? '').toString();
        _branchCodeCtrl.text  = (d['branch_code'] ?? '').toString();
        _emailCtrl.text       = (d['email'] ?? '').toString();
        _phoneCtrl.text       = _normalizeIndiaPhone((d['phone'] ?? '').toString());
        _websiteCtrl.text     = (d['website'] ?? '').toString();
        _attentionCtrl.text   = (d['attention'] ?? '').toString();
        _streetCtrl.text      = (d['address_street_1'] ?? '').toString();
        _street2Ctrl.text     = (d['address_street_2'] ?? '').toString();
        _cityCtrl.text        = (d['city'] ?? '').toString();
        _pincodeCtrl.text     = (d['pincode'] ?? '').toString();
        _faxCtrl.text         = (d['fax'] ?? '').toString();

        final stateVal        = (d['state'] ?? '').toString();
        final businessType    = d['branch_type']?.toString();
        final logoUrl         = d['logo_url']?.toString();
        final gstinStr        = (d['gstin'] ?? '').toString();
        final defaultSeriesId = d['default_transaction_series_id']?.toString();
        final txSeriesIds     = d['transaction_series_ids'] is List
            ? (d['transaction_series_ids'] as List)
                .map((id) => id?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toList()
            : <String>[];
        final txSeriesId      = d['transaction_series_id']?.toString();
        final primaryContact  = d['primary_contact_id']?.toString();
        final parentBranchId  = d['parent_branch_id']?.toString();
        final locationUsers   = d['location_users'] is List
            ? (d['location_users'] as List)
                .whereType<Map<String, dynamic>>()
                .map((user) {
                  final userId = (user['user_id'] ?? '').toString();
                  final orgUser = _orgUsers.cast<Map<String, dynamic>>().firstWhere(
                    (u) => u['id']?.toString() == userId,
                    orElse: () => <String, dynamic>{},
                  );
                  return <String, String>{
                    'userId': userId,
                    'name': (orgUser['name'] ?? orgUser['full_name'] ?? '')
                        .toString(),
                    'email': (orgUser['email'] ?? '').toString(),
                    'role': (user['role'] ?? '').toString(),
                  };
                })
                .where((user) => (user['userId'] ?? '').isNotEmpty)
                .toList()
            : <Map<String, String>>[];
        final restoredSeriesIds = <String>{
          ...txSeriesIds,
          if (txSeriesId != null && txSeriesId.isNotEmpty) txSeriesId,
        }.toList();

        setState(() {
          _selectedState = _stateOptions.contains(stateVal) ? stateVal : null;
          if (businessType != null && businessType.isNotEmpty &&
              _businessTypes.any((t) => t['id'] == businessType)) {
            _selectedBusinessType = businessType;
          }
          if (logoUrl != null && logoUrl.isNotEmpty) { _logoUrl = logoUrl; _logoOption = 'upload'; }
          if (gstinStr.isNotEmpty) {
            _gstinData = _GstinData(
              gstin: gstinStr,
              registrationType: d['gstin_registration_type']?.toString(),
              legalName:  (d['gstin_legal_name'] ?? '').toString(),
              tradeName:  (d['gstin_trade_name'] ?? '').toString(),
              registeredOn: d['gstin_registered_on']?.toString(),
              reverseCharge:    d['gstin_reverse_charge'] == true,
              importExport:     d['gstin_import_export'] == true,
              importExportAccountId: d['gstin_import_export_account_id']?.toString(),
              digitalServices:  d['gstin_digital_services'] == true,
            );
          }
          if (defaultSeriesId != null && defaultSeriesId.isNotEmpty) _selectedDefaultSeriesId = defaultSeriesId;
          _selectedTransactionSeriesIds
            ..clear()
            ..addAll(restoredSeriesIds);
          _locationUsers
            ..clear()
            ..addAll(locationUsers);
          _provideAccessToAll = locationUsers.isEmpty;
          if (primaryContact != null && primaryContact.isNotEmpty) _primaryContactId = primaryContact;
          if (parentBranchId != null && parentBranchId.isNotEmpty) {
            _parentBranchId = parentBranchId;
            _isChildLocation = true;
          }
          final subFrom = d['subscription_from']?.toString();
          final subTo   = d['subscription_to']?.toString();
          if (subFrom != null && subFrom.isNotEmpty) _subscriptionFrom = DateTime.tryParse(subFrom);
          if (subTo   != null && subTo.isNotEmpty)   _subscriptionTo   = DateTime.tryParse(subTo);
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

  // ─── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final user  = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;

      // Duplicate name check
      final nameCheck = await ref.read(apiClientProvider).get('branches', queryParameters: {'org_id': orgId});
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
        'org_id':       orgId,
        'name':         _nameCtrl.text.trim(),
        'branch_code':  _branchCodeCtrl.text.trim().isNotEmpty
            ? _branchCodeCtrl.text.trim().toUpperCase()
            : _nameCtrl.text.trim().toUpperCase().replaceAll(' ', '-'),
        'email':        _emailCtrl.text.trim(),
        'phone':        _phoneCtrl.text.trim(),
        'fax':          _faxCtrl.text.trim(),
        'website':      _websiteCtrl.text.trim(),
        'attention':    _attentionCtrl.text.trim(),
        'address_street_1': _streetCtrl.text.trim(),
        'address_street_2': _street2Ctrl.text.trim(),
        'city':         _cityCtrl.text.trim(),
        'state':        _selectedState ?? '',
        'pincode':      _pincodeCtrl.text.trim(),
        'country':      _orgCountry,
        'is_child_location': _isChildLocation,
        if (_isChildLocation && _parentBranchId != null) 'parent_branch_id': _parentBranchId,
        if (_selectedBusinessType != null) 'branch_type': _selectedBusinessType,
        if (_primaryContactId != null) 'primary_contact_id': _primaryContactId,
        if (_subscriptionFrom != null) 'subscription_from': _subscriptionFrom!.toIso8601String().substring(0, 10),
        if (_subscriptionTo   != null) 'subscription_to':   _subscriptionTo!.toIso8601String().substring(0, 10),
        'gstin': _gstinData?.gstin ?? '',
        if (_gstinData != null) ...{
          'gstin_registration_type': _gstinData!.registrationType,
          'gstin_legal_name':    _gstinData!.legalName,
          'gstin_trade_name':    _gstinData!.tradeName,
          'gstin_registered_on': _gstinData!.registeredOn,
          'gstin_reverse_charge':   _gstinData!.reverseCharge,
          'gstin_import_export':    _gstinData!.importExport,
          if (_gstinData!.importExportAccountId != null)
            'gstin_import_export_account_id': _gstinData!.importExportAccountId,
          'gstin_digital_services': _gstinData!.digitalServices,
        },
        if (_logoOption == 'upload' && _logoUrl != null) 'logo_url': _logoUrl,
        if (_selectedTransactionSeriesIds.isNotEmpty) 'transaction_series_ids': _selectedTransactionSeriesIds,
        if (_selectedDefaultSeriesId    != null) 'default_transaction_series_id': _selectedDefaultSeriesId,
        'location_users': _locationUsers
            .map((u) => {'user_id': u['userId'], 'role': u['role']})
            .toList(),
      };

      final apiClient = ref.read(apiClientProvider);
      final res = _isEditing
          ? await apiClient.put('branches/${widget.branchId}', data: body)
          : await apiClient.post('branches', data: body);
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
        color: Colors.white,
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space32),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 620,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Text(_isEditing ? 'Edit Branch' : 'Add Branch',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: AppTheme.space24),

                // ── Main form ──────────────────────────────────────────────
                Container(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Logo ──────────────────────────────────────────────
                      ZerpaiFormRow(label: 'Logo', child: FormDropdown<String>(
                        value: _logoOption,
                        items: const ['same', 'upload'],
                        displayStringForValue: (v) =>
                            v == 'same' ? 'Same as organization logo' : 'Upload a new logo',
                        onChanged: (v) => setState(() => _logoOption = v ?? 'same'),
                      )),
                      if (_logoOption == 'upload') ...[
                        ZerpaiFormRow(label: '', crossAxisAlignment: CrossAxisAlignment.start, child: _buildLogoUpload()),
                      ],


                      // ── Branch name ───────────────────────────────────────
                      ZerpaiFormRow(
                        label: 'Branch name',
                        required: true,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: _dec('e.g. Head Office, Mumbai Branch'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Branch name is required' : null,
                            ),
                            const SizedBox(height: AppTheme.space10),
                            GestureDetector(
                              onTap: () => setState(() {
                                _isChildLocation = !_isChildLocation;
                                if (!_isChildLocation) _parentBranchId = null;
                              }),
                              child: Row(children: [
                                SizedBox(
                                  width: 16, height: 16,
                                  child: Checkbox(
                                    value: _isChildLocation,
                                    onChanged: (v) => setState(() {
                                      _isChildLocation = v ?? false;
                                      if (!_isChildLocation) _parentBranchId = null;
                                    }),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.space8),
                                const Text('This is a child branch',
                                    style: TextStyle(fontSize: 13, color: AppTheme.textBody)),
                              ]),
                            ),
                          ],
                        ),
                      ),

                      // ── Parent branch (conditional) ────────────────────────
                      if (_isChildLocation) ...[
                        ZerpaiFormRow(
                          label: 'Parent branch',
                          required: true,
                          child: FormDropdown<String>(
                            value: _parentBranchId,
                            hint: 'Select parent branch',
                            items: _availableBranches.map((b) => b['id'].toString()).toList(),
                            displayStringForValue: (id) {
                              final match = _availableBranches.firstWhere(
                                (b) => b['id'].toString() == id,
                                orElse: () => {'name': id},
                              );
                              return (match['name'] ?? id).toString();
                            },
                            onChanged: (v) => setState(() => _parentBranchId = v),
                          ),
                        ),
                      ],


                      // ── Branch code ───────────────────────────────────────
                      ZerpaiFormRow(
                        label: 'Branch code',
                        child: TextFormField(
                          controller: _branchCodeCtrl,
                          decoration: _dec('e.g. MUM-01'),
                          inputFormatters: [LengthLimitingTextInputFormatter(20)],
                        ),
                      ),


                      // ── Email ─────────────────────────────────────────────
                      ZerpaiFormRow(
                        label: 'Email',
                        child: TextFormField(
                          controller: _emailCtrl,
                          decoration: _dec('branch@example.com'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),


                      // ── Business type ──────────────────────────────────────
                      ZerpaiFormRow(
                        label: 'Business type',
                        child: FormDropdown<String>(
                          items: _businessTypes.map((t) => t['id']!).toList(),
                          value: _selectedBusinessType,
                          hint: 'Select business type',
                          showSettings: true,
                          settingsLabel: 'Manage Business Types',
                          settingsIcon: Icons.settings_outlined,
                          onSettingsTap: _showManageBusinessTypesDialog,
                          displayStringForValue: (id) {
                            final match = _businessTypes.firstWhere(
                              (t) => t['id'] == id,
                              orElse: () => {'code': id.toUpperCase(), 'label': ''},
                            );
                            return '${match['code']} — ${match['label']}';
                          },
                          onChanged: (v) => setState(() => _selectedBusinessType = v),
                        ),
                      ),


                      // ── Address ────────────────────────────────────────────
                      ZerpaiFormRow(
                        label: 'Address',
                        crossAxisAlignment: CrossAxisAlignment.start,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(controller: _attentionCtrl, decoration: _dec('Attention')),
                            const SizedBox(height: AppTheme.space8),
                            TextFormField(controller: _streetCtrl, decoration: _dec('Street 1')),
                            const SizedBox(height: AppTheme.space8),
                            TextFormField(controller: _street2Ctrl, decoration: _dec('Street 2')),
                            const SizedBox(height: AppTheme.space8),
                            Row(children: [
                              Expanded(child: TextFormField(controller: _cityCtrl, decoration: _dec('City'))),
                              const SizedBox(width: AppTheme.space8),
                              Expanded(child: TextFormField(
                                controller: _pincodeCtrl,
                                decoration: _dec('Pin code'),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                              )),
                            ]),
                            const SizedBox(height: AppTheme.space8),
                            _buildStaticField(_orgCountry),
                            const SizedBox(height: AppTheme.space8),
                            Row(children: [
                              Expanded(child: FormDropdown<String>(
                                items: _stateOptions,
                                value: _selectedState,
                                hint: 'State / Union territory',
                                onChanged: (v) => setState(() => _selectedState = v),
                              )),
                              const SizedBox(width: AppTheme.space8),
                              Expanded(child: TextFormField(
                                controller: _phoneCtrl,
                                decoration: _dec('Phone'),
                                inputFormatters: [_IndiaPhoneFormatter()],
                                keyboardType: TextInputType.phone,
                              )),
                            ]),
                            const SizedBox(height: AppTheme.space8),
                            TextFormField(
                              controller: _faxCtrl,
                              decoration: _dec('Fax number'),
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),


                      // ── Website URL ────────────────────────────────────────
                      ZerpaiFormRow(
                        label: 'Website URL',
                        child: TextFormField(
                          controller: _websiteCtrl,
                          decoration: _dec('https://example.com'),
                          keyboardType: TextInputType.url,
                        ),
                      ),


                      // ── Primary contact ────────────────────────────────────
                      ZerpaiFormRow(
                        label: 'Primary contact',
                        child: _orgUsers.isEmpty
                            ? _buildStaticField('No users found')
                            : FormDropdown<String>(
                                value: _primaryContactId,
                                hint: 'Select primary contact',
                                items: _orgUsers.map((u) => u['id'].toString()).toList(),
                                displayStringForValue: (id) {
                                  final u = _orgUsers.firstWhere(
                                    (u) => u['id'].toString() == id,
                                    orElse: () => <String, dynamic>{},
                                  );
                                  final name  = (u['name'] ?? u['full_name'] ?? '').toString();
                                  final email = (u['email'] ?? '').toString();
                                  return name.isNotEmpty && email.isNotEmpty
                                      ? '$name <$email>'
                                      : name.isNotEmpty ? name : email;
                                },
                                onChanged: (v) => setState(() => _primaryContactId = v),
                              ),
                      ),


                      // ── GSTIN ──────────────────────────────────────────────
                      ZerpaiFormRow(
                        label: 'GSTIN',
                        crossAxisAlignment: CrossAxisAlignment.start,
                        child: _buildGstinDropdownField(),
                      ),


                      // ── Subscription ───────────────────────────────────────
                      ZerpaiFormRow(
                        label: 'Subscription from',
                        child: GestureDetector(
                          key: _subFromKey,
                          onTap: () async {
                            final picked = await ZerpaiDatePicker.show(context,
                                initialDate: _subscriptionFrom ?? DateTime.now(), targetKey: _subFromKey);
                            if (picked != null) setState(() => _subscriptionFrom = picked);
                          },
                          child: _buildDateField(_subscriptionFrom, 'Select start date'),
                        ),
                      ),


                      ZerpaiFormRow(
                        label: 'Subscription to',
                        child: GestureDetector(
                          key: _subToKey,
                          onTap: () async {
                            final picked = await ZerpaiDatePicker.show(context,
                                initialDate: _subscriptionTo ?? DateTime.now(),
                                firstDate: _subscriptionFrom, targetKey: _subToKey);
                            if (picked != null) setState(() => _subscriptionTo = picked);
                          },
                          child: _buildDateField(_subscriptionTo, 'Select end date'),
                        ),
                      ),

                      // ── Transaction series ─────────────────────────────────
                      ZerpaiFormRow(
                        label: 'Transaction number series',
                        crossAxisAlignment: CrossAxisAlignment.start,
                        child: _buildTransactionSeriesField(),
                      ),
                      ZerpaiFormRow(
                        label: 'Default transaction series',
                        child: FormDropdown<String>(
                          items: _selectedTransactionSeriesIds.isNotEmpty
                              ? _selectedTransactionSeriesIds
                              : _transactionSeries.map((s) => s.id).toList(),
                          value: _selectedDefaultSeriesId,
                          hint: 'Select default series',
                          displayStringForValue: (id) => _transactionSeries
                              .firstWhere((s) => s.id == id, orElse: () => _SeriesOption(id: id, name: id))
                              .name,
                          onChanged: (v) => setState(() => _selectedDefaultSeriesId = v),
                        ),
                      ),


                      ZerpaiFormRow(
                        label: 'Branch access',
                        crossAxisAlignment: CrossAxisAlignment.start,
                        child: _buildLocationAccessContent(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),

          ),
        ),
        // ── Sticky bottom action bar ──────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.borderLight)),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space32, vertical: AppTheme.space16),
          child: _buildActions(),
        ),
      ],
    ),
  );
  }

  // ─── Transaction series multi-select ───────────────────────────────────────

  Widget _buildTransactionSeriesField() {
    final unselectedIds = _transactionSeries
        .where((s) => !_selectedTransactionSeriesIds.contains(s.id))
        .map((s) => s.id)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedTransactionSeriesIds.isNotEmpty) ...[
          Wrap(
            spacing: AppTheme.space6,
            runSpacing: AppTheme.space6,
            children: [
              for (final id in _selectedTransactionSeriesIds)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space10, vertical: AppTheme.space6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      _transactionSeries
                          .firstWhere((s) => s.id == id,
                              orElse: () => _SeriesOption(id: id, name: id))
                          .name,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textBody),
                    ),
                    const SizedBox(width: AppTheme.space6),
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedTransactionSeriesIds.remove(id);
                        if (_selectedDefaultSeriesId == id) _selectedDefaultSeriesId = null;
                      }),
                      child: const Icon(LucideIcons.x, size: 12, color: AppTheme.textSecondary),
                    ),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
        ],
        FormDropdown<String>(
          value: null,
          hint: 'Add transaction series',
          items: [...unselectedIds, '__add_new__'],
          displayStringForValue: (id) => id == '__add_new__'
              ? '+ Add Transaction Series'
              : _transactionSeries
                  .firstWhere((s) => s.id == id, orElse: () => _SeriesOption(id: id, name: id))
                  .name,
          onChanged: (v) {
            if (v == '__add_new__') { _showTransactionSeriesPreferencesDialog(); return; }
            if (v != null && !_selectedTransactionSeriesIds.contains(v)) {
              setState(() => _selectedTransactionSeriesIds.add(v));
            }
          },
        ),
      ],
    );
  }

  // ─── Transaction series preferences dialog ─────────────────────────────────

  void _showTransactionSeriesPreferencesDialog() {
    final seriesNameCtrl = TextEditingController();
    // Per-module prefix + starting number controllers
    final prefixCtrls = {for (final m in _kSeriesModules) m['id']!: TextEditingController()};
    final startingCtrls = {for (final m in _kSeriesModules) m['id']!: TextEditingController(text: '1')};
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final accentColor = ref.read(appBrandingProvider).accentColor;

          String _preview(String moduleId) {
            final prefix = prefixCtrls[moduleId]?.text.trim() ?? '';
            final num = startingCtrls[moduleId]?.text.trim() ?? '1';
            return prefix.isEmpty && num == '1' ? '—' : '$prefix$num';
          }

          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SizedBox(
              width: 640,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppTheme.space24, AppTheme.space24, AppTheme.space24, 0),
                        child: Row(children: [
                          const Expanded(
                            child: Text('Transaction Series Preferences',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(LucideIcons.x, size: 16, color: AppTheme.textSecondary),
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                          ),
                        ]),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      const Divider(height: 1, color: AppTheme.borderLight),

                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppTheme.space24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Series name
                              Row(children: [
                                const SizedBox(
                                  width: 140,
                                  child: Text('Series name',
                                      style: TextStyle(fontSize: 13, color: AppTheme.errorRed)),
                                ),
                                const Text(' *', style: TextStyle(fontSize: 13, color: AppTheme.errorRed)),
                                const SizedBox(width: AppTheme.space12),
                                Expanded(
                                  child: TextFormField(
                                    controller: seriesNameCtrl,
                                    decoration: _dec('e.g. SERIES 1'),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty) ? 'Series name is required' : null,
                                  ),
                                ),
                              ]),
                              const SizedBox(height: AppTheme.space20),

                              // Table
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.borderLight),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(children: [
                                  // Header row
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.space16, vertical: AppTheme.space10),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.bgLight,
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                                    ),
                                    child: Row(children: [
                                      const Expanded(
                                        flex: 3,
                                        child: Text('MODULE',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                                color: AppTheme.textSecondary, letterSpacing: 0.5)),
                                      ),
                                      const Expanded(
                                        flex: 2,
                                        child: Text('PREFIX',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                                color: AppTheme.textSecondary, letterSpacing: 0.5)),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Row(children: [
                                          const Text('STARTING NUMBER',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                                  color: AppTheme.textSecondary, letterSpacing: 0.5)),
                                          const SizedBox(width: AppTheme.space4),
                                          Tooltip(
                                            message: 'This will be the number assigned to the next transaction you create.',
                                            child: const Icon(LucideIcons.helpCircle, size: 13, color: AppTheme.textSecondary),
                                          ),
                                        ]),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Row(children: [
                                          const Text('PREVIEW',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                                  color: AppTheme.textSecondary, letterSpacing: 0.5)),
                                          const SizedBox(width: AppTheme.space4),
                                          Tooltip(
                                            message: 'You can preview your transaction numbers here once you save the series.',
                                            child: const Icon(LucideIcons.helpCircle, size: 13, color: AppTheme.textSecondary),
                                          ),
                                        ]),
                                      ),
                                    ]),
                                  ),
                                  // Module rows
                                  for (int i = 0; i < _kSeriesModules.length; i++) ...[
                                    const Divider(height: 1, color: AppTheme.borderLight),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.space16, vertical: AppTheme.space10),
                                      child: Row(children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(_kSeriesModules[i]['label']!,
                                              style: const TextStyle(fontSize: 13, color: AppTheme.textBody)),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: TextFormField(
                                            controller: prefixCtrls[_kSeriesModules[i]['id']!],
                                            decoration: _dec('e.g. INV-'),
                                            onChanged: (_) => setS(() {}),
                                          ),
                                        ),
                                        const SizedBox(width: AppTheme.space8),
                                        Expanded(
                                          flex: 2,
                                          child: TextFormField(
                                            controller: startingCtrls[_kSeriesModules[i]['id']!],
                                            decoration: _dec('1'),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            onChanged: (_) => setS(() {}),
                                          ),
                                        ),
                                        const SizedBox(width: AppTheme.space8),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            _preview(_kSeriesModules[i]['id']!),
                                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                          ),
                                        ),
                                      ]),
                                    ),
                                  ],
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Footer
                      const Divider(height: 1, color: AppTheme.borderLight),
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: AppTheme.space8),
                          ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final name = seriesNameCtrl.text.trim();
                              final user = ref.read(authUserProvider);
                              final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
                              final modules = {
                                for (final m in _kSeriesModules)
                                  m['id']!: {
                                    'prefix': prefixCtrls[m['id']!]!.text.trim(),
                                    'starting_number': int.tryParse(startingCtrls[m['id']!]!.text.trim()) ?? 1,
                                  }
                              };
                              try {
                                final res = await _apiClient.post('transaction-series', data: {
                                  'org_id': orgId,
                                  'name': name,
                                  'modules': modules,
                                });
                                if (!mounted) return;
                                if (res.success && res.data is Map<String, dynamic>) {
                                  final newId = (res.data as Map<String, dynamic>)['id'].toString();
                                  setState(() {
                                    _transactionSeries.add(_SeriesOption(id: newId, name: name));
                                    _selectedTransactionSeriesIds.add(newId);
                                  });
                                  if (mounted) Navigator.pop(ctx);
                                } else {
                                  ZerpaiToast.error(ctx, 'Failed to create transaction series.');
                                }
                              } catch (_) {
                                ZerpaiToast.error(ctx, 'An unexpected error occurred.');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Save'),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── GSTIN dropdown field ──────────────────────────────────────────────────

  Widget _buildGstinDropdownField() {
    final List<String> items = [
      ..._orgGstins,
      if (_gstinData != null && !_orgGstins.contains(_gstinData!.gstin)) _gstinData!.gstin,
      '__add__',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormDropdown<String>(
          value: _gstinData?.gstin,
          hint: 'Select GSTIN',
          items: items,
          displayStringForValue: (v) => v == '__add__' ? '+ New GSTIN' : v,
          onChanged: (v) {
            if (v == '__add__') { _showGstinDialog(); return; }
            if (v != null) setState(() => _gstinData = _GstinData(gstin: v));
          },
        ),
        if (_gstinData != null) ...[
          const SizedBox(height: AppTheme.space6),
          Row(children: [
            if (_gstinData!.registrationType != null)
              Expanded(
                child: Text(
                  _kGstRegistrationTypes.firstWhere(
                    (t) => t['id'] == _gstinData!.registrationType,
                    orElse: () => {'label': ''},
                  )['label']!,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              )
            else
              const Spacer(),
            TextButton(
              onPressed: _showGstinDialog,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8),
                minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Edit details', style: TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: () => setState(() => _gstinData = null),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8),
                minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Remove', style: TextStyle(fontSize: 12)),
            ),
          ]),
        ],
      ],
    );
  }

  // ─── GSTIN dialog ──────────────────────────────────────────────────────────

  void _showGstinDialog() {
    final gstinCtrl      = TextEditingController(text: _gstinData?.gstin ?? '');
    final legalNameCtrl  = TextEditingController(text: _gstinData?.legalName ?? '');
    final tradeNameCtrl  = TextEditingController(text: _gstinData?.tradeName ?? '');
    String? selectedRegType     = _gstinData?.registrationType;
    DateTime? registeredOn      = _gstinData?.registeredOn != null
        ? DateTime.tryParse(_gstinData!.registeredOn!) : null;
    bool reverseCharge          = _gstinData?.reverseCharge ?? false;
    bool importExport            = _gstinData?.importExport ?? false;
    String? importExportAccountId = _gstinData?.importExportAccountId;
    bool digitalServices         = _gstinData?.digitalServices ?? false;
    final registeredOnKey       = GlobalKey();

    bool isFetchingTaxpayer = false;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final accentColor = ref.read(appBrandingProvider).accentColor;

          Future<void> fetchTaxpayer() async {
            final gstin = gstinCtrl.text.trim();
            if (gstin.length != 15) {
              ZerpaiToast.info(ctx, 'Enter a valid 15-digit GSTIN first');
              return;
            }
            setS(() => isFetchingTaxpayer = true);
            try {
              final res = await _apiClient.get(
                'gst/taxpayer-details',
                queryParameters: {'gstin': gstin},
              );
              final d = res.data as Map<String, dynamic>;
              legalNameCtrl.text  = (d['legalName']  ?? '').toString();
              tradeNameCtrl.text  = (d['tradeName']  ?? '').toString();
              setS(() {
                selectedRegType = (d['registrationType'] as String?)?.isNotEmpty == true
                    ? d['registrationType'] as String : selectedRegType;
                final raw = (d['registeredOn'] ?? '') as String;
                if (raw.isNotEmpty) {
                  final parts = raw.split('-');
                  if (parts.length == 3) {
                    registeredOn = DateTime(
                      int.tryParse(parts[2]) ?? 2000,
                      int.tryParse(parts[1]) ?? 1,
                      int.tryParse(parts[0]) ?? 1,
                    );
                  }
                }
              });
              if (ctx.mounted) {
                showDialog<void>(
                  context: ctx,
                  builder: (tCtx) => Dialog(
                    alignment: Alignment.topCenter,
                    insetPadding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: SizedBox(
                      width: 460,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(ctx).size.height * 0.8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
                              child: Row(children: [
                                const Expanded(
                                  child: Text('Taxpayer Details',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary)),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(tCtx),
                                  icon: const Icon(LucideIcons.x,
                                      size: 16, color: AppTheme.textSecondary),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1, color: AppTheme.borderLight),
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _tdRow('GSTIN', d['gstin']?.toString() ?? ''),
                                    _tdRow('Company Name', d['legalName']?.toString() ?? ''),
                                    _tdRow('Date of Registration',
                                        d['registeredOn']?.toString() ?? ''),
                                    _tdRow('GSTIN/UIN Status',
                                        d['status']?.toString() ?? ''),
                                    _tdRow(
                                      'Taxpayer Type',
                                      _kGstRegistrationTypes
                                          .firstWhere(
                                            (t) => t['id'] == d['registrationType'],
                                            orElse: () => {
                                              'label':
                                                  d['registrationType']?.toString() ?? ''
                                            },
                                          )['label']!,
                                    ),
                                    _tdRow('State Jurisdiction',
                                        d['stateJurisdiction']?.toString() ?? ''),
                                    _tdRow('Constitution of Business',
                                        d['constitutionOfBusiness']?.toString() ?? ''),
                                    if ((d['tradeName']?.toString() ?? '').isNotEmpty)
                                      _tdRow('Business Trade Name',
                                          d['tradeName']!.toString()),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 1, color: AppTheme.borderLight),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(tCtx),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6)),
                                    ),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
            } catch (e) {
              if (ctx.mounted) ZerpaiToast.error(ctx, e.toString().replaceFirst('Exception: ', ''));
            } finally {
              setS(() => isFetchingTaxpayer = false);
            }
          }

          String _fmtDate(DateTime? d) {
            if (d == null) return 'Select date';
            return '${d.day.toString().padLeft(2, '0')} ${_monthNames[d.month - 1]} ${d.year}';
          }

          Widget _checkRow(String text, bool value, ValueChanged<bool> onChanged, {Widget? helper}) {
            return GestureDetector(
              onTap: () => setS(() => onChanged(!value)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    SizedBox(
                      width: 16, height: 16,
                      child: Checkbox(
                        value: value,
                        onChanged: (v) => setS(() => onChanged(v ?? false)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.textBody))),
                  ]),
                  if (helper != null) ...[
                    const SizedBox(height: AppTheme.space4),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: helper,
                    ),
                  ],
                ],
              ),
            );
          }

          return Dialog(
            backgroundColor: Colors.white,
            alignment: Alignment.topCenter,
            insetPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: SizedBox(
              width: 560,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space24, vertical: AppTheme.space16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('GST Details',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary)),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(LucideIcons.x, size: 20, color: AppTheme.errorRed),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable form body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space24, vertical: AppTheme.space16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // GSTIN + Get Taxpayer link
                              ZerpaiFormRow(
                                label: 'GSTIN',
                                required: true,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      controller: gstinCtrl,
                                      decoration: _dec('Enter 15-digit GSTIN'),
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(15),
                                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                                      ],
                                      onChanged: (v) {
                                        gstinCtrl.value = gstinCtrl.value.copyWith(
                                          text: v.toUpperCase(),
                                          selection: TextSelection.collapsed(offset: v.length),
                                        );
                                        if (v.length == 15) fetchTaxpayer();
                                      },
                                    ),
                                    const SizedBox(height: AppTheme.space4),
                                    GestureDetector(
                                      onTap: isFetchingTaxpayer ? null : fetchTaxpayer,
                                      child: isFetchingTaxpayer
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: 12, height: 12,
                                                  child: CircularProgressIndicator(
                                                      strokeWidth: 1.5, color: accentColor),
                                                ),
                                                const SizedBox(width: 6),
                                                Text('Fetching...',
                                                    style: TextStyle(fontSize: 12, color: accentColor)),
                                              ],
                                            )
                                          : Text('Get Taxpayer details',
                                              style: TextStyle(fontSize: 12, color: accentColor)),
                                    ),
                                  ],
                                ),
                              ),
                              kZerpaiFormDivider,
                              // Registration type
                              ZerpaiFormRow(
                                label: 'Registration type',
                                child: FormDropdown<String>(
                                  items: _kGstRegistrationTypes.map((t) => t['id']!).toList(),
                                  value: selectedRegType,
                                  hint: 'Select type',
                                  displayStringForValue: (id) => _kGstRegistrationTypes
                                      .firstWhere((t) => t['id'] == id, orElse: () => {'label': id})['label']!,
                                  onChanged: (v) => setS(() => selectedRegType = v),
                                ),
                              ),
                              kZerpaiFormDivider,
                              // Business Legal Name
                              ZerpaiFormRow(
                                label: 'Business legal name',
                                child: TextFormField(
                                  controller: legalNameCtrl,
                                  decoration: _dec('As per GST registration'),
                                ),
                              ),
                              kZerpaiFormDivider,
                              // Business Trade Name
                              ZerpaiFormRow(
                                label: 'Business trade name',
                                child: TextFormField(
                                  controller: tradeNameCtrl,
                                  decoration: _dec('Trade / brand name'),
                                ),
                              ),
                              kZerpaiFormDivider,
                              // GST Registered On
                              ZerpaiFormRow(
                                label: 'GST registered on',
                                child: GestureDetector(
                                  key: registeredOnKey,
                                  onTap: () async {
                                    final picked = await ZerpaiDatePicker.show(
                                      ctx,
                                      initialDate: registeredOn ?? DateTime.now(),
                                      targetKey: registeredOnKey,
                                    );
                                    if (picked != null) setS(() => registeredOn = picked);
                                  },
                                  child: Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppTheme.borderLight),
                                    ),
                                    child: Row(children: [
                                      Expanded(child: Text(_fmtDate(registeredOn),
                                          style: TextStyle(fontSize: 13,
                                              color: registeredOn == null
                                                  ? AppTheme.textSecondary
                                                  : AppTheme.textBody))),
                                      const Icon(LucideIcons.calendar, size: 14, color: AppTheme.textSecondary),
                                    ]),
                                  ),
                                ),
                              ),
                              kZerpaiFormDivider,
                              // Reverse Charge
                              ZerpaiFormRow(
                                label: 'Reverse charge',
                                crossAxisAlignment: CrossAxisAlignment.start,
                                child: _checkRow(
                                  'Enable Reverse Charge in Sales transactions',
                                  reverseCharge,
                                  (v) => reverseCharge = v,
                                  helper: GestureDetector(
                                    onTap: () => ZerpaiToast.info(ctx,
                                        'Buyer pays GST directly to the government instead of the seller.'),
                                    child: Text('Know more',
                                        style: TextStyle(fontSize: 12, color: accentColor)),
                                  ),
                                ),
                              ),
                              kZerpaiFormDivider,
                              // Import / Export (SEZ)
                              ZerpaiFormRow(
                                label: 'Import / Export',
                                crossAxisAlignment: CrossAxisAlignment.start,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _checkRow(
                                      'My business is involved in SEZ / Overseas Trading',
                                      importExport,
                                      (v) {
                                        importExport = v;
                                        if (!v) importExportAccountId = null;
                                      },
                                    ),
                                    if (importExport) ...[
                                      const SizedBox(height: AppTheme.space10),
                                      Row(children: [
                                        Text('Custom Duty Tracking Account',
                                            style: const TextStyle(fontSize: 13, color: AppTheme.errorRed)),
                                        const Text(' *', style: TextStyle(fontSize: 13, color: AppTheme.errorRed)),
                                      ]),
                                      const SizedBox(height: AppTheme.space6),
                                      FormDropdown<String>(
                                        value: importExportAccountId,
                                        hint: 'Select account',
                                        items: const [],
                                        displayStringForValue: (v) => v,
                                        onChanged: (v) => setS(() => importExportAccountId = v),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              kZerpaiFormDivider,
                              // Digital Services
                              ZerpaiFormRow(
                                label: 'Digital services',
                                crossAxisAlignment: CrossAxisAlignment.start,
                                child: _checkRow(
                                  'Track sale of digital services to overseas customers',
                                  digitalServices,
                                  (v) => digitalServices = v,
                                  helper: const Text(
                                    'Required for GST on e-commerce transactions to non-resident customers.',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ),
                    ),

                    // Footer actions
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space24, vertical: AppTheme.space16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppTheme.borderColor)),
                      ),
                      child: Row(children: [
                        ElevatedButton(
                          onPressed: () {
                            final gstin = gstinCtrl.text.trim().toUpperCase();
                            if (gstin.isEmpty) { Navigator.pop(ctx); return; }
                            setState(() {
                              _gstinData = _GstinData(
                                gstin: gstin,
                                registrationType: selectedRegType,
                                legalName: legalNameCtrl.text.trim(),
                                tradeName: tradeNameCtrl.text.trim(),
                                registeredOn: registeredOn?.toIso8601String().substring(0, 10),
                                reverseCharge: reverseCharge,
                                importExport: importExport,
                                importExportAccountId: importExportAccountId,
                                digitalServices: digitalServices,
                              );
                              if (!_orgGstins.contains(gstin)) _orgGstins = [..._orgGstins, gstin];
                            });
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space24, vertical: AppTheme.space12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.space4)),
                          ),
                          child: const Text('Save'),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.bgDisabled,
                            foregroundColor: AppTheme.textBody,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space24, vertical: AppTheme.space12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.space4),
                              side: const BorderSide(color: AppTheme.borderColor),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ]),
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

  // ─── Location access ───────────────────────────────────────────────────────

  Widget _buildLocationAccessContent() {
    final accentColor = ref.watch(appBrandingProvider).accentColor;
    final int count = _locationUsers.length;

    final addedUserIds = _locationUsers.map((u) => u['userId']).toSet();
    final availableToAdd = _orgUsers
        .where((u) => !addedUserIds.contains(u['id']?.toString()))
        .toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                  vertical: AppTheme.space12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _provideAccessToAll
                            ? accentColor
                            : count > 0
                                ? accentColor
                                : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Expanded(
                      child: Text(
                        _provideAccessToAll
                            ? 'All users have access'
                            : count > 0
                                ? '$count user${count == 1 ? '' : 's'} selected'
                                : 'No users selected',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _provideAccessToAll || count > 0
                              ? accentColor
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(
                        () => _provideAccessToAll = !_provideAccessToAll,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: Checkbox(
                              value: _provideAccessToAll,
                              onChanged: (v) => setState(
                                () => _provideAccessToAll = v ?? true,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space8),
                          const Text(
                            'Provide access to all users',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_provideAccessToAll) ...[
                const Divider(height: 1, color: AppTheme.borderLight),
                Padding(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.users,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: AppTheme.space8),
                      const Expanded(
                        child: Text(
                          'All users in your organization have access to this branch.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                    vertical: AppTheme.space10,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppTheme.borderLight),
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'USERS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'ROLE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(width: 32),
                    ],
                  ),
                ),
                for (final user in _locationUsers)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                    vertical: AppTheme.space12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppTheme.bgLight,
                              child: Text(
                                (user['name'] ?? '?')[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.space10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    user['email'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          user['role'] ?? 'User\'s Role',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textBody,
                          ),
                        ),
                      ),
                      ZTooltip(
                        message: 'Remove Association',
                        child: IconButton(
                          onPressed: () => setState(
                            () => _locationUsers.removeWhere(
                              (u) => u['userId'] == user['userId'],
                            ),
                          ),
                          icon: const Icon(LucideIcons.x, size: 14),
                          color: AppTheme.textSecondary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                    vertical: AppTheme.space12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: availableToAdd.isEmpty
                            ? const Text(
                                'All users already added',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              )
                            : FormDropdown<String>(
                                value: null,
                                hint: 'Select users',
                                items: availableToAdd
                                    .map((u) => u['id'].toString())
                                    .toList(),
                                displayStringForValue: (id) {
                                  final u = availableToAdd.firstWhere(
                                    (u) => u['id'].toString() == id,
                                    orElse: () => <String, dynamic>{},
                                  );
                                  final name = (u['name'] ?? u['full_name'] ?? '')
                                      .toString();
                                  final email =
                                      (u['email'] ?? '').toString();
                                  return name.isNotEmpty ? name : email;
                                },
                                onChanged: (id) {
                                  if (id == null) return;
                                  final u = availableToAdd.firstWhere(
                                    (u) => u['id'].toString() == id,
                                    orElse: () => <String, dynamic>{},
                                  );
                                  if (u.isEmpty) return;
                                  setState(
                                    () => _locationUsers.add({
                                      'userId': id,
                                      'name': (u['name'] ?? u['full_name'] ?? '')
                                          .toString(),
                                      'email': (u['email'] ?? '').toString(),
                                      'role': '',
                                    }),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(width: AppTheme.space16),
                      const Expanded(
                        child: Text(
                          'User\'s Role',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                    ],
                  ),
                ),
              ],
            ],
      ),
    );
  }

  // ─── Manage business types dialog ──────────────────────────────────────────

  void _showManageBusinessTypesDialog() {
    bool showForm = false;
    bool isSaving = false;
    final codeCtrl = TextEditingController();
    final labelCtrl = TextEditingController();

    Future<void> saveType(StateSetter setS, BuildContext ctx) async {
      final code = codeCtrl.text.trim().toUpperCase();
      final label = labelCtrl.text.trim();
      if (code.isEmpty || label.isEmpty) return;

      final id = code.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      final exists = _businessTypes.any((type) => type['id'] == id);
      if (exists) {
        ZerpaiToast.error(ctx, 'A business type with this code already exists.');
        return;
      }

      setS(() => isSaving = true);
      setState(() {
        _businessTypes.add({
          'id': id,
          'code': code,
          'label': label,
        });
      });
      setS(() {
        isSaving = false;
        showForm = false;
      });
      codeCtrl.clear();
      labelCtrl.clear();
      ZerpaiToast.success(ctx, 'Business type added.');
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.white,
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.only(
            top: 0,
            left: 24,
            right: 24,
            bottom: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 650,
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          children: [
                            const Text(
                              'Manage Business Types',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const Spacer(),
                            if (!showForm)
                              InkWell(
                                onTap: () => setS(() => showForm = true),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentGreen,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  child: const Text(
                                    '+ New Business Type',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(
                                Icons.close,
                                color: AppTheme.textSecondary,
                              ),
                              hoverColor: AppTheme.bgLight,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.borderColor),
                      if (showForm) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Business Type Code*',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: codeCtrl,
                                textCapitalization: TextCapitalization.characters,
                                decoration: _dec('e.g. FOFO'),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Business Type Name*',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: labelCtrl,
                                decoration: _dec('Enter business type name'),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: isSaving ? null : () => saveType(setS, ctx),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      minimumSize: const Size(100, 40),
                                    ),
                                    child: isSaving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Save',
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  InkWell(
                                    onTap: () {
                                      codeCtrl.clear();
                                      labelCtrl.clear();
                                      setS(() => showForm = false);
                                    },
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: AppTheme.primaryBlueDark,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BUSINESS TYPES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 16),
                          for (int i = 0; i < _businessTypes.length; i++) ...[
                            if (i > 0)
                              const Divider(height: 1, color: AppTheme.borderLight),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 72,
                                    child: Text(
                                      _businessTypes[i]['code']!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryBlueDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _businessTypes[i]['label']!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textBody,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.bgLight,
                          foregroundColor: const Color(0xFF334155),
                          elevation: 0,
                          minimumSize: const Size(100, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
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
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderLight)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                            Expanded(child: Text(_logoPicked!.name,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                                maxLines: 2, overflow: TextOverflow.ellipsis)),
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 14, color: AppTheme.errorRed),
                              onPressed: () => setState(() => _logoPicked = null),
                              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
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
                                Text('Upload your branch logo',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              ]),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space16),
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
    return Row(mainAxisAlignment: MainAxisAlignment.start, children: [
      ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
            backgroundColor: accentColor, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: _isSaving
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Save', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
      const SizedBox(width: AppTheme.space12),
      OutlinedButton(
        onPressed: _isSaving ? null : () => context.go(AppRoutes.settingsBranches),
        style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
            side: const BorderSide(color: AppTheme.borderLight),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      ),
    ]);
  }


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
      decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.borderLight)),
      alignment: Alignment.centerLeft,
      child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textBody)),
    );
  }

  Widget _tdRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textBody, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: ref.read(appBrandingProvider).accentColor)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.errorRed)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.errorRed)),
        filled: true,
        fillColor: Colors.white,
      );
}
