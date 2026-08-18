import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studium_mobile/features/applications/data/repositories/application_repository_impl.dart';
import 'package:studium_mobile/features/applications/domain/entities/application.dart';
import 'package:studium_mobile/features/applications/presentation/providers/application_providers.dart';
import 'package:studium_mobile/features/profile/presentation/providers/profile_providers.dart';

import '../../../helpers/realtime_mocks.dart';

class MockApplicationRepositoryImpl extends Mock implements ApplicationRepositoryImpl {}

Application _application({String id = 'app1', ApplicationStatus status = ApplicationStatus.draft}) => Application(
      id: id,
      studentId: 'u1',
      programId: 'p1',
      status: status,
    );

void main() {
  setUpAll(registerRealtimeFallbackValues);

  late MockApplicationRepositoryImpl repository;
  late MockSupabaseClient client;
  late ProviderContainer container;

  setUp(() {
    repository = MockApplicationRepositoryImpl();
    client = MockSupabaseClient();
    stubRealtimeChannel(client);

    container = ProviderContainer(overrides: [
      applicationRepositoryProvider.overrideWithValue(repository),
      supabaseClientProvider.overrideWithValue(client),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
    addTearDown(container.dispose);
  });

  test('build returns an empty list when there is no current user', () async {
    final noUserContainer = ProviderContainer(overrides: [
      applicationRepositoryProvider.overrideWithValue(repository),
      supabaseClientProvider.overrideWithValue(client),
      currentUserIdProvider.overrideWithValue(null),
    ]);
    addTearDown(noUserContainer.dispose);

    final result = await noUserContainer.read(myApplicationsProvider.future);

    expect(result, isEmpty);
    verifyNever(() => repository.fetchMyApplications(any()));
  });

  test('build subscribes to realtime updates and fetches applications', () async {
    when(() => repository.fetchMyApplications('u1')).thenAnswer((_) async => [_application()]);

    final result = await container.read(myApplicationsProvider.future);

    expect(result, hasLength(1));
    verify(() => client.channel('my-applications-u1')).called(1);
  });

  test('submit creates the application then invalidates the list', () async {
    when(() => repository.fetchMyApplications('u1')).thenAnswer((_) async => []);
    when(() => repository.createApplication(
          studentProfileId: 'u1',
          programId: 'p1',
          documentIds: const [],
          motivationLetter: null,
        )).thenAnswer((_) async => _application());

    await container.read(myApplicationsProvider.future);
    final result = await container.read(myApplicationsProvider.notifier).submit(programId: 'p1');
    await container.read(myApplicationsProvider.future);

    expect(result, isNotNull);
    verify(() => repository.fetchMyApplications('u1')).called(2);
  });

  test('saveDraft creates a draft application then invalidates the list', () async {
    when(() => repository.fetchMyApplications('u1')).thenAnswer((_) async => []);
    when(() => repository.createApplication(
          studentProfileId: 'u1',
          programId: 'p1',
          draft: true,
          motivationLetter: null,
        )).thenAnswer((_) async => _application());

    await container.read(myApplicationsProvider.future);
    await container.read(myApplicationsProvider.notifier).saveDraft(programId: 'p1');
    await container.read(myApplicationsProvider.future);

    verify(() => repository.fetchMyApplications('u1')).called(2);
  });

  test('submitDraft delegates to the repository then invalidates the list', () async {
    when(() => repository.fetchMyApplications('u1')).thenAnswer((_) async => []);
    when(() => repository.submitDraft('app1', documentIds: const [], motivationLetter: null))
        .thenAnswer((_) async => _application());

    await container.read(myApplicationsProvider.future);
    await container.read(myApplicationsProvider.notifier).submitDraft('app1');
    await container.read(myApplicationsProvider.future);

    verify(() => repository.submitDraft('app1', documentIds: const [], motivationLetter: null)).called(1);
    verify(() => repository.fetchMyApplications('u1')).called(2);
  });

  test('resubmit delegates to the repository then invalidates the list', () async {
    when(() => repository.fetchMyApplications('u1')).thenAnswer((_) async => []);
    when(() => repository.resubmit('app1')).thenAnswer((_) async => _application());

    await container.read(myApplicationsProvider.future);
    await container.read(myApplicationsProvider.notifier).resubmit('app1');
    await container.read(myApplicationsProvider.future);

    verify(() => repository.resubmit('app1')).called(1);
    verify(() => repository.fetchMyApplications('u1')).called(2);
  });
}
