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
  id, student_profile_id, program_id, status, submitted_at, created_at, motivation_letter,
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
    List<String> documentIds = const [],
    String? motivationLetter,
  }) async {
    final existing = await _client
        .from(_kTable)
        .select('id, status')
        .eq('student_profile_id', studentProfileId)
        .eq('program_id', programId)
        .not('status', 'in', '(archived,rejected)')
        .maybeSingle();

    if (existing != null) {
      throw Exception('Une candidature est déjà en cours pour ce programme.');
    }

    final data = await _client
        .from(_kTable)
        .insert({
          'student_profile_id': studentProfileId,
          'program_id':         programId,
          'status':             draft ? 'draft' : 'submitted',
          if (!draft) 'submitted_at': DateTime.now().toIso8601String(),
          if (motivationLetter != null && motivationLetter.trim().isNotEmpty)
            'motivation_letter': motivationLetter.trim(),
        })
        .select(_kSelect)
        .single();

    final app = ApplicationModel.fromJson(data);
    await _saveApplicationDocuments(app.id, documentIds);
    return app;
  }

  Future<void> _saveApplicationDocuments(
    String applicationId,
    List<String> documentIds,
  ) async {
    if (documentIds.isEmpty) return;
    // Remplace les liaisons existantes
    await _client
        .from('application_documents')
        .delete()
        .eq('application_id', applicationId);
    await _client.from('application_documents').insert(
      documentIds
          .map((docId) => {
                'application_id': applicationId,
                'document_id':    docId,
              })
          .toList(),
    );
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

  Future<ApplicationModel> submitDraft(
    String applicationId, {
    List<String> documentIds = const [],
    String? motivationLetter,
  }) async {
    final data = await _client
        .from(_kTable)
        .update({
          'status':       'submitted',
          'submitted_at': DateTime.now().toIso8601String(),
          if (motivationLetter != null && motivationLetter.trim().isNotEmpty)
            'motivation_letter': motivationLetter.trim(),
        })
        .eq('id', applicationId)
        .select(_kSelect)
        .single();
    await _saveApplicationDocuments(applicationId, documentIds);
    return ApplicationModel.fromJson(data);
  }

  Future<ApplicationModel> resubmit(String applicationId) async {
    final data = await _client
        .from(_kTable)
        .update({'status': 'submitted'})
        .eq('id', applicationId)
        .eq('status', 'needsfix')
        .select(_kSelect)
        .single();
    return ApplicationModel.fromJson(data);
  }
}
