import { useState, useEffect, useCallback } from 'react';
import { colors, fonts, radius, shadows } from '../../../shared/constants/theme';
import { PageHeader }   from '../../../shared/components/PageHeader';
import { Pagination }   from '../../../shared/components/Pagination';
import { fetchAuditLogs, actionLabel, entityLabel } from '../services/audit_service';
import type { AuditLog } from '../services/audit_service';
import { supabase } from '../../../shared/services/supabase';

const CSS = `
  .aud-root { animation: aud-fade-up .25s ease; }
  @keyframes aud-fade-up { from{opacity:0;transform:translateY(8px)} to{opacity:1;transform:none} }

  /* Stat grid */
  .aud-stat-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
    margin-bottom: 24px;
  }
  @media (max-width: 700px) { .aud-stat-grid { grid-template-columns: 1fr; } }

  .aud-stat {
    background: white;
    border-radius: ${radius.lg}px;
    box-shadow: ${shadows.card};
    overflow: hidden;
  }
  .aud-stat-inner {
    padding: 18px 20px;
    display: flex;
    align-items: center;
    gap: 16px;
  }
  .aud-stat-icon {
    width: 46px; height: 46px;
    border-radius: 13px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }
  .aud-stat-value {
    font-size: 26px;
    font-family: ${fonts.display};
    font-weight: 800;
    color: ${colors.textPrimary};
    line-height: 1;
  }
  .aud-stat-label {
    font-size: 12px;
    color: ${colors.textSecondary};
    margin-top: 4px;
  }

  /* Stagger animations */
  .aud-stat-grid .aud-stat:nth-child(1) { animation: aud-fade-up .35s .06s ease both; }
  .aud-stat-grid .aud-stat:nth-child(2) { animation: aud-fade-up .35s .14s ease both; }
  .aud-stat-grid .aud-stat:nth-child(3) { animation: aud-fade-up .35s .22s ease both; }
  .aud-table-wrap { animation: aud-fade-up .35s .32s ease both; }

  /* Table card */
  .aud-table-wrap {
    background: white;
    border-radius: ${radius.lg}px;
    box-shadow: ${shadows.card};
    overflow: hidden;
  }

  /* Toolbar (filters inside card) */
  .aud-toolbar {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 16px 20px;
    border-bottom: 1px solid ${colors.border};
    flex-wrap: wrap;
  }
  .aud-filter-group { display: flex; align-items: center; gap: 6px; }
  .aud-filter-label {
    font-size: 12px; color: ${colors.textSecondary};
    white-space: nowrap; font-family: ${fonts.body};
  }
  .aud-filter-select {
    height: 36px; padding: 0 12px;
    border: 1.5px solid ${colors.borderInput}; border-radius: ${radius.md}px;
    font-size: 13px; font-family: ${fonts.body};
    color: ${colors.textPrimary}; background: ${colors.inputBg};
    cursor: pointer; outline: none; min-width: 150px; transition: border-color .18s;
  }
  .aud-filter-select:focus { border-color: ${colors.blue}; background: white; }
  .aud-filter-date {
    height: 36px; padding: 0 10px;
    border: 1.5px solid ${colors.borderInput}; border-radius: ${radius.md}px;
    font-size: 13px; font-family: ${fonts.body};
    color: ${colors.textPrimary}; background: ${colors.inputBg}; outline: none;
    transition: border-color .18s;
  }
  .aud-filter-date:focus { border-color: ${colors.blue}; background: white; }
  .aud-reset-btn {
    height: 36px; padding: 0 14px;
    border: 1.5px solid ${colors.borderInput}; border-radius: ${radius.md}px;
    font-size: 12.5px; font-family: ${fonts.body};
    color: ${colors.textSecondary}; background: white; cursor: pointer;
    transition: all .15s;
  }
  .aud-reset-btn:hover { border-color: ${colors.borderHover}; color: ${colors.navy}; }

  /* Table */
  .aud-table { width: 100%; border-collapse: collapse; }
  .aud-table thead tr {
    background: linear-gradient(135deg, #f8faff 0%, ${colors.inputBg} 100%);
    border-bottom: 2px solid ${colors.border};
  }
  .aud-table th {
    padding: 12px 20px;
    text-align: left; font-size: 11px; font-weight: 700;
    color: ${colors.textSecondary}; text-transform: uppercase;
    letter-spacing: .6px; white-space: nowrap;
  }
  .aud-table td {
    padding: 13px 20px; border-bottom: 1px solid ${colors.border};
    font-size: 13px; color: ${colors.textPrimary}; vertical-align: middle;
  }
  .aud-table tbody tr:last-child td { border-bottom: none; }
  .aud-table tbody tr { transition: background .12s; }
  .aud-table tbody tr:hover td { background: #f5f7ff; }

  /* Badges */
  .aud-badge {
    display: inline-flex; align-items: center; padding: 3px 9px;
    border-radius: 20px; font-size: 11px; font-weight: 700; white-space: nowrap;
  }
  .aud-entity-application { background: #eff6ff; color: #2563eb; }
  .aud-entity-document     { background: #fef9c3; color: #a16207; }
  .aud-entity-program      { background: #f0fdf4; color: #16a34a; }
  .aud-entity-default      { background: #f3f4f6; color: #6b7280; }

  .aud-action-status   { background: #eff6ff; color: #2563eb; }
  .aud-action-approve  { background: #f0fdf4; color: #16a34a; }
  .aud-action-reject   { background: #fef2f2; color: #dc2626; }
  .aud-action-email    { background: #fdf4ff; color: #9333ea; }
  .aud-action-program  { background: #fef9c3; color: #b45309; }
  .aud-action-default  { background: #f3f4f6; color: #6b7280; }

  /* Status chips in Changement column */
  .aud-change { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
  .aud-chip {
    display: inline-flex; align-items: center; padding: 2px 8px;
    border-radius: 20px; font-size: 11px; font-weight: 600; white-space: nowrap;
  }
  .aud-chip-old  { opacity: .55; text-decoration: line-through; }
  .aud-chip-arrow { color: ${colors.textSecondary}; flex-shrink: 0; display: flex; align-items: center; }

  /* Entity cell with ID */
  .aud-entity-cell { display: flex; flex-direction: column; gap: 3px; }
  .aud-entity-id { font-size: 10px; color: ${colors.textSecondary}; font-family: monospace; }

  .aud-date  { font-size: 12px; color: ${colors.textSecondary}; white-space: nowrap; }
  .aud-actor { font-size: 12.5px; color: ${colors.textPrimary}; max-width: 180px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .aud-actor-system { font-size: 12px; color: ${colors.textSecondary}; font-style: italic; }

  /* Empty */
  .aud-empty { text-align: center; padding: 60px 20px; }
  .aud-empty-icon { display: block; margin: 0 auto 12px; }
  .aud-empty-text { font-size: 14px; color: ${colors.textSecondary}; }

  .aud-loading { text-align: center; padding: 48px; color: ${colors.textSecondary}; font-size: 14px; }
`;

if (!document.getElementById('aud-css')) {
  const s = document.createElement('style');
  s.id = 'aud-css';
  s.textContent = CSS;
  document.head.appendChild(s);
}


const STATUS_CFG: Record<string, { label: string; color: string; bg: string }> = {
  draft:            { label: 'Brouillon',   color: '#64748b', bg: '#f1f5f9' },
  submitted:        { label: 'Soumise',     color: '#2563eb', bg: '#eff6ff' },
  needsfix:         { label: 'Correction',  color: '#d97706', bg: '#fffbeb' },
  verified:         { label: 'Validée',     color: '#0891b2', bg: '#ecfeff' },
  sent:             { label: 'Envoyée',     color: '#7c3aed', bg: '#f5f3ff' },
  accepted:         { label: 'Acceptée',    color: '#16a34a', bg: '#f0fdf4' },
  rejected:         { label: 'Refusée',     color: '#dc2626', bg: '#fef2f2' },
  archived:         { label: 'Archivée',    color: '#6b7280', bg: '#f9fafb' },
  pending_decision: { label: 'En attente',  color: '#854d0e', bg: '#fef9c3' },
  uploaded:         { label: 'Uploadé',     color: '#2563eb', bg: '#eff6ff' },
  under_review:     { label: 'En révision', color: '#d97706', bg: '#fffbeb' },
  approved:         { label: 'Approuvé',    color: '#16a34a', bg: '#f0fdf4' },
};

function StatusChip({ value, old: isOld }: { value: string; old?: boolean }) {
  const cfg = STATUS_CFG[value];
  return (
    <span
      className={`aud-chip${isOld ? ' aud-chip-old' : ''}`}
      style={{ background: cfg?.bg ?? '#f3f4f6', color: cfg?.color ?? '#6b7280' }}
    >
      {cfg?.label ?? value}
    </span>
  );
}

function actionBadgeClass(action: string): string {
  if (action.includes('status'))  return 'aud-action-status';
  if (action.includes('approve')) return 'aud-action-approve';
  if (action.includes('reject'))  return 'aud-action-reject';
  if (action.includes('email'))   return 'aud-action-email';
  if (action.includes('program')) return 'aud-action-program';
  return 'aud-action-default';
}

function entityBadgeClass(entity: string): string {
  if (entity === 'application') return 'aud-entity-application';
  if (entity === 'document')    return 'aud-entity-document';
  if (entity === 'program')     return 'aud-entity-program';
  return 'aud-entity-default';
}

function fmtDate(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' })
    + ' ' + d.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
}

interface Stats { total: number; today: number; applications: number }

export default function AuditPage() {
  const [logs,       setLogs]       = useState<AuditLog[]>([]);
  const [total,      setTotal]      = useState(0);
  const [stats,      setStats]      = useState<Stats>({ total: 0, today: 0, applications: 0 });
  const [page,       setPage]       = useState(1);
  const [pageSize,   setPageSize]   = useState(25);
  const [loading,    setLoading]    = useState(true);
  const [error,      setError]      = useState<string | null>(null);
  const [entityType, setEntityType] = useState('');
  const [action,     setAction]     = useState('');
  const [fromDate,   setFromDate]   = useState('');
  const [toDate,     setToDate]     = useState('');

  useEffect(() => {
    async function loadStats() {
      const todayStart = new Date(); todayStart.setHours(0, 0, 0, 0);
      const [
        { count: totalCount },
        { count: todayCount },
        { count: appCount },
      ] = await Promise.all([
        supabase.from('audit_logs').select('*', { count: 'exact', head: true }),
        supabase.from('audit_logs').select('*', { count: 'exact', head: true }).gte('created_at', todayStart.toISOString()),
        supabase.from('audit_logs').select('*', { count: 'exact', head: true }).eq('entity_type', 'application'),
      ]);
      setStats({ total: totalCount ?? 0, today: todayCount ?? 0, applications: appCount ?? 0 });
    }
    loadStats();
  }, []);

  const load = useCallback(async (p: number) => {
    setLoading(true);
    setError(null);
    try {
      const { data, count } = await fetchAuditLogs({
        limit:      pageSize,
        offset:     (p - 1) * pageSize,
        entityType: entityType || undefined,
        action:     action     || undefined,
        from:       fromDate   || undefined,
        to:         toDate     ? toDate + 'T23:59:59' : undefined,
      });
      setLogs(data);
      setTotal(count);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      setError(msg);
      setLogs([]);
      setTotal(0);
    } finally {
      setLoading(false);
    }
  }, [entityType, action, fromDate, toDate, pageSize]);

  useEffect(() => { setPage(1); }, [entityType, action, fromDate, toDate]);
  useEffect(() => { load(page); }, [page, load]);

  const totalPages = Math.ceil(total / pageSize);
  const hasFilters = !!(entityType || action || fromDate || toDate);

  function resetFilters() {
    setEntityType(''); setAction(''); setFromDate(''); setToDate('');
  }

  return (
    <div className="aud-root">
      <PageHeader
        title="Journal d'audit"
        subtitle={`${stats.total} entrée${stats.total !== 1 ? 's' : ''} · historique des actions internes`}
      />

      {/* Stat cards */}
      <div className="aud-stat-grid">
        <div className="aud-stat">
          <div className="aud-stat-inner">
            <div className="aud-stat-icon" style={{ background: 'rgba(37,70,204,0.10)' }}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#2546cc" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                <polyline points="14 2 14 8 20 8"/>
                <line x1="8" y1="13" x2="16" y2="13"/>
                <line x1="8" y1="17" x2="12" y2="17"/>
              </svg>
            </div>
            <div>
              <div className="aud-stat-value">{stats.total}</div>
              <div className="aud-stat-label">Total entrées</div>
            </div>
          </div>
        </div>

        <div className="aud-stat">
          <div className="aud-stat-inner">
            <div className="aud-stat-icon" style={{ background: 'rgba(22,163,74,0.10)' }}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#16a34a" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="12" cy="12" r="10"/>
                <polyline points="12 6 12 12 16 14"/>
              </svg>
            </div>
            <div>
              <div className="aud-stat-value">{stats.today}</div>
              <div className="aud-stat-label">Aujourd'hui</div>
            </div>
          </div>
        </div>

        <div className="aud-stat">
          <div className="aud-stat-inner">
            <div className="aud-stat-icon" style={{ background: 'rgba(217,119,6,0.10)' }}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#d97706" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                <polyline points="14 2 14 8 20 8"/>
                <line x1="16" y1="13" x2="8" y2="13"/>
                <line x1="16" y1="17" x2="8" y2="17"/>
                <polyline points="10 9 9 9 8 9"/>
              </svg>
            </div>
            <div>
              <div className="aud-stat-value">{stats.applications}</div>
              <div className="aud-stat-label">Candidatures tracées</div>
            </div>
          </div>
        </div>
      </div>

      {/* Table card */}
      <div className="aud-table-wrap">

        {/* Toolbar / Filters inside the card */}
        <div className="aud-toolbar">
          <select className="aud-filter-select" value={entityType} onChange={e => setEntityType(e.target.value)}>
            <option value="">Toutes les entités</option>
            <option value="application">Candidatures</option>
            <option value="document">Documents</option>
            <option value="program">Programmes</option>
          </select>
          <select className="aud-filter-select" value={action} onChange={e => setAction(e.target.value)}>
            <option value="">Toutes les actions</option>
            <option value="status_update">Changement statut</option>
            <option value="document_approve">Document approuvé</option>
            <option value="document_reject">Document rejeté</option>
            <option value="email_sent">Email envoyé</option>
            <option value="program_create">Programme créé</option>
            <option value="program_update">Programme modifié</option>
          </select>
          <div className="aud-filter-group">
            <span className="aud-filter-label">De</span>
            <input
              type="date" className="aud-filter-date"
              value={fromDate} onChange={e => setFromDate(e.target.value)}
            />
          </div>
          <div className="aud-filter-group">
            <span className="aud-filter-label">à</span>
            <input
              type="date" className="aud-filter-date"
              value={toDate} onChange={e => setToDate(e.target.value)}
            />
          </div>
          {hasFilters && (
            <button className="aud-reset-btn" onClick={resetFilters}>Réinitialiser</button>
          )}
        </div>

        {loading ? (
          <div className="aud-loading">Chargement</div>
        ) : error ? (
          <div style={{ padding: '32px 24px' }}>
            <div style={{
              padding: '14px 18px', borderRadius: 10,
              background: '#fef2f2', border: '1.5px solid #fecaca',
              display: 'flex', alignItems: 'flex-start', gap: 12,
            }}>
              <svg width={18} height={18} viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth={2} strokeLinecap="round" style={{ flexShrink: 0, marginTop: 2 }}>
                <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
              </svg>
              <div>
                <div style={{ fontWeight: 700, fontSize: 13, color: '#dc2626', marginBottom: 4 }}>
                  Impossible de charger le journal
                </div>
                <div style={{ fontSize: 12, color: '#7f1d1d', lineHeight: 1.5 }}>
                  {error.includes('permission') || error.includes('policy')
                    ? 'Accès refusé. Appliquez la migration SQL de correction des droits (20260611_audit_logs_fix.sql) dans Supabase.'
                    : error}
                </div>
              </div>
            </div>
          </div>
        ) : logs.length === 0 ? (
          <div className="aud-empty">
            <svg className="aud-empty-icon" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
              <polyline points="14 2 14 8 20 8"/>
              <line x1="8" y1="13" x2="16" y2="13"/>
              <line x1="8" y1="17" x2="12" y2="17"/>
            </svg>
            <div className="aud-empty-text">
              {hasFilters ? 'Aucune entrée pour ces critères.' : 'Aucune entrée dans le journal.'}
            </div>
          </div>
        ) : (
          <table className="aud-table">
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
                  <td><span className="aud-date">{fmtDate(log.created_at)}</span></td>
                  <td>
                    <span className={`aud-badge ${actionBadgeClass(log.action)}`}>
                      {actionLabel(log.action)}
                    </span>
                  </td>
                  <td>
                    <div className="aud-entity-cell">
                      <span className={`aud-badge ${entityBadgeClass(log.entity_type)}`}>
                        {entityLabel(log.entity_type)}
                      </span>
                      {log.entity_id && (
                        <span className="aud-entity-id">{log.entity_id.slice(0, 8)}&hellip;</span>
                      )}
                    </div>
                  </td>
                  <td>
                    {(log.old_value || log.new_value) ? (
                      <div className="aud-change">
                        {log.old_value && <StatusChip value={log.old_value} old />}
                        {log.old_value && log.new_value && (
                          <span className="aud-chip-arrow">
                            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                              <path d="M5 12h14M12 5l7 7-7 7"/>
                            </svg>
                          </span>
                        )}
                        {log.new_value && <StatusChip value={log.new_value} />}
                      </div>
                    ) : (
                      <span style={{ color: colors.textSecondary, fontSize: 12 }}>—</span>
                    )}
                  </td>
                  <td>
                    {log.actor_email
                      ? <span className="aud-actor" title={log.actor_email}>{log.actor_email}</span>
                      : <span className="aud-actor-system">Système</span>
                    }
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}

        <Pagination
          page={page}
          totalPages={totalPages}
          total={total}
          pageSize={pageSize}
          onChange={setPage}
          onPageSizeChange={size => { setPageSize(size); setPage(1); }}
          label="entrées"
        />
      </div>
    </div>
  );
}
