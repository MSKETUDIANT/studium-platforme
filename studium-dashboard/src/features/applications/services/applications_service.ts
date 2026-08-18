import { supabase }              from '../../../shared/services/supabase';
import { STATUS_MAP }            from '../types/application';
import type { Application, RawStatus } from '../types/application';

const SELECT = `
  id, status, submitted_at, notes, motivation_letter,
  student_profiles!student_profile_id ( id, first_name, last_name, nationality, completeness_score ),
  programs!program_id                  ( id, program_name, university_name, country, level, deadline, requirements, contact_email, cc_emails, program_contacts!left ( email, cc_emails ) )
`;

function mapRow(a: any): Application {
  const contacts = Array.isArray(a.programs?.program_contacts) ? a.programs.program_contacts : [];
  return {
    id:           a.id,
    studentId:    a.student_profiles?.id ?? '',
    programId:    a.programs?.id         ?? '',
    rawStatus:    a.status               ?? 'submitted',
    status:       STATUS_MAP[a.status]   ?? 'En attente',
    student:      `${a.student_profiles?.first_name ?? ''} ${a.student_profiles?.last_name ?? ''}`.trim() || 'Inconnu',
    email:        '',
    university:   a.programs?.university_name    ?? '',
    program:      a.programs?.program_name       ?? '',
    country:      a.programs?.country            ?? '',
    level:        a.programs?.level              ?? '',
    date:         a.submitted_at                 ?? '',
    score:        a.student_profiles?.completeness_score ?? 0,
    notes:               a.notes                        ?? undefined,
    motivationLetter:    a.motivation_letter             ?? undefined,
    // program_contacts (email/name/cc dédiés) prime si renseigné ; sinon
    // repli sur le champ simple programs.contact_email, seul réellement
    // alimenté aujourd'hui via le formulaire de gestion des programmes.
    contactEmail:        contacts[0]?.email ?? a.programs?.contact_email ?? undefined,
    ccEmails:            Array.isArray(contacts[0]?.cc_emails) && contacts[0].cc_emails.length
                            ? contacts[0].cc_emails.join(', ')
                            : a.programs?.cc_emails ?? undefined,
    deadline:            a.programs?.deadline           ?? null,
    programRequirements: Array.isArray(a.programs?.requirements) ? a.programs.requirements : [],
  };
}

export async function updateApplicationNotes(id: string, notes: string): Promise<void> {
  const { error } = await supabase
    .from('applications')
    .update({ notes: notes || null })
    .eq('id', id);
  if (error) throw error;
}

/*  Commentaires internes (fil horodaté/multi-auteurs, distinct de notes) */

export interface ApplicationComment {
  id:           string;
  content:      string;
  author_email: string | null;
  created_at:   string;
}

export async function fetchApplicationComments(applicationId: string): Promise<ApplicationComment[]> {
  const { data, error } = await supabase
    .from('application_comments')
    .select('id, content, author_email, created_at')
    .eq('application_id', applicationId)
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data ?? [];
}

export async function addApplicationComment(applicationId: string, content: string): Promise<ApplicationComment> {
  const { data: { user } } = await supabase.auth.getUser();
  const { data, error } = await supabase
    .from('application_comments')
    .insert({ application_id: applicationId, content, author_id: user?.id, author_email: user?.email })
    .select('id, content, author_email, created_at')
    .single();
  if (error) throw error;
  return data;
}

export async function deleteApplicationComment(id: string): Promise<void> {
  const { error } = await supabase.from('application_comments').delete().eq('id', id);
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

const STATUS_PUSH_MESSAGES: Partial<Record<RawStatus, { title: string; body: string }>> = {
  needsfix:         { title: 'Correction demandée',    body: 'Votre dossier nécessite des corrections. Consultez le message de l\'équipe.' },
  verified:         { title: 'Dossier validé',         body: 'Votre candidature a été validée et sera bientôt envoyée.' },
  sent:             { title: 'Candidature envoyée',    body: 'Votre dossier a été soumis à l\'université.' },
  accepted:         { title: 'Candidature acceptée',   body: 'Votre candidature a été acceptée !' },
  rejected:         { title: 'Résultat candidature',   body: 'Votre candidature n\'a pas été retenue. Consultez l\'app pour plus d\'infos.' },
  pending_decision: { title: 'En attente de décision', body: 'L\'université examine votre dossier.' },
};

async function sendStatusPush(applicationId: string, status: RawStatus): Promise<void> {
  const msg = STATUS_PUSH_MESSAGES[status];
  if (!msg) return;

  const { data: app } = await supabase
    .from('applications')
    .select('student_profile_id')
    .eq('id', applicationId)
    .single();
  if (!app?.student_profile_id) return;

  await supabase.functions.invoke('send-push-notification', {
    body: {
      user_ids: [app.student_profile_id],
      title: msg.title,
      body:  msg.body,
      data:  { type: 'status_change', application_id: applicationId, status },
    },
  });
}

export async function updateApplicationStatus(
  id: string,
  status: RawStatus,
  note?: string,
): Promise<void> {
  const { error } = await supabase
    .from('applications')
    .update({ status })
    .eq('id', id);
  if (error) throw error;

  // Push notification asynchrone (ne bloque pas)
  sendStatusPush(id, status).catch(console.error);

  // Les tâches de relance J+7/J+14 sont créées par un trigger SQL
  // (create_reminder_tasks_on_sent), qui couvre aussi l'envoi email
  // automatique — celui-ci ne passe jamais par cette fonction.

  if (note) {
    const { data: latest } = await supabase
      .from('application_status_history')
      .select('id')
      .eq('application_id', id)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();
    if (latest) {
      await supabase
        .from('application_status_history')
        .update({ note })
        .eq('id', latest.id);
    }
  }
}

export interface EmailLog {
  id:                string;
  toEmail:           string;
  ccEmails:          string[] | null;
  subject:           string | null;
  provider:          string | null;
  status:            'sent' | 'failed' | 'bounced';
  providerMessageId: string | null;
  errorMessage:      string | null;
  isFollowup:        boolean;
  sentAt:            string;
  retryCount:        number;
}

export async function fetchEmailLogs(applicationId: string): Promise<EmailLog[]> {
  const { data, error } = await supabase
    .from('email_logs')
    .select('id, to_email, cc_emails, subject, provider, status, provider_message_id, error_message, is_followup, sent_at, retry_count')
    .eq('application_id', applicationId)
    .order('sent_at', { ascending: false });
  if (error) return [];
  return (data ?? []).map((e: any) => ({
    id:                e.id,
    toEmail:           e.to_email,
    ccEmails:          e.cc_emails ?? null,
    subject:           e.subject   ?? null,
    provider:          e.provider  ?? null,
    status:            e.status,
    providerMessageId: e.provider_message_id ?? null,
    errorMessage:      e.error_message       ?? null,
    isFollowup:        e.is_followup         ?? false,
    sentAt:            e.sent_at,
    retryCount:        e.retry_count ?? 0,
  }));
}

// Trace un passage manuel à "Envoyée" (dépôt sur portail externe, cf. CDC
// section 1) dans le même historique que les envois email automatiques,
// pour que l'équipe distingue les deux cas au lieu de les confondre.
export async function logManualSend(
  applicationId: string,
  destination:   string,
  note:          string,
): Promise<void> {
  const { data: { session } } = await supabase.auth.getSession();
  const { error } = await supabase.from('email_logs').insert({
    application_id: applicationId,
    to_email:        destination || 'Dépôt manuel (portail externe)',
    subject:         note,
    provider:        'manual',
    status:          'sent',
    sent_by:         session?.user?.id ?? null,
    sent_at:         new Date().toISOString(),
    is_followup:     false,
  });
  if (error) throw error;
}

export async function sendApplicationEmail(
  applicationId: string,
  toEmail:        string,
  ccEmails:       string[] = [],
): Promise<void> {
  const { data: { session } } = await supabase.auth.getSession();
  const res = await supabase.functions.invoke('send-application-email', {
    body: {
      application_id: applicationId,
      to_email:       toEmail,
      cc_emails:      ccEmails,
      sent_by:        session?.user?.id ?? null,
    },
  });
  if (res.error) throw new Error(res.error.message);
  const body = res.data as { error?: string } | null;
  if (body?.error) throw new Error(body.error);
}

export interface StatusHistoryEntry {
  id:         string;
  fromStatus: string | null;
  toStatus:   string;
  note:       string | null;
  createdAt:  string | null;
}

export async function sendCorrectionMessage(
  studentProfileId: string,
  message: string,
): Promise<void> {
  // Trouver ou créer la conversation de l'étudiant
  const { data: existing } = await supabase
    .from('conversations')
    .select('id')
    .eq('student_profile_id', studentProfileId)
    .maybeSingle();

  let convId: string;
  if (existing) {
    convId = existing.id;
  } else {
    const { data: created, error } = await supabase
      .from('conversations')
      .insert({ student_profile_id: studentProfileId })
      .select('id')
      .single();
    if (error || !created) throw error;
    convId = created.id;
  }

  // Envoyer le message comme staff
  const { data: { session } } = await supabase.auth.getSession();
  const { error } = await supabase
    .from('messages')
    .insert({
      conversation_id: convId,
      sender_type:     'staff',
      sender_id:       session?.user?.id ?? null,
      content:         message,
    });
  if (error) throw error;
}

export interface ApplicationDocument {
  id:               string;
  type:             string;
  file_url:         string | null;
  file_name:        string | null;
  size_bytes:       number | null;
  status:           'pending' | 'approved' | 'rejected';
  rejection_reason: string | null;
  created_at:       string;
}

const DOC_TYPE_LABELS: Record<string, string> = {
  cv:                'Curriculum Vitae',
  transcript:        'Relevé de notes',
  recommendation:    'Lettre de recommandation',
  passport:          'Passeport / Pièce d\'identité',
  motivation_letter: 'Lettre de motivation',
  diploma:           'Diplôme',
  language_cert:     'Attestation de langue',
  financial_proof:   'Justificatif de financement',
  other:             'Document complémentaire',
};

export function docTypeLabel(type: string): string {
  return DOC_TYPE_LABELS[type] ?? type;
}

export async function fetchApplicationDocuments(studentProfileId: string): Promise<ApplicationDocument[]> {
  const { data } = await supabase
    .from('documents')
    .select('id, type, file_url, file_name, size_bytes, status, rejection_reason, created_at')
    .eq('student_profile_id', studentProfileId)
    .order('created_at', { ascending: false });
  return (data ?? []) as ApplicationDocument[];
}

export async function approveDocument(id: string, fileName?: string): Promise<void> {
  const { error } = await supabase
    .from('documents')
    .update({
      status:           'approved',
      rejection_reason: null,
      ...(fileName ? { file_name: fileName } : {}),
    })
    .eq('id', id);
  if (error) throw error;
}

export async function rejectDocument(id: string, reason: string): Promise<void> {
  const { error } = await supabase
    .from('documents')
    .update({ status: 'rejected', rejection_reason: reason })
    .eq('id', id);
  if (error) throw error;
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

