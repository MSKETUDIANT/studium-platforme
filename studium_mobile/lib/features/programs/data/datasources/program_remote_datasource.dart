import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/program_model.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/cache_service.dart';

class ProgramRemoteDatasource {
  final SupabaseClient _client;
  const ProgramRemoteDatasource(this._client);

  Future<List<ProgramModel>> getPrograms() async {
    // Retourner depuis le cache si disponible
    final cached = CacheService.instance.get<List>(CacheKeys.programs);
    if (cached != null) {
      return cached.map((e) => ProgramModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    try {
      // Supabase plafonne chaque reponse a 1000 lignes (db-max-rows) meme
      // sans .range() explicite : on boucle par pages de 1000 pour ne
      // jamais tronquer silencieusement le catalogue.
      const pageSize = 1000;
      final all = <dynamic>[];
      var from = 0;
      while (true) {
        final page = await _client
            .from('programs')
            .select()
            .eq('is_active', true)
            .order('program_name', ascending: true)
            .range(from, from + pageSize - 1);
        all.addAll(page as List);
        if (page.length < pageSize) break;
        from += pageSize;
      }
      // Mettre en cache 6 heures
      await CacheService.instance.set(CacheKeys.programs, all, ttl: const Duration(hours: 6));
      return all.map((e) => ProgramModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  Future<Set<String>> fetchFavoriteIds(String studentProfileId) async {
    final data = await _client
        .from('program_favorites')
        .select('program_id')
        .eq('student_profile_id', studentProfileId);
    return (data as List).map((e) => e['program_id'] as String).toSet();
  }

  Future<void> addFavorite(String studentProfileId, String programId) =>
      _client.from('program_favorites').insert({
        'student_profile_id': studentProfileId,
        'program_id': programId,
      });

  Future<void> removeFavorite(String studentProfileId, String programId) =>
      _client
          .from('program_favorites')
          .delete()
          .eq('student_profile_id', studentProfileId)
          .eq('program_id', programId);
}
