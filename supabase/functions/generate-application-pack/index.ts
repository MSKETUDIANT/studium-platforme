// @ts-nocheck  Deno Edge Function — pack PDF assemblé (couverture + profil +
// motivation + fusion des documents approuvés) pour une candidature.
// Remplace l'envoi de documents individuels par un dossier unique persistant.
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { PDFDocument, StandardFonts, rgb } from 'https://esm.sh/pdf-lib@1.17.1';
import { docStoragePath, wrapText, classifyDocuments, isPackStale } from './pack_utils.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const PACKS_BUCKET = 'application-packs';
const DOCS_BUCKET = 'documents';

// Palette reprise de application_pdf_builder.dart (mobile) pour une identité
// visuelle cohérente entre le résumé mobile et le pack assemblé.
const NAVY   = rgb(0x0B / 255, 0x18 / 255, 0x52 / 255);
const BLUE   = rgb(0x15 / 255, 0x3E / 255, 0xA8 / 255);
const GREY   = rgb(0x64 / 255, 0x74 / 255, 0x8B / 255);
const MUTED  = rgb(0x94 / 255, 0xA3 / 255, 0xB8 / 255);
const BORDER = rgb(0xE5 / 255, 0xE7 / 255, 0xEB / 255);

const PAGE_W    = 595.28; // A4 portrait, points
const PAGE_H    = 841.89;
const MARGIN_X  = 40;
const MARGIN_Y  = 36;

const TYPE_LABELS: Record<string, string> = {
  cv:                 'Curriculum Vitae',
  transcript:         'Relevé de notes et diplômes',
  recommendation:     'Lettre de recommandation',
  passport:           "Passeport / Pièce d'identité",
  motivation_letter:  'Lettre de motivation',
  diploma:            'Diplôme',
  language_cert:      'Attestation de langue',
  financial_proof:    'Justificatif de financement',
  other:              'Document complémentaire',
};

interface Payload {
  application_id:   string;
  sent_by?:         string;
  force_regenerate?: boolean;
}

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin':  '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };
}

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status, headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders() });

  try {
    const payload: Payload = await req.json();
    const { application_id, sent_by, force_regenerate } = payload;
    if (!application_id) return jsonError('application_id is required', 400);

    const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

    //  1. Données de la candidature
    const { data: app, error: appErr } = await supabase
      .from('applications')
      .select(`
        id, status, submitted_at, student_profile_id, motivation_letter,
        student_profiles!student_profile_id (
          first_name, last_name, birth_date, nationality, country_residence,
          phone, address, motivation_letter, academic_goals, career_goals, updated_at
        ),
        programs!program_id (
          program_name, university_name, country, level
        )
      `)
      .eq('id', application_id)
      .single();

    if (appErr || !app) return jsonError('Application not found', 404);

    const profile = app.student_profiles;
    const program = app.programs;
    const studentName = `${profile?.first_name ?? ''} ${profile?.last_name ?? ''}`.trim() || 'Candidat';

    // La lettre propre à la candidature (adaptée par l'étudiant pour ce
    // programme) prime sur le modèle générique du profil — cf. migration
    // 20260716_application_motivation_letter.sql.
    const motivationLetter = app.motivation_letter || profile?.motivation_letter || '';

    // L'email vit sur auth.users, pas student_profiles (cf. CDC A2 "Informations
    // personnelles" qui le liste dans le profil) : recuperation via l'API admin,
    // disponible ici car la fonction tourne avec la service role key.
    const { data: authUserData } = await supabase.auth.admin.getUserById(app.student_profile_id);
    const studentEmail = authUserData?.user?.email ?? '';

    // La table s'appelle "academic_backgrounds" (colonne "user_id"), pas
    // "educations" : verifie via profile_remote_datasource.dart, la table
    // "educations" du schema baseline n'existe pas sur la base reelle.
    const { data: academics, error: academicsErr } = await supabase
      .from('academic_backgrounds')
      .select('degree, university, year, average')
      .eq('user_id', app.student_profile_id)
      .order('year', { ascending: false });
    if (academicsErr) console.error(`academic_backgrounds fetch failed: ${academicsErr.message}`);

    const { data: experiences, error: experiencesErr } = await supabase
      .from('experiences')
      .select('company, position, start_date, end_date, description')
      .eq('student_profile_id', app.student_profile_id)
      .order('start_date', { ascending: false });
    if (experiencesErr) console.error(`experiences fetch failed: ${experiencesErr.message}`);

    //  2. Documents approuvés (pivot puis fallback, filtre approved dans les deux cas)
    const { data: linkedRows } = await supabase
      .from('application_documents')
      .select('document_id')
      .eq('application_id', application_id);

    const hasPivot = linkedRows && linkedRows.length > 0;
    let docs: any[] = [];

    if (hasPivot) {
      const docIds = linkedRows.map((r: any) => r.document_id).filter(Boolean);
      if (docIds.length > 0) {
        const { data } = await supabase
          .from('documents')
          .select('id, type, file_url, file_name, mime_type, size_bytes, status, updated_at')
          .in('id', docIds)
          .eq('status', 'approved');
        docs = data ?? [];
      }
    } else {
      const { data } = await supabase
        .from('documents')
        .select('id, type, file_url, file_name, mime_type, size_bytes, status, updated_at')
        .eq('student_profile_id', app.student_profile_id)
        .eq('status', 'approved');
      docs = data ?? [];
    }

    const isPdf   = (mime?: string) => (mime ?? '').includes('pdf');
    const { mergeable, unmerged } = classifyDocuments(docs);

    const unmergedPayload = unmerged.map((d) => ({
      id: d.id, type: d.type, file_url: d.file_url, file_name: d.file_name, size_bytes: d.size_bytes,
    }));

    //  3. Réutiliser un pack existant si présent et toujours à jour, sauf
    //     régénération forcée — la liste des documents non fusionnés reste
    //     toujours recalculée à jour (elle peut changer même si le pack
    //     lui-même ne change pas). "À jour" = généré après la dernière
    //     modification du profil et des documents approuvés (sinon un pack
    //     genéré tôt resterait figé, ex. lettre de motivation ajoutée après
    //     coup et jamais reprise dans le pack déjà envoyé).
    if (!force_regenerate) {
      const { data: existing } = await supabase
        .from('application_packs')
        .select('pack_url, version, generated_at')
        .eq('application_id', application_id)
        .order('version', { ascending: false })
        .limit(1)
        .maybeSingle();

      const isStale = existing && isPackStale(
        [profile?.updated_at, ...docs.map((d) => d.updated_at)],
        existing.generated_at,
      );

      if (existing && !isStale) {
        const existingPath = `${application_id}/pack_v${existing.version}.pdf`;
        const { data: listing } = await supabase.storage
          .from(PACKS_BUCKET)
          .list(application_id, { search: `pack_v${existing.version}.pdf` });
        const sizeBytes = listing?.[0]?.metadata?.size ?? null;

        return new Response(JSON.stringify({
          pack_url: existing.pack_url, pack_path: existingPath, version: existing.version,
          size_bytes: sizeBytes, unmerged: unmergedPayload,
        }), { headers: { ...corsHeaders(), 'Content-Type': 'application/json' } });
      }
    }

    //  4. Construction du PDF assemblé
    const pdfDoc      = await PDFDocument.create();
    const fontRegular = await pdfDoc.embedFont(StandardFonts.Helvetica);
    const fontBold    = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

    // Bandeau de couverture (masthead), identique et repete en haut de
    // chaque page generee par nous — identite visuelle uniforme sur tout le
    // dossier (hors pages de documents fusionnes, qui gardent annexFooter).
    const COVER_BAND_H = 90;
    const coverBand = (page: any, subtitle: string) => {
      page.drawRectangle({ x: 0, y: PAGE_H - COVER_BAND_H, width: PAGE_W, height: COVER_BAND_H, color: NAVY });
      page.drawText('STUDIUM', { x: MARGIN_X, y: PAGE_H - 42, size: 22, font: fontBold, color: rgb(1, 1, 1) });
      page.drawText(subtitle, { x: MARGIN_X, y: PAGE_H - 64, size: 11, font: fontRegular, color: rgb(1, 1, 1) });
    };

    // Etiquette discrete en bas des pages de documents fusionnes : permet de
    // retrouver le dossier d'origine si une page annexe est isolee (imprimee
    // ou extraite seule), sans habillage lourd type page de titre dediee. Le
    // fond blanc semi-opaque garantit la lisibilite quel que soit le contenu
    // du document sous-jacent (scan, CV avec bandeau sombre, etc.).
    const annexFooter = (page: any, label: string) => {
      const w = fontRegular.widthOfTextAtSize(label, 7) + 12;
      page.drawRectangle({ x: MARGIN_X - 6, y: MARGIN_Y - 14, width: w, height: 14, color: rgb(1, 1, 1), opacity: 0.85 });
      page.drawText(label, { x: MARGIN_X, y: MARGIN_Y - 10, size: 7, font: fontRegular, color: MUTED });
    };

    // Etat de "curseur" mutable : page courante + position verticale. newPage()
    // change les deux ; ensure() bascule automatiquement si le contenu deborde,
    // pour eviter le decoupage fige en pages quasi-vides du design precedent.
    let page: any;
    let y = 0;
    let pageSubtitle = 'Profil étudiant';
    const newPage = () => {
      page = pdfDoc.addPage([PAGE_W, PAGE_H]);
      coverBand(page, pageSubtitle);
      y = PAGE_H - COVER_BAND_H - 34;
    };
    const ensure = (needed: number) => { if (y - needed < MARGIN_Y) newPage(); };

    const sectionTitle = (title: string) => {
      ensure(30);
      page.drawRectangle({ x: MARGIN_X, y: y - 2, width: 3, height: 10, color: BLUE });
      page.drawText(title.toUpperCase(), { x: MARGIN_X + 10, y, size: 9, font: fontBold, color: MUTED });
      page.drawLine({
        start: { x: MARGIN_X, y: y - 6 }, end: { x: PAGE_W - MARGIN_X, y: y - 6 },
        thickness: 0.5, color: BORDER,
      });
      y -= 22;
    };

    newPage();

    // --- Identité du candidat et de la candidature ---
    page.drawText(studentName, { x: MARGIN_X, y, size: 17, font: fontBold, color: NAVY });
    y -= 19;
    page.drawText(program?.program_name ?? '', { x: MARGIN_X, y, size: 12, font: fontBold, color: BLUE });
    y -= 15;
    page.drawText(
      `${program?.university_name ?? ''}${program?.country ? ' — ' + program.country : ''}`,
      { x: MARGIN_X, y, size: 10, font: fontRegular, color: GREY },
    );
    y -= 20;

    // Le statut du dossier est un état interne de suivi Studium : il n'a pas
    // sa place dans un document destiné à l'université (cf. CDC B5/B6, qui ne
    // mentionne que couverture/profil/motivation/documents/annexes).
    // Encadré d'informations : une ligne par champ, label à gauche / valeur
    // à droite — reprend les champs "Informations personnelles" du profil
    // étudiant définis au CDC A2 (nom/prénom déjà en en-tête au-dessus).
    const submittedAt = app.submitted_at ? new Date(app.submitted_at).toLocaleDateString('fr-FR') : '—';
    const birthDate = profile?.birth_date ? new Date(profile.birth_date).toLocaleDateString('fr-FR') : '';
    const infoFields: [string, string][] = [
      ['Date de naissance', birthDate],
      ['Nationalité', profile?.nationality ?? ''],
      ['Pays de résidence', profile?.country_residence ?? ''],
      ['Adresse', profile?.address ?? ''],
      ['Téléphone', profile?.phone ?? ''],
      ['Email', studentEmail],
      ['Date de soumission', submittedAt],
      ['Niveau du programme', program?.level ?? ''],
    ];
    const infoRowH = 36;
    const boxH = infoFields.length * infoRowH + 8;
    page.drawRectangle({
      x: MARGIN_X, y: y - boxH, width: PAGE_W - 2 * MARGIN_X, height: boxH,
      color: rgb(0xF8 / 255, 0xFA / 255, 0xFC / 255), borderColor: BORDER, borderWidth: 1,
    });
    let infoY = y - 24;
    infoFields.forEach(([label, value]) => {
      page.drawText(label.toUpperCase(), { x: MARGIN_X + 18, y: infoY, size: 8, font: fontBold, color: MUTED });
      page.drawText(value || '—', { x: MARGIN_X + 170, y: infoY, size: 10, font: fontRegular, color: BLUE });
      infoY -= infoRowH;
    });
    y -= boxH + 12;

    // Saut de page volontaire : la 1re page reste dédiée à l'identité et au
    // résumé de la candidature (elle respire seule), Formations/Expériences/
    // Documents démarrent sur une page propre plutôt que de s'entasser en dessous.
    pageSubtitle = 'Parcours et expériences';
    newPage();

    // Petit encadré par entrée (même style que le bloc d'informations de la
    // page 1) plutôt que du texte brut à la suite — reprend l'esprit des
    // cartes de saisie de l'app (diplôme, expérience), en plus sobre.
    const cardBox = (top: number, h: number) => {
      page.drawRectangle({
        x: MARGIN_X, y: top - h, width: PAGE_W - 2 * MARGIN_X, height: h,
        color: rgb(0xF8 / 255, 0xFA / 255, 0xFC / 255), borderColor: BORDER, borderWidth: 1,
      });
    };

    // --- Formations ---
    sectionTitle('Formations');
    if (academics && academics.length > 0) {
      for (const a of academics) {
        const details = [
          a.year ? `Obtenu en ${a.year}` : null,
          a.average != null ? `Moyenne : ${a.average}` : null,
        ].filter(Boolean).join('   ');
        const cardH = 20 + 16 + (details ? 15 : 0);
        ensure(cardH + 10);
        const top = y;
        cardBox(top, cardH);
        let cy = top - 20;
        page.drawText(`${a.degree ?? ''} — ${a.university ?? ''}`, { x: MARGIN_X + 14, y: cy, size: 11, font: fontBold, color: NAVY });
        cy -= 16;
        if (details) page.drawText(details, { x: MARGIN_X + 14, y: cy, size: 10, font: fontRegular, color: GREY });
        y -= cardH + 10;
      }
    } else {
      ensure(14);
      page.drawText('Aucune formation renseignée.', { x: MARGIN_X, y, size: 10, font: fontRegular, color: GREY });
      y -= 15;
    }
    y -= 14;

    // --- Expériences ---
    sectionTitle('Expériences');
    if (experiences && experiences.length > 0) {
      for (const e of experiences) {
        const lines = e.description ? wrapText(e.description, 85).slice(0, 3) : [];
        const cardH = 20 + 16 + lines.length * 15;
        ensure(cardH + 10);
        const top = y;
        cardBox(top, cardH);
        let cy = top - 20;
        page.drawText(`${e.position ?? ''} — ${e.company ?? ''}`, { x: MARGIN_X + 14, y: cy, size: 11, font: fontBold, color: NAVY });
        cy -= 16;
        for (const line of lines) {
          page.drawText(line, { x: MARGIN_X + 14, y: cy, size: 10, font: fontRegular, color: GREY });
          cy -= 15;
        }
        y -= cardH + 10;
      }
    } else {
      ensure(14);
      page.drawText('Aucune expérience renseignée.', { x: MARGIN_X, y, size: 10, font: fontRegular, color: GREY });
      y -= 15;
    }

    // --- Lettre de motivation (si renseignée) ---
    if (motivationLetter) {
      y -= 24;
      sectionTitle('Lettre de motivation');
      for (const line of wrapText(motivationLetter, 95)) {
        ensure(14);
        page.drawText(line, { x: MARGIN_X, y, size: 10, font: fontRegular, color: NAVY });
        y -= 14;
      }
    }

    // --- Objectifs académiques / de carrière (option, CDC A2) ---
    if (profile?.academic_goals || profile?.career_goals) {
      y -= 24;
      sectionTitle('Objectifs');
      if (profile.academic_goals) {
        ensure(14);
        page.drawText('Objectifs académiques', { x: MARGIN_X, y, size: 10, font: fontBold, color: NAVY });
        y -= 15;
        for (const line of wrapText(profile.academic_goals, 95)) {
          ensure(14);
          page.drawText(line, { x: MARGIN_X, y, size: 10, font: fontRegular, color: GREY });
          y -= 14;
        }
        y -= 10;
      }
      if (profile.career_goals) {
        ensure(14);
        page.drawText('Objectifs de carrière', { x: MARGIN_X, y, size: 10, font: fontBold, color: NAVY });
        y -= 15;
        for (const line of wrapText(profile.career_goals, 95)) {
          ensure(14);
          page.drawText(line, { x: MARGIN_X, y, size: 10, font: fontRegular, color: GREY });
          y -= 14;
        }
      }
    }

    // --- Documents inclus ---
    y -= 24;
    sectionTitle('Documents inclus dans ce dossier');

    // Juste le type de document : le nom de fichier technique et le poids
    // n'apportent rien à un service d'admissions qui consulte ce dossier.
    const docRow = (label: string, ok: boolean) => {
      ensure(18);
      page.drawText('•', { x: MARGIN_X, y: y - 1, size: 11, font: fontBold, color: ok ? BLUE : MUTED });
      page.drawText(label, { x: MARGIN_X + 14, y, size: 10, font: fontBold, color: NAVY });
      y -= 20;
    };

    if (mergeable.length === 0) {
      ensure(14);
      page.drawText('Aucun document fusionnable.', { x: MARGIN_X, y, size: 9, font: fontRegular, color: GREY });
      y -= 14;
    }
    for (const d of mergeable) {
      docRow(TYPE_LABELS[d.type] ?? d.type, true);
    }
    if (unmerged.length > 0) {
      y -= 8;
      sectionTitle('Documents transmis séparément (format non fusionnable)');
      for (const d of unmerged) {
        docRow(TYPE_LABELS[d.type] ?? d.type, false);
      }
    }

    // --- Fusion effective des documents PDF et images approuvés ---
    // Enchaînés directement après la liste, sans page de titre séparée pour
    // chacun (déjà annoncés ci-dessus) — juste une étiquette de traçabilité
    // discrète en bas de chaque page annexe (cf. annexFooter).
    const totalAnnexes = mergeable.length;
    let annexIndex = 0;
    for (const doc of mergeable) {
      try {
        const path = docStoragePath(doc.file_url);
        if (!path) continue;
        const { data: blob, error: dlErr } = await supabase.storage.from(DOCS_BUCKET).download(path);
        if (dlErr || !blob) { console.error(`document download failed (${path}): ${dlErr?.message}`); continue; }
        const bytes = new Uint8Array(await blob.arrayBuffer());

        annexIndex += 1;
        const footerLabel = `Annexe ${annexIndex} sur ${totalAnnexes} — ${TYPE_LABELS[doc.type] ?? doc.type} — Réf. ${application_id.slice(0, 8).toUpperCase()}`;

        if (isPdf(doc.mime_type)) {
          const srcDoc = await PDFDocument.load(bytes, { ignoreEncryption: true });
          const pages  = await pdfDoc.copyPages(srcDoc, srcDoc.getPageIndices());
          pages.forEach((p) => { pdfDoc.addPage(p); annexFooter(p, footerLabel); });
        } else {
          const image = doc.mime_type?.includes('png')
            ? await pdfDoc.embedPng(bytes)
            : await pdfDoc.embedJpg(bytes);
          const imgPage = pdfDoc.addPage([PAGE_W, PAGE_H]);
          const scale = Math.min(
            (PAGE_W - 2 * MARGIN_X) / image.width,
            (PAGE_H - 2 * MARGIN_Y) / image.height,
          );
          const w = image.width * scale;
          const h = image.height * scale;
          imgPage.drawImage(image, { x: (PAGE_W - w) / 2, y: (PAGE_H - h) / 2, width: w, height: h });
          annexFooter(imgPage, footerLabel);
        }
      } catch (_) {
        // Document illisible/non téléchargeable : reste listé mais non fusionné dans le rendu.
      }
    }

    // --- Pagination globale (y compris les pages de documents fusionnés) ---
    const allPages = pdfDoc.getPages();
    allPages.forEach((p, i) => {
      const label = `${i + 1} / ${allPages.length}`;
      p.drawText(label, {
        x: PAGE_W - MARGIN_X - fontRegular.widthOfTextAtSize(label, 8),
        y: MARGIN_Y, size: 8, font: fontRegular, color: MUTED,
      });
    });

    const pdfBytes = await pdfDoc.save();

    //  5. Version (existante + 1, sinon 1)
    const { data: prev } = await supabase
      .from('application_packs')
      .select('version')
      .eq('application_id', application_id)
      .order('version', { ascending: false })
      .limit(1)
      .maybeSingle();
    const version = (prev?.version ?? 0) + 1;

    //  6. Upload Storage
    const path = `${application_id}/pack_v${version}.pdf`;
    const { error: uploadErr } = await supabase.storage
      .from(PACKS_BUCKET)
      .upload(path, pdfBytes, { contentType: 'application/pdf', upsert: true });

    if (uploadErr) return jsonError(`Upload failed: ${uploadErr.message}`, 500);

    const { data: publicUrlData } = supabase.storage.from(PACKS_BUCKET).getPublicUrl(path);
    const packUrl = publicUrlData.publicUrl;

    //  7. Enregistrement application_packs
    const { error: insertErr } = await supabase.from('application_packs').insert({
      application_id, pack_url: packUrl, version, generated_by: sent_by ?? null,
    });
    // Ne doit jamais passer inaperçu : sans cette ligne, chaque envoi régénérerait le pack.
    if (insertErr) console.error('application_packs insert failed:', insertErr.message);

    return new Response(JSON.stringify({
      pack_url: packUrl,
      pack_path: path,
      version,
      size_bytes: pdfBytes.length,
      unmerged: unmergedPayload,
    }), { headers: { ...corsHeaders(), 'Content-Type': 'application/json' } });

  } catch (err) {
    return jsonError(String(err), 500);
  }
});
