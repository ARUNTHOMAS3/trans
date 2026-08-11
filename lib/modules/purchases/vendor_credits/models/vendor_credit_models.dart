class VendorCreditItem {
  final String id;
  final String name;
  final String description;
  final double quantity;
  final double rate;
  final String taxRate;
  final double amount;

  VendorCreditItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.quantity,
    required this.rate,
    required this.taxRate,
    required this.amount,
  });
}

class VendorCreditDetail {
  final String id;
  final String creditNoteNumber;
  final String? billId;
  final String? appliedBillNumber;
  final DateTime? appliedBillDate;
  final double? appliedBillAmount;
  final String vendorName;
  final String billingAddress;
  final String referenceNumber;
  final String sourceOfSupply;
  final String destinationOfSupply;
  final DateTime date;
  final String status;
  final double subtotal;
  final double taxAmount;
  final double shipping;
  final double adjustment;
  final double total;
  final double balance;
  final List<VendorCreditItem> items;

  VendorCreditDetail({
    required this.id,
    required this.creditNoteNumber,
    this.billId,
    this.appliedBillNumber,
    this.appliedBillDate,
    this.appliedBillAmount,
    required this.vendorName,
    this.billingAddress = '',
    this.referenceNumber = '',
    this.sourceOfSupply = '',
    this.destinationOfSupply = '',
    required this.date,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    this.shipping = 0,
    this.adjustment = 0,
    required this.total,
    required this.balance,
    required this.items,
  });
}
