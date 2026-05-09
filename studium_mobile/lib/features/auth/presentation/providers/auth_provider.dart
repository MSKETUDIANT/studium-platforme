import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/usecases/sign_in_usecase.dart';

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl();
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<StudiumUser?>>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AsyncValue<StudiumUser?>> {
  final AuthRepositoryImpl _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    if (supabaseUser != null) {
      try {
        final user = await _repository.getCurrentUser();
        state = AsyncValue.data(user);
      } catch (_) {
        state = const AsyncValue.data(null);
      }
    } else {
      state = const AsyncValue.data(null);
    }

    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;

      if (event == AuthChangeEvent.passwordRecovery) return;

      if (event == AuthChangeEvent.signedIn) {
        try {
          final user = await _repository.getCurrentUser();

          // ✅ Vérifier le rôle avant d'autoriser l'accès
          const mobileRoles = ['student', 'ambassador'];
          if (user != null && !mobileRoles.contains(user.role)) {
            await _repository.logout();
            state = AsyncValue.error(
              Exception('Accès non autorisé. Cette application est réservée aux étudiants et ambassadeurs.'),
              StackTrace.current,
            );
            return;
          }

          state = AsyncValue.data(user);
        } catch (e) {
          state = AsyncValue.error(e, StackTrace.current);
        }
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final usecase = SignInUsecase(_repository);
      final user = await usecase(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.register(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}