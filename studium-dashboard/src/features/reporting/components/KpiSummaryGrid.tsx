import { colors } from '../../../shared/constants/theme';
import { StatCard } from '../../../shared/components/StatCard';
import type { KPISummary } from '../services/reporting_service';

const IconTotal    = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>;
const IconPending  = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>;
const IconSent     = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>;
const IconAccepted = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>;
const IconFix      = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>;
const IconRate     = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>;
const IconScore    = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><circle cx="12" cy="8" r="6"/><path d="M15.477 12.89L17 22l-5-3-5 3 1.523-9.11"/></svg>;
const IconTrophy   = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0V4z"/><path d="M17 5h3a2 2 0 0 1-2 4M7 5H4a2 2 0 0 0 2 4"/></svg>;
const IconClock    = () => <svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8} strokeLinecap="round"><circle cx="12" cy="13" r="8"/><path d="M12 9v4l2.5 2.5M9 2h6"/></svg>;

/** Cartes KPI réutilisées par /dashboard (vue d'ensemble) et /reporting (rapports détaillés) — évite de dupliquer les mêmes métriques dans deux pages. */
export default function KpiSummaryGrid({ kpi }: { kpi: KPISummary | null }) {
  const verifiedRate = kpi && kpi.totalApplications > 0
    ? Math.round(((kpi.verified + kpi.sent + kpi.accepted) / kpi.totalApplications) * 100) : 0;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      <style>{`
        @media (max-width: 900px) {
          .kpi-grid-4, .kpi-grid-3 { grid-template-columns: repeat(2, 1fr) !important; }
        }
        @media (max-width: 480px) {
          .kpi-grid-4, .kpi-grid-3, .kpi-grid-2 { grid-template-columns: 1fr !important; }
        }
      `}</style>
      <div className="kpi-grid-4" style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
        <StatCard
          icon={<IconTotal />}    iconBg="rgba(37,70,204,0.10)" iconColor={colors.blue} accent={colors.blue}
          label="Total candidatures" value={kpi?.totalApplications ?? 0}
          sub="Toutes périodes"
        />
        <StatCard
          icon={<IconPending />}  iconBg="rgba(217,119,6,0.10)" iconColor="#d97706" accent="#d97706"
          label="En attente" value={kpi?.pendingReview ?? 0}
          sub="Brouillons + soumises"
        />
        <StatCard
          icon={<IconSent />}     iconBg="rgba(37,70,204,0.10)" iconColor="#2546cc" accent="#0891b2"
          label="Envoyées" value={kpi?.sent ?? 0}
          sub="Aux universités"
        />
        <StatCard
          icon={<IconAccepted />} iconBg="rgba(22,163,74,0.10)" iconColor={colors.success} accent={colors.success}
          label="Acceptées" value={kpi?.accepted ?? 0}
          sub="Réponses positives"
        />
      </div>

      <div className="kpi-grid-3" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 }}>
        <StatCard
          icon={<IconFix />}   iconBg="rgba(220,38,38,0.10)" iconColor="#ef4444" accent="#ef4444"
          label="Corrections requises" value={kpi?.needsFix ?? 0}
          sub="Dossiers à compléter"
        />
        <StatCard
          icon={<IconRate />}  iconBg="rgba(11,24,82,0.08)" iconColor={colors.navy} accent={colors.navy}
          label="Taux de validation" value={`${verifiedRate}%`}
          sub="Vérifiées + envoyées + acceptées"
        />
        <StatCard
          icon={<IconScore />} iconBg="rgba(8,145,178,0.10)" iconColor="#0891b2" accent="#0891b2"
          label="Score profil moyen" value={`${kpi?.avgCompletenessScore ?? 0}%`}
          sub="Complétude moyenne des dossiers"
        />
      </div>

      <div className="kpi-grid-2" style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 16 }}>
        <StatCard
          icon={<IconTrophy />} iconBg="rgba(22,163,74,0.10)" iconColor={colors.success} accent={colors.success}
          label="Taux d'acceptation" value={`${kpi?.acceptanceRate ?? 0}%`}
          sub="Acceptées parmi les décisions rendues (acceptées + refusées)"
        />
        <StatCard
          icon={<IconClock />} iconBg="rgba(124,58,237,0.10)" iconColor={colors.violet} accent={colors.violet}
          label="Délai moyen de validation" value={`${kpi?.avgValidationDelayDays ?? 0} j`}
          sub="Entre soumission et 1ère validation"
        />
      </div>
    </div>
  );
}
