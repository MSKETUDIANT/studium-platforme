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
    final userId = _client.auth.currentUser?.id;
    final payout = userId == null ? null : await fetchPayoutInfo(userId);
    final payoutLine = switch (payout?['payout_method']) {
      'iban'   => 'IBAN : ${payout?['payout_iban'] ?? '(non renseigne)'}',
      'paypal' => 'PayPal : ${payout?['payout_paypal_email'] ?? '(non renseigne)'}',
      _        => 'Coordonnees de paiement non renseignees par l\'ambassadeur.',
    };
    await _client.from('tasks').insert({
      'title': 'Demande de paiement — commission',
      'description':
          "L'ambassadeur a demandé le versement de sa commission de $amount (statut actuel : payable).\n$payoutLine",
      'task_type': 'manual',
      'priority': 'normal',
      'assignee_label': 'Admin',
    });
  }

  Future<Map<String, dynamic>?> fetchPayoutInfo(String userId) async {
    final data = await _client
        .from('student_profiles')
        .select('payout_method, payout_iban, payout_paypal_email')
        .eq('id', userId)
        .maybeSingle();
    return data;
  }

  Future<void> savePayoutInfo({
    required String userId,
    required String method,
    String? iban,
    String? paypalEmail,
  }) async {
    await _client.from('student_profiles').update({
      'payout_method':        method,
      'payout_iban':          method == 'iban' ? iban : null,
      'payout_paypal_email':  method == 'paypal' ? paypalEmail : null,
    }).eq('id', userId);
  }

  Future<String?> ensureReferralCode() async {
    final result = await _client.rpc('ensure_referral_code');
    return result as String?;
  }
}
