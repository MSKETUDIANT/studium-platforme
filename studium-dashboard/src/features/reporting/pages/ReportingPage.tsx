import React, { useState, useEffect } from 'react';
import { pdf } from '@react-pdf/renderer';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { PageHeader } from '../../../shared/components/PageHeader';
import { colors, fonts } from '../../../shared/constants/theme';
import {
  fetchKPISummary, fetchMonthlyApplications, fetchTopCountries, fetchTopPrograms, exportCSV,
} from '../services/reporting_service';
import type { KPISummary, MonthlyCount, TopItem } from '../services/reporting_service';
import { supabase } from '../../../shared/services/supabase';
import ReportPDF from '../components/ReportPDF';

/*  Icons  */
const IconTotal    = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>;
const IconPending  = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>;
const IconSent     = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>;
const IconAccepted = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>;
const IconFix      = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>;
const IconRate     = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>;
const IconScore    = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><circle cx="12" cy="8" r="6"/><path d="M15.477 12.89L17 22l-5-3-5 3 1.523-9.11"/></svg>;
const IconTrophy   = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0V4z"/><path d="M17 5h3a2 2 0 0 1-2 4M7 5H4a2 2 0 0 0 2 4"/></svg>;
const IconClock    = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><circle cx="12" cy="13" r="8"/><path d="M12 9v4l2.5 2.5M9 2h6"/></svg>;

export default function ReportingPage() {
  const [kpi,       setKpi]       = useState<KPISummary | null>(null);
  const [monthly,   setMonthly]   = useState<MonthlyCount[]>([]);
  const [countries, setCountries] = useState<TopItem[]>([]);
  const [programs,  setPrograms]  = useState<TopItem[]>([]);
  const [loading,      setLoading]      = useState(true);
  const [exporting,    setExporting]    = useState(false);
  const [exportingPdf, setExportingPdf] = useState(false);

  useEffect(() => {
    Promise.all([
      fetchKPISummary(),
      fetchMonthlyApplications(),
      fetchTopCountries(),
      fetchTopPrograms(),
    ]).then(([k, m, c, p]) => {
      setKpi(k); setMonthly(m); setCountries(c); setPrograms(p);
    }).finally(() => setLoading(false));
  }, []);

  async function handleExportPdf() {
    if (!kpi) return;
    setExportingPdf(true);
    try {
      const blob = await pdf(
        <ReportPDF kpi={kpi} monthly={monthly} countries={countries} programs={programs} />
      ).toBlob();
      const url  = URL.createObjectURL(blob);
      const a    = document.createElement('a');
      const month = new Date().toLocaleDateString('fr-FR', { month: '2-digit', year: 'numeric' }).replace('/', '-');
      a.href     = url;
      a.download = `studium_rapport_${month}.pdf`;
      a.click();
      URL.revokeObjectURL(url);
    } finally {
      setExportingPdf(false);
    }
  }

  async function handleExportApplications() {
    setExporting(true);
    try {
      const { data } = await supabase
        .from('applications')
        .select(`id, status, submitted_at, notes, student_profiles!student_profile_id(first_name, last_name, nationality), programs!program_id(program_name, university_name, country)`)
        .order('submitted_at', { ascending: false });
      const rows = (data ?? []).map((a: any) => ({
        'ID':          a.id,
        'Etudiant':    `${a.student_profiles?.first_name ?? ''} ${a.student_profiles?.last_name ?? ''}`.trim(),
        'Nationalite': a.student_profiles?.nationality ?? '',
        'Programme':   a.programs?.program_name    ?? '',
        'Universite':  a.programs?.university_name ?? '',
        'Pays':        a.programs?.country         ?? '',
        'Statut':      a.status,
        'Soumis le':   a.submitted_at ? new Date(a.submitted_at).toLocaleDateString('fr-FR') : '',
      }));
      exportCSV(rows, `studium_candidatures_${new Date().toISOString().slice(0, 10)}.csv`);
    } finally { setExporting(false); }
  }

  const verifiedRate = kpi && kpi.totalApplications > 0
    ? Math.round(((kpi.verified + kpi.sent + kpi.accepted) / kpi.totalApplications) * 100) : 0;

  return (
    <div style={{ fontFamily: fonts.body }}>
      <PageHeader
        title="Rapports"
        subtitle="KPIs et statistiques de la plateforme"
        actions={
          <div style={{ display: 'flex', gap: 8 }}>
            <button
              onClick={handleExportPdf}
              disabled={exportingPdf || loading || !kpi}
              style={{
                padding: '9px 18px', borderRadius: 9, border: `1.5px solid rgba(255,255,255,.35)`,
                background: 'rgba(255,255,255,.15)', color: 'white', backdropFilter: 'blur(4px)',
                fontWeight: 600, fontSize: 13, cursor: 'pointer', fontFamily: fonts.body,
                display: 'flex', alignItems: 'center', gap: 7, opacity: (exportingPdf || loading || !kpi) ? 0.5 : 1,
              }}
            >
              <svg width={14} height={14} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/>
                <line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/>
              </svg>
              {exportingPdf ? 'Generation...' : 'Exporter PDF'}
            </button>
            <button
              onClick={handleExportApplications}
              disabled={exporting}
              style={{
                padding: '9px 18px', borderRadius: 9, border: `1.5px solid rgba(255,255,255,.35)`,
                background: 'rgba(255,255,255,.15)', color: 'white', backdropFilter: 'blur(4px)',
                fontWeight: 600, fontSize: 13, cursor: 'pointer', fontFamily: fonts.body,
                display: 'flex', alignItems: 'center', gap: 7, opacity: exporting ? 0.7 : 1,
              }}
            >
              <svg width={14} height={14} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/>
              </svg>
              {exporting ? 'Export...' : 'Exporter CSV'}
            </button>
          </div>
        }
      />

      <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
        {loading ? (
          <div style={{ textAlign: 'center', padding: '80px 0', color: colors.textMuted, fontSize: 14 }}>
            Chargement des donnees...
          </div>
        ) : (
          <>
            {/* Ligne 1  4 KPIs principaux */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
              <MetricCard
                icon={<IconTotal />}    iconBg="rgba(37,70,204,0.10)" iconColor={colors.blue} accent={colors.blue}
                label="Total candidatures" value={kpi?.totalApplications ?? 0}
                sub="Toutes périodes"
              />
              <MetricCard
                icon={<IconPending />}  iconBg="rgba(217,119,6,0.10)" iconColor="#d97706" accent="#d97706"
                label="En attente" value={kpi?.pendingReview ?? 0}
                sub="Brouillons + soumises"
              />
              <MetricCard
                icon={<IconSent />}     iconBg="rgba(37,70,204,0.10)" iconColor="#2546cc" accent="#0891b2"
                label="Envoyées" value={kpi?.sent ?? 0}
                sub="Aux universités"
              />
              <MetricCard
                icon={<IconAccepted />} iconBg="rgba(22,163,74,0.10)" iconColor={colors.success} accent={colors.success}
                label="Acceptées" value={kpi?.accepted ?? 0}
                sub="Réponses positives"
              />
            </div>

            {/* Ligne 2 — 3 métriques secondaires */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 }}>
              <MetricCard
                icon={<IconFix />}   iconBg="rgba(220,38,38,0.10)" iconColor="#ef4444" accent="#ef4444"
                label="Corrections requises" value={kpi?.needsFix ?? 0}
                sub="Dossiers à compléter"
              />
              <MetricCard
                icon={<IconRate />}  iconBg="rgba(11,24,82,0.08)" iconColor={colors.navy} accent={colors.navy}
                label="Taux de validation" value={`${verifiedRate}%`}
                sub="Vérifiées + envoyées + acceptées"
              />
              <MetricCard
                icon={<IconScore />} iconBg="rgba(8,145,178,0.10)" iconColor="#0891b2" accent="#0891b2"
                label="Score profil moyen" value={`${kpi?.avgCompletenessScore ?? 0}%`}
                sub="Complétude moyenne des dossiers"
              />
            </div>

            {/* Ligne 2bis — taux d'acceptation & délai de validation */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 16 }}>
              <MetricCard
                icon={<IconTrophy />} iconBg="rgba(22,163,74,0.10)" iconColor={colors.success} accent={colors.success}
                label="Taux d'acceptation" value={`${kpi?.acceptanceRate ?? 0}%`}
                sub="Acceptées parmi les décisions rendues (acceptées + refusées)"
              />
              <MetricCard
                icon={<IconClock />} iconBg="rgba(124,58,237,0.10)" iconColor="#7c3aed" accent="#7c3aed"
                label="Délai moyen de validation" value={`${kpi?.avgValidationDelayDays ?? 0} j`}
                sub="Entre soumission et 1ère validation"
              />
            </div>

            {/* Ligne 3  Graphiques */}
            <div style={{ display: 'grid', gridTemplateColumns: '3fr 2fr', gap: 20 }}>
              <Panel title="Candidatures par mois">
                {monthly.length === 0 ? <Empty /> : (
                  <ResponsiveContainer width="100%" height={220}>
                    <BarChart data={monthly} margin={{ top: 4, right: 8, left: -20, bottom: 0 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                      <XAxis dataKey="month" tick={{ fontSize: 11.5, fill: colors.textMuted }} axisLine={false} tickLine={false} />
                      <YAxis tick={{ fontSize: 11, fill: colors.textMuted }} axisLine={false} tickLine={false} allowDecimals={false} />
                      <Tooltip
                        contentStyle={{ borderRadius: 10, fontSize: 12.5, border: 'none', boxShadow: '0 4px 20px rgba(0,0,0,.1)' }}
                        cursor={{ fill: '#f0f4ff' }}
                      />
                      <Bar dataKey="count" name="Candidatures" radius={[6, 6, 0, 0]} fill={colors.blue} maxBarSize={48} />
                    </BarChart>
                  </ResponsiveContainer>
                )}
              </Panel>

              <Panel title="Repartition par statut">
                {kpi && kpi.totalApplications > 0 ? (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 12, paddingTop: 4 }}>
                    {[
                      { label: 'Soumises',   value: kpi.pendingReview, color: '#d97706' },
                      { label: 'A corriger', value: kpi.needsFix,      color: '#ef4444' },
                      { label: 'Verifiees',  value: kpi.verified,      color: '#7c3aed' },
                      { label: 'Envoyees',   value: kpi.sent,          color: colors.blue },
                      { label: 'Acceptees',  value: kpi.accepted,      color: colors.success },
                      { label: 'Refusees',   value: kpi.rejected,      color: '#9ca3af' },
                    ].filter(s => s.value > 0).map(s => (
                      <StatusBar key={s.label} label={s.label} value={s.value} total={kpi.totalApplications} color={s.color} />
                    ))}
                  </div>
                ) : <Empty />}
              </Panel>
            </div>

            {/* Ligne 4  Top listes */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
              <Panel title="Top pays de destination">
                {countries.length === 0 ? <Empty /> : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                    {countries.map((c, i) => (
                      <RankItem key={c.label} rank={i + 1} label={c.label} count={c.count} max={countries[0].count} />
                    ))}
                  </div>
                )}
              </Panel>
              <Panel title="Top programmes">
                {programs.length === 0 ? <Empty /> : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                    {programs.map((p, i) => (
                      <RankItem key={p.label} rank={i + 1} label={p.label} count={p.count} max={programs[0].count} />
                    ))}
                  </div>
                )}
              </Panel>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

/*  Components  */

const CARD_SHADOW = '0 1px 4px rgba(11,24,82,0.04), 0 8px 24px rgba(11,24,82,0.07), 0 28px 60px rgba(11,24,82,0.08)';

function MetricCard({ icon, iconBg, iconColor, label, value, sub, accent }: {
  icon: React.ReactNode; iconBg: string; iconColor: string;
  label: string; value: number | string; sub: string; accent?: string;
}) {
  return (
    <div style={{
      background: 'white', borderRadius: 14, padding: '18px 20px',
      boxShadow: CARD_SHADOW,
      display: 'flex', alignItems: 'center', gap: 16,
      borderLeft: accent ? `4px solid ${accent}` : undefined,
    }}>
      <div style={{
        width: 44, height: 44, borderRadius: 12, flexShrink: 0,
        background: iconBg, color: iconColor,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {icon}
      </div>
      <div>
        <div style={{ fontSize: 28, fontWeight: 800, color: colors.navy, lineHeight: 1, fontFamily: fonts.display }}>
          {value}
        </div>
        <div style={{ fontSize: 12, color: colors.textMuted, marginTop: 5, fontWeight: 500 }}>{label}</div>
        {sub && <div style={{ fontSize: 11, color: colors.textMuted, marginTop: 2 }}>{sub}</div>}
      </div>
    </div>
  );
}

function Panel({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div style={{
      background: 'white', borderRadius: 14, padding: '22px 24px',
      boxShadow: CARD_SHADOW,
    }}>
      <div style={{ fontSize: 14, fontWeight: 700, color: colors.navy, marginBottom: 18, fontFamily: fonts.display }}>{title}</div>
      {children}
    </div>
  );
}

function StatusBar({ label, value, total, color }: { label: string; value: number; total: number; color: string }) {
  const pct = Math.round((value / total) * 100);
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 5 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
          <div style={{ width: 8, height: 8, borderRadius: '50%', background: color, flexShrink: 0 }} />
          <span style={{ fontSize: 13, color: '#374151' }}>{label}</span>
        </div>
        <span style={{ fontSize: 13, fontWeight: 700, color: '#0f172a' }}>
          {value} <span style={{ fontSize: 11, fontWeight: 400, color: colors.textMuted }}>({pct}%)</span>
        </span>
      </div>
      <div style={{ height: 5, borderRadius: 3, background: '#f1f5f9' }}>
        <div style={{ height: 5, borderRadius: 3, width: `${pct}%`, background: color, transition: 'width .5s ease' }} />
      </div>
    </div>
  );
}

function RankItem({ rank, label, count, max }: { rank: number; label: string; count: number; max: number }) {
  const pct        = Math.round((count / max) * 100);
  const medalBg    = rank === 1 ? '#fbbf24' : rank === 2 ? '#9ca3af' : rank === 3 ? '#cd7c3b' : colors.inputBg;
  const medalColor = rank <= 3 ? 'white' : colors.textMuted;
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
      <div style={{
        width: 24, height: 24, borderRadius: '50%', flexShrink: 0,
        background: medalBg, color: medalColor,
        fontSize: 11, fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {rank}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, color: '#374151', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', marginBottom: 4 }}>
          {label}
        </div>
        <div style={{ height: 4, borderRadius: 2, background: '#f1f5f9' }}>
          <div style={{ height: 4, borderRadius: 2, width: `${pct}%`, background: `${colors.blue}80`, transition: 'width .5s ease' }} />
        </div>
      </div>
      <span style={{ fontSize: 13, fontWeight: 700, color: colors.blue, flexShrink: 0, minWidth: 20, textAlign: 'right' }}>{count}</span>
    </div>
  );
}

function Empty() {
  return (
    <div style={{ textAlign: 'center', padding: '28px 0', fontSize: 13, color: colors.textMuted }}>
      Aucune donnee disponible
    </div>
  );
}
