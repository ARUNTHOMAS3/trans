import '../../../customers/data/models/sales_customer_model.dart';
import 'sales_order_item_model.dart';

class SalesOrder {
  final String id;
  final String customerId;
  final String saleNumber;
  final String? reference;
  final DateTime saleDate;
  final DateTime? expectedShipmentDate;
  final String? paymentTerms;
  final String? deliveryMethod;
  final String? salesperson;
  final String status;
  final String documentType;
  final double subTotal;
  final double taxTotal;
  final double discountTotal;
  final double shippingCharges;
  final double adjustment;
  final double total;
  final String? customerNotes;
  final String? termsAndConditions;
  final SalesCustomer? customer;
  final List<SalesOrderItem>? items;
  final String? placeOfSupply;
  final DateTime? createdAt;
  final String? warehouseId;
  final String? paymentTermId;
  final String? priceListId;
  final bool isDelete;
  final String? entityId;
  final String? salesOrderId;

  SalesOrder({
    required this.id,
    required this.customerId,
    required this.saleNumber,
    this.reference,
    required this.saleDate,
    this.expectedShipmentDate,
    this.paymentTerms,
    this.deliveryMethod,
    this.salesperson,
    this.status = 'draft',
    this.documentType = 'order',
    this.subTotal = 0.0,
    this.taxTotal = 0.0,
    this.discountTotal = 0.0,
    this.shippingCharges = 0.0,
    this.adjustment = 0.0,
    this.total = 0.0,
    this.customerNotes,
    this.termsAndConditions,
    this.customer,
    this.items,
    this.placeOfSupply,
    this.createdAt,
    this.warehouseId,
    this.paymentTermId,
    this.priceListId,
    this.isDelete = false,
    this.entityId,
    this.salesOrderId,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    final customerJson =
        (json['customer'] as Map<String, dynamic>?) ??
        (json['customers'] as Map<String, dynamic>?) ??
        (json['customer_data'] as Map<String, dynamic>?) ??
        (json['customerData'] as Map<String, dynamic>?);

    final normalizedCustomerJson = customerJson != null
        ? <String, dynamic>{
            ...customerJson,
            if ((customerJson['displayName'] == null ||
                    customerJson['displayName'].toString().trim().isEmpty) &&
                (json['customer_name'] != null ||
                    json['customerName'] != null ||
                    json['customer_display_name'] != null))
              'displayName':
                  json['customer_name'] ??
                  json['customerName'] ??
                  json['customer_display_name'],
          }
        : null;

    final invoiceNumber =
        (json['invoice_number'] ?? json['invoiceNumber'])?.toString();
    final invoiceDate =
        json['invoice_date'] ?? json['invoiceDate'] ?? json['sale_date'] ?? json['saleDate'];
    final dueDate =
        json['due_date'] ?? json['dueDate'] ?? json['expected_shipment_date'];
    final orderNumber =
        (json['order_number'] ?? json['orderNumber'])?.toString();
    final grandTotal = json['grand_total'] ?? json['grandTotal'];
    final invoiceSubtotal = json['subtotal'] ?? json['sub_total'];
    final invoiceTaxTotal =
        json['tax_total'] ??
        json['taxTotal'] ??
        json['total_tax'] ??
        json['totalTax'];
    final invoiceAdjustment = json['adjustment_amount'] ?? json['adjustment'];
    final invoicePaymentTerms = json['payment_terms'] ?? json['paymentTerms'];
    final invoiceSalesperson =
        json['salesperson_name'] ?? json['salesperson'] ?? json['salespersonId'] ?? json['salesperson_id'];

    return SalesOrder(
      id: json['id']?.toString() ?? '',
      customerId: (json['customer_id'] ?? json['customerId'])?.toString() ?? '',
      isDelete: json['is_delete'] ?? false,
      saleNumber:
          invoiceNumber ??
          (json['sale_number'] ?? json['saleNumber'])?.toString() ??
          '',
      reference: orderNumber ?? json['reference']?.toString(),
      saleDate: DateTime.parse(
        invoiceDate ??
            DateTime.now().toIso8601String(),
      ),
      expectedShipmentDate: dueDate != null
          ? DateTime.parse(dueDate)
          : null,
      paymentTerms: invoicePaymentTerms?.toString(),
      deliveryMethod: json['delivery_method']?.toString(),
      salesperson: invoiceSalesperson?.toString(),
      status: json['status'] ?? 'draft',
      documentType: json['document_type'] ?? json['documentType'] ?? 'order',
      subTotal: (invoiceSubtotal ?? json['subTotal'] ?? 0.0).toDouble(),
      taxTotal: (invoiceTaxTotal ?? 0.0).toDouble(),
      discountTotal: (json['discount_total'] ?? json['discountTotal'] ?? 0.0)
          .toDouble(),
      shippingCharges:
          (json['shipping_charges'] ?? json['shippingCharges'] ?? 0.0)
              .toDouble(),
      adjustment: (invoiceAdjustment ?? 0.0).toDouble(),
      total: (grandTotal ?? json['total'] ?? 0.0).toDouble(),
      customerNotes: json['customer_notes'] ?? json['customerNotes'],
      termsAndConditions:
          json['terms_and_conditions'] ?? json['termsAndConditions'],
      customer: normalizedCustomerJson != null
          ? SalesCustomer.fromJson(normalizedCustomerJson)
          : null,
      items: json['items'] != null
          ? (json['items'] as List)
                .map((i) => SalesOrderItem.fromJson(i))
                .toList()
          : null,
      placeOfSupply: json['place_of_supply'] ?? json['placeOfSupply'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      warehouseId: json['warehouse_id'] ?? json['warehouseId'],
      paymentTermId: json['payment_term_id'] ?? json['paymentTermId'],
      priceListId: json['price_list_id'] ?? json['priceListId'],
      entityId: json['entity_id'] ?? json['entityId'],
      salesOrderId: (json['sales_order_id'] ?? json['salesOrderId'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'saleNumber': saleNumber,
      'reference': reference,
      'saleDate': saleDate.toIso8601String(),
      'expectedShipmentDate': expectedShipmentDate?.toIso8601String(),
      'paymentTerms': paymentTerms,
      'deliveryMethod': deliveryMethod,
      'salesperson': salesperson,
      'status': status,
      'documentType': documentType,
      'subTotal': subTotal,
      'taxTotal': taxTotal,
      'discountTotal': discountTotal,
      'shippingCharges': shippingCharges,
      'adjustment': adjustment,
      'total': total,
      'customerNotes': customerNotes,
      'termsAndConditions': termsAndConditions,
      'items': items?.map((i) => i.toJson()).toList(),
      'placeOfSupply': placeOfSupply,
      'warehouseId': warehouseId,
      'paymentTermId': paymentTermId,
      'priceListId': priceListId,
      'entityId': entityId,
      'is_delete': isDelete,
    };
  }

  static List<SalesOrder> dummyList(int count) {
    return List.generate(
      count,
      (index) => SalesOrder(
        id: 'dummy_$index',
        customerId: 'customer_$index',
        saleNumber: 'SO-000$index',
        saleDate: DateTime.now().subtract(Duration(days: index)),
        subTotal: 1000.0,
        taxTotal: 180.0,
        total: 1180.0,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalesOrder && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

