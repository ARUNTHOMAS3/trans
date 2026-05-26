// ignore_for_file: unused_element, unused_field

import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/services/storage_service.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/transaction_series_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_builders.dart';
import 'package:zerpai_erp/shared/widgets/form_row.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/phone_input_field.dart';
import 'package:zerpai_erp/shared/widgets/settings_fixed_header_layout.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';


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

// ─── Data classes ─────────────────────────────────────────────────────────────

class _SeriesOption {
  final String id;
  final String name;
  const _SeriesOption({required this.id, required this.name});
}

class _StateOption {
  final String id;
  final String name;
  final String? code;
  const _StateOption({required this.id, required this.name, this.code});
}

class _DistrictOption {
  final String id;
  final String name;
  const _DistrictOption({required this.id, required this.name});
}

class _LocalBodyOption {
  final String id;
  final String name;
  final String bodyType;
  const _LocalBodyOption({
    required this.id,
    required this.name,
    required this.bodyType,
  });
}

class _AssemblyOption {
  final String code;
  final String name;
  const _AssemblyOption({required this.code, required this.name});
}

class _WardOption {
  final String id;
  final int? wardNo;
  final String name;
  final String displayName;
  const _WardOption({
    required this.id,
    this.wardNo,
    required this.name,
    required this.displayName,
  });
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

  // ── Text controllers ──────────────────────────────────────────────────────
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _branchCodeCtrl = TextEditingController();
  bool _branchCodeManualOverride = false;
  String _branchCodePrefix = 'BR-';
  int _branchCodeNextNumber = 1;
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  String _phonePrefix = '+91';
  final TextEditingController _websiteCtrl = TextEditingController();
  final TextEditingController _attentionCtrl = TextEditingController();
  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _street2Ctrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();
  final TextEditingController _panCtrl = TextEditingController();

  // ─── Payment Stub Address & Branch Settings ──────────────────────────────────
  String? _selectedFiscalYear;
  String _reportBasis = 'accrual';
  bool _hasSeparatePaymentStubAddress = false;

  final TextEditingController _paymentStubAttentionController =
      TextEditingController();
  final TextEditingController _paymentStubStreet1Controller =
      TextEditingController();
  final TextEditingController _paymentStubStreet2Controller =
      TextEditingController();
  final TextEditingController _paymentStubCityController =
      TextEditingController();
  final TextEditingController _paymentStubPincodeController =
      TextEditingController();
  final TextEditingController _paymentStubPhoneController =
      TextEditingController();
  String _paymentStubPhonePrefix = '+91';

  List<_StateOption> _paymentStubStateLookupRows = [];
  String? _selectedPaymentStubState;
  List<_DistrictOption> _paymentStubDistrictOptions = [];
  String? _selectedPaymentStubDistrictId;
  List<_LocalBodyOption> _paymentStubAllLocalBodyOptions = [];
  List<_LocalBodyOption> _paymentStubLocalBodyOptions = [];
  String? _selectedPaymentStubLocalBodyType;
  String? _selectedPaymentStubLocalBodyId;
  List<_AssemblyOption> _paymentStubAssemblyOptions = [];
  String? _selectedPaymentStubAssemblyCode;
  List<_WardOption> _paymentStubWardOptions = [];
  String? _selectedPaymentStubWardId;

  List<String> get _paymentStubAvailableLocalBodyTypeOptions {
    final seen = <String>{};
    return _paymentStubAllLocalBodyOptions
        .map((localBody) => localBody.bodyType.trim())
        .where((bodyType) => bodyType.isNotEmpty && seen.add(bodyType))
        .toList();
  }

  String? _normalizeIndiaPhoneToTenDigits(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final cleaned = raw.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) return cleaned;
    if (cleaned.length == 11 && cleaned.startsWith('0')) {
      return cleaned.substring(1);
    }
    if (cleaned.length == 12 && cleaned.startsWith('91')) {
      return cleaned.substring(2);
    }
    return cleaned.length > 10 ? cleaned.substring(cleaned.length - 10) : cleaned;
  }

  // ─── LSGD Lookups for Payment Stub ──────────────────────────────────────────

  Future<void> _loadPaymentStubStates() async {
    if (_paymentStubStateLookupRows.isNotEmpty) return;
    try {
      final res = await _apiClient.get('lookups/states');
      if (res.success && res.data is List) {
        if (!mounted) return;
        setState(() {
          _paymentStubStateLookupRows = (res.data as List)
              .whereType<Map<String, dynamic>>()
              .map(
                (s) => _StateOption(
                  id: (s['id'] ?? '').toString(),
                  name: (s['name'] ?? '').toString(),
                ),
              )
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadDistrictsForSelectedPaymentStubState() async {
    if (_selectedPaymentStubState == null) return;
    try {
      final stateRow = _paymentStubStateLookupRows.firstWhere(
        (s) => s.name == _selectedPaymentStubState,
        orElse: () => const _StateOption(id: '', name: ''),
      );
      if (stateRow.id.isEmpty) return;

      final res = await _apiClient.get(
        'lookups/districts',
        queryParameters: {'stateId': stateRow.id},
      );
      if (res.success && res.data is List) {
        if (!mounted) return;
        setState(() {
          _paymentStubDistrictOptions = (res.data as List)
              .whereType<Map<String, dynamic>>()
              .map(
                (d) => _DistrictOption(
                  id: (d['id'] ?? '').toString(),
                  name: (d['name'] ?? '').toString(),
                ),
              )
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadLocalBodiesForSelectedPaymentStubDistrict(
    String districtId,
  ) async {
    try {
      final res = await _apiClient.get(
        'lookups/local-bodies',
        queryParameters: {'districtId': districtId},
      );
      if (res.success && res.data is List) {
        if (!mounted) return;
        setState(() {
          _paymentStubAllLocalBodyOptions = (res.data as List)
              .whereType<Map<String, dynamic>>()
              .map(
                (lb) => _LocalBodyOption(
                  id: (lb['id'] ?? '').toString(),
                  name: (lb['name'] ?? '').toString(),
                  bodyType: (lb['body_type'] ?? '').toString(),
                ),
              )
              .toList();

          // Apply type filter if any
          if (_selectedPaymentStubLocalBodyType != null &&
              _selectedPaymentStubLocalBodyType!.isNotEmpty) {
            _paymentStubLocalBodyOptions = _paymentStubAllLocalBodyOptions
                .where(
                  (lb) =>
                      lb.bodyType.toLowerCase() ==
                      _selectedPaymentStubLocalBodyType!.toLowerCase(),
                )
                .toList();
          } else {
            _paymentStubLocalBodyOptions = _paymentStubAllLocalBodyOptions;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAssembliesForSelectedPaymentStubDistrict() async {
    if (_selectedPaymentStubDistrictId == null ||
        _selectedPaymentStubDistrictId!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _paymentStubAssemblyOptions = [];
        _selectedPaymentStubAssemblyCode = null;
      });
      return;
    }
    try {
      final res = await _apiClient.get(
        'lookups/assemblies',
        queryParameters: {'districtId': _selectedPaymentStubDistrictId},
      );
      if (res.success && res.data is List) {
        final assemblies = (res.data as List)
            .whereType<Map<String, dynamic>>()
            .map(
              (assembly) => _AssemblyOption(
                code: ((assembly['code'] ?? assembly['name']) ?? '').toString(),
                name: (assembly['name'] ?? '').toString(),
              ),
            )
            .where(
              (assembly) =>
                  assembly.code.isNotEmpty && assembly.name.isNotEmpty,
            )
            .toList();
        if (!mounted) return;
        setState(() {
          _paymentStubAssemblyOptions = assemblies;
          if (_selectedPaymentStubAssemblyCode != null &&
              !assemblies.any(
                (assembly) =>
                    assembly.code == _selectedPaymentStubAssemblyCode ||
                    assembly.name == _selectedPaymentStubAssemblyCode,
              )) {
            _selectedPaymentStubAssemblyCode = null;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadWardsForSelectedPaymentStubLocalBody() async {
    if (_selectedPaymentStubLocalBodyId == null) return;
    try {
      final res = await _apiClient.get(
        'lookups/wards',
        queryParameters: {'localBodyId': _selectedPaymentStubLocalBodyId},
      );
      if (res.success && res.data is List) {
        if (!mounted) return;
        setState(() {
          _paymentStubWardOptions = (res.data as List)
              .whereType<Map<String, dynamic>>()
              .map(
                (w) => _WardOption(
                  id: (w['id'] ?? '').toString(),
                  wardNo: int.tryParse(w['ward_no']?.toString() ?? ''),
                  name: (w['name'] ?? '').toString(),
                  displayName: (w['display_name'] ?? '').toString(),
                ),
              )
              .toList();
        });
      }
    } catch (_) {}
  }

  // ── Dropdown state ────────────────────────────────────────────────────────
  String? _selectedState;
  String? _selectedBusinessType;
  String? _selectedIndustry;
  List<String> _industryOptions = [];
  List<Map<String, String>> _businessTypes = [];
  List<Map<String, String>> _gstTreatmentOptions = [];
  List<Map<String, String>> _gstRegistrationTypeOptions = [];
  List<Map<String, String>> _drugLicenceTypeOptions = [];
  List<Map<String, String>> _fiscalYearOptions = [];
  List<Map<String, String>> _transactionModuleOptions = [];
  List<Map<String, String>> _transactionPrefixPlaceholders = [];
  List<Map<String, String>> _transactionRestartOptions = [];
  String? _gstTreatment;

  // Regulatory Compliance
  bool _isDrugRegistered = false;
  String? _selectedDrugLicenceType;
  final TextEditingController _drugLicence20Ctrl = TextEditingController();
  final TextEditingController _drugLicence21Ctrl = TextEditingController();
  final TextEditingController _drugLicence20BCtrl = TextEditingController();
  final TextEditingController _drugLicence21BCtrl = TextEditingController();
  List<PlatformFile> _drugLic20Docs = [];
  List<PlatformFile> _drugLic21Docs = [];
  List<PlatformFile> _drugLic20BDocs = [];
  List<PlatformFile> _drugLic21BDocs = [];
  bool _isFssaiRegistered = false;
  final TextEditingController _fssaiNumberCtrl = TextEditingController();
  List<PlatformFile> _fssaiDocs = [];
  bool _isMsmeRegistered = false;
  String? _selectedMsmeType;
  final TextEditingController _msmeNumberCtrl = TextEditingController();
  List<PlatformFile> _msmeDocs = [];
  String _orgCountry = 'India';
  List<_StateOption> _stateLookupRows = [];
  List<String> _stateOptions = [];
  List<_DistrictOption> _districtOptions = [];
  String? _selectedDistrictId;
  List<_LocalBodyOption> _allLocalBodyOptions = [];
  List<_LocalBodyOption> _localBodyOptions = [];
  String? _selectedLocalBodyType;
  String? _selectedLocalBodyId;
  List<_AssemblyOption> _assemblyOptions = [];
  String? _selectedAssemblyId;

  List<_WardOption> _wardOptions = [];
  String? _selectedWardId;

  // ── Child location ────────────────────────────────────────────────────────
  bool _isChildLocation = false;
  String? _parentBranchId;

  List<Map<String, dynamic>> _availableBranches = [];

  bool _isMasterBranch(Map<String, dynamic> branch) {
    final dynamic flag =
        branch['is_master_branch'] ?? branch['is_master'] ?? branch['master_branch'];
    if (flag is bool) return flag;
    final normalized = flag?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  String _branchBusinessTypeGroupLabel(Map<String, dynamic> branch) {
    final branchTypeId = branch['branch_type']?.toString().trim();
    if (branchTypeId == null || branchTypeId.isEmpty) {
      return 'OTHER';
    }

    final match = _businessTypes.firstWhere(
      (type) => type['id'] == branchTypeId,
      orElse: () => <String, String>{},
    );
    final code = (match['code'] ?? '').trim();

    if (code.isNotEmpty) return code.toUpperCase();
    return branchTypeId.toUpperCase();
  }

  String _branchName(Map<String, dynamic> branch) =>
      (branch['name'] ?? branch['branch_name'] ?? '').toString().trim();

  List<String> get _associatedBranchDropdownItems {
    final masterBranches = _availableBranches
        .where(_isMasterBranch)
        .toList()
      ..sort(
        (a, b) => _branchName(a).toLowerCase().compareTo(_branchName(b).toLowerCase()),
      );

    final nonMasterBranches = _availableBranches
        .where((branch) => !_isMasterBranch(branch))
        .toList();

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final branch in nonMasterBranches) {
      final label = _branchBusinessTypeGroupLabel(branch);
      grouped.putIfAbsent(label, () => <Map<String, dynamic>>[]).add(branch);
    }

    final sortedGroupLabels = grouped.keys.toList()..sort(
      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );

    final ordered = <String>[
      ...masterBranches.map((branch) => branch['id'].toString()),
    ];

    for (final groupLabel in sortedGroupLabels) {
      final branches = grouped[groupLabel]!
        ..sort(
          (a, b) =>
              _branchName(a).toLowerCase().compareTo(_branchName(b).toLowerCase()),
        );
      ordered.addAll(branches.map((branch) => branch['id'].toString()));
    }

    return ordered;
  }

  Map<String, dynamic>? _findAvailableBranchById(String id) {
    for (final branch in _availableBranches) {
      if (branch['id']?.toString() == id) return branch;
    }
    return null;
  }

  String _associatedBranchGroupLabelForId(String id) {
    final branch = _findAvailableBranchById(id);
    if (branch == null) return 'Other Business Types';
    return _isMasterBranch(branch)
        ? 'Master Branch'
        : _branchBusinessTypeGroupLabel(branch);
  }

  bool _isFirstAssociatedBranchInGroup(String id) {
    final items = _associatedBranchDropdownItems;
    final index = items.indexOf(id);
    if (index <= 0) return index == 0;
    return _associatedBranchGroupLabelForId(items[index - 1]) !=
        _associatedBranchGroupLabelForId(id);
  }

  // ── Subscription ──────────────────────────────────────────────────────────
  DateTime? _subscriptionFrom;
  DateTime? _subscriptionTo;
  final GlobalKey _subFromKey = GlobalKey();
  final GlobalKey _subToKey = GlobalKey();

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

  List<TransactionSeriesOption> get _transactionSeriesOptions =>
      _transactionSeries
          .map(
            (series) =>
                TransactionSeriesOption(id: series.id, name: series.name),
          )
          .toList();

  bool get _isPharmacyIndustry =>
      (_selectedIndustry ?? '').trim().toLowerCase() == 'pharmacy';

  bool get _showPaymentStubLsgdFields =>
      _selectedPaymentStubState?.toLowerCase() == 'kerala';

  bool get _showMainAddressLsgdFields =>
      (_selectedState ?? '').trim().toLowerCase() == 'kerala';

  List<String> get _availableLocalBodyTypeOptions {
    final seen = <String>{};
    return _allLocalBodyOptions
        .map((localBody) => localBody.bodyType.trim())
        .where((bodyType) => bodyType.isNotEmpty && seen.add(bodyType))
        .toList();
  }

  // ── Misc ──────────────────────────────────────────────────────────────────
  bool _isSaving = false;
  bool _isLoading = false;
  bool _showValidationErrors = false;
  String _branchSystemId = '';
  String _organizationName = '';
  final Set<String> _expandedBlocks = <String>{'Organization'};

  bool get _isEditing => widget.branchId != null;

  String _formatUserRoleLabel(String? role) {
    final r = (role ?? '').trim();
    if (r.isEmpty) return 'User\'s Role';

    final low = r.toLowerCase();
    switch (low) {
      case 'admin':
        return 'Admin';
      case 'ho_admin':
      case 'ho admin':
        return 'HO Admin';
      case 'branch_admin':
      case 'branch admin':
        return 'Branch Admin';
      case 'branch staff':
      case 'branch_staff':
        return 'Branch Staff';
      default:
        // If it's a UUID, it means the label resolution failed or it's a raw ID
        return r;
    }
  }

  String? _matchLookupCode(
    String? rawValue,
    List<Map<String, String>> options, {
    String codeKey = 'code',
    String labelKey = 'label',
  }) {
    final value = rawValue?.trim();
    if (value == null || value.isEmpty) return null;
    for (final option in options) {
      final code = option[codeKey]?.trim();
      final label = option[labelKey]?.trim();
      if (code == value || label == value) {
        return code ?? label;
      }
    }
    return null;
  }

  String _displayLookupLabel(
    String? code,
    List<Map<String, String>> options, {
    String codeKey = 'code',
    String labelKey = 'label',
  }) {
    if (code == null || code.isEmpty) return '';
    for (final option in options) {
      if (option[codeKey] == code) {
        return option[labelKey] ?? code;
      }
    }
    return code;
  }

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = '';
    _syncBranchCodeFromPreferences();
    _bootstrap();
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
    _paymentStubAttentionController.dispose();
    _paymentStubStreet1Controller.dispose();
    _paymentStubStreet2Controller.dispose();
    _paymentStubCityController.dispose();
    _paymentStubPincodeController.dispose();
    _paymentStubPhoneController.dispose();
    _drugLicence20Ctrl.dispose();
    _drugLicence21Ctrl.dispose();
    _fssaiNumberCtrl.dispose();
    _msmeNumberCtrl.dispose();
    _drugLicence20BCtrl.dispose();
    _drugLicence21BCtrl.dispose();
    super.dispose();
  }

  // ─── Data loading ──────────────────────────────────────────────────────────

  String _formatGeneratedBranchCode() {
    final prefix = _branchCodePrefix.trim();
    final nextNumber = _branchCodeNextNumber < 1 ? 1 : _branchCodeNextNumber;
    return '$prefix${nextNumber.toString().padLeft(5, '0')}';
  }

  void _syncBranchCodeFromPreferences() {
    if (_isEditing || _branchCodeManualOverride) return;
    _branchCodeCtrl.text = _formatGeneratedBranchCode();
  }

  void _hydrateBranchCodePreferences(String rawCode) {
    final code = rawCode.trim();
    if (code.isEmpty) return;

    final match = RegExp(r'^(.*?)(\d+)$').firstMatch(code);
    if (match == null) return;

    final parsedPrefix = match.group(1)?.trim();
    final parsedNext = int.tryParse(match.group(2) ?? '');
    if (parsedPrefix != null && parsedPrefix.isNotEmpty) {
      _branchCodePrefix = parsedPrefix;
    }
    if (parsedNext != null && parsedNext > 0) {
      _branchCodeNextNumber = parsedNext;
    }
  }

  void _resetPharmacyComplianceFields() {
    _isDrugRegistered = false;
    _selectedDrugLicenceType = null;
    _drugLicence20Ctrl.clear();
    _drugLicence21Ctrl.clear();
    _drugLicence20BCtrl.clear();
    _drugLicence21BCtrl.clear();
    _drugLic20Docs = [];
    _drugLic21Docs = [];
    _drugLic20BDocs = [];
    _drugLic21BDocs = [];
    _isFssaiRegistered = false;
    _fssaiNumberCtrl.clear();
    _fssaiDocs = [];
    _isMsmeRegistered = false;
    _selectedMsmeType = null;
    _msmeNumberCtrl.clear();
    _msmeDocs = [];
  }

  Future<void> _bootstrap() async {
    await _loadOrgName();
    if (!mounted) return;
    await Future.wait<void>([
      _loadTransactionSeries(),
      _loadOrgBranchData(),
      _loadOrgUsers(),
      _loadLookups(),
    ]);
    if (!mounted) return;
    if (_isEditing) {
      await _loadExisting();
    }
  }

  Future<void> _loadStatesForCountry(String countryName) async {
    final isIndia = countryName.toLowerCase() == 'india';
    final List<_StateOption> loadedStates = <_StateOption>[];

    try {
      if (isIndia) {
        final statesRes = await _apiClient.get('lookups/states/IN');
        if (statesRes.success && statesRes.data is List) {
          loadedStates.addAll(
            (statesRes.data as List)
                .whereType<Map<String, dynamic>>()
                .map(
                  (state) => _StateOption(
                    id: (state['id'] ?? '').toString(),
                    name: (state['name'] ?? '').toString(),
                    code: state['code']?.toString(),
                  ),
                )
                .where((state) => state.name.isNotEmpty),
          );
        }
      } else if (countryName.isNotEmpty) {
        final countriesRes = await _apiClient.get('lookups/countries');
        if (countriesRes.success && countriesRes.data is List) {
          final match = (countriesRes.data as List)
              .whereType<Map<String, dynamic>>()
              .firstWhere(
                (country) =>
                    (country['name'] ?? '').toString().toLowerCase() ==
                    countryName.toLowerCase(),
                orElse: () => <String, dynamic>{},
              );
          final countryId = (match['id'] ?? '').toString();
          if (countryId.isNotEmpty) {
            final statesRes = await _apiClient.get(
              'lookups/states',
              queryParameters: <String, dynamic>{'countryId': countryId},
            );
            if (statesRes.success && statesRes.data is List) {
              loadedStates.addAll(
                (statesRes.data as List)
                    .whereType<Map<String, dynamic>>()
                    .map(
                      (state) => _StateOption(
                        id: (state['id'] ?? '').toString(),
                        name: (state['name'] ?? '').toString(),
                        code: state['code']?.toString(),
                      ),
                    )
                    .where((state) => state.name.isNotEmpty),
              );
            }
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _stateLookupRows = loadedStates;
      _stateOptions = loadedStates.isNotEmpty
          ? loadedStates.map((state) => state.name).toList()
          : <String>[];
    });
  }

  Future<void> _loadDistrictsForSelectedState() async {
    final selectedState = _selectedState;
    if (selectedState == null || selectedState.isEmpty) return;

    final stateRow = _stateLookupRows.firstWhere(
      (state) => state.name == selectedState,
      orElse: () => const _StateOption(id: '', name: ''),
    );
    if (stateRow.id.isEmpty) return;

    try {
      final res = await _apiClient.get(
        'lookups/districts',
        queryParameters: {'stateId': stateRow.id},
      );
      if (!mounted) return;
      if (res.success && res.data is List) {
        setState(() {
          _districtOptions = (res.data as List)
              .whereType<Map<String, dynamic>>()
              .map(
                (district) => _DistrictOption(
                  id: (district['id'] ?? '').toString(),
                  name: (district['name'] ?? '').toString(),
                ),
              )
              .where((district) => district.id.isNotEmpty)
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadLocalBodiesForSelectedDistrict(String districtId) async {
    try {
      final res = await _apiClient.get(
        'lookups/local-bodies',
        queryParameters: {'districtId': districtId},
      );
      if (!mounted) return;
      if (res.success && res.data is List) {
        final allLocalBodies = (res.data as List)
            .whereType<Map<String, dynamic>>()
            .map(
              (localBody) => _LocalBodyOption(
                id: (localBody['id'] ?? '').toString(),
                name: (localBody['name'] ?? '').toString(),
                bodyType: (localBody['body_type'] ?? '').toString(),
              ),
            )
            .where((localBody) => localBody.id.isNotEmpty)
            .toList();
        setState(() {
          _allLocalBodyOptions = allLocalBodies;
          _localBodyOptions =
              _selectedLocalBodyType == null || _selectedLocalBodyType!.isEmpty
              ? allLocalBodies
              : allLocalBodies
                    .where(
                      (localBody) =>
                          localBody.bodyType.toLowerCase() ==
                          _selectedLocalBodyType!.toLowerCase(),
                    )
                    .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadWardsForSelectedLocalBody() async {
    final localBodyId = _selectedLocalBodyId;
    if (localBodyId == null || localBodyId.isEmpty) return;

    try {
      final res = await _apiClient.get(
        'lookups/wards',
        queryParameters: {'localBodyId': localBodyId},
      );
      if (!mounted) return;
      if (res.success && res.data is List) {
        setState(() {
          _wardOptions = (res.data as List)
              .whereType<Map<String, dynamic>>()
              .map(
                (ward) => _WardOption(
                  id: (ward['id'] ?? '').toString(),
                  wardNo: int.tryParse(ward['ward_no']?.toString() ?? ''),
                  name: (ward['name'] ?? '').toString(),
                  displayName: (ward['display_name'] ?? '').toString(),
                ),
              )
              .where((ward) => ward.id.isNotEmpty)
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAssembliesForSelectedDistrict() async {
    final districtId = _selectedDistrictId;
    if (districtId == null || districtId.isEmpty) return;

    try {
      final res = await _apiClient.get(
        'lookups/assemblies',
        queryParameters: {'districtId': districtId},
      );
      if (!mounted) return;
      if (res.success && res.data is List) {
        setState(() {
          _assemblyOptions = (res.data as List)
              .whereType<Map<String, dynamic>>()
              .map(
                (assembly) => _AssemblyOption(
                  code: (assembly['id'] ?? '').toString(),
                  name: (assembly['name'] ?? '').toString(),
                ),
              )
              .where((assembly) => assembly.code.isNotEmpty)
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadOrgName() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : '';
      final res = await _apiClient.get('lookups/org/$orgId');
      if (!mounted) return;

      String orgCountry = 'India';
      String orgName = user?.orgName ?? '';
      String? preferredState;

      if (res.success && res.data is Map<String, dynamic>) {
        final orgData = res.data as Map<String, dynamic>;
        orgName = ((orgData['name'] ?? user?.orgName ?? '')).toString().trim();
        final countryName = (orgData['country'] ?? '').toString().trim();
        orgCountry = countryName.isNotEmpty ? countryName : 'India';
        preferredState = (orgData['state_name'] ?? orgData['state'] ?? '')
            .toString()
            .trim();
      }

      await _loadStatesForCountry(orgCountry);
      if (!mounted) return;
      String? nextSelectedState;
      setState(() {
        _organizationName = orgName;
        _orgCountry = orgCountry;
        if (!_isEditing &&
            preferredState != null &&
            preferredState.isNotEmpty &&
            _stateOptions.any(
              (state) => state.toLowerCase() == preferredState!.toLowerCase(),
            )) {
          nextSelectedState = _stateOptions.firstWhere(
            (state) => state.toLowerCase() == preferredState!.toLowerCase(),
          );
          _selectedState = nextSelectedState;
        }
      });
    } catch (_) {}
  }

  Future<void> _loadTransactionSeries() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : '';
      final res = await _apiClient.get(
        'transaction-series',
        queryParameters: {'org_id': orgId},
      );
      if (!mounted) return;
      if (res.success && res.data is List) {
        setState(() {
          _transactionSeries = (res.data as List)
              .cast<Map<String, dynamic>>()
              .map(
                (s) => _SeriesOption(
                  id: s['id'].toString(),
                  name: (s['name'] ?? s['series_name'] ?? '').toString(),
                ),
              )
              .toList();
        });
      }
    } catch (_) {}
  }

  /// Loads branches for parent-branch selector and collects org-level GSTINs.
  Future<void> _loadOrgBranchData() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : '';
      final res = await _apiClient.get(
        'branches',
        queryParameters: {'org_id': orgId},
      );
      if (!mounted) return;
      if (res.success && res.data is List) {
        final all = (res.data as List).cast<Map<String, dynamic>>();
        final gstins = all
            .map((b) => (b['gstin'] ?? '').toString().trim())
            .where((g) => g.isNotEmpty)
            .toSet()
            .toList();

        // Derive next branch code number from highest existing code
        int maxCodeNumber = 0;
        String? detectedPrefix;
        final codeRx = RegExp(r'^(.*?)(\d+)$');
        for (final b in all) {
          final code = (b['branch_code'] ?? '').toString().trim();
          final m = codeRx.firstMatch(code);
          if (m != null) {
            final n = int.tryParse(m.group(2) ?? '') ?? 0;
            if (n > maxCodeNumber) {
              maxCodeNumber = n;
              detectedPrefix = m.group(1);
            }
          }
        }

        setState(() {
          _availableBranches = all
              .where((b) => b['id']?.toString() != widget.branchId)
              .toList();
          _orgGstins = gstins;
          if (!_isEditing && !_branchCodeManualOverride && maxCodeNumber > 0) {
            if (detectedPrefix != null && detectedPrefix.isNotEmpty) {
              _branchCodePrefix = detectedPrefix;
            }
            _branchCodeNextNumber = maxCodeNumber + 1;
            _branchCodeCtrl.text = _formatGeneratedBranchCode();
          }
        });
      }
    } catch (_) {}
  }

  /// Loads org users for the Primary Contact selector.
  Future<void> _loadOrgUsers() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : '';
      final res = await _apiClient.get(
        'users',
        queryParameters: {'org_id': orgId},
      );
      if (!mounted) return;
      if (res.success && res.data is List) {
        final assignableUsers = (res.data as List)
            .whereType<Map<String, dynamic>>()
            .map((row) {
              final publicUserId = (row['public_user_id'] ?? '').toString();
              if (publicUserId.isEmpty) return null;
              return <String, dynamic>{
                ...row,
                'id': publicUserId,
              };
            })
            .whereType<Map<String, dynamic>>()
            .toList();
        setState(
          () => _orgUsers = assignableUsers,
        );
      }
    } catch (_) {}
  }

  Future<void> _loadLookups() async {
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : '';
      final results = await Future.wait([
        _apiClient.get('lookups/industries', useCache: true),
        _apiClient.get(
          'branches/business-types',
          queryParameters: {'org_id': orgId},
          useCache: true,
        ),
        _apiClient.get('lookups/gst-treatments', useCache: true),
        _apiClient.get('lookups/gst-registration-types', useCache: true),
        _apiClient.get('lookups/drug-licence-types', useCache: true),
        _apiClient.get('lookups/fiscal-year-presets', useCache: true),
        _apiClient.get('lookups/transaction-modules', useCache: true),
        _apiClient.get('lookups/transaction-restart-options', useCache: true),
        _apiClient.get(
          'lookups/transaction-prefix-placeholders',
          useCache: true,
        ),
        _apiClient.get('lookups/org/$orgId', useCache: true),
      ]);
      if (!mounted) return;
      final indRes = results[0];
      final businessTypeRes = results[1];
      final gstTreatmentRes = results[2];
      final gstRegistrationTypeRes = results[3];
      final drugLicenceTypeRes = results[4];
      final fiscalYearRes = results[5];
      final transactionModuleRes = results[6];
      final transactionRestartRes = results[7];
      final transactionPlaceholderRes = results[8];
      final orgRes = results[9];
      setState(() {
        if (indRes.success && indRes.data is List) {
          _industryOptions = (indRes.data as List)
              .map((e) => e.toString())
              .toList();
        }
        if (businessTypeRes.success && businessTypeRes.data is List) {
          _businessTypes = (businessTypeRes.data as List)
              .whereType<Map>()
              .map(
                (item) => <String, String>{
                  'id': (item['code'] ?? '').toString(),
                  'code': (item['code'] ?? '').toString(),
                  'label': (item['label'] ?? '').toString(),
                },
              )
              .where((item) => item['code']!.isNotEmpty)
              .toList();
        }
        if (gstTreatmentRes.success && gstTreatmentRes.data is List) {
          _gstTreatmentOptions = (gstTreatmentRes.data as List)
              .whereType<Map>()
              .map(
                (item) => <String, String>{
                  'code': (item['code'] ?? '').toString(),
                  'label': (item['label'] ?? '').toString(),
                },
              )
              .where((item) => item['code']!.isNotEmpty)
              .toList();
        }
        if (gstRegistrationTypeRes.success &&
            gstRegistrationTypeRes.data is List) {
          _gstRegistrationTypeOptions = (gstRegistrationTypeRes.data as List)
              .whereType<Map>()
              .map(
                (item) => <String, String>{
                  'code': (item['code'] ?? '').toString(),
                  'label': (item['label'] ?? '').toString(),
                },
              )
              .where((item) => item['code']!.isNotEmpty)
              .toList();
        }
        if (drugLicenceTypeRes.success && drugLicenceTypeRes.data is List) {
          _drugLicenceTypeOptions = (drugLicenceTypeRes.data as List)
              .whereType<Map>()
              .map(
                (item) => <String, String>{
                  'code': (item['code'] ?? '').toString(),
                  'label': (item['label'] ?? '').toString(),
                },
              )
              .where((item) => item['code']!.isNotEmpty)
              .toList();
        }
        if (fiscalYearRes.success && fiscalYearRes.data is List) {
          _fiscalYearOptions = (fiscalYearRes.data as List)
              .whereType<Map>()
              .map(
                (item) => <String, String>{
                  'code': (item['code'] ?? '').toString(),
                  'label': (item['label'] ?? '').toString(),
                },
              )
              .where((item) => item['code']!.isNotEmpty)
              .toList();
        }
        if (transactionModuleRes.success && transactionModuleRes.data is List) {
          _transactionModuleOptions = (transactionModuleRes.data as List)
              .whereType<Map>()
              .map(
                (item) => <String, String>{
                  'id': (item['code'] ?? '').toString(),
                  'label': (item['label'] ?? '').toString(),
                },
              )
              .where((item) => item['id']!.isNotEmpty)
              .toList();
        }
        if (transactionRestartRes.success &&
            transactionRestartRes.data is List) {
          _transactionRestartOptions = (transactionRestartRes.data as List)
              .whereType<Map>()
              .map(
                (item) => <String, String>{
                  'code': (item['code'] ?? '').toString(),
                  'label': (item['label'] ?? '').toString(),
                },
              )
              .where((item) => item['code']!.isNotEmpty)
              .toList();
        }
        if (transactionPlaceholderRes.success &&
            transactionPlaceholderRes.data is List) {
          _transactionPrefixPlaceholders =
              (transactionPlaceholderRes.data as List)
                  .whereType<Map>()
                  .map(
                    (item) => <String, String>{
                      'id': (item['token'] ?? '').toString(),
                      'label': (item['label'] ?? '').toString(),
                    },
                  )
                  .where((item) => item['id']!.isNotEmpty)
                  .toList();
        }
        if (_isEditing && orgRes.success && orgRes.data is Map) {
          // In edit mode org data is only used for fallback fiscal year default
          final orgData = orgRes.data as Map<String, dynamic>;
          if (_selectedFiscalYear == null) {
            _selectedFiscalYear = _matchLookupCode(
              orgData['fiscal_year']?.toString(),
              _fiscalYearOptions,
            );
          }
        }
        if (!_isEditing && orgRes.success && orgRes.data is Map) {
          final orgData = orgRes.data as Map<String, dynamic>;
          _selectedIndustry = orgData['industry']?.toString();
          _gstTreatment = _matchLookupCode(
            orgData['gst_treatment']?.toString(),
            _gstTreatmentOptions,
          );
          _panCtrl.text = orgData['pan_number']?.toString() ?? '';
          _selectedFiscalYear = _matchLookupCode(
            orgData['fiscal_year']?.toString(),
            _fiscalYearOptions,
          );
          if (_selectedFiscalYear == null && _fiscalYearOptions.isNotEmpty) {
            _selectedFiscalYear = _fiscalYearOptions.first['code'];
          }
          _reportBasis = (orgData['report_basis'] ?? 'accrual').toString();
        }
      });
    } catch (_) {}
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : '';
      final res = await _apiClient.get(
        'branches/${widget.branchId}',
        queryParameters: {'org_id': orgId},
      );
      if (!mounted) return;
      if (res.success && res.data is Map<String, dynamic>) {
        final d = res.data as Map<String, dynamic>;
        _branchSystemId = (d['system_id'] ?? '').toString().trim();
        _nameCtrl.text = (d['name'] ?? '').toString();
        _branchCodeCtrl.text = (d['branch_code'] ?? '').toString();
        _hydrateBranchCodePreferences(_branchCodeCtrl.text);
        _emailCtrl.text = (d['email'] ?? '').toString();
        _phoneCtrl.text = (d['phone'] ?? '').toString().replaceAll(RegExp(r'^\+91\s*'), '');
        _websiteCtrl.text = (d['website'] ?? '').toString();
        _attentionCtrl.text = (d['attention'] ?? '').toString();
        _streetCtrl.text = (d['street'] ?? d['address_street_1'] ?? '').toString();
        _street2Ctrl.text = (d['place'] ?? d['address_street_2'] ?? '').toString();
        _cityCtrl.text = (d['city'] ?? '').toString();
        _pincodeCtrl.text = (d['pincode'] ?? '').toString();
        final districtId = d['district_id']?.toString();
        final localBodyId = d['local_body_id']?.toString();
        final wardId = d['ward_id']?.toString();
        final assemblyId = d['assembly_id']?.toString();

        _selectedFiscalYear = _matchLookupCode(
          d['fiscal_year']?.toString(),
          _fiscalYearOptions,
        );
        _reportBasis = (d['report_basis'] ?? 'accrual').toString();
        _hasSeparatePaymentStubAddress =
            d['has_separate_payment_stub_address'] == true;

        if (_hasSeparatePaymentStubAddress &&
            d['payment_stub_address'] != null) {
          try {
            final Map<String, dynamic> psa = d['payment_stub_address'] is String
                ? jsonDecode(d['payment_stub_address'] as String)
                      as Map<String, dynamic>
                : d['payment_stub_address'] as Map<String, dynamic>;

            _paymentStubAttentionController.text = (psa['attention'] ?? '')
                .toString();
            _paymentStubStreet1Controller.text = (psa['street1'] ?? '')
                .toString();
            _paymentStubStreet2Controller.text = (psa['street2'] ?? '')
                .toString();
            _paymentStubCityController.text = (psa['city'] ?? '').toString();
            _selectedPaymentStubState =
                (psa['state_name'] ?? psa['state'] ?? '').toString();
            _paymentStubPincodeController.text = (psa['pincode'] ?? '')
                .toString();
            _paymentStubPhoneController.text = (psa['phone'] ?? '').toString().replaceAll(RegExp(r'^\+91\s*'), '');
            _selectedPaymentStubDistrictId = psa['district_id']?.toString();
            _selectedPaymentStubLocalBodyId = psa['local_body_id']?.toString();
            _selectedPaymentStubAssemblyCode =
                (psa['assembly_code'] ?? psa['assembly_name'] ?? '').toString();
            _selectedPaymentStubWardId = psa['ward_id']?.toString();

            if (_selectedPaymentStubState != null &&
                _selectedPaymentStubState!.isNotEmpty) {
              _loadPaymentStubStates().then((_) {
                _loadDistrictsForSelectedPaymentStubState().then((_) {
                  if (_selectedPaymentStubDistrictId != null) {
                    _loadLocalBodiesForSelectedPaymentStubDistrict(
                      _selectedPaymentStubDistrictId!,
                    ).then((_) {
                      _loadAssembliesForSelectedPaymentStubDistrict();
                      if (_selectedPaymentStubLocalBodyId != null) {
                        _loadWardsForSelectedPaymentStubLocalBody();
                      }
                    });
                  }
                });
              });
            }
          } catch (_) {}
        }

        final stateVal = (d['state'] ?? '').toString();
        final countryVal = (d['country'] ?? 'India').toString();

        // Ensure states are loaded for the branch's country before setting selectedState
        if (_stateOptions.isEmpty && stateVal.isNotEmpty) {
          await _loadStatesForCountry(countryVal);
          if (!mounted) return;
        }

        final businessType = d['branch_type']?.toString();
        final logoUrl = d['logo_url']?.toString();
        final gstinStr = (d['gstin'] ?? '').toString();
        final defaultSeriesId = d['default_transaction_series_id']?.toString();
        final txSeriesIds = d['transaction_series_ids'] is List
            ? (d['transaction_series_ids'] as List)
                  .map((id) => id?.toString() ?? '')
                  .where((id) => id.isNotEmpty)
                  .toList()
            : <String>[];
        final txSeriesId = d['transaction_series_id']?.toString();
        final primaryContact = d['primary_contact_id']?.toString();
        final parentBranchId = d['parent_branch_id']?.toString();
        final locationUsers = d['location_users'] is List
            ? (d['location_users'] as List)
                  .whereType<Map<String, dynamic>>()
                  .map((user) {
                    final userId = (user['user_id'] ?? '').toString();
                    final orgUser = _orgUsers
                        .cast<Map<String, dynamic>>()
                        .firstWhere(
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
          _selectedIndustry = (d['industry'] ?? '').toString().isNotEmpty
              ? (d['industry'] as String)
              : _selectedIndustry;
          _selectedState = _stateOptions.contains(stateVal) ? stateVal : null;
          _selectedDistrictId = districtId?.isNotEmpty == true
              ? districtId
              : null;
          _selectedLocalBodyId = localBodyId?.isNotEmpty == true
              ? localBodyId
              : null;
          _selectedAssemblyId = assemblyId?.isNotEmpty == true
              ? assemblyId
              : null;
          _selectedWardId = wardId?.isNotEmpty == true ? wardId : null;
          _selectedBusinessType = _matchLookupCode(
            businessType,
            _businessTypes,
            codeKey: 'id',
          );
          if (logoUrl != null && logoUrl.isNotEmpty) {
            _logoUrl = logoUrl;
            _logoOption = 'upload';
          }
          _panCtrl.text = (d['pan'] ?? '').toString();
          _gstTreatment = _matchLookupCode(
            d['gst_treatment']?.toString(),
            _gstTreatmentOptions,
          );
          _selectedDrugLicenceType = _matchLookupCode(
            d['drug_licence_type']?.toString(),
            _drugLicenceTypeOptions,
          );
          _isDrugRegistered = d['is_drug_registered'] == true;
          _drugLicence20Ctrl.text = (d['drug_licence_20'] ?? '').toString();
          _drugLicence21Ctrl.text = (d['drug_licence_21'] ?? '').toString();
          _drugLicence20BCtrl.text = (d['drug_licence_20b'] ?? '').toString();
          _drugLicence21BCtrl.text = (d['drug_licence_21b'] ?? '').toString();
          _isFssaiRegistered = d['is_fssai_registered'] == true;
          _fssaiNumberCtrl.text = (d['fssai_number'] ?? '').toString();
          _isMsmeRegistered = d['is_msme_registered'] == true;
          _selectedMsmeType =
              (d['msme_type'] ?? d['msme_registration_type'] ?? '').toString();
          _msmeNumberCtrl.text = (d['msme_number'] ?? '').toString();
          if (gstinStr.isNotEmpty) {
            _gstinData = _GstinData(
              gstin: gstinStr,
              registrationType: d['gstin_registration_type']?.toString(),
              legalName: (d['gstin_legal_name'] ?? '').toString(),
              tradeName: (d['gstin_trade_name'] ?? '').toString(),
              registeredOn: d['gstin_registered_on']?.toString(),
              reverseCharge: d['gstin_reverse_charge'] == true,
              importExport: d['gstin_import_export'] == true,
              importExportAccountId: d['gstin_import_export_account_id']
                  ?.toString(),
              digitalServices: d['gstin_digital_services'] == true,
            );
          }
          if (defaultSeriesId != null && defaultSeriesId.isNotEmpty)
            _selectedDefaultSeriesId = defaultSeriesId;
          _selectedTransactionSeriesIds
            ..clear()
            ..addAll(restoredSeriesIds);
          _locationUsers
            ..clear()
            ..addAll(locationUsers);
          _provideAccessToAll = locationUsers.isEmpty;
          if (primaryContact != null && primaryContact.isNotEmpty)
            _primaryContactId = primaryContact;
          if (parentBranchId != null && parentBranchId.isNotEmpty) {
            _parentBranchId = parentBranchId;
            _isChildLocation = true;
          }
          final subFrom = d['subscription_from']?.toString();
          final subTo = d['subscription_to']?.toString();
          if (subFrom != null && subFrom.isNotEmpty)
            _subscriptionFrom = DateTime.tryParse(subFrom);
          if (subTo != null && subTo.isNotEmpty)
            _subscriptionTo = DateTime.tryParse(subTo);
        });

        if (_showMainAddressLsgdFields) {
          await _loadDistrictsForSelectedState();
          if (_selectedDistrictId != null && _selectedDistrictId!.isNotEmpty) {
            await _loadLocalBodiesForSelectedDistrict(_selectedDistrictId!);
            await _loadAssembliesForSelectedDistrict();
            if (_selectedLocalBodyId != null &&
                _selectedLocalBodyId!.isNotEmpty) {
              _LocalBodyOption? matchedLocalBody;
              for (final localBody in _allLocalBodyOptions) {
                if (localBody.id == _selectedLocalBodyId) {
                  matchedLocalBody = localBody;
                  break;
                }
              }
              if (matchedLocalBody != null) {
                setState(() {
                  _selectedLocalBodyType = matchedLocalBody!.bodyType;
                  _localBodyOptions = _allLocalBodyOptions
                      .where(
                        (localBody) =>
                            localBody.bodyType.toLowerCase() ==
                            matchedLocalBody!.bodyType.toLowerCase(),
                      )
                      .toList();
                });
              }
              await _loadWardsForSelectedLocalBody();
            }
          }
        }
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
    if (result != null && result.files.isNotEmpty)
      setState(() => _logoPicked = result.files.first);
  }

  // ─── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final hasFormErrors = !_formKey.currentState!.validate();
    final parentBranchMissing =
        _isChildLocation &&
        (_parentBranchId == null || _parentBranchId!.trim().isEmpty);
    final industryMissing =
        _selectedIndustry == null || _selectedIndustry!.trim().isEmpty;
    final businessTypeMissing =
        _selectedBusinessType == null || _selectedBusinessType!.trim().isEmpty;
    final addressMissing =
        _streetCtrl.text.trim().isEmpty ||
        _cityCtrl.text.trim().isEmpty ||
        _pincodeCtrl.text.trim().isEmpty ||
        _selectedState == null ||
        _selectedState!.trim().isEmpty;
    final mainAddressLsgdMissing =
        _showMainAddressLsgdFields &&
        (_selectedDistrictId == null ||
            _selectedDistrictId!.trim().isEmpty ||
            _selectedLocalBodyId == null ||
            _selectedLocalBodyId!.trim().isEmpty ||
            // _selectedAssemblyId == null ||
            // _selectedAssemblyId!.trim().isEmpty ||
            _selectedWardId == null ||
            _selectedWardId!.trim().isEmpty);
    final gstTreatmentMissing =
        _gstTreatment == null || _gstTreatment!.trim().isEmpty;
    final drugLicenceTypeMissing =
        _isPharmacyIndustry &&
        (_selectedDrugLicenceType == null ||
            _selectedDrugLicenceType!.trim().isEmpty);
    final transactionSeriesMissing = _selectedTransactionSeriesIds.isEmpty;
    final defaultTransactionSeriesMissing =
        _selectedDefaultSeriesId == null ||
        _selectedDefaultSeriesId!.trim().isEmpty;
    final defaultSeriesInvalid =
        _selectedDefaultSeriesId != null &&
        !_selectedTransactionSeriesIds.contains(_selectedDefaultSeriesId);
    final branchAccessMissing = !_provideAccessToAll && _locationUsers.isEmpty;
    if (mounted) {
      setState(() {
        _showValidationErrors = true;
      });
    }

    if (hasFormErrors ||
        parentBranchMissing ||
        industryMissing ||
        businessTypeMissing ||
        addressMissing ||
        mainAddressLsgdMissing ||
        gstTreatmentMissing ||
        drugLicenceTypeMissing ||
        transactionSeriesMissing ||
        defaultTransactionSeriesMissing ||
        defaultSeriesInvalid ||
        branchAccessMissing) {
      if (_nameCtrl.text.trim().isEmpty) {
        ZerpaiToast.error(context, 'Please enter a branch name.');
      } else if (parentBranchMissing) {
        ZerpaiToast.error(context, 'Please select a Associated branch.');
      } else if (_emailCtrl.text.trim().isEmpty) {
        ZerpaiToast.error(context, 'Please enter an email address.');
      } else if (industryMissing) {
        ZerpaiToast.error(context, 'Please select an industry.');
      } else if (businessTypeMissing) {
        ZerpaiToast.error(context, 'Please select a business type.');
      } else if (addressMissing) {
        ZerpaiToast.error(
          context,
          'Please complete the address with street, city, state, and pin code.',
        );
      } else if (mainAddressLsgdMissing) {
        ZerpaiToast.error(
          context,
          'Please complete the Kerala district, local body, assembly, and ward details.',
        );
      } else if (gstTreatmentMissing) {
        ZerpaiToast.error(context, 'Please select a GST treatment.');
      } else if (_isPharmacyIndustry && drugLicenceTypeMissing) {
        ZerpaiToast.error(context, 'Please select a drug licence type.');
      } else if (transactionSeriesMissing) {
        ZerpaiToast.error(
          context,
          'Please add at least one transaction number series.',
        );
      } else if (defaultTransactionSeriesMissing) {
        ZerpaiToast.error(
          context,
          'Please select a default transaction series.',
        );
      } else if (defaultSeriesInvalid) {
        ZerpaiToast.error(
          context,
          'Default transaction series must be one of the selected transaction series.',
        );
      } else if (branchAccessMissing) {
        ZerpaiToast.error(
          context,
          'Please select at least one user or provide access to all users.',
        );
      } else {
        ZerpaiToast.error(context, 'Please correct the highlighted fields.');
      }
      return;
    }
    setState(() => _isSaving = true);
    try {
      final user = ref.read(authUserProvider);
      final orgId = (user?.orgId.isNotEmpty == true) ? user!.orgId : '';

      // Duplicate name check removed: branch names are not unique (franchises like COCO can share the exact same name).

      if (_logoPicked != null) {
        final url = await StorageService().uploadLocationLogo(_logoPicked!);
        if (url != null) _logoUrl = url;
      }

      final body = <String, dynamic>{
        'org_id': orgId,
        'name': _nameCtrl.text.trim(),
        'branch_code': _branchCodeCtrl.text.trim().isNotEmpty
            ? _branchCodeCtrl.text.trim().toUpperCase()
            : _nameCtrl.text.trim().toUpperCase().replaceAll(' ', '-'),
        'email': _emailCtrl.text.trim(),
        'phone':
            '$_phonePrefix ${_phoneCtrl.text.trim()}',
        'website': _websiteCtrl.text.trim(),
        'attention': _attentionCtrl.text.trim(),
        'street': _streetCtrl.text.trim(),
        'place': _street2Ctrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _selectedState ?? '',
        'district_id': _showMainAddressLsgdFields ? _selectedDistrictId : null,
        'local_body_id': _showMainAddressLsgdFields
            ? _selectedLocalBodyId
            : null,
        'assembly_id': _showMainAddressLsgdFields ? _selectedAssemblyId : null,
        'ward_id': _showMainAddressLsgdFields ? _selectedWardId : null,
        'pincode': _pincodeCtrl.text.trim(),
        'country': _orgCountry,
        'fiscal_year': _selectedFiscalYear,
        'report_basis': _reportBasis,
        'has_separate_payment_stub_address': _hasSeparatePaymentStubAddress,
        if (_hasSeparatePaymentStubAddress)
          'payment_stub_address': jsonEncode({
            'attention': _paymentStubAttentionController.text.trim(),
            'street': _paymentStubStreet1Controller.text.trim(),
            'place': _paymentStubStreet2Controller.text.trim(),
            'city': _paymentStubCityController.text.trim(),
            'state_name': _selectedPaymentStubState,
            'pincode': _paymentStubPincodeController.text.trim(),
            'phone':
                '$_paymentStubPhonePrefix ${_paymentStubPhoneController.text.trim()}',
            'district_id': _selectedPaymentStubDistrictId,
            'local_body_id': _selectedPaymentStubLocalBodyId,
            'assembly_code': _selectedPaymentStubAssemblyCode,
            'assembly_name': _paymentStubAssemblyOptions
                .firstWhere(
                  (assembly) =>
                      assembly.code == _selectedPaymentStubAssemblyCode ||
                      assembly.name == _selectedPaymentStubAssemblyCode,
                  orElse: () => _AssemblyOption(
                    code: _selectedPaymentStubAssemblyCode ?? '',
                    name: _selectedPaymentStubAssemblyCode ?? '',
                  ),
                )
                .name,
            'ward_id': _selectedPaymentStubWardId,
          }),
        'is_child_location': _isChildLocation,
        if (_isChildLocation && _parentBranchId != null)
          'parent_branch_id': _parentBranchId,
        if (_selectedBusinessType != null) 'branch_type': _selectedBusinessType,
        'industry': _selectedIndustry,
        'pan': _panCtrl.text.trim(),
        'gst_treatment': _gstTreatment,
        'is_drug_registered': _isPharmacyIndustry && _isDrugRegistered,
        'drug_licence_type': _isPharmacyIndustry
            ? _selectedDrugLicenceType
            : null,
        'drug_licence_20': _isPharmacyIndustry
            ? _drugLicence20Ctrl.text.trim()
            : '',
        'drug_licence_21': _isPharmacyIndustry
            ? _drugLicence21Ctrl.text.trim()
            : '',
        'drug_licence_20b': _isPharmacyIndustry
            ? _drugLicence20BCtrl.text.trim()
            : '',
        'drug_licence_21b': _isPharmacyIndustry
            ? _drugLicence21BCtrl.text.trim()
            : '',
        'is_fssai_registered': _isPharmacyIndustry && _isFssaiRegistered,
        'fssai_number': _isPharmacyIndustry ? _fssaiNumberCtrl.text.trim() : '',
        'is_msme_registered': _isPharmacyIndustry && _isMsmeRegistered,
        'msme_type': _isPharmacyIndustry ? _selectedMsmeType : null,
        'msme_number': _isPharmacyIndustry ? _msmeNumberCtrl.text.trim() : '',
        if (_primaryContactId != null) 'primary_contact_id': _primaryContactId,
        if (_subscriptionFrom != null)
          'subscription_from': _subscriptionFrom!.toIso8601String().substring(
            0,
            10,
          ),
        if (_subscriptionTo != null)
          'subscription_to': _subscriptionTo!.toIso8601String().substring(
            0,
            10,
          ),
        'gstin': _gstinData?.gstin ?? '',
        if (_gstinData != null) ...{
          'gstin_registration_type': _gstinData!.registrationType,
          'gstin_legal_name': _gstinData!.legalName,
          'gstin_trade_name': _gstinData!.tradeName,
          'gstin_registered_on': _gstinData!.registeredOn,
          'gstin_reverse_charge': _gstinData!.reverseCharge,
          'gstin_import_export': _gstinData!.importExport,
          if (_gstinData!.importExportAccountId != null)
            'gstin_import_export_account_id': _gstinData!.importExportAccountId,
          'gstin_digital_services': _gstinData!.digitalServices,
        },
        if (_logoPicked != null && _logoUrl != null) 'logo_url': _logoUrl,
        if (_logoOption == 'upload' && _logoUrl == null) 'logo_url': null,
        if (_selectedTransactionSeriesIds.isNotEmpty)
          'transaction_series_ids': _selectedTransactionSeriesIds,
        if (_selectedDefaultSeriesId != null)
          'default_transaction_series_id': _selectedDefaultSeriesId,
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
        ZerpaiToast.success(
          context,
          _isEditing
              ? 'Branch updated successfully.'
              : 'Branch created successfully.',
        );
        final uri = GoRouterState.of(context).uri;
        final match = RegExp(r'^/(\d{10,20})').firstMatch(uri.path);
        final orgSystemId = match?.group(1) ?? '0000000000';
        context.go('/$orgSystemId${AppRoutes.settingsBranches}');
      } else {
        ZerpaiToast.error(
          context,
          (res.message?.isNotEmpty == true)
              ? res.message!
              : 'Failed to save branch.',
        );
      }
    } catch (e, st) {
      debugPrint('[BranchSave] error: $e\n$st');
      if (mounted) {
        ZerpaiToast.error(
          context,
          ZerpaiBuilders.parseErrorMessage(e, 'branch'),
        );
      }
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
              if (isExpanded)
                _expandedBlocks.remove(block.title);
              else
                _expandedBlocks.add(block.title);
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
        entry.route != null &&
        (entry.route == currentPath ||
            (entry.route == AppRoutes.settingsBranches &&
                (currentPath.startsWith('/settings/branches/create') ||
                    (currentPath.contains('/settings/branches/') &&
                        currentPath.contains('/edit')))));
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
      return Skeletonizer(
        ignoreContainers: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space32),
          child: ZFormSkeleton(rows: 20),
        ),
      );
    }
    return Form(
      key: _formKey,
      autovalidateMode: _showValidationErrors
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: SettingsFixedHeaderLayout(
        maxWidth: 620,
        header: Text.rich(
          TextSpan(
            text: _isEditing ? 'Edit Branch' : 'Add Branch',
            children: [
              if (_isEditing && _branchSystemId.isNotEmpty)
                TextSpan(
                  text: ' System ID: $_branchSystemId',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditing && _branchSystemId.isNotEmpty)
              ZerpaiFormRow(
                label: 'System ID',
                child: _buildStaticField(_branchSystemId),
              ),
            // ── Main form ──────────────────────────────────────────────
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  ZerpaiFormRow(
                    label: 'Logo',
                    child: FormDropdown<String>(
                      value: _logoOption,
                      items: const ['same', 'upload'],
                      displayStringForValue: (v) => v == 'same'
                          ? 'Same as organization logo'
                          : 'Upload a new logo',
                      onChanged: (v) =>
                          setState(() => _logoOption = v ?? 'same'),
                    ),
                  ),
                  if (_logoOption == 'upload') ...[
                    ZerpaiFormRow(
                      label: '',
                      crossAxisAlignment: CrossAxisAlignment.start,
                      child: _buildLogoUpload(),
                    ),
                  ],

                  // Branch name
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
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Branch name is required'
                              : null,
                        ),
                        const SizedBox(height: AppTheme.space10),
                        GestureDetector(
                          onTap: () => setState(() {
                            _isChildLocation = !_isChildLocation;
                            if (!_isChildLocation) _parentBranchId = null;
                          }),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: Checkbox(
                                  value: _isChildLocation,
                                  onChanged: (v) => setState(() {
                                    _isChildLocation = v ?? false;
                                    if (!_isChildLocation)
                                      _parentBranchId = null;
                                  }),
                                ),
                              ),
                              const SizedBox(width: AppTheme.space8),
                              const Text('This is a child branch'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Associated branch
                  if (_isChildLocation) ...[
                    ZerpaiFormRow(
                      label: 'Associated branch',
                      required: true,
                      child: FormDropdown<String>(
                        value: _parentBranchId,
                        hint: 'Select associated branch',
                        items: _associatedBranchDropdownItems,
                        displayStringForValue: (id) =>
                            _findAvailableBranchById(id)?['name']?.toString() ?? id,
                        searchStringForValue: (id) {
                          final branch = _findAvailableBranchById(id);
                          if (branch == null) return id;
                          final name = _branchName(branch);
                          final groupLabel = _associatedBranchGroupLabelForId(id);
                          return '$name $groupLabel';
                        },
                        itemBuilder: (id, isSelected, isHovered) {
                          final branch = _findAvailableBranchById(id);
                          final branchName = branch == null ? id : _branchName(branch);
                          final showHeader = _isFirstAssociatedBranchInGroup(id);
                          final groupLabel = _associatedBranchGroupLabelForId(id);

                          final textColor = isSelected
                              ? AppTheme.primaryBlueDark
                              : AppTheme.textPrimary;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showHeader)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                                  child: Text(
                                    groupLabel,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 8, 12, 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        branchName.isEmpty ? id : branchName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                        onChanged: (v) => setState(() => _parentBranchId = v),
                      ),
                    ),
                  ],

                  // Branch code — auto-generated from prefix and next number
                  ZerpaiFormRow(
                    label: 'Branch code',
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _branchCodeCtrl,
                            readOnly: !_branchCodeManualOverride,
                            decoration: _dec('e.g. BR-00001').copyWith(
                              suffixIcon: _branchCodeManualOverride
                                  ? null
                                  : const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        'Auto',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryBlueDark,
                                        ),
                                      ),
                                    ),
                              filled: true,
                              fillColor: _branchCodeManualOverride
                                  ? Colors.white
                                  : AppTheme.bgLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ZTooltip(
                          message:
                              'Configure the branch code prefix and next number, or switch to manual entry.',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: _showBranchCodePreferencesDialog,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                LucideIcons.settings,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  ZerpaiFormRow(
                    label: 'Industry',
                    required: true,
                    highlightRequiredLabel: true,
                    child: FormDropdown<String>(
                      value: _selectedIndustry,
                      items: _industryOptions,
                      hint: 'Select Industry',
                      errorText:
                          _showValidationErrors &&
                              (_selectedIndustry == null ||
                                  _selectedIndustry!.trim().isEmpty)
                          ? 'Industry is required'
                          : null,
                      onChanged: (v) => setState(() {
                        final wasPharmacy = _isPharmacyIndustry;
                        _selectedIndustry = v;
                        if (wasPharmacy && !_isPharmacyIndustry) {
                          _resetPharmacyComplianceFields();
                        }
                      }),
                    ),
                  ),

                  // Email
                  ZerpaiFormRow(
                    label: 'Email',
                    required: true,
                    highlightRequiredLabel: true,
                    child: TextFormField(
                      controller: _emailCtrl,
                      decoration: _dec('branch@example.com'),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Email is required';
                        final emailPattern = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        );
                        if (!emailPattern.hasMatch(email)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                  ),

                  // Business type
                  ZerpaiFormRow(
                    label: 'Business type',
                    required: true,
                    highlightRequiredLabel: true,
                    child: FormDropdown<String>(
                      items: _businessTypes.map((t) => t['id']!).toList(),
                      value: _selectedBusinessType,
                      hint: 'Select business type',
                      errorText:
                          _showValidationErrors &&
                              (_selectedBusinessType == null ||
                                  _selectedBusinessType!.trim().isEmpty)
                          ? 'Business type is required'
                          : null,
                      showSettings: true,
                      settingsLabel: 'Manage Business Types',
                      onSettingsTap: _showManageBusinessTypesDialog,
                      displayStringForValue: (id) {
                        final match = _businessTypes.firstWhere(
                          (t) => t['id'] == id,
                          orElse: () => {'code': id, 'label': ''},
                        );
                        return '${match['code']} — ${match['label']}';
                      },
                      onChanged: (v) =>
                          setState(() => _selectedBusinessType = v),
                    ),
                  ),

                  // Address
                  ZerpaiFormRow(
                    label: 'Address',
                    required: true,
                    highlightRequiredLabel: true,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _attentionCtrl,
                          decoration: _dec('Attention'),
                        ),
                        const SizedBox(height: AppTheme.space8),
                        TextFormField(
                          controller: _streetCtrl,
                          decoration: _dec('Street'),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Street is required'
                              : null,
                        ),
                        const SizedBox(height: AppTheme.space8),
                        TextFormField(
                          controller: _street2Ctrl,
                          decoration: _dec('Place'),
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityCtrl,
                                decoration: _dec('City'),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                    ? 'City is required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Expanded(
                              child: TextFormField(
                                controller: _pincodeCtrl,
                                decoration: _dec('Pin code'),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Pin code is required';
                                  }
                                  if (value.trim().length != 6) {
                                    return 'Pin code must be 6 digits';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space8),
                        _buildStaticField(_orgCountry),
                        const SizedBox(height: AppTheme.space8),
                        Row(
                          children: [
                            Expanded(
                              child: FormDropdown<String>(
                                items: _stateOptions,
                                value: _selectedState,
                                hint: 'State / Union territory',
                                errorText:
                                    _showValidationErrors &&
                                        (_selectedState == null ||
                                            _selectedState!.trim().isEmpty)
                                    ? 'State is required'
                                    : null,
                                onChanged: (v) async {
                                  setState(() {
                                    _selectedState = v;
                                    _selectedDistrictId = null;
                                    _selectedLocalBodyType = null;
                                    _selectedLocalBodyId = null;
                                    _selectedAssemblyId = null;
                                    _selectedWardId = null;
                                    _districtOptions = [];
                                    _allLocalBodyOptions = [];
                                    _localBodyOptions = [];
                                    _assemblyOptions = [];
                                    _wardOptions = [];
                                  });
                                  if ((v ?? '').trim().toLowerCase() ==
                                      'kerala') {
                                    await _loadDistrictsForSelectedState();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Expanded(
                              flex: 2,
                              child: PhoneInputField(
                                controller: _phoneCtrl,
                                selectedPrefix: _phonePrefix,
                                onPrefixChanged: (v) =>
                                    setState(() => _phonePrefix = v ?? '+91'),
                              ),
                            ),
                          ],
                        ),
                        if (_showMainAddressLsgdFields) ...[
                          const SizedBox(height: AppTheme.space8),
                          Row(
                            children: [
                              Expanded(
                                child: FormDropdown<String>(
                                  items: _districtOptions
                                      .map((district) => district.id)
                                      .toList(),
                                  value: _selectedDistrictId,
                                  hint: 'Select district',
                                  displayStringForValue: (value) =>
                                      _districtOptions
                                          .firstWhere(
                                            (district) => district.id == value,
                                            orElse: () => _DistrictOption(
                                              id: value,
                                              name: value,
                                            ),
                                          )
                                          .name,
                                  errorText:
                                      _showValidationErrors &&
                                          (_selectedDistrictId == null ||
                                              _selectedDistrictId!
                                                  .trim()
                                                  .isEmpty)
                                      ? 'District is required'
                                      : null,
                                  onChanged: (value) async {
                                    setState(() {
                                      _selectedDistrictId = value;
                                      _selectedLocalBodyType = null;
                                      _selectedLocalBodyId = null;
                                      _selectedAssemblyId = null;
                                      _selectedWardId = null;
                                      _allLocalBodyOptions = [];
                                      _localBodyOptions = [];
                                      _assemblyOptions = [];
                                      _wardOptions = [];
                                    });
                                    if (value != null && value.isNotEmpty) {
                                      await _loadLocalBodiesForSelectedDistrict(
                                        value,
                                      );
                                      await _loadAssembliesForSelectedDistrict();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: AppTheme.space8),
                              Expanded(
                                child: FormDropdown<String>(
                                  items: _availableLocalBodyTypeOptions,
                                  value: _selectedLocalBodyType,
                                  hint: 'Select local body type',
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedLocalBodyType = value;
                                      _selectedLocalBodyId = null;
                                      _selectedWardId = null;
                                      _localBodyOptions =
                                          value == null || value.isEmpty
                                          ? _allLocalBodyOptions
                                          : _allLocalBodyOptions
                                                .where(
                                                  (localBody) =>
                                                      localBody.bodyType
                                                          .toLowerCase() ==
                                                      value.toLowerCase(),
                                                )
                                                .toList();
                                      _wardOptions = [];
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space8),
                          Row(
                            children: [
                              Expanded(
                                child: FormDropdown<String>(
                                  items: _localBodyOptions
                                      .map((localBody) => localBody.id)
                                      .toList(),
                                  value: _selectedLocalBodyId,
                                  hint: 'Select local body name',
                                  displayStringForValue: (value) =>
                                      _localBodyOptions
                                          .firstWhere(
                                            (localBody) =>
                                                localBody.id == value,
                                            orElse: () => _LocalBodyOption(
                                              id: value,
                                              name: value,
                                              bodyType: '',
                                            ),
                                          )
                                          .name,
                                  errorText:
                                      _showValidationErrors &&
                                          (_selectedLocalBodyId == null ||
                                              _selectedLocalBodyId!
                                                  .trim()
                                                  .isEmpty)
                                      ? 'Local body is required'
                                      : null,
                                  onChanged: (value) async {
                                    setState(() {
                                      _selectedLocalBodyId = value;
                                      _selectedWardId = null;
                                      _wardOptions = [];
                                    });
                                    if (value != null && value.isNotEmpty) {
                                      await _loadWardsForSelectedLocalBody();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: AppTheme.space8),
                              Expanded(
                                child: FormDropdown<String>(
                                  items: _wardOptions
                                      .map((ward) => ward.id)
                                      .toList(),
                                  value: _selectedWardId,
                                  hint: 'Select ward',
                                  displayStringForValue: (value) => _wardOptions
                                      .firstWhere(
                                        (ward) => ward.id == value,
                                        orElse: () => _WardOption(
                                          id: value,
                                          name: value,
                                          displayName: value,
                                        ),
                                      )
                                      .displayName,
                                  errorText:
                                      _showValidationErrors &&
                                          (_selectedWardId == null ||
                                              _selectedWardId!.trim().isEmpty)
                                      ? 'Ward is required'
                                      : null,
                                  onChanged: (value) =>
                                      setState(() => _selectedWardId = value),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space8),
                          FormDropdown<String>(
                            items: _assemblyOptions
                                .map((assembly) => assembly.code)
                                .toList(),
                            value: _selectedAssemblyId,
                            hint: 'Select assembly',
                            displayStringForValue: (value) => _assemblyOptions
                                .firstWhere(
                                  (assembly) => assembly.code == value,
                                  orElse: () =>
                                      _AssemblyOption(code: value, name: value),
                                )
                                .name,
                            // errorText: _showValidationErrors &&
                            //     (_selectedAssemblyId == null || _selectedAssemblyId!.trim().isEmpty)
                            //     ? 'Assembly is required'
                            //     : null,
                            onChanged: (value) =>
                                setState(() => _selectedAssemblyId = value),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ZerpaiFormRow(
                    label: 'Payment stub address',
                    child: Row(
                      children: [
                        Checkbox(
                          value: _hasSeparatePaymentStubAddress,
                          activeColor: ref
                              .read(appBrandingProvider)
                              .accentColor,
                          onChanged: (value) {
                            final enabled = value ?? false;
                            setState(() {
                              _hasSeparatePaymentStubAddress = enabled;
                              if (!enabled) {
                                _selectedPaymentStubState = null;
                                _selectedPaymentStubDistrictId = null;
                                _selectedPaymentStubLocalBodyType = null;
                                _selectedPaymentStubLocalBodyId = null;
                                _selectedPaymentStubWardId = null;
                              }
                            });
                            if (enabled) {
                              _loadPaymentStubStates();
                            }
                          },
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Expanded(
                          child: Text(
                            'Use a separate address for payment stubs',
                            style: AppTheme.bodyText.copyWith(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasSeparatePaymentStubAddress)
                    ZerpaiFormRow(
                      label: 'Payment stub details',
                      crossAxisAlignment: CrossAxisAlignment.start,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _paymentStubAttentionController,
                            decoration: _dec('Attention'),
                          ),
                          const SizedBox(height: AppTheme.space8),
                          TextFormField(
                            controller: _paymentStubStreet1Controller,
                            decoration: _dec('Street'),
                          ),
                          const SizedBox(height: AppTheme.space8),
                          TextFormField(
                            controller: _paymentStubStreet2Controller,
                            decoration: _dec('Place'),
                          ),
                          const SizedBox(height: AppTheme.space8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _paymentStubCityController,
                                  decoration: _dec('City'),
                                ),
                              ),
                              const SizedBox(width: AppTheme.space8),
                              Expanded(
                                child: TextFormField(
                                  controller: _paymentStubPincodeController,
                                  decoration: _dec('Pin code'),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space8),
                          _buildStaticField(_orgCountry),
                          const SizedBox(height: AppTheme.space8),
                          Row(
                            children: [
                              Expanded(
                                child: FormDropdown<String>(
                                  items: _paymentStubStateLookupRows
                                      .map((state) => state.name)
                                      .toList(),
                                  value: _selectedPaymentStubState,
                                  hint: 'State / Union territory',
                                  onChanged: (value) async {
                                    setState(() {
                                      _selectedPaymentStubState = value;
                                      _selectedPaymentStubDistrictId = null;
                                      _selectedPaymentStubLocalBodyType = null;
                                      _selectedPaymentStubLocalBodyId = null;
                                      _selectedPaymentStubAssemblyCode = null;
                                      _selectedPaymentStubWardId = null;
                                      _paymentStubDistrictOptions = [];
                                      _paymentStubAllLocalBodyOptions = [];
                                      _paymentStubLocalBodyOptions = [];
                                      _paymentStubAssemblyOptions = [];
                                      _paymentStubWardOptions = [];
                                    });
                                    if (value != null && value.isNotEmpty) {
                                      await _loadDistrictsForSelectedPaymentStubState();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: AppTheme.space8),
                              Expanded(
                                child: PhoneInputField(
                                  controller: _paymentStubPhoneController,
                                  selectedPrefix: _paymentStubPhonePrefix,
                                  onPrefixChanged: (v) => setState(
                                      () => _paymentStubPhonePrefix = v ?? '+91'),
                                ),
                              ),
                            ],
                          ),
                          if (_showPaymentStubLsgdFields) ...[
                            const SizedBox(height: AppTheme.space8),
                            FormDropdown<String>(
                              items: _paymentStubDistrictOptions
                                  .map((district) => district.id)
                                  .toList(),
                              value: _selectedPaymentStubDistrictId,
                              hint: 'Select district',
                              displayStringForValue: (value) =>
                                  _paymentStubDistrictOptions
                                      .firstWhere(
                                        (district) => district.id == value,
                                        orElse: () => _DistrictOption(
                                          id: value,
                                          name: value,
                                        ),
                                      )
                                      .name,
                              onChanged: (value) async {
                                setState(() {
                                  _selectedPaymentStubDistrictId = value;
                                  _selectedPaymentStubLocalBodyType = null;
                                  _selectedPaymentStubLocalBodyId = null;
                                  _selectedPaymentStubAssemblyCode = null;
                                  _selectedPaymentStubWardId = null;
                                  _paymentStubAllLocalBodyOptions = [];
                                  _paymentStubLocalBodyOptions = [];
                                  _paymentStubAssemblyOptions = [];
                                  _paymentStubWardOptions = [];
                                });
                                if (value != null && value.isNotEmpty) {
                                  await _loadLocalBodiesForSelectedPaymentStubDistrict(
                                    value,
                                  );
                                  await _loadAssembliesForSelectedPaymentStubDistrict();
                                }
                              },
                            ),
                            const SizedBox(height: AppTheme.space8),
                            Row(
                              children: [
                                Expanded(
                                  child: FormDropdown<String>(
                                    items:
                                        _paymentStubAvailableLocalBodyTypeOptions,
                                    value: _selectedPaymentStubLocalBodyType,
                                    hint: 'Select local body type',
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPaymentStubLocalBodyType =
                                            value;
                                        _selectedPaymentStubLocalBodyId = null;
                                        _selectedPaymentStubWardId = null;
                                        _paymentStubLocalBodyOptions =
                                            value == null || value.isEmpty
                                            ? _paymentStubAllLocalBodyOptions
                                            : _paymentStubAllLocalBodyOptions
                                                  .where(
                                                    (localBody) =>
                                                        localBody.bodyType
                                                            .toLowerCase() ==
                                                        value.toLowerCase(),
                                                  )
                                                  .toList();
                                        _paymentStubWardOptions = [];
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppTheme.space8),
                                Expanded(
                                  child: FormDropdown<String>(
                                    items: _paymentStubAssemblyOptions
                                        .map((assembly) => assembly.code)
                                        .toList(),
                                    value: _selectedPaymentStubAssemblyCode,
                                    hint: 'Select assembly',
                                    displayStringForValue: (value) =>
                                        _paymentStubAssemblyOptions
                                            .firstWhere(
                                              (assembly) =>
                                                  assembly.code == value ||
                                                  assembly.name == value,
                                              orElse: () => _AssemblyOption(
                                                code: value,
                                                name: value,
                                              ),
                                            )
                                            .name,
                                    onChanged: (value) => setState(
                                      () => _selectedPaymentStubAssemblyCode =
                                          value,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space8),
                            Row(
                              children: [
                                Expanded(
                                  child: FormDropdown<String>(
                                    items: _paymentStubLocalBodyOptions
                                        .map((localBody) => localBody.id)
                                        .toList(),
                                    value: _selectedPaymentStubLocalBodyId,
                                    hint: 'Select local body',
                                    displayStringForValue: (value) =>
                                        _paymentStubLocalBodyOptions
                                            .firstWhere(
                                              (localBody) =>
                                                  localBody.id == value,
                                              orElse: () => _LocalBodyOption(
                                                id: value,
                                                name: value,
                                                bodyType: '',
                                              ),
                                            )
                                            .name,
                                    onChanged: (value) async {
                                      setState(() {
                                        _selectedPaymentStubLocalBodyId = value;
                                        _selectedPaymentStubWardId = null;
                                        _paymentStubWardOptions = [];
                                      });
                                      if (value != null && value.isNotEmpty) {
                                        await _loadWardsForSelectedPaymentStubLocalBody();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppTheme.space8),
                                Expanded(
                                  child: FormDropdown<String>(
                                    items: _paymentStubWardOptions
                                        .map((ward) => ward.id)
                                        .toList(),
                                    value: _selectedPaymentStubWardId,
                                    hint: 'Select ward',
                                    displayStringForValue: (value) =>
                                        _paymentStubWardOptions
                                            .firstWhere(
                                              (ward) => ward.id == value,
                                              orElse: () => _WardOption(
                                                id: value,
                                                name: value,
                                                displayName: value,
                                              ),
                                            )
                                            .displayName,
                                    onChanged: (value) => setState(
                                      () => _selectedPaymentStubWardId = value,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ZerpaiFormRow(
                    label: 'PAN',
                    child: TextFormField(
                      controller: _panCtrl,
                      decoration: _dec('Enter PAN'),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [LengthLimitingTextInputFormatter(10)],
                    ),
                  ),

                  ZerpaiFormRow(
                    label: 'GST Treatment',
                    required: true,
                    highlightRequiredLabel: true,
                    child: FormDropdown<String>(
                      value: _gstTreatment,
                      items: _gstTreatmentOptions
                          .map((option) => option['code']!)
                          .toList(),
                      displayStringForValue: (v) =>
                          _displayLookupLabel(v, _gstTreatmentOptions),
                      errorText:
                          _showValidationErrors &&
                              (_gstTreatment == null ||
                                  _gstTreatment!.trim().isEmpty)
                          ? 'GST treatment is required'
                          : null,
                      onChanged: (v) => setState(() => _gstTreatment = v),
                    ),
                  ),

                  if (_gstTreatment?.startsWith('registered') == true ||
                      _gstTreatment == 'special_economic_zone' ||
                      _gstTreatment == 'deemed_export')
                    ZerpaiFormRow(
                      label: 'GSTIN',
                      child: _buildGstinDropdownField(),
                    ),

                  if (_isPharmacyIndustry) ...[
                    // Drug Licence Type
                    ZerpaiFormRow(
                      label: 'Drug Licence Type',
                      required: true,
                      highlightRequiredLabel: true,
                      child: FormDropdown<String>(
                        value: _selectedDrugLicenceType,
                        hint: 'Select licence type',
                        items: _drugLicenceTypeOptions
                            .map((option) => option['code']!)
                            .toList(),
                        displayStringForValue: (value) =>
                            _displayLookupLabel(value, _drugLicenceTypeOptions),
                        errorText:
                            _showValidationErrors &&
                                (_selectedDrugLicenceType == null ||
                                    _selectedDrugLicenceType!.trim().isEmpty)
                            ? 'Drug licence type is required'
                            : null,
                        onChanged: (v) => setState(() {
                          _selectedDrugLicenceType = v;
                          _isDrugRegistered = v != null;
                        }),
                      ),
                    ),

                    // Retail licences: 20 & 21
                    if (_selectedDrugLicenceType == 'retail' ||
                        _selectedDrugLicenceType == 'wholesale_and_retail') ...[
                      ZerpaiFormRow(
                        label: 'Drug License 20',
                        required: true,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _drugLicence20Ctrl,
                                decoration: _dec('Enter License Number'),
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            FileUploadButton(
                              files: _drugLic20Docs,
                              onFilesChanged: (f) =>
                                  setState(() => _drugLic20Docs = f),
                              showBadge: true,
                              showOverlay: true,
                            ),
                          ],
                        ),
                      ),
                      ZerpaiFormRow(
                        label: 'Drug License 21',
                        required: true,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _drugLicence21Ctrl,
                                decoration: _dec('Enter License Number'),
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            FileUploadButton(
                              files: _drugLic21Docs,
                              onFilesChanged: (f) =>
                                  setState(() => _drugLic21Docs = f),
                              showBadge: true,
                              showOverlay: true,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Wholesale licences: 20B & 21B
                    if (_selectedDrugLicenceType == 'wholesale' ||
                        _selectedDrugLicenceType == 'wholesale_and_retail') ...[
                      ZerpaiFormRow(
                        label: 'Drug License 20B',
                        required: true,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _drugLicence20BCtrl,
                                decoration: _dec('Enter License Number'),
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            FileUploadButton(
                              files: _drugLic20BDocs,
                              onFilesChanged: (f) =>
                                  setState(() => _drugLic20BDocs = f),
                              showBadge: true,
                              showOverlay: true,
                            ),
                          ],
                        ),
                      ),
                      ZerpaiFormRow(
                        label: 'Drug License 21B',
                        required: true,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _drugLicence21BCtrl,
                                decoration: _dec('Enter License Number'),
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            FileUploadButton(
                              files: _drugLic21BDocs,
                              onFilesChanged: (f) =>
                                  setState(() => _drugLic21BDocs = f),
                              showBadge: true,
                              showOverlay: true,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // FSSAI
                    ZerpaiFormRow(
                      label: 'FSSAI License Registered ?',
                      child: Row(
                        children: [
                          Checkbox(
                            value: _isFssaiRegistered,
                            activeColor: ref
                                .read(appBrandingProvider)
                                .accentColor,
                            onChanged: (v) =>
                                setState(() => _isFssaiRegistered = v ?? false),
                          ),
                          const SizedBox(width: AppTheme.space8),
                          Text(
                            'This Branch Is Registered FSSAI License',
                            style: AppTheme.bodyText.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (_isFssaiRegistered) ...[
                      ZerpaiFormRow(
                        label: 'FSSAI Number',
                        required: true,
                        tooltipMessage:
                            'Enter the 14-digit FSSAI license number.',
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _fssaiNumberCtrl,
                                decoration: _dec('Enter FSSAI Number'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            FileUploadButton(
                              files: _fssaiDocs,
                              onFilesChanged: (f) =>
                                  setState(() => _fssaiDocs = f),
                              showBadge: true,
                              showOverlay: true,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // MSME
                    ZerpaiFormRow(
                      label: 'MSME Registered ?',
                      child: Row(
                        children: [
                          Checkbox(
                            value: _isMsmeRegistered,
                            activeColor: ref
                                .read(appBrandingProvider)
                                .accentColor,
                            onChanged: (v) =>
                                setState(() => _isMsmeRegistered = v ?? false),
                          ),
                          const SizedBox(width: AppTheme.space8),
                          Text(
                            'This Branch Is Registered MSME',
                            style: AppTheme.bodyText.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (_isMsmeRegistered) ...[
                      ZerpaiFormRow(
                        label: 'MSME/Udyam Registration Type',
                        required: true,
                        child: FormDropdown<String>(
                          value: _selectedMsmeType,
                          hint: 'Select the Registration Type',
                          items: const ['Micro', 'Small', 'Medium'],
                          onChanged: (v) =>
                              setState(() => _selectedMsmeType = v),
                        ),
                      ),
                      ZerpaiFormRow(
                        label: 'MSME/Udyam Registration Number',
                        required: true,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _msmeNumberCtrl,
                                decoration: _dec(
                                  'Enter MSME/Udyam Registration Number',
                                ),
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            FileUploadButton(
                              files: _msmeDocs,
                              onFilesChanged: (f) =>
                                  setState(() => _msmeDocs = f),
                              showBadge: true,
                              showOverlay: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  // ── Subscription from ───────────────────────────────────
                  ZerpaiFormRow(
                    label: 'Subscription from',
                    child: GestureDetector(
                      key: _subFromKey,
                      onTap: () async {
                        final picked = await ZerpaiDatePicker.show(
                          context,
                          initialDate: _subscriptionFrom ?? DateTime.now(),
                          targetKey: _subFromKey,
                        );
                        if (picked != null)
                          setState(() => _subscriptionFrom = picked);
                      },
                      child: _buildDateField(
                        _subscriptionFrom,
                        'Select start date',
                      ),
                    ),
                  ),

                  // ── Subscription to ─────────────────────────────────────
                  ZerpaiFormRow(
                    label: 'Subscription to',
                    child: GestureDetector(
                      key: _subToKey,
                      onTap: () async {
                        final picked = await ZerpaiDatePicker.show(
                          context,
                          initialDate: _subscriptionTo ?? DateTime.now(),
                          targetKey: _subToKey,
                        );
                        if (picked != null)
                          setState(() => _subscriptionTo = picked);
                      },
                      child: _buildDateField(
                        _subscriptionTo,
                        'Select end date',
                      ),
                    ),
                  ),

                  if (_subscriptionRemainingDays != null)
                    ZerpaiFormRow(
                      label: 'Subscription days',
                      child: _buildStaticField(
                        '${_subscriptionRemainingDays!} days remaining',
                      ),
                    ),

                  // ── Transaction number series ────────────────────────────
                  ZerpaiFormRow(
                    label: 'Transaction number series',
                    required: true,
                    highlightRequiredLabel: true,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    child: TransactionSeriesDropdown(
                      series: _transactionSeriesOptions,
                      selectedIds: _selectedTransactionSeriesIds,
                      multiSelect: true,
                      accentColor: ref.watch(appBrandingProvider).accentColor,
                      errorText:
                          _showValidationErrors &&
                              _selectedTransactionSeriesIds.isEmpty
                          ? 'Select at least one series'
                          : null,
                      onChanged: (ids) => setState(() {
                        _selectedTransactionSeriesIds
                          ..clear()
                          ..addAll(ids);
                        if (_selectedDefaultSeriesId != null &&
                            !_selectedTransactionSeriesIds.contains(
                              _selectedDefaultSeriesId,
                            )) {
                          _selectedDefaultSeriesId = null;
                        }
                      }),
                      onAddTap: _showTransactionSeriesPreferencesDialog,
                    ),
                  ),

                  // ── Default transaction series ───────────────────────────
                  ZerpaiFormRow(
                    label: 'Default transaction series',
                    required: true,
                    highlightRequiredLabel: true,
                    child: TransactionSeriesDropdown(
                      series: _transactionSeriesOptions
                          .where(
                            (series) => _selectedTransactionSeriesIds.contains(
                              series.id,
                            ),
                          )
                          .toList(),
                      selectedIds: _selectedDefaultSeriesId != null
                          ? [_selectedDefaultSeriesId!]
                          : const [],
                      multiSelect: false,
                      includeDefaultOption: false,
                      placeholder: 'Select default series',
                      accentColor: ref.watch(appBrandingProvider).accentColor,
                      errorText:
                          _showValidationErrors &&
                              (_selectedDefaultSeriesId == null ||
                                  _selectedDefaultSeriesId!.trim().isEmpty)
                          ? 'Default series is required'
                          : null,
                      onChanged: (ids) => setState(
                        () => _selectedDefaultSeriesId = ids.isNotEmpty
                            ? ids.first
                            : null,
                      ),
                      onAddTap: _showTransactionSeriesPreferencesDialog,
                    ),
                  ),

                  // ── Branch access ────────────────────────────────────────
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
        footer: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.borderLight)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space32,
            vertical: AppTheme.space16,
          ),
          child: _buildActions(),
        ),
      ),
    );
  }

  // ─── Transaction series preferences dialog ─────────────────────────────────

  void _showTransactionSeriesPreferencesDialog() {
    final seriesNameCtrl = TextEditingController();
    final seriesCodeCtrl = TextEditingController();
    final prefixCtrls = {
      for (final m in _transactionModuleOptions)
        m['id']!: TextEditingController(),
    };
    final startingCtrls = {
      for (final m in _transactionModuleOptions)
        m['id']!: TextEditingController(text: '1'),
    };
    final restartDefaultCode = _transactionRestartOptions.isNotEmpty
        ? _transactionRestartOptions.first['code']!
        : '';
    final restartCtrls = {
      for (final m in _transactionModuleOptions) m['id']!: restartDefaultCode,
    };
    final formKey = GlobalKey<FormState>();

    String buildAutoCode(String value) {
      final name = value.trim();
      if (name.isEmpty) return '';

      final segments = name
          .split(RegExp(r'[^A-Za-z0-9]+'))
          .where((part) => part.isNotEmpty)
          .toList();

      if (segments.length >= 2) {
        final first = segments[0];
        final second = segments[1];
        final p1 = first.length >= 2 ? first.substring(0, 2) : first;
        final p2 = second.isNotEmpty ? second.substring(0, 1) : '';
        return '${p1}${p2.isNotEmpty ? '-$p2' : ''}'.toUpperCase();
      }

      final compact = segments.isNotEmpty ? segments.first : name;
      final prefix = compact.length >= 3 ? compact.substring(0, 3) : compact;
      return prefix.toUpperCase();
    }

    showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          String _preview(String moduleId) {
            final prefix = prefixCtrls[moduleId]?.text.trim() ?? '';
            final num = startingCtrls[moduleId]?.text.trim() ?? '1';
            if (prefix.isEmpty && (num == '1' || num.isEmpty))
              return num.isEmpty ? '1' : num;
            return '$prefix$num';
          }

          // Column flex values
          const int fxModule = 28;
          const int fxPrefix = 28;
          const int fxStarting = 22;
          const int fxRestart = 24;
          const int fxPreview = 20;

          Widget _headerCell(String label, {String? tooltip}) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              if (tooltip != null) ...[
                const SizedBox(width: 3),
                ZTooltip(message: tooltip),
              ],
            ],
          );

          return Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 8,
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: 900,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
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
                                icon: const Icon(
                                  LucideIcons.x,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppTheme.borderLight),

                        // ── Scrollable body ──────────────────────────────
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Series Name row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    RichText(
                                      text: const TextSpan(
                                        text: 'Series Name',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.errorRed,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '*',
                                            style: TextStyle(
                                              color: AppTheme.errorRed,
                                              fontSize: 13,
                                              inherit: false,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 320,
                                      child: TextFormField(
                                        controller: seriesNameCtrl,
                                        decoration: _dec(''),
                                        onChanged: (value) {
                                          setS(() {
                                            seriesCodeCtrl.text = buildAutoCode(
                                              value,
                                            );
                                          });
                                        },
                                        validator: (v) =>
                                            (v == null || v.trim().isEmpty)
                                            ? 'Series name is required'
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 80,
                                      child: Text(
                                        'Series Code',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 180,
                                      child: TextFormField(
                                        controller: seriesCodeCtrl,
                                        readOnly: true,
                                        decoration: _dec('').copyWith(
                                          hintText: 'Auto generated',
                                          filled: true,
                                          fillColor: AppTheme.bgLight,
                                          suffixIcon: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 6,
                                            ),
                                            child: Text(
                                              'Auto',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.primaryBlueDark,
                                              ),
                                            ),
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // ── Table ────────────────────────────────
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppTheme.borderLight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      // Header row
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.bgLight,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            topRight: Radius.circular(8),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: fxModule,
                                              child: _headerCell('MODULE'),
                                            ),
                                            Expanded(
                                              flex: fxPrefix,
                                              child: _headerCell('PREFIX'),
                                            ),
                                            Expanded(
                                              flex: fxStarting,
                                              child: _headerCell(
                                                'STARTING NUMBER',
                                                tooltip:
                                                    'This will be the number assigned to the next transaction you create.',
                                              ),
                                            ),
                                            Expanded(
                                              flex: fxRestart,
                                              child: _headerCell(
                                                'RESTART NUMBERING',
                                                tooltip:
                                                    'Choose how often the sequence resets.',
                                              ),
                                            ),
                                            Expanded(
                                              flex: fxPreview,
                                              child: _headerCell(
                                                'PREVIEW',
                                                tooltip:
                                                    'Preview of the generated transaction number.',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Module rows
                                      for (
                                        int i = 0;
                                        i < _transactionModuleOptions.length;
                                        i++
                                      ) ...[
                                        const Divider(
                                          height: 1,
                                          color: AppTheme.borderLight,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              // Module name
                                              Expanded(
                                                flex: fxModule,
                                                child: Text(
                                                  _transactionModuleOptions[i]['label']!,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: AppTheme.textBody,
                                                  ),
                                                ),
                                              ),

                                              // Prefix + placeholder button
                                              Expanded(
                                                flex: fxPrefix,
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextFormField(
                                                        controller:
                                                            prefixCtrls[_transactionModuleOptions[i]['id']!],
                                                        decoration: _dec(''),
                                                        onChanged: (_) =>
                                                            setS(() {}),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    // + placeholder popup
                                                    MenuAnchor(
                                                      style: MenuStyle(
                                                        backgroundColor:
                                                            WidgetStateProperty.all(
                                                              Colors.white,
                                                            ),
                                                        elevation:
                                                            WidgetStateProperty.all(
                                                              4,
                                                            ),
                                                        shape: WidgetStateProperty.all(
                                                          RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            side: BorderSide(
                                                              color: AppTheme
                                                                  .borderLight,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      menuChildren: [
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.fromLTRB(
                                                                12,
                                                                8,
                                                                12,
                                                                4,
                                                              ),
                                                          child: Text(
                                                            'PLACEHOLDER',
                                                            style: const TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: AppTheme
                                                                  .textSecondary,
                                                              letterSpacing:
                                                                  0.6,
                                                            ),
                                                          ),
                                                        ),
                                                        for (final ph
                                                            in _transactionPrefixPlaceholders)
                                                          MenuItemButton(
                                                            style: ButtonStyle(
                                                              backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                                                                states,
                                                              ) {
                                                                if (states.contains(
                                                                      WidgetState
                                                                          .hovered,
                                                                    ) ||
                                                                    states.contains(
                                                                      WidgetState
                                                                          .focused,
                                                                    )) {
                                                                  return AppTheme
                                                                      .primaryBlue;
                                                                }
                                                                return Colors
                                                                    .white;
                                                              }),
                                                              foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                                                                states,
                                                              ) {
                                                                if (states.contains(
                                                                      WidgetState
                                                                          .hovered,
                                                                    ) ||
                                                                    states.contains(
                                                                      WidgetState
                                                                          .focused,
                                                                    )) {
                                                                  return Colors
                                                                      .white;
                                                                }
                                                                return AppTheme
                                                                    .textPrimary;
                                                              }),
                                                            ),
                                                            onPressed: () {
                                                              final ctrl =
                                                                  prefixCtrls[_transactionModuleOptions[i]['id']!]!;
                                                              ctrl.text =
                                                                  ctrl.text +
                                                                  ph['id']!;
                                                              ctrl.selection =
                                                                  TextSelection.collapsed(
                                                                    offset: ctrl
                                                                        .text
                                                                        .length,
                                                                  );
                                                              setS(() {});
                                                            },
                                                            child: Text(
                                                              ph['label']!,
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                            ),
                                                          ),
                                                      ],
                                                      builder:
                                                          (
                                                            ctx2,
                                                            controller,
                                                            child,
                                                          ) => InkWell(
                                                            onTap: () =>
                                                                controller
                                                                    .isOpen
                                                                ? controller
                                                                      .close()
                                                                : controller
                                                                      .open(),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                            child: Container(
                                                              width: 22,
                                                              height: 22,
                                                              decoration: BoxDecoration(
                                                                color: AppTheme
                                                                    .primaryBlueDark,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              child: const Icon(
                                                                LucideIcons
                                                                    .plus,
                                                                size: 13,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              // Starting number
                                              Expanded(
                                                flex: fxStarting,
                                                child: TextFormField(
                                                  controller:
                                                      startingCtrls[_transactionModuleOptions[i]['id']!],
                                                  decoration: _dec('1'),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                                  onChanged: (_) => setS(() {}),
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              // Restart numbering
                                              Expanded(
                                                flex: fxRestart,
                                                child: FormDropdown<String>(
                                                  value:
                                                      restartCtrls[_transactionModuleOptions[i]['id']!],
                                                  items:
                                                      _transactionRestartOptions
                                                          .map(
                                                            (option) =>
                                                                option['code']!,
                                                          )
                                                          .toList(),
                                                  hint: 'None',
                                                  displayStringForValue:
                                                      (
                                                        value,
                                                      ) => _displayLookupLabel(
                                                        value,
                                                        _transactionRestartOptions,
                                                      ),
                                                  onChanged: (v) {
                                                    if (v != null) {
                                                      setS(
                                                        () =>
                                                            restartCtrls[_transactionModuleOptions[i]['id']!] =
                                                                v,
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              // Preview
                                              Expanded(
                                                flex: fxPreview,
                                                child: Text(
                                                  _preview(
                                                    _transactionModuleOptions[i]['id']!,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        AppTheme.textSecondary,
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
                              ],
                            ),
                          ),
                        ),

                        // ── Footer ───────────────────────────────────────
                        const Divider(height: 1, color: AppTheme.borderLight),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) return;
                                  final name = seriesNameCtrl.text.trim();
                                  final user = ref.read(authUserProvider);
                                  final orgId = (user?.orgId.isNotEmpty == true)
                                      ? user!.orgId
                                      : '';
                                  final modules = {
                                    for (final m in _transactionModuleOptions)
                                      m['id']!: {
                                        'prefix': prefixCtrls[m['id']!]!.text
                                            .trim(),
                                        'starting_number':
                                            int.tryParse(
                                              startingCtrls[m['id']!]!.text
                                                  .trim(),
                                            ) ??
                                            1,
                                      },
                                  };
                                  try {
                                    final res = await _apiClient.post(
                                      'transaction-series',
                                      data: {
                                        'org_id': orgId,
                                        'name': name,
                                        'code':
                                            seriesCodeCtrl.text.trim().isEmpty
                                            ? null
                                            : seriesCodeCtrl.text
                                                  .trim()
                                                  .toUpperCase(),
                                        'modules': modules,
                                      },
                                    );
                                    if (!mounted) return;
                                    if (res.success &&
                                        res.data is Map<String, dynamic>) {
                                      final newId =
                                          (res.data
                                                  as Map<String, dynamic>)['id']
                                              .toString();
                                      setState(() {
                                        _transactionSeries.add(
                                          _SeriesOption(id: newId, name: name),
                                        );
                                        _selectedTransactionSeriesIds.add(
                                          newId,
                                        );
                                      });
                                      if (mounted) Navigator.pop(ctx);
                                    } else {
                                      ZerpaiToast.error(
                                        ctx,
                                        'Failed to create transaction series.',
                                      );
                                    }
                                  } catch (e) {
                                    ZerpaiToast.error(
                                      ctx,
                                      ZerpaiBuilders.parseErrorMessage(
                                        e,
                                        'transaction series',
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text('Save'),
                              ),
                              const SizedBox(width: AppTheme.space8),
                              OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textSecondary,
                                  side: const BorderSide(
                                    color: AppTheme.borderLight,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text('Cancel'),
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
          );
        },
      ),
    );
  }

  Future<void> _showBranchCodePreferencesDialog() async {
    await showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (ctx) {
        bool isAutoGenerate = !_branchCodeManualOverride;
        final prefixCtrl = TextEditingController(text: _branchCodePrefix);
        final numberCtrl = TextEditingController(
          text: _branchCodeNextNumber.toString().padLeft(5, '0'),
        );
        const dialogTextPrimary = AppTheme.textPrimary;
        const dialogTextSecondary = AppTheme.textSecondary;
        const dialogBorderColor = AppTheme.borderLight;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              alignment: Alignment.topCenter,
              insetPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Configure Branch Code Preferences',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: dialogTextPrimary,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(
                              LucideIcons.x,
                              size: 20,
                              color: AppTheme.errorRed,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: dialogBorderColor),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your branch codes are set on auto-generate mode to save your time.',
                            style: TextStyle(
                              fontSize: 14,
                              color: dialogTextPrimary,
                            ),
                          ),
                          const Text(
                            'Are you sure about changing this setting?',
                            style: TextStyle(
                              fontSize: 14,
                              color: dialogTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          InkWell(
                            onTap: () =>
                                setDialogState(() => isAutoGenerate = true),
                            child: Row(
                              children: [
                                RadioGroup<bool>(
                                  groupValue: isAutoGenerate,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(
                                        () => isAutoGenerate = value,
                                      );
                                    }
                                  },
                                  child: const Radio<bool>(
                                    value: true,
                                    activeColor: AppTheme.primaryBlue,
                                  ),
                                ),
                                const Text(
                                  'Continue auto-generating branch codes',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const ZTooltip(
                                  message:
                                      'Set the branch code prefix and the next running number.',
                                ),
                              ],
                            ),
                          ),
                          if (isAutoGenerate) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 48, top: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Prefix',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: dialogTextSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: prefixCtrl,
                                          style: const TextStyle(fontSize: 13),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: const BorderSide(
                                                color: dialogBorderColor,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: const BorderSide(
                                                color: dialogBorderColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Next Number',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: dialogTextSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: numberCtrl,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          style: const TextStyle(fontSize: 13),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: const BorderSide(
                                                color: dialogBorderColor,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              borderSide: const BorderSide(
                                                color: dialogBorderColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () =>
                                setDialogState(() => isAutoGenerate = false),
                            child: Row(
                              children: [
                                RadioGroup<bool>(
                                  groupValue: isAutoGenerate,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(
                                        () => isAutoGenerate = value,
                                      );
                                    }
                                  },
                                  child: const Radio<bool>(
                                    value: false,
                                    activeColor: AppTheme.primaryBlue,
                                  ),
                                ),
                                const Text(
                                  'Enter branch codes manually',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: dialogTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: dialogBorderColor),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              final parsedNext =
                                  int.tryParse(numberCtrl.text.trim()) ?? 1;
                              if (!mounted) return;
                              setState(() {
                                _branchCodeManualOverride = !isAutoGenerate;
                                if (isAutoGenerate) {
                                  final nextPrefix = prefixCtrl.text.trim();
                                  _branchCodePrefix = nextPrefix.isEmpty
                                      ? 'BR-'
                                      : nextPrefix;
                                  _branchCodeNextNumber = parsedNext < 1
                                      ? 1
                                      : parsedNext;
                                  _syncBranchCodeFromPreferences();
                                }
                              });
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: dialogTextPrimary,
                              backgroundColor: AppTheme.bgLight,
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
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
            );
          },
        );
      },
    );
  }

  // ─── GSTIN dropdown field ──────────────────────────────────────────────────

  Widget _buildGstinDropdownField() {
    final List<String> items = [
      ..._orgGstins,
      if (_gstinData != null && !_orgGstins.contains(_gstinData!.gstin))
        _gstinData!.gstin,
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
            if (v == '__add__') {
              _showGstinDialog();
              return;
            }
            if (v != null) setState(() => _gstinData = _GstinData(gstin: v));
          },
        ),
        if (_gstinData != null) ...[
          const SizedBox(height: AppTheme.space6),
          Row(
            children: [
              if (_gstinData!.registrationType != null)
                Expanded(
                  child: Text(
                    _displayLookupLabel(
                      _gstinData!.registrationType,
                      _gstRegistrationTypeOptions,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              else
                const Spacer(),
              TextButton(
                onPressed: _showGstinDialog,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Edit details',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _gstinData = null),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Remove', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ─── GSTIN dialog ──────────────────────────────────────────────────────────

  void _showGstinDialog() {
    final gstinCtrl = TextEditingController(text: _gstinData?.gstin ?? '');
    final legalNameCtrl = TextEditingController(
      text: _gstinData?.legalName ?? '',
    );
    final tradeNameCtrl = TextEditingController(
      text: _gstinData?.tradeName ?? '',
    );
    String? selectedRegType = _gstinData?.registrationType;
    DateTime? registeredOn = _gstinData?.registeredOn != null
        ? DateTime.tryParse(_gstinData!.registeredOn!)
        : null;
    bool reverseCharge = _gstinData?.reverseCharge ?? false;
    bool importExport = _gstinData?.importExport ?? false;
    String? importExportAccountId = _gstinData?.importExportAccountId;
    bool digitalServices = _gstinData?.digitalServices ?? false;
    final registeredOnKey = GlobalKey();

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
              legalNameCtrl.text = (d['legalName'] ?? '').toString();
              tradeNameCtrl.text = (d['tradeName'] ?? '').toString();
              setS(() {
                selectedRegType =
                    (d['registrationType'] as String?)?.isNotEmpty == true
                    ? d['registrationType'] as String
                    : selectedRegType;
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      width: 460,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(ctx).size.height * 0.8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Taxpayer Details',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.pop(tCtx),
                                    icon: const Icon(
                                      LucideIcons.x,
                                      size: 16,
                                      color: AppTheme.textSecondary,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _tdRow(
                                      'GSTIN',
                                      d['gstin']?.toString() ?? '',
                                    ),
                                    _tdRow(
                                      'Company Name',
                                      d['legalName']?.toString() ?? '',
                                    ),
                                    _tdRow(
                                      'Date of Registration',
                                      d['registeredOn']?.toString() ?? '',
                                    ),
                                    _tdRow(
                                      'GSTIN/UIN Status',
                                      d['status']?.toString() ?? '',
                                    ),
                                    _tdRow(
                                      'Taxpayer Type',
                                      _displayLookupLabel(
                                        d['registrationType']?.toString(),
                                        _gstRegistrationTypeOptions,
                                      ),
                                    ),
                                    _tdRow(
                                      'State Jurisdiction',
                                      d['stateJurisdiction']?.toString() ?? '',
                                    ),
                                    _tdRow(
                                      'Constitution of Business',
                                      d['constitutionOfBusiness']?.toString() ??
                                          '',
                                    ),
                                    if ((d['tradeName']?.toString() ?? '')
                                        .isNotEmpty)
                                      _tdRow(
                                        'Business Trade Name',
                                        d['tradeName']!.toString(),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
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
                                        borderRadius: BorderRadius.circular(6),
                                      ),
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
              if (ctx.mounted)
                ZerpaiToast.error(
                  ctx,
                  e.toString().replaceFirst('Exception: ', ''),
                );
            } finally {
              setS(() => isFetchingTaxpayer = false);
            }
          }

          String _fmtDate(DateTime? d) {
            if (d == null) return 'Select date';
            return '${d.day.toString().padLeft(2, '0')} ${_monthNames[d.month - 1]} ${d.year}';
          }

          Widget _checkRow(
            String text,
            bool value,
            ValueChanged<bool> onChanged, {
            Widget? helper,
          }) {
            return GestureDetector(
              onTap: () => setS(() => onChanged(!value)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: Checkbox(
                          value: value,
                          onChanged: (v) => setS(() => onChanged(v ?? false)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textBody,
                          ),
                        ),
                      ),
                    ],
                  ),
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
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              width: 560,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.85,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space24,
                        vertical: AppTheme.space16,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        border: Border(
                          bottom: BorderSide(color: AppTheme.borderColor),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'GST Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(
                              LucideIcons.x,
                              size: 20,
                              color: AppTheme.errorRed,
                            ),
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
                          horizontal: AppTheme.space24,
                          vertical: AppTheme.space16,
                        ),
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
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[A-Za-z0-9]'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      gstinCtrl.value = gstinCtrl.value
                                          .copyWith(
                                            text: v.toUpperCase(),
                                            selection: TextSelection.collapsed(
                                              offset: v.length,
                                            ),
                                          );
                                      if (v.length == 15) fetchTaxpayer();
                                    },
                                  ),
                                  const SizedBox(height: AppTheme.space4),
                                  GestureDetector(
                                    onTap: isFetchingTaxpayer
                                        ? null
                                        : fetchTaxpayer,
                                    child: isFetchingTaxpayer
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 12,
                                                height: 12,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 1.5,
                                                      color: accentColor,
                                                    ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Fetching...',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: accentColor,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            'Get Taxpayer details',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: accentColor,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            // Registration type
                            ZerpaiFormRow(
                              label: 'Registration type',
                              child: FormDropdown<String>(
                                items: _gstRegistrationTypeOptions
                                    .map((option) => option['code']!)
                                    .toList(),
                                value: selectedRegType,
                                hint: 'Select type',
                                displayStringForValue: (id) =>
                                    _displayLookupLabel(
                                      id,
                                      _gstRegistrationTypeOptions,
                                    ),
                                onChanged: (v) =>
                                    setS(() => selectedRegType = v),
                              ),
                            ),
                            // Business Legal Name
                            ZerpaiFormRow(
                              label: 'Business legal name',
                              child: TextFormField(
                                controller: legalNameCtrl,
                                decoration: _dec('As per GST registration'),
                              ),
                            ),
                            // Business Trade Name
                            ZerpaiFormRow(
                              label: 'Business trade name',
                              child: TextFormField(
                                controller: tradeNameCtrl,
                                decoration: _dec('Trade / brand name'),
                              ),
                            ),
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
                                  if (picked != null)
                                    setS(() => registeredOn = picked);
                                },
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.space12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppTheme.borderLight,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _fmtDate(registeredOn),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: registeredOn == null
                                                ? AppTheme.textSecondary
                                                : AppTheme.textBody,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        LucideIcons.calendar,
                                        size: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Reverse Charge
                            ZerpaiFormRow(
                              label: 'Reverse charge',
                              crossAxisAlignment: CrossAxisAlignment.start,
                              child: _checkRow(
                                'Enable Reverse Charge in Sales transactions',
                                reverseCharge,
                                (v) => reverseCharge = v,
                                helper: GestureDetector(
                                  onTap: () => ZerpaiToast.info(
                                    ctx,
                                    'Buyer pays GST directly to the government instead of the seller.',
                                  ),
                                  child: Text(
                                    'Know more',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
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
                                    Row(
                                      children: [
                                        Text(
                                          'Custom Duty Tracking Account',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                          ),
                                        ),
                                        const Text(
                                          ' *',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.errorRed,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppTheme.space6),
                                    FormDropdown<String>(
                                      value: importExportAccountId,
                                      hint: 'Select account',
                                      items: const [],
                                      displayStringForValue: (v) => v,
                                      onChanged: (v) =>
                                          setS(() => importExportAccountId = v),
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
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
                        horizontal: AppTheme.space24,
                        vertical: AppTheme.space16,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.borderColor),
                        ),
                      ),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              final gstin = gstinCtrl.text.trim().toUpperCase();
                              if (gstin.isEmpty) {
                                Navigator.pop(ctx);
                                return;
                              }
                              setState(() {
                                _gstinData = _GstinData(
                                  gstin: gstin,
                                  registrationType: selectedRegType,
                                  legalName: legalNameCtrl.text.trim(),
                                  tradeName: tradeNameCtrl.text.trim(),
                                  registeredOn: registeredOn
                                      ?.toIso8601String()
                                      .substring(0, 10),
                                  reverseCharge: reverseCharge,
                                  importExport: importExport,
                                  importExportAccountId: importExportAccountId,
                                  digitalServices: digitalServices,
                                );
                                if (!_orgGstins.contains(gstin))
                                  _orgGstins = [..._orgGstins, gstin];
                              });
                              Navigator.pop(ctx);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space24,
                                vertical: AppTheme.space12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.space4,
                                ),
                              ),
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
                                horizontal: AppTheme.space24,
                                vertical: AppTheme.space12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.space4,
                                ),
                                side: const BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                              ),
                            ),
                            child: const Text('Cancel'),
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

  // ─── Location access ───────────────────────────────────────────────────────

  Widget _buildLocationAccessContent() {
    final accentColor = ref.watch(appBrandingProvider).accentColor;
    final int count = _locationUsers.length;
    final bool showAccessError =
        _showValidationErrors && !_provideAccessToAll && _locationUsers.isEmpty;

    final addedUserIds = _locationUsers.map((u) => u['userId']).toSet();
    final availableToAdd = _orgUsers
        .where((u) => !addedUserIds.contains(u['id']?.toString()))
        .toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: showAccessError ? AppTheme.errorRed : AppTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space14,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: count > 0 || _provideAccessToAll
                              ? accentColor
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _provideAccessToAll
                                  ? 'All users have access'
                                  : count > 0
                                  ? '$count user${count == 1 ? '' : 's'} selected'
                                  : 'No users selected',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _provideAccessToAll
                                  ? 'All users in your organization can create and access transactions for this location.'
                                  : 'Select the users who can create and access transactions for this location.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(
                    () => _provideAccessToAll = !_provideAccessToAll,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppTheme.space16,
                      top: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: Checkbox(
                            value: _provideAccessToAll,
                            onChanged: (v) =>
                                setState(() => _provideAccessToAll = v ?? true),
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
                ),
              ],
            ),
          ),
          if (_provideAccessToAll) ...[
            const Divider(height: 1, color: AppTheme.borderLight),
            const Padding(
              padding: EdgeInsets.all(AppTheme.space16),
              child: Text(
                'All users in your organization have access to this branch.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
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
                        letterSpacing: 0.4,
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
                        letterSpacing: 0.4,
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
                  color: Color(0xFFF7F8FB),
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
                            radius: 16,
                            backgroundColor: AppTheme.bgLight,
                            child: Text(
                              ((user['name'] ?? '').toString().trim().isNotEmpty
                                      ? (user['name'] ?? '')
                                            .toString()
                                            .trim()[0]
                                      : '?')
                                  .toUpperCase(),
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
                        _formatUserRoleLabel(user['role']),
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
                        color: AppTheme.errorRed,
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
                              final user = availableToAdd.firstWhere(
                                (u) => u['id'].toString() == id,
                                orElse: () => <String, dynamic>{},
                              );
                              final name =
                                  (user['name'] ?? user['full_name'] ?? '')
                                      .toString();
                              final email = (user['email'] ?? '').toString();
                              return name.isNotEmpty ? name : email;
                            },
                            onChanged: (id) {
                              if (id == null) return;
                              final user = availableToAdd.firstWhere(
                                (u) => u['id'].toString() == id,
                                orElse: () => <String, dynamic>{},
                              );
                              if (user.isEmpty) return;
                              setState(
                                () => _locationUsers.add({
                                  'userId': id,
                                  'name':
                                      (user['name'] ?? user['full_name'] ?? '')
                                          .toString(),
                                  'email': (user['email'] ?? '').toString(),
                                  'role': (user['role_label'] ?? user['role'] ?? '')
                                      .toString(),
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
            if (showAccessError)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.space16,
                  0,
                  AppTheme.space16,
                  AppTheme.space12,
                ),
                child: Text(
                  'Select at least one user or provide access to all users.',
                  style: TextStyle(fontSize: 11, color: AppTheme.errorRed),
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

      final exists = _businessTypes.any((type) => type['code'] == code);
      if (exists) {
        ZerpaiToast.error(
          ctx,
          'A business type with this code already exists.',
        );
        return;
      }

      setS(() => isSaving = true);
      try {
        final user = ref.read(authUserProvider);
        final orgId = (user?.orgId.isNotEmpty == true)
            ? user!.orgId
            : '';
        final res = await _apiClient.post(
          'branches/business-types',
          data: {
            'org_id': orgId,
            'business_type': code,
            'label': label,
            'description': label,
          },
        );
        if (!mounted) return;
        if (res.success && res.data is Map<String, dynamic>) {
          final row = res.data as Map<String, dynamic>;
          setState(() {
            _businessTypes.add({
              'id': (row['code'] ?? code).toString(),
              'code': (row['code'] ?? code).toString(),
              'label': (row['label'] ?? label).toString(),
            });
            _businessTypes.sort(
              (a, b) => (a['label'] ?? '').compareTo(b['label'] ?? ''),
            );
          });
          setS(() {
            isSaving = false;
            showForm = false;
          });
          codeCtrl.clear();
          labelCtrl.clear();
          ZerpaiToast.success(ctx, 'Business type added.');
          return;
        }
        ZerpaiToast.error(ctx, res.message ?? 'Failed to add business type.');
      } catch (_) {
        ZerpaiToast.error(ctx, 'Failed to add business type.');
      } finally {
        if (ctx.mounted) {
          setS(() => isSaving = false);
        }
      }
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
                                textCapitalization:
                                    TextCapitalization.characters,
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
                                    onPressed: isSaving
                                        ? null
                                        : () => saveType(setS, ctx),
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
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
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
                              const Divider(
                                height: 1,
                                color: AppTheme.borderLight,
                              ),
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
        border: Border.all(color: AppTheme.borderLight),
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
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: _logoPicked != null
                    ? Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(
                                _logoPicked!.bytes!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _logoPicked = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                    )
                                  ],
                                ),
                                child: const Icon(
                                  LucideIcons.trash2,
                                  size: 14,
                                  color: AppTheme.errorRed,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _logoUrl != null
                        ? Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    _logoUrl!,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(
                                        LucideIcons.imageOff,
                                        color: AppTheme.textSecondary,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(() => _logoUrl = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      LucideIcons.trash2,
                                      size: 14,
                                      color: AppTheme.errorRed,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.upload,
                                size: 20,
                                color: AppTheme.textSecondary,
                              ),
                              SizedBox(height: AppTheme.space8),
                              Text(
                                'Upload your branch logo',
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
                  style: TextStyle(fontSize: 12, color: AppTheme.textBody),
                ),
                SizedBox(height: AppTheme.space8),
                Text(
                  'Dimensions: 240 × 240 pixels @ 72 DPI',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                SizedBox(height: AppTheme.space4),
                Text(
                  'Supported files: jpg, jpeg, png, gif, bmp',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                SizedBox(height: AppTheme.space4),
                Text(
                  'Maximum file size: 1MB',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space24,
              vertical: AppTheme.space12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
        ),
        const SizedBox(width: AppTheme.space12),
        OutlinedButton(
          onPressed: _isSaving
              ? null
              : () => context.go(AppRoutes.settingsBranches),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
            side: const BorderSide(color: AppTheme.borderLight),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space24,
              vertical: AppTheme.space12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
      ],
    );
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
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: date == null
                    ? AppTheme.textSecondary
                    : AppTheme.textBody,
              ),
            ),
          ),
          const Icon(
            LucideIcons.calendar,
            size: 14,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  int? get _subscriptionTotalDays {
    final from = _dateOnly(_subscriptionFrom);
    final to = _dateOnly(_subscriptionTo);
    if (from == null || to == null || to.isBefore(from)) {
      return null;
    }
    return to.difference(from).inDays + 1;
  }

  int? get _subscriptionRemainingDays {
    final from = _dateOnly(_subscriptionFrom);
    final to = _dateOnly(_subscriptionTo);
    if (from == null || to == null || to.isBefore(from)) {
      return null;
    }

    final today = _dateOnly(DateTime.now())!;
    if (today.isBefore(from)) {
      return _subscriptionTotalDays;
    }
    if (today.isAfter(to)) {
      return 0;
    }
    return to.difference(today).inDays + 1;
  }

  DateTime? _dateOnly(DateTime? value) {
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day);
  }

  static const List<String> _monthNames = [
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

  Widget _buildStaticField(String value) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderLight),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
      ),
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
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textBody,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppTheme.space12,
      vertical: AppTheme.space10,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppTheme.borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppTheme.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: ref.read(appBrandingProvider).accentColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppTheme.errorRed),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppTheme.errorRed),
    ),
    filled: true,
    fillColor: Colors.white,
  );
}

class _GstinData {
  final String gstin;
  final String? legalName;
  final String? tradeName;
  final String? registrationType;
  final String? registeredOn;
  final bool reverseCharge;
  final bool importExport;
  final String? importExportAccountId;
  final bool digitalServices;

  const _GstinData({
    required this.gstin,
    this.legalName,
    this.tradeName,
    this.registrationType,
    this.registeredOn,
    this.reverseCharge = false,
    this.importExport = false,
    this.importExportAccountId,
    this.digitalServices = false,
  });
}
