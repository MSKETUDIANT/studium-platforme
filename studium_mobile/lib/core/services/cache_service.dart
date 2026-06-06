import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache local simple basé sur SharedPreferences.
/// Clé  JSON string avec timestamp d'expiration.
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  static const _defaultTtl = Duration(hours: 6);

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'CacheService.init() non appelé');
    return _prefs!;
  }

  //  Écriture 

  Future<void> set(String key, dynamic value, {Duration? ttl}) async {
    final expires = DateTime.now().add(ttl ?? _defaultTtl);
    final entry   = jsonEncode({'v': value, 'exp': expires.millisecondsSinceEpoch});
    await _p.setString(key, entry);
  }

  //  Lecture 

  T? get<T>(String key) {
    final raw = _p.getString(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final exp = DateTime.fromMillisecondsSinceEpoch(map['exp'] as int);
      if (DateTime.now().isAfter(exp)) {
        _p.remove(key);
        return null;
      }
      return map['v'] as T?;
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) => _p.remove(key);

  Future<void> clear() => _p.clear();

  bool has(String key) {
    final raw = _p.getString(key);
    if (raw == null) return false;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final exp = DateTime.fromMillisecondsSinceEpoch(map['exp'] as int);
      return DateTime.now().isBefore(exp);
    } catch (_) {
      return false;
    }
  }
}

//  Clés de cache 

abstract class CacheKeys {
  static const programs        = 'cache_programs';
  static const profile         = 'cache_profile';
  static const documents       = 'cache_documents';
  static const applications    = 'cache_applications';
  static const notifications   = 'cache_notifications';
}
