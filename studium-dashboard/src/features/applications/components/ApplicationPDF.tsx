import { Document, Page, Text, View, StyleSheet } from '@react-pdf/renderer';
import type { Application, RawStatus } from '../types/application';
import type { StatusHistoryEntry } from '../services/applications_service';
import { RAW_STATUS_LABELS } from '../types/application';

const LEVEL_LABELS: Record<string, string> = {
  bachelor: 'Licence',
  master:   'Master',
  phd:      'Doctorat',
};

const s = StyleSheet.create({
  page:       { fontFamily: 'Helvetica', fontSize: 10, color: '#1e293b', padding: '40 48' },
  cover:      { flex: 1, justifyContent: 'center', alignItems: 'center', gap: 12 },
  coverBrand: { fontSize: 28, fontFamily: 'Helvetica-Bold', color: '#1e3a8a', letterSpacing: 2 },
  coverTitle: { fontSize: 14, color: '#64748b', marginTop: 4 },
  coverSep:   { width: 60, height: 2, backgroundColor: '#1e3a8a', marginVertical: 16 },
  coverName:  { fontSize: 20, fontFamily: 'Helvetica-Bold', color: '#0f172a' },
  coverProg:  { fontSize: 13, color: '#1e40af', marginTop: 4 },
  coverUniv:  { fontSize: 11, color: '#64748b' },
  coverDate:  { fontSize: 9, color: '#94a3b8', marginTop: 20 },

  section:    { marginBottom: 20 },
  sLabel:     { fontSize: 8, fontFamily: 'Helvetica-Bold', letterSpacing: 1.5, color: '#94a3b8', textTransform: 'uppercase', marginBottom: 8 },
  sLine:      { height: 1, backgroundColor: '#e2e8f0', marginBottom: 12 },

  row:        { flexDirection: 'row', gap: 8, marginBottom: 5 },
  rowLabel:   { width: 130, fontSize: 9, color: '#64748b' },
  rowValue:   { flex: 1, fontSize: 10, fontFamily: 'Helvetica-Bold', color: '#0f172a' },

  badge:      { paddingHorizontal: 8, paddingVertical: 3, borderRadius: 10, fontSize: 9, fontFamily: 'Helvetica-Bold' },

  scoreBar:   { height: 6, borderRadius: 3, backgroundColor: '#e2e8f0', marginTop: 4 },
  scoreFill:  { height: 6, borderRadius: 3 },

  histRow:    { flexDirection: 'row', gap: 10, marginBottom: 8 },
  histDot:    { width: 7, height: 7, borderRadius: 4, backgroundColor: '#1e40af', marginTop: 2 },
  histText:   { flex: 1 },
  histStatus: { fontSize: 10, fontFamily: 'Helvetica-Bold', color: '#0f172a' },
  histDate:   { fontSize: 8, color: '#94a3b8' },
  histNote:   { fontSize: 9, color: '#64748b', fontStyle: 'italic', marginTop: 2 },

  noteBox:    { backgroundColor: '#f8fafc', borderRadius: 6, padding: '10 12', fontSize: 9.5, color: '#475569', lineHeight: 1.5 },

  footer:     { position: 'absolute', bottom: 24, left: 48, right: 48, flexDirection: 'row', justifyContent: 'space-between' },
  footerText: { fontSize: 7.5, color: '#cbd5e1' },
});

function scoreColor(score: number) {
  if (score >= 80) return '#16a34a';
  if (score >= 65) return '#d97706';
  return '#dc2626';
}

interface Props {
  app:     Application;
  history: StatusHistoryEntry[];
}

export default function ApplicationPDF({ app, history }: Props) {
  const generatedAt = new Date().toLocaleDateString('fr-FR', {
    day: '2-digit', month: 'long', year: 'numeric',
  });

  return (
    <Document title={`Dossier — ${app.student}`} author="Studium">

      {/* Page de couverture */}
      <Page size="A4" style={s.page}>
        <View style={s.cover}>
          <Text style={s.coverBrand}>STUDIUM</Text>
          <Text style={s.coverTitle}>Pack de candidature</Text>
          <View style={s.coverSep} />
          <Text style={s.coverName}>{app.student}</Text>
          <Text style={s.coverProg}>{app.program}</Text>
          <Text style={s.coverUniv}>{app.university}{app.country ? ` — ${app.country}` : ''}</Text>
          {app.level && <Text style={{ ...s.coverDate, marginTop: 8, fontSize: 10, color: '#64748b' }}>{LEVEL_LABELS[app.level] ?? app.level}</Text>}
          <Text style={s.coverDate}>Généré le {generatedAt}</Text>
        </View>

        <View style={s.footer}>
          <Text style={s.footerText}>Studium — Plateforme de gestion des candidatures</Text>
          <Text style={s.footerText}>Confidentiel</Text>
        </View>
      </Page>

      {/* Page détails */}
      <Page size="A4" style={s.page}>

        {/* Résumé candidature */}
        <View style={s.section}>
          <Text style={s.sLabel}>Résumé de la candidature</Text>
          <View style={s.sLine} />
          <View style={s.row}><Text style={s.rowLabel}>Étudiant</Text><Text style={s.rowValue}>{app.student}</Text></View>
          <View style={s.row}><Text style={s.rowLabel}>Programme</Text><Text style={s.rowValue}>{app.program}</Text></View>
          <View style={s.row}><Text style={s.rowLabel}>Université</Text><Text style={s.rowValue}>{app.university}</Text></View>
          <View style={s.row}><Text style={s.rowLabel}>Pays</Text><Text style={s.rowValue}>{app.country || '—'}</Text></View>
          <View style={s.row}><Text style={s.rowLabel}>Niveau</Text><Text style={s.rowValue}>{(LEVEL_LABELS[app.level] ?? app.level) || '—'}</Text></View>
          <View style={s.row}>
            <Text style={s.rowLabel}>Date de soumission</Text>
            <Text style={s.rowValue}>
              {app.date ? new Date(app.date).toLocaleDateString('fr-FR') : '—'}
            </Text>
          </View>
          <View style={s.row}>
            <Text style={s.rowLabel}>Statut</Text>
            <Text style={{ ...s.rowValue, color: '#1e40af' }}>{RAW_STATUS_LABELS[app.rawStatus as RawStatus] ?? app.rawStatus}</Text>
          </View>
        </View>

        {/* Score profil */}
        <View style={s.section}>
          <Text style={s.sLabel}>Score du dossier</Text>
          <View style={s.sLine} />
          <View style={s.row}>
            <Text style={s.rowLabel}>Complétude profil</Text>
            <Text style={{ ...s.rowValue, color: scoreColor(app.score) }}>{app.score}%</Text>
          </View>
          <View style={s.scoreBar}>
            <View style={{ ...s.scoreFill, width: `${app.score}%`, backgroundColor: scoreColor(app.score) }} />
          </View>
        </View>

        {/* Historique des statuts */}
        {history.length > 0 && (
          <View style={s.section}>
            <Text style={s.sLabel}>Historique des statuts</Text>
            <View style={s.sLine} />
            {history.map(entry => (
              <View key={entry.id} style={s.histRow}>
                <View style={s.histDot} />
                <View style={s.histText}>
                  <Text style={s.histStatus}>
                    {entry.fromStatus ? `${RAW_STATUS_LABELS[entry.fromStatus as RawStatus] ?? entry.fromStatus} → ` : ''}
                    {RAW_STATUS_LABELS[entry.toStatus as RawStatus] ?? entry.toStatus}
                  </Text>
                  {entry.createdAt && (
                    <Text style={s.histDate}>
                      {new Date(entry.createdAt).toLocaleDateString('fr-FR')}
                    </Text>
                  )}
                  {entry.note && <Text style={s.histNote}>{entry.note}</Text>}
                </View>
              </View>
            ))}
          </View>
        )}

        {/* Notes internes */}
        {app.notes && (
          <View style={s.section}>
            <Text style={s.sLabel}>Notes internes (équipe)</Text>
            <View style={s.sLine} />
            <View style={s.noteBox}>
              <Text>{app.notes}</Text>
            </View>
          </View>
        )}

        <View style={s.footer}>
          <Text style={s.footerText}>Studium — {app.student} / {app.program}</Text>
          <Text style={s.footerText} render={({ pageNumber, totalPages }) => `${pageNumber} / ${totalPages}`} />
        </View>
      </Page>
    </Document>
  );
}
