import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
        throw Exception('email_not_confirmed');
      }
      rethrow;
    }

    if (response.user == null) throw Exception('Échec de la connexion');

    final role = await _fetchRole(response.user!.id);
    debugPrint('=== ROLE TROUVÉ: $role');

    if (role == null) {
      await _client.auth.signOut();
      throw Exception('Profil introuvable. Contactez le support.');
    }

    const mobileRoles = ['student', 'ambassador'];
    if (!mobileRoles.contains(role)) {
      await _client.auth.signOut();
      throw Exception(
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
  }) async {
    late AuthResponse response;
    try {
      response = await _client.auth.signUp(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      if (e.message.contains('already registered') ||
          e.message.contains('User already registered')) {
        throw Exception('Cet email est déjà utilisé.');
      }
      rethrow;
    }

    if (response.user == null) throw Exception("Échec de l'inscription");

    try {
      await _client.from('user_roles').insert({
        'user_id': response.user!.id,
        'role_id': '6c61f080-50bd-4160-859d-902bc3110f34',
      });
    } catch (e) {
      debugPrint('=== INSERT ROLE ERROR: $e');
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