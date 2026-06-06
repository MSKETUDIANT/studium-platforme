import { supabase } from '../../../shared/services/supabase';

export interface AuditLog {
  id:          string;
  actor_id:    string | null;
  actor_email: string | null;
  action:      string;
  entity_type: string;
  entity_id:   string | null;
  old_value:   string | null;
  new_value:   string | null;
  metadata:    Record<string, unknown>;
  created_at:  string;
}

const ACTION_LABELS: Record<string, string> = {
  status_update:    'Changement de statut',
  document_approve: 'Document approuvé',
  document_reject:  'Document rejeté',
  email_sent:       'Email envoyé',
  program_create:   'Programme créé',
  program_update:   'Programme modifié',
  program_delete:   'Programme supprimé',
};

const ENTITY_LABELS: Record<string, string> = {
  application: 'Candidature',
  document:    'Document',
  program:     'Programme',
};

export const actionLabel  = (a: string) => ACTION_LABELS[a]  ?? a;
export const entityLabel  = (e: string) => ENTITY_LABELS[e]  ?? e;

export async function fetchAuditLogs(params: {
  limit?:      number;
  offset?:     number;
  entityType?: string;
  action?:     string;
  from?:       string;
  to?:         string;
}): Promise<{ data: AuditLog[]; count: number }> {
  const { limit = 50, offset = 0, entityType, action, from, to } = params;

  let query = supabase
    .from('audit_logs')
    .select('*', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (entityType) query = query.eq('entity_type', entityType);
  if (action)     query = query.eq('action', action);
  if (from)       query = query.gte('created_at', from);
  if (to)         query = query.lte('created_at', to);

  const { data, error, count } = await query;
  if (error) throw error;
  return { data: (data ?? []) as AuditLog[], count: count ?? 0 };
}
