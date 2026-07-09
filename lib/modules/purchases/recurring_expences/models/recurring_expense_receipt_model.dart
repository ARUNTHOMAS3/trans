class RecurringExpenseReceipt {
  final String id;
  final String recurringExpenseId;
  final String fileName;
  final String fileUrl;
  final int? fileSize;
  final String? uploadedBy;
  final String? uploadedAt;

  const RecurringExpenseReceipt({
    required this.id,
    required this.recurringExpenseId,
    required this.fileName,
    required this.fileUrl,
    this.fileSize,
    this.uploadedBy,
    this.uploadedAt,
  });

  factory RecurringExpenseReceipt.fromJson(Map<String, dynamic> json) {
    return RecurringExpenseReceipt(
      id: (json['id'] ?? '').toString(),
      recurringExpenseId: (json['recurring_expense_id'] ?? '').toString(),
      fileName: (json['file_name'] ?? '').toString(),
      fileUrl: (json['file_url'] ?? '').toString(),
      fileSize: (json['file_size'] as num?)?.toInt(),
      uploadedBy: json['uploaded_by']?.toString(),
      uploadedAt: json['uploaded_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'recurring_expense_id': recurringExpenseId,
      'file_name': fileName,
      'file_url': fileUrl,
      if (fileSize != null) 'file_size': fileSize,
      if (uploadedBy != null) 'uploaded_by': uploadedBy,
      if (uploadedAt != null) 'uploaded_at': uploadedAt,
    };
  }

  RecurringExpenseReceipt copyWith({
    String? id,
    String? recurringExpenseId,
    String? fileName,
    String? fileUrl,
    int? fileSize,
    String? uploadedBy,
    String? uploadedAt,
  }) {
    return RecurringExpenseReceipt(
      id: id ?? this.id,
      recurringExpenseId: recurringExpenseId ?? this.recurringExpenseId,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileSize: fileSize ?? this.fileSize,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}
