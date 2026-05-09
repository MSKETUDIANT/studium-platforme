import '../entities/document.dart';

enum DocumentErrorType {
  notFound,
  unauthorized,
  network,
  server,
  fileTooLarge,
  unknown,
}

class DocumentException implements Exception {
  final String message;
  final DocumentErrorType type;

  const DocumentException(
    this.message, {
    this.type = DocumentErrorType.unknown,
  });

  @override
  String toString() => 'DocumentException(${type.name}): $message';
}

abstract interface class DocumentRepository {
  Future<List<Document>> getDocuments(String studentProfileId);
  Future<Document> uploadDocument({
    required String studentProfileId,
    required DocumentType type,
    required String filePath,
  });
  Future<void> deleteDocument(String documentId, String fileUrl);
}