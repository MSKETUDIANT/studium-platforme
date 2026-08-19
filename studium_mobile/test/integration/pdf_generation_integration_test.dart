import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:studium_mobile/features/applications/domain/entities/application.dart';
import 'package:studium_mobile/features/applications/presentation/pdf/application_pdf_builder.dart';
import 'package:studium_mobile/features/documents/presentation/providers/document_providers.dart';
import 'package:studium_mobile/features/profile/presentation/providers/profile_providers.dart';

import '../helpers/fake_supabase_server.dart';

Application _application() => Application(
      id: 'app12345',
      studentId: 'u1',
      programId: 'p1',
      status: ApplicationStatus.needsFix,
      submittedAt: DateTime(2026, 6, 1),
      motivationText: 'Je souhaite intégrer ce programme.',
      programName: 'Master Informatique',
      universityName: 'Université de Studium',
      country: 'France',
      level: 'master',
    );

void main() {
  late FakeSupabaseServer fakeServer;
  late SupabaseClient client;
  late ProviderContainer container;

  setUp(() async {
    fakeServer = await FakeSupabaseServer.start();
    client = SupabaseClient(fakeServer.url, 'test-anon-key');
    container = ProviderContainer(overrides: [
      supabaseClientProvider.overrideWithValue(client),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await fakeServer.close();
  });

  test('builds a real, valid PDF from data fetched through the real provider graph', () async {
    fakeServer.stub('GET', '/rest/v1/student_profiles', statusCode: 200, body: [
      {
        'id': 'u1',
        'email': 'aly@example.com',
        'first_name': 'Aly',
        'last_name': 'Syla',
        'phone': null,
        'nationality': 'Guinea Conakry',
        'birth_date': null,
        'country_residence': 'France',
        'address': null,
        'photo_url': null,
        'motivation_letter': 'Lettre de motivation générique du profil.',
        'academic_goals': 'Approfondir mes compétences en IA.',
        'career_goals': 'Devenir ingénieur logiciel.',
        'completeness_score': 75,
      }
    ]);
    fakeServer.stub('GET', '/rest/v1/academic_backgrounds', statusCode: 200, body: [
      {
        'id': 'ac1',
        'user_id': 'u1',
        'degree': 'Licence en Informatique',
        'university': 'Univ Conakry',
        'year': 2025,
        'average': 15.5,
      }
    ]);
    fakeServer.stub('GET', '/rest/v1/experiences', statusCode: 200, body: [
      {
        'id': 'e1',
        'student_profile_id': 'u1',
        'company': 'ACME',
        'position': 'Développeur',
        'start_date': '2024-01-01T00:00:00.000Z',
        'end_date': null,
        'description': 'Développement mobile Flutter.',
      }
    ]);
    fakeServer.stub('GET', '/rest/v1/documents', statusCode: 200, body: [
      {
        'id': 'doc1',
        'student_profile_id': 'u1',
        'type': 'cv',
        'file_url': '${fakeServer.url}/storage/v1/object/public/documents/u1/cv/cv.pdf',
        'file_name': 'cv.pdf',
        'mime_type': 'application/pdf',
        'size_bytes': 2048,
        'status': 'approved',
        'rejection_reason': null,
        'created_at': '2026-01-01T00:00:00.000Z',
      }
    ]);

    final profile = await container.read(profileProvider.future);
    final academics = await container.read(academicBackgroundsProvider.future);
    final experiences = await container.read(experiencesProvider.future);
    final documents = await container.read(documentsProvider.future);

    expect(profile?.fullName, 'Aly Syla');
    expect(academics, hasLength(1));
    expect(experiences, hasLength(1));
    expect(documents, hasLength(1));

    final bytes = await buildApplicationPdfBytes(
      app: _application(),
      profile: profile,
      academics: academics,
      experiences: experiences,
      documents: documents,
      motivationLetter: _application().motivationText,
      accent: const Color(0xFF6366F1),
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('builds a valid single-page PDF even with no profile, academics, experiences or documents', () async {
    fakeServer.stub('GET', '/rest/v1/student_profiles', statusCode: 200, body: []);
    fakeServer.stub('GET', '/rest/v1/academic_backgrounds', statusCode: 200, body: []);
    fakeServer.stub('GET', '/rest/v1/experiences', statusCode: 200, body: []);
    fakeServer.stub('GET', '/rest/v1/documents', statusCode: 200, body: []);

    final profile = await container.read(profileProvider.future);
    final academics = await container.read(academicBackgroundsProvider.future);
    final experiences = await container.read(experiencesProvider.future);
    final documents = await container.read(documentsProvider.future);

    final bytes = await buildApplicationPdfBytes(
      app: _application(),
      profile: profile,
      academics: academics,
      experiences: experiences,
      documents: documents,
      motivationLetter: null,
      accent: const Color(0xFF6366F1),
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
