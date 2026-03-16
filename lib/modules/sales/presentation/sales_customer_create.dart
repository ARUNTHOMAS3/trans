import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:intl/intl.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/modules/sales/models/gstin_lookup_model.dart';
import 'package:zerpai_erp/modules/sales/services/gstin_lookup_service.dart';
import 'package:zerpai_erp/core/constants/phone_prefixes.dart';
import '../controllers/sales_order_controller.dart';
import '../models/sales_customer_model.dart';
import '../../items/pricelist/models/pricelist_model.dart';
import '../../items/pricelist/providers/pricelist_provider.dart';
import 'package:zerpai_erp/core/services/lookup_service.dart';
import 'package:zerpai_erp/core/services/storage_service.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/core/widgets/common/skeleton.dart';

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
  const SalesCustomerCreateScreen({super.key});

  @override
  ConsumerState<SalesCustomerCreateScreen> createState() =>
      _SalesCustomerCreateScreenState();
}

class _SalesCustomerCreateScreenState
    extends ConsumerState<SalesCustomerCreateScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;

  void _state(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void initState() {
    super.initState();
    // Both Business and Individual have 7 tabs
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Rebuild to show the correct section
      }
    });

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

    // Load initial currencies
    _loadCurrencies();

    // Load price lists
    Future.microtask(() {
      ref.read(priceListNotifierProvider.notifier).fetchPriceLists();
      _loadIndiaStates();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Layout Constants (Instance members for extension access)
  final double _salutationWidth = 70.0;
  final double _primaryContactWidth = 360.0;
  final double _labelWidth = 150.0;
  final double _fieldWidth = 360.0;
  final double _inputHeight = 34.0;
  final double _fieldSpacing = 8.0;

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

  List<Map<String, String>> _indiaStates = [];
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
          _indiaStates = states;
        });
      }
    } catch (e) {
      debugPrint('Error loading India states: $e');
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
  final customerNumberCtrl = TextEditingController(text: 'CUS-00011');
  final customerNumberPrefixCtrl = TextEditingController(text: 'CUS');
  final customerNumberNextCtrl = TextEditingController(text: '00011');
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
  bool enablePortal = false;

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
  final demoFieldCtrl = TextEditingController();
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

  // File picker methods for license documents
  Future<void> _pickLicenseDocument(String licenseType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      List<PlatformFile> targetList;
      switch (licenseType) {
        case 'drugLicense20':
          targetList = drugLicense20Docs;
          break;
        case 'drugLicense21':
          targetList = drugLicense21Docs;
          break;
        case 'drugLicense20B':
          targetList = drugLicense20BDocs;
          break;
        case 'drugLicense21B':
          targetList = drugLicense21BDocs;
          break;
        case 'fssai':
          targetList = fssaiDocs;
          break;
        case 'msme':
          targetList = msmeDocs;
          break;
        default:
          return;
      }

      final remainingSlots = 5 - targetList.length;
      if (remainingSlots <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 5 files allowed')),
          );
        }
        return;
      }

      final filesToAdd = result.files.take(remainingSlots).toList();
      targetList.addAll(filesToAdd);
    });
  }

  void _removeLicenseDocument(String licenseType, PlatformFile file) {
    setState(() {
      switch (licenseType) {
        case 'drugLicense20':
          drugLicense20Docs.remove(file);
          break;
        case 'drugLicense21':
          drugLicense21Docs.remove(file);
          break;
        case 'drugLicense20B':
          drugLicense20BDocs.remove(file);
          break;
        case 'drugLicense21B':
          drugLicense21BDocs.remove(file);
          break;
        case 'fssai':
          fssaiDocs.remove(file);
          break;
        case 'msme':
          msmeDocs.remove(file);
          break;
      }
    });
  }

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 5 files allowed')),
          );
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
    return ZerpaiLayout(
      pageTitle: 'New Customer',
      useTopPadding: false,
      horizontalPaddingValue: 24,
      footer: _buildFooter(),
      enableBodyScroll: true,
      child: isLoading
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_buildPrimaryInfo(), FormSkeleton()],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_buildPrimaryInfo(), _buildTabSection()],
            ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: TabBar(
                padding: EdgeInsets.zero,
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.black,
                unselectedLabelColor: const Color(0xFF6B7280),
                indicatorColor: const Color(0xFF2563EB),
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
          ],
        ),
        // Use direct indexing to allow the whole page to scroll as one
        tabViews[_tabController.index],
      ],
    );
  }

  // Validation state
  Set<String> validationErrors = {};
  bool hasAttemptedSubmit = false;

  Future<void> _saveCustomer() async {
    // Mark that user has attempted to submit
    setState(() {
      hasAttemptedSubmit = true;
      validationErrors.clear();
    });

    // Validate required fields
    if (displayNameCtrl.text.trim().isEmpty) {
      validationErrors.add('displayName');
    }
    final email = emailCtrl.text.trim();
    if (enablePortal && email.isEmpty) {
      validationErrors.add('email');
    } else if (email.isNotEmpty && !_isValidEmail(email)) {
      validationErrors.add('email');
    }

    // If there are validation errors, show message and return
    if (validationErrors.isNotEmpty) {
      setState(() {}); // Rebuild to show red borders
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields (marked with *)'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
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
              workPhone: workPhone.isNotEmpty
                  ? '${row.workCode} $workPhone'
                  : null,
              mobilePhone: mobilePhone.isNotEmpty
                  ? '${row.mobileCode} $mobilePhone'
                  : null,
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
        phone: workPhoneCtrl.text.trim().isNotEmpty
            ? '$phoneCode ${workPhoneCtrl.text.trim()}'
            : null,
        mobilePhone: mobilePhoneCtrl.text.trim().isNotEmpty
            ? '$mobileCode ${mobilePhoneCtrl.text.trim()}'
            : null,
        designation: designationCtrl.text.trim(),
        department: departmentCtrl.text.trim(),
        gstTreatment: gstTreatment.label,
        gstin: gstinPrefillCtrl.text.trim(),
        placeOfSupply: placeOfSupply == 'Select' ? null : placeOfSupply,
        pan: panCtrl.text.trim(),
        taxPreference: taxPreference,
        exemptionReason: exemptionReason,
        currencyId: currency.id.isNotEmpty
            ? currency.id
            : currency.code, // Fallback to code if ID missing (legacy)
        openingBalance: double.tryParse(openingBalanceCtrl.text) ?? 0,
        creditLimit: double.tryParse(creditLimitCtrl.text) ?? 0,
        paymentTerms: paymentTerms,
        priceList: selectedPriceList?.id,
        billingAddressStreet1: billingStreetCtrl.text.trim(),
        billingAddressStreet2: billingStreet2Ctrl.text.trim(),
        billingAddressCity: billingCityCtrl.text.trim(),
        billingAddressStateId: billingStateId,
        billingAddressZip: billingPinCtrl.text.trim(),
        billingAddressCountryId: billingCountryId,
        billingAddressPhone: billingPhoneCtrl.text.trim().isNotEmpty
            ? '$billingPhoneCode ${billingPhoneCtrl.text.trim()}'
            : null,
        shippingAddressStreet1: shippingStreetCtrl.text.trim(),
        shippingAddressStreet2: shippingStreet2Ctrl.text.trim(),
        shippingAddressCity: shippingCityCtrl.text.trim(),
        shippingAddressStateId: shippingStateId,
        shippingAddressZip: shippingPinCtrl.text.trim(),
        shippingAddressCountryId: shippingCountryId,
        shippingAddressPhone: shippingPhoneCtrl.text.trim().isNotEmpty
            ? '$shippingPhoneCode ${shippingPhoneCtrl.text.trim()}'
            : null,
        enablePortal: enablePortal,
        facebookHandle: facebookCtrl.text.trim(),
        twitterHandle: xHandleCtrl.text.trim(),
        whatsappNumber: whatsappCtrl.text.trim().isNotEmpty
            ? whatsappCtrl.text.trim()
            : null,
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

      final result = await ref
          .read(salesOrderControllerProvider.notifier)
          .createCustomer(newCustomer);

      if (mounted) {
        // Show success message BEFORE navigation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Customer ${result.displayName} created successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Wait a moment for the SnackBar to show
        await Future.delayed(const Duration(milliseconds: 300));

        // Then navigate
        if (mounted) {
          if (Navigator.of(context).canPop()) {
            Navigator.pop(context);
          } else {
            context.go(AppRoutes.salesCustomers);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error creating customer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating customer: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
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
            // Try to find INR, otherwise take first
            final inrIndex = currencies.indexWhere((c) => c.code == 'INR');
            if (inrIndex != -1) {
              currency = currencies[inrIndex];
            } else {
              currency = currencies.first;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading currencies: $e');
      if (mounted && _localCurrencyOptions.isEmpty) {
        setState(() {
          _localCurrencyOptions = defaultCurrencyOptions;
          currency = defaultCurrencyOptions.first;
        });
      }
    }
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
