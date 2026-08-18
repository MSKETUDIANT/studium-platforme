import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studium_mobile/features/profile/domain/entities/academic_background.dart';
import 'package:studium_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:studium_mobile/features/profile/presentation/providers/profile_providers.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

AcademicBackground _academic({String id = 'ac1'}) => AcademicBackground(
      id: id,
      userId: 'u1',
      degree: 'Licence',
      university: 'Univ Test',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_academic());
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

    final result = await noUserContainer.read(academicBackgroundsProvider.future);

    expect(result, isEmpty);
    verifyNever(() => repository.getAcademicBackgrounds(any()));
  });

  test('build fetches academic backgrounds for the current user', () async {
    when(() => repository.getAcademicBackgrounds('u1')).thenAnswer((_) async => [_academic()]);

    final result = await container.read(academicBackgroundsProvider.future);

    expect(result, hasLength(1));
    verify(() => repository.getAcademicBackgrounds('u1')).called(1);
  });

  test('add calls the repository then refreshes the list', () async {
    when(() => repository.getAcademicBackgrounds('u1')).thenAnswer((_) async => []);
    when(() => repository.addAcademicBackground(any())).thenAnswer((_) async => _academic());

    container.listen(academicBackgroundsProvider, (_, __) {});
    await container.read(academicBackgroundsProvider.future);

    await container.read(academicBackgroundsProvider.notifier).add(_academic());
    await container.read(academicBackgroundsProvider.future);

    verify(() => repository.addAcademicBackground(any())).called(1);
    verify(() => repository.getAcademicBackgrounds('u1')).called(2);
  });

  test('updateItem calls the repository then refreshes the list', () async {
    when(() => repository.getAcademicBackgrounds('u1')).thenAnswer((_) async => []);
    when(() => repository.updateAcademicBackground(any())).thenAnswer((_) async => _academic());

    container.listen(academicBackgroundsProvider, (_, __) {});
    await container.read(academicBackgroundsProvider.future);

    await container.read(academicBackgroundsProvider.notifier).updateItem(_academic());
    await container.read(academicBackgroundsProvider.future);

    verify(() => repository.updateAcademicBackground(any())).called(1);
    verify(() => repository.getAcademicBackgrounds('u1')).called(2);
  });

  test('delete calls the repository then refreshes the list', () async {
    when(() => repository.getAcademicBackgrounds('u1')).thenAnswer((_) async => []);
    when(() => repository.deleteAcademicBackground('ac1')).thenAnswer((_) async {});

    container.listen(academicBackgroundsProvider, (_, __) {});
    await container.read(academicBackgroundsProvider.future);

    await container.read(academicBackgroundsProvider.notifier).delete('ac1');
    await container.read(academicBackgroundsProvider.future);

    verify(() => repository.deleteAcademicBackground('ac1')).called(1);
    verify(() => repository.getAcademicBackgrounds('u1')).called(2);
  });
}
