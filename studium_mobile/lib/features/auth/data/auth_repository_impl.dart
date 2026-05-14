import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/auth_user.dart';
import 'auth_remote_datasource.dart';

class AuthRepositoryImpl {
  final AuthRemoteDatasource _datasource;

  final _googleSignIn = GoogleSignIn(
    clientId: '261169092172-17qnsu38p3rs6u185vsnjqepl9gtd4fd.apps.googleusercontent.com',
  );

  AuthRepositoryImpl()
      : _datasource = AuthRemoteDatasource(Supabase.instance.client);

  Future<StudiumUser> login({
    required String email,
    required String password,
  }) => _datasource.login(email: email, password: password);

  Future<StudiumUser> register({
    required String email,
    required String password,
  }) => _datasource.register(email: email, password: password);

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _datasource.logout();
  }

  Future<void> resetPassword(String email) =>
      _datasource.resetPassword(email);

  Future<StudiumUser?> getCurrentUser() => _datasource.getCurrentUser();

  Future<StudiumUser> signInWithGoogle() async {
    await _googleSignIn.signOut();

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Connexion Google annulée');

    final googleAuth = await googleUser.authentication;

    final response = await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );

    if (response.user == null) throw Exception('Échec de la connexion Google');

    // Vérifier le rôle via datasource
    final user = await _datasource.getCurrentUser();
    if (user == null) throw Exception('Utilisateur introuvable');

    // Accès mobile réservé aux étudiants et ambassadeurs
    const mobileRoles = ['student', 'ambassador'];
    if (!mobileRoles.contains(user.role)) {
      await logout();
      throw Exception(
        'Accès non autorisé. Cette application est réservée aux étudiants et ambassadeurs.',
      );
    }

    return user;
  }
}