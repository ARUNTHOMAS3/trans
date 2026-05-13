class Stock {
  final String id;
  final String productId;
  final String? productCode;
  final String? productName;
  final String? warehouseId;
  final String? warehouseName;
  final double quantityOnHand;
  final double reservedQuantity;
  final double availableQuantity;
  final double reorderLevel;
  final double? minStockLevel;
  final double? maxStockLevel;
  final String? binLocation;
  final String? lotNumber;
  final DateTime? expiryDate;
  final String? uom; // Unit of measure
  final double? averageCost;
  final double? lastCost;
  final DateTime lastUpdated;
  final String status; // active, inactive, discontinued

  Stock({
    required this.id,
    required this.productId,
    this.productCode,
    this.productName,
    this.warehouseId,
    this.warehouseName,
    required this.quantityOnHand,
    this.reservedQuantity = 0.0,
    required this.availableQuantity,
    required this.reorderLevel,
    this.minStockLevel,
    this.maxStockLevel,
    this.binLocation,
    this.lotNumber,
    this.expiryDate,
    this.uom,
    this.averageCost,
    this.lastCost,
    required this.lastUpdated,
    this.status = 'active',
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'],
      productId: json['product_id'],
      productCode: json['product_code'],
      productName: json['product_name'],
      warehouseId: json['warehouse_id'],
      warehouseName: json['warehouse_name'],
      quantityOnHand: double.parse(json['quantity_on_hand'].toString()),
      reservedQuantity: double.parse((json['reserved_quantity'] ?? 0).toString()),
      availableQuantity: double.parse(json['available_quantity'].toString()),
      reorderLevel: double.parse(json['reorder_level'].toString()),
      minStockLevel: json['min_stock_level'] != null
          ? double.parse(json['min_stock_level'].toString())
          : null,
      maxStockLevel: json['max_stock_level'] != null
          ? double.parse(json['max_stock_level'].toString())
          : null,
      binLocation: json['bin_location'],
      lotNumber: json['lot_number'],
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      uom: json['uom'],
      averageCost: json['average_cost'] != null
          ? double.parse(json['average_cost'].toString())
          : null,
      lastCost: json['last_cost'] != null
          ? double.parse(json['last_cost'].toString())
          : null,
      lastUpdated: DateTime.parse(json['last_updated']),
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_code': productCode,
      'product_name': productName,
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'quantity_on_hand': quantityOnHand.toString(),
      'reserved_quantity': reservedQuantity.toString(),
      'available_quantity': availableQuantity.toString(),
      'reorder_level': reorderLevel.toString(),
      'min_stock_level': minStockLevel?.toString(),
      'max_stock_level': maxStockLevel?.toString(),
      'bin_location': binLocation,
      'lot_number': lotNumber,
      'expiry_date': expiryDate?.toIso8601String(),
      'uom': uom,
      'average_cost': averageCost?.toString(),
      'last_cost': lastCost?.toString(),
      'last_updated': lastUpdated.toIso8601String(),
      'status': status,
    };
  }

  /// Calculate if stock is below reorder level
  bool get isBelowReorderLevel => availableQuantity <= reorderLevel;

  /// Calculate if stock is at zero
  bool get isOutOfStock => availableQuantity <= 0;

  /// Calculate stock value
  double get stockValue => availableQuantity * (averageCost ?? 0);
}
