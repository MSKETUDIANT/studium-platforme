import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studium_mobile/features/ambassador/data/repositories/ambassador_repository_impl.dart';
import 'package:studium_mobile/features/ambassador/domain/entities/commission.dart';
import 'package:studium_mobile/features/ambassador/presentation/providers/ambassador_providers.dart';
import 'package:studium_mobile/features/profile/presentation/providers/profile_providers.dart';

class MockAmbassadorRepositoryImpl extends Mock implements AmbassadorRepositoryImpl {}

Commission _commission({String id = 'c1', num amount = 50}) => Commission(
      id: id,
      ambassadorUserId: 'u1',
      amount: amount,
      status: CommissionStatus.payable,
    );

void main() {
  late MockAmbassadorRepositoryImpl repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockAmbassadorRepositoryImpl();
    container = ProviderContainer(overrides: [
      ambassadorRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
    addTearDown(container.dispose);
  });

  test('build returns an empty list when there is no current user', () async {
    final noUserContainer = ProviderContainer(overrides: [
      ambassadorRepositoryProvider.overrideWithValue(repository),
      currentUserIdProvider.overrideWithValue(null),
    ]);
    addTearDown(noUserContainer.dispose);

    final result = await noUserContainer.read(myCommissionsProvider.future);

    expect(result, isEmpty);
    verifyNever(() => repository.fetchMyCommissions(any()));
  });

  test('build fetches commissions for the current user', () async {
    when(() => repository.fetchMyCommissions('u1')).thenAnswer((_) async => [_commission()]);

    final result = await container.read(myCommissionsProvider.future);

    expect(result, hasLength(1));
    verify(() => repository.fetchMyCommissions('u1')).called(1);
  });

  test('requestPayout delegates to the repository with the commission id and amount', () async {
    when(() => repository.fetchMyCommissions('u1')).thenAnswer((_) async => []);
    when(() => repository.requestPayout('c1', 50)).thenAnswer((_) async {});

    await container.read(myCommissionsProvider.future);
    await container.read(myCommissionsProvider.notifier).requestPayout(_commission());

    verify(() => repository.requestPayout('c1', 50)).called(1);
  });
}
