import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studium_mobile/features/documents/domain/entities/document.dart';
import 'package:studium_mobile/features/documents/domain/repositories/document_repository.dart';
import 'package:studium_mobile/features/documents/presentation/providers/document_providers.dart';
import 'package:studium_mobile/features/profile/presentation/providers/profile_providers.dart';

class MockDocumentRepository extends Mock implements DocumentRepository {}

Document _doc({String id = 'd1'}) => Document(
      id: id,
      studentProfileId: 'u1',
      type: DocumentType.cv,
      fileUrl: 'https://example.com/cv.pdf',
      fileName: 'cv.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 1024,
      status: DocumentStatus.uploaded,
    );

void main() {
  late MockDocumentRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockDocumentRepository();
    container = ProviderContainer(overrides: [
      documentRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
    addTearDown(container.dispose);
  });

  test('build returns an empty list when there is no current user', () async {
    final noUserContainer = ProviderContainer(overrides: [
      documentRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue(null),
    ]);
    addTearDown(noUserContainer.dispose);

    final result = await noUserContainer.read(documentsProvider.future);

    expect(result, isEmpty);
    verifyNever(() => repository.getDocuments(any()));
  });

  test('build fetches documents for the current user', () async {
    when(() => repository.getDocuments('u1')).thenAnswer((_) async => [_doc()]);

    final result = await container.read(documentsProvider.future);

    expect(result, hasLength(1));
    verify(() => repository.getDocuments('u1')).called(1);
  });

  test('upload calls the repository then invalidates the list', () async {
    when(() => repository.getDocuments('u1')).thenAnswer((_) async => []);
    when(() => repository.uploadDocument(
          studentProfileId: 'u1',
          type: DocumentType.cv,
          filePath: '/tmp/cv.pdf',
          onProgress: null,
        )).thenAnswer((_) async => _doc());

    container.listen(documentsProvider, (_, __) {});
    await container.read(documentsProvider.future);

    await container.read(documentsProvider.notifier).upload(
          type: DocumentType.cv,
          filePath: '/tmp/cv.pdf',
        );
    await container.read(documentsProvider.future);

    verify(() => repository.uploadDocument(
          studentProfileId: 'u1',
          type: DocumentType.cv,
          filePath: '/tmp/cv.pdf',
          onProgress: null,
        )).called(1);
    // invalidateSelf() triggered a refetch.
    verify(() => repository.getDocuments('u1')).called(2);
  });

  test('delete swallows repository errors (current behavior) but still refreshes the list', () async {
    when(() => repository.getDocuments('u1')).thenAnswer((_) async => []);
    when(() => repository.deleteDocument('d1', 'https://example.com/cv.pdf'))
        .thenThrow(Exception('boom'));

    container.listen(documentsProvider, (_, __) {});
    await container.read(documentsProvider.future);

    // AsyncValue.guard() swallows the exception; delete() never rethrows it.
    await container.read(documentsProvider.notifier).delete('d1', 'https://example.com/cv.pdf');
    await container.read(documentsProvider.future);

    verify(() => repository.deleteDocument('d1', 'https://example.com/cv.pdf')).called(1);
    verify(() => repository.getDocuments('u1')).called(2);
  });

  test('replace calls the repository then invalidates the list', () async {
    when(() => repository.getDocuments('u1')).thenAnswer((_) async => []);
    when(() => repository.replaceDocument(
          documentId: 'd1',
          studentProfileId: 'u1',
          type: DocumentType.cv,
          filePath: '/tmp/new-cv.pdf',
          oldFileUrl: 'https://example.com/cv.pdf',
        )).thenAnswer((_) async => _doc());

    container.listen(documentsProvider, (_, __) {});
    await container.read(documentsProvider.future);

    await container.read(documentsProvider.notifier).replace(
          documentId: 'd1',
          type: DocumentType.cv,
          filePath: '/tmp/new-cv.pdf',
          oldFileUrl: 'https://example.com/cv.pdf',
        );
    await container.read(documentsProvider.future);

    verify(() => repository.getDocuments('u1')).called(2);
  });
}
