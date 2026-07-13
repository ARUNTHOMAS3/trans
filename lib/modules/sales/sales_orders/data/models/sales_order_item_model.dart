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
  final String? hsnCode;
  final String? warehouseId;
  final Item? item;
  final String? accountId;
  final String? priceListId;
  final double taxPercentage;
  final List<dynamic>? batches;
  final double cancelledQuantity;
  final double pickedQuantity;
  final double packedQuantity;
  final double shippedQuantity;
  final double invoicedQuantity;

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
    this.hsnCode,
    this.warehouseId,
    this.item,
    this.accountId,
    this.priceListId,
    this.taxPercentage = 0.0,
    this.batches,
    this.cancelledQuantity = 0.0,
    this.pickedQuantity = 0.0,
    this.packedQuantity = 0.0,
    this.shippedQuantity = 0.0,
    this.invoicedQuantity = 0.0,
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
      itemTotal:
          (json['item_total'] ?? json['itemTotal'] ?? json['amount'] ?? 0.0)
              .toDouble(),
      hsnCode: (json['hsn_code'] ?? json['hsnCode'])?.toString(),
      warehouseId: json['warehouse_id'] ?? json['warehouseId'],
      item: (json['item'] ?? json['product']) != null
          ? Item.fromJson(json['item'] ?? json['product'])
          : null,
      accountId: json['accounts'] ?? json['account_id'] ?? json['accountId'],
      priceListId:json['pricelist'] ?? json['price_list_id'] ?? json['priceListId'],
      taxPercentage: (json['tax_percentage'] ?? json['taxPercentage'] ?? 0.0)
          .toDouble(),
      batches: json['batches'],
      cancelledQuantity: double.tryParse(json['cancelledQuantity']?.toString() ?? json['cancelled_quantity']?.toString() ?? '0.0') ?? 0.0,
      pickedQuantity: double.tryParse(json['pickedQuantity']?.toString() ?? json['picked_quantity']?.toString() ?? '0.0') ?? 0.0,
      packedQuantity: double.tryParse(json['packedQuantity']?.toString() ?? json['packed_quantity']?.toString() ?? '0.0') ?? 0.0,
      shippedQuantity: double.tryParse(json['shippedQuantity']?.toString() ?? json['shipped_quantity']?.toString() ?? '0.0') ?? 0.0,
      invoicedQuantity: double.tryParse(json['invoicedQuantity']?.toString() ?? json['invoiced_quantity']?.toString() ?? '0.0') ?? 0.0,
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
      'hsnCode': hsnCode,
      if (warehouseId != null) 'warehouseId': warehouseId,
      if (accountId != null) 'accounts': accountId,
      if (priceListId != null) 'pricelist': priceListId,
      'cancelled_quantity': cancelledQuantity,
      'picked_quantity': pickedQuantity,
      'packed_quantity': packedQuantity,
      'shipped_quantity': shippedQuantity,
      'invoiced_quantity': invoicedQuantity,
    };
  }
}
