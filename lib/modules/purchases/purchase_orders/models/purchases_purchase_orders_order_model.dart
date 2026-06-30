// FILE: lib/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart
import '../../vendors/models/purchases_vendors_vendor_model.dart';

class PurchaseOrderItem {
  final String? id;
  final String productId;
  final String? productName; // local display only
  final String? hsnCode; // local display only
  final String? itemCode; // local display only
  final String? description;
  final String? accountId;
  final String? accountName;
  final double quantity;
  final double cancelledQuantity;
  final double rate;
  final String? taxId;
  final String? taxName;
  final double taxRate;
  final double taxAmount;
  final String? discountAccountId;
  final String? discountAccountName;
  final double discount;
  final String discountType; // 'percentage' | 'fixed'
  final double amount;
  final String? productType; // 'goods' or 'service'
  final double? availableStock; // Available for Sale in selected warehouse
  final double? stockOnHand; // Stock on Hand in selected warehouse
  final String? priceListId; // Selected price list ID
  final String? pricelist;
  final String? warehouseId;
  final String? warehouseName;
  final bool isHeader;
  final String? headerText;
  final bool trackBatches;
  final bool trackSerialNumber;
  final bool trackBinLocation;

  PurchaseOrderItem({
    this.id,
    required this.productId,
    this.productName,
    this.hsnCode,
    this.itemCode,
    this.description,
    this.accountId,
    this.accountName,
    this.discountAccountId,
    this.discountAccountName,
    required this.quantity,
    this.cancelledQuantity = 0.0,
    required this.rate,
    this.taxId,
    this.taxName,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.discount = 0.0,
    this.discountType = 'percentage',
    required this.amount,
    this.productType,
    this.availableStock,
    this.stockOnHand,
    this.priceListId,
    this.pricelist,
    this.warehouseId,
    this.warehouseName,
    this.isHeader = false,
    this.headerText,
    this.trackBatches = false,
    this.trackSerialNumber = false,
    this.trackBinLocation = false,
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    final productData = json['product'] as Map<String, dynamic>? ?? 
                        json['products'] as Map<String, dynamic>?;
    
    return PurchaseOrderItem(
      id: json['id'] as String?,
      productId: json['productId'] as String? ?? json['product_id'] as String? ?? '',
      productName: productData?['product_name'] as String? ?? 
                   productData?['productName'] as String? ?? 
                   productData?['name'] as String? ?? 
                   json['product_name'] as String? ?? 
                   json['productName'] as String?,
      itemCode: productData?['sku'] as String? ?? json['item_code'] as String?,
      hsnCode: productData?['hsn_code']?.toString() ?? json['hsn_code']?.toString(),
      description: json['description'] as String?,
      accountId: json['accountId'] as String? ?? json['account_id'] as String? ?? json['accounts'] as String?,
      quantity: double.tryParse(json['quantity']?.toString() ?? '1.0') ?? 1.0,
      cancelledQuantity: double.tryParse(json['cancelledQuantity']?.toString() ?? json['cancelled_quantity']?.toString() ?? '0.0') ?? 0.0,
      rate: double.tryParse(json['rate']?.toString() ?? '0.0') ?? 0.0,
      taxId: json['taxId'] as String? ?? json['tax_id'] as String?,
      taxRate: double.tryParse(json['itemTaxRate']?.toString() ?? json['tax_rate']?.toString() ?? '0.0') ?? 0.0,
      taxAmount: double.tryParse(json['taxAmount']?.toString() ?? json['tax_amount']?.toString() ?? '0.0') ?? 0.0,
      discountAccountId: json['discount_account_id'] as String?,
      discount: double.tryParse(json['discount']?.toString() ?? '0.0') ?? 0.0,
      discountType: json['discountType'] as String? ?? json['discount_type'] as String? ?? 'percentage',
      amount: double.tryParse(json['amount']?.toString() ?? '0.0') ?? 0.0,
      isHeader: json['is_header'] as bool? ?? false,
      headerText: json['header_text'] as String?,
      pricelist: json['pricelist'] as String?,
      warehouseId: json['warehouse_id'] as String? ?? json['warehouseId'] as String?,
      warehouseName: json['warehouse_name'] as String? ?? json['warehouseName'] as String?,
      trackBatches: productData?['track_batches'] as bool? ?? json['track_batches'] as bool? ?? false,
      trackSerialNumber: productData?['track_serial_number'] as bool? ?? json['track_serial_number'] as bool? ?? false,
      trackBinLocation: productData?['track_bin_location'] as bool? ?? json['track_bin_location'] as bool? ?? false,
      productType: json['product_type'] as String? ?? json['productType'] as String? ?? productData?['type'] as String? ?? productData?['product_type'] as String? ?? productData?['productType'] as String? ?? 'goods',
    );
  }

  Map<String, dynamic> toJson({int? index}) {
    return {
      'product_id': productId.isEmpty || productId == '__header__' ? null : productId,
      if (description != null) 'description': description,
      if (accountId != null) 'account_id': accountId,
      if (accountId != null) 'accounts': accountId,
      'quantity': quantity,
      'cancelled_quantity': cancelledQuantity,
      'rate': rate,
      if (taxId != null) 'tax_id': taxId,
      'item_tax_rate': taxRate,
      'tax_amount': taxAmount,
      'discount': discount,
      'discount_type': discountType,
      'amount': amount,
      if (pricelist != null) 'pricelist': pricelist,
      if (hsnCode != null) 'hsn_code': hsnCode,
      'is_header': isHeader,
      if (headerText != null) 'header_text': headerText,
      if (index != null) 'sort_order': index,
      'track_batches': trackBatches,
      'track_serial_number': trackSerialNumber,
      'track_bin_location': trackBinLocation,
    };
  }

  PurchaseOrderItem copyWith({
    String? productId,
    String? productName,
    String? hsnCode,
    String? itemCode,
    String? description,
    String? accountId,
    String? accountName,
    String? discountAccountId,
    String? discountAccountName,
    double? quantity,
    double? cancelledQuantity,
    double? rate,
    String? taxId,
    String? taxName,
    double? taxRate,
    double? taxAmount,
    double? discount,
    String? discountType,
    double? amount,
    String? productType,
    double? availableStock,
    double? stockOnHand,
    String? priceListId,
    String? pricelist,
    String? warehouseId,
    String? warehouseName,
    bool? isHeader,
    String? headerText,
    bool? trackBatches,
    bool? trackSerialNumber,
    bool? trackBinLocation,
  }) {
    return PurchaseOrderItem(
      id: id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      hsnCode: hsnCode ?? this.hsnCode,
      itemCode: itemCode ?? this.itemCode,
      description: description ?? this.description,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      discountAccountId: discountAccountId ?? this.discountAccountId,
      discountAccountName: discountAccountName ?? this.discountAccountName,
      quantity: quantity ?? this.quantity,
      cancelledQuantity: cancelledQuantity ?? this.cancelledQuantity,
      rate: rate ?? this.rate,
      taxId: taxId ?? this.taxId,
      taxName: taxName ?? this.taxName,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      amount: amount ?? this.amount,
      productType: productType ?? this.productType,
      availableStock: availableStock ?? this.availableStock,
      stockOnHand: stockOnHand ?? this.stockOnHand,
      priceListId: priceListId ?? this.priceListId,
      pricelist: pricelist ?? this.pricelist,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      isHeader: isHeader ?? this.isHeader,
      headerText: headerText ?? this.headerText,
      trackBatches: trackBatches ?? this.trackBatches,
      trackSerialNumber: trackSerialNumber ?? this.trackSerialNumber,
      trackBinLocation: trackBinLocation ?? this.trackBinLocation,
    );
  }

  PurchaseOrderItem clearTax() {
    return PurchaseOrderItem(
      id: id,
      productId: productId,
      productName: productName,
      hsnCode: hsnCode,
      itemCode: itemCode,
      description: description,
      accountId: accountId,
      accountName: accountName,
      discountAccountId: discountAccountId,
      discountAccountName: discountAccountName,
      quantity: quantity,
      cancelledQuantity: cancelledQuantity,
      rate: rate,
      taxId: null,
      taxName: null,
      taxRate: 0.0,
      taxAmount: 0.0,
      discount: discount,
      discountType: discountType,
      amount: amount,
      productType: productType,
      availableStock: availableStock,
      stockOnHand: stockOnHand,
      priceListId: priceListId,
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      isHeader: isHeader,
      headerText: headerText,
      trackBatches: trackBatches,
      trackSerialNumber: trackSerialNumber,
      trackBinLocation: trackBinLocation,
    );
  }

  PurchaseOrderItem clearPriceList() {
    return PurchaseOrderItem(
      id: id,
      productId: productId,
      productName: productName,
      hsnCode: hsnCode,
      itemCode: itemCode,
      description: description,
      accountId: accountId,
      accountName: accountName,
      discountAccountId: discountAccountId,
      discountAccountName: discountAccountName,
      quantity: quantity,
      cancelledQuantity: cancelledQuantity,
      rate: rate,
      taxId: taxId,
      taxName: taxName,
      taxRate: taxRate,
      taxAmount: taxAmount,
      discount: discount,
      discountType: discountType,
      amount: amount,
      productType: productType,
      availableStock: availableStock,
      stockOnHand: stockOnHand,
      priceListId: null,
      pricelist: null,
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      isHeader: isHeader,
      headerText: headerText,
      trackBatches: trackBatches,
      trackSerialNumber: trackSerialNumber,
      trackBinLocation: trackBinLocation,
    );
  }
}

class PurchaseOrder {
  final String? id;
  final String? orgId;
  final String? branchId;
  final String orderNumber;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final String? referenceNumber;
  final String vendorId;
  final String? vendorName;
  final String? paymentTerms;
  final String? paymentTermsName;
  final String? shipmentPreference;
  final String deliveryType; // 'warehouse' | 'customer'
  final String? deliveryWarehouseId;
  final String? deliveryCustomerId;
  final String? warehouseId;
  final String? warehouseName;
  final double subTotal;
  final double taxAmount;
  final double discount;
  final String discountType; // 'percentage' | 'fixed'
  final String? tdsTcsType; // 'tds' | 'tcs' | 'none'
  final String? tdsTcsId;
  final double adjustment;
  final double total;
  final String status;
  final String? notes;
  final String? termsAndConditions;
  final String discountLevel; // 'transaction' | 'item'
  final String? discountAccountId;
  final String? discountAccountName;
  final Vendor? vendor;
  final List<PurchaseOrderItem> items;
  final double totalQuantity;
  final String currency;
  final String taxType;
  final double tdsTcsAmount;
  final bool isReverseCharge;
  final bool isDelete;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? receiveStatus;
  final String? billStatus;
  final String? sourceOfSupply;
  final String? destinationToSupply;
  final String? shippingAddressId;
  final String? billingAddressId;

  PurchaseOrder({
    this.id,
    this.orgId,
    this.branchId,
    required this.orderNumber,
    required this.orderDate,
    this.expectedDeliveryDate,
    this.referenceNumber,
    required this.vendorId,
    this.vendorName,
    this.paymentTerms,
    this.paymentTermsName,
    this.shipmentPreference,
    this.deliveryType = 'warehouse',
    this.deliveryWarehouseId,
    this.deliveryCustomerId,
    this.warehouseId,
    this.warehouseName,
    this.subTotal = 0.0,
    this.taxAmount = 0.0,
    this.discount = 0.0,
    this.discountType = 'percentage',
    this.tdsTcsType = 'none',
    this.tdsTcsId,
    this.adjustment = 0.0,
    this.total = 0.0,
    this.status = 'Draft',
    this.notes,
    this.termsAndConditions,
    this.discountLevel = 'transaction',
    this.discountAccountId,
    this.discountAccountName,
    this.vendor,
    this.items = const [],
    this.totalQuantity = 0.0,
    this.currency = 'INR',
    this.taxType = 'exclusive',
    this.tdsTcsAmount = 0.0,
    this.isReverseCharge = false,
    this.isDelete = false,
    this.createdAt,
    this.updatedAt,
    this.receiveStatus = 'none',
    this.billStatus = 'none',
    this.sourceOfSupply,
    this.destinationToSupply,
    this.shippingAddressId,
    this.billingAddressId,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? 
                    json['purchases_purchase_order_items'] as List<dynamic>? ??
                    json['purchase_order_items'] as List<dynamic>? ?? 
                    [];
    return PurchaseOrder(
      id: _extractPurchaseOrderId(json),
      orgId: json['org_id'] as String?,
      branchId: json['branch_id'] as String?,
      orderNumber: json['order_number'] as String? ?? '',
      orderDate: json['order_date'] != null
          ? DateTime.tryParse(json['order_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.tryParse(json['expected_delivery_date'] as String)
          : null,
      referenceNumber: json['reference_number'] as String?,
      vendorId: json['vendor_id'] as String? ?? '',
      vendorName: json['vendor']?['display_name'] as String?,
      paymentTerms: json['payment_terms_id'] as String? ?? json['payment_terms'] as String?,
      paymentTermsName: json['payment_term']?['term_name'] as String? ?? json['payment_terms'] as String?,
      shipmentPreference: json['shipment_preference_id'] as String? ?? json['shipment_preference'] as String?,
      deliveryType: json['delivery_type'] as String? ?? 'warehouse',
      deliveryWarehouseId: json['delivery_warehouse_id'] as String?,
      deliveryCustomerId: json['delivery_customer_id'] as String?,
      warehouseId: (json['warehouse_id'] ??
              json['delivery_warehouse_id'] ??
              json['warehouse']?['id'] ??
              json['warehouses']?['id'] ??
              json['branch_id'] ??
              json['branchId'])
          ?.toString(),
      warehouseName: json['warehouse_name'] as String? ??
          json['warehouse']?['name'] as String? ??
          json['warehouses']?['name'] as String? ??
          json['delivery_warehouse_name'] as String?,
      subTotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      discountType: json['discount_type'] as String? ?? 'percentage',
      tdsTcsType: json['tds_tcs_type'] as String? ?? 'none',
      tdsTcsId: json['tds_tcs_id'] as String? ?? json['tds_id'] as String?,
      adjustment: double.tryParse(json['adjustment']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      status: json['status'] as String? ?? 'Draft',
      notes: json['notes'] as String?,
      termsAndConditions: json['terms_and_conditions'] as String?,
      discountLevel: json['discount_level'] as String? ?? 'transaction',
      discountAccountId: json['discount_account_id'] as String?,
      totalQuantity: (json['total_quantity'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      taxType: json['tax_type'] as String? ?? 'exclusive',
      tdsTcsAmount: (json['tds_tcs_amount'] as num?)?.toDouble() ?? 0.0,
      isReverseCharge: json['is_reverse_charge'] as bool? ?? false,
      isDelete: json['is_delete'] as bool? ?? false,
      vendor: json['vendor'] != null ? Vendor.fromJson(json['vendor'] as Map<String, dynamic>) : null,
      items: rawItems
          .map((e) => PurchaseOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      receiveStatus: json['receive_status'] as String? ?? 'none',
      billStatus: json['bill_status'] as String? ?? 'none',
      sourceOfSupply: json['source_of_supply'] as String?,
      destinationToSupply: json['destination_to_supply'] as String?,
      shippingAddressId: json['shipping_address'] as String?,
      billingAddressId: json['billing_address'] as String?,
    );
  }

  static String? _extractPurchaseOrderId(Map<String, dynamic> json) {
    final candidates = <dynamic>[
      json['id'],
      json['purchase_order_id'],
      json['po_id'],
      json['order_id'],
      json['purchaseOrderId'],
      (json['purchase_order'] as Map<String, dynamic>?)?['id'],
      (json['purchase_order'] as Map<String, dynamic>?)?['purchase_order_id'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim();
      if (value == null || value.isEmpty) continue;
      if (_isUuid(value)) return value;
    }
    return null;
  }

  static bool _isUuid(String value) {
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-'
      r'[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{12}$',
    );
    return uuid.hasMatch(value);
  }

  Map<String, dynamic> toJson() {
    return {
      if (orgId != null) 'org_id': orgId,
      if (branchId != null) 'branch_id': branchId,
      'vendor_id': vendorId,
      'order_number': orderNumber,
      'order_date': orderDate.toIso8601String().split('T').first,
      if (expectedDeliveryDate != null)
        'expected_delivery_date': expectedDeliveryDate!
            .toIso8601String()
            .split('T')
            .first,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (paymentTerms != null) 'payment_terms_id': paymentTerms,
      if (shipmentPreference != null) 'shipment_preference_id': shipmentPreference,
      'delivery_type': deliveryType,
      if (deliveryWarehouseId != null)
        'delivery_warehouse_id': deliveryWarehouseId,
      if (deliveryCustomerId != null)
        'delivery_customer_id': deliveryCustomerId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (warehouseName != null) 'warehouse_name': warehouseName,
      'status': status,
      'subtotal': subTotal,
      'tax_amount': taxAmount,
      'discount': discount,
      'discount_type': discountType,
      'tds_tcs_type': tdsTcsType,
      if (tdsTcsId != null) 'tds_tcs_id': tdsTcsId,
      if (tdsTcsId != null) 'tds_id': tdsTcsId,
      'adjustment': adjustment,
      'total': total,
      if (notes != null) 'notes': notes,
      if (termsAndConditions != null)
        'terms_and_conditions': termsAndConditions,
      'discount_level': discountLevel,
      if (discountAccountId != null) 'discount_account_id': discountAccountId,
      'total_quantity': totalQuantity,
      'currency': currency,
      'tax_type': taxType,
      if (tdsTcsAmount != 0) 'tds_tcs_amount': tdsTcsAmount,
      if (sourceOfSupply != null) 'source_of_supply': sourceOfSupply,
      if (destinationToSupply != null) 'destination_to_supply': destinationToSupply,
      if (shippingAddressId != null) 'shipping_address': shippingAddressId,
      if (billingAddressId != null) 'billing_address': billingAddressId,
      'items': items.asMap().entries.map((entry) => entry.value.toJson(index: entry.key)).toList(),
    };
  }

  PurchaseOrder copyWith({
    String? id,
    String? orgId,
    String? branchId,
    String? orderNumber,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
    String? referenceNumber,
    String? vendorId,
    String? vendorName,
    String? paymentTerms,
    String? paymentTermsName,
    String? shipmentPreference,
    String? deliveryType,
    String? deliveryWarehouseId,
    String? deliveryCustomerId,
    String? warehouseId,
    String? warehouseName,
    double? subTotal,
    double? taxAmount,
    double? discount,
    String? discountType,
    String? tdsTcsType,
    String? tdsTcsId,
    double? adjustment,
    double? total,
    String? status,
    String? notes,
    String? termsAndConditions,
    String? discountLevel,
    String? discountAccountId,
    String? discountAccountName,
    Vendor? vendor,
    List<PurchaseOrderItem>? items,
    double? totalQuantity,
    String? currency,
    String? taxType,
    double? tdsTcsAmount,
    bool? isDelete,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? receiveStatus,
    String? billStatus,
    String? sourceOfSupply,
    String? destinationToSupply,
    String? shippingAddressId,
    String? billingAddressId,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      branchId: branchId ?? this.branchId,
      orderNumber: orderNumber ?? this.orderNumber,
      orderDate: orderDate ?? this.orderDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      paymentTermsName: paymentTermsName ?? this.paymentTermsName,
      shipmentPreference: shipmentPreference ?? this.shipmentPreference,
      deliveryType: deliveryType ?? this.deliveryType,
      deliveryWarehouseId: deliveryWarehouseId ?? this.deliveryWarehouseId,
      deliveryCustomerId: deliveryCustomerId ?? this.deliveryCustomerId,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      subTotal: subTotal ?? this.subTotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discount: discount ?? this.discount,
      discountType: discountType ?? this.discountType,
      tdsTcsType: tdsTcsType ?? this.tdsTcsType,
      tdsTcsId: tdsTcsId ?? this.tdsTcsId,
      adjustment: adjustment ?? this.adjustment,
      total: total ?? this.total,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      discountAccountId: discountAccountId ?? this.discountAccountId,
      discountAccountName: discountAccountName ?? this.discountAccountName,
      vendor: vendor ?? this.vendor,
      items: items ?? this.items,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      currency: currency ?? this.currency,
      taxType: taxType ?? this.taxType,
      tdsTcsAmount: tdsTcsAmount ?? this.tdsTcsAmount,
      isDelete: isDelete ?? this.isDelete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      receiveStatus: receiveStatus ?? this.receiveStatus,
      billStatus: billStatus ?? this.billStatus,
      sourceOfSupply: sourceOfSupply ?? this.sourceOfSupply,
      destinationToSupply: destinationToSupply ?? this.destinationToSupply,
      shippingAddressId: shippingAddressId ?? this.shippingAddressId,
      billingAddressId: billingAddressId ?? this.billingAddressId,
    );
  }

  // Backward-compatible alias for code that has moved to outlet naming.
  String? get outletId => branchId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PurchaseOrder) return false;
    if (id != null && other.id != null) return id == other.id;
    return orderNumber == other.orderNumber;
  }

  @override
  int get hashCode {
    if (id != null) return id.hashCode;
    return orderNumber.hashCode;
  }
}

class WarehouseModel {
  final String id;
  final String? orgId;
  final String name;
  final String? attention;
  final String? addressStreet1;
  final String? addressStreet2;
  final String? city;
  final String? state;
  final String? zipCode;
  final String countryRegion;
  final String? phone;
  final String? email;
  final bool isActive;
  final String? locationType;
  final String? parentBranchId;
  final String? entityId;
  final bool isDefaultForBranch;

  WarehouseModel({
    required this.id,
    this.orgId,
    required this.name,
    this.attention,
    this.addressStreet1,
    this.addressStreet2,
    this.city,
    this.state,
    this.zipCode,
    required this.countryRegion,
    this.phone,
    this.email,
    this.isActive = true,
    this.locationType,
    this.parentBranchId,
    this.entityId,
    this.isDefaultForBranch = true,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    // Handle both legacy warehouses rows and settings_branches/settings_locations rows.
    return WarehouseModel(
      id: (json['id'] ?? '').toString(),
      orgId: (json['orgId'] ?? json['org_id'])?.toString(),
      name: (json['name'] ?? 'Unknown Warehouse').toString(),
      attention: json['attention']?.toString(),
      addressStreet1: (json['addressStreet1'] ??
              json['address_street_1'] ??
              json['address'])
          ?.toString(),
      addressStreet2: (json['addressStreet2'] ?? json['address_street_2'])?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      zipCode: (json['zipCode'] ?? json['zip_code'] ?? json['pincode'])?.toString(),
      countryRegion:
          (json['countryRegion'] ?? json['country_region'] ?? json['country'])
              ?.toString() ??
          'India',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      locationType: (json['locationType'] ?? json['location_type'])?.toString(),
      parentBranchId: (json['parentBranchId'] ?? json['parent_branch_id'] ?? json['branch_id'])?.toString(),
      entityId: (json['entity_id'] ?? json['entityId'])?.toString(),
      isDefaultForBranch: json['is_default_for_branch'] as bool? ?? json['isDefaultForBranch'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (orgId != null) 'org_id': orgId,
      'attention': attention,
      'address_street_1': addressStreet1,
      'address_street_2': addressStreet2,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country_region': countryRegion,
      'phone': phone,
      'email': email,
      'is_active': isActive,
      'location_type': locationType,
      'parent_branch_id': parentBranchId,
      'entity_id': entityId,
      'is_default_for_branch': isDefaultForBranch,
    };
  }


  String get displayAddress {
    final List<String> parts = [];
    if (addressStreet1 != null && addressStreet1!.isNotEmpty)
      parts.add(addressStreet1!);
    if (addressStreet2 != null && addressStreet2!.isNotEmpty)
      parts.add(addressStreet2!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (countryRegion.isNotEmpty) parts.add(countryRegion);
    if (zipCode != null && zipCode!.isNotEmpty) parts.add(zipCode!);
    return parts.join(', ');
  }

  // Backward-compatible alias for code that has moved to outlet naming.
  String? get parentOutletId => parentBranchId;
}
