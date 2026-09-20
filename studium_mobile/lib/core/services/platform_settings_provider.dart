import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/presentation/providers/profile_providers.dart'
    show supabaseClientProvider;

/// Limites d'upload configurables par l'equipe (dashboard -> Parametres ->
/// Plateforme, table platform_settings) : le mobile les lisait jamais et
/// utilisait des valeurs figees dans le code, desynchronisees de ce que
/// l'equipe configure reellement.
class UploadSettings {
  final int maxSizeMb;
  final List<String> allowedExtensions;
  const UploadSettings({required this.maxSizeMb, required this.allowedExtensions});
}

const _defaultUploadSettings = UploadSettings(
  maxSizeMb: 10,
  allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
);

final uploadSettingsProvider = FutureProvider<UploadSettings>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final rows = await client
        .from('platform_settings')
        .select('key, value')
        .inFilter('key', ['upload_max_size_mb', 'upload_allowed_formats']);

    final map = {
      for (final row in (rows as List))
        row['key'] as String: row['value'] as String,
    };

    final maxSizeMb = int.tryParse(map['upload_max_size_mb'] ?? '') ??
        _defaultUploadSettings.maxSizeMb;
    final formats = (map['upload_allowed_formats'] ?? '')
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();

    return UploadSettings(
      maxSizeMb: maxSizeMb,
      allowedExtensions: formats.isNotEmpty ? formats : _defaultUploadSettings.allowedExtensions,
    );
  } catch (_) {
    // Table non lisible / vide / hors-ligne : on retombe sur des valeurs
    // par defaut plutot que de bloquer tout upload.
    return _defaultUploadSettings;
  }
});

/// Langues activees par l'equipe (dashboard -> Parametres -> Plateforme,
/// cle "available_languages") : le selecteur de langue proposait toujours
/// FR + EN en dur, sans lien avec ce que l'equipe configure.
const _defaultAvailableLanguages = ['fr', 'en'];

final availableLanguagesProvider = FutureProvider<List<String>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final rows = await client
        .from('platform_settings')
        .select('value')
        .eq('key', 'available_languages')
        .maybeSingle();

    final codes = ((rows?['value'] as String?) ?? '')
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();

    return codes.isNotEmpty ? codes : _defaultAvailableLanguages;
  } catch (_) {
    return _defaultAvailableLanguages;
  }
});
