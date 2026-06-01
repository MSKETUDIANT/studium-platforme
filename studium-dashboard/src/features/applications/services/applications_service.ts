import { supabase }    from '../../../shared/services/supabase';
import { STATUS_MAP }  from '../types/application';
import type { Application, RawStatus } from '../types/application';

const SELECT = `
  id, status, submitted_at, notes,
  student_profiles!student_profile_id ( id, first_name, last_name, nationality, completeness_score ),
  programs!program_id                  ( id, program_name, university_name, country, level )
`;

function mapRow(a: any): Application {
  return {
    id:         a.id,
    studentId:  a.student_profiles?.id ?? '',
    programId:  a.programs?.id         ?? '',
    rawStatus:  a.status               ?? 'submitted',
    status:     STATUS_MAP[a.status]   ?? 'En attente',
    student:    `${a.student_profiles?.first_name ?? ''} ${a.student_profiles?.last_name ?? ''}`.trim() || 'Inconnu',
    email:      a.student_profiles?.nationality ?? '',
    university: a.programs?.university_name          ?? '—',
    program:    a.programs?.program_name             ?? '—',
    country:    a.programs?.country                  ?? '—',
    level:      a.programs?.level                    ?? '',
    date:       a.submitted_at                       ?? '',
    score:      a.student_profiles?.completeness_score ?? 0,
    notes:      a.notes ?? undefined,
  };
}

export async function updateApplicationNotes(id: string, notes: string): Promise<void> {
  const { error } = await supabase
    .from('applications')
    .update({ notes: notes || null })
    .eq('id', id);
  if (error) throw error;
}

export async function fetchApplications(): Promise<Application[]> {
  const { data, error } = await supabase
    .from('applications')
    .select(SELECT)
    .order('submitted_at', { ascending: false });
  if (error) throw error;
  return (data ?? []).map(mapRow);
}

export async function updateApplicationStatus(id: string, status: RawStatus): Promise<void> {
  const { error } = await supabase
    .from('applications')
    .update({ status })
    .eq('id', id);
  if (error) throw error;
}

export interface StatusHistoryEntry {
  id:         string;
  fromStatus: string | null;
  toStatus:   string;
  note:       string | null;
  createdAt:  string | null;
}

export async function fetchStatusHistory(applicationId: string): Promise<StatusHistoryEntry[]> {
  const { data, error } = await supabase
    .from('application_status_history')
    .select('id, from_status, to_status, note, created_at')
    .eq('application_id', applicationId)
    .order('created_at', { ascending: true });
  if (error) throw error;
  return (data ?? []).map((e: any) => ({
    id:         e.id,
    fromStatus: e.from_status ?? null,
    toStatus:   e.to_status,
    note:       e.note ?? null,
    createdAt:  e.created_at ?? null,
  }));
}

