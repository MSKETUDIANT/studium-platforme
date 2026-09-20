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

  // Le nom de la classe et le type ne doivent pas fuiter dans l'UI : de
  // nombreux ecrans affichent directement e.toString() a l'utilisateur.
  @override
  String toString() => message;
}

typedef UploadProgressCallback = void Function(int sent, int total);

abstract interface class DocumentRepository {
  Future<List<Document>> getDocuments(String studentProfileId);
  Future<Document> uploadDocument({
    required String studentProfileId,
    required DocumentType type,
    required String filePath,
    UploadProgressCallback? onProgress,
  });
  Future<void> deleteDocument(String documentId, String fileUrl);
  Future<String> getSignedUrl(String fileUrl);
  Future<Document> replaceDocument({
    required String documentId,
    required String studentProfileId,
    required DocumentType type,
    required String filePath,
    required String oldFileUrl,
    UploadProgressCallback? onProgress,
  });
}