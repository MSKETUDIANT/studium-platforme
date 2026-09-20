// Fonctions pures extraites de index.ts pour être testables sans démarrer
// Deno.serve (import direct, aucun effet de bord réseau).

export interface TemplateData {
  studentName:      string;
  programName:      string;
  univName:         string;
  country:          string;
  submittedAt:      string;
  notes?:           string | null;
  customBody?:      string | null;
  attachCount?:     number;
  signedLinksHtml?: string;
  signedLinksText?: string;
  docsListHtml?:    string;
  docsListText?:    string;
}

export function replaceVars(tpl: string, vars: Record<string, string>): string {
  return tpl
    .replace(/\{\{student_name\}\}/g,     vars.studentName         ?? '')
    .replace(/\{\{program_name\}\}/g,     vars.programName         ?? '')
    .replace(/\{\{university_name\}\}/g,  vars.univName            ?? '')
    .replace(/\{\{country\}\}/g,          vars.country ? ` (${vars.country})` : '')
    .replace(/\{\{submitted_at\}\}/g,     vars.submittedAt         ?? '')
    .replace(/\{\{documents_list\}\}/g,   vars.documentsListText   ?? '');
}

// Version HTML avec rendu liste pour les templates
export function replaceVarsHtml(tpl: string, vars: Record<string, string>, docsListHtml: string): string {
  return tpl
    .replace(/\{\{student_name\}\}/g,     vars.studentName       ?? '')
    .replace(/\{\{program_name\}\}/g,     vars.programName       ?? '')
    .replace(/\{\{university_name\}\}/g,  vars.univName          ?? '')
    .replace(/\{\{country\}\}/g,          vars.country ? ` (${vars.country})` : '')
    .replace(/\{\{submitted_at\}\}/g,     vars.submittedAt       ?? '')
    .replace(/\{\{documents_list\}\}/g,   `<ul style="margin:8px 0 16px;padding-left:20px;">${docsListHtml}</ul>`);
}

export function buildEmailHtml(d: TemplateData): string {
  const docsSection = `
    <p style="font-size:14px;font-weight:bold;color:#111827;margin:0 0 8px;"> Documents transmis :</p>
    <ul style="font-size:14px;color:#374151;margin:0 0 16px;padding-left:20px;line-height:1.8;">
      ${d.docsListHtml ?? '<li style="color:#6b7280;">Aucun document approuvé</li>'}
    </ul>`;

  const attachInfo = d.attachCount && d.attachCount > 0
    ? `${docsSection}<p style="font-size:13px;color:#6b7280;margin:0 0 16px;"> Ces documents sont joints en pièce jointe à cet email.</p>`
    : d.signedLinksHtml
      ? `${docsSection}<p style="font-size:13px;color:#374151;margin:0 0 8px;"> <strong>Liens de téléchargement (valables 7 jours) :</strong></p>
         <ul style="font-size:13px;color:#2563eb;margin:0 0 20px;padding-left:20px;">${d.signedLinksHtml}</ul>`
      : `<p style="font-size:14px;color:#6b7280;margin:0 0 12px;font-style:italic;">Aucun document approuvé à joindre.</p>`;

  const bodyContent = d.customBody
    ? d.customBody.split('\n').map(line =>
        `<p style="font-size:14px;color:#374151;line-height:1.6;margin:0 0 12px;">${line || '&nbsp;'}</p>`
      ).join('') + attachInfo
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
       ${attachInfo}
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

export function buildEmailText(d: TemplateData): string {
  const docsList    = d.docsListText ? `\nDOCUMENTS TRANSMIS :\n${d.docsListText}` : '';
  const docsSection = d.signedLinksText
    ? `${docsList}\n\nLIENS DE TÉLÉCHARGEMENT (valables 7 jours) :\n${d.signedLinksText}`
    : d.attachCount && d.attachCount > 0
      ? `${docsList}\n(Documents joints en pièce jointe)`
      : '';

  return `STUDIUM  Candidature académique

Madame, Monsieur,

Nous vous transmettons la candidature de ${d.studentName} pour le programme ${d.programName} à ${d.univName}${d.country ? ` (${d.country})` : ''}.

DÉTAILS :
- Candidat        : ${d.studentName}
- Programme       : ${d.programName}
- Université      : ${d.univName}
- Date soumission : ${d.submittedAt}
${docsSection}
Cordialement,
L'équipe Studium Admissions
support@studium.app`;
}

export function bytesToBase64(bytes: Uint8Array): string {
  let binary = '';
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}

// Le bucket cible garde un format d'URL publique historique meme apres son
// passage en prive (utile pour en extraire bucket + chemin ; le
// telechargement reel passe par .download()/.createSignedUrl() en service
// role, qui contourne RLS).
export function extractBucketAndPath(fileUrl: string): { bucket: string; path: string } | null {
  const urlObj = new URL(fileUrl);
  const pathParts = urlObj.pathname.split('/object/public/');
  if (pathParts.length < 2) return null;
  const bucketAndPath = pathParts[1];
  const slashIdx = bucketAndPath.indexOf('/');
  if (slashIdx === -1) return null;
  return { bucket: bucketAndPath.slice(0, slashIdx), path: bucketAndPath.slice(slashIdx + 1) };
}
