class PurchaseReceiveItem {
  final String? itemId;
  final String itemName;
  final String? description;
  final double ordered;
  final double received;
  final double inTransit;
  final double quantityToReceive;

  const PurchaseReceiveItem({
    this.itemId,
    this.itemName = '',
    this.description,
    this.ordered = 0,
    this.received = 0,
    this.inTransit = 0,
    this.quantityToReceive = 0,
  });

  PurchaseReceiveItem copyWith({
    String? itemId,
    String? itemName,
    String? description,
    double? ordered,
    double? received,
    double? inTransit,
    double? quantityToReceive,
  }) {
    return PurchaseReceiveItem(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      ordered: ordered ?? this.ordered,
      received: received ?? this.received,
      inTransit: inTransit ?? this.inTransit,
      quantityToReceive: quantityToReceive ?? this.quantityToReceive,
    );
  }

  Map<String, dynamic> toJson() => {
    'item_id': itemId,
    'item_name': itemName,
    'description': description,
    'ordered': ordered,
    'received': received,
    'in_transit': inTransit,
    'quantity_to_receive': quantityToReceive,
  };

  factory PurchaseReceiveItem.fromJson(Map<String, dynamic> json) {
    return PurchaseReceiveItem(
      itemId: json['item_id']?.toString(),
      itemName: (json['item_name'] ?? json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      ordered: (json['ordered'] as num?)?.toDouble() ?? 0,
      received: (json['received'] as num?)?.toDouble() ?? 0,
      inTransit: (json['in_transit'] as num?)?.toDouble() ?? 0,
      quantityToReceive:
          (json['quantity_to_receive'] as num?)?.toDouble() ??
          (json['quantity'] as num?)?.toDouble() ??
          0,
    );
  }
}

class PurchaseReceive {
  final String? id;
  final String purchaseReceiveNumber;
  final DateTime? receivedDate;
  final String? vendorId;
  final String? vendorName;
  final String? purchaseOrderId;
  final String? purchaseOrderNumber;
  final String status;
  final String? notes;
  final List<PurchaseReceiveItem> items;
  final bool billed;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double quantity;

  const PurchaseReceive({
    this.id,
    this.purchaseReceiveNumber = '',
    this.receivedDate,
    this.vendorId,
    this.vendorName,
    this.purchaseOrderId,
    this.purchaseOrderNumber,
    this.status = 'draft',
    this.notes,
    this.items = const [],
    this.billed = false,
    this.createdAt,
    this.updatedAt,
    this.quantity = 0,
  });

  double get totalQuantity {
    if (quantity > 0) {
      return quantity;
    }
    return items.fold<double>(
      0,
      (sum, item) => sum + item.quantityToReceive,
    );
  }

  PurchaseReceive copyWith({
    String? id,
    String? purchaseReceiveNumber,
    DateTime? receivedDate,
    String? vendorId,
    String? vendorName,
    String? purchaseOrderId,
    String? purchaseOrderNumber,
    String? status,
    String? notes,
    List<PurchaseReceiveItem>? items,
    bool? billed,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? quantity,
  }) {
    return PurchaseReceive(
      id: id ?? this.id,
      purchaseReceiveNumber:
          purchaseReceiveNumber ?? this.purchaseReceiveNumber,
      receivedDate: receivedDate ?? this.receivedDate,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      purchaseOrderNumber: purchaseOrderNumber ?? this.purchaseOrderNumber,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      billed: billed ?? this.billed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'purchase_receive_number': purchaseReceiveNumber,
    'received_date': receivedDate?.toIso8601String(),
    'vendor_id': vendorId,
    'vendor_name': vendorName,
    'purchase_order_id': purchaseOrderId,
    'purchase_order_number': purchaseOrderNumber,
    'status': status,
    'notes': notes,
    'billed': billed,
    'quantity': totalQuantity,
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory PurchaseReceive.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) {
        return null;
      }
      return DateTime.tryParse(value.toString());
    }

    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return PurchaseReceive(
      id: json['id']?.toString(),
      purchaseReceiveNumber:
          (json['purchase_receive_number'] ?? json['receive_number'] ?? '')
              .toString(),
      receivedDate: parseDate(json['received_date'] ?? json['date']),
      vendorId: json['vendor_id']?.toString(),
      vendorName: (json['vendor_name'] ?? json['vendor'])?.toString(),
      purchaseOrderId: json['purchase_order_id']?.toString(),
      purchaseOrderNumber:
          (json['purchase_order_number'] ?? json['po_number'])?.toString(),
      status: (json['status'] ?? 'draft').toString(),
      notes: json['notes']?.toString(),
      billed:
          json['billed'] == true ||
          json['is_billed'] == true ||
          json['billed_status']?.toString().toLowerCase() == 'billed',
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(PurchaseReceiveItem.fromJson)
          .toList(),
    );
  }
}
