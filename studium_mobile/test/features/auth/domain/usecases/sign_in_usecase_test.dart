import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studium_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:studium_mobile/features/auth/domain/models/auth_user.dart';
import 'package:studium_mobile/features/auth/domain/usecases/sign_in_usecase.dart';

class MockAuthRepositoryImpl extends Mock implements AuthRepositoryImpl {}

void main() {
  late MockAuthRepositoryImpl repository;
  late SignInUsecase usecase;

  setUp(() {
    repository = MockAuthRepositoryImpl();
    usecase = SignInUsecase(repository);
  });

  final user = StudiumUser(
    id: 'u1',
    email: 'test@test.com',
    role: 'student',
    status: 'active',
    createdAt: DateTime(2026, 1, 1),
  );

  test('throws when email is empty', () {
    expect(
      () => usecase(email: '', password: 'longenough'),
      throwsA(isA<Exception>()),
    );
  });

  test('throws when password is empty', () {
    expect(
      () => usecase(email: 'test@test.com', password: ''),
      throwsA(isA<Exception>()),
    );
  });

  test('throws when password is shorter than 8 characters', () {
    expect(
      () => usecase(email: 'test@test.com', password: 'short'),
      throwsA(isA<Exception>()),
    );
  });

  test('delegates to repository.login and returns its result on valid input', () async {
    when(() => repository.login(email: 'test@test.com', password: 'longenough'))
        .thenAnswer((_) async => user);

    final result = await usecase(email: 'test@test.com', password: 'longenough');

    expect(result, user);
    verify(() => repository.login(email: 'test@test.com', password: 'longenough')).called(1);
  });
}
