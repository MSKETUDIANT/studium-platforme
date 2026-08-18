import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:studium_mobile/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:studium_mobile/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:studium_mobile/features/profile/presentation/providers/profile_providers.dart';

import '../../../helpers/realtime_mocks.dart';

class MockMessagingRemoteDatasource extends Mock implements MessagingRemoteDatasource {}

/// Fakes just enough of the chainable Postgrest query builder to make the
/// notifier's fire-and-forget "mark conversation as read" call
/// (`client.from('conversations').update(...).eq(...).then(...).catchError(...)`)
/// resolve harmlessly instead of hitting a real network call.
class _NoopFilterBuilder extends Fake implements PostgrestFilterBuilder<dynamic> {
  @override
  PostgrestFilterBuilder<dynamic> eq(String column, Object value) => this;

  @override
  Future<U> then<U>(FutureOr<U> Function(dynamic value) onValue, {Function? onError}) =>
      Future<dynamic>.value(const []).then(onValue, onError: onError);
}

class _NoopQueryBuilder extends Fake implements SupabaseQueryBuilder {
  @override
  PostgrestFilterBuilder update(Map values) => _NoopFilterBuilder();
}

MessageModel _message({String id = 'm1', String senderType = 'staff', String content = 'hello'}) => MessageModel(
      id: id,
      senderType: senderType,
      content: content,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  setUpAll(() {
    registerRealtimeFallbackValues();
    registerFallbackValue(Uint8List(0));
  });

  late MockMessagingRemoteDatasource datasource;
  late MockSupabaseClient client;
  late MockRealtimeChannel channel;
  late ProviderContainer container;

  setUp(() {
    datasource = MockMessagingRemoteDatasource();
    client = MockSupabaseClient();
    channel = MockRealtimeChannel();
    when(() => client.from('conversations')).thenAnswer((_) => _NoopQueryBuilder());
    when(() => channel.unsubscribe()).thenAnswer((_) async => 'ok');
    when(() => datasource.subscribeToMessages(
          conversationId: any(named: 'conversationId'),
          onMessage: any(named: 'onMessage'),
        )).thenReturn(channel);

    container = ProviderContainer(overrides: [
      messagingDatasourceProvider.overrideWithValue(datasource),
      supabaseClientProvider.overrideWithValue(client),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
    addTearDown(container.dispose);
  });

  test('build returns an empty list when there is no current user', () async {
    final noUserContainer = ProviderContainer(overrides: [
      messagingDatasourceProvider.overrideWithValue(datasource),
      supabaseClientProvider.overrideWithValue(client),
      currentUserIdProvider.overrideWithValue(null),
    ]);
    addTearDown(noUserContainer.dispose);

    final result = await noUserContainer.read(messagesProvider.future);

    expect(result, isEmpty);
  });

  test('build fetches messages for the conversation and subscribes to realtime updates', () async {
    when(() => datasource.getOrCreateConversation('u1')).thenAnswer((_) async => 'conv1');
    when(() => datasource.fetchMessages('conv1')).thenAnswer((_) async => [_message()]);

    final result = await container.read(messagesProvider.future);

    expect(result, hasLength(1));
    verify(() => datasource.subscribeToMessages(
          conversationId: 'conv1',
          onMessage: any(named: 'onMessage'),
        )).called(1);
  });

  group('send', () {
    setUp(() {
      when(() => datasource.getOrCreateConversation('u1')).thenAnswer((_) async => 'conv1');
      when(() => datasource.fetchMessages('conv1')).thenAnswer((_) async => []);
      // Keep the autoDispose provider alive across the multiple reads below.
      container.listen(messagesProvider, (_, __) {});
    });

    test('optimistically appends a temp message then replaces it with the real one on success', () async {
      final completer = Completer<MessageModel>();
      when(() => datasource.sendMessage(
            conversationId: 'conv1',
            studentId: 'u1',
            content: 'Bonjour',
            fileUrl: null,
            fileName: null,
          )).thenAnswer((_) => completer.future);

      await container.read(messagesProvider.future);
      final sendFuture = container.read(messagesProvider.notifier).send('Bonjour');
      // send() awaits conversationIdProvider.future before the optimistic
      // append; let that microtask settle before inspecting state.
      await Future<void>.delayed(Duration.zero);

      // The optimistic temp message is visible before the repository call resolves.
      final duringSend = container.read(messagesProvider).valueOrNull!;
      expect(duringSend, hasLength(1));
      expect(duringSend.single.id, startsWith('temp_'));
      expect(duringSend.single.content, 'Bonjour');

      completer.complete(_message(id: 'real1', senderType: 'student', content: 'Bonjour'));
      await sendFuture;

      final afterSend = container.read(messagesProvider).valueOrNull!;
      expect(afterSend, hasLength(1));
      expect(afterSend.single.id, 'real1');
    });

    test('rolls back the optimistic message when the repository call fails', () async {
      when(() => datasource.sendMessage(
            conversationId: 'conv1',
            studentId: 'u1',
            content: 'Bonjour',
            fileUrl: null,
            fileName: null,
          )).thenThrow(Exception('network error'));

      await container.read(messagesProvider.future);
      await container.read(messagesProvider.notifier).send('Bonjour');

      expect(container.read(messagesProvider).valueOrNull, isEmpty);
    });

    test('uploads via uploadLargeFile when filePath is provided (mode 2)', () async {
      when(() => datasource.uploadLargeFile(
            userId: 'u1',
            fileName: 'big.pdf',
            filePath: '/tmp/big.pdf',
            mimeType: 'application/pdf',
          )).thenAnswer((_) async => 'https://signed-url');
      when(() => datasource.sendMessage(
            conversationId: 'conv1',
            studentId: 'u1',
            content: 'Fichier',
            fileUrl: 'https://signed-url',
            fileName: 'big.pdf',
          )).thenAnswer((_) async => _message(id: 'real2'));

      await container.read(messagesProvider.future);
      await container.read(messagesProvider.notifier).send(
            'Fichier',
            fileName: 'big.pdf',
            mimeType: 'application/pdf',
            filePath: '/tmp/big.pdf',
          );

      verify(() => datasource.uploadLargeFile(
            userId: 'u1',
            fileName: 'big.pdf',
            filePath: '/tmp/big.pdf',
            mimeType: 'application/pdf',
          )).called(1);
      verifyNever(() => datasource.uploadAttachment(
            userId: any(named: 'userId'),
            fileName: any(named: 'fileName'),
            bytes: any(named: 'bytes'),
            mimeType: any(named: 'mimeType'),
          ));
    });

    test('uploads via uploadAttachment when fileBytes is provided (mode 1)', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      when(() => datasource.uploadAttachment(
            userId: 'u1',
            fileName: 'small.png',
            bytes: bytes,
            mimeType: 'image/png',
          )).thenAnswer((_) async => 'https://public-url');
      when(() => datasource.sendMessage(
            conversationId: 'conv1',
            studentId: 'u1',
            content: 'Image',
            fileUrl: 'https://public-url',
            fileName: 'small.png',
          )).thenAnswer((_) async => _message(id: 'real3'));

      await container.read(messagesProvider.future);
      await container.read(messagesProvider.notifier).send(
            'Image',
            fileName: 'small.png',
            mimeType: 'image/png',
            fileBytes: bytes,
          );

      verify(() => datasource.uploadAttachment(
            userId: 'u1',
            fileName: 'small.png',
            bytes: bytes,
            mimeType: 'image/png',
          )).called(1);
      verifyNever(() => datasource.uploadLargeFile(
            userId: any(named: 'userId'),
            fileName: any(named: 'fileName'),
            filePath: any(named: 'filePath'),
            mimeType: any(named: 'mimeType'),
          ));
    });
  });
}
