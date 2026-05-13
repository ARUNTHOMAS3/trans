// FILE: lib/modules/items/models/tax_rate_model.dart

class TaxRate {
  final String id;
  final String taxName;
  final double taxRate;
  final String? taxType; // IGST, CGST, SGST
  final bool isActive;

  TaxRate({
    required this.id,
    required this.taxName,
    required this.taxRate,
    this.taxType,
    this.isActive = true,
  });

  factory TaxRate.fromJson(Map<String, dynamic> json) {
    return TaxRate(
      id: json['id']?.toString() ?? '',
      taxName: json['tax_name'] ?? '',
      taxRate: double.tryParse(json['tax_rate']?.toString() ?? '0') ?? 0.0,
      taxType: json['tax_type'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tax_name': taxName,
      'tax_rate': taxRate,
      if (taxType != null) 'tax_type': taxType,
      'is_active': isActive,
    };
  }
}
