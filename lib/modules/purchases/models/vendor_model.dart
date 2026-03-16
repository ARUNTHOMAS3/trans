class Vendor {
  final String id;
  final String? vendorNumber;
  final String displayName;
  // final String? vendorType; // Business, Individual
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

  // Tax & Regulatory
  final String? gstTreatment;
  final String? gstin;
  final String? placeOfSupply;
  final String? pan;
  // final String? taxPreference;
  // final String? exemptionReason;

  // Finance Details
  final String? currency;
  final double? openingBalance;
  final double? creditLimit;
  final String? paymentTerms;
  // final String? priceList;
  final double? payables;

  // Addresses
  final String? billingAddressStreet1;
  final String? billingAddressStreet2;
  final String? billingAddressCity;
  final String? billingAddressState;
  final String? billingAddressZip;
  final String? billingAddressCountry;
  final String? billingAddressPhone;

  final String? shippingAddressStreet1;
  final String? shippingAddressStreet2;
  final String? shippingAddressCity;
  final String? shippingAddressState;
  final String? shippingAddressZip;
  final String? shippingAddressCountry;
  final String? shippingAddressPhone;

  // Social & CRM
  final String? facebookHandle;
  final String? twitterHandle;
  final String? whatsappNumber;
  final bool? enablePortal;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Vendor({
    required this.id,
    this.vendorNumber,
    required this.displayName,
    // this.vendorType,
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
    // this.taxPreference,
    // this.exemptionReason,
    this.currency,
    this.openingBalance,
    this.creditLimit,
    this.paymentTerms,
    // this.priceList,
    this.payables,
    this.billingAddressStreet1,
    this.billingAddressStreet2,
    this.billingAddressCity,
    this.billingAddressState,
    this.billingAddressZip,
    this.billingAddressCountry,
    this.billingAddressPhone,
    this.shippingAddressStreet1,
    this.shippingAddressStreet2,
    this.shippingAddressCity,
    this.shippingAddressState,
    this.shippingAddressZip,
    this.shippingAddressCountry,
    this.shippingAddressPhone,
    this.facebookHandle,
    this.twitterHandle,
    this.whatsappNumber,
    this.enablePortal,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      vendorNumber: json['vendor_number'],
      displayName: json['display_name'],
      // vendorType: json['vendor_type'],
      salutation: json['salutation'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      companyName: json['company_name'],
      email: json['email'],
      phone: json['phone'],
      mobilePhone: json['mobile_phone'],
      designation: json['designation'],
      department: json['department'],
      website: json['website'],
      gstTreatment: json['gst_treatment'],
      gstin: json['gstin'],
      placeOfSupply: json['place_of_supply'],
      pan: json['pan'],
      // taxPreference: json['tax_preference'],
      // exemptionReason: json['exemption_reason'],
      currency: json['currency'],
      openingBalance: json['opening_balance'] != null
          ? double.parse(json['opening_balance'].toString())
          : null,
      creditLimit: json['credit_limit'] != null
          ? double.parse(json['credit_limit'].toString())
          : null,
      paymentTerms: json['payment_terms'],
      // priceList: json['price_list'],
      payables: json['payables'] != null
          ? double.parse(json['payables'].toString())
          : null,
      billingAddressStreet1: json['billing_address_street1'],
      billingAddressStreet2: json['billing_address_street2'],
      billingAddressCity: json['billing_address_city'],
      billingAddressState: json['billing_address_state'],
      billingAddressZip: json['billing_address_zip'],
      billingAddressCountry: json['billing_address_country'],
      billingAddressPhone: json['billing_address_phone'],
      shippingAddressStreet1: json['shipping_address_street1'],
      shippingAddressStreet2: json['shipping_address_street2'],
      shippingAddressCity: json['shipping_address_city'],
      shippingAddressState: json['shipping_address_state'],
      shippingAddressZip: json['shipping_address_zip'],
      shippingAddressCountry: json['shipping_address_country'],
      shippingAddressPhone: json['shipping_address_phone'],
      facebookHandle: json['facebook_handle'],
      twitterHandle: json['twitter_handle'],
      whatsappNumber: json['whatsapp_number'],
      enablePortal: json['enable_portal'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_number': vendorNumber,
      'display_name': displayName,
      // 'vendor_type': vendorType,
      'salutation': salutation,
      'first_name': firstName,
      'last_name': lastName,
      'company_name': companyName,
      'email': email,
      'phone': phone,
      'mobile_phone': mobilePhone,
      'designation': designation,
      'department': department,
      'website': website,
      'gst_treatment': gstTreatment,
      'gstin': gstin,
      'place_of_supply': placeOfSupply,
      'pan': pan,
      // 'tax_preference': taxPreference,
      // 'exemption_reason': exemptionReason,
      'currency': currency,
      'opening_balance': openingBalance?.toString(),
      'credit_limit': creditLimit?.toString(),
      'payment_terms': paymentTerms,
      // 'price_list': priceList,
      'payables': payables?.toString(),
      'billing_address_street1': billingAddressStreet1,
      'billing_address_street2': billingAddressStreet2,
      'billing_address_city': billingAddressCity,
      'billing_address_state': billingAddressState,
      'billing_address_zip': billingAddressZip,
      'billing_address_country': billingAddressCountry,
      'billing_address_phone': billingAddressPhone,
      'shipping_address_street1': shippingAddressStreet1,
      'shipping_address_street2': shippingAddressStreet2,
      'shipping_address_city': shippingAddressCity,
      'shipping_address_state': shippingAddressState,
      'shipping_address_zip': shippingAddressZip,
      'shipping_address_country': shippingAddressCountry,
      'shipping_address_phone': shippingAddressPhone,
      'facebook_handle': facebookHandle,
      'twitter_handle': twitterHandle,
      'whatsapp_number': whatsappNumber,
      'enable_portal': enablePortal,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
