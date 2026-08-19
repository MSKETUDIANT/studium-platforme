import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studium_mobile/features/documents/domain/repositories/document_repository.dart';
import 'package:studium_mobile/features/documents/presentation/pages/documents_page.dart';
import 'package:studium_mobile/features/documents/presentation/providers/document_providers.dart';
import 'package:studium_mobile/features/profile/presentation/providers/profile_providers.dart';

class MockDocumentRepository extends Mock implements DocumentRepository {}

void main() {
  testWidgets(
    'shows the raw error text in red, with no retry action, when the document fetch fails',
    (tester) async {
      final repository = MockDocumentRepository();
      when(() => repository.getDocuments('u1')).thenThrow(Exception('boom'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            documentRepositoryProvider.overrideWithValue(repository),
            currentUserIdProvider.overrideWithValue('u1'),
          ],
          child: const MaterialApp(home: DocumentsPage()),
        ),
      );
      await tester.pump();

      expect(find.textContaining('boom'), findsOneWidget);
      final textWidget = tester.widget<Text>(find.textContaining('boom'));
      expect(textWidget.style?.color, Colors.red);

      // Current behavior: this screen offers no retry affordance on error.
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    },
  );
}
