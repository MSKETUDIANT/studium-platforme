// @ts-nocheck — Deno Edge Function (erreurs IDE normales, pas de compilation Node)
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const RESEND_API_KEY  = Deno.env.get('RESEND_API_KEY')!;
const SUPABASE_URL    = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_KEY    = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const FROM_EMAIL      = 'onboarding@resend.dev'; // TODO: remplacer par noreply@studium.app après vérification domaine
const FROM_NAME       = 'Studium Admissions';

interface Payload {
  application_id: string;
  to_email:       string;
  cc_emails?:     string[];
  sent_by?:       string;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders() });
  }

  try {
    const payload: Payload = await req.json();
    const { application_id, to_email, cc_emails = [], sent_by } = payload;

    if (!application_id || !to_email) {
      return jsonError('application_id and to_email are required', 400);
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

    // Fetch application details
    const { data: app, error: appErr } = await supabase
      .from('applications')
      .select(`
        id, status, submitted_at, notes,
        student_profiles!student_profile_id (
          first_name, last_name, nationality, completeness_score
        ),
        programs!program_id (
          program_name, university_name, country, level
        )
      `)
      .eq('id', application_id)
      .single();

    if (appErr || !app) return jsonError('Application not found', 404);

    const studentName = `${app.student_profiles?.first_name ?? ''} ${app.student_profiles?.last_name ?? ''}`.trim();
    const programName = app.programs?.program_name  ?? '—';
    const univName    = app.programs?.university_name ?? '—';
    const country     = app.programs?.country         ?? '';
    const submittedAt = app.submitted_at
      ? new Date(app.submitted_at).toLocaleDateString('fr-FR') : '—';

    // Fetch template from DB (program-specific first, then global, then fallback)
    // Try program-specific template first, then global fallback
    const { data: programTpl } = await supabase
      .from('email_templates')
      .select('subject_template, body_template')
      .eq('scope', 'program')
      .eq('language', 'fr')
      .eq('program_id', app.program_id)
      .limit(1);

    const { data: globalTpl } = programTpl?.length ? { data: null } : await supabase
      .from('email_templates')
      .select('subject_template, body_template')
      .eq('scope', 'global')
      .eq('language', 'fr')
      .limit(1);

    const templates = programTpl?.length ? programTpl : (globalTpl ?? []);

    const tpl     = templates?.[0];
    const vars    = { studentName, programName, univName, country, submittedAt };
    const subject = tpl ? replaceVars(tpl.subject_template, vars) : `[Studium] Candidature – ${studentName} – ${programName}`;
    const bodyTxt = tpl ? replaceVars(tpl.body_template,    vars) : buildEmailText({ studentName, programName, univName, country, submittedAt });
    const html    = buildEmailHtml({ studentName, programName, univName, country, submittedAt, notes: app.notes, customBody: tpl ? bodyTxt : null });

    // Send via Resend
    const resendRes = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type':  'application/json',
      },
      body: JSON.stringify({
        from:    `${FROM_NAME} <${FROM_EMAIL}>`,
        to:      [to_email],
        cc:      cc_emails.length ? cc_emails : undefined,
        subject,
        html,
        text: bodyTxt,
      }),
    });

    const resendData = await resendRes.json();
    const success    = resendRes.ok;
    const msgId      = resendData?.id ?? null;
    const errMsg     = success ? null : JSON.stringify(resendData);

    // Log the attempt
    await supabase.from('email_logs').insert({
      application_id,
      to_email,
      cc_emails:           cc_emails.length ? cc_emails : null,
      subject,
      provider:            'resend',
      status:              success ? 'sent' : 'failed',
      provider_message_id: msgId,
      error_message:       errMsg,
      sent_by:             sent_by ?? null,
      is_followup:         false,
    });

    // Update application status to 'sent' if successful
    if (success) {
      await supabase
        .from('applications')
        .update({ status: 'sent' })
        .eq('id', application_id);
    }

    if (!success) return jsonError(`Resend error: ${errMsg}`, 502);

    return new Response(JSON.stringify({ success: true, message_id: msgId }), {
      headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
    });

  } catch (err) {
    return jsonError(String(err), 500);
  }
});

/* ─── Email templates ──────────────────────────────────────────────────────── */

interface TemplateData {
  studentName:  string;
  programName:  string;
  univName:     string;
  country:      string;
  submittedAt:  string;
  notes?:       string | null;
  customBody?:  string | null;
}

function replaceVars(tpl: string, vars: Record<string, string>): string {
  return tpl
    .replace(/\{\{student_name\}\}/g,    vars.studentName ?? '')
    .replace(/\{\{program_name\}\}/g,    vars.programName ?? '')
    .replace(/\{\{university_name\}\}/g, vars.univName    ?? '')
    .replace(/\{\{country\}\}/g,         vars.country ? ` (${vars.country})` : '')
    .replace(/\{\{submitted_at\}\}/g,    vars.submittedAt ?? '');
}

function buildEmailHtml(d: TemplateData): string {
  const bodyContent = d.customBody
    ? d.customBody.split('\n').map(line => `<p style="font-size:14px;color:#374151;line-height:1.6;margin:0 0 12px;">${line || '&nbsp;'}</p>`).join('')
    : `<p style="font-size:15px;color:#374151;margin:0 0 20px;">Madame, Monsieur,</p>
          <p style="font-size:15px;color:#374151;line-height:1.6;margin:0 0 24px;">
            Nous vous transmettons la candidature de <strong>${d.studentName}</strong>
            pour le programme <strong>${d.programName}</strong>
            à <strong>${d.univName}</strong>${d.country ? ` (${d.country})` : ''}.
          </p>
          <table width="100%" cellpadding="0" cellspacing="0" style="background:#f8fafc;border-radius:8px;border:1px solid #e2e8f0;margin-bottom:24px;">
            <tr><td style="padding:20px 24px;">
              <table width="100%" cellpadding="4" cellspacing="0">
                <tr><td style="font-size:12px;color:#6b7280;width:40%;">Candidat</td><td style="font-size:14px;font-weight:bold;color:#111827;">${d.studentName}</td></tr>
                <tr><td style="font-size:12px;color:#6b7280;">Programme</td><td style="font-size:14px;font-weight:bold;color:#111827;">${d.programName}</td></tr>
                <tr><td style="font-size:12px;color:#6b7280;">Université</td><td style="font-size:14px;color:#111827;">${d.univName}</td></tr>
                <tr><td style="font-size:12px;color:#6b7280;">Date soumission</td><td style="font-size:14px;color:#111827;">${d.submittedAt}</td></tr>
              </table>
            </td></tr>
          </table>
          <p style="font-size:14px;color:#374151;line-height:1.6;margin:0 0 20px;">Vous trouverez en pièce jointe le dossier complet du candidat.</p>
          <p style="font-size:14px;color:#374151;font-weight:bold;margin:0;">L'équipe Studium Admissions</p>`;

  return `<!DOCTYPE html>
<html lang="fr">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f4f7fb;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f7fb;padding:40px 0;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,.08);">
        <tr><td style="background:linear-gradient(135deg,#1e3a8a 0%,#1e40af 100%);padding:32px 40px;">
          <h1 style="margin:0;color:#fff;font-size:24px;letter-spacing:2px;">STUDIUM</h1>
          <p style="margin:6px 0 0;color:rgba(255,255,255,.75);font-size:13px;">Plateforme de gestion des candidatures académiques</p>
        </td></tr>
        <tr><td style="padding:36px 40px;">${bodyContent}</td></tr>
        <tr><td style="background:#f8fafc;padding:20px 40px;border-top:1px solid #e2e8f0;">
          <p style="margin:0;font-size:11px;color:#9ca3af;text-align:center;">
            Cet email a été envoyé automatiquement par la plateforme Studium.<br>
            Pour toute question : support@studium.app
          </p>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;
}

function buildEmailText(d: TemplateData): string {
  return `STUDIUM — Candidature académique

Madame, Monsieur,

Nous vous transmettons la candidature de ${d.studentName} pour le programme ${d.programName} à ${d.univName}${d.country ? ` (${d.country})` : ''}.

DÉTAILS :
- Candidat       : ${d.studentName}
- Programme      : ${d.programName}
- Université     : ${d.univName}
- Date soumission: ${d.submittedAt}

Vous trouverez en pièce jointe le dossier complet du candidat.

Cordialement,
L'équipe Studium Admissions
support@studium.app`;
}

/* ─── Helpers ──────────────────────────────────────────────────────────────── */

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin':  '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };
}

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
  });
}
