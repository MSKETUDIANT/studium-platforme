import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../domain/entities/app_notification.dart';

final notificationsDatasourceProvider =
    Provider<NotificationsRemoteDatasource>(
  (ref) => NotificationsRemoteDatasource(ref.watch(supabaseClientProvider)),
);

//  Badge non-lus (Realtime) 

final unreadNotificationsProvider = StreamProvider.autoDispose<int>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(0);

  final client = ref.watch(supabaseClientProvider);
  final ds   = ref.read(notificationsDatasourceProvider);
  final ctrl = StreamController<int>.broadcast();

  ds.fetchUnreadCount(userId).then((count) {
    if (!ctrl.isClosed) ctrl.add(count);
  });

  final channel = ds.subscribeToUnread(
    userId: userId,
    onCount: (count) {
      if (!ctrl.isClosed) ctrl.add(count);
    },
  );

  ref.onDispose(() {
    client.removeChannel(channel);
    ctrl.close();
  });

  return ctrl.stream;
});

//  Liste notifications 

class NotificationsNotifier
    extends AutoDisposeAsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];
    return ref.read(notificationsDatasourceProvider).fetchAll(userId);
  }

  Future<void> markRead(String id) async {
    await ref.read(notificationsDatasourceProvider).markAsRead(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((n) => n.id == id ? n.copyWith(readAt: DateTime.now()) : n).toList(),
    );
    ref.invalidate(unreadNotificationsProvider);
  }

  Future<void> markAllRead() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref.read(notificationsDatasourceProvider).markAllAsRead(userId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((n) => n.copyWith(readAt: DateTime.now())).toList(),
    );
    ref.invalidate(unreadNotificationsProvider);
  }
}

final notificationsProvider = AsyncNotifierProvider.autoDispose<
    NotificationsNotifier, List<AppNotification>>(NotificationsNotifier.new);
