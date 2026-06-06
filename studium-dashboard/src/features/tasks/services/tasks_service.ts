import { supabase } from '../../../shared/services/supabase';

export interface Task {
  id:             string;
  application_id: string | null;
  title:          string;
  description:    string | null;
  task_type:      'manual' | 'reminder_j7' | 'reminder_j14';
  due_date:       string | null;
  assigned_to:    string | null;
  completed_at:   string | null;
  created_at:     string;
  created_by:     string | null;
  // joined
  program_name?:  string;
  student_name?:  string;
}

export async function fetchTasks(showCompleted = false): Promise<Task[]> {
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

  if (!showCompleted) query = query.isFilter('completed_at', null);

  const { data, error } = await query;
  if (error) throw error;

  return ((data ?? []) as any[]).map(t => ({
    ...t,
    program_name: t.applications?.programs?.program_name ?? null,
    student_name: t.applications?.student_profiles
      ? `${t.applications.student_profiles.first_name ?? ''} ${t.applications.student_profiles.last_name ?? ''}`.trim()
      : null,
  }));
}

export async function createTask(task: {
  title:          string;
  description?:   string;
  application_id?: string;
  due_date?:       string;
  assigned_to?:    string;
}): Promise<void> {
  const { error } = await supabase.from('tasks').insert({
    ...task,
    task_type: 'manual',
  });
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
