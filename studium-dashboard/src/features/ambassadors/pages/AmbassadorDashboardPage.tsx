import { useEffect, useState, useCallback } from 'react';
import { colors, fonts, radius, shadows } from '../../../shared/constants/theme';
import { PageHeader } from '../../../shared/components/PageHeader';
import {
  getMyReferrals, getMyCommissions, getMyReferralCode, requestPayout,
} from '../services/ambassadors_service';
import { REFERRAL_STATUS_LABELS, COMMISSION_STATUS_LABELS } from '../types/ambassador';
import type { Referral, Commission } from '../types/ambassador';

const CSS = `
  .amb-root { animation: amb-fade-up .25s ease; }
  @keyframes amb-fade-up { from{opacity:0;transform:translateY(8px)} to{opacity:1;transform:none} }

  .amb-link-card {
    background: white; border-radius: ${radius.lg}px; box-shadow: ${shadows.card};
    padding: 20px 22px; margin-bottom: 20px;
    display: flex; align-items: center; justify-content: space-between; gap: 16px; flex-wrap: wrap;
  }
  .amb-link-label { font-size: 12px; color: ${colors.textSecondary}; margin-bottom: 6px; }
  .amb-link-value {
    font-family: monospace; font-size: 13px; color: ${colors.textPrimary};
    background: ${colors.inputBg}; padding: 8px 12px; border-radius: ${radius.md}px;
    max-width: 420px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  }
  .amb-copy-btn {
    height: 38px; padding: 0 18px; border-radius: ${radius.md}px; border: none;
    background: ${colors.navy}; color: white; font-weight: 700; font-size: 13px;
    cursor: pointer; font-family: ${fonts.body}; transition: background .15s;
  }
  .amb-copy-btn:hover { background: ${colors.blue}; }

  .amb-section-title {
    font-family: ${fonts.display}; font-weight: 800; font-size: 15px;
    color: ${colors.textPrimary}; margin: 0 0 12px;
  }
  .amb-table-wrap {
    background: white; border-radius: ${radius.lg}px; box-shadow: ${shadows.card};
    overflow: hidden; margin-bottom: 24px;
  }
  .amb-table { width: 100%; border-collapse: collapse; }
  .amb-table thead tr { background: linear-gradient(135deg, #f8faff 0%, ${colors.inputBg} 100%); border-bottom: 2px solid ${colors.border}; }
  .amb-table th { padding: 12px 20px; text-align: left; font-size: 11px; font-weight: 700; color: ${colors.textSecondary}; text-transform: uppercase; letter-spacing: .6px; }
  .amb-table td { padding: 13px 20px; border-bottom: 1px solid ${colors.border}; font-size: 13px; color: ${colors.textPrimary}; }
  .amb-table tbody tr:last-child td { border-bottom: none; }

  .amb-badge { display: inline-flex; align-items: center; padding: 3px 9px; border-radius: 20px; font-size: 11px; font-weight: 700; white-space: nowrap; }
  .amb-status-registered, .amb-status-pending { background: #eff6ff; color: #2563eb; }
  .amb-status-converted, .amb-status-paid     { background: #f0fdf4; color: #16a34a; }
  .amb-status-clicked                          { background: #f3f4f6; color: #6b7280; }
  .amb-status-payable                          { background: #fffbeb; color: #d97706; }

  .amb-payout-btn {
    height: 30px; padding: 0 12px; border-radius: ${radius.sm}px; border: 1.5px solid ${colors.blue};
    background: white; color: ${colors.blue}; font-weight: 700; font-size: 12px;
    cursor: pointer; font-family: ${fonts.body};
  }
  .amb-payout-btn:disabled { opacity: .5; cursor: not-allowed; }

  .amb-empty { text-align: center; padding: 40px 20px; font-size: 13px; color: ${colors.textSecondary}; }
`;

if (typeof document !== 'undefined' && !document.getElementById('amb-css')) {
  const s = document.createElement('style');
  s.id = 'amb-css';
  s.textContent = CSS;
  document.head.appendChild(s);
}

export default function AmbassadorDashboardPage() {
  const [code,        setCode]        = useState<string | null>(null);
  const [referrals,   setReferrals]   = useState<Referral[]>([]);
  const [commissions, setCommissions] = useState<Commission[]>([]);
  const [loading,      setLoading]      = useState(true);
  const [requesting,   setRequesting]   = useState<string | null>(null);
  const [copied,       setCopied]       = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    const [c0, r, c] = await Promise.all([getMyReferralCode(), getMyReferrals(), getMyCommissions()]);
    setCode(c0);
    setReferrals(r);
    setCommissions(c);
    setLoading(false);
  }, []);

  useEffect(() => { load(); }, [load]);

  async function handleCopy() {
    if (!code) return;
    await navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  async function handleRequestPayout(commission: Commission) {
    setRequesting(commission.id);
    try {
      await requestPayout(commission);
    } finally {
      setRequesting(null);
    }
  }

  return (
    <div className="amb-root">
      <PageHeader title="Parrainage" subtitle="Ton code, tes filleuls et tes commissions" />

      <div className="amb-link-card">
        <div>
          <div className="amb-link-label">Ton code de parrainage</div>
          <div className="amb-link-value">{code || '—'}</div>
        </div>
        <button className="amb-copy-btn" onClick={handleCopy} disabled={!code}>
          {copied ? 'Copié !' : 'Copier le code'}
        </button>
      </div>

      <h2 className="amb-section-title">Filleuls ({referrals.length})</h2>
      <div className="amb-table-wrap">
        {loading ? (
          <div className="amb-empty">Chargement</div>
        ) : referrals.length === 0 ? (
          <div className="amb-empty">Aucun filleul pour l'instant. Partage ton lien pour commencer.</div>
        ) : (
          <table className="amb-table">
            <thead>
              <tr><th>Étudiant</th><th>Statut</th><th>Inscrit le</th></tr>
            </thead>
            <tbody>
              {referrals.map(r => (
                <tr key={r.id}>
                  <td>{r.studentName}</td>
                  <td><span className={`amb-badge amb-status-${r.status}`}>{REFERRAL_STATUS_LABELS[r.status]}</span></td>
                  <td>{r.createdAt ? new Date(r.createdAt).toLocaleDateString('fr-FR') : '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <h2 className="amb-section-title">Commissions</h2>
      <div className="amb-table-wrap">
        {loading ? (
          <div className="amb-empty">Chargement</div>
        ) : commissions.length === 0 ? (
          <div className="amb-empty">Aucune commission pour l'instant.</div>
        ) : (
          <table className="amb-table">
            <thead>
              <tr><th>Période</th><th>Montant</th><th>Statut</th><th></th></tr>
            </thead>
            <tbody>
              {commissions.map(c => (
                <tr key={c.id}>
                  <td>{c.periodStart ? new Date(c.periodStart).toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' }) : '—'}</td>
                  <td>{c.amount}</td>
                  <td><span className={`amb-badge amb-status-${c.status}`}>{COMMISSION_STATUS_LABELS[c.status]}</span></td>
                  <td>
                    {c.status === 'payable' && (
                      <button
                        className="amb-payout-btn"
                        disabled={requesting === c.id}
                        onClick={() => handleRequestPayout(c)}
                      >
                        Demander un paiement
                      </button>
                    )}
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
