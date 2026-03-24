part of '../sales_customer_create.dart';

extension _SalesCustomerHelpers on _SalesCustomerCreateScreenState {
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

  int _phoneMaxLengthForCode(String code) {
    return phonePrefixMaxDigits[code] ?? 15;
  }

  /// Trim phone number if it exceeds the max length for the new code.
  void _trimPhoneForCode(String code, TextEditingController ctrl) {
    final max = _phoneMaxLengthForCode(code);
    if (ctrl.text.length > max) {
      ctrl.text = ctrl.text.substring(0, max);
    }
  }

  /// Load phone codes from the countries table (same approach as vendors).
  Future<void> _loadCountries() async {
    try {
      final lookupsService = LookupsApiService();
      final countries = await lookupsService.getCountries();
      if (!mounted) return;
      _state(() {
        final codes = countries
            .map((c) => c['phone_code']?.toString())
            .where((c) => c != null && c.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();

        if (codes.isNotEmpty) {
          codes.sort((a, b) {
            if (a == '+91') return -1;
            if (b == '+91') return 1;
            return a.compareTo(b);
          });
          _phoneCodesList = codes;
        }

        // Build labels map: phone_code → country name
        final labels = <String, String>{};
        for (final c in countries) {
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
