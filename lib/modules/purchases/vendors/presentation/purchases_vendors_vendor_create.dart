import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/modules/sales/services/gstin_lookup_service.dart';
import 'package:zerpai_erp/modules/sales/models/gstin_lookup_model.dart';
import 'package:zerpai_erp/shared/services/lookup_service.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_payment_terms_dialog.dart';
import 'package:flutter/services.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';
import 'package:zerpai_erp/shared/mixins/licence_validation_mixin.dart';
import 'package:zerpai_erp/shared/widgets/inputs/gstin_prefill_banner.dart';
import 'package:zerpai_erp/shared/widgets/inputs/phone_input_field.dart';

part 'sections/purchases_vendors_builders.dart';
part 'sections/purchases_vendors_primary_info_section.dart';
part 'sections/purchases_vendors_other_details_section.dart';
part 'sections/purchases_vendors_address_section.dart';
part 'sections/purchases_vendors_contact_persons_section.dart';
part 'sections/purchases_vendors_bank_details_section.dart';
part 'sections/purchases_vendors_license_section.dart';
part 'sections/purchases_vendors_remarks_section.dart';
part 'sections/purchases_vendors_helpers.dart';
part 'sections/purchases_vendors_dialogs.dart';

class PurchasesVendorsVendorCreateScreen extends ConsumerStatefulWidget {
  final bool showLayout;
  final bool showPrefillBanner;
  final void Function(Vendor)? onSaveSuccess;

  const PurchasesVendorsVendorCreateScreen({
    super.key,
    this.showLayout = true,
    this.showPrefillBanner = true,
    this.onSaveSuccess,
  });

  @override
  ConsumerState<PurchasesVendorsVendorCreateScreen> createState() =>
      _PurchasesVendorsVendorCreateScreenState();
}

class _PurchasesVendorsVendorCreateScreenState
    extends ConsumerState<PurchasesVendorsVendorCreateScreen>
    with
        TickerProviderStateMixin,
        LicenceValidationMixin<PurchasesVendorsVendorCreateScreen> {

  // LicenceValidationMixin: map local names to mixin contract
  @override
  TextEditingController get msmeCtrl => _msmeRegistrationNumberCtrl;
  @override
  bool get isMsmeRegistered => _isMsmeRegistered;
  late TabController _tabController;
  late final ScrollController _tabScrollController = ScrollController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  // ignore: unused_field
  List<String> _phoneCodesList = [];
  // ignore: unused_field
  Map<String, String> _phoneCodeToLabel = {};

  // Layout Constants
  final double _labelWidth = 220.0;
  final double _fieldWidth = 480.0;
  final double _inputHeight = 32.0;
  final double _fieldSpacing = 24.0;

  static const String _whatsappSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><path fill="#1af43e" d="M380.9 97.1c-41.9-42-97.7-65.1-157-65.1-122.4 0-222 99.6-222 222 0 39.1 10.2 77.3 29.6 111L0 480 117.7 449.1c32.4 17.7 68.9 27 106.1 27l.1 0c122.3 0 224.1-99.6 224.1-222 0-59.3-25.2-115-67.1-157zm-157 341.6c-33.2 0-65.7-8.9-94-25.7l-6.7-4-69.8 18.3 18.6-68.1-4.4-7c-18.5-29.4-28.2-63.3-28.2-98.2 0-101.7 82.8-184.5 184.6-184.5 49.3 0 95.6 19.2 130.4 54.1s56.2 81.2 56.1 130.5c0 101.8-84.9 184.6-186.6 184.6zM325.1 300.5c-5.5-2.8-32.8-16.2-37.9-18-5.1-1.9-8.8-2.8-12.5 2.8s-14.3 18-17.6 21.8c-3.2 3.7-6.5 4.2-12 1.4-32.6-16.3-54-29.1-75.5-66-5.7-9.8 5.7-9.1 16.3-30.3 1.8-3.7 .9-6.9-.5-9.7s-12.5-30.1-17.1-41.2c-4.5-10.8-9.1-9.3-12.5-9.5-3.2-.2-6.9-.2-10.6-.2s-9.7 1.4-14.8 6.9c-5.1 5.6-19.4 19-19.4 46.3s19.9 53.7 22.6 57.4c2.8 3.7 39.1 59.7 94.8 83.8 35.2 15.2 49 16.5 66.6 13.9 10.7-1.6 32.8-13.4 37.4-26.4s4.6-24.1 3.2-26.4c-1.3-2.5-5-3.9-10.5-6.6z"/></svg>''';
  static const String _facebookSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><path fill="#2a70ea" d="M512 256C512 114.6 397.4 0 256 0S0 114.6 0 256C0 376 82.7 476.8 194.2 504.5l0-170.3-52.8 0 0-78.2 52.8 0 0-33.7c0-87.1 39.4-127.5 125-127.5 16.2 0 44.2 3.2 55.7 6.4l0 70.8c-6-.6-16.5-1-29.6-1-42 0-58.2 15.9-58.2 57.2l0 27.8 83.6 0-14.4 78.2-69.3 0 0 175.9C413.8 494.8 512 386.9 512 256z"/></svg>''';
  static const String _xSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512"><path fill="#010409" d="M357.2 48L427.8 48 273.6 224.2 455 464 313 464 201.7 318.6 74.5 464 3.8 464 168.7 275.5-5.2 48 140.4 48 240.9 180.9 357.2 48zM332.4 421.8l39.1 0-252.4-333.8-42 0 255.3 333.8z"/></svg>''';

  // Primary Info Controllers
  final _displayNameCtrl = TextEditingController();
  final _vendorNumberCtrl = TextEditingController();
  final _vendorNumberPrefixCtrl = TextEditingController();
  final _vendorNumberNextCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _workPhoneCtrl = TextEditingController();
  final _mobilePhoneCtrl = TextEditingController();
  String _salutation = 'Mr.';
  String _vendorLanguage = 'English';

  // Other Details Controllers & State
  final _panCtrl = TextEditingController();
  final _gstinPrefillCtrl = TextEditingController();

  // Additional details
  final _websiteUrlCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _xHandleCtrl = TextEditingController();
  final _skypeCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  bool _showMoreDetails = false;

  _GstTreatmentOption? _gstTreatment;
  String? _sourceOfSupply;
  bool _isMsmeRegistered = false;
  String? _msmeRegistrationType;
  final _msmeRegistrationNumberCtrl = TextEditingController();
  CurrencyOption _currency = const CurrencyOption(
    code: 'INR',
    name: 'Indian Rupee',
    symbol: '₹',
    decimals: 2,
    format: '1,234,567.89',
    label: 'INR - Indian Rupee',
  );
  List<CurrencyOption> _localCurrencyOptions = [];
  String? _paymentTerms;
  List<Map<String, dynamic>> _paymentTermsList = [];
  String? _tdsRateId;
  List<Map<String, dynamic>> _tdsRatesList = [];
  String? _priceListId;
  List<Map<String, dynamic>> _priceListsList = [];
  bool _enablePortal = false;
  final List<PlatformFile> _attachedFiles = [];
  final LayerLink _attachedFilesLink = LayerLink();
  OverlayEntry? _attachedFilesOverlayEntry;
  bool _isUploadHovered = false;

  // License Details
  bool isDrugRegistered = false;
  String? drugLicenceType;
  final drugLicense20Ctrl = TextEditingController();
  final drugLicense21Ctrl = TextEditingController();
  final drugLicense20BCtrl = TextEditingController();
  final drugLicense21BCtrl = TextEditingController();

  final drugLicense20Focus = FocusNode();
  final drugLicense21Focus = FocusNode();
  final drugLicense20BFocus = FocusNode();
  final drugLicense21BFocus = FocusNode();

  List<PlatformFile> drugLicense20Docs = [];
  List<PlatformFile> drugLicense21Docs = [];
  List<PlatformFile> drugLicense20BDocs = [];
  List<PlatformFile> drugLicense21BDocs = [];

  bool isFssaiRegistered = false;
  final fssaiCtrl = TextEditingController();
  final fssaiFocus = FocusNode();
  List<PlatformFile> fssaiDocs = [];

  // MSME state
  List<PlatformFile> msmeDocs = [];
  final msmeFocus = FocusNode();

  // Address Controllers
  final _billingAttentionCtrl = TextEditingController();
  final _billingStreet1Ctrl = TextEditingController();
  final _billingStreet2Ctrl = TextEditingController();
  final _billingCityCtrl = TextEditingController();
  final _billingPinCtrl = TextEditingController();
  final _billingPhoneCtrl = TextEditingController();
  final _billingFaxCtrl = TextEditingController();
  String? _billingCountry = 'India';
  String? _billingState;
  String _billingPhoneCode = '+91';

  final _shippingAttentionCtrl = TextEditingController();
  final _shippingStreet1Ctrl = TextEditingController();
  final _shippingStreet2Ctrl = TextEditingController();
  final _shippingCityCtrl = TextEditingController();
  final _shippingPinCtrl = TextEditingController();
  final _shippingPhoneCtrl = TextEditingController();
  final _shippingFaxCtrl = TextEditingController();
  String? _shippingCountry = 'India';
  String? _shippingState;
  String _shippingPhoneCode = '+91';
  String _workPhoneCode = '+91';
  String _mobilePhoneCode = '+91';
  List<String> _sourceOfSupplyList = _initialSourceOfSupplyOptions;

  // Contact Persons
  final List<_ContactPersonRow> contactRows = [];
  List<String> _displayNameOptions = [];

  // Bank Details
  final List<_BankDetailRow> bankRows = [];

  // Services
  late final GstinLookupService _gstinLookupService = GstinLookupService();
  bool isGSTINLoading = false;

  void _state(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _fetchNextVendorNumber();
    _tabController = TabController(length: 8, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    contactRows.add(_ContactPersonRow());
    _refreshDisplayNameOptions();
    _loadPaymentTerms();
    _loadTdsRates();
    _loadPriceLists();
    _loadCountries(); // Load phone codes from DB
    _loadSourceOfSupply(); // Load Indian states for Source of Supply
    _localCurrencyOptions = List.from(defaultCurrencyOptions);

    initLicenceValidation();
  }

  Future<void> _fetchNextVendorNumber() async {
    try {
      final lookupsService = LookupsApiService();
      final nextNumber = await lookupsService.getNextSequence('vendor');
      if (nextNumber != null && mounted) {
        setState(() {
          _vendorNumberCtrl.text = nextNumber;
        });
      }
    } catch (e) {
      AppLogger.error('Error fetching next vendor number', error: e, module: 'purchases');
    }
  }

  Future<void> _loadPaymentTerms() async {
    try {
      final lookupsService = LookupsApiService();
      final terms = await lookupsService.getPaymentTerms();
      if (mounted) {
        setState(() {
          _paymentTermsList = terms;
          if (terms.isNotEmpty) {
            // Set default to Net 30 if available
            final net30 = terms.firstWhere(
              (t) => t['term_name'] == 'Net 30',
              orElse: () => terms.first,
            );
            _paymentTerms = net30['id'];
          }
        });
      }
    } catch (e) {
      AppLogger.error('Error loading payment terms', error: e, module: 'purchases');
    }
  }

  Future<void> _loadTdsRates() async {
    try {
      final lookupsService = LookupsApiService();
      final rates = await lookupsService.getTdsRates();
      if (mounted) {
        setState(() {
          _tdsRatesList = rates;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading TDS rates', error: e, module: 'purchases');
    }
  }

  Future<void> _loadPriceLists() async {
    try {
      final lookupsService = LookupsApiService();
      final priceLists = await lookupsService.getPriceLists();
      if (mounted) {
        setState(() {
          _priceListsList = priceLists;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading price lists', error: e, module: 'purchases');
    }
  }

  Future<void> _loadCountries() async {
    try {
      final lookupsService = LookupsApiService();
      final countries = await lookupsService.getCountries();
      if (mounted) {
        setState(() {
          final codes = countries
              .map((c) => c['phone_code']?.toString())
              .where((c) => c != null && c.isNotEmpty)
              .cast<String>()
              .toSet() // Remove duplicates
              .toList();

          if (codes.isNotEmpty) {
            // Sort to keep common ones at top or just alphabetical
            codes.sort((a, b) {
              if (a == '+91') return -1;
              if (b == '+91') return 1;
              return a.compareTo(b);
            });
            _phoneCodesList = codes;
          }

          // Build labels map (Store only the country name for the dropdown list)
          final labels = <String, String>{};
          for (var c in countries) {
            final code = c['phone_code']?.toString();
            final name = c['name']?.toString();
            if (code != null && name != null) {
              labels[code] = name;
            }
          }
          _phoneCodeToLabel = labels;

          // Set India as default country
          final india = countries.firstWhere(
            (c) => c['name']?.toString().toLowerCase() == 'india',
            orElse: () => {},
          );
          if (india.isNotEmpty) {
            _billingCountry ??= india['name']?.toString();
            _shippingCountry ??= india['name']?.toString();
          }
        });
      }
    } catch (e) {
      AppLogger.error('Error loading countries/phone codes', error: e, module: 'purchases');
    }
  }

  Future<void> _loadSourceOfSupply() async {
    try {
      final lookupsService = LookupsApiService();
      final states = await lookupsService.getStates('IN'); // India
      if (mounted && states.isNotEmpty) {
        setState(() {
          _sourceOfSupplyList = states.map((s) {
            final code = s['code']?.toString() ?? '';
            final name = s['name']?.toString() ?? '';
            return '[$code] - $name';
          }).toList();
        });
      }
    } catch (e) {
      AppLogger.error('Error loading source of supply states', error: e, module: 'purchases');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tabScrollController.dispose();
    _removeAttachedFilesOverlay();
    _displayNameCtrl.dispose();
    _vendorNumberCtrl.dispose();
    _vendorNumberPrefixCtrl.dispose();
    _vendorNumberNextCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _companyNameCtrl.dispose();
    _emailCtrl.dispose();
    _workPhoneCtrl.dispose();
    _mobilePhoneCtrl.dispose();
    _panCtrl.dispose();
    _gstinPrefillCtrl.dispose();
    _websiteUrlCtrl.dispose();
    _departmentCtrl.dispose();
    _designationCtrl.dispose();
    _whatsappCtrl.dispose();
    _facebookCtrl.dispose();
    _xHandleCtrl.dispose();
    _skypeCtrl.dispose();
    _msmeRegistrationNumberCtrl.dispose();

    // License Controllers
    drugLicense20Ctrl.dispose();
    drugLicense21Ctrl.dispose();
    drugLicense20BCtrl.dispose();
    drugLicense21BCtrl.dispose();
    fssaiCtrl.dispose();
    disposeLicenceNodes();
    for (var row in bankRows) {
      row.dispose();
    }
    _billingAttentionCtrl.dispose();
    _billingStreet1Ctrl.dispose();
    _billingStreet2Ctrl.dispose();
    _billingCityCtrl.dispose();
    _billingPinCtrl.dispose();
    _billingPhoneCtrl.dispose();
    _billingFaxCtrl.dispose();
    _shippingAttentionCtrl.dispose();
    _shippingStreet1Ctrl.dispose();
    _shippingStreet2Ctrl.dispose();
    _shippingCityCtrl.dispose();
    _shippingPinCtrl.dispose();
    _shippingPhoneCtrl.dispose();
    _shippingFaxCtrl.dispose();
    for (var row in contactRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      final vendor = Vendor(
        id: '',
        displayName: _displayNameCtrl.text.trim(),
        vendorNumber: _vendorNumberCtrl.text.trim(),
        salutation: _salutation,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        companyName: _companyNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: '${_workPhoneCode} ${_workPhoneCtrl.text.trim()}',
        mobilePhone: '${_mobilePhoneCode} ${_mobilePhoneCtrl.text.trim()}',
        gstTreatment: _gstTreatment?.label,
        gstin: _gstinPrefillCtrl.text.trim(),
        sourceOfSupply: _sourceOfSupply,
        pan: _panCtrl.text.trim(),
        currency: _currency.code,

        paymentTerms: _paymentTerms,
        website: _websiteUrlCtrl.text.trim(),
        department: _departmentCtrl.text.trim(),
        designation: _designationCtrl.text.trim(),
        vendorLanguage: _vendorLanguage,
        isMsmeRegistered: _isMsmeRegistered,
        msmeRegistrationType: _msmeRegistrationType,
        msmeRegistrationNumber: _msmeRegistrationNumberCtrl.text.trim(),
        isDrugRegistered: isDrugRegistered,
        drugLicenceType: drugLicenceType,
        drugLicense20: drugLicense20Ctrl.text.trim(),
        drugLicense21: drugLicense21Ctrl.text.trim(),
        drugLicense20b: drugLicense20BCtrl.text.trim(),
        drugLicense21b: drugLicense21BCtrl.text.trim(),
        isFssaiRegistered: isFssaiRegistered,
        fssaiNumber: fssaiCtrl.text.trim(),
        tdsRateId: _tdsRateId,
        priceListId: _priceListId,
        enablePortal: _enablePortal,
        billingAddress: {
          'attention': _billingAttentionCtrl.text.trim(),
          'street1': _billingStreet1Ctrl.text.trim(),
          'street2': _billingStreet2Ctrl.text.trim(),
          'city': _billingCityCtrl.text.trim(),
          'state': _billingState ?? '',
          'zip': _billingPinCtrl.text.trim(),
          'country': _billingCountry ?? '',
          'phone': '${_billingPhoneCode} ${_billingPhoneCtrl.text.trim()}',
          'phoneCode': _billingPhoneCode,
        },
        shippingAddress: {
          'attention': _shippingAttentionCtrl.text.trim(),
          'street1': _shippingStreet1Ctrl.text.trim(),
          'street2': _shippingStreet2Ctrl.text.trim(),
          'city': _shippingCityCtrl.text.trim(),
          'state': _shippingState ?? '',
          'zip': _shippingPinCtrl.text.trim(),
          'country': _shippingCountry ?? '',
          'phone': '${_shippingPhoneCode} ${_shippingPhoneCtrl.text.trim()}',
          'phoneCode': _shippingPhoneCode,
        },
        contactPersons: contactRows
            .map(
              (r) => {
                'salutation': r.salutation,
                'firstName': r.firstNameCtrl.text.trim(),
                'lastName': r.lastNameCtrl.text.trim(),
                'email': r.emailCtrl.text.trim(),
                'workCode': r.workCode,
                'workPhone': '${r.workCode} ${r.workPhoneCtrl.text.trim()}',
                'mobileCode': r.mobileCode,
                'mobilePhone':
                    '${r.mobileCode} ${r.mobilePhoneCtrl.text.trim()}',
              },
            )
            .toList(),
        bankDetails: bankRows
            .map(
              (r) => {
                'holderName': r.holderNameCtrl.text.trim(),
                'bankName': r.bankNameCtrl.text.trim(),
                'accountNumber': r.accountNumberCtrl.text.trim(),
                'ifsc': r.ifscCtrl.text.trim(),
              },
            )
            .toList(),
        remarks: _remarksCtrl.text.trim(),
        xHandle: _xHandleCtrl.text.trim(),
        facebookHandle: _facebookCtrl.text.trim(),
        whatsappNumber: _whatsappCtrl.text.trim(),
      );

      try {
        // 1. Double check for duplicate vendor number before creating
        final String currentNumber = _vendorNumberCtrl.text.trim();
        final bool isDuplicate = await LookupsApiService().checkDuplicateNumber(
          'vendor',
          currentNumber,
        );

        if (isDuplicate) {
          // AUTOMATIC CONCURRENCY HANDLING: Retrieve the next available number silently.
          final nextFormatted = await LookupsApiService().getNextSequence(
            'vendor',
          );
          if (nextFormatted != null) {
            _vendorNumberCtrl.text = nextFormatted;
          }
        }

        // Use the potentially updated number
        final finalVendorNumber = _vendorNumberCtrl.text.trim();
        final updatedVendor = vendor.copyWith(vendorNumber: finalVendorNumber);

        // 2. Create the vendor
        final createdVendor = await ref.read(vendorProvider.notifier).createVendor(updatedVendor);

        if (mounted) {
          ZerpaiToast.success(context, 'Vendor created successfully');

          if (widget.onSaveSuccess != null) {
            widget.onSaveSuccess!(createdVendor);
            return;
          }

          // 3. Inform backend to increment sequence
          try {
            await LookupsApiService().incrementSequence(
              'vendor',
              usedNumber: finalVendorNumber,
            );
          } catch (e) {
            AppLogger.warning('Failed to increment vendor sequence', error: e, module: 'purchases');
          }

          // 4. RESET FORM & FETCH NEXT NUMBER (Stay on page)
          _resetForm();
          _fetchNextVendorNumber();
        }
      } catch (e) {
        if (mounted) {
          ZerpaiToast.error(context, 'Error: $e');
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      // Clear Text Controllers
      _displayNameCtrl.clear();
      _firstNameCtrl.clear();
      _lastNameCtrl.clear();
      _companyNameCtrl.clear();
      _emailCtrl.clear();
      _workPhoneCtrl.clear();
      _mobilePhoneCtrl.clear();
      _panCtrl.clear();
      _gstinPrefillCtrl.clear();
      _websiteUrlCtrl.clear();
      _departmentCtrl.clear();
      _designationCtrl.clear();
      _whatsappCtrl.clear();
      _facebookCtrl.clear();
      _xHandleCtrl.clear();
      _skypeCtrl.clear();
      _remarksCtrl.clear();
      _msmeRegistrationNumberCtrl.clear();
      drugLicense20Ctrl.clear();
      drugLicense21Ctrl.clear();
      drugLicense20BCtrl.clear();
      drugLicense21BCtrl.clear();
      fssaiCtrl.clear();
      _billingAttentionCtrl.clear();
      _billingStreet1Ctrl.clear();
      _billingStreet2Ctrl.clear();
      _billingCityCtrl.clear();
      _billingPinCtrl.clear();
      _billingPhoneCtrl.clear();
      _billingFaxCtrl.clear();
      _shippingAttentionCtrl.clear();
      _shippingStreet1Ctrl.clear();
      _shippingStreet2Ctrl.clear();
      _shippingCityCtrl.clear();
      _shippingPinCtrl.clear();
      _shippingPhoneCtrl.clear();
      _shippingFaxCtrl.clear();

      // Reset Collections to defaults
      _displayNameOptions = [];
      _attachedFiles.clear();
      // Contact Persons: reset to one empty row
      contactRows.clear();
      contactRows.add(_ContactPersonRow());
      // Bank Details: clear all
      bankRows.clear();

      // License Files
      drugLicense20Docs.clear();
      drugLicense21Docs.clear();
      drugLicense20BDocs.clear();
      drugLicense21BDocs.clear();
      fssaiDocs.clear();
      msmeDocs.clear();

      // Reset Booleans & Dropdowns
      _salutation = 'Mr.';
      _gstTreatment = null; // or reset to default if desired
      _sourceOfSupply = null;
      _isMsmeRegistered = false;
      _msmeRegistrationType = null;
      isDrugRegistered = false;
      drugLicenceType = null;
      isFssaiRegistered = false;

      // Keep: _vendorLanguage, _currency, phone/mobile codes, state/country selections
      // Reset Tab
      _tabController.animateTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showPrefillBanner) _buildPrefillBanner(),
            if (widget.showPrefillBanner) const SizedBox(height: 32),
            _buildPrimaryInfo(),
            const SizedBox(height: 32),
            _buildTabSection(),
          ],
        ),
      ),
    );

    if (!widget.showLayout) {
      return Material(
        color: Colors.white,
        child: Column(
          children: [
            _buildDialogHeader(),
            const Divider(height: 1),
            Expanded(child: SingleChildScrollView(child: content)),
            _buildFooter(),
          ],
        ),
      );
    }

    return ZerpaiLayout(
      pageTitle: 'New Vendor',
      enableBodyScroll: true,
      footer: _buildFooter(),
      child: content,
    );
  }

  Widget _buildDialogHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'New Vendor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.x, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPrefillBanner() =>
      GstinPrefillBanner(entityLabel: 'Vendor', onPrefill: _openGstinPrefillDialog);

  Widget _buildTabSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Scrollbar(
            controller: _tabScrollController,
            thumbVisibility: true,
            interactive: true,
            thickness: 6,
            radius: const Radius.circular(3),
            child: SingleChildScrollView(
              controller: _tabScrollController,
              scrollDirection: Axis.horizontal,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: const Color(0xFF6B7280),
                indicatorColor: const Color(0xFF2563EB),
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.label,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Other Details'),
                  Tab(text: 'License Details'),
                  Tab(text: 'Address'),
                  Tab(text: 'Contact Persons'),
                  Tab(text: 'Bank Details'),
                  Tab(text: 'Custom Fields'),
                  Tab(text: 'Reporting Tags'),
                  Tab(text: 'Remarks'),
                ],
              ),
            ),
          ),
        ),
        _buildTabContent(_tabController.index),
      ],
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return _buildOtherDetails();
      case 1:
        return _buildLicenseSection();
      case 2:
        return _buildAddressSection();
      case 3:
        return _buildContactPersons();
      case 4:
        return _buildBankDetails();
      case 5:
        return _buildCustomFields();
      case 6:
        return _buildReportingTags();
      case 7:
        return _buildRemarks();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: isLoading ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.purchasesVendors);
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _ContactPersonRow {
  String salutation = 'Mr.';
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  String workCode = '+91';
  final workPhoneCtrl = TextEditingController();
  String mobileCode = '+91';
  final mobilePhoneCtrl = TextEditingController();
  bool isHovered = false;

  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    workPhoneCtrl.dispose();
    mobilePhoneCtrl.dispose();
  }
}

class _BankDetailRow {
  final holderNameCtrl = TextEditingController();
  final bankNameCtrl = TextEditingController();
  final accountNumberCtrl = TextEditingController();
  final reEnterAccountNumberCtrl = TextEditingController();
  final ifscCtrl = TextEditingController();
  bool showAccountNumber = false;
  bool showReEnterAccountNumber = false;

  void dispose() {
    holderNameCtrl.dispose();
    bankNameCtrl.dispose();
    accountNumberCtrl.dispose();
    reEnterAccountNumberCtrl.dispose();
    ifscCtrl.dispose();
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
];

const List<String> _initialSourceOfSupplyOptions = [
  '[AN] - Andaman and Nicobar Islands',
  '[AD] - Andhra Pradesh',
  '[AR] - Arunachal Pradesh',
  '[AS] - Assam',
  '[BR] - Bihar',
  '[CH] - Chandigarh',
  '[CG] - Chhattisgarh',
  '[DN] - Dadra and Nagar Haveli and Daman and Diu',
  '[DL] - Delhi',
  '[GA] - Goa',
  '[GJ] - Gujarat',
  '[HR] - Haryana',
  '[HP] - Himachal Pradesh',
  '[JK] - Jammu and Kashmir',
  '[JH] - Jharkhand',
  '[KA] - Karnataka',
  '[KL] - Kerala',
  '[LA] - Ladakh',
  '[LD] - Lakshadweep',
  '[MP] - Madhya Pradesh',
  '[MH] - Maharashtra',
  '[MN] - Manipur',
  '[ML] - Meghalaya',
  '[MZ] - Mizoram',
  '[NL] - Nagaland',
  '[OD] - Odisha',
  '[PY] - Puducherry',
  '[PB] - Punjab',
  '[RJ] - Rajasthan',
  '[SK] - Sikkim',
  '[TN] - Tamil Nadu',
  '[TS] - Telangana',
  '[TR] - Tripura',
  '[UP] - Uttar Pradesh',
  '[UK] - Uttarakhand',
  '[WB] - West Bengal',
];
