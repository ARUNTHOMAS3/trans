/// Model classes for Inventory Package documents.
class InventoryPackage {
  final String? id;
  final String? customerId;
  final String? customerName;
  final String packageNumber;
  final DateTime? packageDate;
  final double dimensionLength;
  final double dimensionWidth;
  final double dimensionHeight;
  final String dimensionUnit;
  final double weight;
  final String weightUnit;
  final bool isManualMode;
  final String? notes;
  final String status;
  final List<InventoryPackageItem> items;
  final List<String> salesOrderIds;
  final List<String> picklistIds;
  final List<String> salesOrderNumbers;
  final List<String> picklistNumbers;
  final String? carrier;
  final String? trackingNumber;
  final DateTime? shipmentDate;
  final String? salesOrderNumber;
  final List<InventoryPackageSORef> salesOrderRefs;
  final bool isDelete;

  InventoryPackage({
    this.id,
    this.customerId,
    this.customerName,
    this.packageNumber = '',
    this.packageDate,
    this.dimensionLength = 0,
    this.dimensionWidth = 0,
    this.dimensionHeight = 0,
    this.dimensionUnit = 'cm',
    this.weight = 0,
    this.weightUnit = 'kg',
    this.isManualMode = false,
    this.notes,
    this.status = 'Not Shipped',
    this.items = const [],
    this.salesOrderIds = const [],
    this.picklistIds = const [],
    this.salesOrderNumbers = const [],
    this.picklistNumbers = const [],
    this.carrier,
    this.trackingNumber,
    this.shipmentDate,
    this.salesOrderNumber,
    this.salesOrderRefs = const [],
    this.isDelete = false,
  });

  InventoryPackage copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? packageNumber,
    DateTime? packageDate,
    double? dimensionLength,
    double? dimensionWidth,
    double? dimensionHeight,
    String? dimensionUnit,
    double? weight,
    String? weightUnit,
    bool? isManualMode,
    String? notes,
    String? status,
    List<InventoryPackageItem>? items,
    List<String>? salesOrderIds,
    List<String>? picklistIds,
    List<String>? salesOrderNumbers,
    List<String>? picklistNumbers,
    String? carrier,
    String? trackingNumber,
    DateTime? shipmentDate,
    String? salesOrderNumber,
    List<InventoryPackageSORef>? salesOrderRefs,
    bool? isDelete,
  }) {
    return InventoryPackage(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      packageNumber: packageNumber ?? this.packageNumber,
      packageDate: packageDate ?? this.packageDate,
      dimensionLength: dimensionLength ?? this.dimensionLength,
      dimensionWidth: dimensionWidth ?? this.dimensionWidth,
      dimensionHeight: dimensionHeight ?? this.dimensionHeight,
      dimensionUnit: dimensionUnit ?? this.dimensionUnit,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      isManualMode: isManualMode ?? this.isManualMode,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      items: items ?? this.items,
      salesOrderIds: salesOrderIds ?? this.salesOrderIds,
      picklistIds: picklistIds ?? this.picklistIds,
      salesOrderNumbers: salesOrderNumbers ?? this.salesOrderNumbers,
      picklistNumbers: picklistNumbers ?? this.picklistNumbers,
      carrier: carrier ?? this.carrier,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      shipmentDate: shipmentDate ?? this.shipmentDate,
      salesOrderNumber: salesOrderNumber ?? this.salesOrderNumber,
      salesOrderRefs: salesOrderRefs ?? this.salesOrderRefs,
      isDelete: isDelete ?? this.isDelete,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'package_number': packageNumber,
        'package_date': packageDate?.toIso8601String(),
        'dimension_length': dimensionLength,
        'dimension_width': dimensionWidth,
        'dimension_height': dimensionHeight,
        'dimension_unit': dimensionUnit,
        'weight': weight,
        'weight_unit': weightUnit,
        'is_manual_mode': isManualMode,
        'notes': notes,
        'status': status,
        'items': items.map((i) => i.toJson()).toList(),
        'sales_order_ids': salesOrderIds,
        'picklist_ids': picklistIds,
        'sales_order_numbers': salesOrderNumbers,
        'picklist_numbers': picklistNumbers,
        'carrier': carrier,
        'tracking_number': trackingNumber,
        'shipment_date': shipmentDate?.toIso8601String(),
        'sales_order_number': salesOrderNumber,
        'sales_order_refs': salesOrderRefs.map((r) => r.toJson()).toList(),
        'is_delete': isDelete,
      };

  factory InventoryPackage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>?;
    final rawSoIds = json['sales_order_ids'] as List<dynamic>?;
    
    return InventoryPackage(
      id: json['id'] as String?,
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String?,
      packageNumber: json['package_number'] as String? ?? '',
      packageDate: json['package_date'] != null ? DateTime.parse(json['package_date'] as String) : null,
      dimensionLength: (json['dimension_length'] as num?)?.toDouble() ?? 0,
      dimensionWidth: (json['dimension_width'] as num?)?.toDouble() ?? 0,
      dimensionHeight: (json['dimension_height'] as num?)?.toDouble() ?? 0,
      dimensionUnit: json['dimension_unit'] as String? ?? 'cm',
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      weightUnit: json['weight_unit'] as String? ?? 'kg',
      isManualMode: json['is_manual_mode'] as bool? ?? false,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'Not Shipped',
      items: rawItems != null
          ? rawItems.map((e) => InventoryPackageItem.fromJson(e as Map<String, dynamic>)).toList()
          : [],
      salesOrderIds: rawSoIds != null ? rawSoIds.map((e) => e.toString()).toList() : [],
      picklistIds: (json['picklist_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      salesOrderNumbers: (json['sales_order_numbers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      picklistNumbers: (json['picklist_numbers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      carrier: json['carrier'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      shipmentDate: json['shipment_date'] != null ? DateTime.parse(json['shipment_date'] as String) : null,
      salesOrderNumber: json['sales_order_number'] as String?,
      salesOrderRefs: (json['sales_order_refs'] as List<dynamic>?)?.map((e) => InventoryPackageSORef.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      isDelete: json['is_delete'] as bool? ?? false,
    );
  }

  double get totalQty => items.fold(0.0, (sum, item) => sum + item.quantity);
}

class InventoryPackageSORef {
  final String salesOrderId;
  final String? saleNumber;
  final String? binLocation;
  final String? batchNo;

  InventoryPackageSORef({
    required this.salesOrderId,
    this.saleNumber,
    this.binLocation,
    this.batchNo,
  });

  Map<String, dynamic> toJson() => {
    'sales_order_id': salesOrderId,
    'sale_number': saleNumber,
    'bin_location': binLocation,
    'batch_no': batchNo,
  };

  factory InventoryPackageSORef.fromJson(Map<String, dynamic> json) {
    return InventoryPackageSORef(
      salesOrderId: json['sales_order_id'] as String,
      saleNumber: json['sale_number'] as String?,
      binLocation: json['bin_location'] as String?,
      batchNo: json['batch_no'] as String?,
    );
  }
}

class InventoryPackageItem {
  final String? id;
  final String? packageId;
  final String? productId;
  final String? itemName;
  final double quantity;
  final String? salesOrderId;
  final String? salesOrderNumber;
  final String? picklistId;
  final String? picklistNumber;

  InventoryPackageItem({
    this.id,
    this.packageId,
    this.productId,
    this.itemName,
    this.quantity = 0,
    this.salesOrderId,
    this.salesOrderNumber,
    this.picklistId,
    this.picklistNumber,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'package_id': packageId,
        'product_id': productId,
        'item_name': itemName,
        'quantity': quantity,
        'sales_order_id': salesOrderId,
        'sales_order_number': salesOrderNumber,
        'picklist_id': picklistId,
        'picklist_number': picklistNumber,
      };

  factory InventoryPackageItem.fromJson(Map<String, dynamic> json) {
    return InventoryPackageItem(
      id: json['id'] as String?,
      packageId: json['package_id'] as String?,
      productId: json['product_id'] as String?,
      itemName: json['item_name'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      salesOrderId: json['sales_order_id'] as String?,
      salesOrderNumber: json['sales_order_number'] as String?,
      picklistId: json['picklist_id'] as String?,
      picklistNumber: json['picklist_number'] as String?,
    );
  }
}
