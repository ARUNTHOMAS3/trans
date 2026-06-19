class PurchasesBill {
  final String id;
  final String? billNumber;
  final String vendorId;
  final String vendorName;
  final String? placeOfSupply;
  final String? vendorNumber;
  final String? orderNumber; // reference PO number
  final DateTime? billDate;
  final DateTime? dueDate;
  final String? paymentTerms;
  final bool isReverseCharge;
  final String? subject;
  final String? warehouseId;
  final String? warehouseName;
  final String taxLevel; // 'transaction' or 'item'
  final List<PurchasesBillLineItem> lineItems;
  final double subTotal;
  final double discountPercent;
  final double discountAmount;
  final String tdsOrTcs; // 'tds' or 'tcs'
  final String? taxId;
  final String? taxName;
  final double taxAmount;
  final String? adjustmentLabel;
  final double adjustment;
  final double total;
  final double tdsTotal;
  final double tcsTotal;
  final String? notes;
  final List<String> attachmentUrls;
  final String status; // 'draft', 'open', 'paid', 'overdue', 'void'
  final String? pdfTemplate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? vendorAddress;
  final String? vendorPhone;
  final String? vendorGstin;
  final String? reasonToVoid;
  final String? reasonToDraft;
  final String? sourceOfSupply;
  final String? destinationToSupply;
  final String? billingAddress;

  PurchasesBill({
    required this.id,
    this.billNumber,
    required this.vendorId,
    required this.vendorName,
    this.placeOfSupply,
    this.sourceOfSupply,
    this.destinationToSupply,
    this.billingAddress,
    this.vendorNumber,
    this.orderNumber,
    this.billDate,
    this.dueDate,
    this.paymentTerms,
    this.isReverseCharge = false,
    this.subject,
    this.warehouseId,
    this.warehouseName,
    this.taxLevel = 'transaction',
    this.lineItems = const [],
    this.subTotal = 0,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.tdsOrTcs = 'tds',
    this.taxId,
    this.taxName,
    this.taxAmount = 0,
    this.adjustmentLabel = 'Adjustment',
    this.adjustment = 0,
    this.total = 0,
    this.tdsTotal = 0,
    this.tcsTotal = 0,
    this.notes,
    this.attachmentUrls = const [],
    this.status = 'draft',
    this.pdfTemplate,
    this.createdAt,
    this.updatedAt,
    this.vendorAddress,
    this.vendorPhone,
    this.vendorGstin,
    this.reasonToVoid,
    this.reasonToDraft,
  });

  factory PurchasesBill.fromJson(Map<String, dynamic> json) {
    final vendorData = json['vendor'] as Map<String, dynamic>?;
    String? vendorAddress;
    String? vendorPhone;
    if (vendorData != null) {
      final attention = vendorData['billing_attention'] as String? ?? vendorData['billingAttention'] as String?;
      final street = vendorData['billing_address_street'] as String? ?? vendorData['billingAddressStreet'] as String?;
      final place = vendorData['billing_address_place'] as String? ?? vendorData['billingAddressPlace'] as String?;
      final city = vendorData['billing_city'] as String? ?? vendorData['billingCity'] as String?;
      final state = vendorData['billing_state'] as String? ?? vendorData['billingState'] as String?;
      final zip = vendorData['billing_pincode'] as String? ?? vendorData['billingPincode'] as String?;
      final country = vendorData['billing_country_region'] as String? ?? vendorData['billingCountryRegion'] as String?;
      vendorPhone = vendorData['phone'] as String? ?? vendorData['mobile_phone'] as String? ?? vendorData['billing_phone'] as String? ?? vendorData['billingPhone'] as String? ?? vendorData['mobilePhone'] as String?;

      final List<String> addrParts = [];
      if (attention != null && attention.trim().isNotEmpty) addrParts.add(attention.trim());
      if (street != null && street.trim().isNotEmpty) addrParts.add(street.trim());
      if (place != null && place.trim().isNotEmpty) addrParts.add(place.trim());
      
      String cityState = '';
      if (city != null && city.trim().isNotEmpty) {
        cityState = city.trim();
      }
      if (state != null && state.trim().isNotEmpty) {
        if (cityState.isNotEmpty) {
          cityState += ', ${state.trim()}';
        } else {
          cityState = state.trim();
        }
      }
      if (cityState.isNotEmpty) {
        addrParts.add(cityState);
      }

      String countryZip = '';
      if (country != null && country.trim().isNotEmpty) {
        countryZip = country.trim();
      }
      if (zip != null && zip.trim().isNotEmpty) {
        if (countryZip.isNotEmpty) {
          countryZip += ' - ${zip.trim()}';
        } else {
          countryZip = zip.trim();
        }
      }
      if (countryZip.isNotEmpty) {
        addrParts.add(countryZip);
      }
      
      if (addrParts.isNotEmpty) {
        vendorAddress = addrParts.join('\n');
      }
    }

    return PurchasesBill(
      id: json['id'] ?? '',
      billNumber: json['bill_number'],
      vendorId: json['vendor_id'] ?? '',
      vendorName: vendorData?['display_name'] as String? ??
          vendorData?['company_name'] as String? ??
          json['vendor_name'] as String? ??
          '',
      placeOfSupply: json['place_of_supply'] ?? json['placeOfSupply'],
      vendorNumber: json['vendor_number'],
      orderNumber: json['order_number'],
      billDate: json['bill_date'] != null
          ? DateTime.tryParse(json['bill_date'])
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'])
          : null,
      paymentTerms: json['payment_terms'] is Map
          ? (json['payment_terms']['term_name'] ?? json['payment_terms']['termName'])
          : json['payment_terms'],
      isReverseCharge: json['is_reverse_charge'] ?? false,
      subject: json['subject'],
      warehouseId: json['warehouse_id'],
      warehouseName: json['warehouse_name'] ??
          (json['warehouse'] != null ? json['warehouse']['name'] : null),
      taxLevel: json['tax_level'] ?? 'transaction',
      lineItems:
          (json['line_items'] as List<dynamic>?)
              ?.map((e) => PurchasesBillLineItem.fromJson(e))
              .toList() ??
          [],
      subTotal: _parseDouble(json['sub_total'] ?? json['subtotal'] ?? 0),
      discountPercent: _parseDouble(json['discount_percent'] ?? 0),
      discountAmount: _parseDouble(json['discount_amount'] ?? json['discount_total'] ?? 0),
      tdsOrTcs: json['tds_or_tcs'] ?? 'tds',
      taxId: json['tax_id'],
      taxName: json['tax_name'],
      taxAmount: _parseDouble(json['tax_amount'] ?? json['tax_total'] ?? 0),
      adjustmentLabel: json['adjustment_label'] ?? 'Adjustment',
      adjustment: _parseDouble(json['adjustment'] ?? json['adjustment_amount'] ?? 0),
      total: _parseDouble(json['total'] ?? json['grand_total'] ?? 0),
      tdsTotal: _parseDouble(json['tds_total'] ?? json['tdsTotal'] ?? 0),
      tcsTotal: _parseDouble(json['tcs_total'] ?? json['tcsTotal'] ?? 0),
      notes: json['notes'],
      attachmentUrls:
          (json['attachment_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      status: json['status'] ?? 'draft',
      pdfTemplate: json['pdf_template'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      vendorAddress: vendorAddress,
      vendorPhone: vendorPhone,
      vendorGstin: vendorData?['gstin'] as String? ?? json['vendor_gstin'] as String? ?? json['vendorGstin'] as String?,
      reasonToVoid: json['reason_to_void'] ?? json['reasonToVoid'],
      reasonToDraft: json['reason_to_draft'] ?? json['reasonToDraft'],
      sourceOfSupply: json['source_of_supply'] ?? json['sourceOfSupply'],
      destinationToSupply: json['destination_to_supply'] ?? json['destinationToSupply'],
      billingAddress: json['billing_address'] ?? json['billingAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (billNumber != null) 'billNumber': billNumber,
      'vendorId': vendorId,
      'vendorName': vendorName,
      if (placeOfSupply != null && placeOfSupply!.isNotEmpty)
        'placeOfSupply': placeOfSupply,
      if (sourceOfSupply != null) 'sourceOfSupply': sourceOfSupply,
      if (destinationToSupply != null) 'destinationToSupply': destinationToSupply,
      if (billingAddress != null) 'billingAddress': billingAddress,
      if (vendorNumber != null) 'vendorNumber': vendorNumber,
      if (orderNumber != null) 'orderNumber': orderNumber,
      if (billDate != null)
        'billDate': billDate!.toIso8601String().split('T').first,
      if (dueDate != null)
        'dueDate': dueDate!.toIso8601String().split('T').first,
      if (paymentTerms != null) 'paymentTerms': paymentTerms,
      'isReverseCharge': isReverseCharge,
      if (subject != null) 'subject': subject,
      if (warehouseId != null) 'warehouseId': warehouseId,
      'taxLevel': taxLevel,
      'lineItems': lineItems.map((e) => e.toJson()).toList(),
      'subTotal': subTotal,
      'discountPercent': discountPercent,
      'discountAmount': discountAmount,
      'tdsOrTcs': tdsOrTcs,
      if (taxId != null) 'taxId': taxId,
      'taxAmount': taxAmount,
      'adjustmentLabel': adjustmentLabel ?? 'Adjustment',
      'adjustment': adjustment,
      'total': total,
      'tdsTotal': tdsTotal,
      'tcsTotal': tcsTotal,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'attachmentUrls': attachmentUrls,
      'status': status,
      if (vendorGstin != null) 'vendorGstin': vendorGstin,
      if (reasonToVoid != null) 'reasonToVoid': reasonToVoid,
      if (reasonToDraft != null) 'reasonToDraft': reasonToDraft,
    };
  }
}

class PurchasesBillLineItem {
  final String? id;
  final String? itemId;
  final String? itemName;
  final String? hsnCode;
  final String? description;
  final String? itemImageUrl;
  final String? batch;
  final String? unitPack;
  final DateTime? expiry;
  final double mrp;
  final double ptr;
  final double freeQuantity;
  final String? accountId;
  final String? accountName;
  final double quantity;
  final double rate;
  final String? taxId;
  final String? taxName;
  final double taxAmount;
  final String? customerId; // Customer Details column
  final String? customerName;
  final double discount;
  final String discountType; // '%' or '₹'
  final double amount;
  final bool isLandedCost;
  final List<dynamic>? batches;
  final bool trackBatches;
  final bool trackSerialNumber;
  final bool trackBinLocation;

  PurchasesBillLineItem({
    this.id,
    this.itemId,
    this.itemName,
    this.hsnCode,
    this.description,
    this.itemImageUrl,
    this.batch,
    this.unitPack,
    this.expiry,
    this.mrp = 0,
    this.ptr = 0,
    this.freeQuantity = 0,
    this.accountId,
    this.accountName,
    this.quantity = 1,
    this.rate = 0,
    this.taxId,
    this.taxName,
    this.taxAmount = 0,
    this.customerId,
    this.customerName,
    this.discount = 0,
    this.discountType = '%',
    this.amount = 0,
    this.isLandedCost = false,
    this.batches,
    this.trackBatches = false,
    this.trackSerialNumber = false,
    this.trackBinLocation = false,
  });

  double get computedAmount {
    double base = quantity * rate;
    if (discountType == '%') {
      return base - (base * discount / 100);
    }
    return base - discount;
  }

  factory PurchasesBillLineItem.fromJson(Map<String, dynamic> json) {
    final productData = json['product'] as Map<String, dynamic>? ?? 
                        json['products'] as Map<String, dynamic>?;
    final accountData = json['account'] as Map<String, dynamic>?;
    final customerData = json['customer'] as Map<String, dynamic>?;

    return PurchasesBillLineItem(
      id: json['id'],
      itemId: json['item_id'] ?? json['product_id'],
      itemName: productData?['product_name'] as String? ?? 
                productData?['productName'] as String? ?? 
                productData?['name'] as String? ?? 
                json['item_name'] as String?,
      hsnCode: productData?['hsn_code']?.toString() ?? json['hsn_code']?.toString(),
      description: json['description'],
      itemImageUrl: productData?['image_url'] as String? ?? json['item_image_url'] as String?,
      batch: json['batch'],
      unitPack: json['unit_pack'],
      expiry: json['expiry'] != null ? DateTime.tryParse(json['expiry']) : null,
      mrp: _parseDouble(json['mrp'] ?? 0),
      ptr: _parseDouble(json['ptr'] ?? 0),
      freeQuantity: _parseDouble(json['free_quantity'] ?? 0),
      accountId: json['account_id'] ?? json['accountId'],
      accountName: accountData?['user_account_name'] as String? ??
                  accountData?['system_account_name'] as String? ??
                  json['account_name'] as String?,
      quantity: _parseDouble(json['quantity'] ?? 1),
      rate: _parseDouble(json['rate'] ?? 0),
      taxId: json['tax_id'],
      taxName: json['tax_name'],
      taxAmount: _parseDouble(json['tax_amount'] ?? 0),
      customerId: json['customer_id'] ?? json['customerId'],
      customerName: customerData?['display_name'] as String? ?? json['customer_name'] as String?,
      discount: _parseDouble(json['discount'] ?? 0),
      discountType: json['discount_type'] ?? '%',
      amount: _parseDouble(json['amount'] ?? 0),
      isLandedCost: json['is_landed_cost'] ?? false,
      batches: json['batches'] as List<dynamic>?,
      trackBatches: productData?['track_batches'] as bool? ?? json['track_batches'] as bool? ?? false,
      trackSerialNumber: productData?['track_serial_number'] as bool? ?? json['track_serial_number'] as bool? ?? false,
      trackBinLocation: productData?['track_bin_location'] as bool? ?? json['track_bin_location'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (itemName != null) 'item_name': itemName,
      if (hsnCode != null) 'hsn_code': hsnCode,
      if (description != null) 'description': description,
      if (batch != null) 'batch': batch,
      if (unitPack != null) 'unit_pack': unitPack,
      if (expiry != null) 'expiry': expiry!.toIso8601String(),
      'mrp': mrp,
      'ptr': ptr,
      'free_quantity': freeQuantity,
      if (accountId != null) 'account_id': accountId,
      'quantity': quantity,
      'rate': rate,
      if (taxId != null) 'tax_id': taxId,
      'tax_amount': taxAmount,
      if (customerId != null) 'customer_id': customerId,
      'discount': discount,
      'discount_type': discountType,
      'amount': computedAmount,
      'is_landed_cost': isLandedCost,
      if (batches != null) 'batches': batches,
      'track_batches': trackBatches,
      'track_serial_number': trackSerialNumber,
      'track_bin_location': trackBinLocation,
    };
  }

  PurchasesBillLineItem copyWith({
    String? itemId,
    String? itemName,
    String? hsnCode,
    String? description,
    String? itemImageUrl,
    String? batch,
    String? unitPack,
    DateTime? expiry,
    double? mrp,
    double? ptr,
    double? freeQuantity,
    String? accountId,
    String? accountName,
    double? quantity,
    double? rate,
    String? taxId,
    String? taxName,
    double? taxAmount,
    String? customerId,
    String? customerName,
    double? discount,
    String? discountType,
    bool? isLandedCost,
    List<dynamic>? batches,
    bool? trackBatches,
    bool? trackSerialNumber,
    bool? trackBinLocation,
  }) {
    return PurchasesBillLineItem(
      id: id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      hsnCode: hsnCode ?? this.hsnCode,
      description: description ?? this.description,
      itemImageUrl: itemImageUrl ?? this.itemImageUrl,
      batch: batch ?? this.batch,
      unitPack: unitPack ?? this.unitPack,
      expiry: expiry ?? this.expiry,
      mrp: mrp ?? this.mrp,
      ptr: ptr ?? this.ptr,
      freeQuantity: freeQuantity ?? this.freeQuantity,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      taxId: taxId ?? this.taxId,
      taxName: taxName ?? this.taxName,
      taxAmount: taxAmount ?? this.taxAmount,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      amount: 0, // Recalculated by computedAmount
      isLandedCost: isLandedCost ?? this.isLandedCost,
      batches: batches ?? this.batches,
      trackBatches: trackBatches ?? this.trackBatches,
      trackSerialNumber: trackSerialNumber ?? this.trackSerialNumber,
      trackBinLocation: trackBinLocation ?? this.trackBinLocation,
    );
  }
}

double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}
