import 'package:supabase_flutter/supabase_flutter.dart';

class MessageModel {
  final String  id;
  final String  senderType;
  final String  content;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.senderType,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
    id:         j['id'] as String,
    senderType: j['sender_type'] as String,
    content:    j['content'] as String,
    createdAt:  DateTime.parse(j['created_at'] as String),
  );

  bool get isStaff => senderType == 'staff';
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
        .select('id, sender_type, content, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (data as List)
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Envoyer un message étudiant
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String studentId,
    required String content,
  }) async {
    final data = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_type':     'student',
          'sender_id':       studentId,
          'content':         content,
        })
        .select('id, sender_type, content, created_at')
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
