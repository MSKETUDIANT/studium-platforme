import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/document_remote_datasource.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDatasource _datasource;

  const DocumentRepositoryImpl(this._datasource);

  @override
  Future<List<Document>> getDocuments(String studentProfileId) =>
      _datasource.getDocuments(studentProfileId);

  @override
  Future<Document> uploadDocument({
    required String studentProfileId,
    required DocumentType type,
    required String filePath,
    UploadProgressCallback? onProgress,
  }) =>
      _datasource.uploadDocument(
        studentProfileId: studentProfileId,
        type: type,
        filePath: filePath,
        onProgress: onProgress,
      );

  @override
  Future<void> deleteDocument(String documentId, String fileUrl) =>
      _datasource.deleteDocument(documentId, fileUrl);

  @override
  Future<Document> replaceDocument({
    required String documentId,
    required String studentProfileId,
    required DocumentType type,
    required String filePath,
    required String oldFileUrl,
    UploadProgressCallback? onProgress,
  }) =>
      _datasource.replaceDocument(
        documentId:       documentId,
        studentProfileId: studentProfileId,
        type:             type,
        filePath:         filePath,
        oldFileUrl:       oldFileUrl,
        onProgress:       onProgress,
      );
}