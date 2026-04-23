part of '../sales_customer_create.dart';

extension _SalesCustomerHelpers on _SalesCustomerCreateScreenState {
  String _normalizeCustomerType(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == 'individual') {
      return 'Individual';
    }
    return 'Business';
  }

  void _populateFromCustomer(SalesCustomer customer) {
    customerType = _normalizeCustomerType(customer.customerType);
    salutation = customer.salutation ?? 'Mr.';

    firstNameCtrl.text = customer.firstName ?? '';
    lastNameCtrl.text = customer.lastName ?? '';
    companyNameCtrl.text = customer.companyName ?? '';
    displayNameCtrl.text = customer.displayName;
    emailCtrl.text = customer.email ?? '';
    departmentCtrl.text = customer.department ?? '';
    designationCtrl.text = customer.designation ?? '';
    panCtrl.text = customer.pan ?? '';
    gstinPrefillCtrl.text = customer.gstin ?? '';
    placeOfSupply = customer.placeOfSupply?.isNotEmpty == true
        ? customer.placeOfSupply!
        : 'Select';
    taxPreference = customer.taxPreference?.isNotEmpty == true
        ? customer.taxPreference!
        : 'Taxable';
    customerNumberCtrl.text = customer.customerNumber ?? customerNumberCtrl.text;
    remarksCtrl.text = customer.privilegeCardNumber ?? '';
    xHandleCtrl.text = customer.twitterHandle ?? '';
    whatsappCtrl.text = customer.whatsappNumber ?? '';
    facebookCtrl.text = customer.facebookHandle ?? '';
    businessType = customer.businessType ?? businessType;
    openingBalanceCtrl.text = (customer.openingBalance ?? 0).toString();
    creditLimitCtrl.text = (customer.creditLimit ?? 0).toString();
    paymentTerms = customer.paymentTerms?.isNotEmpty == true
        ? customer.paymentTerms!
        : paymentTerms;
    selectedPriceListId = customer.priceList;
    enablePortal = customer.enablePortal ?? false;

    _applyPhoneValue(customer.phone, isMobile: false);
    _applyPhoneValue(customer.mobilePhone, isMobile: true);
    _applyAddressPhoneValue(customer.billingAddressPhone, isShipping: false);
    _applyAddressPhoneValue(customer.shippingAddressPhone, isShipping: true);

    billingStreetCtrl.text = customer.billingAddressStreet1 ?? '';
    billingStreet2Ctrl.text = customer.billingAddressStreet2 ?? '';
    billingCityCtrl.text = customer.billingAddressCity ?? '';
    billingStateId = customer.billingAddressStateId;
    billingPinCtrl.text = customer.billingAddressZip ?? '';
    billingCountryId = customer.billingAddressCountryId;

    shippingStreetCtrl.text = customer.shippingAddressStreet1 ?? '';
    shippingStreet2Ctrl.text = customer.shippingAddressStreet2 ?? '';
    shippingCityCtrl.text = customer.shippingAddressCity ?? '';
    shippingStateId = customer.shippingAddressStateId;
    shippingPinCtrl.text = customer.shippingAddressZip ?? '';
    shippingCountryId = customer.shippingAddressCountryId;

    isDrugRegistered = customer.isDrugRegistered;
    isFssaiRegistered = customer.isFssaiRegistered;
    isMsmeRegistered = customer.isMsmeRegistered;
    drugLicenceType = customer.drugLicenceType;
    drugLicense20Ctrl.text = customer.drugLicense20 ?? '';
    drugLicense21Ctrl.text = customer.drugLicense21 ?? '';
    drugLicense20BCtrl.text = customer.drugLicense20B ?? '';
    drugLicense21BCtrl.text = customer.drugLicense21B ?? '';
    fssaiCtrl.text = customer.fssai ?? '';
    msmeRegistrationType = customer.msmeRegistrationType;
    msmeNumberCtrl.text = customer.msmeNumber ?? '';
    isRecurring = customer.isRecurring;
    dob = customer.dob;
    if (customer.dob != null) {
      dobCtrl.text = DateFormat('dd/MM/yyyy').format(customer.dob!);
      dobDay = customer.dob!.day.toString().padLeft(2, '0');
      dobMonth = DateFormat('MMMM').format(customer.dob!);
      dobYear = customer.dob!.year.toString();
    }

    if (customer.gstTreatment?.isNotEmpty == true) {
      gstTreatment = _gstTreatmentOptions.firstWhere(
        (option) =>
            option.label == customer.gstTreatment ||
            option.label.toLowerCase() == customer.gstTreatment!.toLowerCase(),
        orElse: () => gstTreatment,
      );
    }

    contactRows
      ..clear()
      ..addAll(
        (customer.contactPersons ?? []).map((contact) {
          final row = _ContactPersonRow()
            ..salutation = contact.salutation ?? 'Mr.'
            ..firstNameCtrl.text = contact.firstName ?? ''
            ..lastNameCtrl.text = contact.lastName ?? ''
            ..emailCtrl.text = contact.email ?? '';
          _applyPhoneIntoRow(contact.workPhone, row, isMobile: false);
          _applyPhoneIntoRow(contact.mobilePhone, row, isMobile: true);
          return row;
        }),
      );
    if (contactRows.isEmpty) {
      contactRows.add(_ContactPersonRow());
    }

    _refreshDisplayNameOptions();
    _syncCustomerNumberPreferences();
  }

  void _applyPhoneValue(String? value, {required bool isMobile}) {
    if (value == null || value.trim().isEmpty) return;
    final parsed = _splitPhone(value);
    if (isMobile) {
      mobileCode = parsed.$1;
      mobilePhoneCtrl.text = parsed.$2;
    } else {
      phoneCode = parsed.$1;
      workPhoneCtrl.text = parsed.$2;
    }
  }

  void _applyAddressPhoneValue(String? value, {required bool isShipping}) {
    if (value == null || value.trim().isEmpty) return;
    final parsed = _splitPhone(value);
    if (isShipping) {
      shippingPhoneCode = parsed.$1;
      shippingPhoneCtrl.text = parsed.$2;
    } else {
      billingPhoneCode = parsed.$1;
      billingPhoneCtrl.text = parsed.$2;
    }
  }

  void _applyPhoneIntoRow(String? value, _ContactPersonRow row, {required bool isMobile}) {
    if (value == null || value.trim().isEmpty) return;
    final parsed = _splitPhone(value);
    if (isMobile) {
      row.mobileCode = parsed.$1;
      row.mobilePhoneCtrl.text = parsed.$2;
    } else {
      row.workCode = parsed.$1;
      row.workPhoneCtrl.text = parsed.$2;
    }
  }

  (String, String) _splitPhone(String value) {
    final trimmed = value.trim();
    final match = RegExp(r'^(\+\d+)\s*(.*)$').firstMatch(trimmed);
    if (match != null) {
      return (match.group(1) ?? '+91', match.group(2) ?? '');
    }
    return ('+91', trimmed);
  }

  void _updateAgeFromDropdowns() {
    if (dobDay == null || dobMonth == null || dobYear == null) return;
    try {
      final month = _monthNameToNumber(dobMonth!);
      final parsed = DateTime(int.parse(dobYear!), month, int.parse(dobDay!));
      _state(() {
        dob = parsed;
        dobCtrl.text = DateFormat('dd/MM/yyyy').format(parsed);
      });
    } catch (_) {}
  }

  int _monthNameToNumber(String name) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months.indexOf(name) + 1;
  }

  bool _shouldHideGstRegistrationFields() {
    final label = gstTreatment.label;
    return label == 'Unregistered Business' ||
        label == 'Consumer' ||
        label == 'Overseas';
  }

  bool _isGstinRequired() => !_shouldHideGstRegistrationFields();

  bool _shouldHidePlaceOfSupply() {
    return gstTreatment.label == 'Overseas';
  }

  int _calculateAge(DateTime date) {
    final now = DateTime.now();
    int years = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      years -= 1;
    }
    return years;
  }

  void _updateSalutation(String? value) {
    final next = value ?? 'Mr.';
    final options = _buildDisplayNameOptions(
      next,
      firstNameCtrl.text,
      lastNameCtrl.text,
      companyNameCtrl.text,
    );
    final current = displayNameCtrl.text.trim();
    final bool shouldAutoSet =
        current.isEmpty || _displayNameOptions.contains(current);

    _state(() {
      salutation = next;
      _displayNameOptions = options;
      if (shouldAutoSet && options.isNotEmpty) {
        displayNameCtrl.text = options.first;
      }
    });
  }

  void _refreshDisplayNameOptions() {
    final options = _buildDisplayNameOptions(
      salutation,
      firstNameCtrl.text,
      lastNameCtrl.text,
      companyNameCtrl.text,
    );
    final current = displayNameCtrl.text.trim();
    final bool shouldAutoSet =
        current.isEmpty || _displayNameOptions.contains(current);

    if (!mounted) return;
    _state(() {
      _displayNameOptions = options;
      if (shouldAutoSet && options.isNotEmpty) {
        displayNameCtrl.text = options.first;
      }
    });
  }

  /// Load phone codes from the countries table (same approach as vendors).
  Future<void> _loadCountries() async {
    try {
      final lookupsService = LookupsApiService();
      final countries = await lookupsService.getCountries();
      if (!mounted) return;
      _state(() {
        // Set India as default country
        final india = countries.firstWhere(
          (c) => c['name']?.toString().toLowerCase() == 'india',
          orElse: () => {},
        );
        if (india.isNotEmpty) {
          billingCountryId ??= india['id']?.toString();
          shippingCountryId ??= india['id']?.toString();
        }
      });
    } catch (e) {
      AppLogger.error('Error loading countries/phone codes', error: e);
    }
  }

  Widget _prefillInfoTile({required String title, required String value}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _applyGstinPrefill(GstinLookupResult result, GstinAddress? address) {
    _state(() {
      companyNameCtrl.text = result.legalName;
      displayNameCtrl.text = (result.tradeName.isNotEmpty
          ? result.tradeName
          : result.legalName);
      gstinPrefillCtrl.text = result.gstin;
      businessLegalNameCtrl.text = result.legalName;
      businessTradeNameCtrl.text = result.tradeName;

      if (panCtrl.text.isEmpty && result.gstin.length >= 12) {
        panCtrl.text = result.gstin.substring(2, 12);
      }

      if (address != null) {
        billingStreetCtrl.text = address.line1;
        billingStreet2Ctrl.text = address.line2;
        billingCityCtrl.text = address.city;
        billingPinCtrl.text = address.pinCode;
      }
    });
  }

  void _syncCustomerNumberPreferences() {
    final current = customerNumberCtrl.text.trim();
    if (current.isEmpty) return;

    final match = RegExp(r'^(.*?)(\d+)$').firstMatch(current);
    if (match == null) {
      customerNumberPrefixCtrl.text = current.replaceAll('-', '').trim();
      customerNumberNextCtrl.text = '';
      return;
    }

    final rawPrefix = match.group(1) ?? '';
    customerNumberPrefixCtrl.text = rawPrefix.replaceAll('-', '').trim();
    customerNumberNextCtrl.text = match.group(2) ?? '';
  }

  void _applyCustomerNumberPreferences() {
    final prefix = customerNumberPrefixCtrl.text.replaceAll('-', '').trim();
    final nextNumber = customerNumberNextCtrl.text.replaceAll('-', '').trim();
    if (prefix.isEmpty && nextNumber.isEmpty) return;
    if (prefix.isEmpty) {
      customerNumberCtrl.text = nextNumber;
      return;
    }
    if (nextNumber.isEmpty) {
      customerNumberCtrl.text = prefix;
      return;
    }
    customerNumberCtrl.text = '$prefix-$nextNumber';
  }

  void _handleCustomerTypeChange(String? value) {
    if (value == null || value == customerType) return;

    _state(() {
      customerType = value;
      // Re-initialize tab controller for dynamic tab layout (even if count is same, mapping shifts)
      _tabController.dispose();
      int tabCount = 7;
      // Both Business and Individual now have 7 tabs
      // Business: Other, Licence, Address, Contact, Custom, Reporting, Remarks
      // Individual: Other, Address, Contact, Custom, Reporting, Remarks, Attributes

      _tabController = TabController(length: tabCount, vsync: this);
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          _state(() {});
        }
      });
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return "${(bytes / math.pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}";
  }

}
