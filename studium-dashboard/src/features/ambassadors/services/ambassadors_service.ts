import { supabase }        from '../../../shared/services/supabase';
import { createTask }      from '../../tasks/services/tasks_service';
import type { Referral, Commission, RawCommissionStatus } from '../types/ambassador';

export async function getMyReferralCode(): Promise<string | null> {
  const { data, error } = await supabase.rpc('ensure_referral_code');
  if (error) throw error;
  return (data as string | null) ?? null;
}

export async function getMyReferrals(): Promise<Referral[]> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];

  const { data, error } = await supabase
    .from('referrals')
    .select('id, ambassador_user_id, student_user_id, status, created_at, converted_at')
    .eq('ambassador_user_id', user.id)
    .order('created_at', { ascending: false });
  if (error) throw error;

  const rows = data ?? [];
  const studentIds = rows.map(r => r.student_user_id).filter(Boolean);
  const profiles = studentIds.length
    ? await supabase.from('student_profiles').select('id, first_name, last_name').in('id', studentIds)
    : { data: [] };
  const profileById = new Map((profiles.data ?? []).map((p: any) => [p.id, p]));

  return rows.map((r: any) => {
    const profile = profileById.get(r.student_user_id) as any;
    return {
      id:               r.id,
      ambassadorUserId: r.ambassador_user_id,
      studentUserId:    r.student_user_id,
      status:           r.status,
      studentName:      profile ? `${profile.first_name ?? ''} ${profile.last_name ?? ''}`.trim() || 'Inconnu' : 'Inconnu',
      createdAt:        r.created_at,
      convertedAt:      r.converted_at ?? null,
    };
  });
}

export async function getMyCommissions(): Promise<Commission[]> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];

  const { data, error } = await supabase
    .from('commissions')
    .select('id, ambassador_user_id, amount, status, period_start, period_end, paid_at')
    .eq('ambassador_user_id', user.id)
    .order('period_start', { ascending: false });
  if (error) throw error;

  return (data ?? []).map((c: any) => ({
    id:               c.id,
    ambassadorUserId: c.ambassador_user_id,
    ambassadorName:   '',
    amount:           Number(c.amount),
    status:           c.status,
    periodStart:      c.period_start ?? null,
    periodEnd:        c.period_end ?? null,
    paidAt:           c.paid_at ?? null,
  }));
}

export async function requestPayout(commission: Commission): Promise<void> {
  await createTask({
    title:          `Demande de paiement — commission ${commission.periodStart ?? ''}`,
    description:    `L'ambassadeur a demandé le versement de sa commission de ${commission.amount} (statut actuel : payable).`,
    priority:       'normal',
    assignee_label: 'Admin',
  });
}

export async function getAllCommissions(): Promise<Commission[]> {
  const { data, error } = await supabase
    .from('commissions')
    .select('id, ambassador_user_id, amount, status, period_start, period_end, paid_at')
    .order('period_start', { ascending: false });
  if (error) throw error;

  const rows = data ?? [];
  const ambassadorIds = [...new Set(rows.map((c: any) => c.ambassador_user_id).filter(Boolean))];
  const profiles = ambassadorIds.length
    ? await supabase.from('student_profiles').select('id, first_name, last_name').in('id', ambassadorIds)
    : { data: [] };
  const profileById = new Map((profiles.data ?? []).map((p: any) => [p.id, p]));

  return rows.map((c: any) => {
    const profile = profileById.get(c.ambassador_user_id) as any;
    return {
      id:               c.id,
      ambassadorUserId: c.ambassador_user_id,
      ambassadorName:   profile ? `${profile.first_name ?? ''} ${profile.last_name ?? ''}`.trim() || 'Inconnu' : 'Inconnu',
      amount:           Number(c.amount),
      status:           c.status,
      periodStart:      c.period_start ?? null,
      periodEnd:        c.period_end ?? null,
      paidAt:           c.paid_at ?? null,
    };
  });
}

export async function updateCommissionStatus(id: string, status: RawCommissionStatus): Promise<void> {
  const { error } = await supabase
    .from('commissions')
    .update({ status, ...(status === 'paid' ? { paid_at: new Date().toISOString() } : {}) })
    .eq('id', id);
  if (error) throw error;
}
