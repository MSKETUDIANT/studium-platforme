enum DocumentType {
  cv,
  transcript,
  recommendation,
  passport,
  other,
}

enum DocumentStatus {
  uploaded,
  underReview,
  approved,
  rejected,
}

class Document {
  final String id;
  final String studentProfileId;
  final DocumentType type;
  final String fileUrl;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final DocumentStatus status;
  final String? rejectionReason;
  final DateTime? createdAt;

  const Document({
    required this.id,
    required this.studentProfileId,
    required this.type,
    required this.fileUrl,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.status,
    this.rejectionReason,
    this.createdAt,
  });

  String get typeLabel => switch (type) {
        DocumentType.cv           => 'CV',
        DocumentType.transcript   => 'Relevé de notes',
        DocumentType.recommendation => 'Lettre de recommandation',
        DocumentType.passport     => 'Passeport',
        DocumentType.other        => 'Autre',
      };

  String get statusLabel => switch (status) {
        DocumentStatus.uploaded    => 'Uploadé',
        DocumentStatus.underReview => 'En révision',
        DocumentStatus.approved    => 'Approuvé',
        DocumentStatus.rejected    => 'Rejeté',
      };

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}