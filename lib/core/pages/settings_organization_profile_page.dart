import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/providers/app_branding_provider.dart';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/form_row.dart';
import 'package:zerpai_erp/shared/widgets/settings_fixed_header_layout.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';
import 'package:zerpai_erp/shared/services/storage_service.dart';

// TODO(auth): Remove _kDevOrgId and all fallbacks that reference it once auth
// is fully enabled. Replace every usage with the real authUserProvider orgId.
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

class _TimezoneOption {
  final String id;
  final String name;
  final String tzdbName;
  final String utcOffset;
  final String display;
  final String? countryId;

  const _TimezoneOption({
    required this.id,
    required this.name,
    required this.tzdbName,
    required this.utcOffset,
    required this.display,
    this.countryId,
  });
}

class _DistrictOption {
  final String id;
  final String name;
  final String? code;
  const _DistrictOption({required this.id, required this.name, this.code});
}

class _LocalBodyOption {
  final String id;
  final String name;
  final String? code;
  final String bodyType;
  const _LocalBodyOption({
    required this.id,
    required this.name,
    required this.bodyType,
    this.code,
  });
}

class _WardOption {
  final String id;
  final int? wardNo;
  final String name;
  final String? code;
  final String displayName;
  const _WardOption({
    required this.id,
    this.wardNo,
    required this.name,
    this.code,
    required this.displayName,
  });
}

class _StateOption {
  final String id;
  final String name;
  final String? code;
  const _StateOption({required this.id, required this.name, this.code});
}

class SettingsOrganizationProfilePage extends ConsumerStatefulWidget {
  const SettingsOrganizationProfilePage({super.key});

  @override
  ConsumerState<SettingsOrganizationProfilePage> createState() =>
      _SettingsOrganizationProfilePageState();
}

class _SettingsOrganizationProfilePageState
    extends ConsumerState<SettingsOrganizationProfilePage> {
  // Populated from /lookups/industries
  List<String> _industryOptions = <String>[];
  // Populated from /lookups/timezones (re-fetched on country change)
  List<_TimezoneOption> _timeZoneOptions = <_TimezoneOption>[];
  // Populated from /lookups/company-id-labels
  List<String> _companyIdOptions = <String>[];
  // Maps country name → UUID for timezone filtering
  Map<String, String> _countryIdByName = <String, String>{};
  // Maps state name ↔ UUID for org profile persistence
  Map<String, String> _stateIdByName = <String, String>{};

  static const List<String> _fiscalYearOptions = <String>[
    'January - December',
    'February - January',
    'March - February',
    'April - March',
    'May - April',
    'June - May',
    'July - June',
    'August - July',
    'September - August',
    'October - September',
    'November - October',
    'December - November',
  ];

  // Group label → list of DateFormat patterns
  static const Map<String, List<String>> _dateFormatGroups =
      <String, List<String>>{
        'short': <String>['MM-dd-yy', 'dd-MM-yy', 'yy-MM-dd'],
        'medium': <String>['MM-dd-yyyy', 'dd-MM-yyyy', 'yyyy-MM-dd'],
        'long': <String>[
          'dd MMM yyyy',
          'dd MMMM yyyy',
          'MMMM dd, yyyy',
          'EEE, MMMM dd, yyyy',
          'EEEE, MMMM dd, yyyy',
          'MMM dd, yyyy',
          'yyyy MM dd',
        ],
        'date & time': <String>[
          'dd MMM yyyy, hh:mm a',
          'dd MMM yyyy, HH:mm',
          'dd-MM-yyyy HH:mm',
          'MM-dd-yyyy hh:mm a',
          'yyyy-MM-dd HH:mm',
          'EEE, dd MMM yyyy HH:mm',
        ],
      };

  static const List<String> _dateSeparatorOptions = <String>['-', '/', '.'];


  static const List<_ProfileNavSection> _navSections = <_ProfileNavSection>[
    _ProfileNavSection(
      title: 'Organization Settings',
      blocks: <_ProfileNavBlock>[
        _ProfileNavBlock(
          title: 'Organization',
          items: <_ProfileNavEntry>[
            _ProfileNavEntry(
              label: 'Profile',
              route: AppRoutes.settingsOrgProfile,
            ),
            _ProfileNavEntry(
              label: 'Branding',
              route: AppRoutes.settingsOrgBranding,
            ),
            _ProfileNavEntry(
              label: 'Branches',
              route: AppRoutes.settingsBranches,
            ),
            _ProfileNavEntry(
              label: 'Warehouses',
              route: AppRoutes.settingsWarehouses,
            ),
            _ProfileNavEntry(label: 'Approvals'),
            _ProfileNavEntry(label: 'Manage Subscription'),
          ],
        ),
        _ProfileNavBlock(
          title: 'Users & Roles',
          items: <_ProfileNavEntry>[
            _ProfileNavEntry(label: 'Users'),
            _ProfileNavEntry(label: 'Roles'),
            _ProfileNavEntry(label: 'User Preferences'),
          ],
        ),
        _ProfileNavBlock(
          title: 'Taxes & Compliance',
          items: <_ProfileNavEntry>[
            _ProfileNavEntry(label: 'Taxes'),
            _ProfileNavEntry(label: 'Direct Taxes'),
            _ProfileNavEntry(label: 'e-Way Bills'),
            _ProfileNavEntry(label: 'e-Invoicing'),
            _ProfileNavEntry(label: 'MSME Settings'),
          ],
        ),
        _ProfileNavBlock(
          title: 'Setup & Configurations',
          items: <_ProfileNavEntry>[
            _ProfileNavEntry(label: 'General'),
            _ProfileNavEntry(label: 'Currencies'),
            _ProfileNavEntry(label: 'Reminders'),
            _ProfileNavEntry(label: 'Customer Portal'),
          ],
        ),
        _ProfileNavBlock(
          title: 'Customization',
          items: <_ProfileNavEntry>[
            _ProfileNavEntry(label: 'Transaction Number Series'),
            _ProfileNavEntry(label: 'PDF Templates'),
            _ProfileNavEntry(label: 'Email Notifications'),
            _ProfileNavEntry(label: 'SMS Notifications'),
            _ProfileNavEntry(label: 'Reporting Tags'),
            _ProfileNavEntry(label: 'Web Tabs'),
          ],
        ),
        _ProfileNavBlock(
          title: 'Automation',
          items: <_ProfileNavEntry>[
            _ProfileNavEntry(label: 'Workflow Rules'),
            _ProfileNavEntry(label: 'Workflow Actions'),
            _ProfileNavEntry(
              label: 'Workflow Logs',
              route: AppRoutes.auditLogs,
            ),
          ],
        ),
      ],
    ),
    _ProfileNavSection(
      title: 'Module Settings',
      blocks: <_ProfileNavBlock>[
        _ProfileNavBlock(
          title: 'General',
          items: <_ProfileNavEntry>[
            _ProfileNavEntry(
              label: 'Customers and Vendors',
              route: AppRoutes.salesCustomers,
            ),
            _ProfileNavEntry(label: 'Items', route: AppRoutes.itemsReport),
          ],
        ),
        _ProfileNavBlock(
          title: 'Inventory',
          items: <_ProfileNavEntry>[
            _ProfileNavEntry(label: 'Assemblies', route: AppRoutes.assemblies),
            _ProfileNavEntry(
              label: 'Inventory Adjustments',
              route: AppRoutes.inventoryAdjustments,
            ),
            _ProfileNavEntry(label: 'Picklists', route: AppRoutes.picklists),
            _ProfileNavEntry(label: 'Packages', route: AppRoutes.packages),
            _ProfileNavEntry(label: 'Shipments', route: AppRoutes.shipments),
            _ProfileNavEntry(
              label: 'Transfer Orders',
              route: AppRoutes.transferOrders,
            ),
          ],
        ),
      ],
    ),
  ];

  final ApiClient _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _bodyScrollController = ScrollController();
  final TextEditingController _organizationNameController =
      TextEditingController();
  final TextEditingController _companyIdValueController =
      TextEditingController();
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
  final TextEditingController _paymentStubFaxController =
      TextEditingController();
  String? _selectedPaymentStubState;
  final Set<String> _expandedBlocks = <String>{'Organization'};
  final List<_ProfileAdditionalField> _additionalFields =
      <_ProfileAdditionalField>[_ProfileAdditionalField()];
  final GlobalKey _logoSectionKey = GlobalKey();
  final GlobalKey _organizationNameKey = GlobalKey();
  final GlobalKey _industryKey = GlobalKey();
  final GlobalKey _organizationLocationKey = GlobalKey();
  final GlobalKey _stateKey = GlobalKey();
  final GlobalKey _paymentStubKey = GlobalKey();
  final GlobalKey _primaryContactKey = GlobalKey();
  final GlobalKey _baseCurrencyKey = GlobalKey();
  final GlobalKey _fiscalYearKey = GlobalKey();

  final GlobalKey _timeZoneKey = GlobalKey();
  final GlobalKey _dateFormatKey = GlobalKey();
  final GlobalKey _companyIdKey = GlobalKey();
  final GlobalKey _additionalFieldsKey = GlobalKey();

  // LSGD fields for Payment Stub Address (Kerala specific)
  List<_DistrictOption> _paymentStubDistrictOptions = <_DistrictOption>[];
  List<_LocalBodyOption> _paymentStubAllLocalBodyOptions = <_LocalBodyOption>[];
  List<_LocalBodyOption> _paymentStubLocalBodyOptions = <_LocalBodyOption>[];
  List<_WardOption> _paymentStubWardOptions = const [];
  String? _selectedPaymentStubDistrictId;
  String? _selectedPaymentStubLocalBodyType;
  String? _selectedPaymentStubLocalBodyId;
  String? _selectedPaymentStubWardId;
  List<_StateOption> _paymentStubStateLookupRows = <_StateOption>[];

  // Pharmacy-specific compliance fields
  bool _isDrugRegistered = false;
  String? _drugLicenceType;
  final TextEditingController _drugLicense20Controller = TextEditingController();
  final TextEditingController _drugLicense21Controller = TextEditingController();
  final TextEditingController _drugLicense20BController = TextEditingController();
  final TextEditingController _drugLicense21BController = TextEditingController();

  bool _isFssaiRegistered = false;
  final TextEditingController _fssaiNumberController = TextEditingController();

  bool _isMsmeRegistered = false;
  String? _msmeRegistrationType;
  final TextEditingController _msmeNumberController = TextEditingController();

  // Pharmacy compliance documents/attachments
  List<PlatformFile> _drugLicense20Docs = [];
  List<PlatformFile> _drugLicense21Docs = [];
  List<PlatformFile> _drugLicense20BDocs = [];
  List<PlatformFile> _drugLicense21BDocs = [];
  List<PlatformFile> _fssaiDocs = [];
  List<PlatformFile> _msmeDocs = [];

  bool get _showKeralaLsgdFields =>
      _selectedPaymentStubState?.toLowerCase() == 'kerala';

  String _localBodyTypeLabel(String value) {
    switch (value) {
      case 'grama_panchayat':
        return 'Grama Panchayat';
      case 'municipality':
        return 'Municipality';
      case 'corporation':
        return 'Corporation';
      default:
        return value;
    }
  }

  List<String> get _paymentStubAvailableLocalBodyTypeOptions {
    final seen = <String>{};
    return _paymentStubAllLocalBodyOptions
        .map((localBody) => localBody.bodyType.trim())
        .where((bodyType) => bodyType.isNotEmpty && seen.add(bodyType))
        .toList();
  }

  _StateOption? get _selectedPaymentStubStateRow {
    if (_selectedPaymentStubState == null || _selectedPaymentStubState!.isEmpty)
      return null;
    for (final option in _paymentStubStateLookupRows) {
      if (option.name.toLowerCase() ==
          _selectedPaymentStubState!.toLowerCase()) {
        return option;
      }
    }
    return null;
  }

  Future<void> _loadPaymentStubStates() async {
    try {
      final res = await _apiClient.get('lookups/states/IN');
      if (res.success && res.data is List) {
        final states = (res.data as List)
            .whereType<Map<String, dynamic>>()
            .map(
              (state) => _StateOption(
                id: (state['id'] ?? '').toString(),
                name: (state['name'] ?? '').toString(),
                code: state['code']?.toString(),
              ),
            )
            .where((state) => state.name.isNotEmpty)
            .toList();
        if (!mounted) return;
        setState(() {
          _paymentStubStateLookupRows = states;
        });
        // If Kerala is already selected (from load), trigger district load
        if (_showKeralaLsgdFields) {
          _loadDistrictsForSelectedPaymentStubState();
        }
      }
    } catch (_) {}
  }

  Future<void> _loadDistrictsForSelectedPaymentStubState({
    String? preferredDistrictId,
  }) async {
    final stateRow = _selectedPaymentStubStateRow;
    if (stateRow == null || stateRow.id.isEmpty) {
      if (!mounted) return;
      setState(() {
        _paymentStubDistrictOptions = const [];
        _selectedPaymentStubDistrictId = null;
      });
      return;
    }

    try {
      final res = await _apiClient.get(
        'lookups/districts',
        queryParameters: <String, dynamic>{'stateId': stateRow.id},
      );
      if (!mounted) return;
      final districts = res.success && res.data is List
          ? (res.data as List)
                .whereType<Map<String, dynamic>>()
                .map(
                  (district) => _DistrictOption(
                    id: (district['id'] ?? '').toString(),
                    name: (district['name'] ?? '').toString(),
                    code: district['code']?.toString(),
                  ),
                )
                .where((district) => district.id.isNotEmpty)
                .toList()
          : <_DistrictOption>[];

      setState(() {
        _paymentStubDistrictOptions = districts;
        if (preferredDistrictId != null &&
            districts
                .any((district) => district.id == preferredDistrictId)) {
          _selectedPaymentStubDistrictId = preferredDistrictId;
        } else if (_selectedPaymentStubDistrictId != null &&
            districts.any(
              (district) => district.id == _selectedPaymentStubDistrictId,
            )) {
          // keep current
        } else {
          _selectedPaymentStubDistrictId = null;
        }
      });
      if (_selectedPaymentStubDistrictId != null) {
        _loadLocalBodiesForSelectedPaymentStubDistrict();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paymentStubDistrictOptions = const [];
        _selectedPaymentStubDistrictId = null;
      });
    }
  }

  Future<void> _loadLocalBodiesForSelectedPaymentStubDistrict({
    String? preferredLocalBodyId,
    bool ignoreTypeFilter = false,
  }) async {
    if (_selectedPaymentStubDistrictId == null ||
        _selectedPaymentStubDistrictId!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _paymentStubAllLocalBodyOptions = const [];
        _paymentStubLocalBodyOptions = const [];
        _selectedPaymentStubLocalBodyId = null;
        if (ignoreTypeFilter) _selectedPaymentStubLocalBodyType = null;
      });
      return;
    }

    try {
      final res = await _apiClient.get(
        'lookups/local-bodies',
        queryParameters: <String, dynamic>{
          'districtId': _selectedPaymentStubDistrictId,
        },
      );
      if (!mounted) return;
      final allLocalBodies = res.success && res.data is List
          ? (res.data as List)
                .whereType<Map<String, dynamic>>()
                .map(
                  (localBody) => _LocalBodyOption(
                    id: (localBody['id'] ?? '').toString(),
                    name: (localBody['name'] ?? '').toString(),
                    code: localBody['code']?.toString(),
                    bodyType: (localBody['body_type'] ?? '').toString(),
                  ),
                )
                .where((localBody) => localBody.id.isNotEmpty)
                .toList()
          : <_LocalBodyOption>[];

      setState(() {
        _paymentStubAllLocalBodyOptions = allLocalBodies;
        final availableTypes = _paymentStubAvailableLocalBodyTypeOptions;
        if (ignoreTypeFilter ||
            (_selectedPaymentStubLocalBodyType != null &&
                !availableTypes.contains(_selectedPaymentStubLocalBodyType))) {
          _selectedPaymentStubLocalBodyType = null;
        }

        final filteredLocalBodies = _selectedPaymentStubLocalBodyType == null ||
                _selectedPaymentStubLocalBodyType!.isEmpty
            ? allLocalBodies
            : allLocalBodies
                .where(
                  (localBody) =>
                      localBody.bodyType == _selectedPaymentStubLocalBodyType,
                )
                .toList();

        _paymentStubLocalBodyOptions = filteredLocalBodies;
        if (preferredLocalBodyId != null) {
          final preferred = allLocalBodies
              .where((localBody) => localBody.id == preferredLocalBodyId)
              .cast<_LocalBodyOption?>()
              .firstOrNull;
          if (preferred != null) {
            _selectedPaymentStubLocalBodyId = preferred.id;
            _selectedPaymentStubLocalBodyType = preferred.bodyType;
            _loadWardsForSelectedPaymentStubLocalBody();
            return;
          }
        }

        if (_selectedPaymentStubLocalBodyId != null &&
            filteredLocalBodies.any(
              (localBody) => localBody.id == _selectedPaymentStubLocalBodyId,
            )) {
          _loadWardsForSelectedPaymentStubLocalBody();
          return;
        }

        _selectedPaymentStubLocalBodyId = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paymentStubAllLocalBodyOptions = const [];
        _paymentStubLocalBodyOptions = const [];
        _selectedPaymentStubLocalBodyId = null;
        if (ignoreTypeFilter) _selectedPaymentStubLocalBodyType = null;
      });
    }
  }

  Future<void> _loadWardsForSelectedPaymentStubLocalBody({
    String? preferredWardId,
  }) async {
    if (_selectedPaymentStubLocalBodyId == null ||
        _selectedPaymentStubLocalBodyId!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _paymentStubWardOptions = const [];
        _selectedPaymentStubWardId = null;
      });
      return;
    }

    try {
      final res = await _apiClient.get(
        'lookups/wards',
        queryParameters: <String, dynamic>{
          'localBodyId': _selectedPaymentStubLocalBodyId,
        },
      );
      if (!mounted) return;
      final wards = res.success && res.data is List
          ? (res.data as List)
                .whereType<Map<String, dynamic>>()
                .map(
                  (ward) => _WardOption(
                    id: (ward['id'] ?? '').toString(),
                    wardNo: ward['ward_no'] is int
                        ? ward['ward_no'] as int
                        : int.tryParse((ward['ward_no'] ?? '').toString()),
                    name: (ward['name'] ?? '').toString(),
                    code: ward['code']?.toString(),
                    displayName: (ward['display_name'] ?? ward['name'] ?? '')
                        .toString(),
                  ),
                )
                .where((ward) => ward.id.isNotEmpty)
                .toList()
          : <_WardOption>[];

      setState(() {
        _paymentStubWardOptions = wards;
        if (preferredWardId != null &&
            wards.any((ward) => ward.id == preferredWardId)) {
          _selectedPaymentStubWardId = preferredWardId;
        } else if (_selectedPaymentStubWardId != null &&
            wards.any((ward) => ward.id == _selectedPaymentStubWardId)) {
          // keep current
        } else {
          _selectedPaymentStubWardId = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paymentStubWardOptions = const [];
        _selectedPaymentStubWardId = null;
      });
    }
  }

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String _organizationName = '';
  String _organizationId = '';
  String _organizationSystemId = '';
  String _primaryContactName = '';
  String _primaryContactEmail = '';
  String? _selectedIndustry;
  String? _selectedLocation;
  String? _selectedState;
  String? _selectedBaseCurrency;
  String? _selectedBaseCurrencyDecimals;
  String? _selectedBaseCurrencyFormat;
  String? _selectedFiscalYear;

  String? _selectedTimeZone;
  String? _selectedDateFormat;
  String? _selectedDateSeparator;
  String? _selectedCompanyIdLabel;
  bool _hasSeparatePaymentStubAddress = false;
  List<String> _currencyOptions = <String>[];
  Map<String, Map<String, dynamic>> _currencyDataByCode =
      <String, Map<String, dynamic>>{};
  List<String> _countryOptions = <String>[];
  List<String> _stateOptions = <String>[];
  Uint8List? _logoBytes;
  String? _logoFileName;
  String? _existingLogoUrl;
  bool _isUploadingLogo = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _bodyScrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _organizationNameController.dispose();
    _companyIdValueController.dispose();
    _paymentStubAttentionController.dispose();
    _paymentStubStreet1Controller.dispose();
_paymentStubStreet2Controller.dispose();
    _paymentStubCityController.dispose();
    _paymentStubPincodeController.dispose();
    _paymentStubPhoneController.dispose();
    _paymentStubFaxController.dispose();

    _drugLicense20Controller.dispose();
    _drugLicense21Controller.dispose();
    _drugLicense20BController.dispose();
    _drugLicense21BController.dispose();
    _fssaiNumberController.dispose();
    _msmeNumberController.dispose();

    for (final field in _additionalFields) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '',
      useHorizontalPadding: false,
      useTopPadding: false,
      enableBodyScroll: false,
      searchFocusNode: _searchFocusNode,
      child: Form(
        key: _formKey,
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              _SettingsProfileTopBar(
                organizationName: _organizationName,
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                searchItems: _buildSettingsSearchItems(),
                onBack: () => context.go(AppRoutes.settings),
                onClose: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.go(AppRoutes.home);
                },
                onSearchSubmitted: _handleSearch,
              ),
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
      ),
    );
  }

  _TimezoneOption? get _selectedTimeZoneOption {
    final selected = _selectedTimeZone;
    if (selected == null || selected.isEmpty) {
      return null;
    }

    for (final option in _timeZoneOptions) {
      if (option.tzdbName == selected ||
          option.display == selected ||
          option.name == selected ||
          option.id == selected) {
        return option;
      }
    }

    return null;
  }

  String? _matchOption(String raw, List<String> options) {
    if (raw.isEmpty) {
      return null;
    }
    for (final option in options) {
      if (option.toLowerCase() == raw.toLowerCase()) {
        return option;
      }
    }
    return null;
  }

  Future<Response<dynamic>?> _safeGet(
    String path, {
    bool useCache = false,
  }) async {
    try {
      return await _apiClient.get(path, useCache: useCache);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(authUserProvider);

      // TODO(auth): Remove _kDevOrgId fallback once auth is enabled.
      final String effectiveOrgId = (user?.orgId.isNotEmpty == true)
          ? user!.orgId
          : _kDevOrgId;

      final List<Future<Response<dynamic>?>> futures =
          <Future<Response<dynamic>?>>[
            if (effectiveOrgId.isNotEmpty)
              _safeGet('/lookups/org/$effectiveOrgId', useCache: false),
            _safeGet('/lookups/currencies', useCache: false),
            _safeGet('/lookups/countries', useCache: false),
            _safeGet('/lookups/industries', useCache: false),
            _safeGet('/lookups/timezones', useCache: false),
            _safeGet('/lookups/company-id-labels', useCache: false),
          ];

      final List<Response<dynamic>?> responses =
          await Future.wait<Response<dynamic>?>(futures);

      final bool hasOrgData = effectiveOrgId.isNotEmpty;
      final int offset = hasOrgData ? 1 : 0;
      final Response<dynamic>? orgResponse = hasOrgData ? responses[0] : null;
      final Response<dynamic>? currenciesResponse = responses[offset];
      final Response<dynamic>? countriesResponse = responses[offset + 1];
      final Response<dynamic>? industriesResponse = responses[offset + 2];
      final Response<dynamic>? timezonesResponse = responses[offset + 3];
      final Response<dynamic>? companyIdLabelsResponse = responses[offset + 4];

      final Map<String, dynamic> orgData =
          orgResponse != null &&
              orgResponse.success &&
              orgResponse.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(orgResponse.data as Map<String, dynamic>)
          : <String, dynamic>{};

      final List<String> currencyOptions = <String>[];
      final Map<String, Map<String, dynamic>> currencyDataByCode =
          <String, Map<String, dynamic>>{};
      if (currenciesResponse != null &&
          currenciesResponse.success &&
          currenciesResponse.data is List) {
        for (final dynamic item
            in (currenciesResponse.data as List).whereType<Map>()) {
          final String code = (item['code'] ?? '').toString();
          if (code.isNotEmpty) {
            currencyOptions.add(code);
            currencyDataByCode[code] = Map<String, dynamic>.from(
              item as Map<dynamic, dynamic>,
            );
          }
        }
      }

      final List<String> countryOptions = <String>[];
      final Map<String, String> countryIdByName = <String, String>{};
      if (countriesResponse != null &&
          countriesResponse.success &&
          countriesResponse.data is List) {
        for (final dynamic item
            in (countriesResponse.data as List).whereType<Map>()) {
          final String name = (item['name'] ?? '').toString();
          final String id = (item['id'] ?? '').toString();
          if (name.isNotEmpty) {
            countryOptions.add(name);
            if (id.isNotEmpty) countryIdByName[name] = id;
          }
        }
      }

      List<String> _parseStringList(Response<dynamic> r) =>
          r.success && r.data is List
          ? (r.data as List)
                .map((dynamic e) => e.toString())
                .where((s) => s.isNotEmpty)
                .toList()
          : <String>[];

      final List<String> industryOptions = industriesResponse != null
          ? _parseStringList(industriesResponse)
          : <String>[];
      final List<_TimezoneOption> timezoneOptions = timezonesResponse != null
          ? _parseTimezoneOptions(timezonesResponse)
          : <_TimezoneOption>[];
      final List<String> companyIdOptions = companyIdLabelsResponse != null
          ? _parseStringList(companyIdLabelsResponse)
          : <String>[];

      if (!mounted) return;

      setState(() {
        _organizationName = (orgData['name'] ?? user?.orgName ?? '')
            .toString()
            .trim();
        _organizationId = (orgData['id'] ?? user?.orgId ?? '').toString();
        _organizationSystemId = (orgData['system_id'] ?? '').toString().trim();
        _primaryContactName = user?.fullName.trim() ?? '';
        _primaryContactEmail = user?.email.trim() ?? '';
        _organizationNameController.text = _organizationName;
        _currencyOptions = currencyOptions;
        _currencyDataByCode = currencyDataByCode;
        _countryOptions = countryOptions;
        _countryIdByName = countryIdByName;
        _industryOptions = industryOptions;
        _timeZoneOptions = timezoneOptions;
        _companyIdOptions = companyIdOptions;
        _selectedBaseCurrency = _matchOption(
          (orgData['base_currency'] ?? '').toString(),
          _currencyOptions,
        );
        final selectedCurrencyData =
            _currencyDataByCode[_selectedBaseCurrency] ?? <String, dynamic>{};
        final orgDecimals = orgData['base_currency_decimals']?.toString();
        final orgFormat = (orgData['base_currency_format'] ?? '').toString();
        _selectedBaseCurrencyDecimals =
            orgDecimals != null && orgDecimals.isNotEmpty
            ? orgDecimals
            : selectedCurrencyData['decimals']?.toString();
        _selectedBaseCurrencyFormat = orgFormat.isNotEmpty
            ? orgFormat
            : selectedCurrencyData['format']?.toString();
        _selectedLocation = _matchOption(
          (orgData['country'] ?? '').toString(),
          _countryOptions,
        );
        _selectedIndustry = _matchOption(
          (orgData['industry'] ?? '').toString(),
          _industryOptions,
        );
        _selectedFiscalYear = _matchOption(
          (orgData['fiscal_year'] ?? '').toString(),
          _fiscalYearOptions,
        );

        _selectedTimeZone = _matchTimezoneValue(
          (orgData['timezone_tzdb_name'] ??
                  orgData['timezone_display'] ??
                  orgData['timezone'] ??
                  '')
              .toString(),
          _timeZoneOptions,
        );
        _selectedDateFormat = _matchOption(
          (orgData['date_format'] ?? '').toString(),
          _dateFormatGroups.values.expand((e) => e).toList(),
        );
        _selectedDateSeparator = _matchOption(
          (orgData['date_separator'] ?? '').toString(),
          _dateSeparatorOptions,
        );
        _selectedCompanyIdLabel = _matchOption(
          (orgData['company_id_label'] ?? '').toString(),
          _companyIdOptions,
        );
        _companyIdValueController.text = (orgData['company_id_value'] ?? '')
            .toString();
        _existingLogoUrl = (orgData['logo_url'] ?? '').toString().trim().isEmpty
            ? null
            : (orgData['logo_url'] ?? '').toString().trim();
        _selectedState = null;
        _stateOptions = <String>[];
        _stateIdByName = <String, String>{};
        final String rawAddress =
            (orgData['payment_stub_address'] ?? '').toString();
        try {
          if (rawAddress.startsWith('{')) {
            final addr = jsonDecode(rawAddress) as Map<String, dynamic>;
            _paymentStubAttentionController.text =
                (addr['attention'] ?? '').toString();
            _paymentStubStreet1Controller.text =
                (addr['street1'] ?? '').toString();
            _paymentStubStreet2Controller.text =
                (addr['street2'] ?? '').toString();
            _paymentStubCityController.text = (addr['city'] ?? '').toString();
            _paymentStubPincodeController.text =
                (addr['pincode'] ?? '').toString();
            _paymentStubPhoneController.text =
                _normalizeIndiaPhone((addr['phone'] ?? '').toString());
            _paymentStubFaxController.text = (addr['fax'] ?? '').toString();
            _selectedPaymentStubState = _matchOption(
              (addr['state_name'] ?? '').toString(),
              _indianStates,
            );
            _selectedPaymentStubDistrictId = (addr['district_id'] ?? '').toString();
            _selectedPaymentStubLocalBodyId = (addr['local_body_id'] ?? '').toString();
            _selectedPaymentStubWardId = (addr['ward_id'] ?? '').toString();
          } else {
            _paymentStubStreet1Controller.text = rawAddress;
          }
        } catch (_) {
          _paymentStubStreet1Controller.text = rawAddress;
        }

        _hasSeparatePaymentStubAddress =
            orgData['has_separate_payment_stub_address'] == true;

        // Pharmacy compliance fields
        _isDrugRegistered = orgData['is_drug_registered'] == true;
        _drugLicenceType = orgData['drug_licence_type']?.toString();
        _drugLicense20Controller.text =
            (orgData['drug_license_20'] ?? '').toString();
        _drugLicense21Controller.text =
            (orgData['drug_license_21'] ?? '').toString();
        _drugLicense20BController.text =
            (orgData['drug_license_20b'] ?? '').toString();
        _drugLicense21BController.text =
            (orgData['drug_license_21b'] ?? '').toString();

        _isFssaiRegistered = orgData['is_fssai_registered'] == true;
        _fssaiNumberController.text = (orgData['fssai_number'] ?? '').toString();

        _isMsmeRegistered = orgData['is_msme_registered'] == true;
        _msmeRegistrationType = orgData['msme_registration_type']?.toString();
        _msmeNumberController.text = (orgData['msme_number'] ?? '').toString();

        _isLoading = false;
      });

      final String? countryId = _selectedLocation != null
          ? _countryIdByName[_selectedLocation!]
          : null;
      if (countryId != null) {
        await _fetchStates(
          countryId,
          selectedStateId: (orgData['state_id'] ?? '').toString(),
        );
        await _fetchTimezones(countryId);
        await _loadPaymentStubStates();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _fetchTimezones([String? countryId]) async {
    final String path = countryId != null
        ? '/lookups/timezones?countryId=$countryId'
        : '/lookups/timezones';
    try {
      final response = await _apiClient.get(path, useCache: false);
      if (!mounted) return;
      setState(() {
        _timeZoneOptions = response.success && response.data is List
            ? _parseTimezoneOptions(response)
            : <_TimezoneOption>[];
        if (_selectedTimeZone != null &&
            !_timeZoneOptions.any(
              (option) =>
                  option.tzdbName == _selectedTimeZone ||
                  option.display == _selectedTimeZone ||
                  option.name == _selectedTimeZone ||
                  option.id == _selectedTimeZone,
            )) {
          _selectedTimeZone = null;
        }
      });
    } catch (_) {
      // Keep existing options on error
    }
  }

  Future<void> _fetchStates(String countryId, {String? selectedStateId}) async {
    try {
      final response = await _apiClient.get(
        '/lookups/states',
        queryParameters: <String, dynamic>{'countryId': countryId},
        useCache: false,
      );

      if (!mounted) return;

      final Map<String, String> stateIdByName = <String, String>{};
      final Map<String, String> stateNameById = <String, String>{};
      final List<String> stateOptions = <String>[];

      if (response.success && response.data is List) {
        for (final dynamic item in (response.data as List).whereType<Map>()) {
          final String id = (item['id'] ?? '').toString();
          final String name = (item['name'] ?? '').toString();
          if (id.isEmpty || name.isEmpty) {
            continue;
          }
          stateOptions.add(name);
          stateIdByName[name] = id;
          stateNameById[id] = name;
        }
      }

      setState(() {
        _stateOptions = stateOptions;
        _stateIdByName = stateIdByName;
        _selectedState = selectedStateId != null && selectedStateId.isNotEmpty
            ? stateNameById[selectedStateId]
            : (_selectedState != null && stateOptions.contains(_selectedState)
                  ? _selectedState
                  : null);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stateOptions = <String>[];
        _stateIdByName = <String, String>{};
        _selectedState = null;
      });
    }
  }

  Widget _buildSidebar() {
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
            for (final block in section.blocks) _buildSidebarBlock(block),
            const SizedBox(height: AppTheme.space12),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarBlock(_ProfileNavBlock block) {
    final currentPath = GoRouterState.of(
      context,
    ).uri.path.replaceFirst(RegExp(r'^/\d{10,20}'), '');
    final hasActiveChild = block.items.any((item) => item.route == currentPath);
    final isExpanded = _expandedBlocks.contains(block.title) || hasActiveChild;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space4),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedBlocks.remove(block.title);
                } else {
                  _expandedBlocks.add(block.title);
                }
              });
            },
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
                    .map((entry) => _buildSidebarEntry(entry, currentPath))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarEntry(_ProfileNavEntry entry, String currentPath) {
    final isActive = entry.route == currentPath;
    final Color accentColor = ref.watch(appBrandingProvider).accentColor;

    return InkWell(
      onTap: () => _openEntry(entry),
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
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.label,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: isActive ? Colors.white : AppTheme.textPrimary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(AppTheme.space24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.alertTriangle,
                color: AppTheme.warningOrange,
                size: 28,
              ),
              const SizedBox(height: AppTheme.space12),
              Text(
                'Unable to load organization profile',
                style: AppTheme.sectionHeader,
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SettingsFixedHeaderLayout(
      maxWidth: 620,
      scrollController: _bodyScrollController,
      headerPadding: const EdgeInsets.fromLTRB(
        AppTheme.space32,
        AppTheme.space32,
        AppTheme.space32,
        AppTheme.space16,
      ),
      header: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Organization Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          if (_organizationSystemId.isNotEmpty) ...[
            const SizedBox(width: AppTheme.space12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space12,
                vertical: AppTheme.space4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'ID: $_organizationSystemId',
                style: AppTheme.metaHelper.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.space8),


          // ── Section: Organization Logo ─────────────────────────
          _buildLogoSection(),
          const SizedBox(height: AppTheme.space24),

          // ── Section: Organization Details ─────────────────────
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ZerpaiFormRow(
                  key: _organizationNameKey,
                  label: 'Organization Name',
                  required: true,
                  child: TextFormField(
                    controller: _organizationNameController,
                    decoration: const InputDecoration(
                      hintText: 'Your organization name',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Organization name is required.'
                        : null,
                  ),
                ),
                ZerpaiFormRow(
                  key: _industryKey,
                  label: 'Industry',
                  child: _buildDropdownField(
                    value: _selectedIndustry,
                    hintText: 'Select industry',
                    items: _industryOptions,
                    onChanged: (value) =>
                        setState(() => _selectedIndustry = value),
                  ),
                ),
                ZerpaiFormRow(
                  key: _organizationLocationKey,
                  label: 'Organization Location',
                  required: true,
                  child: _buildDropdownField(
                    value: _selectedLocation,
                    hintText: _countryOptions.isEmpty
                        ? 'No country data available'
                        : 'Select country',
                    items: _countryOptions,
                    onChanged: (value) async {
                      setState(() {
                        _selectedLocation = value;
                        _selectedState = null;
                      });
                      if (value != null) {
                        final countryId = _countryIdByName[value];
                        if (countryId != null) {
                          await _fetchStates(countryId);
                          await _fetchTimezones(countryId);

                          if (value.toLowerCase() == 'india') {
                            setState(() {
                              // 1. Default state to Kerala
                              final kerala = _stateOptions
                                  .where((s) => s.toLowerCase() == 'kerala')
                                  .firstOrNull;
                              if (kerala != null) {
                                _selectedState = kerala;
                              }

                              // 2. Default currency to INR
                              final inr = _currencyOptions
                                  .where((c) => c.toUpperCase() == 'INR')
                                  .firstOrNull;
                              if (inr != null) {
                                _selectedBaseCurrency = inr;
                                final currencyData =
                                    _currencyDataByCode[inr] ??
                                    <String, dynamic>{};
                                _selectedBaseCurrencyDecimals =
                                    currencyData['decimals']?.toString() ?? '2';
                                _selectedBaseCurrencyFormat =
                                    currencyData['format']?.toString();
                              }

                              // 3. Default timezone to Asia/Kolkata (IST)
                              final ist = _timeZoneOptions
                                  .where(
                                    (t) =>
                                        t.tzdbName == 'Asia/Kolkata' ||
                                        t.display.contains('Kolkata') ||
                                        t.display.contains('Mumbai') ||
                                        t.display.contains('New Delhi') ||
                                        t.display.contains('Chennai'),
                                  )
                                  .firstOrNull;
                              if (ist != null) {
                                _selectedTimeZone = ist.tzdbName;
                              }

                              // 4. Default fiscal year to April - March
                              if (_fiscalYearOptions.contains('April - March')) {
                                _selectedFiscalYear = 'April - March';
                              }
                            });
                          }
                        }
                      } else {
                        setState(() {
                          _stateOptions = <String>[];
                          _stateIdByName = <String, String>{};
                          _timeZoneOptions = <_TimezoneOption>[];
                          _selectedTimeZone = null;
                        });
                      }
                    },
                  ),
                ),
                ZerpaiFormRow(
                  key: _stateKey,
                  label: 'State',
                  required: true,
                  child: _buildDropdownField(
                    value: _selectedState,
                    hintText: _selectedLocation == null
                        ? 'Select country first'
                        : (_stateOptions.isEmpty
                              ? 'No state data available'
                              : 'Select state'),
                    items: _stateOptions,
                    onChanged: (value) =>
                        setState(() => _selectedState = value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space20),

          // ── Organization Address banner ────────────────────────
          Container(
            key: _paymentStubKey,
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              color: AppTheme.infoBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      size: 18,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Text(
                      'Organization Address',
                      style: AppTheme.bodyText.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space10),
                Text(
                  'Manage your business branches and warehouses from the Branches and Warehouses settings pages.',
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => context.go(AppRoutes.settingsBranches),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Go to Branches'),
                    ),
                    const SizedBox(width: AppTheme.space16),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.settingsWarehouses),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Go to Warehouses'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space12),

          // ── Payment stub toggle ───────────────────────────────
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ZerpaiFormRow(
                  label: 'Payment Stub Address',
                  crossAxisAlignment: CrossAxisAlignment.center,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Would you like to add a different address for payment stubs?',
                          style: AppTheme.bodyText.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        _hasSeparatePaymentStubAddress ? 'Yes' : 'No',
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Switch.adaptive(
                        value: _hasSeparatePaymentStubAddress,
                        activeThumbColor: ref
                            .watch(appBrandingProvider)
                            .accentColor,
                        onChanged: (value) {
                          setState(() {
                            _hasSeparatePaymentStubAddress = value;
                          });
                          if (value) {
                            _loadPaymentStubStates();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                if (_hasSeparatePaymentStubAddress) ...[
                  kZerpaiFormDivider,
                  ZerpaiFormRow(
                    label: 'Address',
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
                          decoration: _dec('Street 1'),
                        ),
                        const SizedBox(height: AppTheme.space8),
                        TextFormField(
                          controller: _paymentStubStreet2Controller,
                          decoration: _dec('Street 2'),
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
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space8),
                        _buildStaticField('India'),
                        const SizedBox(height: AppTheme.space8),
                        Row(
                          children: [
                            Expanded(
                              child: FormDropdown<String>(
                                value: _selectedPaymentStubState,
                                hint: 'State / Union territory',
                                items: _indianStates,
                                onChanged: (v) {
                                  setState(() {
                                    _selectedPaymentStubState = v;
                                    _selectedPaymentStubDistrictId = null;
                                    _selectedPaymentStubLocalBodyType = null;
                                    _selectedPaymentStubLocalBodyId = null;
                                    _selectedPaymentStubWardId = null;
                                    _paymentStubDistrictOptions = const [];
                                    _paymentStubAllLocalBodyOptions = const [];
                                    _paymentStubLocalBodyOptions = const [];
                                    _paymentStubWardOptions = const [];
                                  });
                                  if (_showKeralaLsgdFields) {
                                    _loadDistrictsForSelectedPaymentStubState();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Expanded(
                              child: TextFormField(
                                controller: _paymentStubPhoneController,
                                decoration: _dec('Phone'),
                                inputFormatters: [_IndiaPhoneFormatter()],
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _paymentStubFaxController,
                                decoration: _dec('Fax number'),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                        if (_showKeralaLsgdFields) ...[
                          const SizedBox(height: AppTheme.space8),
                          _buildPaymentStubLsgdFields(),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.space32),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space24),

          // ── Section: Primary Contact ───────────────────────────
          Text(
            'Primary Contact',
            key: _primaryContactKey,
            style: AppTheme.sectionHeader,
          ),
          const SizedBox(height: AppTheme.space12),
          _buildPrimaryContactCard(),
          const SizedBox(height: AppTheme.space12),


          // ── Section: Configuration ────────────────────────────
          Text('Configuration', style: AppTheme.sectionHeader),
          const SizedBox(height: AppTheme.space12),
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ZerpaiFormRow(
                  key: _baseCurrencyKey,
                  label: 'Base Currency',
                  required: true,
                  child: _buildBaseCurrencyField(),
                ),
                ZerpaiFormRow(
                  key: _fiscalYearKey,
                  label: 'Fiscal Year',
                  required: true,
                  child: _buildDropdownField(
                    value: _selectedFiscalYear,
                    hintText: 'Select fiscal year',
                    items: _fiscalYearOptions,
                    onChanged: (value) =>
                        setState(() => _selectedFiscalYear = value),
                  ),
                ),

                ZerpaiFormRow(
                  key: _timeZoneKey,
                  label: 'Time Zone',
                  required: true,
                  child: FormDropdown<_TimezoneOption>(
                    value: _selectedTimeZoneOption,
                    items: _timeZoneOptions,
                    hint: 'Select time zone',
                    displayStringForValue: (option) => option.display,
                    searchStringForValue: (option) =>
                        '${option.display} ${option.name} ${option.tzdbName}',
                    onChanged: (value) =>
                        setState(() => _selectedTimeZone = value?.tzdbName),
                    menuWidth: 720,
                  ),
                ),
                ZerpaiFormRow(
                  key: _dateFormatKey,
                  label: 'Date Format',
                  required: true,
                  child: Row(
                    children: [
                      Expanded(child: _buildGroupedDateFormatDropdown()),
                      const SizedBox(width: AppTheme.space12),
                      SizedBox(
                        width: 120,
                        child: _buildDropdownField(
                          value: _selectedDateSeparator,
                          hintText: 'Separator',
                          items: _dateSeparatorOptions,
                          onChanged: (value) =>
                              setState(() => _selectedDateSeparator = value),
                        ),
                      ),
                    ],
                  ),
                ),
                ZerpaiFormRow(
                  key: _companyIdKey,
                  label: 'Company ID',
                  required: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          value: _selectedCompanyIdLabel,
                          hintText: 'Select identifier',
                          items: _companyIdOptions,
                          onChanged: (value) =>
                              setState(() => _selectedCompanyIdLabel = value),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: TextFormField(
                          controller: _companyIdValueController,
                          decoration: const InputDecoration(
                            hintText: 'Enter identifier value',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildPharmacyComplianceFields(),
          const SizedBox(height: AppTheme.space24),

          // ── Section: Additional Fields ─────────────────────────
          Text(
            'Additional Fields',
            key: _additionalFieldsKey,
            style: AppTheme.sectionHeader,
          ),
          const SizedBox(height: AppTheme.space12),
          _buildAdditionalFieldsTable(),
          const SizedBox(height: AppTheme.space12),
          TextButton.icon(
            onPressed: _addAdditionalField,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            icon: const Icon(LucideIcons.plusCircle, size: 18),
            label: const Text('New Field'),
          ),
          const SizedBox(height: AppTheme.space16),

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
        child: Row(
          children: [
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: ref.watch(appBrandingProvider).accentColor,
                foregroundColor: Colors.white,
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
                  : const Text('Save'),
            ),
            const SizedBox(width: AppTheme.space12),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.settings),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    final bool hasLogo = _logoBytes != null || _existingLogoUrl != null;

    Widget imageChild;
    if (_isUploadingLogo) {
      imageChild = const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (_logoBytes != null) {
      imageChild = ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.memory(
          _logoBytes!,
          fit: BoxFit.contain,
          width: 250,
          height: 96,
        ),
      );
    } else if (_existingLogoUrl != null) {
      imageChild = ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.network(
          _existingLogoUrl!,
          fit: BoxFit.contain,
          width: 250,
          height: 96,
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.imageOff,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  'Logo unavailable',
                  style: AppTheme.captionText.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      imageChild = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.upload,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Click to upload logo',
            style: AppTheme.captionText.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      );
    }

    return Column(
      key: _logoSectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Organization Logo', style: AppTheme.sectionHeader),
        const SizedBox(height: AppTheme.space12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview box with overlaid trash icon
            SizedBox(
              width: 250,
              height: 96,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DashedBorderPainter(
                        color: AppTheme.borderColor,
                        radius: 6,
                      ),
                      child: InkWell(
                        onTap: _isUploadingLogo ? null : _pickLogo,
                        borderRadius: BorderRadius.circular(6),
                        child: Center(child: imageChild),
                      ),
                    ),
                  ),
                  if (hasLogo && !_isUploadingLogo)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _logoBytes = null;
                          _logoFileName = null;
                          _existingLogoUrl = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: const Icon(
                            LucideIcons.trash2,
                            size: 13,
                            color: AppTheme.errorRed,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.space20),
            // Info text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This logo will be displayed in transaction PDFs and email notifications.',
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Preferred Image Dimensions: 240 × 240 pixels @ 72 DPI',
                    style: AppTheme.captionText.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Supported Files: jpg, jpeg, png, gif, bmp',
                    style: AppTheme.captionText.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Maximum File Size: 1 MB',
                    style: AppTheme.captionText.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    // Hard limit: 1 MB
    if (file.bytes!.lengthInBytes > 1 * 1024 * 1024) {
      if (mounted) {
        ZerpaiToast.error(
          context,
          'Logo file must not exceed 1 MB. Please choose a smaller image.',
        );
      }
      return;
    }

    final ext = (file.extension ?? 'jpg').toLowerCase();

    // gif and bmp are not compressible — use as-is
    CompressFormat? format;
    if (ext == 'png') format = CompressFormat.png;
    if (ext == 'webp') format = CompressFormat.webp;
    if (ext == 'jpg' || ext == 'jpeg') format = CompressFormat.jpeg;

    Uint8List bytes = file.bytes!;
    if (!kIsWeb && format != null && bytes.lengthInBytes > 200 * 1024) {
      bytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 240,
        minHeight: 240,
        quality: 85,
        format: format,
      );
    }

    setState(() {
      _logoBytes = bytes;
      _logoFileName = file.name;
    });
  }

  Future<void> _uploadLogoIfChanged(String orgId) async {
    if (_logoBytes == null || _logoFileName == null) return;
    setState(() => _isUploadingLogo = true);
    try {
      final base64Data = base64Encode(_logoBytes!);
      final ext = (_logoFileName!.split('.').last).toLowerCase();
      final mime = ext == 'jpg' ? 'image/jpeg' : 'image/$ext';
      final response = await _apiClient.post(
        '/lookups/org/$orgId/logo',
        data: {
          'fileName': _logoFileName,
          'fileData': base64Data,
          'mimeType': mime,
        },
      );
      if (response.success) {
        final logoUrl = response.data?['logoUrl'] as String?;
        setState(() => _existingLogoUrl = logoUrl);
        ref.invalidate(orgSettingsProvider);
      }
    } finally {
      setState(() => _isUploadingLogo = false);
    }
  }

  Widget _buildPrimaryContactCard() {
    return SizedBox(
      width: 630,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildPrimaryContactPane(
                icon: LucideIcons.send,
                title: 'Sender',
                value: _primaryContactName.isEmpty
                    ? 'Not configured'
                    : _primaryContactName,
                subValue: _primaryContactEmail.isEmpty
                    ? 'No email found'
                    : _primaryContactEmail,
              ),
            ),
            Container(
              width: 1,
              height: 64,
              color: AppTheme.borderLight,
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            ),
            Expanded(
              child: _buildPrimaryContactPane(
                icon: LucideIcons.mail,
                title: 'Emails are sent through',
                value: 'Email address of Zerpai Inventory',
                subValue: 'message-service@sender.zerpai-erp.in',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryContactPane({
    required IconData icon,
    required String title,
    required String value,
    required String subValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: AppTheme.space8),
            Text(
              title.toUpperCase(),
              style: AppTheme.captionText.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space12),
        Text(
          value,
          style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppTheme.space6),
        Text(
          subValue,
          style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildAdditionalFieldsTable() {
    return SizedBox(
      width: 630,
      child: Table(
        border: TableBorder.all(color: AppTheme.borderLight),
        columnWidths: const <int, TableColumnWidth>{
          0: FlexColumnWidth(),
          1: FlexColumnWidth(),
          2: FixedColumnWidth(52),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppTheme.bgLight),
            children: [
              _buildTableHeaderCell('Label Name'),
              _buildTableHeaderCell('Value'),
              const SizedBox.shrink(),
            ],
          ),
          for (int index = 0; index < _additionalFields.length; index++)
            TableRow(
              children: [
                _buildTableTextField(_additionalFields[index].labelController),
                _buildTableTextField(_additionalFields[index].valueController),
                IconButton(
                  onPressed: _additionalFields.length == 1
                      ? null
                      : () => _removeAdditionalField(index),
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: AppTheme.errorRed,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentStubLsgdFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // District and Local Body Type
        Row(
          children: [
            Expanded(
              child: FormDropdown<String>(
                items: _paymentStubDistrictOptions
                    .map((district) => district.id)
                    .toList(),
                value: _selectedPaymentStubDistrictId,
                hint: 'District',
                displayStringForValue: (id) {
                  final match = _paymentStubDistrictOptions.firstWhere(
                    (district) => district.id == id,
                    orElse: () => _DistrictOption(id: id, name: id),
                  );
                  return match.name;
                },
                onChanged: (v) async {
                  setState(() {
                    _selectedPaymentStubDistrictId = v;
                    _selectedPaymentStubLocalBodyType = null;
                    _selectedPaymentStubLocalBodyId = null;
                    _selectedPaymentStubWardId = null;
                    _paymentStubAllLocalBodyOptions = const [];
                    _paymentStubLocalBodyOptions = const [];
                    _paymentStubWardOptions = const [];
                  });
                  if (v != null && v.isNotEmpty) {
                    await _loadLocalBodiesForSelectedPaymentStubDistrict(
                      ignoreTypeFilter: true,
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: AppTheme.space8),
            Expanded(
              child: FormDropdown<String>(
                items: _paymentStubAvailableLocalBodyTypeOptions,
                value: _selectedPaymentStubLocalBodyType,
                hint: 'Local body type',
                displayStringForValue: _localBodyTypeLabel,
                onChanged: (v) async {
                  setState(() {
                    _selectedPaymentStubLocalBodyType = v;
                    _selectedPaymentStubLocalBodyId = null;
                    _selectedPaymentStubWardId = null;
                    _paymentStubLocalBodyOptions = v == null || v.isEmpty
                        ? _paymentStubAllLocalBodyOptions
                        : _paymentStubAllLocalBodyOptions
                            .where((localBody) => localBody.bodyType == v)
                            .toList();
                    _paymentStubWardOptions = const [];
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space8),
        // Local Body and Ward
        Row(
          children: [
            Expanded(
              child: FormDropdown<String>(
                items: _paymentStubLocalBodyOptions
                    .map((localBody) => localBody.id)
                    .toList(),
                value: _selectedPaymentStubLocalBodyId,
                hint: 'Local body name',
                displayStringForValue: (id) {
                  final match = _paymentStubLocalBodyOptions.firstWhere(
                    (localBody) => localBody.id == id,
                    orElse: () =>
                        _LocalBodyOption(id: id, name: id, bodyType: ''),
                  );
                  return match.name;
                },
                onChanged: (v) async {
                  setState(() {
                    _selectedPaymentStubLocalBodyId = v;
                    _selectedPaymentStubWardId = null;
                    _paymentStubWardOptions = const [];
                  });
                  if (v != null && v.isNotEmpty) {
                    await _loadWardsForSelectedPaymentStubLocalBody();
                  }
                },
              ),
            ),
            const SizedBox(width: AppTheme.space8),
            Expanded(
              child: FormDropdown<String>(
                items: _paymentStubWardOptions.map((ward) => ward.id).toList(),
                value: _selectedPaymentStubWardId,
                hint: 'Ward',
                displayStringForValue: (id) {
                  final match = _paymentStubWardOptions.firstWhere(
                    (ward) => ward.id == id,
                    orElse: () => _WardOption(id: id, name: id, displayName: id),
                  );
                  return match.displayName;
                },
                onChanged: (v) => setState(() => _selectedPaymentStubWardId = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.space10,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.captionText.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTableTextField(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space4),
      child: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppTheme.space8,
            vertical: AppTheme.space10,
          ),
        ),
      ),
    );
  }



  Widget _buildBaseCurrencyField() {
    final bool isIndia = _selectedLocation?.toLowerCase() == 'india';
    final gearIconButton = IconButton(
      icon: Icon(
        LucideIcons.settings,
        size: 16,
        color: _selectedBaseCurrency == null
            ? AppTheme.textMuted
            : AppTheme.textSecondary,
      ),
      tooltip: 'Edit currency details',
      splashRadius: 18,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      onPressed: _selectedBaseCurrency == null
          ? null
          : () => _showEditCurrencyDialog(_selectedBaseCurrency!),
    );
    final gearButton = isIndia
        ? ZTooltip(
            message:
                'Base currency is fixed to INR for India-based organizations, but you can still edit the INR currency settings.',
            child: gearIconButton,
          )
        : gearIconButton;

    return Row(
      children: [
        Expanded(
          child: _buildDropdownField(
            value: _selectedBaseCurrency,
            hintText: _currencyOptions.isEmpty
                ? 'No currency data available'
                : 'Select base currency',
            items: _currencyOptions,
            onChanged: isIndia
                ? null
                : (value) => setState(() {
                    _selectedBaseCurrency = value;
                    final selectedCurrencyData =
                        _currencyDataByCode[value] ?? <String, dynamic>{};
                    _selectedBaseCurrencyDecimals =
                        selectedCurrencyData['decimals']?.toString() ?? '2';
                    _selectedBaseCurrencyFormat = selectedCurrencyData['format']
                        ?.toString();
                  }),
          ),
        ),
        const SizedBox(width: AppTheme.space8),
        gearButton,
      ],
    );
  }

  Future<void> _showEditCurrencyDialog(String code) async {
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      _currencyDataByCode[code] ?? {},
    );

    final codeCtrl = TextEditingController(
      text: (data['code'] ?? code).toString(),
    );
    final symbolCtrl = TextEditingController(
      text: (data['symbol'] ?? '').toString(),
    );
    final nameCtrl = TextEditingController(
      text: (data['name'] ?? '').toString(),
    );

    final List<String> decimalOptions = ['0', '2', '3'];
    List<String> formatOptionsFor(String? decimals) {
      switch (decimals) {
        case '0':
          return [
            '1,234,567',
            '1.234.567',
            '1 234 567',
            "1'234'567",
            '12,34,567',
          ];
        case '3':
          return [
            '1,234,567.890',
            '1.234.567,890',
            '1 234 567,890',
            "1'234'567.890",
            '12,34,567.890',
          ];
        case '2':
        default:
          return [
            '1,234,567.89',
            '1.234.567,89',
            '1 234 567,89',
            "1'234'567.89",
            '12,34,567.89',
          ];
      }
    }

    String? selectedDecimals =
        decimalOptions.contains(
          (_selectedBaseCurrencyDecimals ?? data['decimals'] ?? '').toString(),
        )
        ? (_selectedBaseCurrencyDecimals ?? data['decimals'] ?? '').toString()
        : '2';
    List<String> formatOptions = formatOptionsFor(selectedDecimals);
    String? selectedFormat = (_selectedBaseCurrencyFormat ?? data['format'])
        ?.toString();
    if (selectedFormat != null && !formatOptions.contains(selectedFormat)) {
      selectedFormat = formatOptions.first;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.space8),
          ),
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space24,
                    AppTheme.space20,
                    AppTheme.space16,
                    AppTheme.space16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Edit Currency',
                          style: AppTheme.sectionHeader,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                // ── Body ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dialogField(
                        label: 'Currency Code',
                        required: true,
                        child: _readOnlyDialogInput(codeCtrl),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      _dialogField(
                        label: 'Currency Symbol',
                        required: true,
                        child: _readOnlyDialogInput(symbolCtrl),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      _dialogField(
                        label: 'Currency Name',
                        required: true,
                        child: _readOnlyDialogInput(nameCtrl),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      _dialogField(
                        label: 'Decimal Places',
                        child: _buildDropdownField(
                          value: selectedDecimals,
                          hintText: 'Select',
                          items: decimalOptions,
                          onChanged: (v) => setDlgState(() {
                            selectedDecimals = v;
                            formatOptions = formatOptionsFor(selectedDecimals);
                            if (selectedFormat == null ||
                                !formatOptions.contains(selectedFormat)) {
                              selectedFormat = formatOptions.first;
                            }
                          }),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space16),
                      _dialogField(
                        label: 'Format',
                        child: _buildDropdownField(
                          value: selectedFormat,
                          hintText: 'Select format',
                          items: formatOptions,
                          onChanged: (v) =>
                              setDlgState(() => selectedFormat = v),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                // ── Footer ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space24,
                    vertical: AppTheme.space16,
                  ),
                  child: Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space20,
                            vertical: AppTheme.space10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.space4,
                            ),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedBaseCurrencyDecimals = selectedDecimals;
                            _selectedBaseCurrencyFormat = selectedFormat;
                          });
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Save'),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: AppTheme.textSecondary),
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

    codeCtrl.dispose();
    symbolCtrl.dispose();
    nameCtrl.dispose();
  }

  Widget _dialogField({
    required String label,
    required Widget child,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: AppTheme.tableHeader,
            children: required
                ? [
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: AppTheme.errorRed),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: AppTheme.space6),
        child,
      ],
    );
  }

  Widget _readOnlyDialogInput(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: AppTheme.bodyText,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.bgDisabled,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space8,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.space4),
          borderSide: BorderSide(color: AppTheme.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.space4),
          borderSide: BorderSide(color: AppTheme.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.space4),
          borderSide: BorderSide(color: AppTheme.borderLight),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hintText,
    required List<String> items,
    ValueChanged<String?>? onChanged,
    double? menuWidth,
  }) {
    return FormDropdown<String>(
      value: value,
      items: items,
      hint: hintText,
      menuWidth: menuWidth,
      onChanged: onChanged ?? (_) {},
    );
  }

  Widget _buildPharmacyComplianceFields() {
    if (_selectedIndustry != 'Pharmacy' && _selectedIndustry != 'Pharmaceuticals') {
      return const SizedBox.shrink();
    }

    final Color accentColor = ref.watch(appBrandingProvider).accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.space24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space32),
          child: Text(
            'REGULATORY COMPLIANCE',
            style: AppTheme.sectionHeader.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drug Licence Type (Always on for Pharmacy Industry)
            ZerpaiFormRow(
              label: 'Drug Licence Type',
              required: true,
              child: _buildDropdownField(
                value: _drugLicenceType,
                hintText: 'Select licence type',
                items: const ['Wholesale', 'Retail', 'Wholesale and Retail'],
                onChanged: (v) => setState(() => _drugLicenceType = v),
              ),
            ),
            if (_drugLicenceType == 'Retail' ||
                _drugLicenceType == 'Wholesale and Retail') ...[
              kZerpaiFormDivider,
              ZerpaiFormRow(
                label: 'Drug License 20',
                required: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _drugLicense20Controller,
                            decoration: const InputDecoration(
                                hintText: 'Enter License Number'),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        FileUploadButton(
                          files: _drugLicense20Docs,
                          onFilesChanged: (files) =>
                              setState(() => _drugLicense20Docs = files),
                          showBadge: true,
                          showOverlay: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              kZerpaiFormDivider,
              ZerpaiFormRow(
                label: 'Drug License 21',
                required: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _drugLicense21Controller,
                            decoration: const InputDecoration(
                                hintText: 'Enter License Number'),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        FileUploadButton(
                          files: _drugLicense21Docs,
                          onFilesChanged: (files) =>
                              setState(() => _drugLicense21Docs = files),
                          showBadge: true,
                          showOverlay: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (_drugLicenceType == 'Wholesale' ||
                _drugLicenceType == 'Wholesale and Retail') ...[
              kZerpaiFormDivider,
              ZerpaiFormRow(
                label: 'Drug License 20B',
                required: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _drugLicense20BController,
                            decoration: const InputDecoration(
                                hintText: 'Enter License Number'),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        FileUploadButton(
                          files: _drugLicense20BDocs,
                          onFilesChanged: (files) =>
                              setState(() => _drugLicense20BDocs = files),
                          showBadge: true,
                          showOverlay: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              kZerpaiFormDivider,
              ZerpaiFormRow(
                label: 'Drug License 21B',
                required: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _drugLicense21BController,
                            decoration: const InputDecoration(
                                hintText: 'Enter License Number'),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        FileUploadButton(
                          files: _drugLicense21BDocs,
                          onFilesChanged: (files) =>
                              setState(() => _drugLicense21BDocs = files),
                          showBadge: true,
                          showOverlay: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            kZerpaiFormDivider,
            // FSSAI SECTION
            ZerpaiFormRow(
              label: 'FSSAI License Registered ?',
              child: Row(
                children: [
                  Checkbox(
                    value: _isFssaiRegistered,
                    activeColor: accentColor,
                    onChanged: (v) =>
                        setState(() => _isFssaiRegistered = v ?? false),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Text(
                    'This Organization Is Registered FSSAI License',
                    style: AppTheme.bodyText.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            if (_isFssaiRegistered) ...[
              kZerpaiFormDivider,
              ZerpaiFormRow(
                label: 'FSSAI Number',
                required: true,
                tooltipMessage: 'Enter the 14-digit FSSAI license number.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fssaiNumberController,
                            decoration: const InputDecoration(
                                hintText: 'Enter FSSAI Number'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        FileUploadButton(
                          files: _fssaiDocs,
                          onFilesChanged: (files) =>
                              setState(() => _fssaiDocs = files),
                          showBadge: true,
                          showOverlay: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            kZerpaiFormDivider,
            // MSME SECTION
            ZerpaiFormRow(
              label: 'MSME Registered ?',
              child: Row(
                children: [
                  Checkbox(
                    value: _isMsmeRegistered,
                    activeColor: accentColor,
                    onChanged: (v) =>
                        setState(() => _isMsmeRegistered = v ?? false),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Text(
                    'This Organization Is Registered MSME',
                    style: AppTheme.bodyText.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            if (_isMsmeRegistered) ...[
              kZerpaiFormDivider,
              ZerpaiFormRow(
                label: 'MSME/Udyam Registration Type',
                required: true,
                child: _buildDropdownField(
                  value: _msmeRegistrationType,
                  hintText: 'Select the Registration Type',
                  items: const ['Micro', 'Small', 'Medium'],
                  onChanged: (v) => setState(() => _msmeRegistrationType = v),
                ),
              ),
              kZerpaiFormDivider,
              ZerpaiFormRow(
                label: 'MSME/Udyam Registration Number',
                required: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _msmeNumberController,
                            decoration: const InputDecoration(
                                hintText:
                                    'Enter MSME/Udyam Registration Number'),
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        FileUploadButton(
                          files: _msmeDocs,
                          onFilesChanged: (files) =>
                              setState(() => _msmeDocs = files),
                          showBadge: true,
                          showOverlay: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }



  List<_TimezoneOption> _parseTimezoneOptions(Response<dynamic> response) {
    if (!response.success || response.data is! List) {
      return <_TimezoneOption>[];
    }

    return (response.data as List)
        .whereType<Map>()
        .map(
          (dynamic item) =>
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
        )
        .map(
          (item) => _TimezoneOption(
            id: (item['id'] ?? '').toString(),
            name: (item['name'] ?? '').toString(),
            tzdbName: (item['tzdb_name'] ?? '').toString(),
            utcOffset: (item['utc_offset'] ?? '').toString(),
            display: (item['display'] ?? '').toString(),
            countryId: (item['country_id'] ?? '').toString().trim().isEmpty
                ? null
                : (item['country_id'] ?? '').toString(),
          ),
        )
        .where(
          (option) =>
              option.id.isNotEmpty &&
              option.tzdbName.isNotEmpty &&
              option.display.isNotEmpty,
        )
        .toList();
  }

  String? _matchTimezoneValue(String raw, List<_TimezoneOption> options) {
    if (raw.isEmpty) {
      return null;
    }

    for (final option in options) {
      if (option.tzdbName == raw ||
          option.display == raw ||
          option.name == raw ||
          option.id == raw) {
        return option.tzdbName;
      }
    }

    return null;
  }

  Future<bool> _verifySavedOrgProfile(
    String orgId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _safeGet('/lookups/org/$orgId', useCache: false);
    if (response == null ||
        !response.success ||
        response.data is! Map<String, dynamic>) {
      return false;
    }

    final data = Map<String, dynamic>.from(
      response.data as Map<String, dynamic>,
    );

    bool matches(String key) {
      if (!payload.containsKey(key)) {
        return true;
      }

      final expected = payload[key];
      final actual = data[key];
      return (actual ?? '').toString().trim() ==
          (expected ?? '').toString().trim();
    }

    return matches('name') &&
        matches('state_id') &&
        matches('industry') &&
        matches('base_currency') &&
        matches('base_currency_decimals') &&
        matches('base_currency_format') &&
        matches('fiscal_year') &&

        matches('timezone') &&
        matches('date_format') &&
        matches('date_separator') &&
        matches('company_id_label') &&
        matches('company_id_value') &&

        matches('payment_stub_address') &&
        data['has_separate_payment_stub_address'] ==
            payload['has_separate_payment_stub_address'];
  }



  Widget _buildGroupedDateFormatDropdown() {
    // Build flat list: group headers interleaved with patterns
    final flatItems = <String>[];
    _dateFormatGroups.forEach((group, patterns) {
      flatItems.add('__header__$group');
      flatItems.addAll(patterns);
    });

    // Parse UTC offset from the selected timezone lookup row.
    Duration tzOffset() {
      final offset = _selectedTimeZoneOption?.utcOffset ?? '';
      final match = RegExp(r'([+-])(\d{2}):(\d{2})').firstMatch(offset);
      if (match == null) return Duration.zero;
      final sign = match.group(1) == '+' ? 1 : -1;
      final hours = int.parse(match.group(2)!);
      final minutes = int.parse(match.group(3)!);
      return Duration(hours: sign * hours, minutes: sign * minutes);
    }

    final nowInTz = DateTime.now().toUtc().add(tzOffset());

    String _sample(String pattern) {
      try {
        return DateFormat(pattern).format(nowInTz);
      } catch (_) {
        return pattern;
      }
    }

    return FormDropdown<String>(
      value: _selectedDateFormat,
      hint: 'Select date format',
      items: flatItems,
      isItemEnabled: (item) => !item.startsWith('__header__'),
      displayStringForValue: (pattern) => '$pattern  [ ${_sample(pattern)} ]',
      itemBuilder: (item, isSelected, isHovered) {
        if (item.startsWith('__header__')) {
          final label = item.replaceFirst('__header__', '');
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
            child: Text(
              label,
              style: AppTheme.captionText.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        final sample = _sample(item);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item,
                  style: AppTheme.bodyText.copyWith(
                    color: isSelected
                        ? ref.read(appBrandingProvider).accentColor
                        : AppTheme.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              Text(
                '[ $sample ]',
                style: AppTheme.captionText.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
      onChanged: (value) {
        if (value != null) setState(() => _selectedDateFormat = value);
      },
    );
  }

  List<SettingsSearchItem> _buildSettingsSearchItems() {
    final List<SettingsSearchItem> items = <SettingsSearchItem>[];

    for (final section in _navSections) {
      for (final block in section.blocks) {
        for (final entry in block.items) {
          if (!_isSettingsSearchEntry(entry)) {
            continue;
          }
          items.add(
            SettingsSearchItem(
              group: block.title,
              label: entry.label,
              subtitle: section.title,
              keywords: <String>[section.title, block.title],
              onSelected: () => _openEntry(entry),
            ),
          );
        }
      }
    }

    items.addAll(<SettingsSearchItem>[
      SettingsSearchItem(
        group: 'Organization',
        label: 'Organization Logo',
        subtitle: 'Profile',
        onSelected: () => _scrollToKey(_logoSectionKey),
      ),
      SettingsSearchItem(
        group: 'Organization',
        label: 'Organization Name',
        subtitle: 'Profile',
        onSelected: () => _scrollToKey(_organizationNameKey),
      ),
      SettingsSearchItem(
        group: 'Organization',
        label: 'Industry',
        subtitle: 'Profile',
        onSelected: () => _scrollToKey(_industryKey),
      ),
      SettingsSearchItem(
        group: 'Organization',
        label: 'Organization Location',
        subtitle: 'Profile',
        onSelected: () => _scrollToKey(_organizationLocationKey),
      ),
      SettingsSearchItem(
        group: 'Organization',
        label: 'State',
        subtitle: 'Profile',
        onSelected: () => _scrollToKey(_stateKey),
      ),
      SettingsSearchItem(
        group: 'Organization',
        label: 'Payment Stub Address',
        subtitle: 'Profile',
        onSelected: () => _scrollToKey(_paymentStubKey),
      ),
      SettingsSearchItem(
        group: 'Organization',
        label: 'Primary Contact',
        subtitle: 'Profile',
        onSelected: () => _scrollToKey(_primaryContactKey),
      ),
      SettingsSearchItem(
        group: 'Setup & Configurations',
        label: 'Base Currency',
        subtitle: 'Profile',
        onSelected: () => _scrollToKey(_baseCurrencyKey),
      ),
      SettingsSearchItem(
        group: 'Setup & Configurations',
        label: 'Fiscal Year',
        subtitle: 'Profile',
        onSelected: () => _scrollToKey(_fiscalYearKey),
      ),

      SettingsSearchItem(
        group: 'Setup & Configurations',
        label: 'Time Zone',
        subtitle: 'Profile',
        onSelected: () => _scrollToKey(_timeZoneKey),
      ),
      SettingsSearchItem(
        group: 'Setup & Configurations',
        label: 'Date Format',
        subtitle: 'Profile',
        onSelected: () => _scrollToKey(_dateFormatKey),
      ),
      SettingsSearchItem(
        group: 'Setup & Configurations',
        label: 'Company ID',
        subtitle: 'Profile',
        onSelected: () => _scrollToKey(_companyIdKey),
      ),
      SettingsSearchItem(
        group: 'Setup & Configurations',
        label: 'Additional Fields',
        subtitle: 'Profile',
        onSelected: () => _scrollToKey(_additionalFieldsKey),
      ),
    ]);

    return items;
  }

  void _handleSearch(String rawQuery) {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return;
    }

    final matches = _buildSettingsSearchItems()
        .where((item) => item.matches(query))
        .toList();
    if (matches.isEmpty) {
      ZerpaiToast.info(context, 'No settings matched "$rawQuery"');
      return;
    }

    matches.first.onSelected();
  }

  Future<void> _scrollToKey(GlobalKey key) async {
    final currentContext = key.currentContext;
    if (currentContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      currentContext,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: 0.12,
    );
  }

  bool _isSettingsSearchEntry(_ProfileNavEntry entry) {
    if (entry.route == null) {
      return true;
    }
    return entry.route == AppRoutes.settings ||
        entry.route == AppRoutes.settingsOrgProfile ||
        entry.route!.startsWith('${AppRoutes.settings}/');
  }

  void _openEntry(_ProfileNavEntry entry) {
    if (entry.route == null) {
      ZerpaiToast.info(context, '${entry.label} is not available yet');
      return;
    }
    context.go(entry.route!);
  }

  void _addAdditionalField() {
    setState(() {
      _additionalFields.add(_ProfileAdditionalField());
    });
  }

  void _removeAdditionalField(int index) {
    final field = _additionalFields.removeAt(index);
    field.dispose();
    setState(() {});
  }

  Future<void> _saveProfile() async {
    // Validate form fields
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Validate required dropdowns not covered by TextFormField
    if (_selectedBaseCurrency == null) {
      ZerpaiToast.error(context, 'Please select a base currency.');
      return;
    }
    if (_selectedFiscalYear == null) {
      ZerpaiToast.error(context, 'Please select a fiscal year.');
      return;
    }

    if (_selectedTimeZone == null || _selectedTimeZone!.trim().isEmpty) {
      ZerpaiToast.error(context, 'Please select a time zone.');
      return;
    }
    if (_selectedDateFormat == null || _selectedDateFormat!.trim().isEmpty) {
      ZerpaiToast.error(context, 'Please select a date format.');
      return;
    }
    if (_selectedDateSeparator == null ||
        _selectedDateSeparator!.trim().isEmpty) {
      ZerpaiToast.error(context, 'Please select a date separator.');
      return;
    }
    if (_selectedLocation == null) {
      ZerpaiToast.error(context, 'Please select an organization location.');
      return;
    }
    if (_selectedState == null) {
      ZerpaiToast.error(
        context,
        'Please select a state for the selected organization location.',
      );
      return;
    }
    if (!_stateIdByName.containsKey(_selectedState)) {
      ZerpaiToast.error(
        context,
        'Please select a valid state for the selected organization location.',
      );
      return;
    }
    final String companyIdValue = _companyIdValueController.text.trim();
    if (_selectedCompanyIdLabel == null ||
        _selectedCompanyIdLabel!.trim().isEmpty) {
      ZerpaiToast.error(context, 'Please select a company ID label.');
      return;
    }
    if (companyIdValue.isEmpty) {
      ZerpaiToast.error(context, 'Please enter the company ID value.');
      return;
    }

    // Resolve org ID — prefer auth user, then API-loaded ID, then dev fallback.
    // TODO(auth): Remove _kDevOrgId fallback once auth is enabled.
    final user = ref.read(authUserProvider);
    final orgId = (user?.orgId.isNotEmpty == true)
        ? user!.orgId
        : (_organizationId.isNotEmpty ? _organizationId : _kDevOrgId);

    if (orgId.isEmpty) {
      ZerpaiToast.error(
        context,
        'Organization not found. Please log in again.',
      );
      return;
    }

    final payload = <String, dynamic>{
      'name': _organizationNameController.text.trim(),
      if (_selectedState != null) 'state_id': _stateIdByName[_selectedState],
      if (_selectedIndustry != null) 'industry': _selectedIndustry,
      'base_currency': _selectedBaseCurrency,
      if (_selectedBaseCurrencyDecimals != null)
        'base_currency_decimals': int.tryParse(_selectedBaseCurrencyDecimals!),
      if (_selectedBaseCurrencyFormat != null &&
          _selectedBaseCurrencyFormat!.trim().isNotEmpty)
        'base_currency_format': _selectedBaseCurrencyFormat,
      'fiscal_year': _selectedFiscalYear,

      if (_selectedTimeZone != null) 'timezone': _selectedTimeZone,
      if (_selectedDateFormat != null) 'date_format': _selectedDateFormat,
      if (_selectedDateSeparator != null)
        'date_separator': _selectedDateSeparator,
      if (_selectedCompanyIdLabel != null)
        'company_id_label': _selectedCompanyIdLabel,
      'company_id_value': _companyIdValueController.text.trim(),

      // Pharmacy compliance fields
      'is_drug_registered': _isDrugRegistered ||
          (_selectedIndustry?.toLowerCase() == 'pharmacy'),
      'drug_licence_type': _drugLicenceType,
      'drug_license_20': _drugLicense20Controller.text.trim(),
      'drug_license_21': _drugLicense21Controller.text.trim(),
      'drug_license_20b': _drugLicense20BController.text.trim(),
      'drug_license_21b': _drugLicense21BController.text.trim(),
      'is_fssai_registered': _isFssaiRegistered,
      'fssai_number': _fssaiNumberController.text.trim(),
      'is_msme_registered': _isMsmeRegistered,
      'msme_registration_type': _msmeRegistrationType,
      'msme_number': _msmeNumberController.text.trim(),

      'has_separate_payment_stub_address': _hasSeparatePaymentStubAddress,
      if (_hasSeparatePaymentStubAddress)
        'payment_stub_address': jsonEncode({
          'attention': _paymentStubAttentionController.text.trim(),
          'street1': _paymentStubStreet1Controller.text.trim(),
          'street2': _paymentStubStreet2Controller.text.trim(),
          'city': _paymentStubCityController.text.trim(),
          'state_name': _selectedPaymentStubState,
          'pincode': _paymentStubPincodeController.text.trim(),
          'phone': _normalizeIndiaPhone(_paymentStubPhoneController.text),
          'fax': _paymentStubFaxController.text.trim(),
          'district_id': _selectedPaymentStubDistrictId,
          'local_body_id': _selectedPaymentStubLocalBodyId,
          'ward_id': _selectedPaymentStubWardId,
        }),
    };

    // Pharmacy Compliance Document Uploads
    if (_selectedIndustry?.toLowerCase() == 'pharmacy') {
      final storage = StorageService();

      Future<String?> uploadDocs(List<PlatformFile> docs) async {
        if (docs.isEmpty) return null;
        final urls = <String>[];
        for (final file in docs) {
          final url = await storage.uploadLicenseDocument(file);
          if (url != null) urls.add(url);
        }
        return urls.isNotEmpty ? urls.join(',') : null;
      }

      final dl20 = await uploadDocs(_drugLicense20Docs);
      if (dl20 != null) payload['drug_license_20_url'] = dl20;

      final dl21 = await uploadDocs(_drugLicense21Docs);
      if (dl21 != null) payload['drug_license_21_url'] = dl21;

      final dl20b = await uploadDocs(_drugLicense20BDocs);
      if (dl20b != null) payload['drug_license_20b_url'] = dl20b;

      final dl21b = await uploadDocs(_drugLicense21BDocs);
      if (dl21b != null) payload['drug_license_21b_url'] = dl21b;

      final fssai = await uploadDocs(_fssaiDocs);
      if (fssai != null) payload['fssai_url'] = fssai;

      final msme = await uploadDocs(_msmeDocs);
      if (msme != null) payload['msme_url'] = msme;
    }

    setState(() => _isSaving = true);
    try {
      await _uploadLogoIfChanged(orgId);

      final response = await _apiClient.post(
        '/lookups/org/$orgId/save',
        data: jsonEncode(payload),
      );

      if (!mounted) return;
      if (response.success) {
        ref.invalidate(orgSettingsProvider);
        ZerpaiToast.success(context, 'Organization profile saved.');
      } else {
        ZerpaiToast.error(context, 'Failed to save organization profile.');
      }
    } on DioException catch (error) {
      if (kIsWeb && error.type == DioExceptionType.connectionError) {
        final verified = await _verifySavedOrgProfile(orgId, payload);
        if (!mounted) return;
        if (verified) {
          ZerpaiToast.success(context, 'Organization profile saved.');
          return;
        }
      }

      if (mounted) {
        ZerpaiToast.error(
          context,
          'Unable to save organization profile right now.',
        );
      }
    } catch (_) {
      if (mounted) {
        ZerpaiToast.error(context, 'Error saving profile.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _SettingsProfileTopBar extends StatelessWidget {
  final String organizationName;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final List<SettingsSearchItem> searchItems;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final ValueChanged<String> onSearchSubmitted;

  const _SettingsProfileTopBar({
    required this.organizationName,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchItems,
    required this.onBack,
    required this.onClose,
    required this.onSearchSubmitted,
  });

  @override
  Widget build(BuildContext context) {
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
                      onTap: onBack,
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
                                  organizationName,
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
                      controller: searchController,
                      focusNode: searchFocusNode,
                      items: searchItems,
                      onNoMatch: onSearchSubmitted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space24),
              TextButton.icon(
                onPressed: onClose,
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
}

class _ProfileNavSection {
  final String title;
  final List<_ProfileNavBlock> blocks;

  const _ProfileNavSection({required this.title, required this.blocks});
}

class _ProfileNavBlock {
  final String title;
  final List<_ProfileNavEntry> items;

  const _ProfileNavBlock({required this.title, required this.items});
}

class _ProfileNavEntry {
  final String label;
  final String? route;
  const _ProfileNavEntry({required this.label, this.route});
}

class _ProfileAdditionalField {
  final TextEditingController labelController = TextEditingController();
  final TextEditingController valueController = TextEditingController();

  void dispose() {
    labelController.dispose();
    valueController.dispose();
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  static const double _dashWidth = 5;
  static const double _dashSpace = 4;
  static const double _strokeWidth = 1.2;

  const _DashedBorderPainter({
    this.color = const Color(0xFFD1D5DB),
    this.radius = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final extracted = metric.extractPath(distance, distance + _dashWidth);
        canvas.drawPath(extracted, paint);
        distance += _dashWidth + _dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

extension _SettingsOrgProfilePageHelper on _SettingsOrganizationProfilePageState {
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
          borderSide:
              BorderSide(color: ref.read(appBrandingProvider).accentColor),
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

  Widget _buildStaticField(String value) {
    return Container(
      width: double.infinity,
      height: 40,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.space10,
      ),
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
}

class _IndiaPhoneFormatter extends TextInputFormatter {
  static const String _prefix = '+91 ';
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    if (!text.startsWith(_prefix)) {
      String digits = text.replaceAll(RegExp(r'\D'), '');
      if (digits.startsWith('91') && digits.length > 10)
        digits = digits.substring(2);
      if (digits.length > 10) digits = digits.substring(0, 10);
      final result = _prefix + digits;
      return TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(offset: result.length),
      );
    }
    String digits = text
        .substring(_prefix.length)
        .replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);
    final result = _prefix + digits;
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

String _normalizeIndiaPhone(String raw) {
  if (raw.isEmpty) return '+91 ';
  final digits = raw.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
  final stripped = digits.startsWith('91') && digits.length > 10
      ? digits.substring(2)
      : digits;
  return '+91 ${stripped.length > 10 ? stripped.substring(0, 10) : stripped}';
}

