import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studium_mobile/features/profile/domain/entities/academic_background.dart';
import 'package:studium_mobile/features/profile/domain/entities/student_profile.dart';
import 'package:studium_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:studium_mobile/features/profile/presentation/providers/profile_providers.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

const _profile = StudentProfile(
  id: 'u1',
  firstName: 'Aly',
  lastName: 'Syla',
  nationality: 'Guinea Conakry',
  completenessScore: 25,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_profile);
  });

  late MockProfileRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockProfileRepository();
    container = ProviderContainer(overrides: [
      profileRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
    addTearDown(container.dispose);

    // build()'s Future.microtask(refreshScore) always fires — stub the
    // dependencies it needs by default so tests that don't care about the
    // score recompute aren't forced to stub them individually.
    when(() => repository.getAcademicBackgrounds('u1')).thenAnswer((_) async => []);
    when(() => repository.getExperiences('u1')).thenAnswer((_) async => []);
    when(() => repository.getDocumentsCount('u1')).thenAnswer((_) async => 0);
  });

  test('build returns null when there is no current user', () async {
    final noUserContainer = ProviderContainer(overrides: [
      profileRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue(null),
    ]);
    addTearDown(noUserContainer.dispose);

    final result = await noUserContainer.read(profileNotifierProvider.future);

    expect(result, isNull);
  });

  test('build fetches the profile for the current user', () async {
    when(() => repository.getProfile('u1')).thenAnswer((_) async => _profile);

    final result = await container.read(profileNotifierProvider.future);

    expect(result?.id, 'u1');
    verify(() => repository.getProfile('u1')).called(1);
  });

  test('upsert updates the profile then recomputes the score', () async {
    when(() => repository.getProfile('u1')).thenAnswer((_) async => _profile);
    when(() => repository.upsertProfile(any())).thenAnswer((_) async => _profile);

    await container.read(profileNotifierProvider.future);
    await container.read(profileNotifierProvider.notifier).upsert(_profile);

    verify(() => repository.upsertProfile(_profile)).called(1);
  });

  test('upsert failure surfaces as an AsyncError state', () async {
    when(() => repository.getProfile('u1')).thenAnswer((_) async => _profile);
    when(() => repository.upsertProfile(any())).thenThrow(Exception('boom'));

    await container.read(profileNotifierProvider.future);
    await container.read(profileNotifierProvider.notifier).upsert(_profile);

    expect(container.read(profileNotifierProvider).hasError, isTrue);
  });

  test('refreshScore recomputes and persists a changed score', () async {
    // Stored score is 25 (personal info only); with 1 academic background
    // the recomputed score should be 50, triggering a repository update.
    when(() => repository.getProfile('u1')).thenAnswer((_) async => _profile);
    when(() => repository.getAcademicBackgrounds('u1')).thenAnswer(
      (_) async => [AcademicBackground(id: 'ac1', userId: 'u1', degree: 'Licence', university: 'Univ')],
    );
    when(() => repository.upsertProfile(any())).thenAnswer((_) async => _profile);

    await container.read(profileNotifierProvider.future);
    await container.read(profileNotifierProvider.notifier).refreshScore();

    final captured = verify(() => repository.upsertProfile(captureAny())).captured;
    expect(captured, isNotEmpty);
    final updated = captured.last as StudentProfile;
    expect(updated.completenessScore, 50);
  });

  test('refreshScore is a no-op when the recomputed score is unchanged', () async {
    when(() => repository.getProfile('u1')).thenAnswer((_) async => _profile);
    // Stored score (25) already matches personal-info-only with no
    // academics/experiences/documents.

    await container.read(profileNotifierProvider.future);
    await container.read(profileNotifierProvider.notifier).refreshScore();

    verifyNever(() => repository.upsertProfile(any()));
  });

  test('updatePhoto calls the repository then reloads the profile', () async {
    when(() => repository.getProfile('u1')).thenAnswer((_) async => _profile);
    when(() => repository.updatePhoto('u1', '/tmp/photo.jpg')).thenAnswer((_) async => 'https://x/photo.jpg');

    await container.read(profileNotifierProvider.future);
    await container.read(profileNotifierProvider.notifier).updatePhoto('u1', '/tmp/photo.jpg');
    await container.read(profileNotifierProvider.future);

    verify(() => repository.updatePhoto('u1', '/tmp/photo.jpg')).called(1);
    verify(() => repository.getProfile('u1')).called(2);
  });

  test('deletePhoto calls the repository then reloads the profile', () async {
    when(() => repository.getProfile('u1')).thenAnswer((_) async => _profile);
    when(() => repository.deletePhoto('u1')).thenAnswer((_) async {});

    await container.read(profileNotifierProvider.future);
    await container.read(profileNotifierProvider.notifier).deletePhoto('u1');
    await container.read(profileNotifierProvider.future);

    verify(() => repository.deletePhoto('u1')).called(1);
    verify(() => repository.getProfile('u1')).called(2);
  });
}
