import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class FakePostgresChangeFilter extends Fake implements PostgresChangeFilter {}

class FakeRealtimeChannel extends Fake implements RealtimeChannel {}

/// Registers mocktail fallback values needed to stub arguments used in the
/// Supabase Realtime channel chain (channel -> onPostgresChanges -> subscribe).
/// Call once per test file, in `setUpAll()`.
void registerRealtimeFallbackValues() {
  registerFallbackValue(PostgresChangeEvent.all);
  registerFallbackValue(FakePostgresChangeFilter());
  registerFallbackValue(FakeRealtimeChannel());
}

/// Stubs [client] so any `.channel(name).onPostgresChanges(...).subscribe()`
/// chain resolves to a no-op [MockRealtimeChannel] instead of attempting a
/// real websocket connection, and stubs [SupabaseClient.removeChannel] for
/// the matching teardown. Reused by notifiers that open a Realtime
/// subscription directly on the raw client (not behind a datasource).
MockRealtimeChannel stubRealtimeChannel(MockSupabaseClient client) {
  final channel = MockRealtimeChannel();

  when(() => client.channel(any())).thenReturn(channel);
  when(() => channel.onPostgresChanges(
        event: any(named: 'event'),
        schema: any(named: 'schema'),
        table: any(named: 'table'),
        filter: any(named: 'filter'),
        callback: any(named: 'callback'),
      )).thenReturn(channel);
  when(() => channel.subscribe()).thenReturn(channel);
  when(() => client.removeChannel(any())).thenAnswer((_) async => 'ok');

  return channel;
}
