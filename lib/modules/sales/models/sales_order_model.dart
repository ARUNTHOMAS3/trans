import 'sales_customer_model.dart';
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
  final DateTime? createdAt;

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
    this.createdAt,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    return SalesOrder(
      id: json['id'],
      customerId: json['customer_id'] ?? json['customerId'] ?? '',
      saleNumber: json['sale_number'] ?? json['saleNumber'] ?? '',
      reference: json['reference'],
      saleDate: DateTime.parse(
        json['sale_date'] ??
            json['saleDate'] ??
            DateTime.now().toIso8601String(),
      ),
      expectedShipmentDate: json['expected_shipment_date'] != null
          ? DateTime.parse(json['expected_shipment_date'])
          : null,
      paymentTerms: json['payment_terms'],
      deliveryMethod: json['delivery_method'],
      salesperson: json['salesperson'] ?? json['salesperson'],
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
      customer: json['customer'] != null
          ? SalesCustomer.fromJson(json['customer'])
          : null,
      items: json['items'] != null
          ? (json['items'] as List)
                .map((i) => SalesOrderItem.fromJson(i))
                .toList()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
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
      'shippingCharges': shippingCharges,
      'adjustment': adjustment,
      'customerNotes': customerNotes,
      'termsAndConditions': termsAndConditions,
      'items': items?.map((i) => i.toJson()).toList(),
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
