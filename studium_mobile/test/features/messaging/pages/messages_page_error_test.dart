import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studium_mobile/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:studium_mobile/features/messaging/presentation/pages/messages_page.dart';
import 'package:studium_mobile/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:studium_mobile/features/profile/presentation/providers/profile_providers.dart';

class MockMessagingRemoteDatasource extends Mock implements MessagingRemoteDatasource {}

void main() {
  testWidgets(
    'shows the rich error state with a retry action when the messages fetch fails, '
    'and retry re-triggers the fetch',
    (tester) async {
      final datasource = MockMessagingRemoteDatasource();
      when(() => datasource.getOrCreateConversation('u1')).thenAnswer((_) async => 'conv1');
      when(() => datasource.fetchMessages('conv1')).thenThrow(Exception('boom'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            messagingDatasourceProvider.overrideWithValue(datasource),
            currentUserIdProvider.overrideWithValue('u1'),
          ],
          child: const MaterialApp(home: MessagesPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Erreur de chargement'), findsOneWidget);
      expect(find.textContaining('boom'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();

      verify(() => datasource.fetchMessages('conv1')).called(2);
    },
  );
}
