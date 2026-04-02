// FILE: lib/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart

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
  final bool isHeader;
  final String? headerText;

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
    this.isHeader = false,
    this.headerText,
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) {
    final productData = json['product'] as Map<String, dynamic>? ?? 
                        json['products'] as Map<String, dynamic>?;
    
    return PurchaseOrderItem(
      id: json['id'] as String?,
      productId: json['product_id'] as String? ?? '',
      productName: productData?['product_name'] as String? ?? 
                   productData?['productName'] as String? ?? 
                   productData?['name'] as String? ?? 
                   json['product_name'] as String? ?? 
                   json['productName'] as String?,
      itemCode: productData?['sku'] as String? ?? json['item_code'] as String?,
      hsnCode: productData?['hsn_code'] as String? ?? json['hsn_code'] as String?,
      description: json['description'] as String?,
      accountId: json['account_id'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      taxId: json['tax_id'] as String?,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      discountAccountId: json['discount_account_id'] as String?,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      discountType: json['discount_type'] as String? ?? 'percentage',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isHeader: json['is_header'] as bool? ?? false,
      headerText: json['header_text'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      if (description != null) 'description': description,
      if (accountId != null) 'account_id': accountId,
      if (discountAccountId != null) 'discount_account_id': discountAccountId,
      'quantity': quantity,
      'rate': rate,
      if (taxId != null) 'tax_id': taxId,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'discount': discount,
      'discount_type': discountType,
      'amount': amount,
      if (isHeader) 'is_header': isHeader,
      if (headerText != null) 'header_text': headerText,
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
    bool? isHeader,
    String? headerText,
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
      isHeader: isHeader ?? this.isHeader,
      headerText: headerText ?? this.headerText,
    );
  }
}

class PurchaseOrder {
  final String? id;
  final String? orgId;
  final String? outletId;
  final String orderNumber;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final String? referenceNumber;
  final String vendorId;
  final String? vendorName;
  final String? paymentTerms;
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
  final List<PurchaseOrderItem> items;
  final bool isReverseCharge;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PurchaseOrder({
    this.id,
    this.orgId,
    this.outletId,
    required this.orderNumber,
    required this.orderDate,
    this.expectedDeliveryDate,
    this.referenceNumber,
    required this.vendorId,
    this.vendorName,
    this.paymentTerms,
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
    this.items = const [],
    this.isReverseCharge = false,
    this.createdAt,
    this.updatedAt,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? 
                    json['purchases_purchase_order_items'] as List<dynamic>? ??
                    json['purchase_order_items'] as List<dynamic>? ?? 
                    [];
    return PurchaseOrder(
      id: json['id'] as String?,
      orgId: json['org_id'] as String?,
      outletId: json['outlet_id'] as String?,
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
      paymentTerms: json['payment_terms'] as String?,
      shipmentPreference: json['shipment_preference'] as String?,
      deliveryType: json['delivery_type'] as String? ?? 'warehouse',
      deliveryWarehouseId: json['delivery_warehouse_id'] as String?,
      deliveryCustomerId: json['delivery_customer_id'] as String?,
      warehouseId: json['warehouse_id'] as String?,
        warehouseName:
          json['warehouse_name'] as String? ??
          json['warehouse']?['name'] as String? ??
          json['warehouses']?['name'] as String?,
      subTotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      discountType: json['discount_type'] as String? ?? 'percentage',
      tdsTcsType: json['tds_tcs_type'] as String? ?? 'none',
      tdsTcsId: json['tds_tcs_id'] as String?,
      adjustment: double.tryParse(json['adjustment']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      status: json['status'] as String? ?? 'Draft',
      notes: json['notes'] as String?,
      termsAndConditions: json['terms_and_conditions'] as String?,
      discountLevel: json['discount_level'] as String? ?? 'transaction',
      discountAccountId: json['discount_account_id'] as String?,
      isReverseCharge: json['is_reverse_charge'] as bool? ?? false,
      items: rawItems
          .map((e) => PurchaseOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (orgId != null) 'org_id': orgId,
      if (outletId != null) 'outlet_id': outletId,
      'vendor_id': vendorId,
      'order_number': orderNumber,
      'order_date': orderDate.toIso8601String().split('T').first,
      if (expectedDeliveryDate != null)
        'expected_delivery_date': expectedDeliveryDate!
            .toIso8601String()
            .split('T')
            .first,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (paymentTerms != null) 'payment_terms': paymentTerms,
      if (shipmentPreference != null) 'shipment_preference': shipmentPreference,
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
      'adjustment': adjustment,
      'total': total,
      if (notes != null) 'notes': notes,
      if (termsAndConditions != null)
        'terms_and_conditions': termsAndConditions,
      'discount_level': discountLevel,
      if (discountAccountId != null) 'discount_account_id': discountAccountId,
      'is_reverse_charge': isReverseCharge,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  PurchaseOrder copyWith({
    String? id,
    String? orgId,
    String? outletId,
    String? orderNumber,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
    String? referenceNumber,
    String? vendorId,
    String? vendorName,
    String? paymentTerms,
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
    String? discountAccountId,
    String? discountAccountName,
    List<PurchaseOrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      outletId: outletId ?? this.outletId,
      orderNumber: orderNumber ?? this.orderNumber,
      orderDate: orderDate ?? this.orderDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      paymentTerms: paymentTerms ?? this.paymentTerms,
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
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    // Handle both legacy warehouses rows and settings_outlets/settings_locations rows.
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
}
