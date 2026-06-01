import React, { useState, useMemo, useEffect, useCallback } from 'react';
import { Badge }          from '../../../shared/components/Badge';
import { Button }         from '../../../shared/components/Button';
import { EmptyState }     from '../../../shared/components/EmptyState';
import { LoadingSpinner } from '../../../shared/components/LoadingSpinner';
import { PageHeader }     from '../../../shared/components/PageHeader';
import { Pagination }     from '../../../shared/components/Pagination';
import { colors, fonts, radius, shadows } from '../../../shared/constants/theme';
import type { Application }              from '../types/application';
import { RAW_STATUS_LABELS }             from '../types/application';
import { fetchApplications }              from '../services/applications_service';
import ApplicationDetailModal             from '../components/ApplicationDetailModal';
import ApplicationKanban                  from '../components/ApplicationKanban';

/* ─── Constants ─────────────────────────────────────────────────────────── */
const PAGE_SIZE = 10;

/* ─── Types ──────────────────────────────────────────────────────────────── */
type UIStatus = Application['status'];
type ViewMode = 'table' | 'kanban';

/* ─── CSS ────────────────────────────────────────────────────────────────── */
const CSS = `
  .ap-stat-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 16px;
    margin-bottom: 24px;
  }
  @media (max-width: 900px) { .ap-stat-grid { grid-template-columns: repeat(2, 1fr); } }
  @media (max-width: 480px) { .ap-stat-grid { grid-template-columns: 1fr 1fr; gap: 10px; } }

  .ap-stat {
    background: white;
    border-radius: ${radius.lg}px;
    box-shadow: ${shadows.card};
    overflow: hidden;
  }
  .ap-stat-inner {
    padding: 16px 20px;
    display: flex;
    align-items: center;
    gap: 14px;
  }
  .ap-stat-icon {
    width: 44px; height: 44px;
    border-radius: 12px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }

  .ap-table-card {
    background: white;
    border-radius: ${radius.lg}px;
    box-shadow: ${shadows.card};
    overflow: hidden;
  }

  .ap-toolbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 18px 20px 16px;
    flex-wrap: wrap;
  }
  @media (max-width: 600px) {
    .ap-toolbar { flex-direction: column; align-items: stretch; }
  }

  .ap-search-wrap { position: relative; }
  .ap-search {
    padding: 9px 14px 9px 38px;
    border: 1.5px solid ${colors.borderInput};
    border-radius: 9px; font-size: 13.5px;
    color: ${colors.textPrimary}; background: ${colors.inputBg};
    font-family: ${fonts.body}; width: 240px; outline: none;
    transition: border-color .18s, box-shadow .18s, background .18s;
  }
  .ap-search:focus { border-color: ${colors.blue}; background: #fff; box-shadow: 0 0 0 3px rgba(37,70,204,.1); }
  @media (max-width: 600px) { .ap-search { width: 100%; } }

  .ap-filters { display: flex; gap: 6px; flex-wrap: wrap; }
  .ap-filter-btn {
    padding: 6px 16px; border-radius: 20px;
    font-size: 12px; font-weight: 600;
    border: 1.5px solid ${colors.borderInput};
    background: white; color: ${colors.textSecondary};
    cursor: pointer; transition: all .15s;
    font-family: ${fonts.body};
  }
  .ap-filter-btn--active { background: ${colors.navy}; color: white; border-color: ${colors.navy}; }
  .ap-filter-btn:hover:not(.ap-filter-btn--active) { border-color: ${colors.blue}; color: ${colors.blue}; }

  .ap-table-wrap { overflow-x: auto; }
  .ap-table { width: 100%; border-collapse: collapse; min-width: 700px; font-family: ${fonts.body}; }

  .ap-table thead tr {
    background: linear-gradient(135deg, #f8faff 0%, ${colors.inputBg} 100%);
    border-bottom: 2px solid ${colors.border};
  }
  .ap-table th {
    padding: 12px 16px;
    font-size: 11px; font-weight: 700;
    letter-spacing: .06em; text-transform: uppercase;
    color: ${colors.textSecondary}; text-align: left;
    white-space: nowrap;
  }
  .ap-table td {
    padding: 13px 16px; font-size: 13.5px;
    color: ${colors.textPrimary};
    border-bottom: 1px solid ${colors.border};
    vertical-align: middle;
  }
  .ap-table tbody tr:last-child td { border-bottom: none; }
  .ap-table tbody tr { transition: background .12s; cursor: pointer; }
  .ap-table tbody tr:hover td { background: #f5f8ff; }

  .ap-student-cell { display: flex; align-items: center; gap: 10px; }
  .ap-avatar {
    width: 34px; height: 34px; border-radius: 9px; flex-shrink: 0;
    display: flex; align-items: center; justify-content: center;
    font-size: 11px; font-weight: 700; font-family: ${fonts.display};
  }

  .ap-score-bar { height: 4px; border-radius: 2px; background: #e8eaf2; overflow: hidden; width: 56px; }
  .ap-score-fill { height: 100%; border-radius: 2px; transition: width .3s; }

  .ap-action-btn {
    background: ${colors.inputBg}; border: 1.5px solid transparent;
    cursor: pointer; padding: 6px 10px; border-radius: 7px;
    color: ${colors.textMuted}; display: flex; align-items: center;
    transition: all .15s; font-family: ${fonts.body};
  }
  .ap-action-btn:hover { background: white; border-color: ${colors.blue}; color: ${colors.blue}; }

  .ap-footer {
    padding: 12px 20px;
    border-top: 1px solid ${colors.border};
    display: flex; align-items: center; justify-content: space-between;
    flex-wrap: wrap; gap: 8px; background: #fafbff;
  }

  .ap-view-btn {
    display: flex; align-items: center; gap: 6px;
    padding: 7px 14px; border-radius: 8px; font-size: 13px; font-weight: 600;
    border: 1.5px solid ${colors.borderInput}; cursor: pointer;
    background: white; color: ${colors.textSecondary};
    font-family: ${fonts.body}; transition: all .15s;
  }
  .ap-view-btn--active {
    background: ${colors.navy}; color: white; border-color: ${colors.navy};
  }
  .ap-view-btn:hover:not(.ap-view-btn--active) { border-color: ${colors.blue}; color: ${colors.blue}; }

  .ap-stat-grid .ap-stat:nth-child(1) { animation: ph-fade-up .35s .08s ease both; }
  .ap-stat-grid .ap-stat:nth-child(2) { animation: ph-fade-up .35s .16s ease both; }
  .ap-stat-grid .ap-stat:nth-child(3) { animation: ph-fade-up .35s .24s ease both; }
  .ap-stat-grid .ap-stat:nth-child(4) { animation: ph-fade-up .35s .32s ease both; }
  .ap-table-card { animation: ph-fade-up .35s .42s ease both; }
`;

if (!document.getElementById('ap-css')) {
  const s = document.createElement('style'); s.id = 'ap-css'; s.textContent = CSS;
  document.head.appendChild(s);
}

/* ─── Helpers ────────────────────────────────────────────────────────────── */
const STATUS_BADGE: Record<string, 'validated' | 'pending' | 'urgent' | 'info' | 'default'> = {
  draft:            'default',
  submitted:        'pending',
  needsfix:         'urgent',
  verified:         'info',
  sent:             'info',
  accepted:         'validated',
  rejected:         'default',
  pending_decision: 'pending',
  archived:         'default',
};

const AVATAR_PALETTE = [
  ['#2546cc', 'rgba(37,70,204,0.12)'],
  ['#7c3aed', 'rgba(124,58,237,0.12)'],
  ['#15803d', 'rgba(22,163,74,0.12)'],
  ['#d97706', 'rgba(217,119,6,0.12)'],
  ['#0891b2', 'rgba(8,145,178,0.12)'],
];
const avatarColor = (name: string) => AVATAR_PALETTE[name.charCodeAt(0) % AVATAR_PALETTE.length];

function initials(name: string) {
  return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
}

function scoreColor(n: number) {
  if (n >= 80) return colors.success;
  if (n >= 65) return colors.warning;
  return colors.danger;
}

const FILTERS: ('Tous' | UIStatus)[] = ['Tous', 'En attente', 'Validé', 'Urgent', 'Refusé'];

/* ─── Stat card ──────────────────────────────────────────────────────────── */
function StatCard({ label, value, sub, accent, iconBg, iconColor, icon }: {
  label: string; value: number; sub?: string;
  accent: string; iconBg: string; iconColor: string;
  icon: React.ReactNode;
}) {
  return (
    <div className="ap-stat">
      <div style={{ height: 3, background: accent }} />
      <div className="ap-stat-inner">
        <div className="ap-stat-icon" style={{ background: iconBg, color: iconColor }}>{icon}</div>
        <div>
          <div style={{ fontSize: 26, fontWeight: 800, color: accent, fontFamily: fonts.display, lineHeight: 1 }}>{value}</div>
          <div style={{ fontSize: 12.5, fontWeight: 600, color: colors.textPrimary, marginTop: 2 }}>{label}</div>
          {sub && <div style={{ fontSize: 11.5, color: colors.textMuted, marginTop: 1 }}>{sub}</div>}
        </div>
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════════════════════════════════
   ApplicationsPage
   ═══════════════════════════════════════════════════════════════════════════ */
export default function ApplicationsPage() {
  const [apps,        setApps]        = useState<Application[]>([]);
  const [search,      setSearch]      = useState('');
  const [filter,      setFilter]      = useState<'Tous' | UIStatus>('Tous');
  const [loading,     setLoading]     = useState(true);
  const [fetchError,  setFetchError]  = useState<string | null>(null);
  const [view,        setView]        = useState<ViewMode>('table');
  const [selectedApp, setSelectedApp] = useState<Application | null>(null);
  const [page,        setPage]        = useState(1);

  useEffect(() => {
    fetchApplications()
      .then(data => { setApps(data); setFetchError(null); })
      .catch(err  => { console.error('fetchApplications:', err); setFetchError(err?.message ?? String(err)); setApps([]); })
      .finally(() => setLoading(false));
  }, []);

  const handleUpdate = useCallback((id: string, patch: Partial<Application>) => {
    setApps(prev => prev.map(a => a.id === id ? { ...a, ...patch } : a));
    setSelectedApp(prev => prev?.id === id ? { ...prev, ...patch } as Application : prev);
  }, []);

  const total     = apps.length;
  const validated = apps.filter(a => a.status === 'Validé').length;
  const pending   = apps.filter(a => a.status === 'En attente').length;
  const urgent    = apps.filter(a => a.status === 'Urgent').length;

  const filtered = useMemo(() => {
    let d = apps;
    if (filter !== 'Tous') d = d.filter(a => a.status === filter);
    if (search.trim()) {
      const q = search.toLowerCase();
      d = d.filter(a =>
        a.student.toLowerCase().includes(q) ||
        a.university.toLowerCase().includes(q) ||
        a.program.toLowerCase().includes(q) ||
        a.country.toLowerCase().includes(q)
      );
    }
    return d;
  }, [apps, search, filter]);

  useEffect(() => setPage(1), [filter, search]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const paginated  = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  if (loading) return <LoadingSpinner fullPage />;

  return (
    <div>
      <PageHeader
        title="Candidatures"
        subtitle={`${total} dossier${total !== 1 ? 's' : ''} · ${pending} en attente de traitement`}
      />

      {/* ── Toggle vue ── */}
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 20, marginTop: -12 }}>
        <div style={{ display: 'flex', gap: 4, background: colors.inputBg, borderRadius: 10, padding: 4 }}>
          <button
            className={`ap-view-btn${view === 'table' ? ' ap-view-btn--active' : ''}`}
            onClick={() => setView('table')}
          >
            <IconTable /> Tableau
          </button>
          <button
            className={`ap-view-btn${view === 'kanban' ? ' ap-view-btn--active' : ''}`}
            onClick={() => setView('kanban')}
          >
            <IconKanban /> Kanban
          </button>
        </div>
      </div>

      {/* ── Erreur fetch ── */}
      {fetchError && (
        <div style={{
          marginBottom: 20, padding: '12px 16px',
          background: '#fef2f2', border: '1.5px solid #fecaca',
          borderRadius: 10, fontSize: 13, color: '#dc2626', fontFamily: fonts.body,
        }}>
          <strong>Erreur de chargement :</strong> {fetchError}
        </div>
      )}

      {/* ── Stats ── */}
      <div className="ap-stat-grid">
        <StatCard
          label="Total dossiers" value={total} sub="Toutes périodes"
          accent={colors.blue} iconBg="rgba(37,70,204,0.10)" iconColor={colors.blue}
          icon={<svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>}
        />
        <StatCard
          label="Validés" value={validated}
          accent={colors.success} iconBg="rgba(22,163,74,0.10)" iconColor={colors.success}
          icon={<svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>}
        />
        <StatCard
          label="En attente" value={pending} sub="À traiter"
          accent={colors.warning} iconBg="rgba(217,119,6,0.10)" iconColor={colors.warning}
          icon={<svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>}
        />
        <StatCard
          label="Urgents" value={urgent} sub="Correction requise"
          accent={colors.danger} iconBg="rgba(220,38,38,0.10)" iconColor={colors.danger}
          icon={<svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>}
        />
      </div>

      {/* ── Vue kanban ── */}
      {view === 'kanban' && (
        <ApplicationKanban
          apps={apps}
          onUpdate={handleUpdate}
          onSelect={setSelectedApp}
        />
      )}

      {/* ── Vue tableau ── */}
      {view === 'table' && (
        <div className="ap-table-card">
          <div style={{ height: 3, background: `linear-gradient(90deg, ${colors.blue}, #7c3aed)` }} />

          {/* Toolbar */}
          <div className="ap-toolbar">
            <div className="ap-search-wrap">
              <span style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: colors.textMuted, display: 'flex', pointerEvents: 'none' }}>
                <IconSearch />
              </span>
              <input
                className="ap-search"
                type="search"
                placeholder="Rechercher…"
                value={search}
                onChange={e => setSearch(e.target.value)}
              />
            </div>
            <div className="ap-filters">
              {FILTERS.map(f => (
                <button
                  key={f}
                  className={`ap-filter-btn${filter === f ? ' ap-filter-btn--active' : ''}`}
                  onClick={() => setFilter(f)}
                >
                  {f}
                </button>
              ))}
            </div>
          </div>

          <div className="ap-table-wrap">
            {filtered.length === 0 ? (
              <EmptyState
                icon={<IconSearch />}
                title="Aucun dossier trouvé"
                description="Essayez d'ajuster votre recherche ou vos filtres."
                action={
                  <Button variant="ghost" size="sm" onClick={() => { setSearch(''); setFilter('Tous'); }}>
                    Réinitialiser
                  </Button>
                }
              />
            ) : (
              <table className="ap-table">
                <thead>
                  <tr>
                    <th>Étudiant</th>
                    <th>Université</th>
                    <th>Programme</th>
                    <th>Pays</th>
                    <th>Date</th>
                    <th>Score</th>
                    <th>Statut</th>
                    <th style={{ textAlign: 'right' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {paginated.map(app => {
                    const [fg, bg] = avatarColor(app.student);
                    return (
                      <tr key={app.id} onClick={() => setSelectedApp(app)}>
                        <td>
                          <div className="ap-student-cell">
                            <div className="ap-avatar" style={{ background: bg, color: fg }}>
                              {initials(app.student)}
                            </div>
                            <div>
                              <div style={{ fontWeight: 600, fontSize: 13.5, color: colors.textPrimary }}>{app.student}</div>
                              {app.email && <div style={{ fontSize: 12, color: colors.textMuted }}>{app.email}</div>}
                            </div>
                          </div>
                        </td>
                        <td style={{ fontWeight: 500, maxWidth: 180 }}>
                          <div style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{app.university}</div>
                        </td>
                        <td style={{ color: colors.textSecondary, maxWidth: 160 }}>
                          <div style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{app.program}</div>
                        </td>
                        <td>
                          <span style={{ fontSize: 13, color: colors.textSecondary }}>{app.country}</span>
                        </td>
                        <td style={{ color: colors.textMuted, fontSize: 13, whiteSpace: 'nowrap' }}>
                          {app.date ? new Date(app.date).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' }) : '—'}
                        </td>
                        <td>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                            <div className="ap-score-bar">
                              <div className="ap-score-fill" style={{ width: `${app.score}%`, background: scoreColor(app.score) }} />
                            </div>
                            <span style={{ fontSize: 13, fontWeight: 700, color: scoreColor(app.score) }}>{app.score}</span>
                          </div>
                        </td>
                        <td>
                          <Badge variant={STATUS_BADGE[app.rawStatus] ?? 'default'} dot>{RAW_STATUS_LABELS[app.rawStatus]}</Badge>
                        </td>
                        <td style={{ textAlign: 'right' }}>
                          <div style={{ display: 'flex', gap: 6, justifyContent: 'flex-end' }} onClick={e => e.stopPropagation()}>
                            <button className="ap-action-btn" title="Ouvrir le dossier" onClick={() => setSelectedApp(app)}>
                              <IconEye />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>

          <Pagination
            page={page}
            totalPages={totalPages}
            total={filtered.length}
            pageSize={PAGE_SIZE}
            onChange={setPage}
            label="candidatures"
          />
        </div>
      )}

      {/* ── Modal détail ── */}
      {selectedApp && (
        <ApplicationDetailModal
          app={selectedApp}
          onClose={() => setSelectedApp(null)}
          onUpdate={handleUpdate}
        />
      )}
    </div>
  );
}

/* ─── Icons ──────────────────────────────────────────────────────────────── */
function IconSearch()  { return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>; }
function IconEye()     { return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>; }
function IconTable()   { return <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><line x1="3" y1="9" x2="21" y2="9"/><line x1="3" y1="15" x2="21" y2="15"/><line x1="9" y1="3" x2="9" y2="21"/></svg>; }
function IconKanban()  { return <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="5" height="18" rx="1"/><rect x="10" y="3" width="5" height="11" rx="1"/><rect x="17" y="3" width="5" height="15" rx="1"/></svg>; }
