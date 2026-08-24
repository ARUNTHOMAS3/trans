class DocumentModel {
  final String id;
  final String sourceType;
  final String sourceRecordId;
  final String? associatedNumber;
  final String fileName;
  final String? fileUrl;
  final String? fileType;
  final int? fileSizeBytes;
  final String? uploadedBy;
  final DateTime? uploadedOn;
  final String? status;

  DocumentModel({
    required this.id,
    required this.sourceType,
    required this.sourceRecordId,
    this.associatedNumber,
    required this.fileName,
    this.fileUrl,
    this.fileType,
    this.fileSizeBytes,
    this.uploadedBy,
    this.uploadedOn,
    this.status,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    int? parsedSizeBytes;
    if (json['fileSizeBytes'] != null) {
      if (json['fileSizeBytes'] is int) {
        parsedSizeBytes = json['fileSizeBytes'] as int;
      } else if (json['fileSizeBytes'] is String) {
        parsedSizeBytes = int.tryParse(json['fileSizeBytes'] as String);
      } else if (json['fileSizeBytes'] is double) {
        parsedSizeBytes = (json['fileSizeBytes'] as double).toInt();
      }
    }

    return DocumentModel(
      id: json['id'] as String? ?? '',
      sourceType: json['sourceType'] as String? ?? 'Unknown',
      sourceRecordId: json['sourceRecordId'] as String? ?? '',
      associatedNumber: json['associatedNumber'] as String?,
      fileName: json['fileName'] as String? ?? 'Unknown',
      fileUrl: json['fileUrl'] as String?,
      fileType: json['fileType'] as String?,
      fileSizeBytes: parsedSizeBytes,
      uploadedBy: json['uploadedBy'] as String?,
      uploadedOn: json['uploadedOn'] != null
          ? DateTime.tryParse(json['uploadedOn'].toString())
          : null,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceType': sourceType,
      'sourceRecordId': sourceRecordId,
      'associatedNumber': associatedNumber,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'uploadedBy': uploadedBy,
      'uploadedOn': uploadedOn?.toIso8601String(),
      'status': status,
    };
  }
}
