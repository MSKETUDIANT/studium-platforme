import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/program_model.dart';
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
      final data = await _client
          .from('programs')
          .select()
          .eq('is_active', true)
          .order('program_name', ascending: true);
      // Mettre en cache 6 heures
      await CacheService.instance.set(CacheKeys.programs, data, ttl: const Duration(hours: 6));
      return (data as List).map((e) => ProgramModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
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
