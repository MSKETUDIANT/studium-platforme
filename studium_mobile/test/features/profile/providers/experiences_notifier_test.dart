import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studium_mobile/features/profile/domain/entities/experience.dart';
import 'package:studium_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:studium_mobile/features/profile/presentation/providers/profile_providers.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

Experience _experience({String id = 'e1'}) => Experience(
      id: id,
      studentProfileId: 'u1',
      company: 'ACME',
      position: 'Dev',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_experience());
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
  });

  test('build returns an empty list when there is no current user', () async {
    final noUserContainer = ProviderContainer(overrides: [
      profileRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue(null),
    ]);
    addTearDown(noUserContainer.dispose);

    final result = await noUserContainer.read(experiencesProvider.future);

    expect(result, isEmpty);
    verifyNever(() => repository.getExperiences(any()));
  });

  test('build fetches experiences for the current user', () async {
    when(() => repository.getExperiences('u1')).thenAnswer((_) async => [_experience()]);

    final result = await container.read(experiencesProvider.future);

    expect(result, hasLength(1));
    verify(() => repository.getExperiences('u1')).called(1);
  });

  test('add calls the repository then refreshes the list', () async {
    when(() => repository.getExperiences('u1')).thenAnswer((_) async => []);
    when(() => repository.addExperience(any())).thenAnswer((_) async => _experience());

    container.listen(experiencesProvider, (_, __) {});
    await container.read(experiencesProvider.future);

    await container.read(experiencesProvider.notifier).add(_experience());
    await container.read(experiencesProvider.future);

    verify(() => repository.addExperience(any())).called(1);
    verify(() => repository.getExperiences('u1')).called(2);
  });

  test('updateItem calls the repository then refreshes the list', () async {
    when(() => repository.getExperiences('u1')).thenAnswer((_) async => []);
    when(() => repository.updateExperience(any())).thenAnswer((_) async => _experience());

    container.listen(experiencesProvider, (_, __) {});
    await container.read(experiencesProvider.future);

    await container.read(experiencesProvider.notifier).updateItem(_experience());
    await container.read(experiencesProvider.future);

    verify(() => repository.updateExperience(any())).called(1);
    verify(() => repository.getExperiences('u1')).called(2);
  });

  test('delete calls the repository then refreshes the list', () async {
    when(() => repository.getExperiences('u1')).thenAnswer((_) async => []);
    when(() => repository.deleteExperience('e1')).thenAnswer((_) async {});

    container.listen(experiencesProvider, (_, __) {});
    await container.read(experiencesProvider.future);

    await container.read(experiencesProvider.notifier).delete('e1');
    await container.read(experiencesProvider.future);

    verify(() => repository.deleteExperience('e1')).called(1);
    verify(() => repository.getExperiences('u1')).called(2);
  });
}
