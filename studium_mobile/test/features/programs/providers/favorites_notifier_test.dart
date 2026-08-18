import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studium_mobile/features/profile/presentation/providers/profile_providers.dart';
import 'package:studium_mobile/features/programs/domain/repositories/program_repository.dart';
import 'package:studium_mobile/features/programs/presentation/providers/program_providers.dart';

class MockProgramRepository extends Mock implements ProgramRepository {}

void main() {
  late MockProgramRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockProgramRepository();
    container = ProviderContainer(overrides: [
      programRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
    addTearDown(container.dispose);
  });

  test('build returns an empty set when there is no current user', () async {
    final noUserContainer = ProviderContainer(overrides: [
      programRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue(null),
    ]);
    addTearDown(noUserContainer.dispose);

    final result = await noUserContainer.read(favoriteProgramIdsProvider.future);

    expect(result, isEmpty);
    verifyNever(() => repository.fetchFavoriteIds(any()));
  });

  test('build fetches favorite ids for the current user', () async {
    when(() => repository.fetchFavoriteIds('u1')).thenAnswer((_) async => {'p1'});

    final result = await container.read(favoriteProgramIdsProvider.future);

    expect(result, {'p1'});
  });

  test('toggle adds a program that is not yet favorited', () async {
    when(() => repository.fetchFavoriteIds('u1')).thenAnswer((_) async => {});
    when(() => repository.addFavorite('u1', 'p1')).thenAnswer((_) async {});

    await container.read(favoriteProgramIdsProvider.future);
    await container.read(favoriteProgramIdsProvider.notifier).toggle('p1');

    expect(container.read(favoriteProgramIdsProvider).valueOrNull, {'p1'});
    verify(() => repository.addFavorite('u1', 'p1')).called(1);
    verifyNever(() => repository.removeFavorite(any(), any()));
  });

  test('toggle removes a program that is already favorited', () async {
    when(() => repository.fetchFavoriteIds('u1')).thenAnswer((_) async => {'p1'});
    when(() => repository.removeFavorite('u1', 'p1')).thenAnswer((_) async {});

    await container.read(favoriteProgramIdsProvider.future);
    await container.read(favoriteProgramIdsProvider.notifier).toggle('p1');

    expect(container.read(favoriteProgramIdsProvider).valueOrNull, isEmpty);
    verify(() => repository.removeFavorite('u1', 'p1')).called(1);
    verifyNever(() => repository.addFavorite(any(), any()));
  });
}
