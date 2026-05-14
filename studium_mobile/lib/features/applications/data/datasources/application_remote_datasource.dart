import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/application_model.dart';

const _kTable  = 'applications';
const _kSelect = '''
  id, student_id, program_id, status, submitted_at, created_at,
  motivation_text, notes,
  programs!program_id(program_name, university_name, country, level)''';

class ApplicationRemoteDatasource {
  final SupabaseClient _client;
  const ApplicationRemoteDatasource(this._client);

  Future<List<ApplicationModel>> fetchMyApplications(String studentId) async {
    final data = await _client
        .from(_kTable)
        .select(_kSelect)
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => ApplicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApplicationModel> createApplication({
    required String studentId,
    required String programId,
    String? motivationText,
  }) async {
    final data = await _client
        .from(_kTable)
        .insert({
          'student_id':   studentId,
          'program_id':   programId,
          'status':       'submitted',
          'submitted_at': DateTime.now().toIso8601String(),
          if (motivationText != null && motivationText.isNotEmpty)
            'motivation_text': motivationText,
        })
        .select(_kSelect)
        .single();
    return ApplicationModel.fromJson(data);
  }
}
