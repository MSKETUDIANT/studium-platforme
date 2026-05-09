import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/program_model.dart';

class ProgramRemoteDatasource {
  final SupabaseClient _client;
  const ProgramRemoteDatasource(this._client);

  Future<List<ProgramModel>> getPrograms() async {
    try {
      final data = await _client
          .from('programs')
          .select()
          .eq('is_active', true)
          .order('program_name', ascending: true);
      return (data as List).map((e) => ProgramModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
