class ExpenseAttachmentModel {
  const ExpenseAttachmentModel({
    required this.id,
    required this.expenseId,
    required this.fileName,
    required this.fileUrl,
    this.fileSize = 0,
    this.fileType,
    this.originalFileName,
    this.uploadedBy,
    this.remarks,
    this.createdAt,
  });

  final String id;
  final String expenseId;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String? fileType;
  final String? originalFileName;
  final String? uploadedBy;
  final String? remarks;
  final String? createdAt;

  factory ExpenseAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ExpenseAttachmentModel(
      id: (json['id'] ?? '').toString(),
      expenseId: (json['expense_id'] ?? json['expenseId'] ?? '').toString(),
      fileName: (json['file_name'] ?? json['fileName'] ?? '').toString(),
      fileUrl: (json['file_url'] ?? json['fileUrl'] ?? '').toString(),
      fileSize: (json['file_size'] as num?)?.toInt() ??
          int.tryParse((json['file_size'] ?? '0').toString()) ??
          0,
      fileType: (json['file_type'] ?? json['fileType'])?.toString(),
      originalFileName:
          (json['original_file_name'] ?? json['originalFileName'])?.toString(),
      uploadedBy: (json['uploaded_by'] ?? json['uploadedBy'])?.toString(),
      remarks: (json['remarks'] ?? '').toString().isEmpty
          ? null
          : (json['remarks'] ?? '').toString(),
      createdAt: (json['created_at'] ?? json['createdAt'])?.toString(),
    );
  }

  Map<String, dynamic> toAttachmentRequestJson() => <String, dynamic>{
        'file_name': fileName,
        'original_file_name': originalFileName,
        'file_url': fileUrl,
        'file_type': fileType,
        'file_size': fileSize,
        'remarks': remarks,
      };
}
