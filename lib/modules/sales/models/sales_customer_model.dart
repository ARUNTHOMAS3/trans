class SalesCustomer {
  final String id;
  final String? customerNumber;
  final String displayName;
  final String? customerType; // Business, Individual
  final String? salutation;
  final String? firstName;
  final String? lastName;
  final String? companyName;
  final String? email;
  final String? phone; // General or Work
  final String? mobilePhone;
  final String? designation;
  final String? department;
  final String? website;
  final String? businessType;

  // Tax & Regulatory
  final String? gstTreatment;
  final String? gstin;
  final String? placeOfSupply;
  final String? pan;
  final String? taxPreference;
  final String? exemptionReason;

  // Licence Details
  final bool isDrugRegistered;
  final bool isFssaiRegistered;
  final bool isMsmeRegistered;
  final String? drugLicenceType;
  final String? drugLicense20; // Retail Form 20
  final String? drugLicense21; // Retail Form 21
  final String? drugLicense20B; // Wholesale Form 20B
  final String? drugLicense21B; // Wholesale Form 21B
  final String? fssai;
  final String? msmeRegistrationType;
  final String? msmeNumber;

  // License Document URLs
  final String? drugLicense20DocUrl;
  final String? drugLicense21DocUrl;
  final String? drugLicense20BDocUrl;
  final String? drugLicense21BDocUrl;
  final String? fssaiDocUrl;
  final String? msmeDocUrl;
  final String? documentUrls;

  // Finance Details
  final String? currencyId;
  final double? openingBalance;
  final double? creditLimit;
  final String? paymentTerms;
  final String? priceList;
  final double? receivables;

  // Addresses
  final String? billingAddressStreet1;
  final String? billingAddressStreet2;
  final String? billingAddressCity;
  final String? billingAddressStateId;
  final String? billingAddressZip;
  final String? billingAddressCountryId;
  final String? billingAddressPhone;

  final String? shippingAddressStreet1;
  final String? shippingAddressStreet2;
  final String? shippingAddressCity;
  final String? shippingAddressStateId;
  final String? shippingAddressZip;
  final String? shippingAddressCountryId;
  final String? shippingAddressPhone;

  // Social & CRM
  final bool? enablePortal;
  final String? facebookHandle;
  final String? twitterHandle;
  final String? whatsappNumber;
  final bool isRecurring;
  final List<CustomerContact>? contactPersons;

  final bool isActive;
  final DateTime? createdAt;
  final DateTime? dob;
  final String? gender;
  final String? placeOfCustomer;
  final String? privilegeCardNumber;

  SalesCustomer({
    required this.id,
    this.customerNumber,
    required this.displayName,
    this.customerType = 'Business',
    this.salutation,
    this.firstName,
    this.lastName,
    this.companyName,
    this.email,
    this.phone,
    this.mobilePhone,
    this.designation,
    this.department,
    this.website,
    this.gstTreatment,
    this.gstin,
    this.placeOfSupply,
    this.pan,
    this.taxPreference,
    this.exemptionReason,
    this.currencyId,
    this.openingBalance,
    this.creditLimit,
    this.paymentTerms,
    this.priceList,
    this.receivables,
    this.billingAddressStreet1,
    this.billingAddressStreet2,
    this.billingAddressCity,
    this.billingAddressStateId,
    this.billingAddressZip,
    this.billingAddressCountryId,
    this.billingAddressPhone,
    this.shippingAddressStreet1,
    this.shippingAddressStreet2,
    this.shippingAddressCity,
    this.shippingAddressStateId,
    this.shippingAddressZip,
    this.shippingAddressCountryId,
    this.shippingAddressPhone,
    this.enablePortal,
    this.facebookHandle,
    this.twitterHandle,
    this.whatsappNumber,
    this.isRecurring = false,
    this.isDrugRegistered = false,
    this.isFssaiRegistered = false,
    this.isMsmeRegistered = false,
    this.drugLicenceType,
    this.drugLicense20,
    this.drugLicense21,
    this.drugLicense20B,
    this.drugLicense21B,
    this.fssai,
    this.msmeRegistrationType,
    this.msmeNumber,
    this.drugLicense20DocUrl,
    this.drugLicense21DocUrl,
    this.drugLicense20BDocUrl,
    this.drugLicense21BDocUrl,
    this.fssaiDocUrl,
    this.msmeDocUrl,
    this.documentUrls,
    this.businessType,
    this.contactPersons,
    this.isActive = true,
    this.createdAt,
    this.dob,
    this.gender,
    this.placeOfCustomer,
    this.privilegeCardNumber,
  });

  SalesCustomer copyWith({
    String? id,
    String? customerNumber,
    String? displayName,
    String? customerType,
    String? salutation,
    String? firstName,
    String? lastName,
    String? companyName,
    String? email,
    String? phone,
    String? mobilePhone,
    String? designation,
    String? department,
    String? website,
    String? gstTreatment,
    String? gstin,
    String? placeOfSupply,
    String? pan,
    String? taxPreference,
    String? exemptionReason,
    String? currencyId,
    double? openingBalance,
    double? creditLimit,
    String? paymentTerms,
    String? priceList,
    double? receivables,
    String? billingAddressStreet1,
    String? billingAddressStreet2,
    String? billingAddressCity,
    String? billingAddressStateId,
    String? billingAddressZip,
    String? billingAddressCountryId,
    String? billingAddressPhone,
    String? shippingAddressStreet1,
    String? shippingAddressStreet2,
    String? shippingAddressCity,
    String? shippingAddressStateId,
    String? shippingAddressZip,
    String? shippingAddressCountryId,
    String? shippingAddressPhone,
    bool? enablePortal,
    String? facebookHandle,
    String? twitterHandle,
    String? whatsappNumber,
    bool? isRecurring,
    bool? isDrugRegistered,
    bool? isFssaiRegistered,
    bool? isMsmeRegistered,
    String? drugLicenceType,
    String? drugLicense20,
    String? drugLicense21,
    String? drugLicense20B,
    String? drugLicense21B,
    String? fssai,
    String? msmeRegistrationType,
    String? msmeNumber,
    String? drugLicense20DocUrl,
    String? drugLicense21DocUrl,
    String? drugLicense20BDocUrl,
    String? drugLicense21BDocUrl,
    String? fssaiDocUrl,
    String? msmeDocUrl,
    String? documentUrls,
    String? businessType,
    List<CustomerContact>? contactPersons,
    bool? isActive,
    DateTime? createdAt,
    DateTime? dob,
    String? gender,
    String? placeOfCustomer,
    String? privilegeCardNumber,
  }) {
    return SalesCustomer(
      id: id ?? this.id,
      customerNumber: customerNumber ?? this.customerNumber,
      displayName: displayName ?? this.displayName,
      customerType: customerType ?? this.customerType,
      salutation: salutation ?? this.salutation,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      mobilePhone: mobilePhone ?? this.mobilePhone,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      website: website ?? this.website,
      gstTreatment: gstTreatment ?? this.gstTreatment,
      gstin: gstin ?? this.gstin,
      placeOfSupply: placeOfSupply ?? this.placeOfSupply,
      pan: pan ?? this.pan,
      taxPreference: taxPreference ?? this.taxPreference,
      exemptionReason: exemptionReason ?? this.exemptionReason,
      currencyId: currencyId ?? this.currencyId,
      openingBalance: openingBalance ?? this.openingBalance,
      creditLimit: creditLimit ?? this.creditLimit,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      priceList: priceList ?? this.priceList,
      receivables: receivables ?? this.receivables,
      billingAddressStreet1:
          billingAddressStreet1 ?? this.billingAddressStreet1,
      billingAddressStreet2:
          billingAddressStreet2 ?? this.billingAddressStreet2,
      billingAddressCity: billingAddressCity ?? this.billingAddressCity,
      billingAddressStateId:
          billingAddressStateId ?? this.billingAddressStateId,
      billingAddressZip: billingAddressZip ?? this.billingAddressZip,
      billingAddressCountryId:
          billingAddressCountryId ?? this.billingAddressCountryId,
      billingAddressPhone: billingAddressPhone ?? this.billingAddressPhone,
      shippingAddressStreet1:
          shippingAddressStreet1 ?? this.shippingAddressStreet1,
      shippingAddressStreet2:
          shippingAddressStreet2 ?? this.shippingAddressStreet2,
      shippingAddressCity: shippingAddressCity ?? this.shippingAddressCity,
      shippingAddressStateId:
          shippingAddressStateId ?? this.shippingAddressStateId,
      shippingAddressZip: shippingAddressZip ?? this.shippingAddressZip,
      shippingAddressCountryId:
          shippingAddressCountryId ?? this.shippingAddressCountryId,
      shippingAddressPhone: shippingAddressPhone ?? this.shippingAddressPhone,
      enablePortal: enablePortal ?? this.enablePortal,
      facebookHandle: facebookHandle ?? this.facebookHandle,
      twitterHandle: twitterHandle ?? this.twitterHandle,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      isRecurring: isRecurring ?? this.isRecurring,
      isDrugRegistered: isDrugRegistered ?? this.isDrugRegistered,
      isFssaiRegistered: isFssaiRegistered ?? this.isFssaiRegistered,
      isMsmeRegistered: isMsmeRegistered ?? this.isMsmeRegistered,
      drugLicenceType: drugLicenceType ?? this.drugLicenceType,
      drugLicense20: drugLicense20 ?? this.drugLicense20,
      drugLicense21: drugLicense21 ?? this.drugLicense21,
      drugLicense20B: drugLicense20B ?? this.drugLicense20B,
      drugLicense21B: drugLicense21B ?? this.drugLicense21B,
      fssai: fssai ?? this.fssai,
      msmeRegistrationType: msmeRegistrationType ?? this.msmeRegistrationType,
      msmeNumber: msmeNumber ?? this.msmeNumber,
      drugLicense20DocUrl: drugLicense20DocUrl ?? this.drugLicense20DocUrl,
      drugLicense21DocUrl: drugLicense21DocUrl ?? this.drugLicense21DocUrl,
      drugLicense20BDocUrl: drugLicense20BDocUrl ?? this.drugLicense20BDocUrl,
      drugLicense21BDocUrl: drugLicense21BDocUrl ?? this.drugLicense21BDocUrl,
      fssaiDocUrl: fssaiDocUrl ?? this.fssaiDocUrl,
      msmeDocUrl: msmeDocUrl ?? this.msmeDocUrl,
      documentUrls: documentUrls ?? this.documentUrls,
      businessType: businessType ?? this.businessType,
      contactPersons: contactPersons ?? this.contactPersons,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      placeOfCustomer: placeOfCustomer ?? this.placeOfCustomer,
      privilegeCardNumber: privilegeCardNumber ?? this.privilegeCardNumber,
    );
  }

  factory SalesCustomer.fromJson(Map<String, dynamic> json) {
    return SalesCustomer(
      id: json['id'] ?? '',
      customerNumber: json['customerNumber'] ?? json['customer_number'],
      displayName: json['displayName'] ?? json['display_name'] ?? '',
      customerType: json['customerType'] ?? json['customer_type'],
      salutation: json['salutation'],
      firstName: json['firstName'] ?? json['first_name'],
      lastName: json['lastName'] ?? json['last_name'],
      companyName: json['companyName'] ?? json['company_name'],
      email: json['email'],
      phone: json['phone']?.toString(),
      mobilePhone: (json['mobilePhone'] ?? json['mobile_phone'])?.toString(),
      designation: json['designation'],
      department: json['department'],
      website: json['website'],
      gstTreatment: json['gstTreatment'] ?? json['gst_treatment'],
      gstin: json['gstin'],
      placeOfSupply: (json['placeOfSupply'] ?? json['place_of_supply'])
          ?.toString(),
      pan: json['pan'],
      taxPreference: json['taxPreference'] ?? json['tax_preference'],
      exemptionReason: json['exemptionReason'] ?? json['exemption_reason'],
      currencyId: json['currencyId'] ?? json['currency_id'],
      openingBalance: _parseDouble(
        json['openingBalance'] ?? json['opening_balance'],
      ),
      creditLimit: _parseDouble(json['creditLimit'] ?? json['credit_limit']),
      paymentTerms: json['paymentTerms'] ?? json['payment_terms'],
      priceList: json['priceList'] ?? json['price_list'],
      receivables: _parseDouble(json['receivables']),
      billingAddressStreet1:
          json['billingAddressStreet1'] ?? json['billing_address_street1'],
      billingAddressStreet2:
          json['billingAddressStreet2'] ?? json['billing_address_street2'],
      billingAddressCity:
          json['billingAddressCity'] ?? json['billing_address_city'],
      billingAddressStateId:
          json['billingAddressStateId'] ?? json['billing_address_state_id'],
      billingAddressZip:
          json['billingAddressZip'] ?? json['billing_address_zip'],
      billingAddressCountryId:
          json['billingAddressCountryId'] ?? json['billing_address_country_id'],
      billingAddressPhone:
          json['billingAddressPhone'] ?? json['billing_address_phone'],
      shippingAddressStreet1:
          json['shippingAddressStreet1'] ?? json['shipping_address_street1'],
      shippingAddressStreet2:
          json['shippingAddressStreet2'] ?? json['shipping_address_street2'],
      shippingAddressCity:
          json['shippingAddressCity'] ?? json['shipping_address_city'],
      shippingAddressStateId:
          json['shippingAddressStateId'] ?? json['shipping_address_state_id'],
      shippingAddressZip:
          json['shippingAddressZip'] ?? json['shipping_address_zip'],
      shippingAddressCountryId:
          json['shippingAddressCountryId'] ??
          json['shipping_address_country_id'],
      shippingAddressPhone:
          json['shippingAddressPhone'] ?? json['shipping_address_phone'],
      enablePortal: json['enablePortal'] ?? json['enable_portal'],
      facebookHandle: json['facebookHandle'] ?? json['facebook_handle'],
      twitterHandle: json['twitterHandle'] ?? json['twitter_handle'],
      whatsappNumber: json['whatsappNumber'] ?? json['whatsapp_number'],
      isDrugRegistered:
          json['isDrugRegistered'] ?? json['is_drug_registered'] ?? false,
      isFssaiRegistered:
          json['isFssaiRegistered'] ?? json['is_fssai_registered'] ?? false,
      isMsmeRegistered:
          json['isMsmeRegistered'] ?? json['is_msme_registered'] ?? false,
      drugLicenceType: json['drugLicenceType'] ?? json['drug_licence_type'],
      drugLicense20: json['drugLicense20'] ?? json['drug_license_20'],
      drugLicense21: json['drugLicense21'] ?? json['drug_license_21'],
      drugLicense20B: json['drugLicense20B'] ?? json['drug_license_20b'],
      drugLicense21B: json['drugLicense21B'] ?? json['drug_license_21b'],
      fssai: json['fssai'],
      msmeRegistrationType:
          json['msmeRegistrationType'] ?? json['msme_registration_type'],
      msmeNumber: json['msmeNumber'] ?? json['msme_number'],
      drugLicense20DocUrl:
          json['drugLicense20DocUrl'] ?? json['drug_license_20_doc_url'],
      drugLicense21DocUrl:
          json['drugLicense21DocUrl'] ?? json['drug_license_21_doc_url'],
      drugLicense20BDocUrl:
          json['drugLicense20BDocUrl'] ?? json['drug_license_20b_doc_url'],
      drugLicense21BDocUrl:
          json['drugLicense21BDocUrl'] ?? json['drug_license_21b_doc_url'],
      fssaiDocUrl: json['fssaiDocUrl'] ?? json['fssai_doc_url'],
      msmeDocUrl: json['msmeDocUrl'] ?? json['msme_doc_url'],
      documentUrls: json['documentUrls'] is List
          ? (json['documentUrls'] as List).join(',')
          : (json['document_urls'] is List
                ? (json['document_urls'] as List).join(',')
                : (json['documentUrls'] ?? json['document_urls'])),
      isRecurring: json['isRecurring'] ?? json['is_recurring'] ?? false,
      businessType: json['businessType'] ?? json['business_type'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: json['createdAt'] != null || json['created_at'] != null
          ? DateTime.parse(json['createdAt'] ?? json['created_at'])
          : null,
      dob: json['dob'] != null || json['date_of_birth'] != null
          ? DateTime.parse(json['dob'] ?? json['date_of_birth'])
          : null,
      gender: json['gender'],
      placeOfCustomer: json['placeOfCustomer'] ?? json['place_of_customer'],
      privilegeCardNumber:
          json['privilegeCardNumber'] ?? json['privilege_card_number'],
      contactPersons: json['contactPersons'] != null
          ? (json['contactPersons'] as List)
                .map((i) => CustomerContact.fromJson(i))
                .toList()
          : (json['contacts'] != null
                ? (json['contacts'] as List)
                      .map((i) => CustomerContact.fromJson(i))
                      .toList()
                : null),
    );
  }

  String get fullBillingAddress {
    final parts = [
      billingAddressStreet1,
      billingAddressStreet2,
      billingAddressCity,
      billingAddressZip,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.isEmpty ? 'N/A' : parts.join(', ');
  }

  String get fullShippingAddress {
    final parts = [
      shippingAddressStreet1,
      shippingAddressStreet2,
      shippingAddressCity,
      shippingAddressZip,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.isEmpty ? 'N/A' : parts.join(', ');
  }

  Map<String, dynamic> toJson() {
    final billingAddress = {
      'street1': billingAddressStreet1,
      'street2': billingAddressStreet2,
      'city': billingAddressCity,
      'stateId': billingAddressStateId,
      'zip': billingAddressZip,
      'countryId': billingAddressCountryId,
      'phone': billingAddressPhone,
    }..removeWhere((key, value) => value == null || value.toString().isEmpty);

    final shippingAddress = {
      'street1': shippingAddressStreet1,
      'street2': shippingAddressStreet2,
      'city': shippingAddressCity,
      'stateId': shippingAddressStateId,
      'zip': shippingAddressZip,
      'countryId': shippingAddressCountryId,
      'phone': shippingAddressPhone,
    }..removeWhere((key, value) => value == null || value.toString().isEmpty);

    return {
      'customerNumber': customerNumber,
      'displayName': displayName,
      'customerType': customerType?.toLowerCase() ?? 'business',
      if (salutation != null && salutation!.isNotEmpty)
        'salutation': salutation,
      if (firstName != null && firstName!.isNotEmpty) 'firstName': firstName,
      if (lastName != null && lastName!.isNotEmpty) 'lastName': lastName,
      if (companyName != null && companyName!.isNotEmpty)
        'companyName': companyName,
      if (email != null && email!.isNotEmpty) 'email': email,
      // Map mobilePhone to phone as backend expects 'phone'
      if (phone != null && phone!.isNotEmpty)
        'phone': phone
      else if (mobilePhone != null && mobilePhone!.isNotEmpty)
        'phone': mobilePhone,
      if (website != null && website!.isNotEmpty) 'website': website,
      if (designation != null && designation!.isNotEmpty)
        'designation': designation,
      if (department != null && department!.isNotEmpty)
        'department': department,
      if (businessType != null && businessType!.isNotEmpty)
        'businessType': businessType,
      if (gstTreatment != null)
        'gstTreatment': _mapGstTreatmentToBackend(gstTreatment!),
      if (gstin != null && gstin!.isNotEmpty) 'gstin': gstin,
      if (pan != null && pan!.isNotEmpty) 'pan': pan,
      if (placeOfSupply != null && placeOfSupply!.isNotEmpty)
        'placeOfSupply': placeOfSupply,
      if (currencyId != null && currencyId!.isNotEmpty)
        'currencyId': currencyId,
      if (priceList != null && priceList!.isNotEmpty) 'priceListId': priceList,
      if (openingBalance != null && openingBalance! > 0)
        'receivableBalance': openingBalance,
      if (paymentTerms != null && paymentTerms!.isNotEmpty)
        'paymentTerms': paymentTerms,
      if (billingAddress.isNotEmpty) 'billingAddress': billingAddress,
      if (shippingAddress.isNotEmpty) 'shippingAddress': shippingAddress,
      if (facebookHandle != null && facebookHandle!.isNotEmpty)
        'facebookHandle': facebookHandle,
      if (twitterHandle != null && twitterHandle!.isNotEmpty)
        'twitterHandle': twitterHandle,
      if (whatsappNumber != null && whatsappNumber!.isNotEmpty)
        'whatsappNumber': whatsappNumber,
      'isDrugRegistered': isDrugRegistered,
      'isFssaiRegistered': isFssaiRegistered,
      'isMsmeRegistered': isMsmeRegistered,
      if (drugLicenceType != null && drugLicenceType!.isNotEmpty)
        'drugLicenceType': drugLicenceType,
      if (drugLicense20 != null && drugLicense20!.isNotEmpty)
        'drugLicense20': drugLicense20,
      if (drugLicense21 != null && drugLicense21!.isNotEmpty)
        'drugLicense21': drugLicense21,
      if (drugLicense20B != null && drugLicense20B!.isNotEmpty)
        'drugLicense20B': drugLicense20B,
      if (drugLicense21B != null && drugLicense21B!.isNotEmpty)
        'drugLicense21B': drugLicense21B,
      if (fssai != null && fssai!.isNotEmpty) 'fssai': fssai,
      if (msmeRegistrationType != null && msmeRegistrationType!.isNotEmpty)
        'msmeRegistrationType': msmeRegistrationType,
      if (msmeNumber != null && msmeNumber!.isNotEmpty)
        'msmeNumber': msmeNumber,
      if (drugLicense20DocUrl != null && drugLicense20DocUrl!.isNotEmpty)
        'drugLicense20DocUrl': drugLicense20DocUrl,
      if (drugLicense21DocUrl != null && drugLicense21DocUrl!.isNotEmpty)
        'drugLicense21DocUrl': drugLicense21DocUrl,
      if (drugLicense20BDocUrl != null && drugLicense20BDocUrl!.isNotEmpty)
        'drugLicense20BDocUrl': drugLicense20BDocUrl,
      if (drugLicense21BDocUrl != null && drugLicense21BDocUrl!.isNotEmpty)
        'drugLicense21BDocUrl': drugLicense21BDocUrl,
      if (fssaiDocUrl != null && fssaiDocUrl!.isNotEmpty)
        'fssaiDocUrl': fssaiDocUrl,
      if (msmeDocUrl != null && msmeDocUrl!.isNotEmpty)
        'msmeDocUrl': msmeDocUrl,
      if (documentUrls != null && documentUrls!.isNotEmpty)
        'documentUrls': documentUrls,
      'isRecurring': isRecurring,
      if (businessType != null) 'businessType': businessType,
      if (dob != null) 'date_of_birth': dob!.toIso8601String(),
      if (gender != null) 'gender': gender,
      if (placeOfCustomer != null) 'place_of_customer': placeOfCustomer,
      if (privilegeCardNumber != null)
        'privilege_card_number': privilegeCardNumber,
      if (contactPersons != null)
        'contactPersons': contactPersons!.map((e) => e.toJson()).toList(),
    };
  }

  String _mapGstTreatmentToBackend(String uiValue) {
    const map = {
      'Registered Business - Regular': 'registered_business',
      'Registered Business - Composition': 'registered_business',
      'Unregistered Business': 'unregistered_business',
      'Consumer': 'consumer',
      'Overseas': 'overseas',
      'Special Economic Zone': 'overseas',
      'SEZ Developer': 'overseas',
      'Deemed Export': 'overseas',
    };
    // Default fallback if not found (or return as-is snake_cased if risky)
    return map[uiValue] ?? 'consumer';
  }

  // Helper function to safely parse doubles from various types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}

class CustomerContact {
  final String? id;
  final String? salutation;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? workPhone;
  final String? mobilePhone;
  // Removed isPrimary

  CustomerContact({
    this.id,
    this.salutation,
    this.firstName,
    this.lastName,
    this.email,
    this.workPhone,
    this.mobilePhone,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (salutation != null) 'salutation': salutation,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (email != null) 'email': email,
      if (workPhone != null) 'workPhone': workPhone,
      if (mobilePhone != null) 'mobilePhone': mobilePhone,
    };
  }

  factory CustomerContact.fromJson(Map<String, dynamic> json) {
    return CustomerContact(
      id: json['id'],
      salutation: json['salutation'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      workPhone: json['workPhone'],
      mobilePhone: json['mobilePhone'],
    );
  }
}
