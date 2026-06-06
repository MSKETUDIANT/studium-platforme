import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/messaging_remote_datasource.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

//  Infrastructure 

final messagingDatasourceProvider = Provider<MessagingRemoteDatasource>(
  (ref) => MessagingRemoteDatasource(ref.watch(supabaseClientProvider)),
);

//  Badge non-lus étudiant (Realtime sur UPDATE) 

final unreadStudentProvider = StreamProvider.autoDispose<int>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(0);

  final client  = ref.watch(supabaseClientProvider);
  final ctrl    = StreamController<int>.broadcast();

  // Valeur initiale depuis la DB
  client
      .from('conversations')
      .select('unread_student')
      .eq('student_profile_id', userId)
      .maybeSingle()
      .then((data) {
        if (!ctrl.isClosed) {
          ctrl.add(data?['unread_student'] as int? ?? 0);
        }
      });

  // Écoute les UPDATE en temps réel
  final channel = client
      .channel('unread-student-$userId')
      .onPostgresChanges(
        event:  PostgresChangeEvent.update,
        schema: 'public',
        table:  'conversations',
        filter: PostgresChangeFilter(
          type:   PostgresChangeFilterType.eq,
          column: 'student_profile_id',
          value:  userId,
        ),
        callback: (payload) {
          final count = payload.newRecord['unread_student'] as int? ?? 0;
          if (!ctrl.isClosed) ctrl.add(count);
        },
      )
      .subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
    ctrl.close();
  });

  return ctrl.stream;
});

//  Conversation ID 

final conversationIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.read(messagingDatasourceProvider).getOrCreateConversation(userId);
});

//  Messages Notifier 

class MessagesNotifier extends AutoDisposeAsyncNotifier<List<MessageModel>> {
  RealtimeChannel? _channel;

  @override
  Future<List<MessageModel>> build() async {
    final convId = await ref.watch(conversationIdProvider.future);
    if (convId == null) return [];

    final ds       = ref.read(messagingDatasourceProvider);
    final messages = await ds.fetchMessages(convId);

    // Marquer les messages comme lus
    ref.read(supabaseClientProvider)
        .from('conversations')
        .update({'unread_student': 0})
        .eq('id', convId)
        .then((_) {})
        .catchError((_) {});

    // Abonnement Realtime
    _channel?.unsubscribe();
    _channel = ds.subscribeToMessages(
      conversationId: convId,
      onMessage: (msg) {
        final current = state.valueOrNull ?? [];
        // éviter les doublons (le message envoyé est déjà ajouté optimistiquement)
        if (!current.any((m) => m.id == msg.id)) {
          state = AsyncData([...current, msg]);
        }
      },
    );

    ref.onDispose(() {
      _channel?.unsubscribe();
      _channel = null;
    });

    return messages;
  }

  Future<void> send(String content) async {
    final userId = ref.read(currentUserIdProvider);
    final convId = await ref.read(conversationIdProvider.future);
    if (userId == null || convId == null) return;

    // Ajout optimiste
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = MessageModel(
      id:         tempId,
      senderType: 'student',
      content:    content,
      createdAt:  DateTime.now(),
    );
    state = AsyncData([...state.valueOrNull ?? [], tempMsg]);

    try {
      final real = await ref.read(messagingDatasourceProvider).sendMessage(
        conversationId: convId,
        studentId:      userId,
        content:        content,
      );
      // Remplacer le message temporaire par le vrai
      final current = state.valueOrNull ?? [];
      state = AsyncData(
        current.map((m) => m.id == tempId ? real : m).toList(),
      );
    } catch (_) {
      // Retirer le message temporaire en cas d'erreur
      final current = state.valueOrNull ?? [];
      state = AsyncData(current.where((m) => m.id != tempId).toList());
    }
  }
}

final messagesProvider =
    AsyncNotifierProvider.autoDispose<MessagesNotifier, List<MessageModel>>(
  MessagesNotifier.new,
);
