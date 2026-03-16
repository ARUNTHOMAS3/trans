class Vendor {
  final String id;
  final String? vendorNumber;
  final String displayName;
  // final String? vendorType; // Manufacturer, Distributor, Wholesaler
  final String? salutation;
  final String? firstName;
  final String? lastName;
  final String? companyName;
  final String? email;
  final String? phone;
  final String? mobilePhone;
  final String? designation;
  final String? department;
  final String? website;
  final String? vendorLanguage;

  // Tax & Regulatory
  final String? gstTreatment;
  final String? gstin;
  final String? sourceOfSupply;
  final String? pan;
  // final String? taxPreference;
  // final String? exemptionReason;
  // final String? drugLicenseNo;
  final bool? isDrugRegistered;
  final String? drugLicenceType;
  final String? drugLicense20;
  final String? drugLicense21;
  final String? drugLicense20b;
  final String? drugLicense21b;
  final bool? isFssaiRegistered;
  final String? fssaiNumber;
  final bool? isMsmeRegistered;
  final String? msmeRegistrationType;
  final String? msmeRegistrationNumber;
  final String? tdsRateId;
  final String? priceListId;

  // Finance Details
  final String? currency;
  final String? paymentTerms;
  // final String? priceList;
  final String? remarks;
  final String? xHandle;
  final String? facebookHandle;
  final String? whatsappNumber;
  final String? source;

  // Addresses
  final Map<String, dynamic>? billingAddress;
  final Map<String, dynamic>? shippingAddress;
  final List<Map<String, dynamic>>? contactPersons;
  final List<Map<String, dynamic>>? bankDetails;
  final bool? enablePortal;

  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.vendorLanguage = 'English',
    this.gstTreatment,
    this.gstin,
    this.sourceOfSupply,
    this.pan,
    // this.taxPreference = 'Taxable',
    // this.exemptionReason,
    // this.drugLicenseNo,
    this.isDrugRegistered = false,
    this.drugLicenceType,
    this.drugLicense20,
    this.drugLicense21,
    this.drugLicense20b,
    this.drugLicense21b,
    this.isFssaiRegistered = false,
    this.fssaiNumber,
    this.isMsmeRegistered = false,
    this.msmeRegistrationType,
    this.msmeRegistrationNumber,
    this.tdsRateId,
    this.priceListId,
    this.currency = 'INR',
    this.paymentTerms,
    // this.priceList,
    this.remarks,
    this.xHandle,
    this.facebookHandle,
    this.whatsappNumber,
    this.source = 'User',
    this.billingAddress,
    this.shippingAddress,
    this.contactPersons,
    this.bankDetails,
    this.enablePortal = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] ?? '',
      vendorNumber: json['vendor_number'],
      displayName: json['display_name'] ?? '',
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
      vendorLanguage: json['vendor_language'],
      gstTreatment: json['gst_treatment'],
      gstin: json['gstin'],
      sourceOfSupply: json['source_of_supply'],
      pan: json['pan'],
      // taxPreference: json['tax_preference'],
      // exemptionReason: json['exemption_reason'],
      // drugLicenseNo: json['drug_license_no'],
      isDrugRegistered: json['is_drug_registered'] ?? false,
      drugLicenceType: json['drug_licence_type'],
      drugLicense20: json['drug_license_20'],
      drugLicense21: json['drug_license_21'],
      drugLicense20b: json['drug_license_20b'],
      drugLicense21b: json['drug_license_21b'],
      isFssaiRegistered: json['is_fssai_registered'] ?? false,
      fssaiNumber: json['fssai_number'],
      isMsmeRegistered: json['is_msme_registered'] ?? false,
      msmeRegistrationType: json['msme_registration_type'],
      msmeRegistrationNumber: json['msme_registration_number'],
      tdsRateId: json['tds_rate_id'],
      priceListId: json['price_list_id'],
      currency: json['currency'],
      paymentTerms: json['payment_terms'],
      // priceList: json['price_list'],
      remarks: json['remarks'],
      xHandle: json['x_handle'],
      facebookHandle: json['facebook_handle'],
      whatsappNumber: json['whatsapp_number'],
      source: json['source'] ?? 'User',
      billingAddress: _extractAddress(json, isBilling: true),
      shippingAddress: _extractAddress(json, isBilling: false),
      contactPersons: (json['vendor_contact_persons'] as List?)
          ?.map(
            (i) => {
              'salutation': i['salutation'],
              'firstName': i['first_name'] ?? i['firstName'],
              'lastName': i['last_name'] ?? i['lastName'],
              'email': i['email'],
              'workPhone': i['work_phone'] ?? i['workPhone'],
              'mobilePhone': i['mobile_phone'] ?? i['mobilePhone'],
              'designation': i['designation'],
              'department': i['department'],
            },
          )
          .toList(),
      bankDetails: (json['vendor_bank_accounts'] as List?)
          ?.map(
            (i) => {
              'holderName': i['holder_name'] ?? i['holderName'],
              'bankName': i['bank_name'] ?? i['bankName'],
              'accountNumber': i['account_number'] ?? i['accountNumber'],
              'ifsc': i['ifsc'],
            },
          )
          .toList(),
      enablePortal: json['enable_portal'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  static Map<String, dynamic>? _extractAddress(
    Map<String, dynamic> json, {
    required bool isBilling,
  }) {
    final prefix = isBilling ? 'billing_' : 'shipping_';

    // Check if at least one field is non-null
    if (json['${prefix}attention'] == null &&
        json['${prefix}address_street_1'] == null) {
      return null;
    }

    return {
      'attention': json['${prefix}attention'],
      'street1': json['${prefix}address_street_1'],
      'street2': json['${prefix}address_street_2'],
      'city': json['${prefix}city'],
      'state': json['${prefix}state'],
      'zip': json['${prefix}pincode'],
      'country': json['${prefix}country_region'],
      'phone': json['${prefix}phone'],
      'fax': json['${prefix}fax'],
    };
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'displayName': displayName,
      'isDrugRegistered': isDrugRegistered ?? false,
      'isFssaiRegistered': isFssaiRegistered ?? false,
      'isMsmeRegistered': isMsmeRegistered ?? false,
      'enablePortal': enablePortal ?? false,
      'isActive': isActive,
      'source': source ?? 'User',
    };

    void addIfNotEmpty(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        String cleanValue = value.trim();
        // Specifically for email, ensure no spaces (fixes potential web browser duplication/autofill bugs)
        if (key == 'email') {
          cleanValue = cleanValue.split(' ').first;
        }
        data[key] = cleanValue;
      }
    }

    addIfNotEmpty('vendorNumber', vendorNumber);
    // addIfNotEmpty('vendorType', vendorType);
    addIfNotEmpty('salutation', salutation);
    addIfNotEmpty('firstName', firstName);
    addIfNotEmpty('lastName', lastName);
    addIfNotEmpty('companyName', companyName);
    addIfNotEmpty('email', email);
    addIfNotEmpty('phone', phone);
    addIfNotEmpty('mobilePhone', mobilePhone);
    addIfNotEmpty('designation', designation);
    addIfNotEmpty('department', department);
    addIfNotEmpty('website', website);
    addIfNotEmpty('vendorLanguage', vendorLanguage);
    addIfNotEmpty('gstTreatment', gstTreatment);
    addIfNotEmpty('gstin', gstin);
    addIfNotEmpty('sourceOfSupply', sourceOfSupply);
    addIfNotEmpty('pan', pan);
    // addIfNotEmpty('taxPreference', taxPreference);
    // addIfNotEmpty('exemptionReason', exemptionReason);
    // addIfNotEmpty('drugLicenseNo', drugLicenseNo);
    addIfNotEmpty('drugLicenceType', drugLicenceType);
    addIfNotEmpty('drugLicense20', drugLicense20);
    addIfNotEmpty('drugLicense21', drugLicense21);
    addIfNotEmpty('drugLicense20b', drugLicense20b);
    addIfNotEmpty('drugLicense21b', drugLicense21b);
    addIfNotEmpty('fssaiNumber', fssaiNumber);
    addIfNotEmpty('msmeRegistrationType', msmeRegistrationType);
    addIfNotEmpty('msmeRegistrationNumber', msmeRegistrationNumber);
    addIfNotEmpty('currency', currency);
    addIfNotEmpty('paymentTerms', paymentTerms);
    // addIfNotEmpty('priceListId', priceList);
    addIfNotEmpty('tdsRateId', tdsRateId);
    addIfNotEmpty('priceListId', priceListId);
    addIfNotEmpty('remarks', remarks);
    addIfNotEmpty('xHandle', xHandle);
    addIfNotEmpty('facebookHandle', facebookHandle);
    addIfNotEmpty('whatsappNumber', whatsappNumber);

    if (billingAddress != null) {
      data['billingAddress'] = billingAddress;
    }
    if (shippingAddress != null) {
      data['shippingAddress'] = shippingAddress;
    }
    if (contactPersons != null && contactPersons!.isNotEmpty) {
      data['contactPersons'] = contactPersons;
    }
    if (bankDetails != null && bankDetails!.isNotEmpty) {
      data['bankDetails'] = bankDetails;
    }

    return data;
  }
}
