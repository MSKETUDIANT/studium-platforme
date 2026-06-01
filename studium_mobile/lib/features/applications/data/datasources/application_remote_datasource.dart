import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/application_model.dart';

class StatusHistoryEntry {
  final String  id;
  final String? fromStatus;
  final String  toStatus;
  final String? note;
  final DateTime? createdAt;

  const StatusHistoryEntry({
    required this.id,
    this.fromStatus,
    required this.toStatus,
    this.note,
    this.createdAt,
  });

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> j) =>
      StatusHistoryEntry(
        id:         j['id'] as String,
        fromStatus: j['from_status'] as String?,
        toStatus:   j['to_status']   as String,
        note:       j['note']        as String?,
        createdAt:  j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );
}

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
    bool draft = false,
  }) async {
    final data = await _client
        .from(_kTable)
        .insert({
          'student_profile_id': studentProfileId,
          'program_id':         programId,
          'status':             draft ? 'draft' : 'submitted',
          if (!draft) 'submitted_at': DateTime.now().toIso8601String(),
        })
        .select(_kSelect)
        .single();
    return ApplicationModel.fromJson(data);
  }

  Future<List<StatusHistoryEntry>> fetchStatusHistory(String applicationId) async {
    final data = await _client
        .from('application_status_history')
        .select('id, from_status, to_status, note, created_at')
        .eq('application_id', applicationId)
        .order('created_at', ascending: true);
    return (data as List)
        .map((e) => StatusHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApplicationModel> submitDraft(String applicationId) async {
    final data = await _client
        .from(_kTable)
        .update({
          'status':       'submitted',
          'submitted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', applicationId)
        .select(_kSelect)
        .single();
    return ApplicationModel.fromJson(data);
  }
}
