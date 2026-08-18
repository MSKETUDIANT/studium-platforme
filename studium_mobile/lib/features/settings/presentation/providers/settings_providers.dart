import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kThemeKey  = 'settings_theme';
const _kLocaleKey = 'settings_locale';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

//  Thème

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.light;
  }

  Future<void> _load() async {
    final val = await ref.read(secureStorageProvider).read(key: _kThemeKey);
    if (val == 'dark') state = ThemeMode.dark;
  }

  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await ref.read(secureStorageProvider).write(
        key: _kThemeKey, value: state == ThemeMode.dark ? 'dark' : 'light');
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

//  Locale

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _load();
    return const Locale('fr');
  }

  Future<void> _load() async {
    final val = await ref.read(secureStorageProvider).read(key: _kLocaleKey);
    if (val == 'en') state = const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await ref.read(secureStorageProvider).write(key: _kLocaleKey, value: locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

//  Réglages plateforme (configurés côté dashboard)

// Nombre de mots minimum recommandé pour la lettre de motivation.
// Lu depuis platform_settings (clé motivation_min_words) au lieu d'être
// codé en dur côté mobile, pour rester cohérent avec le seuil configuré
// par l'équipe dans le dashboard. Repli sur 300 (défaut dashboard) si le
// réglage est absent ou en cas d'erreur réseau.
final motivationMinWordsProvider = FutureProvider<int>((ref) async {
  const fallback = 300;
  try {
    final data = await Supabase.instance.client
        .from('platform_settings')
        .select('value')
        .eq('key', 'motivation_min_words')
        .maybeSingle();
    final raw = data?['value'] as String?;
    if (raw == null) return fallback;
    return int.tryParse(raw) ?? fallback;
  } catch (_) {
    return fallback;
  }
});
