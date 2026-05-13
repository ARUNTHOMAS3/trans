import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_payment_terms_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/modules/sales/models/gstin_lookup_model.dart';
import 'package:zerpai_erp/modules/sales/services/gstin_lookup_service.dart';
import '../controllers/sales_order_controller.dart';
import '../models/sales_customer_model.dart';
import '../../items/pricelist/models/pricelist_model.dart';
import '../../items/pricelist/providers/pricelist_provider.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';
import 'package:zerpai_erp/shared/services/storage_service.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/mixins/licence_validation_mixin.dart';
import 'package:zerpai_erp/shared/widgets/inputs/gstin_prefill_banner.dart';
import 'package:zerpai_erp/shared/widgets/inputs/phone_input_field.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';

part 'sections/sales_customer_address_section.dart';
part 'sections/sales_customer_primary_info_section.dart';
part 'sections/sales_customer_other_details_section.dart';
part 'sections/sales_customer_contact_persons_section.dart';
part 'sections/sales_customer_custom_fields_section.dart';
part 'sections/sales_customer_reporting_tags_section.dart';
part 'sections/sales_customer_remarks_section.dart';
part 'sections/sales_customer_licence_section.dart';
part 'sections/sales_customer_attributes_section.dart';
part 'sections/sales_customer_dialogs.dart';
part 'sections/sales_customer_builders.dart';
part 'sections/sales_customer_helpers.dart';

class SalesCustomerCreateScreen extends ConsumerStatefulWidget {
  const SalesCustomerCreateScreen({
    super.key,
    this.initialCustomer,
    this.customerId,
    this.initialTab,
    this.onSaveSuccess,
    this.showLayout = true,
  });

  final SalesCustomer? initialCustomer;
  final String? customerId;
  final String? initialTab;
  final void Function(SalesCustomer)? onSaveSuccess;
  final bool showLayout;

  @override
  ConsumerState<SalesCustomerCreateScreen> createState() =>
      _SalesCustomerCreateScreenState();
}

class _SalesCustomerCreateScreenState
    extends ConsumerState<SalesCustomerCreateScreen>
    with TickerProviderStateMixin, LicenceValidationMixin<SalesCustomerCreateScreen> {
  static const List<String> _businessTabKeys = [
    'other-details',
    'licence-details',
    'address',
    'contact-persons',
    'custom-fields',
    'reporting-tags',
    'remarks',
  ];
  static const List<String> _individualTabKeys = [
    'other-details',
    'address',
    'alternative-contacts',
    'attributes',
    'custom-fields',
    'reporting-tags',
    'remarks',
  ];

  bool get _isEditMode => widget.initialCustomer != null || widget.customerId != null;
  String? get _editingCustomerId => widget.customerId ?? widget.initialCustomer?.id;
  String get _draftKey => _editingCustomerId == null ? 'create' : 'edit:${_editingCustomerId!}';
  List<String> get _tabKeys =>
      customerType == 'Individual' ? _individualTabKeys : _businessTabKeys;
  String get _orgSystemId =>
      GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
  static final Map<String, _SalesCustomerFormDraft> _draftCache = {};

  // LicenceValidationMixin: map local msme controller name to mixin contract
  @override
  TextEditingController get msmeCtrl => msmeNumberCtrl;
  late TabController _tabController;
  late final ScrollController _tabScrollController = ScrollController();
  bool isLoading = true;

  void _state(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void initState() {
    super.initState();
    final initialIndex = _resolveInitialTabIndex(widget.initialTab);
    _tabController = TabController(
      length: customerType == 'Individual' ? _individualTabKeys.length : _businessTabKeys.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_handleTabChanged);

    // Simulate initial load for skeleton feel
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          isLoading = false;
          // Start with one contact row by default
          if (contactRows.isEmpty) {
            contactRows.add(_ContactPersonRow());
          }
        });
      }
    });

    // Wire up focus-based licence validation via LicenceValidationMixin
    initLicenceValidation();

    // Load initial currencies
    _loadCurrencies();
    _loadNextCustomerNumber();

    // Load price lists, countries and phone codes
    Future.microtask(() {
      ref.read(priceListNotifierProvider.notifier).fetchPriceLists();
      _loadIndiaStates();
      _loadCountries();
      _loadPaymentTerms();
      final cachedDraft = _draftCache[_draftKey];
      if (cachedDraft != null) {
        _restoreDraft(cachedDraft);
      } else if (_isEditMode) {
        if (widget.initialCustomer != null) {
          _populateFromCustomer(widget.initialCustomer!);
        } else if (_editingCustomerId != null) {
          _loadEditingCustomer(_editingCustomerId!);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant SalesCustomerCreateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialTab != widget.initialTab) {
      final nextIndex = _resolveInitialTabIndex(widget.initialTab);
      if (nextIndex != _tabController.index && nextIndex < _tabController.length) {
        _tabController.animateTo(nextIndex);
      }
    }

    final oldCustomerId = oldWidget.customerId ?? oldWidget.initialCustomer?.id;
    if (oldCustomerId != _editingCustomerId &&
        widget.initialCustomer == null &&
        _editingCustomerId != null) {
      _loadEditingCustomer(_editingCustomerId!);
    }
  }

  int _resolveInitialTabIndex(String? initialTab) {
    if (initialTab == null || initialTab.trim().isEmpty) {
      return 0;
    }
    final businessIndex = _businessTabKeys.indexOf(initialTab);
    if (businessIndex != -1) {
      return businessIndex;
    }
    final individualIndex = _individualTabKeys.indexOf(initialTab);
    if (individualIndex != -1) {
      return individualIndex;
    }
    return 0;
  }

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging) {
      if (mounted) {
        setState(() {});
      }
      return;
    }

    _draftCache[_draftKey] = _createDraft();

    final tab = _tabKeys[_tabController.index];
    final routeName = _isEditMode ? AppRoutes.salesCustomersEdit : AppRoutes.salesCustomersCreate;
    final pathParameters = <String, String>{'orgSystemId': _orgSystemId};
    if (_isEditMode && _editingCustomerId != null) {
      pathParameters['id'] = _editingCustomerId!;
    }

    context.go(
      context.namedLocation(
        routeName,
        pathParameters: pathParameters,
        queryParameters: tab == _tabKeys.first ? {} : {'tab': tab},
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _tabScrollController.dispose();
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    companyNameCtrl.dispose();
    displayNameCtrl.dispose();
    emailCtrl.dispose();
    workPhoneCtrl.dispose();
    mobilePhoneCtrl.dispose();
    panCtrl.dispose();
    gstinPrefillCtrl.dispose();
    businessLegalNameCtrl.dispose();
    businessTradeNameCtrl.dispose();
    disposeLicenceNodes(); // From LicenceValidationMixin
    super.dispose();
  }

  Future<void> _loadEditingCustomer(String customerId) async {
    try {
      final customer = await ref.read(
        salesCustomerByIdProvider(customerId).future,
      );
      if (!mounted) return;
      setState(() {
        final cachedDraft = _draftCache[_draftKey];
        if (cachedDraft != null) {
          _restoreDraft(cachedDraft);
        } else {
          _populateFromCustomer(customer);
        }
      });
    } catch (e) {
      AppLogger.error('Error loading customer for edit', error: e);
      if (!mounted) return;
      ZerpaiToast.error(context, 'Unable to load customer for editing');
    }
  }

  // Layout Constants (Instance members for extension access)

  final double _labelWidth = 220.0;
  final double _fieldWidth = 480.0;
  final double _inputHeight = 32.0;
  final double _fieldSpacing = 24.0;

  // General Info
  String customerType = 'Business';
  String salutation = 'Mr.';
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final companyNameCtrl = TextEditingController();
  final displayNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final workPhoneCtrl = TextEditingController();
  final mobilePhoneCtrl = TextEditingController();
  List<String> _displayNameOptions = [];
  String phoneCode = '+91';
  String mobileCode = '+91';
  String customerLanguage = 'English';

  // PAN / GSTIN / Tax
  final panCtrl = TextEditingController();
  final gstinPrefillCtrl = TextEditingController();
  bool isGSTINLoading = false;
  late final GstinLookupService _gstinLookupService = GstinLookupService();
  _GstTreatmentOption gstTreatment = _gstTreatmentOptions.first;
  final businessLegalNameCtrl = TextEditingController();
  final businessTradeNameCtrl = TextEditingController();
  String placeOfSupply = 'Select';
  String taxPreference = 'Taxable';
  String? exemptionReason;

  List<String> _indiaStates = [];
  Future<void> _loadIndiaStates() async {
    try {
      final countries = await ref.read(countriesProvider(null).future);
      final india = countries.firstWhere(
        (c) => c['name'] == 'India' || c['id'] == 'IN',
        orElse: () => {},
      );

      if (india.isNotEmpty && india['id'] != null) {
        final states = await ref.read(statesProvider(india['id']!).future);
        _state(() {
          _indiaStates = states.map((s) => s['name'] ?? '').where((n) => n.isNotEmpty).toList();
        });
      }
    } catch (e) {
      AppLogger.error('Error loading India states', error: e);
    }
  }

  // Address
  final billingAttentionCtrl = TextEditingController();
  String? billingCountryId;
  final billingStreetCtrl = TextEditingController();
  final billingStreet2Ctrl = TextEditingController();
  final billingCityCtrl = TextEditingController();
  String? billingStateId;
  final billingPinCtrl = TextEditingController();
  String billingPhoneCode = '+91';
  final billingPhoneCtrl = TextEditingController();
  final billingFaxCtrl = TextEditingController();

  final shippingAttentionCtrl = TextEditingController();
  String? shippingCountryId;
  final shippingStreetCtrl = TextEditingController();
  final shippingStreet2Ctrl = TextEditingController();
  final shippingCityCtrl = TextEditingController();
  String? shippingStateId;
  final shippingPinCtrl = TextEditingController();
  String shippingPhoneCode = '+91';
  final shippingPhoneCtrl = TextEditingController();
  final shippingFaxCtrl = TextEditingController();

  // Settings & Others
  final customerNumberCtrl = TextEditingController();
  final customerNumberPrefixCtrl = TextEditingController(text: 'CUS');
  final customerNumberNextCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();
  final departmentCtrl = TextEditingController();
  final designationCtrl = TextEditingController();
  final xHandleCtrl = TextEditingController();
  final whatsappCtrl = TextEditingController();
  final facebookCtrl = TextEditingController();
  String businessType = 'COCO';
  String? parentCustomer;
  String gender = 'Male';
  final privilegeCardNumberCtrl = TextEditingController();

  bool showMoreDetails = false;
  List<CurrencyOption> _localCurrencyOptions = [];
  late CurrencyOption currency =
      defaultCurrencyOptions.first; // Default fallback
  final openingBalanceCtrl = TextEditingController();
  final creditLimitCtrl = TextEditingController();
  String paymentTerms = 'Net 360';
  PriceList? selectedPriceList;
  String? selectedPriceListId;
  List<Map<String, dynamic>> _priceListsList = [];
  bool enablePortal = false;


  // Phone codes (loaded dynamically from countries table)

  // Payment terms (loaded dynamically)
  List<Map<String, dynamic>> _paymentTermsList = [];

  // Licence Details
  bool isDrugRegistered = false;
  bool isFssaiRegistered = false;
  bool isMsmeRegistered = false;
  String? drugLicenceType; // No default selection
  String? msmeRegistrationType; // No default selection
  final drugLicense20Ctrl = TextEditingController(); // Retail Form 20
  final drugLicense21Ctrl = TextEditingController(); // Retail Form 21
  final drugLicense20BCtrl = TextEditingController(); // Wholesale Form 20B
  final drugLicense21BCtrl = TextEditingController(); // Wholesale Form 21B
  final fssaiCtrl = TextEditingController();
  final msmeNumberCtrl = TextEditingController();

  // Licence focus nodes (error strings come from LicenceValidationMixin)
  final drugLicense20Focus = FocusNode();
  final drugLicense21Focus = FocusNode();
  final drugLicense20BFocus = FocusNode();
  final drugLicense21BFocus = FocusNode();
  final fssaiFocus = FocusNode();
  final msmeFocus = FocusNode();

  // License document files
  List<PlatformFile> drugLicense20Docs = [];
  List<PlatformFile> drugLicense21Docs = [];
  List<PlatformFile> drugLicense20BDocs = [];
  List<PlatformFile> drugLicense21BDocs = [];
  List<PlatformFile> fssaiDocs = [];
  List<PlatformFile> msmeDocs = [];
  List<PlatformFile> documents = [];

  // Tabs Data
  final List<_ContactPersonRow> contactRows = [];
  String reportingTag = 'Select';
  _StaffOption? assignedStaff;
  _ReferralOption? referredBy;
  DateTime? dob;
  final dobCtrl = TextEditingController();
  String? dobDay;
  String? dobMonth;
  String? dobYear;
  final placeOfCustomerCtrl = TextEditingController();
  bool isRecurring = false;


  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'docx', 'xlsx'],
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      final remainingSlots = 5 - documents.length;
      if (remainingSlots <= 0) {
        if (mounted) {
          ZerpaiToast.info(context, 'Maximum 5 files allowed');
        }
        return;
      }

      final filesToAdd = result.files.take(remainingSlots).toList();
      documents.addAll(filesToAdd);
    });
  }

  void _removeDocument(PlatformFile file) {
    setState(() {
      documents.remove(file);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep _priceListsList in sync with the provider
    ref.watch(priceListNotifierProvider).whenData((lists) {
      _priceListsList = lists
          .map<Map<String, dynamic>>(
            (p) => <String, dynamic>{
              'id': p.id,
              'name': p.name,
              'status': p.status,
              'transaction_type': p.transactionType,
            },
          )
          .toList();
    });

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: isLoading
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildPrimaryInfo(), const FormSkeleton()],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrimaryInfo(),
                  const SizedBox(height: 32),
                  _buildTabSection(),
                ],
              ),
            ),
    );

    if (!widget.showLayout) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDialogHeader(),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Expanded(child: content),
          _buildFooter(),
        ],
      );
    }

    return ZerpaiLayout(
      pageTitle: _isEditMode ? 'Edit Customer' : 'New Customer',
      enableBodyScroll: true,
      footer: _buildFooter(),
      child: content,
    );
  }

  Widget _buildTabSection() {
    final List<Tab> tabs = [
      const Tab(text: 'Other Details'),
      if (customerType != 'Individual') const Tab(text: 'Licence Details'),
      const Tab(text: 'Address'),
      Tab(
        text: customerType == 'Individual'
            ? 'Alternative contacts'
            : 'Contact Persons',
      ),
      if (customerType == 'Individual') const Tab(text: 'Attributes'),
      const Tab(text: 'Custom Fields'),
      const Tab(text: 'Reporting Tags'),
      const Tab(text: 'Remarks'),
    ];

    final List<Widget> tabViews = [
      _buildOtherDetails(),
      if (customerType != 'Individual') _buildLicenceSection(),
      _buildAddressSection(),
      _buildContactPersons(),
      if (customerType == 'Individual') _buildAttributes(),
      _buildCustomFields(),
      _buildReportingTags(),
      _buildRemarks(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Scrollbar(
            controller: _tabScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _tabScrollController,
              scrollDirection: Axis.horizontal,
              child: TabBar(
                padding: EdgeInsets.zero,
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.black,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryBlueDark,
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.label,
                labelPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 2,
                ),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: tabs,
              ),
            ),
          ),
        ),
        // Use direct indexing to allow the whole page to scroll as one
        tabViews[_tabController.index],
      ],
    );
  }

  // Validation state
  Set<String> validationErrors = {};
  final Map<String, String> fieldErrors = {};
  bool hasAttemptedSubmit = false;

  void _setFieldError(String field, String message) {
    validationErrors.add(field);
    fieldErrors[field] = message;
  }

  void _clearFieldError(String field) {
    validationErrors.remove(field);
    fieldErrors.remove(field);
  }

  String? _fieldError(String field) => fieldErrors[field];

  bool _hasFieldError(String field) => validationErrors.contains(field);

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _buildErrorToastMessage([Map<String, String>? source]) {
    final entries = (source ?? fieldErrors)
        .entries
        .where((entry) => entry.key != 'form' && entry.value.trim().isNotEmpty)
        .map((entry) => entry.value.trim())
        .toSet()
        .toList();

    if (entries.isEmpty) {
      final formMessage = (source ?? fieldErrors)['form'];
      if (formMessage != null && formMessage.trim().isNotEmpty) {
        return formMessage.trim();
      }
      return 'Please fix the highlighted validation errors';
    }

    return entries.join('\n');
  }

  String? _normalizedDigits(String value) {
    final digits = _digitsOnly(value);
    return digits.isEmpty ? null : digits;
  }

  void _validateDisplayNameField([String? value]) {
    final displayName = (value ?? displayNameCtrl.text).trim();
    if (displayName.isEmpty) {
      _setFieldError('displayName', 'Display name is required');
    } else {
      _clearFieldError('displayName');
    }
  }

  void _validateEmailField([String? value]) {
    final email = (value ?? emailCtrl.text).trim();
    if (enablePortal && email.isEmpty) {
      _setFieldError('email', 'Email is required when portal access is enabled');
    } else if (email.isNotEmpty && !_isValidEmail(email)) {
      _setFieldError('email', 'Enter a valid email address');
    } else {
      _clearFieldError('email');
    }
  }

  void _validatePhoneField(String field, String value) {
    final digits = _normalizedDigits(value.trim());
    if (digits != null && digits.length != 10) {
      final label = switch (field) {
        'phone' => 'Phone number must be exactly 10 digits',
        'mobilePhone' => 'Mobile number must be exactly 10 digits',
        'whatsappNumber' => 'WhatsApp number must be exactly 10 digits',
        _ => 'Phone number must be exactly 10 digits',
      };
      _setFieldError(field, label);
    } else {
      _clearFieldError(field);
    }
  }

  void _runLiveValidation(VoidCallback update) {
    _state(() {
      update();
    });
  }

  Map<String, String> _extractBackendFieldErrors(Object error) {
    final mapped = <String, String>{};
    if (error is! DioException) {
      return mapped;
    }

    final data = error.response?.data;
    if (data is! Map<String, dynamic>) {
      return mapped;
    }

    final details = data['details'];
    if (details is List) {
      for (final detail in details) {
        if (detail is! Map) continue;
        final rawField = (detail['field'] ?? '').toString();
        if (rawField.isEmpty) continue;
        final constraints = detail['constraints'];
        String? message;
        if (constraints is Map && constraints.isNotEmpty) {
          message = constraints.values.first.toString();
        } else if (detail['message'] != null) {
          message = detail['message'].toString();
        }
        if (message == null || message.isEmpty) continue;

        final field = switch (rawField) {
          'whatsappNumber' => 'whatsappNumber',
          'phone' => 'phone',
          'mobilePhone' => 'mobilePhone',
          'displayName' => 'displayName',
          'email' => 'email',
          'contactPersons' => 'contactPersons',
          _ => rawField,
        };
        mapped[field] = message;
      }
    }

    final message = data['message'];
    if (mapped.isEmpty && message is String && message.isNotEmpty) {
      final lowerMessage = message.toLowerCase();
      if (lowerMessage.contains('customer number already exists') ||
          lowerMessage.contains('customers_customer_number_key')) {
        mapped['customerNumber'] = 'Customer number already exists';
      } else {
        mapped['form'] = message;
      }
    }
    return mapped;
  }

  Future<void> _saveCustomer() async {
    // Mark that user has attempted to submit
    setState(() {
      hasAttemptedSubmit = true;
      validationErrors.clear();
      fieldErrors.clear();
    });

    // Validate required fields
    if (displayNameCtrl.text.trim().isEmpty) {
      _setFieldError('displayName', 'Display name is required');
    }
    final email = emailCtrl.text.trim();
    if (enablePortal && email.isEmpty) {
      _setFieldError('email', 'Email is required when portal access is enabled');
    } else if (email.isNotEmpty && !_isValidEmail(email)) {
      _setFieldError('email', 'Enter a valid email address');
    }

    final phoneDigits = _normalizedDigits(workPhoneCtrl.text.trim());
    if (phoneDigits != null && phoneDigits.length != 10) {
      _setFieldError('phone', 'Phone number must be exactly 10 digits');
    }

    final mobileDigits = _normalizedDigits(mobilePhoneCtrl.text.trim());
    if (mobileDigits != null && mobileDigits.length != 10) {
      _setFieldError('mobilePhone', 'Mobile number must be exactly 10 digits');
    }

    final whatsappDigits = _normalizedDigits(whatsappCtrl.text.trim());
    if (whatsappDigits != null && whatsappDigits.length != 10) {
      _setFieldError(
        'whatsappNumber',
        'WhatsApp number must be exactly 10 digits',
      );
    }

    // If there are validation errors, show message and return
    if (validationErrors.isNotEmpty) {
      setState(() {}); // Rebuild to show red borders
      ZerpaiToast.error(context, _buildErrorToastMessage());
      return;
    }

    // Show loading
    setState(() => isLoading = true);

    try {
      // Upload license documents if any are selected
      final storage = StorageService();
      String? drugLicense20Url;
      String? drugLicense21Url;
      String? drugLicense20BUrl;
      String? drugLicense21BUrl;
      String? fssaiUrl;
      String? msmeUrl;
      String? generalDocumentUrls;

      if (drugLicense20Docs.isNotEmpty) {
        final urls = <String>[];
        for (final file in drugLicense20Docs) {
          final url = await storage.uploadLicenseDocument(file);
          if (url != null) urls.add(url);
        }
        drugLicense20Url = urls.isNotEmpty ? urls.join(',') : null;
      }
      if (drugLicense21Docs.isNotEmpty) {
        final urls = <String>[];
        for (final file in drugLicense21Docs) {
          final url = await storage.uploadLicenseDocument(file);
          if (url != null) urls.add(url);
        }
        drugLicense21Url = urls.isNotEmpty ? urls.join(',') : null;
      }
      if (drugLicense20BDocs.isNotEmpty) {
        final urls = <String>[];
        for (final file in drugLicense20BDocs) {
          final url = await storage.uploadLicenseDocument(file);
          if (url != null) urls.add(url);
        }
        drugLicense20BUrl = urls.isNotEmpty ? urls.join(',') : null;
      }
      if (drugLicense21BDocs.isNotEmpty) {
        final urls = <String>[];
        for (final file in drugLicense21BDocs) {
          final url = await storage.uploadLicenseDocument(file);
          if (url != null) urls.add(url);
        }
        drugLicense21BUrl = urls.isNotEmpty ? urls.join(',') : null;
      }
      if (fssaiDocs.isNotEmpty) {
        final urls = <String>[];
        for (final file in fssaiDocs) {
          final url = await storage.uploadLicenseDocument(file);
          if (url != null) urls.add(url);
        }
        fssaiUrl = urls.isNotEmpty ? urls.join(',') : null;
      }
      if (msmeDocs.isNotEmpty) {
        final urls = <String>[];
        for (final file in msmeDocs) {
          final url = await storage.uploadLicenseDocument(file);
          if (url != null) urls.add(url);
        }
        msmeUrl = urls.isNotEmpty ? urls.join(',') : null;
      }
      if (documents.isNotEmpty) {
        final urls = <String>[];
        for (final file in documents) {
          final url = await storage.uploadLicenseDocument(file);
          if (url != null) urls.add(url);
        }
        generalDocumentUrls = urls.isNotEmpty ? urls.join(',') : null;
      }

      final contactPersons = contactRows
          .where((row) {
            final firstName = row.firstNameCtrl.text.trim();
            final lastName = row.lastNameCtrl.text.trim();
            final email = row.emailCtrl.text.trim();
            final workPhone = row.workPhoneCtrl.text.trim();
            final mobilePhone = row.mobilePhoneCtrl.text.trim();
            return firstName.isNotEmpty ||
                lastName.isNotEmpty ||
                email.isNotEmpty ||
                workPhone.isNotEmpty ||
                mobilePhone.isNotEmpty;
          })
          .map((row) {
            final firstName = row.firstNameCtrl.text.trim();
            final lastName = row.lastNameCtrl.text.trim();
            final email = row.emailCtrl.text.trim();
            final workPhone = row.workPhoneCtrl.text.trim();
            final mobilePhone = row.mobilePhoneCtrl.text.trim();
            return CustomerContact(
              salutation: row.salutation,
              firstName: firstName.isNotEmpty ? firstName : null,
              lastName: lastName.isNotEmpty ? lastName : null,
              email: email.isNotEmpty ? email : null,
              workPhone: _normalizedDigits(workPhone),
              mobilePhone: _normalizedDigits(mobilePhone),
            );
          })
          .toList();

      final newCustomer = SalesCustomer(
        id: '', // Backend will generate UUID
        customerNumber: customerNumberCtrl.text.trim(),
        displayName: displayNameCtrl.text.trim(),
        customerType: customerType,
        salutation: salutation,
        firstName: firstNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        companyName: companyNameCtrl.text.trim(),
        businessType: businessType,
        email: emailCtrl.text.trim(),
        phone: phoneDigits,
        mobilePhone: mobileDigits,
        designation: designationCtrl.text.trim(),
        department: departmentCtrl.text.trim(),
        gstTreatment: gstTreatment.label,
        gstin: gstinPrefillCtrl.text.trim(),
        placeOfSupply: placeOfSupply == 'Select' ? null : placeOfSupply,
        pan: panCtrl.text.trim(),
        taxPreference: taxPreference,
        exemptionReason: exemptionReason,
        currencyId: currency.id.isNotEmpty ? currency.id : null,
        openingBalance: double.tryParse(openingBalanceCtrl.text) ?? 0,
        creditLimit: double.tryParse(creditLimitCtrl.text) ?? 0,
        paymentTerms: paymentTerms,
        priceList: selectedPriceListId,
        billingAddressStreet1: billingStreetCtrl.text.trim(),
        billingAddressStreet2: billingStreet2Ctrl.text.trim(),
        billingAddressCity: billingCityCtrl.text.trim(),
        billingAddressStateId: billingStateId,
        billingAddressZip: billingPinCtrl.text.trim(),
        billingAddressCountryId: billingCountryId,
        billingAddressPhone: _normalizedDigits(billingPhoneCtrl.text.trim()),
        shippingAddressStreet1: shippingStreetCtrl.text.trim(),
        shippingAddressStreet2: shippingStreet2Ctrl.text.trim(),
        shippingAddressCity: shippingCityCtrl.text.trim(),
        shippingAddressStateId: shippingStateId,
        shippingAddressZip: shippingPinCtrl.text.trim(),
        shippingAddressCountryId: shippingCountryId,
        shippingAddressPhone: _normalizedDigits(shippingPhoneCtrl.text.trim()),
        enablePortal: enablePortal,
        facebookHandle: facebookCtrl.text.trim(),
        twitterHandle: xHandleCtrl.text.trim(),
        whatsappNumber: whatsappDigits,
        isDrugRegistered: isDrugRegistered,
        isFssaiRegistered: isFssaiRegistered,
        isMsmeRegistered: isMsmeRegistered,
        drugLicenceType: drugLicenceType,
        drugLicense20: drugLicense20Ctrl.text.trim(),
        drugLicense21: drugLicense21Ctrl.text.trim(),
        drugLicense20B: drugLicense20BCtrl.text.trim(),
        drugLicense21B: drugLicense21BCtrl.text.trim(),
        fssai: fssaiCtrl.text.trim(),
        msmeRegistrationType: msmeRegistrationType,
        msmeNumber: msmeNumberCtrl.text.trim(),
        drugLicense20DocUrl: drugLicense20Url,
        drugLicense21DocUrl: drugLicense21Url,
        drugLicense20BDocUrl: drugLicense20BUrl,
        drugLicense21BDocUrl: drugLicense21BUrl,
        fssaiDocUrl: fssaiUrl,
        msmeDocUrl: msmeUrl,
        documentUrls: generalDocumentUrls,
        isRecurring: isRecurring,
        contactPersons: contactPersons.isNotEmpty ? contactPersons : null,
      );

      final controller = ref.read(salesOrderControllerProvider.notifier);
      SalesCustomer result;
      if (_isEditMode && _editingCustomerId != null) {
        result = await controller.updateCustomer(
          _editingCustomerId!,
          newCustomer.toJson(),
        );
      } else {
        result = await controller.createCustomer(newCustomer);
      }

      if (mounted) {
        ZerpaiToast.success(
          context,
          _isEditMode
              ? 'Customer ${result.displayName} updated successfully!'
              : 'Customer ${result.displayName} created successfully!',
        );
        _draftCache.remove(_draftKey);
        
        if (widget.onSaveSuccess != null) {
          widget.onSaveSuccess!(result);
          return;
        }

        // Navigate
        if (mounted) {
          context.goNamed(
            AppRoutes.salesCustomersDetail,
            pathParameters: {'orgSystemId': _orgSystemId, 'id': result.id},
          );
        }
      }
    } catch (e) {
      final isUserFixableResponse =
          e is DioException && e.type == DioExceptionType.badResponse;
      final actionLabel = _isEditMode ? 'update' : 'create';
      if (isUserFixableResponse) {
        AppLogger.warning('Customer save rejected', error: e);
      } else {
        AppLogger.error('Error $actionLabel customer', error: e);
      }
      if (mounted) {
        final backendFieldErrors = _extractBackendFieldErrors(e);
        if (backendFieldErrors.isNotEmpty) {
          setState(() {
            for (final entry in backendFieldErrors.entries) {
              if (entry.key == 'form') continue;
              _setFieldError(entry.key, entry.value);
            }
          });
          ZerpaiToast.error(context, _buildErrorToastMessage(backendFieldErrors));
        } else {
          final friendlyMessage = ErrorHandler.getFriendlyMessage(e);
          ZerpaiToast.error(context, friendlyMessage);
        }
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Email validation helper
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _loadCurrencies() async {
    try {
      final currencies = await ref.read(currenciesProvider(null).future);
      if (mounted) {
        setState(() {
          _localCurrencyOptions = currencies;
          if (currencies.isNotEmpty) {
            final selectedCurrencyId =
                widget.initialCustomer?.currencyId?.trim();
            final matchedCurrency = selectedCurrencyId == null ||
                    selectedCurrencyId.isEmpty
                ? null
                : currencies.cast<CurrencyOption?>().firstWhere(
                    (c) =>
                        c != null &&
                        (c.id == selectedCurrencyId ||
                            c.code == selectedCurrencyId),
                    orElse: () => null,
                  );
            if (matchedCurrency != null) {
              currency = matchedCurrency;
            } else {
              final inrIndex = currencies.indexWhere((c) => c.code == 'INR');
              if (inrIndex != -1) {
                currency = currencies[inrIndex];
              } else {
                currency = currencies.first;
              }
            }
          }
        });
      }
    } catch (e) {
      AppLogger.error('Error loading currencies', error: e);
      if (mounted && _localCurrencyOptions.isEmpty) {
        setState(() {
          _localCurrencyOptions = defaultCurrencyOptions;
          currency = defaultCurrencyOptions.first;
        });
      }
    }
  }

  Future<void> _loadNextCustomerNumber() async {
    if (_isEditMode) return;

    final current = customerNumberCtrl.text.trim();
    if (current.isNotEmpty) return;

    try {
      final lookupsService = LookupsApiService();
      final nextNumber = await lookupsService.getNextSequence('customer');
      if (!mounted || nextNumber == null || nextNumber.trim().isEmpty) return;

      setState(() {
        customerNumberCtrl.text = nextNumber.trim();
        _syncCustomerNumberPreferences();
      });
    } catch (e) {
      AppLogger.error('Error loading next customer number', error: e);
    }
  }

  Future<void> _loadPaymentTerms() async {
    try {
      final lookupsService = LookupsApiService();
      final terms = await lookupsService.getPaymentTerms();
      if (!mounted) return;

      setState(() {
        _paymentTermsList = terms;

        final hasSelectedTerm = _paymentTermsList.any(
          (term) =>
              (term['id']?.toString() ?? '') == paymentTerms ||
              (term['term_name']?.toString() ?? '') == paymentTerms,
        );

        if (!hasSelectedTerm && paymentTerms.trim().isNotEmpty) {
          _paymentTermsList = [
            ..._paymentTermsList,
            <String, dynamic>{
              'id': paymentTerms,
              'term_name': paymentTerms,
            },
          ];
        }
      });
    } catch (e) {
      AppLogger.error('Error loading payment terms', error: e);
      if (!mounted) return;

      setState(() {
        if (_paymentTermsList.isEmpty && paymentTerms.trim().isNotEmpty) {
          _paymentTermsList = [
            <String, dynamic>{
              'id': paymentTerms,
              'term_name': paymentTerms,
            },
          ];
        }
      });
    }
  }

  _SalesCustomerFormDraft _createDraft() {
    return _SalesCustomerFormDraft(
      customerType: customerType,
      salutation: salutation,
      firstName: firstNameCtrl.text,
      lastName: lastNameCtrl.text,
      companyName: companyNameCtrl.text,
      displayName: displayNameCtrl.text,
      email: emailCtrl.text,
      workPhone: workPhoneCtrl.text,
      mobilePhone: mobilePhoneCtrl.text,
      phoneCode: phoneCode,
      mobileCode: mobileCode,
      customerLanguage: customerLanguage,
      pan: panCtrl.text,
      gstin: gstinPrefillCtrl.text,
      businessLegalName: businessLegalNameCtrl.text,
      businessTradeName: businessTradeNameCtrl.text,
      placeOfSupply: placeOfSupply,
      taxPreference: taxPreference,
      exemptionReason: exemptionReason,
      currency: currency,
      openingBalance: openingBalanceCtrl.text,
      creditLimit: creditLimitCtrl.text,
      paymentTerms: paymentTerms,
      selectedPriceListId: selectedPriceListId,
      enablePortal: enablePortal,
      customerNumber: customerNumberCtrl.text,
      customerNumberPrefix: customerNumberPrefixCtrl.text,
      customerNumberNext: customerNumberNextCtrl.text,
      remarks: remarksCtrl.text,
      department: departmentCtrl.text,
      designation: designationCtrl.text,
      xHandle: xHandleCtrl.text,
      whatsapp: whatsappCtrl.text,
      facebook: facebookCtrl.text,
      businessType: businessType,
      parentCustomer: parentCustomer,
      gender: gender,
      privilegeCardNumber: privilegeCardNumberCtrl.text,
      showMoreDetails: showMoreDetails,
      isDrugRegistered: isDrugRegistered,
      isFssaiRegistered: isFssaiRegistered,
      isMsmeRegistered: isMsmeRegistered,
      drugLicenceType: drugLicenceType,
      msmeRegistrationType: msmeRegistrationType,
      drugLicense20: drugLicense20Ctrl.text,
      drugLicense21: drugLicense21Ctrl.text,
      drugLicense20B: drugLicense20BCtrl.text,
      drugLicense21B: drugLicense21BCtrl.text,
      fssai: fssaiCtrl.text,
      msmeNumber: msmeNumberCtrl.text,
      drugLicense20Docs: List<PlatformFile>.from(drugLicense20Docs),
      drugLicense21Docs: List<PlatformFile>.from(drugLicense21Docs),
      drugLicense20BDocs: List<PlatformFile>.from(drugLicense20BDocs),
      drugLicense21BDocs: List<PlatformFile>.from(drugLicense21BDocs),
      fssaiDocs: List<PlatformFile>.from(fssaiDocs),
      msmeDocs: List<PlatformFile>.from(msmeDocs),
      documents: List<PlatformFile>.from(documents),
      billingCountryId: billingCountryId,
      billingStreet1: billingStreetCtrl.text,
      billingStreet2: billingStreet2Ctrl.text,
      billingCity: billingCityCtrl.text,
      billingStateId: billingStateId,
      billingPin: billingPinCtrl.text,
      billingPhoneCode: billingPhoneCode,
      billingPhone: billingPhoneCtrl.text,
      billingFax: billingFaxCtrl.text,
      shippingCountryId: shippingCountryId,
      shippingStreet1: shippingStreetCtrl.text,
      shippingStreet2: shippingStreet2Ctrl.text,
      shippingCity: shippingCityCtrl.text,
      shippingStateId: shippingStateId,
      shippingPin: shippingPinCtrl.text,
      shippingPhoneCode: shippingPhoneCode,
      shippingPhone: shippingPhoneCtrl.text,
      shippingFax: shippingFaxCtrl.text,
      dob: dob,
      dobText: dobCtrl.text,
      dobDay: dobDay,
      dobMonth: dobMonth,
      dobYear: dobYear,
      placeOfCustomer: placeOfCustomerCtrl.text,
      isRecurring: isRecurring,
      reportingTag: reportingTag,
      contactRows: contactRows
          .map(
            (row) => _ContactPersonDraft(
              salutation: row.salutation,
              firstName: row.firstNameCtrl.text,
              lastName: row.lastNameCtrl.text,
              email: row.emailCtrl.text,
              workCode: row.workCode,
              workPhone: row.workPhoneCtrl.text,
              mobileCode: row.mobileCode,
              mobilePhone: row.mobilePhoneCtrl.text,
            ),
          )
          .toList(),
    );
  }

  void _restoreDraft(_SalesCustomerFormDraft draft) {
    customerType = draft.customerType.trim().toLowerCase() == 'individual'
        ? 'Individual'
        : 'Business';
    salutation = draft.salutation;
    firstNameCtrl.text = draft.firstName;
    lastNameCtrl.text = draft.lastName;
    companyNameCtrl.text = draft.companyName;
    displayNameCtrl.text = draft.displayName;
    emailCtrl.text = draft.email;
    workPhoneCtrl.text = draft.workPhone;
    mobilePhoneCtrl.text = draft.mobilePhone;
    phoneCode = draft.phoneCode;
    mobileCode = draft.mobileCode;
    customerLanguage = draft.customerLanguage;
    panCtrl.text = draft.pan;
    gstinPrefillCtrl.text = draft.gstin;
    businessLegalNameCtrl.text = draft.businessLegalName;
    businessTradeNameCtrl.text = draft.businessTradeName;
    placeOfSupply = draft.placeOfSupply;
    taxPreference = draft.taxPreference;
    exemptionReason = draft.exemptionReason;
    currency = draft.currency;
    openingBalanceCtrl.text = draft.openingBalance;
    creditLimitCtrl.text = draft.creditLimit;
    paymentTerms = draft.paymentTerms;
    selectedPriceListId = draft.selectedPriceListId;
    enablePortal = draft.enablePortal;
    customerNumberCtrl.text = draft.customerNumber;
    customerNumberPrefixCtrl.text = draft.customerNumberPrefix;
    customerNumberNextCtrl.text = draft.customerNumberNext;
    remarksCtrl.text = draft.remarks;
    departmentCtrl.text = draft.department;
    designationCtrl.text = draft.designation;
    xHandleCtrl.text = draft.xHandle;
    whatsappCtrl.text = draft.whatsapp;
    facebookCtrl.text = draft.facebook;
    businessType = draft.businessType;
    parentCustomer = draft.parentCustomer;
    gender = draft.gender;
    privilegeCardNumberCtrl.text = draft.privilegeCardNumber;
    showMoreDetails = draft.showMoreDetails;
    isDrugRegistered = draft.isDrugRegistered;
    isFssaiRegistered = draft.isFssaiRegistered;
    isMsmeRegistered = draft.isMsmeRegistered;
    drugLicenceType = draft.drugLicenceType;
    msmeRegistrationType = draft.msmeRegistrationType;
    drugLicense20Ctrl.text = draft.drugLicense20;
    drugLicense21Ctrl.text = draft.drugLicense21;
    drugLicense20BCtrl.text = draft.drugLicense20B;
    drugLicense21BCtrl.text = draft.drugLicense21B;
    fssaiCtrl.text = draft.fssai;
    msmeNumberCtrl.text = draft.msmeNumber;
    drugLicense20Docs = List<PlatformFile>.from(draft.drugLicense20Docs);
    drugLicense21Docs = List<PlatformFile>.from(draft.drugLicense21Docs);
    drugLicense20BDocs = List<PlatformFile>.from(draft.drugLicense20BDocs);
    drugLicense21BDocs = List<PlatformFile>.from(draft.drugLicense21BDocs);
    fssaiDocs = List<PlatformFile>.from(draft.fssaiDocs);
    msmeDocs = List<PlatformFile>.from(draft.msmeDocs);
    documents = List<PlatformFile>.from(draft.documents);
    billingCountryId = draft.billingCountryId;
    billingStreetCtrl.text = draft.billingStreet1;
    billingStreet2Ctrl.text = draft.billingStreet2;
    billingCityCtrl.text = draft.billingCity;
    billingStateId = draft.billingStateId;
    billingPinCtrl.text = draft.billingPin;
    billingPhoneCode = draft.billingPhoneCode;
    billingPhoneCtrl.text = draft.billingPhone;
    billingFaxCtrl.text = draft.billingFax;
    shippingCountryId = draft.shippingCountryId;
    shippingStreetCtrl.text = draft.shippingStreet1;
    shippingStreet2Ctrl.text = draft.shippingStreet2;
    shippingCityCtrl.text = draft.shippingCity;
    shippingStateId = draft.shippingStateId;
    shippingPinCtrl.text = draft.shippingPin;
    shippingPhoneCode = draft.shippingPhoneCode;
    shippingPhoneCtrl.text = draft.shippingPhone;
    shippingFaxCtrl.text = draft.shippingFax;
    dob = draft.dob;
    dobCtrl.text = draft.dobText;
    dobDay = draft.dobDay;
    dobMonth = draft.dobMonth;
    dobYear = draft.dobYear;
    placeOfCustomerCtrl.text = draft.placeOfCustomer;
    isRecurring = draft.isRecurring;
    reportingTag = draft.reportingTag;

    for (final row in contactRows) {
      row.dispose();
    }
    contactRows
      ..clear()
      ..addAll(
        draft.contactRows.map((rowDraft) {
          final row = _ContactPersonRow()
            ..salutation = rowDraft.salutation
            ..workCode = rowDraft.workCode
            ..mobileCode = rowDraft.mobileCode;
          row.firstNameCtrl.text = rowDraft.firstName;
          row.lastNameCtrl.text = rowDraft.lastName;
          row.emailCtrl.text = rowDraft.email;
          row.workPhoneCtrl.text = rowDraft.workPhone;
          row.mobilePhoneCtrl.text = rowDraft.mobilePhone;
          return row;
        }),
      );
    if (contactRows.isEmpty) {
      contactRows.add(_ContactPersonRow());
    }

    _refreshDisplayNameOptions();
    _syncCustomerNumberPreferences();
  }
}

class _SalesCustomerFormDraft {
  final String customerType;
  final String salutation;
  final String firstName;
  final String lastName;
  final String companyName;
  final String displayName;
  final String email;
  final String workPhone;
  final String mobilePhone;
  final String phoneCode;
  final String mobileCode;
  final String customerLanguage;
  final String pan;
  final String gstin;
  final String businessLegalName;
  final String businessTradeName;
  final String placeOfSupply;
  final String taxPreference;
  final String? exemptionReason;
  final CurrencyOption currency;
  final String openingBalance;
  final String creditLimit;
  final String paymentTerms;
  final String? selectedPriceListId;
  final bool enablePortal;
  final String customerNumber;
  final String customerNumberPrefix;
  final String customerNumberNext;
  final String remarks;
  final String department;
  final String designation;
  final String xHandle;
  final String whatsapp;
  final String facebook;
  final String businessType;
  final String? parentCustomer;
  final String gender;
  final String privilegeCardNumber;
  final bool showMoreDetails;
  final bool isDrugRegistered;
  final bool isFssaiRegistered;
  final bool isMsmeRegistered;
  final String? drugLicenceType;
  final String? msmeRegistrationType;
  final String drugLicense20;
  final String drugLicense21;
  final String drugLicense20B;
  final String drugLicense21B;
  final String fssai;
  final String msmeNumber;
  final List<PlatformFile> drugLicense20Docs;
  final List<PlatformFile> drugLicense21Docs;
  final List<PlatformFile> drugLicense20BDocs;
  final List<PlatformFile> drugLicense21BDocs;
  final List<PlatformFile> fssaiDocs;
  final List<PlatformFile> msmeDocs;
  final List<PlatformFile> documents;
  final String? billingCountryId;
  final String billingStreet1;
  final String billingStreet2;
  final String billingCity;
  final String? billingStateId;
  final String billingPin;
  final String billingPhoneCode;
  final String billingPhone;
  final String billingFax;
  final String? shippingCountryId;
  final String shippingStreet1;
  final String shippingStreet2;
  final String shippingCity;
  final String? shippingStateId;
  final String shippingPin;
  final String shippingPhoneCode;
  final String shippingPhone;
  final String shippingFax;
  final DateTime? dob;
  final String dobText;
  final String? dobDay;
  final String? dobMonth;
  final String? dobYear;
  final String placeOfCustomer;
  final bool isRecurring;
  final String reportingTag;
  final List<_ContactPersonDraft> contactRows;

  const _SalesCustomerFormDraft({
    required this.customerType,
    required this.salutation,
    required this.firstName,
    required this.lastName,
    required this.companyName,
    required this.displayName,
    required this.email,
    required this.workPhone,
    required this.mobilePhone,
    required this.phoneCode,
    required this.mobileCode,
    required this.customerLanguage,
    required this.pan,
    required this.gstin,
    required this.businessLegalName,
    required this.businessTradeName,
    required this.placeOfSupply,
    required this.taxPreference,
    required this.exemptionReason,
    required this.currency,
    required this.openingBalance,
    required this.creditLimit,
    required this.paymentTerms,
    required this.selectedPriceListId,
    required this.enablePortal,
    required this.customerNumber,
    required this.customerNumberPrefix,
    required this.customerNumberNext,
    required this.remarks,
    required this.department,
    required this.designation,
    required this.xHandle,
    required this.whatsapp,
    required this.facebook,
    required this.businessType,
    required this.parentCustomer,
    required this.gender,
    required this.privilegeCardNumber,
    required this.showMoreDetails,
    required this.isDrugRegistered,
    required this.isFssaiRegistered,
    required this.isMsmeRegistered,
    required this.drugLicenceType,
    required this.msmeRegistrationType,
    required this.drugLicense20,
    required this.drugLicense21,
    required this.drugLicense20B,
    required this.drugLicense21B,
    required this.fssai,
    required this.msmeNumber,
    required this.drugLicense20Docs,
    required this.drugLicense21Docs,
    required this.drugLicense20BDocs,
    required this.drugLicense21BDocs,
    required this.fssaiDocs,
    required this.msmeDocs,
    required this.documents,
    required this.billingCountryId,
    required this.billingStreet1,
    required this.billingStreet2,
    required this.billingCity,
    required this.billingStateId,
    required this.billingPin,
    required this.billingPhoneCode,
    required this.billingPhone,
    required this.billingFax,
    required this.shippingCountryId,
    required this.shippingStreet1,
    required this.shippingStreet2,
    required this.shippingCity,
    required this.shippingStateId,
    required this.shippingPin,
    required this.shippingPhoneCode,
    required this.shippingPhone,
    required this.shippingFax,
    required this.dob,
    required this.dobText,
    required this.dobDay,
    required this.dobMonth,
    required this.dobYear,
    required this.placeOfCustomer,
    required this.isRecurring,
    required this.reportingTag,
    required this.contactRows,
  });
}

class _ContactPersonDraft {
  final String salutation;
  final String firstName;
  final String lastName;
  final String email;
  final String workCode;
  final String workPhone;
  final String mobileCode;
  final String mobilePhone;

  const _ContactPersonDraft({
    required this.salutation,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.workCode,
    required this.workPhone,
    required this.mobileCode,
    required this.mobilePhone,
  });
}

class _ContactPersonRow {
  String salutation = 'Mr.';
  bool isHovered = false;
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  String workCode = '+91';
  final workPhoneCtrl = TextEditingController();
  String mobileCode = '+91';
  final mobilePhoneCtrl = TextEditingController();

  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    workPhoneCtrl.dispose();
    mobilePhoneCtrl.dispose();
  }
}

class _StaffOption {
  final String id;
  final String name;
  final String phone;

  const _StaffOption({
    required this.id,
    required this.name,
    required this.phone,
  });

  @override
  String toString() {
    return '$name | $phone | $id';
  }
}

enum _ReferralType { customer, staff, business }

class _ReferralOption {
  final _ReferralType type;
  final String id;
  final String name;
  final String phone;

  const _ReferralOption({
    required this.type,
    required this.id,
    required this.name,
    required this.phone,
  });

  String get displayLabel {
    final typeLabel = type.name[0].toUpperCase() + type.name.substring(1);
    return '$typeLabel - $name';
  }

  @override
  String toString() {
    final typeLabel = type.name[0].toUpperCase() + type.name.substring(1);
    return '$typeLabel | $name | $phone | $id';
  }
}

class _GstTreatmentOption {
  final String label;
  final String description;
  const _GstTreatmentOption(this.label, this.description);
}

const List<_GstTreatmentOption> _gstTreatmentOptions = [
  _GstTreatmentOption(
    'Registered Business - Regular',
    'Business that is registered under GST',
  ),
  _GstTreatmentOption(
    'Registered Business - Composition',
    'Business that is registered under the Composition Scheme in GST',
  ),
  _GstTreatmentOption(
    'Unregistered Business',
    'Business that has not been registered under GST',
  ),
  _GstTreatmentOption('Consumer', 'A customer who is a regular consumer'),
  _GstTreatmentOption(
    'Overseas',
    'Persons with whom you do import or export of supplies outside India',
  ),
  _GstTreatmentOption(
    'Special Economic Zone',
    'Business (Unit) that is located in a Special Economic Zone (SEZ) of '
        'India or a SEZ Developer',
  ),
  _GstTreatmentOption(
    'Deemed Export',
    'Supply of goods to an Export Oriented Unit or against Advanced '
        'Authorization/Export Promotion Capital Goods.',
  ),
  _GstTreatmentOption(
    'Tax Deductor',
    'Departments of the State/Central government, governmental agencies or '
        'local authorities',
  ),
  _GstTreatmentOption(
    'SEZ Developer',
    'A person/organisation who owns at least 26% of the equity in creating '
        'business units in a Special Economic Zone (SEZ)',
  ),
  _GstTreatmentOption(
    'Input Service Distributor',
    'Input Service Distributor (ISD) is an office that receives tax invoices '
        'for services used by the company in different states under the same PAN.',
  ),
];
