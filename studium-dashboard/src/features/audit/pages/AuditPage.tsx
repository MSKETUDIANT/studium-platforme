import { useState, useEffect, useCallback } from 'react';
import { colors, fonts } from '../../../shared/constants/theme';
import { PageHeader } from '../../../shared/components/PageHeader';
import { fetchAuditLogs, actionLabel, entityLabel } from '../services/audit_service';
import type { AuditLog } from '../services/audit_service';

const CSS = `
  .audit-root { animation: fadeInUp .25s ease; }
  @keyframes fadeInUp { from{opacity:0;transform:translateY(8px)} to{opacity:1;transform:none} }


  .audit-filters {
    background:white; border-radius:14px;
    box-shadow:0 1px 4px rgba(11,24,82,0.04), 0 8px 24px rgba(11,24,82,0.07), 0 28px 60px rgba(11,24,82,0.08);
    padding:14px 16px; margin-bottom:20px;
    display:flex; gap:10px; flex-wrap:wrap; align-items:center;
  }
  .audit-filter-select {
    height:38px; padding:0 12px;
    border:1.5px solid ${colors.borderInput}; border-radius:10px;
    font-size:13.5px; font-family:${fonts.body};
    color:${colors.textPrimary}; background:${colors.inputBg}; cursor:pointer;
    outline:none; min-width:160px; transition:border-color .18s;
  }
  .audit-filter-select:focus { border-color:${colors.blue}; }
  .audit-filter-date {
    height:38px; padding:0 10px;
    border:1.5px solid ${colors.borderInput}; border-radius:10px;
    font-size:13.5px; font-family:${fonts.body};
    color:${colors.textPrimary}; background:${colors.inputBg}; outline:none;
    transition:border-color .18s;
  }
  .audit-filter-date:focus { border-color:${colors.blue}; }
  .audit-reset-btn {
    height:38px; padding:0 14px;
    border:1.5px solid ${colors.borderInput}; border-radius:10px;
    font-size:13px; font-family:${fonts.body};
    color:${colors.textSecondary}; background:white; cursor:pointer;
    transition:all .15s;
  }
  .audit-reset-btn:hover { border-color:${colors.borderHover}; color:${colors.navy}; }

  .audit-table-wrap {
    background:white; border-radius:14px; overflow:hidden;
    box-shadow:0 1px 4px rgba(11,24,82,0.04), 0 8px 24px rgba(11,24,82,0.07), 0 28px 60px rgba(11,24,82,0.08);
  }
  .audit-table { width:100%; border-collapse:collapse; }
  .audit-table thead tr {
    background:linear-gradient(135deg, #f8faff 0%, ${colors.inputBg} 100%);
    border-bottom:2px solid ${colors.border};
  }
  .audit-table th {
    padding:13px 16px;
    text-align:left; font-size:11px; font-weight:700;
    color:${colors.textSecondary}; text-transform:uppercase;
    letter-spacing:.6px; white-space:nowrap;
  }
  .audit-table td {
    padding:13px 16px; border-bottom:1px solid ${colors.border};
    font-size:13px; color:${colors.textPrimary}; vertical-align:top;
  }
  .audit-table tbody tr:last-child td { border-bottom:none; }
  .audit-table tbody tr { transition:background .12s; }
  .audit-table tbody tr:hover td { background:#f5f7ff; }

  .audit-badge {
    display:inline-flex; align-items:center; padding:3px 9px;
    border-radius:20px; font-size:11px; font-weight:700; white-space:nowrap;
  }
  .audit-entity-application { background:#eff6ff; color:#2563eb; }
  .audit-entity-document     { background:#fef9c3; color:#a16207; }
  .audit-entity-program      { background:#f0fdf4; color:#16a34a; }
  .audit-entity-default      { background:#f3f4f6; color:#6b7280; }

  .audit-action-status   { background:#eff6ff; color:#2563eb; }
  .audit-action-approve  { background:#f0fdf4; color:#16a34a; }
  .audit-action-reject   { background:#fef2f2; color:#dc2626; }
  .audit-action-email    { background:#fdf4ff; color:#9333ea; }
  .audit-action-program  { background:#fef9c3; color:#b45309; }
  .audit-action-default  { background:#f3f4f6; color:#6b7280; }

  .audit-old-new { display:flex; align-items:center; gap:6px; font-size:12px; }
  .audit-old { color:${colors.textSecondary}; text-decoration:line-through; }
  .audit-arrow { color:${colors.textSecondary}; flex-shrink:0; }
  .audit-new { color:${colors.navy}; font-weight:600; }

  .audit-date { font-size:12px; color:${colors.textSecondary}; white-space:nowrap; }
  .audit-actor { font-size:12px; color:${colors.textSecondary}; max-width:160px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }

  .audit-empty { text-align:center; padding:60px 20px; }
  .audit-empty-icon { display:block; margin:0 auto 12px; }
  .audit-empty-text { font-size:14px; color:${colors.textSecondary}; }

  .audit-pagination {
    display:flex; align-items:center; justify-content:space-between;
    padding:12px 20px; border-top:1px solid ${colors.border};
    background:#fafbff;
  }
  .audit-pag-info { font-size:12.5px; color:${colors.textMuted}; font-family:${fonts.body}; }
  .audit-pag-btns { display:flex; gap:4px; }
  .audit-pag-btn {
    height:32px; padding:0 12px;
    border:1.5px solid ${colors.borderInput}; border-radius:8px;
    font-size:12.5px; font-weight:600; font-family:${fonts.body};
    background:white; cursor:pointer; color:${colors.textSecondary};
    transition:all .15s; display:inline-flex; align-items:center; gap:4px;
  }
  .audit-pag-btn:not(:disabled):hover { border-color:${colors.blue}; color:${colors.blue}; }
  .audit-pag-btn:disabled { opacity:.4; cursor:not-allowed; }

  .audit-loading { text-align:center; padding:40px; color:${colors.textSecondary}; font-size:14px; }
`;

if (!document.getElementById('audit-css')) {
  const s = document.createElement('style');
  s.id = 'audit-css';
  s.textContent = CSS;
  document.head.appendChild(s);
}

const PAGE_SIZE = 50;

const STATUS_LABELS: Record<string, string> = {
  draft: 'Brouillon', submitted: 'Soumise', needsfix: 'Correction',
  verified: 'Validée', sent: 'Envoyée', accepted: 'Acceptée',
  rejected: 'Refusée', archived: 'Archivée', pending_decision: 'En attente',
  uploaded: 'Uploadé', under_review: 'En révision', approved: 'Approuvé',
};
const labelOf = (v: string | null) => v ? (STATUS_LABELS[v] ?? v) : '';

function actionBadgeClass(action: string): string {
  if (action.includes('status'))  return 'audit-action-status';
  if (action.includes('approve')) return 'audit-action-approve';
  if (action.includes('reject'))  return 'audit-action-reject';
  if (action.includes('email'))   return 'audit-action-email';
  if (action.includes('program')) return 'audit-action-program';
  return 'audit-action-default';
}

function entityBadgeClass(entity: string): string {
  if (entity === 'application') return 'audit-entity-application';
  if (entity === 'document')    return 'audit-entity-document';
  if (entity === 'program')     return 'audit-entity-program';
  return 'audit-entity-default';
}

function fmtDate(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' })
    + ' ' + d.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
}

export default function AuditPage() {
  const [logs,       setLogs]       = useState<AuditLog[]>([]);
  const [total,      setTotal]      = useState(0);
  const [page,       setPage]       = useState(0);
  const [loading,    setLoading]    = useState(true);
  const [entityType, setEntityType] = useState('');
  const [action,     setAction]     = useState('');
  const [fromDate,   setFromDate]   = useState('');
  const [toDate,     setToDate]     = useState('');

  const load = useCallback(async (p: number) => {
    setLoading(true);
    try {
      const { data, count } = await fetchAuditLogs({
        limit:      PAGE_SIZE,
        offset:     p * PAGE_SIZE,
        entityType: entityType || undefined,
        action:     action     || undefined,
        from:       fromDate   || undefined,
        to:         toDate     ? toDate + 'T23:59:59' : undefined,
      });
      setLogs(data);
      setTotal(count);
    } finally {
      setLoading(false);
    }
  }, [entityType, action, fromDate, toDate]);

  useEffect(() => { setPage(0); }, [entityType, action, fromDate, toDate]);
  useEffect(() => { load(page); }, [page, load]);

  const totalPages = Math.ceil(total / PAGE_SIZE);

  function resetFilters() {
    setEntityType(''); setAction(''); setFromDate(''); setToDate('');
  }

  return (
    <div className="audit-root">
      <PageHeader
        title="Journal d'audit"
        subtitle={`${total} entrée${total !== 1 ? 's' : ''} · historique des actions internes`}
      />

      <div className="audit-filters">
        <select className="audit-filter-select" value={entityType} onChange={e => setEntityType(e.target.value)}>
          <option value="">Toutes les entités</option>
          <option value="application">Candidatures</option>
          <option value="document">Documents</option>
          <option value="program">Programmes</option>
        </select>
        <select className="audit-filter-select" value={action} onChange={e => setAction(e.target.value)}>
          <option value="">Toutes les actions</option>
          <option value="status_update">Changement statut</option>
          <option value="document_approve">Document approuvé</option>
          <option value="document_reject">Document rejeté</option>
          <option value="email_sent">Email envoyé</option>
          <option value="program_create">Programme créé</option>
          <option value="program_update">Programme modifié</option>
        </select>
        <input
          type="date" className="audit-filter-date"
          value={fromDate} onChange={e => setFromDate(e.target.value)}
          title="Depuis"
        />
        <input
          type="date" className="audit-filter-date"
          value={toDate} onChange={e => setToDate(e.target.value)}
          title="Jusqu'au"
        />
        {(entityType || action || fromDate || toDate) && (
          <button className="audit-reset-btn" onClick={resetFilters}>Réinitialiser</button>
        )}
      </div>

      <div className="audit-table-wrap">
        {loading ? (
          <div className="audit-loading">Chargement</div>
        ) : logs.length === 0 ? (
          <div className="audit-empty">
            <svg className="audit-empty-icon" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/>
              <line x1="8" y1="13" x2="16" y2="13"/><line x1="8" y1="17" x2="12" y2="17"/>
            </svg>
            <div className="audit-empty-text">Aucune entrée dans le journal.</div>
          </div>
        ) : (
          <table className="audit-table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Action</th>
                <th>Entité</th>
                <th>Changement</th>
                <th>Acteur</th>
              </tr>
            </thead>
            <tbody>
              {logs.map(log => (
                <tr key={log.id}>
                  <td><span className="audit-date">{fmtDate(log.created_at)}</span></td>
                  <td>
                    <span className={`audit-badge ${actionBadgeClass(log.action)}`}>
                      {actionLabel(log.action)}
                    </span>
                  </td>
                  <td>
                    <span className={`audit-badge ${entityBadgeClass(log.entity_type)}`}>
                      {entityLabel(log.entity_type)}
                    </span>
                  </td>
                  <td>
                    {(log.old_value || log.new_value) ? (
                      <span className="audit-old-new">
                        {log.old_value && <span className="audit-old">{labelOf(log.old_value)}</span>}
                        {log.old_value && log.new_value && <span className="audit-arrow"></span>}
                        {log.new_value && <span className="audit-new">{labelOf(log.new_value)}</span>}
                      </span>
                    ) : <span style={{ color: colors.textSecondary, fontSize: 12 }}></span>}
                  </td>
                  <td>
                    <span className="audit-actor" title={log.actor_email ?? ''}>
                      {log.actor_email ?? 'Système'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}

        {total > PAGE_SIZE && (
          <div className="audit-pagination">
            <span className="audit-pag-info">
              {page * PAGE_SIZE + 1}{Math.min((page + 1) * PAGE_SIZE, total)} sur {total}
            </span>
            <div className="audit-pag-btns">
              <button className="audit-pag-btn" disabled={page === 0} onClick={() => setPage(p => p - 1)}>
                 Précédent
              </button>
              <button className="audit-pag-btn" disabled={page >= totalPages - 1} onClick={() => setPage(p => p + 1)}>
                Suivant 
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
