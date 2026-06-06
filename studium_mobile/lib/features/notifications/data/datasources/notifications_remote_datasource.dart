import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_notification.dart';

class NotificationsRemoteDatasource {
  final SupabaseClient _client;
  const NotificationsRemoteDatasource(this._client);

  Future<List<AppNotification>> fetchAll(String userId) async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List).map((r) => AppNotification.fromJson(r)).toList();
  }

  Future<int> fetchUnreadCount(String userId) async {
    final result = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .isFilter('read_at', null);
    return (result as List).length;
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', userId)
        .isFilter('read_at', null);
  }

  RealtimeChannel subscribeToUnread({
    required String userId,
    required void Function(int count) onCount,
  }) {
    return _client
        .channel('notifications-$userId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.insert,
          schema: 'public',
          table:  'notifications',
          filter: PostgresChangeFilter(
            type:   PostgresChangeFilterType.eq,
            column: 'user_id',
            value:  userId,
          ),
          callback: (_) async {
            final count = await fetchUnreadCount(userId);
            onCount(count);
          },
        )
        .subscribe();
  }
}
