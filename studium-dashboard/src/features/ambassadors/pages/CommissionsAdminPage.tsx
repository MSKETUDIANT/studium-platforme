import { useEffect, useState, useCallback } from 'react';
import { colors, fonts, radius, shadows } from '../../../shared/constants/theme';
import { PageHeader } from '../../../shared/components/PageHeader';
import { getAllCommissions, updateCommissionStatus } from '../services/ambassadors_service';
import { COMMISSION_STATUS_LABELS } from '../types/ambassador';
import type { Commission, RawCommissionStatus } from '../types/ambassador';

const CSS = `
  .cma-root { animation: cma-fade-up .25s ease; }
  @keyframes cma-fade-up { from{opacity:0;transform:translateY(8px)} to{opacity:1;transform:none} }

  .cma-table-wrap { background: white; border-radius: ${radius.lg}px; box-shadow: ${shadows.card}; overflow: hidden; }
  .cma-table { width: 100%; border-collapse: collapse; }
  .cma-table thead tr { background: linear-gradient(135deg, #f8faff 0%, ${colors.inputBg} 100%); border-bottom: 2px solid ${colors.border}; }
  .cma-table th { padding: 12px 20px; text-align: left; font-size: 11px; font-weight: 700; color: ${colors.textSecondary}; text-transform: uppercase; letter-spacing: .6px; }
  .cma-table td { padding: 13px 20px; border-bottom: 1px solid ${colors.border}; font-size: 13px; color: ${colors.textPrimary}; vertical-align: middle; }
  .cma-table tbody tr:last-child td { border-bottom: none; }

  .cma-badge { display: inline-flex; align-items: center; padding: 3px 9px; border-radius: 20px; font-size: 11px; font-weight: 700; white-space: nowrap; }
  .cma-status-pending { background: #eff6ff; color: #2563eb; }
  .cma-status-payable { background: #fffbeb; color: #d97706; }
  .cma-status-paid    { background: #f0fdf4; color: #16a34a; }

  .cma-select {
    height: 32px; padding: 0 10px; border-radius: ${radius.sm}px;
    border: 1.5px solid ${colors.borderInput}; font-size: 12.5px; font-family: ${fonts.body};
    color: ${colors.textPrimary}; background: white; cursor: pointer; outline: none;
  }
  .cma-select:focus { border-color: ${colors.blue}; }

  .cma-empty { text-align: center; padding: 48px 20px; font-size: 13px; color: ${colors.textSecondary}; }
`;

if (typeof document !== 'undefined' && !document.getElementById('cma-css')) {
  const s = document.createElement('style');
  s.id = 'cma-css';
  s.textContent = CSS;
  document.head.appendChild(s);
}

const NEXT_STATUS: Record<RawCommissionStatus, RawCommissionStatus[]> = {
  pending: ['pending', 'payable'],
  payable: ['payable', 'paid'],
  paid:    ['paid'],
};

export default function CommissionsAdminPage() {
  const [commissions, setCommissions] = useState<Commission[]>([]);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setCommissions(await getAllCommissions());
    setLoading(false);
  }, []);

  useEffect(() => { load(); }, [load]);

  async function handleStatusChange(commission: Commission, status: RawCommissionStatus) {
    if (status === commission.status) return;
    setUpdating(commission.id);
    try {
      await updateCommissionStatus(commission.id, status);
      await load();
    } finally {
      setUpdating(null);
    }
  }

  return (
    <div className="cma-root">
      <PageHeader title="Commissions ambassadeurs" subtitle={`${commissions.length} commission${commissions.length !== 1 ? 's' : ''}`} />

      <div className="cma-table-wrap">
        {loading ? (
          <div className="cma-empty">Chargement</div>
        ) : commissions.length === 0 ? (
          <div className="cma-empty">Aucune commission enregistrée.</div>
        ) : (
          <table className="cma-table">
            <thead>
              <tr><th>Ambassadeur</th><th>Période</th><th>Montant</th><th>Statut</th></tr>
            </thead>
            <tbody>
              {commissions.map(c => (
                <tr key={c.id}>
                  <td>{c.ambassadorName}</td>
                  <td>{c.periodStart ? new Date(c.periodStart).toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' }) : '—'}</td>
                  <td>{c.amount}</td>
                  <td>
                    <select
                      className="cma-select"
                      value={c.status}
                      disabled={updating === c.id || c.status === 'paid'}
                      onChange={e => handleStatusChange(c, e.target.value as RawCommissionStatus)}
                    >
                      {NEXT_STATUS[c.status].map(s => (
                        <option key={s} value={s}>{COMMISSION_STATUS_LABELS[s]}</option>
                      ))}
                    </select>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
