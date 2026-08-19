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
    'shows the raw error text in red, with no retry action, when the applications fetch fails',
    (tester) async {
      final repository = MockApplicationRepositoryImpl();
      final client = MockSupabaseClient();
      stubRealtimeChannel(client);
      when(() => repository.fetchMyApplications('u1')).thenThrow(Exception('boom'));

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

      // Current behavior: this screen offers no retry affordance on error.
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);
    },
  );
}
