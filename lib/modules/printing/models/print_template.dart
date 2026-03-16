// PATH: lib/modules/printing/models/print_template.dart

import 'package:equatable/equatable.dart';

class PrintTemplate extends Equatable {
  final String id;
  final String name;
  final String type;
  final String content;
  final Map<String, dynamic> variables;
  final String? description;
  final bool isDefault;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PrintTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.content,
    required this.variables,
    this.description,
    this.isDefault = false,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PrintTemplate.fromJson(Map<String, dynamic> json) {
    return PrintTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      content: json['content'] as String,
      variables: Map<String, dynamic>.from(json['variables'] as Map),
      description: json['description'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'content': content,
      'variables': variables,
      'description': description,
      'isDefault': isDefault,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PrintTemplate copyWith({
    String? id,
    String? name,
    String? type,
    String? content,
    Map<String, dynamic>? variables,
    String? description,
    bool? isDefault,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrintTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      content: content ?? this.content,
      variables: variables ?? this.variables,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        content,
        variables,
        description,
        isDefault,
        isActive,
        createdBy,
        createdAt,
        updatedAt,
      ];
}

// Template types enumeration
class TemplateType {
  static const String invoice = 'invoice';
  static const String receipt = 'receipt';
  static const String purchaseOrder = 'purchase_order';
  static const String deliveryNote = 'delivery_note';
  static const String quotation = 'quotation';
  static const String creditNote = 'credit_note';
  static const String debitNote = 'debit_note';
  static const String paymentVoucher = 'payment_voucher';
  static const String journalEntry = 'journal_entry';
  
  static List<String> get all => [
        invoice,
        receipt,
        purchaseOrder,
        deliveryNote,
        quotation,
        creditNote,
        debitNote,
        paymentVoucher,
        journalEntry,
      ];
}

// Variable types for template customization
class TemplateVariables {
  // Company information
  static const String companyName = '{{company_name}}';
  static const String companyAddress = '{{company_address}}';
  static const String companyPhone = '{{company_phone}}';
  static const String companyEmail = '{{company_email}}';
  static const String companyGstin = '{{company_gstin}}';
  static const String companyPan = '{{company_pan}}';
  
  // Document information
  static const String documentNumber = '{{document_number}}';
  static const String documentDate = '{{document_date}}';
  static const String dueDate = '{{due_date}}';
  static const String referenceNumber = '{{reference_number}}';
  
  // Customer/Vendor information
  static const String partyName = '{{party_name}}';
  static const String partyAddress = '{{party_address}}';
  static const String partyPhone = '{{party_phone}}';
  static const String partyEmail = '{{party_email}}';
  static const String partyGstin = '{{party_gstin}}';
  
  // Financial information
  static const String subtotal = '{{subtotal}}';
  static const String taxAmount = '{{tax_amount}}';
  static const String discountAmount = '{{discount_amount}}';
  static const String totalAmount = '{{total_amount}}';
  static const String amountInWords = '{{amount_in_words}}';
  static const String currencySymbol = '{{currency_symbol}}';
  
  // Item details
  static const String itemList = '{{item_list}}';
  static const String itemDescription = '{{item_description}}';
  static const String itemQuantity = '{{item_quantity}}';
  static const String itemRate = '{{item_rate}}';
  static const String itemAmount = '{{item_amount}}';
  
  // Payment information
  static const String paymentTerms = '{{payment_terms}}';
  static const String paymentMethod = '{{payment_method}}';
  static const String bankDetails = '{{bank_details}}';
  
  // Signatures
  static const String authorizedSignature = '{{authorized_signature}}';
  static const String preparedBy = '{{prepared_by}}';
  static const String approvedBy = '{{approved_by}}';
}
