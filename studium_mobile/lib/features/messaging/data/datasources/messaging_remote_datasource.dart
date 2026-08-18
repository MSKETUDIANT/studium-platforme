import 'dart:io' as io;
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kMsgBucket   = 'message-attachments';
const _kLargeBucket = 'large-file-transfers';

class MessageModel {
  final String   id;
  final String   senderType;
  final String   content;
  final DateTime createdAt;
  final String?  fileUrl;
  final String?  fileName;

  const MessageModel({
    required this.id,
    required this.senderType,
    required this.content,
    required this.createdAt,
    this.fileUrl,
    this.fileName,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
    id:         j['id'] as String,
    senderType: j['sender_type'] as String,
    content:    (j['content'] as String?) ?? '',
    createdAt:  DateTime.parse(j['created_at'] as String),
    fileUrl:    j['file_url']  as String?,
    fileName:   j['file_name'] as String?,
  );

  bool get isStaff      => senderType == 'staff';
  bool get hasAttachment => fileUrl != null && fileUrl!.isNotEmpty;
  bool get isImage {
    final ext = fileName?.split('.').last.toLowerCase() ?? '';
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }
}

class MessagingRemoteDatasource {
  final SupabaseClient _client;
  const MessagingRemoteDatasource(this._client);

  // Obtenir ou créer la conversation de l'étudiant
  Future<String> getOrCreateConversation(String studentProfileId) async {
    final existing = await _client
        .from('conversations')
        .select('id')
        .eq('student_profile_id', studentProfileId)
        .maybeSingle();

    if (existing != null) return existing['id'] as String;

    final created = await _client
        .from('conversations')
        .insert({'student_profile_id': studentProfileId})
        .select('id')
        .single();

    return created['id'] as String;
  }

  // Charger les messages d'une conversation
  Future<List<MessageModel>> fetchMessages(String conversationId) async {
    final data = await _client
        .from('messages')
        .select('id, sender_type, content, created_at, file_url, file_name')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (data as List)
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Uploader un fichier et retourner son URL publique
  Future<String> uploadAttachment({
    required String      userId,
    required String      fileName,
    required Uint8List   bytes,
    required String      mimeType,
  }) async {
    final ext  = fileName.split('.').last;
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from(_kMsgBucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: mimeType, upsert: true),
    );

    return _client.storage.from(_kMsgBucket).getPublicUrl(path);
  }

  // Uploader un fichier volumineux (Mode 2) et retourner un lien signé 30 jours
  Future<String> uploadLargeFile({
    required String userId,
    required String fileName,
    required String filePath,
    required String mimeType,
  }) async {
    final ext  = fileName.split('.').last;
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from(_kLargeBucket).upload(
      path,
      io.File(filePath),
      fileOptions: FileOptions(contentType: mimeType, upsert: true),
    );

    return await _client.storage
        .from(_kLargeBucket)
        .createSignedUrl(path, 30 * 24 * 3600); // 30 jours
  }

  // Envoyer un message étudiant (texte et/ou pièce jointe)
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String studentId,
    required String content,
    String? fileUrl,
    String? fileName,
  }) async {
    final data = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_type':     'student',
          'sender_id':       studentId,
          'content':         content,
          if (fileUrl  != null) 'file_url':  fileUrl,
          if (fileName != null) 'file_name': fileName,
        })
        .select('id, sender_type, content, created_at, file_url, file_name')
        .single();

    return MessageModel.fromJson(data);
  }

  // Abonnement Realtime aux nouveaux messages
  RealtimeChannel subscribeToMessages({
    required String conversationId,
    required void Function(MessageModel) onMessage,
  }) {
    return _client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'messages',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value:  conversationId,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isNotEmpty) onMessage(MessageModel.fromJson(row));
          },
        )
        .subscribe();
  }
}