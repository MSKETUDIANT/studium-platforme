// @ts-nocheck  Deno Edge Function
// Génère un PDF pack candidature et le stocke dans Supabase Storage
// Payload : { application_id: string }
// Retourne : { url: string, path: string }

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { PDFDocument, rgb, StandardFonts } from 'https://esm.sh/pdf-lib@1.17.1'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

//  Couleurs 
const NAVY  = rgb(0.031, 0.071, 0.176)  // #08122E
const BLUE  = rgb(0.082, 0.243, 0.659)  // #153EA8
const LIGHT = rgb(0.902, 0.929, 0.961)  // #E6EDF5
const WHITE = rgb(1, 1, 1)
const GREY  = rgb(0.612, 0.631, 0.69)   // #9CA3AF
const GREEN = rgb(0.063, 0.725, 0.506)  // #10B981

//  Helpers 

function truncate(str: string, max: number): string {
  if (!str) return ''
  return str.length > max ? str.substring(0, max) + '' : str
}

function fmtDate(iso: string | null): string {
  if (!iso) return ''
  return new Date(iso).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

const STATUS_LABELS: Record<string, string> = {
  draft:           'Brouillon',
  submitted:       'Soumise',
  needs_fix:       'Correction demandée',
  verified:        'Validée',
  sent:            'Envoyée',
  pending_decision:'En attente de décision',
  accepted:        'Acceptée',
  rejected:        'Refusée',
  archived:        'Archivée',
}

const DOC_LABELS: Record<string, string> = {
  cv:             'Curriculum Vitae',
  transcript:     'Relevé de notes',
  recommendation: 'Lettre de recommandation',
  passport:       'Passeport / Pièce d\'identité',
  other:          'Document complémentaire',
}

//  Génération PDF 

async function buildPdf(app: any): Promise<Uint8Array> {
  const pdf  = await PDFDocument.create()
  const bold = await pdf.embedFont(StandardFonts.HelveticaBold)
  const reg  = await pdf.embedFont(StandardFonts.Helvetica)

  const W = 595.28   // A4 width pt
  const H = 841.89   // A4 height pt

  //  PAGE 1 : Couverture 
  const cover = pdf.addPage([W, H])

  // Fond gradient simulé (bandes)
  cover.drawRectangle({ x: 0, y: H * 0.45, width: W, height: H * 0.55, color: NAVY })
  cover.drawRectangle({ x: 0, y: 0,         width: W, height: H * 0.45, color: LIGHT })

  // Bande décorative
  cover.drawRectangle({ x: 0, y: H * 0.44, width: W, height: 4, color: BLUE })

  // Logo / Nom plateforme
  cover.drawText('STUDIUM', {
    x: 50, y: H - 70,
    size: 28, font: bold, color: WHITE,
  })
  cover.drawText('Plateforme de Candidatures Académiques', {
    x: 50, y: H - 92,
    size: 11, font: reg, color: rgb(0.7, 0.8, 0.95),
  })

  // Titre central
  cover.drawText('DOSSIER DE CANDIDATURE', {
    x: 50, y: H * 0.6,
    size: 22, font: bold, color: WHITE,
  })

  const student = app.student_profiles
  const program = app.programs
  const studentName = [student?.first_name, student?.last_name].filter(Boolean).join(' ') || 'Étudiant'

  cover.drawText(studentName, {
    x: 50, y: H * 0.6 - 36,
    size: 16, font: reg, color: rgb(0.8, 0.88, 1),
  })

  // Info programme
  cover.drawText('Programme', { x: 50, y: H * 0.47 - 20, size: 9, font: reg, color: GREY })
  cover.drawText(truncate(program?.program_name ?? '', 60), {
    x: 50, y: H * 0.47 - 34, size: 13, font: bold, color: NAVY,
  })
  cover.drawText(truncate(program?.university_name ?? '', 60), {
    x: 50, y: H * 0.47 - 50, size: 10, font: reg, color: BLUE,
  })

  // Méta
  const metaY = H * 0.47 - 90
  const cols = [
    ['Pays',     program?.country ?? ''],
    ['Niveau',   program?.level ?? ''],
    ['Statut',   STATUS_LABELS[app.status] ?? app.status],
    ['Date',     fmtDate(app.submitted_at)],
  ]
  cols.forEach(([label, value], i) => {
    const x = 50 + i * 130
    cover.drawText(label.toUpperCase(), { x, y: metaY + 14, size: 7, font: bold, color: GREY })
    cover.drawText(truncate(value, 14),  { x, y: metaY,      size: 10, font: bold, color: NAVY })
  })

  // Footer
  cover.drawText(`Généré le ${new Date().toLocaleDateString('fr-FR')} · Studium`, {
    x: 50, y: 30, size: 8, font: reg, color: GREY,
  })

  //  PAGE 2 : Profil étudiant 
  const p2 = pdf.addPage([W, H])
  let y = H - 50

  const section = (title: string) => {
    p2.drawRectangle({ x: 40, y: y - 22, width: W - 80, height: 24, color: NAVY })
    p2.drawText(title, { x: 50, y: y - 16, size: 11, font: bold, color: WHITE })
    y -= 40
  }

  const row = (label: string, value: string) => {
    p2.drawText(label + ' :', { x: 60, y, size: 9, font: bold, color: NAVY })
    p2.drawText(truncate(value, 70), { x: 180, y, size: 9, font: reg, color: rgb(0.2, 0.2, 0.2) })
    y -= 16
  }

  // Header page
  p2.drawText('STUDIUM', { x: 50, y: H - 30, size: 10, font: bold, color: BLUE })
  p2.drawText('Dossier de candidature', { x: 50, y: H - 44, size: 8, font: reg, color: GREY })
  p2.drawLine({ start: { x: 40, y: H - 50 }, end: { x: W - 40, y: H - 50 }, thickness: 0.5, color: LIGHT })
  y = H - 70

  section('PROFIL ÉTUDIANT')
  row('Nom complet', studentName)
  row('Nationalité', student?.nationality ?? '')
  row('Email', app.email ?? student?.email ?? '')
  row('Téléphone', student?.phone ?? '')
  row('Pays de résidence', student?.country_of_residence ?? '')
  y -= 10

  // Parcours académique
  const edus = app.educations ?? []
  if (edus.length > 0) {
    section('PARCOURS ACADÉMIQUE')
    edus.forEach((e: any) => {
      row('Institution', e.institution ?? '')
      row('Diplôme', e.degree ?? '')
      row('Année', e.graduation_year?.toString() ?? '')
      if (e.gpa) row('Moyenne', e.gpa.toString())
      y -= 6
    })
  }

  // Expériences
  const exps = app.experiences ?? []
  if (exps.length > 0) {
    section('EXPÉRIENCES PROFESSIONNELLES')
    exps.forEach((e: any) => {
      row('Entreprise', e.company ?? '')
      row('Poste', e.position ?? '')
      row('Période', `${e.start_date ?? '?'}  ${e.end_date ?? 'Présent'}`)
      y -= 6
    })
  }

  //  PAGE 3 : Lettre de motivation 
  if (app.motivation_letter) {
    const p3    = pdf.addPage([W, H])
    let   y3    = H - 70

    p3.drawText('STUDIUM', { x: 50, y: H - 30, size: 10, font: bold, color: BLUE })
    p3.drawLine({ start: { x: 40, y: H - 50 }, end: { x: W - 40, y: H - 50 }, thickness: 0.5, color: LIGHT })
    p3.drawRectangle({ x: 40, y: y3 - 22, width: W - 80, height: 24, color: NAVY })
    p3.drawText('LETTRE DE MOTIVATION', { x: 50, y: y3 - 16, size: 11, font: bold, color: WHITE })
    y3 -= 50

    const words   = (app.motivation_letter as string).split(' ')
    let   line    = ''
    const maxW    = 70
    const lineH   = 14
    const margin  = 50

    for (const word of words) {
      const test = line ? `${line} ${word}` : word
      if (test.length > maxW) {
        p3.drawText(line, { x: margin, y: y3, size: 10, font: reg, color: rgb(0.2, 0.2, 0.2) })
        y3 -= lineH
        line = word
        if (y3 < 60) break
      } else {
        line = test
      }
    }
    if (line && y3 >= 60) {
      p3.drawText(line, { x: margin, y: y3, size: 10, font: reg, color: rgb(0.2, 0.2, 0.2) })
    }
  }

  //  PAGE 4 : Documents 
  const p4 = pdf.addPage([W, H])
  let y4   = H - 70

  p4.drawText('STUDIUM', { x: 50, y: H - 30, size: 10, font: bold, color: BLUE })
  p4.drawLine({ start: { x: 40, y: H - 50 }, end: { x: W - 40, y: H - 50 }, thickness: 0.5, color: LIGHT })
  p4.drawRectangle({ x: 40, y: y4 - 22, width: W - 80, height: 24, color: NAVY })
  p4.drawText('DOCUMENTS FOURNIS', { x: 50, y: y4 - 16, size: 11, font: bold, color: WHITE })
  y4 -= 50

  const docs = app.documents ?? []
  if (docs.length === 0) {
    p4.drawText('Aucun document joint.', { x: 60, y: y4, size: 10, font: reg, color: GREY })
  } else {
    docs.forEach((d: any, i: number) => {
      const bg = i % 2 === 0 ? LIGHT : WHITE
      p4.drawRectangle({ x: 40, y: y4 - 18, width: W - 80, height: 20, color: bg })
      p4.drawText(DOC_LABELS[d.type] ?? d.type ?? '', {
        x: 50, y: y4 - 13, size: 9, font: bold, color: NAVY,
      })
      const statusColor = d.status === 'approved' ? GREEN : d.status === 'rejected' ? rgb(0.87, 0.15, 0.15) : GREY
      p4.drawText((d.status === 'approved' ? ' Approuvé' : d.status === 'rejected' ? ' Rejeté' : ' En attente'), {
        x: W - 160, y: y4 - 13, size: 9, font: bold, color: statusColor,
      })
      p4.drawText(truncate(d.file_name ?? '', 40), { x: 50, y: y4 - 25, size: 7, font: reg, color: GREY })
      y4 -= 34
    })
  }

  // Signature page finale
  p4.drawLine({ start: { x: 40, y: 60 }, end: { x: W - 40, y: 60 }, thickness: 0.5, color: LIGHT })
  p4.drawText('Ce document est généré automatiquement par la plateforme Studium. Contact : support@studium.app',
    { x: 50, y: 44, size: 7, font: reg, color: GREY })

  return pdf.save()
}

//  Handler principal 

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { application_id } = await req.json()
    if (!application_id) {
      return new Response(JSON.stringify({ error: 'application_id requis' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_KEY)

    // Récupérer les données complètes de la candidature
    const { data: app, error } = await supabase
      .from('applications')
      .select(`
        id, status, submitted_at, notes, motivation_letter,
        student_profiles!student_profile_id (
          first_name, last_name, nationality, phone, country_of_residence
        ),
        programs!program_id (
          program_name, university_name, country, level
        ),
        documents (
          id, type, file_name, status
        ),
        educations:student_profiles!student_profile_id (
          educations ( institution, degree, graduation_year, gpa )
        ),
        experiences:student_profiles!student_profile_id (
          experiences ( company, position, start_date, end_date )
        )
      `)
      .eq('id', application_id)
      .single()

    if (error || !app) throw error ?? new Error('Candidature introuvable')

    // Aplatir les relations imbriquées
    const flat = {
      ...app,
      student_profiles: app.student_profiles,
      programs:         app.programs,
      documents:        app.documents ?? [],
      educations:       (app.educations as any)?.educations ?? [],
      experiences:      (app.experiences as any)?.experiences ?? [],
    }

    // Générer le PDF
    const pdfBytes = await buildPdf(flat)

    // Sauvegarder dans Supabase Storage
    const path = `pdfs/${application_id}/dossier_${Date.now()}.pdf`
    const { error: uploadErr } = await supabase.storage
      .from('documents')
      .upload(path, pdfBytes, { contentType: 'application/pdf', upsert: true })

    if (uploadErr) throw uploadErr

    // URL publique signée (1 heure)
    const { data: signed } = await supabase.storage
      .from('documents')
      .createSignedUrl(path, 3600)

    console.log(`PDF généré : ${path}`)

    return new Response(JSON.stringify({ success: true, url: signed?.signedUrl, path }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (err) {
    console.error('Erreur generate-pdf:', err)
    return new Response(JSON.stringify({ success: false, error: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
