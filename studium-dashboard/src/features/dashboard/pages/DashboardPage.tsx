import { useState, useEffect } from 'react';
import { PageHeader } from '../../../shared/components/PageHeader';
import { colors, fonts } from '../../../shared/constants/theme';
import { fetchKPISummary } from '../../reporting/services/reporting_service';
import type { KPISummary } from '../../reporting/services/reporting_service';
import KpiSummaryGrid from '../../reporting/components/KpiSummaryGrid';

export default function DashboardPage() {
  const [kpi, setKpi] = useState<KPISummary | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchKPISummary().then(setKpi).finally(() => setLoading(false));
  }, []);

  return (
    <div style={{ fontFamily: fonts.body }}>
      <PageHeader title="Tableau de bord" subtitle="Vue d'ensemble en un coup d'œil" />

      {loading ? (
        <div style={{ textAlign: 'center', padding: '80px 0', color: colors.textMuted, fontSize: 14 }}>
          Chargement des donnees...
        </div>
      ) : (
        <KpiSummaryGrid kpi={kpi} />
      )}
    </div>
  );
}
