import '../../domain/entities/document.dart';

class DocumentModel extends Document {
  const DocumentModel({
    required super.id,
    required super.studentProfileId,
    required super.type,
    required super.fileUrl,
    required super.fileName,
    required super.mimeType,
    required super.sizeBytes,
    required super.status,
    super.rejectionReason,
    super.createdAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      studentProfileId: json['student_profile_id'] as String,
      type: _parseType(json['type'] as String),
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String,
      mimeType: json['mime_type'] as String,
      sizeBytes: json['size_bytes'] as int,
      status: _parseStatus(json['status'] as String),
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'student_profile_id': studentProfileId,
        'type': _typeToString(type),
        'file_url': fileUrl,
        'file_name': fileName,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'status': 'uploaded',
      };

  static DocumentType _parseType(String value) => switch (value.toLowerCase()) {
        'cv'             => DocumentType.cv,
        'transcript'     => DocumentType.transcript,
        'recommendation' => DocumentType.recommendation,
        'passport'       => DocumentType.passport,
        _                => DocumentType.other,
      };

  static String _typeToString(DocumentType type) => switch (type) {
        DocumentType.cv             => 'cv',
        DocumentType.transcript     => 'transcript',
        DocumentType.recommendation => 'recommendation',
        DocumentType.passport       => 'passport',
        DocumentType.other          => 'other',
      };

  static DocumentStatus _parseStatus(String value) => switch (value) {
        'uploaded'     => DocumentStatus.uploaded,
        'under_review' => DocumentStatus.underReview,
        'approved'     => DocumentStatus.approved,
        'rejected'     => DocumentStatus.rejected,
        _              => DocumentStatus.uploaded,
      };
}