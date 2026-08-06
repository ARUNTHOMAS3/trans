import 'package:zerpai_erp/modules/items/items/models/item_model.dart';

class SalesOrderItem {
  final String? id;
  final String? salesOrderId;
  final String itemId;
  final String? description;
  final double quantity;
  final double rate;
  final double discount;
  final String discountType;
  final String? taxId;
  final double taxAmount;
  final double itemTotal;
  final String? warehouseId;
  final Item? item;

  SalesOrderItem({
    this.id,
    this.salesOrderId,
    required this.itemId,
    this.description,
    required this.quantity,
    required this.rate,
    this.discount = 0.0,
    this.discountType = '%',
    this.taxId,
    this.taxAmount = 0.0,
    this.itemTotal = 0.0,
    this.warehouseId,
    this.item,
  });

  factory SalesOrderItem.fromJson(Map<String, dynamic> json) {
    return SalesOrderItem(
      id: json['id'],
      salesOrderId: json['sales_order_id'] ?? json['salesOrderId'],
      itemId:
          json['item_id'] ??
          json['itemId'] ??
          json['product_id'] ??
          json['productId'] ??
          '',
      description: json['description'],
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      rate: (json['rate'] ?? 0.0).toDouble(),
      discount: (json['discount_value'] ?? json['discount'] ?? 0.0).toDouble(),
      discountType: json['discount_type'] ?? json['discountType'] ?? '%',
      taxId: json['tax_id'] ?? json['taxId'],
      taxAmount: (json['tax_amount'] ?? json['taxAmount'] ?? 0.0).toDouble(),
      itemTotal: (json['item_total'] ?? json['itemTotal'] ?? json['amount'] ?? 0.0).toDouble(),
      warehouseId: json['warehouse_id'] ?? json['warehouseId'],
      item: (json['item'] ?? json['product']) != null
          ? Item.fromJson(json['item'] ?? json['product'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (salesOrderId != null) 'salesOrderId': salesOrderId,
      'itemId': itemId,
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'discount': discount,
      'discountType': discountType,
      'taxId': taxId,
      if (warehouseId != null) 'warehouseId': warehouseId,
    };
  }
}
