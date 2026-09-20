// @ts-nocheck  Deno Edge Function (erreurs IDE normales, pas de compilation Node)
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import {
  replaceVars, replaceVarsHtml, buildEmailHtml, buildEmailText, bytesToBase64, extractBucketAndPath,
} from './email_templates.ts';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!;
const SUPABASE_URL   = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_KEY   = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const FROM_EMAIL     = 'onboarding@resend.dev'; // TODO: remplacer par noreply@studium.app après vérification domaine
const FROM_NAME      = 'Studium Admissions';
const MAX_ATTACH_MB  = 20; // Limite pièces jointes (Mo)

const TYPE_LABELS: Record<string, string> = {
  cv:                'Curriculum Vitae',
  transcript:        'Relevé de notes et diplômes',
  recommendation:    'Lettre de recommandation',
  passport:          'Passeport / Pièce d\'identité',
  motivation_letter: 'Lettre de motivation',
  diploma:           'Diplôme',
  language_cert:     'Attestation de langue',
  financial_proof:   'Justificatif de financement',
  other:             'Document complémentaire',
};

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

    //  0. Anti-spam (CDC §7) : cooldown par candidature + limite par destinataire
    const fiveMinAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000).toISOString();

    const { count: recentSameApp } = await supabase
      .from('email_logs')
      .select('id', { count: 'exact', head: true })
      .eq('application_id', application_id)
      .gte('sent_at', fiveMinAgo);

    if ((recentSameApp ?? 0) > 0) {
      return jsonError(
        'Un envoi pour cette candidature a déjà été effectué il y a moins de 5 minutes. Merci de patienter avant de réessayer.',
        429,
      );
    }

    const { count: recentToRecipient } = await supabase
      .from('email_logs')
      .select('id', { count: 'exact', head: true })
      .eq('to_email', to_email)
      .gte('sent_at', oneHourAgo);

    if ((recentToRecipient ?? 0) >= 5) {
      return jsonError(
        `Trop d'envois vers ${to_email} au cours de la dernière heure (limite : 5). Réessayez plus tard.`,
        429,
      );
    }

    //  1. Détails de la candidature
    const { data: app, error: appErr } = await supabase
      .from('applications')
      .select(`
        id, status, submitted_at, notes, student_profile_id,
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

    const studentName  = `${app.student_profiles?.first_name ?? ''} ${app.student_profiles?.last_name ?? ''}`.trim();
    const programName  = app.programs?.program_name   ?? '';
    const univName     = app.programs?.university_name ?? '';
    const country      = app.programs?.country          ?? '';
    const submittedAt  = app.submitted_at
      ? new Date(app.submitted_at).toLocaleDateString('fr-FR') : '';

    //  2. Pack PDF assemblé (résumé + documents fusionnés) — génère au premier
    //     envoi, réutilise ensuite (voir generate-application-pack)
    const { data: packData, error: packErr } = await supabase.functions.invoke(
      'generate-application-pack',
      { body: { application_id, sent_by } },
    );

    if (packErr || !packData?.pack_url) {
      return jsonError(`Pack generation failed: ${packErr?.message ?? 'no pack_url returned'}`, 500);
    }

    const packUrl  = packData.pack_url as string;
    const packPath = (packData.pack_path as string) ?? `${application_id}/pack_v${packData.version}.pdf`;
    const unmerged = (packData.unmerged ?? []) as Array<
      { id: string; type: string; file_url: string; file_name: string; size_bytes?: number }
    >;

    // Taille du pack renvoyée directement par generate-application-pack —
    // évite de dépendre de la propagation de l'URL publique juste après
    // l'upload (source du 400 observé lors des premiers tests).
    const packSizeBytes    = (packData.size_bytes as number) ?? 0;
    const unmergedSizeBytes = unmerged.reduce((s, d) => s + (d.size_bytes ?? 0), 0);
    const totalSizeMb       = (packSizeBytes + unmergedSizeBytes) / (1024 * 1024);

    //  3. Mode attachments : ≤ MAX_ATTACH_MB  joint, sinon liens signés
    let attachments: Array<{ filename: string; content: string; type?: string }> = [];
    let signedLinksHtml = '';
    let signedLinksText = '';

    // Reflète ce qui a réellement été joint/lié — jamais ce qui était prévu.
    const includedLabels: string[] = [];   // pour le corps de l'email (texte simple)
    const includedHtmlItems: string[] = [];

    const packFilename = `Dossier_${(studentName || 'candidature').replace(/\s+/g, '_')}.pdf`;

    if (totalSizeMb <= MAX_ATTACH_MB) {
      // Mode 1  Télécharger et attacher le pack + les documents non fusionnés
      try {
        // Téléchargement via l'API Storage authentifiée (pas fetch(packUrl)) :
        // juste après l'upload, l'URL publique peut renvoyer 400/404 le temps
        // de sa propagation côté CDN ; .download() lit l'objet directement.
        const { data: blob, error: dlErr } = await supabase.storage
          .from('application-packs')
          .download(packPath);

        if (blob) {
          const bytes = new Uint8Array(await blob.arrayBuffer());
          attachments.push({ filename: packFilename, content: bytesToBase64(bytes) });
          includedLabels.push('Dossier complet de candidature (pack PDF)');
          includedHtmlItems.push('<li>Dossier complet de candidature (pack PDF)</li>');
        } else {
          console.error(`Pack download failed for ${packPath}: ${dlErr?.message}`);
        }
      } catch (fetchErr) {
        // Ne doit jamais passer inaperçu : sans ce log, un email part en
        // prétendant joindre le dossier alors qu'aucune pièce n'est attachée.
        console.error(`Pack download threw: ${String(fetchErr)} for ${packPath}`);
      }

      for (const doc of unmerged) {
        try {
          // Le bucket "documents" est prive : fetch(url) echoue desormais.
          // .download() via service role contourne RLS, comme pour le pack.
          const parsed = extractBucketAndPath(doc.file_url);
          if (!parsed) continue;
          const { bucket, path: storagePath } = parsed;

          const { data: blob, error: dlErr } = await supabase.storage.from(bucket).download(storagePath);
          if (dlErr || !blob) {
            console.error(`Document download failed for ${doc.file_url}: ${dlErr?.message}`);
            continue;
          }
          const filename = doc.file_name || `${doc.type}_${doc.id.slice(0, 8)}`;
          attachments.push({ filename, content: bytesToBase64(new Uint8Array(await blob.arrayBuffer())) });
          includedLabels.push(`${TYPE_LABELS[doc.type] ?? doc.type}${doc.file_name ? ` (${doc.file_name})` : ''}`);
          includedHtmlItems.push(
            `<li>${TYPE_LABELS[doc.type] ?? doc.type}${doc.file_name ? ` <span style="color:#6b7280;font-size:12px;">(${doc.file_name})</span>` : ''}</li>`,
          );
        } catch (fetchErr) {
          console.error(`Document download threw: ${String(fetchErr)} for ${doc.file_url}`);
        }
      }
    } else {
      // Mode 2  Liens signés (dossier trop volumineux)
      try {
        const { data: signed } = await supabase.storage
          .from('application-packs')
          .createSignedUrl(packPath, 7 * 24 * 3600); // 7 jours

        if (signed?.signedUrl) {
          signedLinksHtml += `<li><a href="${signed.signedUrl}">Dossier complet de candidature (pack PDF)</a></li>`;
          signedLinksText += `  - Dossier complet de candidature (pack PDF): ${signed.signedUrl}\n`;
          includedLabels.push('Dossier complet de candidature (pack PDF)');
          includedHtmlItems.push('<li>Dossier complet de candidature (pack PDF)</li>');
        } else {
          console.error(`createSignedUrl failed for pack path ${packPath}`);
        }
      } catch (signErr) {
        console.error(`createSignedUrl threw: ${String(signErr)} for pack path ${packPath}`);
      }

      for (const doc of unmerged) {
        try {
          // Extraire le chemin relatif depuis l'URL Supabase Storage
          const parsed = extractBucketAndPath(doc.file_url);
          if (!parsed) continue;
          const { bucket, path: storagePath } = parsed;

          const { data: signed } = await supabase.storage
            .from(bucket)
            .createSignedUrl(storagePath, 7 * 24 * 3600); // 7 jours

          if (signed?.signedUrl) {
            const label = doc.file_name || doc.type;
            signedLinksHtml += `<li><a href="${signed.signedUrl}">${label}</a></li>`;
            signedLinksText += `  - ${label}: ${signed.signedUrl}\n`;
            includedLabels.push(`${TYPE_LABELS[doc.type] ?? doc.type}${doc.file_name ? ` (${doc.file_name})` : ''}`);
            includedHtmlItems.push(
              `<li>${TYPE_LABELS[doc.type] ?? doc.type}${doc.file_name ? ` <span style="color:#6b7280;font-size:12px;">(${doc.file_name})</span>` : ''}</li>`,
            );
          }
        } catch (_) {}
      }
    }

    // Construits APRÈS coup, à partir de ce qui a réellement été joint/lié —
    // jamais depuis ce qui était seulement prévu.
    const docsListHtml = includedHtmlItems.length > 0
      ? includedHtmlItems.join('')
      : '<li style="color:#6b7280;">Aucun document n\'a pu être transmis</li>';
    const docsListText = includedLabels.length > 0
      ? includedLabels.map((l) => `  - ${l}`).join('\n')
      : '  - Aucun document n\'a pu être transmis';

    //  4. Template email 
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
    const tpl       = templates?.[0];
    const vars      = { studentName, programName, univName, country, submittedAt, documentsListText: docsListText };
    const subject   = tpl
      ? replaceVars(tpl.subject_template, vars)
      : `[Studium] Application – ${studentName} – ${programName}`;
    const bodyTxt   = tpl
      ? replaceVars(tpl.body_template, vars)
      : buildEmailText({ studentName, programName, univName, country, submittedAt, signedLinksText, docsListText });
    const html      = buildEmailHtml({
      studentName, programName, univName, country, submittedAt,
      notes:          app.notes,
      customBody:     tpl ? replaceVarsHtml(tpl.body_template, vars, docsListHtml) : null,
      attachCount:    attachments.length,
      signedLinksHtml,
      docsListHtml,
    });

    //  5. Envoi via Resend 
    const resendBody: any = {
      from:    `${FROM_NAME} <${FROM_EMAIL}>`,
      to:      [to_email],
      cc:      cc_emails.length ? cc_emails : undefined,
      subject,
      html,
      text:    bodyTxt,
    };

    if (attachments.length > 0) {
      resendBody.attachments = attachments;
    }

    //  5bis. Retry avec backoff croissant (1s, 2s) sur échec Resend —
    //  couvre les erreurs transitoires (réseau, 429, 5xx ponctuel).
    const MAX_ATTEMPTS = 3;
    let resendData: any = null;
    let success         = false;
    let attempts        = 0;

    for (attempts = 1; attempts <= MAX_ATTEMPTS; attempts++) {
      try {
        const resendRes = await fetch('https://api.resend.com/emails', {
          method:  'POST',
          headers: { 'Authorization': `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
          body:    JSON.stringify(resendBody),
        });
        resendData = await resendRes.json();
        success    = resendRes.ok;
      } catch (fetchErr) {
        resendData = { error: String(fetchErr) };
        success    = false;
      }

      if (success || attempts === MAX_ATTEMPTS) break;
      await new Promise(r => setTimeout(r, attempts * 1000));
    }

    const msgId  = resendData?.id ?? null;
    const errMsg = success ? null : JSON.stringify(resendData);
    const retryCount = attempts - 1;

    //  6. Log + mise à jour statut
    const { error: logErr } = await supabase.from('email_logs').insert({
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
      sent_at:             new Date().toISOString(),
      retry_count:         retryCount,
    });
    // Ne doit jamais passer inaperçu : une erreur ici (contrainte, RLS...)
    // cassait silencieusement toute la traçabilité des envois jusqu'ici.
    if (logErr) console.error('email_logs insert failed:', logErr.message);

    if (success) {
      await supabase.from('applications').update({ status: 'sent' }).eq('id', application_id);
    }

    if (!success) return jsonError(`Resend error: ${errMsg}`, 502);

    return new Response(JSON.stringify({
      success:        true,
      message_id:     msgId,
      attachments:    attachments.length,
      signed_links:   signedLinksHtml ? true : false,
    }), {
      headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
    });

  } catch (err) {
    return jsonError(String(err), 500);
  }
});

/*  Helpers  */

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
