import 'dart:io';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;

import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../models/document_model.dart';

const _kDocuments   = 'documents';
const _kDocsBucket  = 'documents';

class DocumentRemoteDatasource {
  final SupabaseClient _client;
  final Dio _dio = Dio();

  DocumentRemoteDatasource(this._client);

  // Upload direct (bypass du client storage_client, qui n'expose aucun
  // callback de progression) : réutilise l'URL et les headers déjà
  // configurés par le SDK Supabase (auth + apikey), reproduit exactement
  // la requête multipart que storage_client envoie en interne, mais via
  // Dio pour bénéficier de onSendProgress.
  Future<void> _uploadWithProgress({
    required String storagePath,
    required File file,
    required String mimeType,
    UploadProgressCallback? onProgress,
  }) async {
    final api     = _client.storage.from(_kDocsBucket);
    final url     = '${api.url}/object/$_kDocsBucket/$storagePath';
    final headers = {...api.headers, 'x-upsert': 'true'};

    final formData = FormData()
      ..files.add(MapEntry(
        '',
        await MultipartFile.fromFile(
          file.path,
          filename: '',
          contentType: DioMediaType.parse(mimeType),
        ),
      ))
      ..fields.add(const MapEntry('cacheControl', '3600'));

    await _dio.post(
      url,
      data: formData,
      options: Options(headers: headers),
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent, total);
      },
    );
  }

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
    UploadProgressCallback? onProgress,
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
      await _uploadWithProgress(
        storagePath: storagePath,
        file:        file,
        mimeType:    mimeType,
        onProgress:  onProgress,
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

  Future<DocumentModel> replaceDocument({
    required String documentId,
    required String studentProfileId,
    required DocumentType type,
    required String filePath,
    required String oldFileUrl,
    UploadProgressCallback? onProgress,
  }) async {
    try {
      final file     = File(filePath);
      final bytes    = await file.length();
      final fileName = filePath.split('/').last;
      final ext      = fileName.split('.').last.toLowerCase();
      final mimeType = _mimeFromExt(ext);
      final storagePath = '$studentProfileId/${type.name}/$fileName';

      // Supprime l'ancien fichier (non bloquant si absent)
      try {
        final oldUri  = Uri.parse(oldFileUrl);
        final oldPath = oldUri.pathSegments
            .skipWhile((s) => s != _kDocsBucket)
            .skip(1)
            .join('/');
        await _client.storage.from(_kDocsBucket).remove([oldPath]);
      } catch (_) {}

      await _uploadWithProgress(
        storagePath: storagePath,
        file:        file,
        mimeType:    mimeType,
        onProgress:  onProgress,
      );
      final fileUrl =
          _client.storage.from(_kDocsBucket).getPublicUrl(storagePath);

      final data = await _client
          .from(_kDocuments)
          .update({
            'file_url':         fileUrl,
            'file_name':        fileName,
            'mime_type':        mimeType,
            'size_bytes':       bytes,
            'status':           'uploaded',
            'rejection_reason': null,
          })
          .eq('id', documentId)
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