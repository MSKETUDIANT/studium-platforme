import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/messaging_remote_datasource.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final messagingDatasourceProvider = Provider<MessagingRemoteDatasource>(
  (ref) => MessagingRemoteDatasource(ref.watch(supabaseClientProvider)),
);

// ─── Conversation ID ─────────────────────────────────────────────────────────

final conversationIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.read(messagingDatasourceProvider).getOrCreateConversation(userId);
});

// ─── Messages Notifier ───────────────────────────────────────────────────────

class MessagesNotifier extends AutoDisposeAsyncNotifier<List<MessageModel>> {
  RealtimeChannel? _channel;

  @override
  Future<List<MessageModel>> build() async {
    final convId = await ref.watch(conversationIdProvider.future);
    if (convId == null) return [];

    final ds       = ref.read(messagingDatasourceProvider);
    final messages = await ds.fetchMessages(convId);

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
