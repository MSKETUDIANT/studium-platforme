import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:studium_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:studium_mobile/features/auth/domain/models/auth_user.dart';
import 'package:studium_mobile/features/auth/presentation/providers/auth_provider.dart';

class MockAuthRepositoryImpl extends Mock implements AuthRepositoryImpl {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockSession extends Mock implements Session {}

StudiumUser _user({String role = 'student'}) => StudiumUser(
      id: 'u1',
      email: 'test@test.com',
      role: role,
      status: 'active',
      createdAt: DateTime(2026, 1, 1),
    );

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late MockAuthRepositoryImpl repository;
  late MockGoTrueClient auth;
  late StreamController<AuthState> authChanges;

  setUp(() {
    repository = MockAuthRepositoryImpl();
    auth = MockGoTrueClient();
    authChanges = StreamController<AuthState>.broadcast();
    when(() => auth.onAuthStateChange).thenAnswer((_) => authChanges.stream);
    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.currentSession).thenReturn(null);
  });

  tearDown(() => authChanges.close());

  test('init: no current user resolves to data(null)', () async {
    final notifier = AuthNotifier(repository, auth: auth);
    await _settle();

    expect(notifier.state, const AsyncValue<StudiumUser?>.data(null));
    verifyNever(() => repository.getCurrentUser());
  });

  test('init: existing current user resolves to data(user)', () async {
    final user = _user();
    when(() => auth.currentUser).thenReturn(MockUser());
    when(() => repository.getCurrentUser()).thenAnswer((_) async => user);

    final notifier = AuthNotifier(repository, auth: auth);
    await _settle();

    expect(notifier.state, AsyncValue<StudiumUser?>.data(user));
  });

  group('signIn', () {
    test('success updates state to data(user)', () async {
      final user = _user();
      when(() => repository.login(email: 'test@test.com', password: 'longenough'))
          .thenAnswer((_) async => user);

      final notifier = AuthNotifier(repository, auth: auth);
      await _settle();
      await notifier.signIn(email: 'test@test.com', password: 'longenough');

      expect(notifier.state, AsyncValue<StudiumUser?>.data(user));
    });

    test('repository failure updates state to error', () async {
      when(() => repository.login(email: 'test@test.com', password: 'longenough'))
          .thenThrow(Exception('Identifiants invalides'));

      final notifier = AuthNotifier(repository, auth: auth);
      await _settle();
      await notifier.signIn(email: 'test@test.com', password: 'longenough');

      expect(notifier.state.hasError, isTrue);
    });
  });

  group('signUp', () {
    test('with an active session updates state to data(user)', () async {
      final user = _user();
      when(() => repository.register(
            email: 'test@test.com',
            password: 'longenough',
            refCode: null,
          )).thenAnswer((_) async => user);
      when(() => auth.currentSession).thenReturn(MockSession());

      final notifier = AuthNotifier(repository, auth: auth);
      await _settle();
      await notifier.signUp(email: 'test@test.com', password: 'longenough');

      expect(notifier.state, AsyncValue<StudiumUser?>.data(user));
    });

    test('without an active session (email confirmation pending) updates state to data(null)', () async {
      final user = _user();
      when(() => repository.register(
            email: 'test@test.com',
            password: 'longenough',
            refCode: null,
          )).thenAnswer((_) async => user);
      when(() => auth.currentSession).thenReturn(null);

      final notifier = AuthNotifier(repository, auth: auth);
      await _settle();
      await notifier.signUp(email: 'test@test.com', password: 'longenough');

      expect(notifier.state, const AsyncValue<StudiumUser?>.data(null));
    });

    test('repository failure updates state to error and rethrows', () async {
      when(() => repository.register(
            email: 'test@test.com',
            password: 'longenough',
            refCode: null,
          )).thenThrow(Exception('Email déjà utilisé'));

      final notifier = AuthNotifier(repository, auth: auth);
      await _settle();

      await expectLater(
        () => notifier.signUp(email: 'test@test.com', password: 'longenough'),
        throwsA(isA<Exception>()),
      );
      expect(notifier.state.hasError, isTrue);
    });
  });

  test('signOut logs out and updates state to data(null)', () async {
    when(() => repository.logout()).thenAnswer((_) async {});

    final notifier = AuthNotifier(repository, auth: auth);
    await _settle();
    await notifier.signOut();

    expect(notifier.state, const AsyncValue<StudiumUser?>.data(null));
    verify(() => repository.logout()).called(1);
  });

  group('onAuthStateChange', () {
    test('signedIn with an authorized role updates state to data(user)', () async {
      final user = _user(role: 'student');
      when(() => repository.getCurrentUser()).thenAnswer((_) async => user);

      AuthNotifier(repository, auth: auth);
      await _settle();
      authChanges.add(const AuthState(AuthChangeEvent.signedIn, null));
      await _settle();

      verifyNever(() => repository.logout());
    });

    test('signedIn with an unauthorized role forces logout and sets an error', () async {
      final user = _user(role: 'team');
      when(() => repository.getCurrentUser()).thenAnswer((_) async => user);
      when(() => repository.logout()).thenAnswer((_) async {});

      final notifier = AuthNotifier(repository, auth: auth);
      await _settle();
      authChanges.add(const AuthState(AuthChangeEvent.signedIn, null));
      await _settle();

      verify(() => repository.logout()).called(1);
      expect(notifier.state.hasError, isTrue);
      expect(notifier.state.error.toString(), contains('Accès non autorisé'));
    });

    test('signedOut updates state to data(null)', () async {
      final notifier = AuthNotifier(repository, auth: auth);
      await _settle();
      authChanges.add(const AuthState(AuthChangeEvent.signedOut, null));
      await _settle();

      expect(notifier.state, const AsyncValue<StudiumUser?>.data(null));
    });

    test('passwordRecovery does not change the current state', () async {
      final notifier = AuthNotifier(repository, auth: auth);
      await _settle();
      final stateBefore = notifier.state;

      authChanges.add(const AuthState(AuthChangeEvent.passwordRecovery, null));
      await _settle();

      expect(notifier.state, stateBefore);
    });
  });
}
