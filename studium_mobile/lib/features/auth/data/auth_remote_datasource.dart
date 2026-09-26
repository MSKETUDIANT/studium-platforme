import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/cache_service.dart';
import 'models/user_model.dart';

class AuthRemoteDatasource {
  final SupabaseClient _client;
  AuthRemoteDatasource(this._client);

  Future<String?> _fetchRole(String userId) async {
    try {
      final data = await _client
          .from('user_roles')
          .select('roles(name)')
          .eq('user_id', userId)
          .single();
      debugPrint('=== ROLE DATA: $data');
      final roles = data['roles'];
      if (roles == null) return null;
      if (roles is Map) return roles['name'] as String?;
      if (roles is List && roles.isNotEmpty) return roles[0]['name'] as String?;
      return null;
    } catch (e) {
      debugPrint('=== FETCH ROLE ERROR: $e');
      return null;
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    late AuthResponse response;
    try {
      response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      // Intercepter email non confirmé avant que Supabase retourne un user
      if (e.code == 'email_not_confirmed' ||
          e.message.contains('email_not_confirmed') ||
          e.message.contains('Email not confirmed')) {
        throw const AppException('email_not_confirmed');
      }
      rethrow;
    }

    if (response.user == null) throw const AppException('Échec de la connexion');

    final role = await _fetchRole(response.user!.id);
    debugPrint('=== ROLE TROUVÉ: $role');

    if (role == null) {
      await _client.auth.signOut();
      throw const AppException('Profil introuvable. Contactez le support.');
    }

    const mobileRoles = ['student', 'ambassador'];
    if (!mobileRoles.contains(role)) {
      await _client.auth.signOut();
      throw const AppException(
        'Accès non autorisé. Cette application est réservée aux étudiants et ambassadeurs.',
      );
    }

    return UserModel.fromSupabase({
      'id':         response.user!.id,
      'email':      response.user!.email ?? email,
      'role':       role,
      'status':     'active',
      'created_at': response.user!.createdAt,
    });
  }

  Future<UserModel> register({
    required String email,
    required String password,
    String? refCode,
  }) async {
    late AuthResponse response;
    try {
      response = await _client.auth.signUp(
        email: email,
        password: password,
        // L'appelant (register_screen.dart) bloque déjà l'appel tant que la
        // case CGU/politique de confidentialité n'est pas cochée : on fixe
        // le consentement dès la création du compte, y compris quand la
        // confirmation email est requise (pas de session pour un updateUser
        // ultérieur dans ce cas). Google/Apple n'ont pas cette garantie
        // amont -> gérés séparément par l'écran d'interstitiel /accept-terms.
        data: {'terms_accepted': true},
        // Deep link natif plutôt que localhost:5173 (inatteignable hors de
        // la machine de dev) : le clic sur le lien de confirmation ouvre
        // directement l'app et finalise la session (cf. main.dart).
        emailRedirectTo: 'studium://confirm-email',
      );
    } on AuthException catch (e) {
      if (e.message.contains('already registered') ||
          e.message.contains('User already registered')) {
        throw const AppException('Cet email est déjà utilisé.');
      }
      rethrow;
    }

    if (response.user == null) throw const AppException("Échec de l'inscription");

    // Le rôle par défaut est attribué côté serveur par le trigger
    // assign_default_role() (AFTER INSERT sur auth.users) : un insert
    // client ici échouerait systématiquement (RLS, auth.uid() vide tant
    // que l'email n'est pas confirmé) et serait de toute façon redondant.

    if (refCode != null && refCode.isNotEmpty) {
      if (response.session != null) {
        // Session déjà active (cas où la confirmation email ne serait pas
        // exigée) : on peut appeler le RPC tout de suite.
        try {
          await _client.rpc('register_referral', params: {'p_code': refCode});
        } catch (e) {
          debugPrint('=== REGISTER REFERRAL ERROR: $e');
        }
      } else {
        // Confirmation email requise -> pas de session, donc auth.uid()
        // est vide et le RPC (SECURITY DEFINER mais basé sur auth.uid())
        // échouerait silencieusement. On mémorise le code pour le
        // rejouer une fois la session établie (cf. main.dart, deep link
        // studium://confirm-email).
        await CacheService.instance.set(
          CacheKeys.pendingRefCode,
          refCode,
          ttl: const Duration(days: 7),
        );
      }
    }

    return UserModel.fromSupabase({
      'id':         response.user!.id,
      'email':      response.user!.email ?? email,
      'role':       'student',
      'status':     'active',
      'created_at': response.user!.createdAt,
    });
  }

  Future<void> logout() async => await _client.auth.signOut();

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'studium://reset-password',
    );
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final role = await _fetchRole(user.id);
    debugPrint('=== CURRENT USER ROLE: $role');
    return UserModel.fromSupabase({
      'id':         user.id,
      'email':      user.email ?? '',
      'role':       role ?? 'student',
      'status':     'active',
      'created_at': user.createdAt,
    });
  }
}