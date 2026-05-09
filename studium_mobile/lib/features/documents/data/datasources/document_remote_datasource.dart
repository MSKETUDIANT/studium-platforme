import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../models/document_model.dart';

const _kDocuments   = 'documents';
const _kDocsBucket  = 'documents';

class DocumentRemoteDatasource {
  final SupabaseClient _client;

  const DocumentRemoteDatasource(this._client);

  Future<List<DocumentModel>> getDocuments(String studentProfileId) async {
    try {
      final data = await _client
          .from(_kDocuments)
          .select()
          .eq('student_profile_id', studentProfileId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => DocumentModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw DocumentException(e.message, type: DocumentErrorType.server);
    } catch (e) {
      throw DocumentException(e.toString());
    }
  }

  Future<DocumentModel> uploadDocument({
    required String studentProfileId,
    required DocumentType type,
    required String filePath,
  }) async {
    try {
      final file     = File(filePath);
      final bytes    = await file.length();
      final fileName = filePath.split('/').last;
      final ext      = fileName.split('.').last.toLowerCase();
      final mimeType = _mimeFromExt(ext);
      final storagePath =
          '$studentProfileId/${type.name}/$fileName';

      // Upload fichier dans le bucket
      await _client.storage.from(_kDocsBucket).upload(
            storagePath,
            file,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      final fileUrl = _client.storage
          .from(_kDocsBucket)
          .getPublicUrl(storagePath);

      // Insérer la ligne dans la table
      final model = DocumentModel(
        id: '',
        studentProfileId: studentProfileId,
        type: type,
        fileUrl: fileUrl,
        fileName: fileName,
        mimeType: mimeType,
        sizeBytes: bytes,
        status: DocumentStatus.uploaded,
      );

      final data = await _client
          .from(_kDocuments)
          .insert(model.toInsertJson())
          .select()
          .single();

      return DocumentModel.fromJson(data);
    } on StorageException catch (e) {
      throw DocumentException(e.message, type: DocumentErrorType.server);
    } on PostgrestException catch (e) {
      throw DocumentException(e.message, type: DocumentErrorType.server);
    } catch (e) {
      throw DocumentException(e.toString());
    }
  }

  Future<void> deleteDocument(String documentId, String fileUrl) async {
    try {
      // Extraire le path depuis l'URL
      final uri  = Uri.parse(fileUrl);
      final path = uri.pathSegments
          .skipWhile((s) => s != _kDocsBucket)
          .skip(1)
          .join('/');

      await _client.storage.from(_kDocsBucket).remove([path]);
      await _client.from(_kDocuments).delete().eq('id', documentId);
    } on StorageException catch (e) {
      throw DocumentException(e.message, type: DocumentErrorType.server);
    } on PostgrestException catch (e) {
      throw DocumentException(e.message, type: DocumentErrorType.server);
    } catch (e) {
      throw DocumentException(e.toString());
    }
  }

  String _mimeFromExt(String ext) => switch (ext) {
        'pdf'  => 'application/pdf',
        'jpg'  => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png'  => 'image/png',
        'doc'  => 'application/msword',
        'docx' =>
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        _ => 'application/octet-stream',
      };
}