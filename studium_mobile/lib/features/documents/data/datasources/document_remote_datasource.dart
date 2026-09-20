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
    final api = _client.storage.from(_kDocsBucket);
    // Chaque segment du chemin doit être encodé individuellement (le nom de
    // fichier peut contenir espaces/accents/parenthèses) : une concaténation
    // brute produit une URL invalide, rejetée par le serveur avec un 400.
    final encodedPath = storagePath.split('/').map(Uri.encodeComponent).join('/');
    final url = '${api.url}/object/$_kDocsBucket/$encodedPath';
    // api.headers est fige au moment de la creation du SupabaseClient (juste
    // l'apikey) : contrairement a postgrest/functions, le client storage ne
    // recoit jamais l'Authorization dynamiquement (pas d'AuthHttpClient sur
    // cet appel Dio manuel). Il faut donc lire le token de session courant
    // nous-memes, sinon le serveur rejette la requete (400, authorization
    // manquant), peu importe le fichier envoye.
    final accessToken = _client.auth.currentSession?.accessToken;
    final headers = {
      ...api.headers,
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      'x-upsert': 'true',
    };

    // Pas de reprise octet-par-octet (demanderait le protocole TUS, hors
    // scope) : une coupure reseau pendant l'envoi relance l'upload depuis le
    // debut, jusqu'a 3 tentatives, pour absorber les coupures breves/timeouts
    // sans faire echouer l'upload au premier accroc. 'x-upsert' garantit
    // qu'une tentative reussie apres echec ecrase proprement, sans doublon.
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
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

      try {
        await _dio.post(
          url,
          data: formData,
          options: Options(headers: headers),
          onSendProgress: (sent, total) {
            if (total > 0) onProgress?.call(sent, total);
          },
        );
        return;
      } on DioException catch (e) {
        // Pas de reponse serveur (timeout, coupure, DNS...) ou 5xx : probablement
        // transitoire, on retente. Une reponse 4xx (fichier invalide, auth...)
        // ne changera pas au prochain essai, inutile d'insister.
        final retryable = e.response == null || (e.response!.statusCode ?? 0) >= 500;
        if (!retryable || attempt == maxAttempts) {
          // Le message par defaut de Dio ("bad syntax") masque la vraie raison
          // renvoyee par Supabase Storage dans le corps de la reponse.
          throw DocumentException(
            'Upload failed (${e.response?.statusCode}): ${e.response?.data}',
            type: DocumentErrorType.server,
          );
        }
        await Future.delayed(Duration(seconds: attempt));
      }
    }
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

  // Le bucket "documents" est prive : fileUrl garde le format d'URL publique
  // historique (pratique pour en extraire le chemin de facon fiable), mais
  // n'est plus directement accessible. On signe une URL de courte duree
  // juste avant l'ouverture du fichier plutot que de la stocker.
  Future<String> getSignedUrl(String fileUrl, {int expiresInSeconds = 60}) async {
    try {
      final uri  = Uri.parse(fileUrl);
      final path = uri.pathSegments
          .skipWhile((s) => s != _kDocsBucket)
          .skip(1)
          .join('/');
      return await _client.storage
          .from(_kDocsBucket)
          .createSignedUrl(path, expiresInSeconds);
    } on StorageException catch (e) {
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