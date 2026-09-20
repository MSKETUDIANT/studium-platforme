import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studium_mobile/features/applications/data/repositories/application_repository_impl.dart';
import 'package:studium_mobile/features/applications/presentation/pages/applications_page.dart';
import 'package:studium_mobile/features/applications/presentation/providers/application_providers.dart';
import 'package:studium_mobile/features/profile/presentation/providers/profile_providers.dart';

import '../../../helpers/realtime_mocks.dart';

class MockApplicationRepositoryImpl extends Mock implements ApplicationRepositoryImpl {}

void main() {
  setUpAll(registerRealtimeFallbackValues);

  testWidgets(
    'shows the raw error text in red with a retry button that re-fetches the applications',
    (tester) async {
      final repository = MockApplicationRepositoryImpl();
      final client = MockSupabaseClient();
      stubRealtimeChannel(client);
      var callCount = 0;
      when(() => repository.fetchMyApplications('u1')).thenAnswer((_) {
        callCount++;
        if (callCount == 1) throw Exception('boom');
        return Future.value(const []);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            applicationRepositoryProvider.overrideWithValue(repository),
            supabaseClientProvider.overrideWithValue(client),
            currentUserIdProvider.overrideWithValue('u1'),
          ],
          child: const MaterialApp(home: ApplicationsPage()),
        ),
      );
      await tester.pump();

      expect(find.textContaining('boom'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.textContaining('boom'));
      expect(textWidget.style?.color, Colors.red);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Réessayer'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Réessayer'));
      await tester.pumpAndSettle();

      expect(callCount, 2);
      expect(find.textContaining('boom'), findsNothing);
    },
  );
}
