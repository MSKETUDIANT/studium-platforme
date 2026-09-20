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
    'shows the raw error text in red with a retry button that re-fetches the documents',
    (tester) async {
      final repository = MockDocumentRepository();
      var callCount = 0;
      when(() => repository.getDocuments('u1')).thenAnswer((_) {
        callCount++;
        if (callCount == 1) throw Exception('boom');
        return Future.value(const []);
      });

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
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Réessayer'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Réessayer'));
      await tester.pumpAndSettle();

      expect(callCount, 2);
      expect(find.textContaining('boom'), findsNothing);
      expect(find.text('Aucun document'), findsOneWidget);
    },
  );
}
