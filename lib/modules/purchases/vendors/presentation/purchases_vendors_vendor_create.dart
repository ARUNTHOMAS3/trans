import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:zerpai_erp/shared/constants/phone_prefixes.dart';
import 'package:flutter/services.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';

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
  const PurchasesVendorsVendorCreateScreen({super.key});

  @override
  ConsumerState<PurchasesVendorsVendorCreateScreen> createState() =>
      _PurchasesVendorsVendorCreateScreenState();
}

class _PurchasesVendorsVendorCreateScreenState
    extends ConsumerState<PurchasesVendorsVendorCreateScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // Layout Constants
  final double _labelWidth = 180.0;
  final double _fieldWidth = 480.0;
  final double _inputHeight = 36.0;
  final double _fieldSpacing = 24.0;

  static const String _whatsappSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640"><path fill="rgba(61, 255, 2, 1.00)" d="M476.9 161.1C435 119.1 379.2 96 319.9 96C197.5 96 97.9 195.6 97.9 318C97.9 357.1 108.1 395.3 127.5 429L96 544L213.7 513.1C246.1 530.8 282.6 540.1 319.8 540.1L319.9 540.1C442.2 540.1 544 440.5 544 318.1C544 258.8 518.8 203.1 476.9 161.1zM319.9 502.7C286.7 502.7 254.2 493.8 225.9 477L219.2 473L149.4 491.3L168 423.2L163.6 416.2C145.1 386.8 135.4 352.9 135.4 318C135.4 216.3 218.2 133.5 320 133.5C369.3 133.5 415.6 152.7 450.4 187.6C485.2 222.5 506.6 268.8 506.5 318.1C506.5 419.9 421.6 502.7 319.9 502.7zM421.1 364.5C415.6 361.7 388.3 348.3 383.2 346.5C378.1 344.6 374.4 343.7 370.7 349.3C367 354.9 356.4 367.3 353.1 371.1C349.9 374.8 346.6 375.3 341.1 372.5C308.5 356.2 287.1 343.4 265.6 306.5C259.9 296.7 271.3 297.4 281.9 276.2C283.7 272.5 282.8 269.3 281.4 266.5C280 263.7 268.9 236.4 264.3 225.3C259.8 214.5 255.2 216 251.8 215.8C248.6 215.6 244.9 215.6 241.2 215.6C237.5 215.6 231.5 217 226.4 222.5C221.3 228.1 207 241.5 207 268.8C207 296.1 226.9 322.5 229.6 326.2C232.4 329.9 268.7 385.9 324.4 410C359.6 425.2 373.4 426.5 391 423.9C401.7 422.3 423.8 410.5 428.4 397.5C433 384.5 433 373.4 431.6 371.1C430.3 368.6 426.6 367.2 421.1 364.5z"/></svg>';
  static const String _facebookSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640"><path fill="rgba(30, 21, 207, 1.00)" d="M576 320C576 178.6 461.4 64 320 64C178.6 64 64 178.6 64 320C64 440 146.7 540.8 258.2 568.5L258.2 398.2L205.4 398.2L205.4 320L258.2 320L258.2 286.3C258.2 199.2 297.6 158.8 383.2 158.8C399.4 158.8 427.4 162 438.9 165.2L438.9 236C432.9 235.4 422.4 235 409.3 235C367.3 235 351.1 250.9 351.1 292.2L351.1 320L434.7 320L420.3 398.2L351 398.2L351 574.1C477.8 558.8 576 450.9 576 320z"/></svg>';
  static const String _xSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640"><path d="M453.2 112L523.8 112L369.6 288.2L551 528L409 528L297.7 382.6L170.5 528L99.8 528L264.7 339.5L90.8 112L236.4 112L336.9 244.9L453.2 112zM428.4 485.8L467.5 485.8L215.1 152L173.1 152L428.4 485.8z"/></svg>';

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
  bool _isDirty = false;

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

  String? drugLicense20Error;
  String? drugLicense21Error;
  String? drugLicense20BError;
  String? drugLicense21BError;

  final List<PlatformFile> drugLicense20Docs = [];
  final List<PlatformFile> drugLicense21Docs = [];
  final List<PlatformFile> drugLicense20BDocs = [];
  final List<PlatformFile> drugLicense21BDocs = [];

  final LayerLink drugLicense20Link = LayerLink();
  final LayerLink drugLicense21Link = LayerLink();
  final LayerLink drugLicense20BLink = LayerLink();
  final LayerLink drugLicense21BLink = LayerLink();

  bool isFssaiRegistered = false;
  final fssaiCtrl = TextEditingController();
  final fssaiFocus = FocusNode();
  String? fssaiError;
  final List<PlatformFile> fssaiDocs = [];
  final LayerLink fssaiLink = LayerLink();

  // MSME state (reusing/aligning with your snippet)
  // _isMsmeRegistered already exists at line 84
  // _msmeRegistrationType exists at 85
  // _msmeRegistrationNumberCtrl exists at 86
  final List<PlatformFile> msmeDocs = [];
  final msmeLink = LayerLink();
  final msmeFocus = FocusNode();
  String? msmeError;

  OverlayEntry? _licenseOverlayEntry;
  String? _activeLicenseField;

  // Address Controllers
  final _billingAttentionCtrl = TextEditingController();
  final _billingStreet1Ctrl = TextEditingController();
  final _billingStreet2Ctrl = TextEditingController();
  final _billingCityCtrl = TextEditingController();
  final _billingPinCtrl = TextEditingController();
  final _billingPhoneCtrl = TextEditingController();
  final _billingFaxCtrl = TextEditingController();
  String? _billingCountry;
  String? _billingState;
  String _billingPhoneCode = '+91';

  final _shippingAttentionCtrl = TextEditingController();
  final _shippingStreet1Ctrl = TextEditingController();
  final _shippingStreet2Ctrl = TextEditingController();
  final _shippingCityCtrl = TextEditingController();
  final _shippingPinCtrl = TextEditingController();
  final _shippingPhoneCtrl = TextEditingController();
  final _shippingFaxCtrl = TextEditingController();
  String? _shippingCountry;
  String? _shippingState;
  String _shippingPhoneCode = '+91';
  List<String> _phoneCodesList = [
    '+91',
    '+1',
    '+44',
    '+971',
  ]; // Initial defaults
  Map<String, String> _phoneCodeToLabel = {}; // From DB
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

    // License Focus Listeners
    drugLicense20Focus.addListener(
      () => _onLicenseFocusChange('drugLicense20'),
    );
    drugLicense21Focus.addListener(
      () => _onLicenseFocusChange('drugLicense21'),
    );
    drugLicense20BFocus.addListener(
      () => _onLicenseFocusChange('drugLicense20B'),
    );
    drugLicense21BFocus.addListener(
      () => _onLicenseFocusChange('drugLicense21B'),
    );
    fssaiFocus.addListener(() => _onLicenseFocusChange('fssai'));
    msmeFocus.addListener(() => _onLicenseFocusChange('msme'));
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
      debugPrint('❌ Error fetching next vendor number: $e');
    }
  }

  Future<void> _loadPaymentTerms() async {
    try {
      debugPrint('🔍 Loading payment terms...');
      final lookupsService = LookupsApiService();
      final terms = await lookupsService.getPaymentTerms();
      debugPrint('🔍 Loaded ${terms.length} payment terms');
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
            debugPrint('🔍 Default payment term set to: $_paymentTerms');
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading payment terms: $e');
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
      debugPrint('❌ Error loading TDS rates: $e');
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
      debugPrint('❌ Error loading Price Lists: $e');
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
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading countries/phone codes: $e');
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
      debugPrint('❌ Error loading source of supply states: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    drugLicense20Focus.dispose();
    drugLicense21Focus.dispose();
    drugLicense20BFocus.dispose();
    drugLicense21BFocus.dispose();
    fssaiFocus.dispose();
    msmeFocus.dispose();
    _removeLicenseOverlay();
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

  Future<void> _pickLicenseDocument(String field) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      _state(() {
        switch (field) {
          case 'drugLicense20':
            drugLicense20Docs.addAll(result.files);
            break;
          case 'drugLicense21':
            drugLicense21Docs.addAll(result.files);
            break;
          case 'drugLicense20B':
            drugLicense20BDocs.addAll(result.files);
            break;
          case 'drugLicense21B':
            drugLicense21BDocs.addAll(result.files);
            break;
          case 'fssai':
            fssaiDocs.addAll(result.files);
            break;
          case 'msme':
            msmeDocs.addAll(result.files);
            break;
        }
      });
    }
  }

  void _removeLicenseDocument(String field, {int? index}) {
    _state(() {
      switch (field) {
        case 'drugLicense20':
          if (index != null) {
            if (index >= 0 && index < drugLicense20Docs.length) {
              drugLicense20Docs.removeAt(index);
            }
          } else {
            drugLicense20Docs.clear();
          }
          break;
        case 'drugLicense21':
          if (index != null) {
            if (index >= 0 && index < drugLicense21Docs.length) {
              drugLicense21Docs.removeAt(index);
            }
          } else {
            drugLicense21Docs.clear();
          }
          break;
        case 'drugLicense20B':
          if (index != null) {
            if (index >= 0 && index < drugLicense20BDocs.length) {
              drugLicense20BDocs.removeAt(index);
            }
          } else {
            drugLicense20BDocs.clear();
          }
          break;
        case 'drugLicense21B':
          if (index != null) {
            if (index >= 0 && index < drugLicense21BDocs.length) {
              drugLicense21BDocs.removeAt(index);
            }
          } else {
            drugLicense21BDocs.clear();
          }
          break;
        case 'fssai':
          if (index != null) {
            if (index >= 0 && index < fssaiDocs.length) {
              fssaiDocs.removeAt(index);
            }
          } else {
            fssaiDocs.clear();
          }
          break;
        case 'msme':
          if (index != null) {
            if (index >= 0 && index < msmeDocs.length) {
              msmeDocs.removeAt(index);
            }
          } else {
            msmeDocs.clear();
          }
          break;
      }

      // Update or close overlay if empty
      final list = _getLicenseFilesList(field);
      if (list.isEmpty) {
        _removeLicenseOverlay();
      } else {
        _licenseOverlayEntry?.markNeedsBuild();
      }
    });
  }

  void _onLicenseFocusChange(String field) {
    final focusNode = _getLicenseFocusNode(field);
    if (!focusNode.hasFocus) {
      _validateLicenseField(field);
    }
  }

  FocusNode _getLicenseFocusNode(String field) {
    switch (field) {
      case 'drugLicense20':
        return drugLicense20Focus;
      case 'drugLicense21':
        return drugLicense21Focus;
      case 'drugLicense20B':
        return drugLicense20BFocus;
      case 'drugLicense21B':
        return drugLicense21BFocus;
      case 'fssai':
        return fssaiFocus;
      case 'msme':
        return msmeFocus;
      default:
        return FocusNode();
    }
  }

  void _validateLicenseField(String field) {
    setState(() {
      switch (field) {
        case 'drugLicense20':
          drugLicense20Error = _getLicenseErrorMessage(
            field,
            drugLicense20Ctrl.text,
          );
          break;
        case 'drugLicense21':
          drugLicense21Error = _getLicenseErrorMessage(
            field,
            drugLicense21Ctrl.text,
          );
          break;
        case 'drugLicense20B':
          drugLicense20BError = _getLicenseErrorMessage(
            field,
            drugLicense20BCtrl.text,
          );
          break;
        case 'drugLicense21B':
          drugLicense21BError = _getLicenseErrorMessage(
            field,
            drugLicense21BCtrl.text,
          );
          break;
        case 'fssai':
          fssaiError = _getLicenseErrorMessage(field, fssaiCtrl.text);
          break;
        case 'msme':
          msmeError = _getLicenseErrorMessage(
            field,
            _msmeRegistrationNumberCtrl.text,
          );
          break;
      }
    });
  }

  String? _getLicenseErrorMessage(String field, String value) {
    if (value.trim().isEmpty) {
      switch (field) {
        case 'drugLicense20':
          return 'Enter a valid Drug License 20.';
        case 'drugLicense21':
          return 'Enter a valid Drug License 21.';
        case 'drugLicense20B':
          return 'Enter a valid Drug License 20B.';
        case 'drugLicense21B':
          return 'Enter a valid Drug License 21B.';
        case 'fssai':
          return 'Enter a valid FSSAI Number.';
        case 'msme':
          return 'Enter a valid MSME/Udyam Registration Number. Ensure that the number is in the format UDYAM-XX-00-0000000.';
      }
    }
    // Add specific format validations if needed later
    return null;
  }

  List<PlatformFile> _getLicenseFilesList(String field) {
    switch (field) {
      case 'drugLicense20':
        return drugLicense20Docs;
      case 'drugLicense21':
        return drugLicense21Docs;
      case 'drugLicense20B':
        return drugLicense20BDocs;
      case 'drugLicense21B':
        return drugLicense21BDocs;
      case 'fssai':
        return fssaiDocs;
      case 'msme':
        return msmeDocs;
      default:
        return [];
    }
  }

  LayerLink _getLicenseLink(String field) {
    switch (field) {
      case 'drugLicense20':
        return drugLicense20Link;
      case 'drugLicense21':
        return drugLicense21Link;
      case 'drugLicense20B':
        return drugLicense20BLink;
      case 'drugLicense21B':
        return drugLicense21BLink;
      case 'fssai':
        return fssaiLink;
      case 'msme':
        return msmeLink;
      default:
        return LayerLink();
    }
  }

  void _toggleLicenseOverlay(String field) {
    if (_licenseOverlayEntry != null && _activeLicenseField == field) {
      _removeLicenseOverlay();
    } else {
      if (_licenseOverlayEntry != null) _removeLicenseOverlay();
      _showLicenseOverlay(field);
    }
  }

  void _showLicenseOverlay(String field) {
    if (!mounted) return;
    _activeLicenseField = field;
    final overlay = Overlay.of(context);
    _licenseOverlayEntry = OverlayEntry(
      builder: (context) => _buildLicenseOverlay(field),
    );
    overlay.insert(_licenseOverlayEntry!);
  }

  void _removeLicenseOverlay() {
    _licenseOverlayEntry?.remove();
    _licenseOverlayEntry = null;
    _activeLicenseField = null;
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
          'fax': _billingFaxCtrl.text.trim(),
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
          'fax': _shippingFaxCtrl.text.trim(),
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'The vendor number "$currentNumber" already exists. Please use a unique number.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => isLoading = false);
          }
          return;
        }

        // 2. Create the vendor
        await ref.read(vendorProvider.notifier).createVendor(vendor);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vendor created successfully')),
          );

          // 3. Inform backend to increment sequence (backend now handles the check
          // to only increment if it was the auto-generated one)
          try {
            await LookupsApiService().incrementSequence(
              'vendor',
              usedNumber: currentNumber,
            );
          } catch (e) {
            debugPrint('⚠️ Failed to increment vendor sequence: $e');
          }

          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.purchasesVendors);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  void _onCancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.purchasesVendors);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: 'New Vendor',
      enableBodyScroll: true,
      onSave: _handleSave,
      onCancel: _onCancel,
      isDirty: _isDirty,
      footer: _buildFooter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPrefillBanner(),
              const SizedBox(height: 32),
              Form(
                onChanged: () => setState(() => _isDirty = true),
                child: _buildPrimaryInfo(),
              ),
              const SizedBox(height: 32),
              _buildTabSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrefillBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Prefill Vendor details from the GST portal using the Vendor\'s GSTIN.',
              style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8)),
            ),
          ),
          InkWell(
            onTap: _openGstinPrefillDialog,
            child: const Text(
              'Prefill >',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
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
          Tooltip(
            message: 'Cancel (Esc)',
            child: OutlinedButton(
              onPressed: _onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Cancel'),
          ),
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
