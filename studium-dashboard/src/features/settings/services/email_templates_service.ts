import { supabase } from '../../../shared/services/supabase';

export interface EmailTemplate {
  id:              string;
  scope:           string;
  programId:       string | null;
  language:        string;
  subjectTemplate: string;
  bodyTemplate:    string;
  updatedAt:       string | null;
}

export const TEMPLATE_VARIABLES = [
  { key: '{{student_name}}',    label: 'Nom étudiant' },
  { key: '{{program_name}}',    label: 'Programme' },
  { key: '{{university_name}}', label: 'Université' },
  { key: '{{country}}',         label: 'Pays' },
  { key: '{{submitted_at}}',    label: 'Date soumission' },
];

export const SCOPE_LABELS: Record<string, string> = {
  global:     'Email candidature (tous les programmes)',
  program:    'Email candidature (programme spécifique)',
  followup:   'Email relance (J+7 / J+14)',
  correction: 'Email correction (étudiant)',
};

function mapRow(e: any): EmailTemplate {
  return {
    id:              e.id,
    scope:           e.scope,
    programId:       e.program_id   ?? null,
    language:        e.language     ?? 'fr',
    subjectTemplate: e.subject_template,
    bodyTemplate:    e.body_template,
    updatedAt:       e.updated_at   ?? null,
  };
}

export async function fetchEmailTemplates(): Promise<EmailTemplate[]> {
  const { data, error } = await supabase
    .from('email_templates')
    .select('id, scope, program_id, language, subject_template, body_template, updated_at')
    .order('scope')
    .order('language');
  if (error) throw error;
  return (data ?? []).map(mapRow);
}

export async function upsertEmailTemplate(
  template: Omit<EmailTemplate, 'id' | 'updatedAt'> & { id?: string },
): Promise<void> {
  const now = new Date().toISOString();

  if (template.id) {
    const { error } = await supabase
      .from('email_templates')
      .update({
        scope:            template.scope,
        program_id:       template.programId ?? null,
        language:         template.language,
        subject_template: template.subjectTemplate,
        body_template:    template.bodyTemplate,
        updated_at:       now,
      })
      .eq('id', template.id);
    if (error) throw error;
  } else {
    const { error } = await supabase
      .from('email_templates')
      .insert({
        scope:            template.scope,
        program_id:       template.programId ?? null,
        language:         template.language,
        subject_template: template.subjectTemplate,
        body_template:    template.bodyTemplate,
        created_at:       now,
        updated_at:       now,
      });
    if (error) throw error;
  }
}

export async function deleteEmailTemplate(id: string): Promise<void> {
  const { error } = await supabase.from('email_templates').delete().eq('id', id);
  if (error) throw error;
}
