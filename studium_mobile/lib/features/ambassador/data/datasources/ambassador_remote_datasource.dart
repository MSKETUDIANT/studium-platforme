import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/referral_model.dart';
import '../models/commission_model.dart';

class AmbassadorRemoteDatasource {
  final SupabaseClient _client;
  const AmbassadorRemoteDatasource(this._client);

  Future<List<ReferralModel>> fetchMyReferrals(String ambassadorUserId) async {
    final data = await _client
        .from('referrals')
        .select('id, ambassador_user_id, student_user_id, status, created_at, converted_at')
        .eq('ambassador_user_id', ambassadorUserId)
        .order('created_at', ascending: false);

    final rows = (data as List).cast<Map<String, dynamic>>();
    final studentIds = rows.map((r) => r['student_user_id'] as String).toSet().toList();

    final profilesById = <String, Map<String, dynamic>>{};
    if (studentIds.isNotEmpty) {
      final profiles = await _client
          .from('student_profiles')
          .select('id, first_name, last_name')
          .inFilter('id', studentIds);
      for (final p in (profiles as List).cast<Map<String, dynamic>>()) {
        profilesById[p['id'] as String] = p;
      }
    }

    return rows.map((r) {
      final profile = profilesById[r['student_user_id']];
      final name = profile != null
          ? '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim()
          : null;
      return ReferralModel.fromJson(r, studentName: name?.isEmpty ?? true ? null : name);
    }).toList();
  }

  Future<List<CommissionModel>> fetchMyCommissions(String ambassadorUserId) async {
    final data = await _client
        .from('commissions')
        .select('id, ambassador_user_id, amount, status, period_start, period_end, paid_at')
        .eq('ambassador_user_id', ambassadorUserId)
        .order('period_start', ascending: false);
    return (data as List)
        .map((e) => CommissionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> requestPayout(String commissionId, num amount) async {
    await _client.from('tasks').insert({
      'title': 'Demande de paiement — commission',
      'description': "L'ambassadeur a demandé le versement de sa commission de $amount (statut actuel : payable).",
      'task_type': 'manual',
      'priority': 'normal',
      'assignee_label': 'Admin',
    });
  }

  Future<String?> ensureReferralCode() async {
    final result = await _client.rpc('ensure_referral_code');
    return result as String?;
  }
}
