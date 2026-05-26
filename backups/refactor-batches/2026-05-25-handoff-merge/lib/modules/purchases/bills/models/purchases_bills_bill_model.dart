class PurchasesBill {
  final String id;
  final String? billNumber;
  final String vendorId;
  final String vendorName;
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
  final String? notes;
  final List<String> attachmentUrls;
  final String status; // 'draft', 'open', 'paid', 'overdue', 'void'
  final String? pdfTemplate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PurchasesBill({
    required this.id,
    this.billNumber,
    required this.vendorId,
    required this.vendorName,
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
    this.notes,
    this.attachmentUrls = const [],
    this.status = 'draft',
    this.pdfTemplate,
    this.createdAt,
    this.updatedAt,
  });

  factory PurchasesBill.fromJson(Map<String, dynamic> json) {
    return PurchasesBill(
      id: json['id'] ?? '',
      billNumber: json['bill_number'],
      vendorId: json['vendor_id'] ?? '',
      vendorName: json['vendor_name'] ?? '',
      vendorNumber: json['vendor_number'],
      orderNumber: json['order_number'],
      billDate: json['bill_date'] != null
          ? DateTime.tryParse(json['bill_date'])
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'])
          : null,
      paymentTerms: json['payment_terms'],
      isReverseCharge: json['is_reverse_charge'] ?? false,
      subject: json['subject'],
      warehouseId: json['warehouse_id'],
      warehouseName: json['warehouse_name'],
      taxLevel: json['tax_level'] ?? 'transaction',
      lineItems:
          (json['line_items'] as List<dynamic>?)
              ?.map((e) => PurchasesBillLineItem.fromJson(e))
              .toList() ??
          [],
      subTotal: (json['sub_total'] ?? 0).toDouble(),
      discountPercent: (json['discount_percent'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      tdsOrTcs: json['tds_or_tcs'] ?? 'tds',
      taxId: json['tax_id'],
      taxName: json['tax_name'],
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      adjustmentLabel: json['adjustment_label'] ?? 'Adjustment',
      adjustment: (json['adjustment'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendorId': vendorId,
      'vendorName': vendorName,
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
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'attachmentUrls': attachmentUrls,
      'status': status,
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
  });

  double get computedAmount {
    double base = quantity * rate;
    if (discountType == '%') {
      return base - (base * discount / 100);
    }
    return base - discount;
  }

  factory PurchasesBillLineItem.fromJson(Map<String, dynamic> json) {
    return PurchasesBillLineItem(
      id: json['id'],
      itemId: json['item_id'],
      itemName: json['item_name'],
      hsnCode: json['hsn_code'],
      description: json['description'],
      itemImageUrl: json['item_image_url'],
      batch: json['batch'],
      unitPack: json['unit_pack'],
      expiry: json['expiry'] != null ? DateTime.tryParse(json['expiry']) : null,
      mrp: (json['mrp'] ?? 0).toDouble(),
      ptr: (json['ptr'] ?? 0).toDouble(),
      freeQuantity: (json['free_quantity'] ?? 0).toDouble(),
      accountId: json['account_id'],
      accountName: json['account_name'],
      quantity: (json['quantity'] ?? 1).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
      taxId: json['tax_id'],
      taxName: json['tax_name'],
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      discount: (json['discount'] ?? 0).toDouble(),
      discountType: json['discount_type'] ?? '%',
      amount: (json['amount'] ?? 0).toDouble(),
      isLandedCost: json['is_landed_cost'] ?? false,
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
    );
  }
}
