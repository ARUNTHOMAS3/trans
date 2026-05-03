/// Model classes for Inventory Picklist documents.
///
/// A Picklist tracks the process of picking items from inventory for orders.
class Picklist {
  final String? id;
  final String picklistNumber;
  final DateTime? date;
  final String status; // 'YET_TO_PICK' | 'IN_PROGRESS' | 'ON_HOLD' | 'COMPLETED' | 'FORCE_COMPLETE' | 'APPROVED'
  final String? assignee;
  final String? location;
  final String? notes;
  final String? customerName;
  final String? salesOrderNumber;
  final List<PicklistItem> items;

  Picklist({
    this.id,
    this.picklistNumber = '',
    this.date,
    this.status = 'YET_TO_PICK',
    this.assignee,
    this.location,
    this.notes,
    this.customerName,
    this.salesOrderNumber,
    this.items = const [],
  });

  Picklist copyWith({
    String? id,
    String? picklistNumber,
    DateTime? date,
    String? status,
    String? assignee,
    String? location,
    String? notes,
    String? customerName,
    String? salesOrderNumber,
    List<PicklistItem>? items,
  }) {
    return Picklist(
      id: id ?? this.id,
      picklistNumber: picklistNumber ?? this.picklistNumber,
      date: date ?? this.date,
      status: status ?? this.status,
      assignee: assignee ?? this.assignee,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      customerName: customerName ?? this.customerName,
      salesOrderNumber: salesOrderNumber ?? this.salesOrderNumber,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'picklist_number': picklistNumber,
        'date': date?.toIso8601String(),
        'status': status,
        'assignee': assignee,
        'location': location,
        'notes': notes,
        'customer_name': customerName,
        'sales_order_number': salesOrderNumber,
      };

  factory Picklist.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>?;
    return Picklist(
      id: json['id'] as String?,
      picklistNumber: json['picklist_number'] as String? ?? '',
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      status: json['status'] as String? ?? 'YET_TO_PICK',
      assignee: json['assignee'] as String?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      customerName: json['customer_name'] as String?,
      salesOrderNumber: json['sales_order_number'] as String?,
      items: rawItems != null
          ? rawItems.map((e) => PicklistItem.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }
}

/// Individual line item within a picklist.
class PicklistItem {
  final String? id;
  final String? productId;
  final String? productName;
  final String? salesOrderId;
  final String? salesOrderLineId;
  final String? salesOrderNumber;
  final String? customerName;
  final double qtyOrdered;
  final double qtyToPick;
  final double qtyPicked;
  final String status;
  final double qtyPacked;
  final List<Map<String, dynamic>> batchAllocations;

  PicklistItem({
    this.id,
    this.productId,
    this.productName,
    this.salesOrderId,
    this.salesOrderLineId,
    this.salesOrderNumber,
    this.customerName,
    this.qtyOrdered = 0,
    this.qtyToPick = 0,
    this.qtyPicked = 0,
    this.status = 'Yet To Start',
    this.qtyPacked = 0,
    this.batchAllocations = const [],
  });

  double get yetToPick => (qtyToPick - qtyPicked).clamp(0, double.infinity);

  String get itemStatus {
    // Priority 1: Honor specific status if it's On Hold or terminal
    final s = status.toUpperCase().replaceAll(' ', '_');
    if (s == 'ON_HOLD') return 'On Hold';
    if (s == 'FORCE_COMPLETE') return 'Force Complete';
    if (s == 'APPROVED') return 'Approved';
    if (s == 'CANCELLED') return 'Cancelled';

    // Priority 2: Calculate based on quantities
    if (qtyPicked <= 0) return 'Yet to Start';
    if (qtyPicked < qtyToPick) return 'In Progress';
    return 'Completed';
  }

  factory PicklistItem.fromJson(Map<String, dynamic> json) {
    return PicklistItem(
      id: json['id'] as String?,
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String?,
      salesOrderId: json['sales_order_id'] as String?,
      salesOrderLineId: json['sales_order_line_id'] as String?,
      salesOrderNumber: json['sales_order_number'] as String?,
      customerName: json['customer_name'] as String?,
      qtyOrdered: (json['qty_ordered'] as num?)?.toDouble() ?? 0,
      qtyToPick: (json['qty_to_pick'] as num?)?.toDouble() ?? 0,
      qtyPicked: json['qty_picked'] != null ? double.parse(json['qty_picked'].toString()) : 0,
      status: json['status']?.toString() ?? 'Yet To Start',
      qtyPacked: json['qty_packed'] != null ? double.parse(json['qty_packed'].toString()) : 0,
      batchAllocations: (json['batch_allocations'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}
