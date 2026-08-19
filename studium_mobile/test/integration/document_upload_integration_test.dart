import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:studium_mobile/features/documents/domain/entities/document.dart';
import 'package:studium_mobile/features/documents/domain/repositories/document_repository.dart';
import 'package:studium_mobile/features/documents/presentation/providers/document_providers.dart';
import 'package:studium_mobile/features/profile/presentation/providers/profile_providers.dart';

import '../helpers/fake_supabase_server.dart';

Map<String, dynamic> _documentJson({
  String id = 'doc1',
  String type = 'cv',
  String fileUrl = 'http://127.0.0.1/storage/v1/object/public/documents/u1/cv/resume.pdf',
  String fileName = 'resume.pdf',
  String status = 'uploaded',
}) => {
      'id': id,
      'student_profile_id': 'u1',
      'type': type,
      'file_url': fileUrl,
      'file_name': fileName,
      'mime_type': 'application/pdf',
      'size_bytes': 12,
      'status': status,
      'rejection_reason': null,
      'created_at': '2026-01-01T00:00:00.000Z',
    };

void main() {
  late FakeSupabaseServer fakeServer;
  late SupabaseClient client;
  late ProviderContainer container;
  late File tempFile;

  setUp(() async {
    fakeServer = await FakeSupabaseServer.start();
    client = SupabaseClient(fakeServer.url, 'test-anon-key');
    container = ProviderContainer(overrides: [
      supabaseClientProvider.overrideWithValue(client),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);

    final dir = await Directory.systemTemp.createTemp('studium_upload_test');
    tempFile = File('${dir.path}/resume.pdf');
    await tempFile.writeAsBytes(List<int>.filled(12, 65)); // 12 bytes, arbitrary content
  });

  tearDown(() async {
    container.dispose();
    await fakeServer.close();
    await tempFile.parent.delete(recursive: true);
  });

  test('getDocuments parses a real PostgREST array response through the real repository chain', () async {
    fakeServer.stub('GET', '/rest/v1/documents', statusCode: 200, body: [_documentJson()]);

    final result = await container.read(documentsProvider.future);

    expect(result, hasLength(1));
    expect(result.single.type, DocumentType.cv);
    expect(result.single.status, DocumentStatus.uploaded);
    expect(result.single.fileName, 'resume.pdf');
  });

  test('upload sends a real multipart request then a real PostgREST insert', () async {
    fakeServer.stub('GET', '/rest/v1/documents', statusCode: 200, body: []);
    fakeServer.stub(
      'POST',
      '/storage/v1/object/documents/u1/cv/resume.pdf',
      statusCode: 200,
      body: {'Key': 'documents/u1/cv/resume.pdf'},
    );
    fakeServer.stub(
      'POST',
      '/rest/v1/documents',
      statusCode: 201,
      body: _documentJson(id: 'new-doc'),
    );

    await container.read(documentsProvider.future);
    await container.read(documentsProvider.notifier).upload(
          type: DocumentType.cv,
          filePath: tempFile.path,
        );

    final uploadRequest = fakeServer.requests.firstWhere(
      (r) => r.method == 'POST' && r.path == '/storage/v1/object/documents/u1/cv/resume.pdf',
    );
    expect(uploadRequest.contentType, 'multipart/form-data');
    expect(uploadRequest.contentLength, greaterThan(0));

    final insertRequest = fakeServer.requests.firstWhere(
      (r) => r.method == 'POST' && r.path == '/rest/v1/documents',
    );
    final insertedBody = jsonDecode(insertRequest.body) as Map<String, dynamic>;
    expect(insertedBody['student_profile_id'], 'u1');
    expect(insertedBody['type'], 'cv');
    expect(insertedBody['file_name'], 'resume.pdf');
  });

  test('delete sends a storage removal and a PostgREST delete with the extracted path', () async {
    fakeServer.stub('DELETE', '/storage/v1/object/documents', statusCode: 200, body: []);
    fakeServer.stub('DELETE', '/rest/v1/documents', statusCode: 204, body: null);
    fakeServer.stub('GET', '/rest/v1/documents', statusCode: 200, body: []);

    await container.read(documentsProvider.future);
    await container.read(documentsProvider.notifier).delete(
          'doc1',
          '${fakeServer.url}/storage/v1/object/public/documents/u1/cv/resume.pdf',
        );

    final removeRequest = fakeServer.requests.firstWhere(
      (r) => r.method == 'DELETE' && r.path == '/storage/v1/object/documents',
    );
    final removeBody = jsonDecode(removeRequest.body) as Map<String, dynamic>;
    expect(removeBody['prefixes'], ['u1/cv/resume.pdf']);

    expect(
      fakeServer.requests.any((r) => r.method == 'DELETE' && r.path == '/rest/v1/documents'),
      isTrue,
    );
  });

  test('a Supabase-shaped error response surfaces as a DocumentException', () async {
    fakeServer.stub('GET', '/rest/v1/documents', statusCode: 200, body: []);
    fakeServer.stub(
      'POST',
      '/storage/v1/object/documents/u1/cv/resume.pdf',
      statusCode: 200,
      body: {'Key': 'documents/u1/cv/resume.pdf'},
    );
    fakeServer.stub(
      'POST',
      '/rest/v1/documents',
      statusCode: 400,
      body: {'message': 'insert violates row-level security policy', 'code': '42501'},
    );

    await container.read(documentsProvider.future);

    expect(
      () => container.read(documentsProvider.notifier).upload(
            type: DocumentType.cv,
            filePath: tempFile.path,
          ),
      throwsA(isA<DocumentException>()),
    );
  });
}
