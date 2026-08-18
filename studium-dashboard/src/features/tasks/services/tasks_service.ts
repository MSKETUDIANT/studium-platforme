import { supabase } from '../../../shared/services/supabase';

export interface Task {
  id:             string;
  application_id: string | null;
  title:          string;
  description:    string | null;
  task_type:      'manual' | 'reminder_j7' | 'reminder_j14';
  due_date:       string | null;
  assigned_to:    string | null;
  assignee_label: string | null;
  priority:       'normal' | 'urgent' | 'faible' | null;
  reminder_hours: number | null;
  completed_at:   string | null;
  created_at:     string;
  created_by:     string | null;
  // Rôle du créateur — propriétaire de la tâche (peut modifier/supprimer)
  creator_role:   'admin' | 'manager' | 'admissions' | 'support' | null;
  // joined
  program_name?:  string;
  student_name?:  string;
}

export async function fetchTasks(showCompleted = false): Promise<Task[]> {
  // Requête complète avec jointures pour afficher étudiant + programme
  let query = supabase
    .from('tasks')
    .select(`
      *,
      applications!application_id(
        student_profiles!student_profile_id(first_name, last_name),
        programs!program_id(program_name)
      )
    `)
    .order('due_date', { ascending: true, nullsFirst: false })
    .order('created_at', { ascending: false });

  if (!showCompleted) query = query.is('completed_at', null);

  const { data, error } = await query;

  if (!error && data) {
    return (data as any[]).map(t => ({
      ...t,
      program_name: t.applications?.programs?.program_name ?? null,
      student_name: t.applications?.student_profiles
        ? `${t.applications.student_profiles.first_name ?? ''} ${t.applications.student_profiles.last_name ?? ''}`.trim()
        : null,
    }));
  }

  // Fallback sans jointure si les FK ne sont pas encore dans le cache PostgREST
  let fallback = supabase
    .from('tasks')
    .select('*')
    .order('due_date', { ascending: true, nullsFirst: false })
    .order('created_at', { ascending: false });

  if (!showCompleted) fallback = fallback.is('completed_at', null);

  const { data: data2, error: error2 } = await fallback;
  if (error2) throw error2;

  return ((data2 ?? []) as any[]).map(t => ({
    ...t,
    program_name: null,
    student_name: null,
  }));
}

export async function createTask(task: {
  title:           string;
  description?:    string;
  application_id?: string;
  due_date?:       string;
  assigned_to?:    string;
  priority?:       'normal' | 'urgent' | 'faible';
  assignee_label?: string;
  reminder_hours?: number;
  creator_role?:   'admin' | 'manager' | 'admissions' | 'support';
}): Promise<void> {
  const { error } = await supabase.from('tasks').insert({
    ...task,
    task_type: 'manual',
  });
  if (error) throw error;
}

export async function updateTask(id: string, fields: {
  title?:          string;
  description?:    string | null;
  application_id?: string | null;
  due_date?:       string | null;
  assignee_label?: string;
  priority?:       'normal' | 'urgent' | 'faible';
  reminder_hours?: number | null;
}): Promise<void> {
  const { error } = await supabase.from('tasks').update(fields).eq('id', id);
  if (error) throw error;
}

export async function completeTask(id: string): Promise<void> {
  const { error } = await supabase
    .from('tasks')
    .update({ completed_at: new Date().toISOString() })
    .eq('id', id);
  if (error) throw error;
}

export async function deleteTask(id: string): Promise<void> {
  const { error } = await supabase.from('tasks').delete().eq('id', id);
  if (error) throw error;
}

// Les tâches de relance J+7/J+14 sont créées par le trigger SQL
// create_reminder_tasks_on_sent (couvre à la fois le passage manuel à
// "Envoyée" et l'envoi email automatique, cf. migration
// 20260720_reminder_tasks_trigger.sql).

export async function searchApplications(query: string): Promise<{ id: string; label: string }[]> {
  const { data: profiles } = await supabase
    .from('student_profiles')
    .select('id, first_name, last_name')
    .or(`first_name.ilike.%${query}%,last_name.ilike.%${query}%`)
    .limit(8);

  if (!profiles?.length) return [];

  const { data: apps } = await supabase
    .from('applications')
    .select('id, student_profile_id, programs!program_id(program_name)')
    .in('student_profile_id', profiles.map(p => p.id))
    .limit(15);

  return (apps ?? []).map((a: any) => {
    const profile = profiles.find(p => p.id === a.student_profile_id);
    const name = profile
      ? `${profile.first_name ?? ''} ${profile.last_name ?? ''}`.trim()
      : 'Inconnu';
    const prog = a.programs?.program_name ?? 'Programme inconnu';
    return { id: a.id, label: `${name} — ${prog}` };
  });
}
