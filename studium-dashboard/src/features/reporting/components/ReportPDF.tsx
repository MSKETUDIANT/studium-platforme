import { Document, Page, Text, View, StyleSheet } from '@react-pdf/renderer';
import type { KPISummary, MonthlyCount, TopItem } from '../services/reporting_service';

const s = StyleSheet.create({
  page:       { fontFamily: 'Helvetica', fontSize: 10, color: '#1e293b', padding: '40 48', position: 'relative' },

  /* Cover */
  cover:      { flex: 1, justifyContent: 'center', alignItems: 'center' },
  brand:      { fontSize: 32, fontFamily: 'Helvetica-Bold', color: '#1e3a8a', letterSpacing: 3 },
  brandSub:   { fontSize: 11, color: '#64748b', marginTop: 4, letterSpacing: 1 },
  sep:        { width: 60, height: 2, backgroundColor: '#1e3a8a', marginVertical: 18 },
  coverTitle: { fontSize: 18, fontFamily: 'Helvetica-Bold', color: '#0f172a' },
  coverMonth: { fontSize: 12, color: '#1e40af', marginTop: 6 },
  genDate:    { fontSize: 8.5, color: '#94a3b8', marginTop: 28 },

  /* Section */
  section:    { marginBottom: 22 },
  sLabel:     { fontSize: 8, fontFamily: 'Helvetica-Bold', letterSpacing: 1.5, color: '#94a3b8', textTransform: 'uppercase', marginBottom: 6 },
  sLine:      { height: 1, backgroundColor: '#e2e8f0', marginBottom: 12 },

  /* KPI grid */
  kpiGrid:    { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  kpiCard:    { width: '30%', backgroundColor: '#f8fafc', borderRadius: 6, padding: '10 12', borderLeft: '3 solid #1e3a8a' },
  kpiValue:   { fontSize: 22, fontFamily: 'Helvetica-Bold', color: '#0f172a' },
  kpiLabel:   { fontSize: 8, color: '#64748b', marginTop: 3 },

  /* Table */
  tableHead:  { flexDirection: 'row', backgroundColor: '#f1f5f9', borderRadius: 4, padding: '6 10', marginBottom: 2 },
  tableRow:   { flexDirection: 'row', padding: '6 10', borderBottom: '1 solid #e2e8f0' },
  tableCell:  { flex: 1, fontSize: 9.5 },
  tableCellB: { flex: 1, fontSize: 9.5, fontFamily: 'Helvetica-Bold' },
  tableNum:   { width: 50, fontSize: 9.5, textAlign: 'right' },
  tableNumB:  { width: 50, fontSize: 9.5, fontFamily: 'Helvetica-Bold', textAlign: 'right', color: '#1e40af' },

  /* Bar */
  barRow:     { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 5 },
  barLabel:   { width: 160, fontSize: 9, color: '#475569' },
  barBg:      { flex: 1, height: 8, backgroundColor: '#e2e8f0', borderRadius: 4 },
  barFill:    { height: 8, borderRadius: 4, backgroundColor: '#1e3a8a' },
  barCount:   { width: 28, fontSize: 9, color: '#64748b', textAlign: 'right' },

  /* Rate badge */
  rateBadge:  { padding: '6 14', borderRadius: 6, backgroundColor: '#eff6ff', alignSelf: 'flex-start', marginTop: 4 },
  rateValue:  { fontSize: 28, fontFamily: 'Helvetica-Bold', color: '#1e40af' },
  rateSub:    { fontSize: 9, color: '#64748b', marginTop: 2 },

  /* Footer */
  footer:     { position: 'absolute', bottom: 24, left: 48, right: 48, flexDirection: 'row', justifyContent: 'space-between' },
  footerText: { fontSize: 7.5, color: '#cbd5e1' },
});

interface Props {
  kpi:       KPISummary;
  monthly:   MonthlyCount[];
  countries: TopItem[];
  programs:  TopItem[];
}

function Section({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <View style={s.section}>
      <Text style={s.sLabel}>{label}</Text>
      <View style={s.sLine} />
      {children}
    </View>
  );
}

function Footer({ page }: { page: number }) {
  const now = new Date().toLocaleDateString('fr-FR', { day: '2-digit', month: 'long', year: 'numeric' });
  return (
    <View style={s.footer} fixed>
      <Text style={s.footerText}>Studium — Rapport confidentiel</Text>
      <Text style={s.footerText}>Genere le {now} — Page {page}</Text>
    </View>
  );
}

export default function ReportPDF({ kpi, monthly, countries, programs }: Props) {
  const now        = new Date();
  const monthLabel = now.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
  const genDate    = now.toLocaleDateString('fr-FR', { day: '2-digit', month: 'long', year: 'numeric' });
  const validRate  = kpi.totalApplications > 0
    ? Math.round(((kpi.verified + kpi.sent + kpi.accepted) / kpi.totalApplications) * 100)
    : 0;
  const maxMonthly = Math.max(...monthly.map(m => m.count), 1);
  const maxCountry = Math.max(...countries.map(c => c.count), 1);
  const maxProg    = Math.max(...programs.map(p => p.count), 1);

  const kpiCards = [
    { label: 'Total candidatures',    value: kpi.totalApplications },
    { label: 'En attente',            value: kpi.pendingReview },
    { label: 'Envoyees',              value: kpi.sent },
    { label: 'Acceptees',             value: kpi.accepted },
    { label: 'Correction requise',    value: kpi.needsFix },
    { label: 'Refusees / Archivees',  value: kpi.rejected },
  ];

  return (
    <Document title={`Rapport Studium — ${monthLabel}`} author="Studium">

      {/* Page 1 — Couverture + KPIs */}
      <Page size="A4" style={s.page}>
        {/* Couverture */}
        <View style={s.cover}>
          <Text style={s.brand}>STUDIUM</Text>
          <Text style={s.brandSub}>Plateforme de gestion des candidatures</Text>
          <View style={s.sep} />
          <Text style={s.coverTitle}>Rapport Mensuel</Text>
          <Text style={s.coverMonth}>{monthLabel.charAt(0).toUpperCase() + monthLabel.slice(1)}</Text>
          <Text style={s.genDate}>Genere le {genDate}</Text>
        </View>

        <Footer page={1} />
      </Page>

      {/* Page 2 — KPIs + Taux */}
      <Page size="A4" style={s.page}>
        <Section label="Resume des indicateurs cles">
          <View style={s.kpiGrid}>
            {kpiCards.map(c => (
              <View key={c.label} style={s.kpiCard}>
                <Text style={s.kpiValue}>{c.value}</Text>
                <Text style={s.kpiLabel}>{c.label}</Text>
              </View>
            ))}
          </View>
        </Section>

        <Section label="Taux de validation">
          <View style={s.rateBadge}>
            <Text style={s.rateValue}>{validRate}%</Text>
            <Text style={s.rateSub}>des candidatures verifiees, envoyees ou acceptees</Text>
          </View>
          <View style={{ marginTop: 10 }}>
            <View style={s.tableHead}>
              <Text style={s.tableCellB}>Statut</Text>
              <Text style={s.tableNumB}>Nombre</Text>
            </View>
            {[
              { label: 'Verifiees',        v: kpi.verified  },
              { label: 'Envoyees',         v: kpi.sent      },
              { label: 'Acceptees',        v: kpi.accepted  },
              { label: 'Correction req.',  v: kpi.needsFix  },
              { label: 'Refusees/Archiv.', v: kpi.rejected  },
            ].map(r => (
              <View key={r.label} style={s.tableRow}>
                <Text style={s.tableCell}>{r.label}</Text>
                <Text style={s.tableNum}>{r.v}</Text>
              </View>
            ))}
          </View>
        </Section>

        <Section label="Taux d'acceptation et delai de validation">
          <View style={{ flexDirection: 'row', gap: 12 }}>
            <View style={{ ...s.rateBadge, flex: 1 }}>
              <Text style={s.rateValue}>{kpi.acceptanceRate}%</Text>
              <Text style={s.rateSub}>acceptees parmi les decisions rendues</Text>
            </View>
            <View style={{ ...s.rateBadge, flex: 1 }}>
              <Text style={s.rateValue}>{kpi.avgValidationDelayDays} j</Text>
              <Text style={s.rateSub}>delai moyen soumission {'->'} 1ere validation</Text>
            </View>
          </View>
        </Section>

        <Section label="Score moyen de completude profil">
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}>
            <View style={{ flex: 1, height: 10, backgroundColor: '#e2e8f0', borderRadius: 5 }}>
              <View style={{ width: `${kpi.avgCompletenessScore}%`, height: 10, backgroundColor: '#16a34a', borderRadius: 5 }} />
            </View>
            <Text style={{ fontSize: 14, fontFamily: 'Helvetica-Bold', color: '#16a34a', width: 45 }}>
              {kpi.avgCompletenessScore}%
            </Text>
          </View>
        </Section>

        <Footer page={2} />
      </Page>

      {/* Page 3 — Mensuel + Top pays + Top programmes */}
      <Page size="A4" style={s.page}>
        {monthly.length > 0 && (
          <Section label="Evolution mensuelle (6 derniers mois)">
            {monthly.map(m => (
              <View key={m.month} style={s.barRow}>
                <Text style={s.barLabel}>{m.month}</Text>
                <View style={s.barBg}>
                  <View style={{ ...s.barFill, width: `${Math.round((m.count / maxMonthly) * 100)}%` }} />
                </View>
                <Text style={s.barCount}>{m.count}</Text>
              </View>
            ))}
          </Section>
        )}

        {countries.length > 0 && (
          <Section label="Top destinations">
            <View style={s.tableHead}>
              <Text style={s.tableCellB}>Pays</Text>
              <Text style={{ flex: 2 }} />
              <Text style={s.tableNumB}>Candidatures</Text>
            </View>
            {countries.map((c, i) => (
              <View key={c.label} style={s.tableRow}>
                <Text style={s.tableCell}>{i + 1}. {c.label}</Text>
                <View style={{ flex: 2, paddingRight: 8 }}>
                  <View style={{ height: 6, backgroundColor: '#e2e8f0', borderRadius: 3 }}>
                    <View style={{ width: `${Math.round((c.count / maxCountry) * 100)}%`, height: 6, backgroundColor: '#0891b2', borderRadius: 3 }} />
                  </View>
                </View>
                <Text style={s.tableNum}>{c.count}</Text>
              </View>
            ))}
          </Section>
        )}

        {programs.length > 0 && (
          <Section label="Top programmes">
            <View style={s.tableHead}>
              <Text style={s.tableCellB}>Programme</Text>
              <Text style={{ flex: 2 }} />
              <Text style={s.tableNumB}>Candidatures</Text>
            </View>
            {programs.map((p, i) => (
              <View key={p.label} style={s.tableRow}>
                <Text style={{ ...s.tableCell, flex: 3 }}>{i + 1}. {p.label}</Text>
                <View style={{ flex: 2, paddingRight: 8 }}>
                  <View style={{ height: 6, backgroundColor: '#e2e8f0', borderRadius: 3 }}>
                    <View style={{ width: `${Math.round((p.count / maxProg) * 100)}%`, height: 6, backgroundColor: '#7c3aed', borderRadius: 3 }} />
                  </View>
                </View>
                <Text style={s.tableNum}>{p.count}</Text>
              </View>
            ))}
          </Section>
        )}

        <Footer page={3} />
      </Page>

    </Document>
  );
}
