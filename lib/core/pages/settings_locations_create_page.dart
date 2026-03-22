import 'package:file_picker/file_picker.dart';
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
import 'package:zerpai_erp/shared/services/storage_service.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

const String _kDevOrgId = '00000000-0000-0000-0000-000000000002';

const List<String> _indianStates = <String>[
  'Andaman and Nicobar Islands',
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chandigarh',
  'Chhattisgarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jammu and Kashmir',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Ladakh',
  'Lakshadweep',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Puducherry',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
];

// ─── Sidebar nav (mirrors settings_locations_page) ────────────────────────────

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
          _NavEntry(
            label: 'Customers and Vendors',
            route: AppRoutes.salesCustomers,
          ),
          _NavEntry(label: 'Items', route: AppRoutes.itemsReport),
        ],
      ),
      _NavBlock(
        title: 'Inventory',
        items: <_NavEntry>[
          _NavEntry(label: 'Assemblies', route: AppRoutes.assemblies),
          _NavEntry(
            label: 'Inventory Adjustments',
            route: AppRoutes.inventoryAdjustments,
          ),
          _NavEntry(label: 'Picklists', route: AppRoutes.picklists),
          _NavEntry(label: 'Packages', route: AppRoutes.packages),
          _NavEntry(label: 'Shipments', route: AppRoutes.shipments),
          _NavEntry(label: 'Transfer Orders', route: AppRoutes.transferOrders),
        ],
      ),
    ],
  ),
];

// ─── Parent outlet option ──────────────────────────────────────────────────────

class _OutletOption {
  final String id;
  final String name;
  const _OutletOption({required this.id, required this.name});
}

class _SeriesOption {
  final String id;
  final String name;
  const _SeriesOption({required this.id, required this.name});
}

// ─── Transaction series module definitions ─────────────────────────────────

class _SeriesModuleRow {
  final TextEditingController prefixCtrl;
  final TextEditingController startingCtrl;
  _SeriesModuleRow({required String prefix, required String starting})
      : prefixCtrl = TextEditingController(text: prefix),
        startingCtrl = TextEditingController(text: starting);
  void dispose() {
    prefixCtrl.dispose();
    startingCtrl.dispose();
  }
}

const List<Map<String, String>> _kSeriesModules = [
  {'key': 'credit_note', 'label': 'Credit Note', 'prefix': 'CN-', 'starting': '00001'},
  {'key': 'customer_payment', 'label': 'Customer Payment', 'prefix': '', 'starting': '1'},
  {'key': 'purchase_order', 'label': 'Purchase Order', 'prefix': 'PO-', 'starting': '00001'},
  {'key': 'sales_order', 'label': 'Sales Order', 'prefix': 'SO-', 'starting': '00001'},
  {'key': 'vendor_payment', 'label': 'Vendor Payment', 'prefix': '', 'starting': '1'},
  {'key': 'retainer_invoice', 'label': 'Retainer Invoice', 'prefix': 'RET-', 'starting': '00001'},
  {'key': 'bill_of_supply', 'label': 'Bill Of Supply', 'prefix': 'BOS-', 'starting': '000001'},
  {'key': 'invoice', 'label': 'Invoice', 'prefix': 'INV-', 'starting': '000001'},
  {'key': 'delivery_challan', 'label': 'Delivery Challan', 'prefix': 'DC-', 'starting': '00001'},
  {'key': 'self_invoice', 'label': 'Self-Invoice', 'prefix': '', 'starting': '1'},
];

class _AccountOption {
  final String id;
  final String name;
  final String? accountType;
  const _AccountOption({required this.id, required this.name, this.accountType});
}

class _GstinData {
  final String gstin;
  final String? registrationType;
  final String legalName;
  final String tradeName;
  final String? registeredOn;
  final bool reverseCharge;
  final bool importExport;
  final String? customDutyAccountId;
  final bool digitalServices;

  const _GstinData({
    required this.gstin,
    this.registrationType,
    this.legalName = '',
    this.tradeName = '',
    this.registeredOn,
    this.reverseCharge = false,
    this.importExport = false,
    this.customDutyAccountId,
    this.digitalServices = false,
  });
}

const List<Map<String, String>> _kGstRegistrationTypes = [
  {'id': 'registered_regular', 'label': 'Registered Business - Regular'},
  {'id': 'composition', 'label': 'Composition Scheme'},
  {'id': 'unregistered', 'label': 'Unregistered Business'},
  {'id': 'consumer', 'label': 'Consumer'},
  {'id': 'overseas', 'label': 'Overseas'},
  {'id': 'sez', 'label': 'Special Economic Zone'},
  {'id': 'deemed_export', 'label': 'Deemed Export'},
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class SettingsLocationsCreatePage extends ConsumerStatefulWidget {
  final String? outletId;
  const SettingsLocationsCreatePage({super.key, this.outletId});

  @override
  ConsumerState<SettingsLocationsCreatePage> createState() =>
      _SettingsLocationsCreatePageState();
}

class _SettingsLocationsCreatePageState
    extends ConsumerState<SettingsLocationsCreatePage> {
  final ApiClient _apiClient = ApiClient();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Form controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _attentionCtrl = TextEditingController();
  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _street2Ctrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();
  final TextEditingController _faxCtrl = TextEditingController();
  final TextEditingController _websiteCtrl = TextEditingController();

  // State
  String _locationType = 'business';
  String _logoOption = 'same'; // 'same' | 'upload'
  String? _selectedState;
  bool _isChildLocation = false;
  String? _parentOutletId;
  String? _parentError;
  bool _isSaving = false;
  bool _isLoading = false;
  String _organizationName = '';
  List<_OutletOption> _outlets = [];
  final Set<String> _expandedBlocks = <String>{'Organization'};

  // GSTIN
  _GstinData? _gstinData;

  // Transaction series
  List<_SeriesOption> _transactionSeries = [];
  final List<String> _selectedSeriesIds = [];
  String? _selectedDefaultSeriesId;

  // Chart-of-accounts for custom duty
  List<_AccountOption> _accounts = [];

  // Location access — list of { userId, name, email, role }
  final List<Map<String, String>> _locationUsers = [];

  // Logo upload state
  PlatformFile? _logoPicked;
  String? _logoUrl; // URL after upload or loaded from existing

  bool get _isBusiness => _locationType == 'business';
  bool get _isEditing => widget.outletId != null;

  @override
  void initState() {
    super.initState();
    _loadOrgName();
    _loadOutlets();
    _loadTransactionSeries();
    _loadAccounts();
    if (_isEditing) _loadExisting();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _attentionCtrl.dispose();
    _streetCtrl.dispose();
    _street2Ctrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    _faxCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrgName() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final res = await _apiClient.get('/lookups/org/$orgId');
      if (!mounted) return;
      if (res.success && res.data is Map<String, dynamic>) {
        setState(() {
          _organizationName =
              ((res.data as Map<String, dynamic>)['name'] ??
                      user?.orgName ??
                      '')
                  .toString()
                  .trim();
        });
      } else {
        setState(() => _organizationName = user?.orgName ?? '');
      }
    } catch (_) {}
  }

  Future<void> _loadOutlets() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final res = await _apiClient.get(
        '/outlets',
        queryParameters: {'org_id': orgId},
      );
      if (!mounted) return;
      if (res.success && res.data is List) {
        final list = (res.data as List).cast<Map<String, dynamic>>();
        setState(() {
          _outlets = list
              .where((o) => o['id'] != widget.outletId)
              .map(
                (o) => _OutletOption(
                  id: o['id'].toString(),
                  name: o['name'].toString(),
                ),
              )
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadTransactionSeries() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId =
          (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final res = await _apiClient.get(
        '/transaction-series',
        queryParameters: {'org_id': orgId},
      );
      if (!mounted) return;
      if (res.success && res.data is List) {
        setState(() {
          _transactionSeries = (res.data as List)
              .cast<Map<String, dynamic>>()
              .map((s) => _SeriesOption(
                    id: s['id'].toString(),
                    name: (s['name'] ?? s['series_name'] ?? '').toString(),
                  ))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAccounts() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId =
          (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final res = await _apiClient.get(
        '/accountant',
        queryParameters: {'orgId': orgId},
      );
      if (!mounted) return;
      if (res.success && res.data is List) {
        // Keep only Expense-type accounts for Custom Duty Tracking Account
        final expenseTypes = {'expense', 'other_expense', 'cost_of_goods_sold'};
        setState(() {
          _accounts = (res.data as List)
              .cast<Map<String, dynamic>>()
              .where((a) {
                final t = (a['account_type'] ?? '')
                    .toString()
                    .toLowerCase()
                    .replaceAll(' ', '_');
                return expenseTypes.contains(t);
              })
              .map((a) => _AccountOption(
                    id: a['id'].toString(),
                    name: (a['user_account_name'] ?? a['system_account_name'] ?? '').toString(),
                    accountType: (a['account_type'] ?? '').toString(),
                  ))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authUserProvider);
      final orgId =
          (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
      final res = await _apiClient.get(
        '/outlets/${widget.outletId}',
        queryParameters: {'org_id': orgId},
      );
      if (!mounted) return;
      if (res.success && res.data is Map<String, dynamic>) {
        final d = res.data as Map<String, dynamic>;
        final state = (d['state'] ?? '').toString();
        final parentId = d['parent_outlet_id']?.toString();
        final logoUrl = d['logo_url']?.toString();
        final locationType = (d['location_type'] ?? 'business').toString();

        _nameCtrl.text = (d['name'] ?? '').toString();
        _emailCtrl.text = (d['email'] ?? '').toString();
        _phoneCtrl.text = (d['phone'] ?? '').toString();
        _attentionCtrl.text = (d['attention'] ?? '').toString();
        _streetCtrl.text = (d['address'] ?? '').toString();
        _street2Ctrl.text = (d['address2'] ?? '').toString();
        _cityCtrl.text = (d['city'] ?? '').toString();
        _pincodeCtrl.text = (d['pincode'] ?? '').toString();
        _faxCtrl.text = (d['fax'] ?? '').toString();
        _websiteCtrl.text = (d['website'] ?? '').toString();

        final gstinStr = (d['gstin'] ?? '').toString();
        final defaultSeriesId = d['default_transaction_series_id']?.toString();
        final seriesIds = d['transaction_series_ids'];

        setState(() {
          _locationType = locationType;
          _selectedState = _indianStates.contains(state) ? state : null;
          if (parentId != null && parentId.isNotEmpty) {
            _parentOutletId = parentId;
            _isChildLocation = locationType == 'business';
          }
          if (logoUrl != null && logoUrl.isNotEmpty) {
            _logoUrl = logoUrl;
            _logoOption = 'upload';
          }
          if (gstinStr.isNotEmpty) {
            _gstinData = _GstinData(
              gstin: gstinStr,
              registrationType: d['gstin_registration_type']?.toString(),
              legalName: (d['gstin_legal_name'] ?? '').toString(),
              tradeName: (d['gstin_trade_name'] ?? '').toString(),
              registeredOn: d['gstin_registered_on']?.toString(),
              reverseCharge: d['gstin_reverse_charge'] == true,
              importExport: d['gstin_import_export'] == true,
              customDutyAccountId: d['gstin_custom_duty_account_id']?.toString(),
              digitalServices: d['gstin_digital_services'] == true,
            );
          }
          if (seriesIds is List) {
            _selectedSeriesIds
              ..clear()
              ..addAll(seriesIds.map((e) => e.toString()));
          }
          if (defaultSeriesId != null && defaultSeriesId.isNotEmpty) {
            _selectedDefaultSeriesId = defaultSeriesId;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _logoPicked = result.files.first);
    }
  }

  Future<void> _save() async {
    final bool needsParent = !_isBusiness || _isChildLocation;
    final bool parentMissing = needsParent && _parentOutletId == null;
    if (parentMissing)
      setState(() => _parentError = 'Parent location is required');
    if (!_formKey.currentState!.validate() || parentMissing) return;

    setState(() => _isSaving = true);
    try {
      final user = ref.read(authUserProvider);
      final String orgId = (user?.orgId.isNotEmpty == true)
          ? user!.orgId
          : _kDevOrgId;

      // Upload logo if a new file was picked
      if (_logoPicked != null) {
        final url = await StorageService().uploadLocationLogo(_logoPicked!);
        if (url != null) _logoUrl = url;
      }

      final body = <String, dynamic>{
        'org_id': orgId,
        'name': _nameCtrl.text.trim(),
        'outlet_code': _nameCtrl.text.trim().toUpperCase().replaceAll(' ', '-'),
        'gstin': _gstinData?.gstin ?? '',
        if (_gstinData != null) ...{
          'gstin_registration_type': _gstinData!.registrationType,
          'gstin_legal_name': _gstinData!.legalName,
          'gstin_trade_name': _gstinData!.tradeName,
          'gstin_registered_on': _gstinData!.registeredOn,
          'gstin_reverse_charge': _gstinData!.reverseCharge,
          'gstin_import_export': _gstinData!.importExport,
          'gstin_custom_duty_account_id': _gstinData!.customDutyAccountId,
          'gstin_digital_services': _gstinData!.digitalServices,
        },
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'attention': _attentionCtrl.text.trim(),
        'address': _streetCtrl.text.trim(),
        'address2': _street2Ctrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _selectedState ?? '',
        'country': 'India',
        'pincode': _pincodeCtrl.text.trim(),
        'fax': _faxCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'location_type': _locationType,
        'parent_outlet_id': needsParent ? _parentOutletId : null,
        'logo_url': _logoOption == 'upload' ? _logoUrl : null,
        'is_active': true,
        if (_isBusiness) ...{
          'transaction_series_ids': _selectedSeriesIds,
          'default_transaction_series_id': _selectedDefaultSeriesId,
        },
        'location_users': _locationUsers
            .map((u) => {'user_id': u['userId'], 'role': u['role']})
            .toList(),
      };

      final res = _isEditing
          ? await _apiClient.patch('/outlets/${widget.outletId}', data: body)
          : await _apiClient.post('/outlets', data: body);

      if (!mounted) return;
      if (res.success) {
        ZerpaiToast.success(
          context,
          _isEditing ? 'Location updated' : 'Location added',
        );
        context.go(AppRoutes.settingsLocations);
      } else {
        ZerpaiToast.error(context, res.message ?? 'Failed to save location');
      }
    } catch (e) {
      if (mounted) ZerpaiToast.error(context, 'Failed to save location');
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

  // ─── Top bar (mirrors list page) ───────────────────────────────────────────

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
                      onTap: () => context.go(AppRoutes.settingsLocations),
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

  // ─── Sidebar (mirrors list page, Locations stays highlighted) ──────────────

  Widget _buildSidebar() {
    // Treat any /settings/locations/* path as active for Locations
    final String rawPath = GoRouterState.of(context).uri.path;
    final String currentPath = rawPath.replaceFirst(RegExp(r'^/\d{10,20}'), '');
    final String activePath = currentPath.startsWith('/settings/locations')
        ? AppRoutes.settingsLocations
        : currentPath;

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
              _buildSidebarBlock(block, activePath),
            const SizedBox(height: AppTheme.space12),
          ],
        ],
      ),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
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
                Text(
                  _isEditing ? 'Edit Location' : 'Add Location',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.space24),
                _buildLocationTypeSelector(),
                const SizedBox(height: AppTheme.space24),
                _buildMainFields(),
                const SizedBox(height: AppTheme.space20),
                _buildAddressSection(),
                const SizedBox(height: AppTheme.space20),
                _buildBottomFields(),
                const SizedBox(height: AppTheme.space20),
                if (_isBusiness) ...[
                  _buildTransactionSeriesSection(),
                  const SizedBox(height: AppTheme.space20),
                ],
                _buildLocationAccessSection(),
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

  // ─── Location type selector ────────────────────────────────────────────────

  Widget _buildLocationTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Location Type'),
        const SizedBox(height: AppTheme.space12),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                type: 'business',
                title: 'Business Location',
                description:
                    'A Business Location represents your organization or office\'s '
                    'operational location. It is used to record transactions, assess '
                    'regional performance, and monitor stock levels for items stored at this location.',
              ),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: _buildTypeCard(
                type: 'warehouse',
                title: 'Warehouse Only Location',
                description:
                    'A Warehouse Only Location refers to where your items are stored. '
                    'It helps track and monitor stock levels for items stored at this location.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required String type,
    required String title,
    required String description,
  }) {
    final bool isSelected = _locationType == type;
    final Color accentColor = ref.watch(appBrandingProvider).accentColor;

    return InkWell(
      onTap: () => setState(() {
        _locationType = type;
        if (type == 'warehouse') _isChildLocation = false;
      }),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accentColor : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Radio<String>(
                value: type,
                groupValue: _locationType,
                onChanged: (v) => setState(() {
                  _locationType = v ?? type;
                  if (v == 'warehouse') _isChildLocation = false;
                }),
                activeColor: accentColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: AppTheme.space10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Main fields (type-aware) ──────────────────────────────────────────────

  Widget _buildMainFields() {
    final accentColor = ref.watch(appBrandingProvider).accentColor;

    return _buildCard(
      children: [
        // Logo — Business only
        if (_isBusiness) ...[
          _buildLabel('Logo'),
          const SizedBox(height: AppTheme.space6),
          FormDropdown<String>(
            value: _logoOption,
            items: const ['same', 'upload'],
            displayStringForValue: (v) =>
                v == 'same' ? 'Same as Organization Logo' : 'Upload a New Logo',
            onChanged: (v) => setState(() => _logoOption = v ?? 'same'),
          ),
          if (_logoOption == 'upload') ...[
            const SizedBox(height: AppTheme.space12),
            _buildLogoUploadArea(),
          ],
          const SizedBox(height: AppTheme.space20),
        ],

        // Name — both
        _buildTextField(
          label: 'Name',
          required: true,
          controller: _nameCtrl,
          hint: 'e.g. Head Office, Mumbai Branch',
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Name is required' : null,
        ),

        // Business: "This is a Child Location" checkbox
        if (_isBusiness) ...[
          const SizedBox(height: AppTheme.space16),
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: _isChildLocation,
                  onChanged: (v) => setState(() {
                    _isChildLocation = v ?? false;
                    if (!_isChildLocation) _parentOutletId = null;
                  }),
                  activeColor: accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              const Text(
                'This is a Child Location',
                style: TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ],
          ),
          if (_isChildLocation) ...[
            const SizedBox(height: AppTheme.space16),
            _buildParentDropdown(required: true),
          ],
        ],

        // Warehouse: Parent Location always required
        if (!_isBusiness) ...[
          const SizedBox(height: AppTheme.space20),
          _buildParentDropdown(required: true),
        ],

        // GSTIN — Business only (required)
        if (_isBusiness) ...[
          const SizedBox(height: AppTheme.space20),
          _buildGstinField(),
        ],

        // Primary Contact — required for Business, optional for Warehouse
        const SizedBox(height: AppTheme.space20),
        _buildTextField(
          label: 'Primary Contact',
          required: _isBusiness,
          controller: _emailCtrl,
          hint: 'contact@example.com',
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            final s = v?.trim() ?? '';
            if (_isBusiness && s.isEmpty) return 'Primary contact is required';
            if (s.isNotEmpty) {
              final emailRegex = RegExp(
                r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
              );
              if (!emailRegex.hasMatch(s)) return 'Enter a valid email address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLogoUploadArea() {
    final bool hasPicked = _logoPicked != null;
    final bool hasExisting = _logoUrl != null && _logoUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: _pickLogo,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: hasPicked
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.checkCircle,
                              size: 18,
                              color: AppTheme.successGreen,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _logoPicked!.name,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      )
                    : hasExisting
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.image,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Logo uploaded — tap to change',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.upload,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Upload your Location Logo',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          const Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This logo will be displayed in transaction PDFs and email notifications.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Dimensions: 240 × 240 pixels @ 72 DPI',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                Text(
                  'Supported files: jpg, jpeg, png, gif, bmp',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                Text(
                  'Maximum file size: 1MB',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── GSTIN field + dialog ──────────────────────────────────────────────────

  Widget _buildGstinField() {
    final hasGstin = _gstinData != null && _gstinData!.gstin.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('GSTIN', required: true),
        const SizedBox(height: AppTheme.space6),
        GestureDetector(
          onTap: () => _showNewGstinDialog(context),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasGstin ? _gstinData!.gstin : 'GSTIN',
                    style: TextStyle(
                      fontSize: 13,
                      color: hasGstin
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showNewGstinDialog(BuildContext ctx) async {
    // Local state for dialog
    final gstinCtrl = TextEditingController(text: _gstinData?.gstin ?? '');
    final legalNameCtrl =
        TextEditingController(text: _gstinData?.legalName ?? '');
    final tradeNameCtrl =
        TextEditingController(text: _gstinData?.tradeName ?? '');
    final registeredOnCtrl =
        TextEditingController(text: _gstinData?.registeredOn ?? '');
    String? regType = _gstinData?.registrationType;
    bool reverseCharge = _gstinData?.reverseCharge ?? false;
    bool importExport = _gstinData?.importExport ?? false;
    String? customDutyAccountId = _gstinData?.customDutyAccountId;
    bool digitalServices = _gstinData?.digitalServices ?? false;
    String? gstinError;
    bool fetchingGstin = false;
    String? fetchError;

    Future<void> fetchTaxpayerDetails(StateSetter setS) async {
      final gstin = gstinCtrl.text.trim().toUpperCase();
      if (gstin.length != 15) {
        setS(() => gstinError = 'GSTIN must be exactly 15 characters');
        return;
      }
      setS(() {
        fetchingGstin = true;
        fetchError = null;
        gstinError = null;
      });
      try {
        final response = await _apiClient.get(
          '/gst/taxpayer-details',
          queryParameters: {'gstin': gstin},
        );
        final data = response.data as Map<String, dynamic>;
        setS(() {
          legalNameCtrl.text = data['legalName'] ?? '';
          tradeNameCtrl.text = data['tradeName'] ?? '';
          registeredOnCtrl.text = data['registeredOn'] ?? '';
          if (data['registrationType'] != null) {
            regType = data['registrationType'] as String;
          }
          gstinCtrl.text = gstin;
          fetchingGstin = false;
        });
      } catch (e) {
        setS(() {
          fetchError = e.toString().replaceFirst('DioException [bad response]: ', '');
          fetchingGstin = false;
        });
      }
    }

    final result = await showDialog<_GstinData>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (dialogCtx, setS) {
          return Dialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        const Expanded(
                          child: Text(
                            'New GSTIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogCtx),
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
                          // GSTIN
                          _buildDialogRow(
                            label: 'GSTIN',
                            required: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: gstinCtrl,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: _dialogInputDecoration(
                                      'e.g. 27ABCDE1234F2Z5'),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary),
                                  onChanged: (_) =>
                                      setS(() => gstinError = null),
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
                                    if (fetchingGstin)
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 1.5),
                                      )
                                    else
                                      GestureDetector(
                                        onTap: () => fetchTaxpayerDetails(setS),
                                        child: const Text(
                                          'Get Taxpayer details',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.primaryBlue,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (fetchError != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    fetchError!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.errorRed,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space16),
                          // Registration Type
                          _buildDialogRow(
                            label: 'Registration Type',
                            child: FormDropdown<Map<String, String>>(
                              value: _kGstRegistrationTypes
                                  .where((t) => t['id'] == regType)
                                  .firstOrNull,
                              items: _kGstRegistrationTypes,
                              displayStringForValue: (t) => t['label'] ?? '',
                              hint: 'Select a Registration Type',
                              onChanged: (t) =>
                                  setS(() => regType = t?['id']),
                            ),
                          ),
                          const SizedBox(height: AppTheme.space16),
                          // Business Legal Name
                          _buildDialogRow(
                            label: 'Business Legal Name',
                            child: TextFormField(
                              controller: legalNameCtrl,
                              decoration:
                                  _dialogInputDecoration('Legal name'),
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.textPrimary),
                            ),
                          ),
                          const SizedBox(height: AppTheme.space16),
                          // Business Trade Name
                          _buildDialogRow(
                            label: 'Business Trade Name',
                            child: TextFormField(
                              controller: tradeNameCtrl,
                              decoration:
                                  _dialogInputDecoration('Trade name'),
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.textPrimary),
                            ),
                          ),
                          const SizedBox(height: AppTheme.space16),
                          // GST Registered On
                          _buildDialogRow(
                            label: 'GST Registered On',
                            child: TextFormField(
                              controller: registeredOnCtrl,
                              decoration:
                                  _dialogInputDecoration('dd-MM-yyyy'),
                              keyboardType: TextInputType.datetime,
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.textPrimary),
                            ),
                          ),
                          const SizedBox(height: AppTheme.space16),
                          // Reverse Charge
                          _buildDialogRow(
                            label: 'Reverse Charge',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: Checkbox(
                                        value: reverseCharge,
                                        onChanged: (v) => setS(
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
                                          color: AppTheme.textBody),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () {},
                                  child: const Text(
                                    'Know more',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryBlue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space16),
                          // Import / Export
                          _buildDialogRow(
                            label: 'Import / Export',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: Checkbox(
                                        value: importExport,
                                        onChanged: (v) => setS(
                                            () => importExport = v ?? false),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'My business is involved in SEZ / Overseas Trading',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textBody),
                                    ),
                                  ],
                                ),
                                if (importExport) ...[
                                  const SizedBox(height: 12),
                                  RichText(
                                    text: const TextSpan(
                                      text: 'Custom Duty Tracking Account',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.errorRed,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: ' *',
                                          style: TextStyle(
                                              color: AppTheme.errorRed),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  FormDropdown<_AccountOption>(
                                    value: _accounts
                                        .where((a) =>
                                            a.id == customDutyAccountId)
                                        .firstOrNull,
                                    items: _accounts,
                                    displayStringForValue: (a) => a.name,
                                    hint: 'Select an account',
                                    onChanged: (a) => setS(
                                        () => customDutyAccountId = a?.id),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'You can create a new account with type as Expense or Other Expense.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space16),
                          // Digital Services
                          _buildDialogRow(
                            label: 'Digital Services',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: Checkbox(
                                        value: digitalServices,
                                        onChanged: (v) => setS(
                                            () => digitalServices = v ?? false),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Track sale of digital services to overseas customers',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textBody),
                                    ),
                                  ],
                                ),
                                if (digitalServices)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      'If you disable this option, any digital service created by you will be considered as a service.',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary),
                                    ),
                                  )
                                else
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Enabling this option will let you record and track export of digital services to individuals.',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary),
                                    ),
                                  ),
                              ],
                            ),
                          ),
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
                          onPressed: () {
                            final g = gstinCtrl.text.trim().toUpperCase();
                            final gstinRegex = RegExp(
                              r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}Z[A-Z\d]{1}$',
                            );
                            if (g.isEmpty || !gstinRegex.hasMatch(g)) {
                              setS(() => gstinError =
                                  'Enter a valid 15-character GSTIN');
                              return;
                            }
                            Navigator.pop(
                              dialogCtx,
                              _GstinData(
                                gstin: g,
                                registrationType: regType,
                                legalName: legalNameCtrl.text.trim(),
                                tradeName: tradeNameCtrl.text.trim(),
                                registeredOn: registeredOnCtrl.text.trim(),
                                reverseCharge: reverseCharge,
                                importExport: importExport,
                                customDutyAccountId: customDutyAccountId,
                                digitalServices: digitalServices,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
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
                          onPressed: () => Navigator.pop(dialogCtx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            side:
                                const BorderSide(color: AppTheme.borderColor),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  fontSize: 13, color: AppTheme.textBody)),
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
    registeredOnCtrl.dispose();

    if (result != null) setState(() => _gstinData = result);
  }

  Widget _buildDialogRow({
    required String label,
    required Widget child,
    bool required = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 200,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: RichText(
              text: TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textBody,
                ),
                children: required
                    ? const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppTheme.errorRed),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: child),
      ],
    );
  }

  InputDecoration _dialogInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      isDense: true,
    );
  }

  Widget _buildParentDropdown({required bool required}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Parent Location', required: required),
        const SizedBox(height: AppTheme.space6),
        FormDropdown<_OutletOption>(
          value: _outlets.where((o) => o.id == _parentOutletId).firstOrNull,
          items: _outlets,
          displayStringForValue: (o) => o.name,
          hint: 'Select parent location',
          errorText: _parentError,
          onChanged: (o) => setState(() {
            _parentOutletId = o?.id;
            _parentError = null;
          }),
        ),
      ],
    );
  }

  // ─── Address section ───────────────────────────────────────────────────────

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Address'),
        const SizedBox(height: AppTheme.space12),
        _buildCard(
          children: [
            _buildTextField(
              label: 'Attention',
              controller: _attentionCtrl,
              hint: 'Attention',
            ),
            const SizedBox(height: AppTheme.space12),
            _buildTextField(
              label: 'Street 1',
              controller: _streetCtrl,
              hint: 'Street 1',
            ),
            const SizedBox(height: AppTheme.space12),
            _buildTextField(
              label: 'Street 2',
              controller: _street2Ctrl,
              hint: 'Street 2',
            ),
            const SizedBox(height: AppTheme.space12),
            _buildTextField(label: 'City', controller: _cityCtrl, hint: 'City'),
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('State / Union Territory'),
                      const SizedBox(height: AppTheme.space6),
                      FormDropdown<String>(
                        value: _selectedState,
                        items: _indianStates,
                        displayStringForValue: (s) => s,
                        hint: 'Select state',
                        onChanged: (v) => setState(() => _selectedState = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: _buildTextField(
                    label: 'Pin Code',
                    controller: _pincodeCtrl,
                    hint: '560001',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return null;
                      if (!RegExp(r'^\d{6}$').hasMatch(s)) {
                        return 'Enter a valid 6-digit pin code';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            _buildLabel('Country'),
            const SizedBox(height: AppTheme.space6),
            _buildStaticDropdown('India'),
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Phone',
                    controller: _phoneCtrl,
                    hint: '+91 98765 43210',
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return null;
                      final digits = s.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
                      if (!RegExp(r'^\d{7,15}$').hasMatch(digits)) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: _buildTextField(
                    label: 'Fax Number',
                    controller: _faxCtrl,
                    hint: 'Fax number',
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return null;
                      final digits = s.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
                      if (!RegExp(r'^\d{7,15}$').hasMatch(digits)) {
                        return 'Enter a valid fax number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ─── Bottom fields ─────────────────────────────────────────────────────────

  Widget _buildBottomFields() {
    return _buildCard(
      children: [
        _buildTextField(
          label: 'Website URL',
          controller: _websiteCtrl,
          hint: 'https://example.com',
          keyboardType: TextInputType.url,
          validator: (v) {
            final s = v?.trim() ?? '';
            if (s.isEmpty) return null;
            if (!RegExp(r'^https?://').hasMatch(s)) {
              return 'URL must start with http:// or https://';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ─── Transaction series (Business only) ────────────────────────────────────

  Widget _buildTransactionSeriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Transaction Number Series'),
        const SizedBox(height: AppTheme.space12),
        _buildCard(
          children: [
            // ── Transaction Number Series (multi-select) ───────────────
            _buildLabel('Transaction Number Series', required: true),
            const SizedBox(height: AppTheme.space6),
            _buildSeriesMultiSelect(),
            const SizedBox(height: AppTheme.space16),
            // ── Default Transaction Number Series (single select) ───────
            _buildLabel('Default Transaction Number Series', required: true),
            const SizedBox(height: AppTheme.space6),
            _buildDefaultSeriesSelect(),
          ],
        ),
      ],
    );
  }

  Widget _buildSeriesMultiSelect() {
    return GestureDetector(
      onTap: () => _showTransactionSeriesPickerDialog(isDefault: false),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: _selectedSeriesIds.isEmpty
                  ? const Text(
                      'Add Transaction Series',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    )
                  : Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final id in _selectedSeriesIds)
                          Builder(builder: (_) {
                            final s = _transactionSeries
                                .where((s) => s.id == id)
                                .firstOrNull;
                            if (s == null) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.bgLight,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: AppTheme.borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(s.name,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textPrimary)),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedSeriesIds.remove(id)),
                                    behavior: HitTestBehavior.opaque,
                                    child: const Icon(LucideIcons.x,
                                        size: 12,
                                        color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
            ),
            const Icon(LucideIcons.chevronDown,
                size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultSeriesSelect() {
    final selected = _transactionSeries
        .where((s) => s.id == _selectedDefaultSeriesId)
        .firstOrNull;

    return GestureDetector(
      onTap: () => _showTransactionSeriesPickerDialog(isDefault: true),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected?.name ?? 'Add Transaction Series',
                style: TextStyle(
                  fontSize: 13,
                  color: selected != null
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
              ),
            ),
            const Icon(LucideIcons.chevronDown,
                size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  // ─── Transaction series picker dialog ──────────────────────────────────────

  Future<void> _showTransactionSeriesPickerDialog({
    required bool isDefault,
  }) async {
    final accentColor = ref.read(appBrandingProvider).accentColor;
    String search = '';

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) {
          final filtered = _transactionSeries
              .where((s) =>
                  s.name.toLowerCase().contains(search.toLowerCase()))
              .toList();

          void selectSeries(_SeriesOption s) {
            if (isDefault) {
              setState(() => _selectedDefaultSeriesId = s.id);
              Navigator.pop(ctx2);
            } else {
              setState(() {
                if (!_selectedSeriesIds.contains(s.id)) {
                  _selectedSeriesIds.add(s.id);
                }
              });
            }
          }

          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      autofocus: true,
                      onChanged: (v) => setS(() => search = v),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(LucideIcons.search,
                            size: 14, color: AppTheme.textSecondary),
                        hintStyle: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide:
                              const BorderSide(color: AppTheme.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide:
                              const BorderSide(color: AppTheme.borderColor),
                        ),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  // List
                  Flexible(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: [
                        // Default Transaction Series (always first)
                        if (_transactionSeries.isNotEmpty &&
                            search.isEmpty) ...[
                          _buildSeriesPickerItem(
                            label: 'Default Transaction Series',
                            isHighlighted: true,
                            accentColor: accentColor,
                            isSelected: isDefault
                                ? _selectedDefaultSeriesId ==
                                    _transactionSeries.first.id
                                : _selectedSeriesIds
                                    .contains(_transactionSeries.first.id),
                            onTap: () =>
                                selectSeries(_transactionSeries.first),
                          ),
                        ],
                        // Other series
                        for (final s in filtered)
                          _buildSeriesPickerItem(
                            label: s.name,
                            isHighlighted: false,
                            accentColor: accentColor,
                            isSelected: isDefault
                                ? _selectedDefaultSeriesId == s.id
                                : _selectedSeriesIds.contains(s.id),
                            onTap: () => selectSeries(s),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.borderLight),
                  // Add Transaction Series
                  InkWell(
                    onTap: () async {
                      Navigator.pop(ctx2);
                      await _showCreateSeriesDialog();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(LucideIcons.plus,
                              size: 14, color: accentColor),
                          const SizedBox(width: 8),
                          Text(
                            'Add Transaction Series',
                            style: TextStyle(
                              fontSize: 13,
                              color: accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeriesPickerItem({
    required String label,
    required bool isHighlighted,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        color: isHighlighted ? accentColor : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isHighlighted ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.check,
                size: 14,
                color: isHighlighted ? Colors.white : accentColor,
              ),
          ],
        ),
      ),
    );
  }

  // ─── Create Transaction Series dialog ──────────────────────────────────────

  Future<void> _showCreateSeriesDialog() async {
    final nameCtrl = TextEditingController();
    String? nameError;

    // Create a row controller per module
    final rows = _kSeriesModules
        .map((m) => _SeriesModuleRow(
              prefix: m['prefix']!,
              starting: m['starting']!,
            ))
        .toList();

    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          String preview(int i) {
            final p = rows[i].prefixCtrl.text;
            final s = rows[i].startingCtrl.text;
            return '$p$s';
          }

          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Transaction Series Preferences',
                            style: TextStyle(
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
                  // Series Name
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 160,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: RichText(
                              text: const TextSpan(
                                text: 'Series Name',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.errorRed,
                                    fontWeight: FontWeight.w500),
                                children: [
                                  TextSpan(
                                    text: '*',
                                    style:
                                        TextStyle(color: AppTheme.errorRed),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: nameCtrl,
                                onChanged: (_) =>
                                    setS(() => nameError = null),
                                decoration: _dialogInputDecoration('').copyWith(
                                  errorText: nameError,
                                ),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Table
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Table header
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                      color: AppTheme.borderLight),
                                  bottom: BorderSide(
                                      color: AppTheme.borderLight),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 8),
                                      child: Text('MODULE',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textSecondary,
                                              letterSpacing: 0.5)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 8),
                                      child: Text('PREFIX',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textSecondary,
                                              letterSpacing: 0.5)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 8),
                                      child: Text('STARTING NUMBER',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textSecondary,
                                              letterSpacing: 0.5)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 8),
                                      child: Text('PREVIEW',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textSecondary,
                                              letterSpacing: 0.5)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Table rows
                            for (int i = 0; i < _kSeriesModules.length; i++)
                              Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                        color: AppTheme.borderLight),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Module name
                                    Expanded(
                                      flex: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 8),
                                        child: Text(
                                          _kSeriesModules[i]['label']!,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textPrimary),
                                        ),
                                      ),
                                    ),
                                    // Prefix
                                    Expanded(
                                      flex: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6, horizontal: 4),
                                        child: TextField(
                                          controller:
                                              rows[i].prefixCtrl,
                                          onChanged: (_) => setS(() {}),
                                          decoration:
                                              _dialogInputDecoration(''),
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textPrimary),
                                        ),
                                      ),
                                    ),
                                    // Starting Number
                                    Expanded(
                                      flex: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6, horizontal: 4),
                                        child: TextField(
                                          controller:
                                              rows[i].startingCtrl,
                                          onChanged: (_) => setS(() {}),
                                          keyboardType: TextInputType.number,
                                          decoration:
                                              _dialogInputDecoration(''),
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textPrimary),
                                        ),
                                      ),
                                    ),
                                    // Preview (read-only)
                                    Expanded(
                                      flex: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 8),
                                        child: Text(
                                          preview(i),
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textSecondary),
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
                  ),
                  const Divider(height: 1, color: AppTheme.borderLight),
                  // Footer
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final name = nameCtrl.text.trim();
                                  if (name.isEmpty) {
                                    setS(() => nameError =
                                        'Series name is required');
                                    return;
                                  }
                                  setS(() => isSaving = true);
                                  try {
                                    final user =
                                        ref.read(authUserProvider);
                                    final orgId =
                                        (user?.orgId.isNotEmpty == true)
                                            ? user!.orgId
                                            : _kDevOrgId;

                                    final modules = <Map<String, dynamic>>[];
                                    for (int i = 0;
                                        i < _kSeriesModules.length;
                                        i++) {
                                      modules.add({
                                        'module_key':
                                            _kSeriesModules[i]['key'],
                                        'prefix': rows[i]
                                            .prefixCtrl
                                            .text
                                            .trim(),
                                        'starting_number': rows[i]
                                            .startingCtrl
                                            .text
                                            .trim(),
                                      });
                                    }

                                    final res = await _apiClient.post(
                                      '/transaction-series',
                                      data: {
                                        'org_id': orgId,
                                        'name': name,
                                        'modules': modules,
                                      },
                                    );

                                    if (!mounted) return;

                                    if (res.success) {
                                      final newId = (res.data
                                              as Map<String, dynamic>?)?['id']
                                          ?.toString();
                                      setState(() {
                                        _transactionSeries.add(_SeriesOption(
                                          id: newId ?? name,
                                          name: name,
                                        ));
                                        if (newId != null) {
                                          _selectedSeriesIds.add(newId);
                                        }
                                      });
                                      if (mounted)
                                        Navigator.pop(ctx);
                                    } else {
                                      setS(() => isSaving = false);
                                      if (mounted) {
                                        ZerpaiToast.error(
                                          context,
                                          res.message ??
                                              'Failed to create series',
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    setS(() => isSaving = false);
                                    if (mounted) {
                                      ZerpaiToast.error(
                                          context, 'Failed to create series');
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                        Colors.white),
                                  ),
                                )
                              : const Text('Save',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () {
                            for (final r in rows) r.dispose();
                            Navigator.pop(ctx);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            side: const BorderSide(
                                color: AppTheme.borderColor),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  fontSize: 13, color: AppTheme.textBody)),
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

    nameCtrl.dispose();
    for (final r in rows) r.dispose();
  }

  // ─── Location access ────────────────────────────────────────────────────────

  Widget _buildLocationAccessSection() {
    final accentColor = ref.watch(appBrandingProvider).accentColor;
    final int count = _locationUsers.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Location Access'),
        const SizedBox(height: AppTheme.space12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: count > 0 ? accentColor : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            count > 0
                                ? '$count user${count == 1 ? '' : 's'} selected'
                                : 'No users selected',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: count > 0
                                  ? accentColor
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            count > 0
                                ? 'Selected users can create and access transactions for this location.'
                                : 'Select the users who can create and access transactions for this location.',
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

              // Column headers
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
                  ],
                ),
              ),

              // User rows
              for (final user in _locationUsers)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                    vertical: AppTheme.space12,
                  ),
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: AppTheme.borderLight)),
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
                          user['role'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textBody,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() =>
                            _locationUsers.removeWhere(
                                (u) => u['userId'] == user['userId'])),
                        icon: const Icon(LucideIcons.x, size: 14),
                        color: AppTheme.textSecondary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

              // Add user row (placeholder)
              Padding(
                padding: const EdgeInsets.all(AppTheme.space12),
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ZerpaiToast.info(context, 'User assignment coming soon'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space16,
                      vertical: AppTheme.space10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  icon: const Icon(LucideIcons.userPlus, size: 14),
                  label: const Text(
                    'Add User',
                    style: TextStyle(fontSize: 13, color: AppTheme.textBody),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Shared helpers ────────────────────────────────────────────────────────

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppTheme.textBody,
        ),
        children: required
            ? const <TextSpan>[
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildStaticDropdown(String value) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
          const Icon(
            LucideIcons.chevronDown,
            size: 14,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        const SizedBox(height: AppTheme.space6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space12,
              vertical: AppTheme.space10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildActions() {
    final accentColor = ref.watch(appBrandingProvider).accentColor;
    return Row(
      children: [
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space28,
              vertical: AppTheme.space12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _isEditing ? 'Update' : 'Save',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        const SizedBox(width: AppTheme.space12),
        OutlinedButton(
          onPressed: () => context.go(AppRoutes.settingsLocations),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space24,
              vertical: AppTheme.space12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textBody,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
