class SalesEWayBill {
  final String? id;
  final String? saleId;
  final String billNumber;
  final DateTime billDate;
  final String supplyType;
  final String subType;
  final String? transporterId;
  final String? vehicleNumber;
  final String status;

  SalesEWayBill({
    this.id,
    this.saleId,
    required this.billNumber,
    required this.billDate,
    this.supplyType = 'Outward',
    this.subType = 'Supply',
    this.transporterId,
    this.vehicleNumber,
    this.status = 'active',
  });

  factory SalesEWayBill.fromJson(Map<String, dynamic> json) {
    return SalesEWayBill(
      id: json['id'],
      saleId: json['sale_id'],
      billNumber: json['bill_number'],
      billDate: DateTime.parse(json['bill_date']),
      supplyType: json['supply_type'] ?? 'Outward',
      subType: json['sub_type'] ?? 'Supply',
      transporterId: json['transporter_id'],
      vehicleNumber: json['vehicle_number'],
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (saleId != null) 'sale_id': saleId,
      'billNumber': billNumber,
      'billDate': billDate.toIso8601String(),
      'supplyType': supplyType,
      'subType': subType,
      'transporterId': transporterId,
      'vehicleNumber': vehicleNumber,
      'status': status,
    };
  }
}
