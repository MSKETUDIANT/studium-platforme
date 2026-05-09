import '../models/auth_user.dart';
import '../../data/auth_repository_impl.dart';

class SignInUsecase {
  final AuthRepositoryImpl _repository;

  SignInUsecase(this._repository);

  Future<StudiumUser> call({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email et mot de passe requis');
    }
    if (password.length < 8) {
      throw Exception('Le mot de passe doit contenir au moins 8 caractères');
    }
    return _repository.login(email: email, password: password);
  }
}