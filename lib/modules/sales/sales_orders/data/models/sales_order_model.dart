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
  final String? tdsTcsType;
  final String? tdsTcsTaxId;
  final double tdsTcsAmount;
  final double tdsTotal;
  final double tcsTotal;

  final String? reasonToVoid;
  final String? reasonToConfirmed;

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
    this.tdsTcsType,
    this.tdsTcsTaxId,
    this.tdsTcsAmount = 0.0,
    this.tdsTotal = 0.0,
    this.tcsTotal = 0.0,
    this.reasonToVoid,
    this.reasonToConfirmed,
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

    return SalesOrder(
      id: json['id']?.toString() ?? '',
      customerId: (json['customer_id'] ?? json['customerId'])?.toString() ?? '',
      isDelete: json['is_delete'] ?? false,
      saleNumber: (json['sale_number'] ?? json['saleNumber'])?.toString() ?? '',
      reference: json['reference']?.toString(),
      saleDate: DateTime.parse(
        json['sale_date'] ??
            json['saleDate'] ??
            DateTime.now().toIso8601String(),
      ),
      expectedShipmentDate: json['expected_shipment_date'] != null
          ? DateTime.parse(json['expected_shipment_date'])
          : null,
      paymentTerms: json['payment_terms']?.toString(),
      deliveryMethod: json['delivery_method']?.toString(),
      salesperson: (json['salesperson'] ?? json['salesperson'])?.toString(),
      status: json['status'] ?? 'draft',
      documentType: json['document_type'] ?? json['documentType'] ?? 'order',
      subTotal: (json['sub_total'] ?? json['subTotal'] ?? 0.0).toDouble(),
      taxTotal: (json['tax_total'] ?? json['taxTotal'] ?? 0.0).toDouble(),
      discountTotal: (json['discount_total'] ?? json['discountTotal'] ?? 0.0)
          .toDouble(),
      shippingCharges:
          (json['shipping_charges'] ?? json['shippingCharges'] ?? 0.0)
              .toDouble(),
      adjustment: (json['adjustment'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
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
      salesOrderId: (json['sales_order_id'] ?? json['salesOrderId'])
          ?.toString(),
      tdsTcsType: json['tds_tcs_type']?.toString() ?? json['tdsTcsType']?.toString(),
      tdsTcsTaxId:
          json['tds_tcs_tax_id']?.toString() ?? json['tdsTcsTaxId']?.toString(),
      tdsTcsAmount:
          (json['tds_tcs_amount'] ?? json['tdsTcsAmount'] ?? 0.0).toDouble(),
      tdsTotal: (json['tds_total'] ?? json['tdsTotal'] ?? 0.0).toDouble(),
      tcsTotal: (json['tcs_total'] ?? json['tcsTotal'] ?? 0.0).toDouble(),
      reasonToVoid: json['reason_to_void'] ?? json['reasonToVoid'],
      reasonToConfirmed: json['reason_to_confirmed'] ?? json['reasonToConfirmed'],
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
      'tdsTcsType': tdsTcsType,
      'tdsTcsTaxId': tdsTcsTaxId,
      'tdsTcsAmount': tdsTcsAmount,
      'tdsTotal': tdsTotal,
      'tcsTotal': tcsTotal,
      if (reasonToVoid != null) 'reasonToVoid': reasonToVoid,
      if (reasonToConfirmed != null) 'reasonToConfirmed': reasonToConfirmed,
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
