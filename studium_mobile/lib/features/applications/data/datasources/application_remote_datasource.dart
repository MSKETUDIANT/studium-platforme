import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/application_model.dart';

const _kTable  = 'applications';
const _kSelect = '''
  id, student_profile_id, program_id, status, submitted_at, created_at,
  programs!program_id(program_name, university_name, country, level)''';

class ApplicationRemoteDatasource {
  final SupabaseClient _client;
  const ApplicationRemoteDatasource(this._client);

  Future<List<ApplicationModel>> fetchMyApplications(String studentProfileId) async {
    final data = await _client
        .from(_kTable)
        .select(_kSelect)
        .eq('student_profile_id', studentProfileId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApplicationModel> createApplication({
    required String studentProfileId,
    required String programId,
  }) async {
    final data = await _client
        .from(_kTable)
        .insert({
          'student_profile_id': studentProfileId,
          'program_id':         programId,
          'status':             'submitted',
          'submitted_at':       DateTime.now().toIso8601String(),
        })
        .select(_kSelect)
        .single();
    return ApplicationModel.fromJson(data);
  }
}
