import { supabase } from '../../../shared/services/supabase';

export interface KPISummary {
  totalApplications:      number;
  pendingReview:          number;
  verified:               number;
  sent:                   number;
  accepted:               number;
  rejected:               number;
  avgCompletenessScore:   number;
  needsFix:               number;
  acceptanceRate:         number; // % parmi les candidatures décidées (acceptées + refusées)
  avgValidationDelayDays: number; // jours entre soumission et 1ère validation ('verified')
}

export interface MonthlyCount {
  month: string;
  count: number;
}

export interface TopItem {
  label: string;
  count: number;
}

const EMPTY_KPI: KPISummary = {
  totalApplications: 0, pendingReview: 0, verified: 0,
  sent: 0, accepted: 0, rejected: 0, avgCompletenessScore: 0, needsFix: 0,
  acceptanceRate: 0, avgValidationDelayDays: 0,
};

// Délai moyen entre soumission (applications.submitted_at) et 1ère validation
// (première transition vers 'verified' dans application_status_history).
async function fetchAvgValidationDelayDays(): Promise<number> {
  const [{ data: apps }, { data: history }] = await Promise.all([
    supabase.from('applications').select('id, submitted_at').not('submitted_at', 'is', null),
    supabase.from('application_status_history').select('application_id, created_at').eq('to_status', 'verified'),
  ]);
  if (!apps?.length || !history?.length) return 0;

  // Garde la 1ère transition 'verified' par candidature
  const verifiedAtByApp = new Map<string, string>();
  history.forEach((h: any) => {
    const existing = verifiedAtByApp.get(h.application_id);
    if (!existing || h.created_at < existing) verifiedAtByApp.set(h.application_id, h.created_at);
  });

  const delaysDays: number[] = [];
  apps.forEach((a: any) => {
    const verifiedAt = verifiedAtByApp.get(a.id);
    if (!verifiedAt) return;
    const diffMs = new Date(verifiedAt).getTime() - new Date(a.submitted_at).getTime();
    if (diffMs >= 0) delaysDays.push(diffMs / 86_400_000);
  });
  if (!delaysDays.length) return 0;

  return Math.round((delaysDays.reduce((s, v) => s + v, 0) / delaysDays.length) * 10) / 10;
}

export async function fetchKPISummary(): Promise<KPISummary> {
  const { data, error } = await supabase
    .from('applications')
    .select('status, student_profiles!student_profile_id(id, completeness_score)');

  if (error || !data) return EMPTY_KPI;

  const total    = data.length;
  const byStatus = (s: string) => data.filter((a: any) => a.status === s).length;

  // Score moyen : dédupliquer par étudiant pour éviter de compter N fois un étudiant avec N candidatures
  const seenIds = new Set<string>();
  const uniqueScores: number[] = [];
  data.forEach((a: any) => {
    const sid = a.student_profiles?.id as string | undefined;
    if (sid && !seenIds.has(sid)) {
      seenIds.add(sid);
      uniqueScores.push(a.student_profiles?.completeness_score ?? 0);
    }
  });
  const avg = uniqueScores.length
    ? Math.round(uniqueScores.reduce((s, v) => s + v, 0) / uniqueScores.length)
    : 0;

  const accepted = byStatus('accepted');
  const rejected = data.filter((a: any) => ['rejected', 'archived'].includes(a.status)).length;
  const decided  = accepted + rejected;

  const avgValidationDelayDays = await fetchAvgValidationDelayDays();

  return {
    totalApplications:    total,
    pendingReview:        data.filter((a: any) => ['draft', 'submitted', 'pending_decision'].includes(a.status)).length,
    needsFix:             byStatus('needsfix'),
    verified:             byStatus('verified'),
    sent:                 byStatus('sent'),
    accepted,
    rejected,
    avgCompletenessScore: avg,
    acceptanceRate:         decided > 0 ? Math.round((accepted / decided) * 100) : 0,
    avgValidationDelayDays,
  };
}

export async function fetchMonthlyApplications(): Promise<MonthlyCount[]> {
  const { data, error } = await supabase
    .from('applications')
    .select('submitted_at')
    .not('submitted_at', 'is', null)
    .order('submitted_at', { ascending: true });

  if (error || !data) return [];

  const map: Record<string, number> = {};
  data.forEach((a: any) => {
    if (!a.submitted_at) return;
    const d     = new Date(a.submitted_at);
    const key   = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
    map[key]    = (map[key] ?? 0) + 1;
  });

  return Object.entries(map)
    .sort(([a], [b]) => a.localeCompare(b))
    .slice(-6)
    .map(([month, count]) => ({
      month: new Date(month + '-01').toLocaleDateString('fr-FR', { month: 'short', year: '2-digit' }),
      count,
    }));
}

export async function fetchTopCountries(limit = 5): Promise<TopItem[]> {
  const { data, error } = await supabase
    .from('applications')
    .select('programs!program_id(country)');

  if (error || !data) return [];

  const map: Record<string, number> = {};
  data.forEach((a: any) => {
    const c = a.programs?.country;
    if (c) map[c] = (map[c] ?? 0) + 1;
  });

  return Object.entries(map)
    .sort(([, a], [, b]) => b - a)
    .slice(0, limit)
    .map(([label, count]) => ({ label, count }));
}

export async function fetchTopPrograms(limit = 5): Promise<TopItem[]> {
  const { data, error } = await supabase
    .from('applications')
    .select('programs!program_id(program_name, university_name)');

  if (error || !data) return [];

  const map: Record<string, number> = {};
  data.forEach((a: any) => {
    const p = a.programs;
    if (!p) return;
    const key = `${p.program_name}  ${p.university_name}`;
    map[key] = (map[key] ?? 0) + 1;
  });

  return Object.entries(map)
    .sort(([, a], [, b]) => b - a)
    .slice(0, limit)
    .map(([label, count]) => ({ label, count }));
}

export function exportCSV(rows: Record<string, any>[], filename: string) {
  if (!rows.length) return;
  const headers = Object.keys(rows[0]);
  const csv     = [
    headers.join(','),
    ...rows.map(r => headers.map(h => `"${String(r[h] ?? '').replace(/"/g, '""')}"`).join(',')),
  ].join('\n');

  const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
  const url  = URL.createObjectURL(blob);
  const a    = document.createElement('a');
  a.href = url; a.download = filename; a.click();
  URL.revokeObjectURL(url);
}
