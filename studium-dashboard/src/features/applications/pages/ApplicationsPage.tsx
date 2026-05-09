import React, { useState, useMemo } from 'react';
import { Badge }          from '../../../shared/components/Badge';
import { Button }         from '../../../shared/components/Button';
import { EmptyState }     from '../../../shared/components/EmptyState';
import { LoadingSpinner } from '../../../shared/components/LoadingSpinner';
import { colors, fonts, radius, shadows } from '../../../shared/constants/theme';

/* ─── Types ──────────────────────────────────────────────────────────────── */
type Status = 'En attente' | 'Validé' | 'Urgent' | 'Refusé';

interface Application {
  id:         string;
  student:    string;
  email:      string;
  university: string;
  country:    string;
  program:    string;
  date:       string;
  status:     Status;
  score:      number;
}

/* ─── Données mock ───────────────────────────────────────────────────────── */
const MOCK_DATA: Application[] = [
  { id:'APP-001', student:'Amir Benali',    email:'amir.benali@gmail.com',    university:'HEC Paris',              country:'France',   program:'Master Finance',           date:'2025-01-15', status:'Validé',     score:88 },
  { id:'APP-002', student:'Sana Khelifi',   email:'sana.khelifi@yahoo.fr',    university:'Université de Montréal', country:'Canada',   program:'MBA International',        date:'2025-01-18', status:'En attente', score:74 },
  { id:'APP-003', student:'Youssef Tazi',   email:'youssef.tazi@gmail.com',   university:'Sciences Po Paris',      country:'France',   program:'Relations Internationales', date:'2025-01-20', status:'Urgent',     score:81 },
  { id:'APP-004', student:'Rim Ouali',      email:'rim.ouali@outlook.com',    university:'Polytechnique Montréal', country:'Canada',   program:'Génie Civil',              date:'2025-01-22', status:'Validé',     score:91 },
  { id:'APP-005', student:'Karim Mansouri', email:'karim.mansouri@gmail.com', university:'Université de Bordeaux', country:'France',   program:'Master Droit',             date:'2025-01-25', status:'Refusé',     score:58 },
  { id:'APP-006', student:'Nadia Hamdi',    email:'nadia.hamdi@gmail.com',    university:'ESSEC Business School',  country:'France',   program:'Grande École',             date:'2025-01-28', status:'En attente', score:77 },
  { id:'APP-007', student:'Omar Ziani',     email:'omar.ziani@yahoo.com',     university:'McGill University',      country:'Canada',   program:'MSc Computer Science',     date:'2025-02-01', status:'Urgent',     score:85 },
  { id:'APP-008', student:'Fatima Larbi',   email:'fatima.larbi@gmail.com',   university:'Sorbonne Université',    country:'France',   program:'Master Lettres',           date:'2025-02-03', status:'Validé',     score:82 },
  { id:'APP-009', student:'Bilal Chouikh',  email:'bilal.chouikh@gmail.com',  university:'Université Laval',       country:'Canada',   program:'Master Économie',          date:'2025-02-05', status:'En attente', score:70 },
  { id:'APP-010', student:'Meriem Saadi',   email:'meriem.saadi@gmail.com',   university:'INSA Lyon',              country:'France',   program:'Ingénierie Industrielle',  date:'2025-02-08', status:'Validé',     score:89 },
];

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
  .ap-table tbody tr { transition: background .12s; }
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
`;

if (!document.getElementById('ap-css')) {
  const s = document.createElement('style'); s.id = 'ap-css'; s.textContent = CSS;
  document.head.appendChild(s);
}

/* ─── Helpers ────────────────────────────────────────────────────────────── */
const STATUS_BADGE: Record<Status, 'validated' | 'pending' | 'urgent' | 'default'> = {
  'Validé':     'validated',
  'En attente': 'pending',
  'Urgent':     'urgent',
  'Refusé':     'default',
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

const FILTERS: ('Tous' | Status)[] = ['Tous', 'En attente', 'Validé', 'Urgent', 'Refusé'];

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
        <div className="ap-stat-icon" style={{ background: iconBg, color: iconColor }}>
          {icon}
        </div>
        <div>
          <div style={{ fontSize: 26, fontWeight: 800, color: accent, fontFamily: fonts.display, lineHeight: 1 }}>
            {value}
          </div>
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
  const [search,  setSearch]  = useState('');
  const [filter,  setFilter]  = useState<'Tous' | Status>('Tous');
  const [loading, _]          = useState(false);

  const total     = MOCK_DATA.length;
  const validated = MOCK_DATA.filter(a => a.status === 'Validé').length;
  const pending   = MOCK_DATA.filter(a => a.status === 'En attente').length;
  const urgent    = MOCK_DATA.filter(a => a.status === 'Urgent').length;

  const filtered = useMemo(() => {
    let d = MOCK_DATA;
    if (filter !== 'Tous') d = d.filter(a => a.status === filter);
    if (search.trim()) {
      const q = search.toLowerCase();
      d = d.filter(a =>
        a.student.toLowerCase().includes(q) ||
        a.university.toLowerCase().includes(q) ||
        a.program.toLowerCase().includes(q) ||
        a.country.toLowerCase().includes(q) ||
        a.id.toLowerCase().includes(q)
      );
    }
    return d;
  }, [search, filter]);

  if (loading) return <LoadingSpinner fullPage />;

  return (
    <div>
      {/* ── En-tête ── */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 24, flexWrap: 'wrap', gap: 12 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 800, color: colors.navy, margin: 0, fontFamily: fonts.display }}>
            Candidatures
          </h2>
          <p style={{ fontSize: 13.5, margin: '5px 0 0', color: colors.textMuted }}>
            <span style={{ fontWeight: 600, color: colors.textSecondary }}>{total}</span> dossiers au total
            {' · '}
            <span style={{ fontWeight: 600, color: colors.warning }}>{pending}</span> en attente de traitement
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10, flexShrink: 0 }}>
          <button style={{
            display: 'flex', alignItems: 'center', gap: 7,
            padding: '9px 16px', borderRadius: 9,
            border: `1.5px solid ${colors.borderInput}`,
            background: 'white', color: colors.textSecondary,
            fontWeight: 600, fontSize: 13.5, cursor: 'pointer',
            fontFamily: fonts.body, transition: 'all .15s',
          }}>
            <IconDownload /> Exporter
          </button>
          <button style={{
            display: 'flex', alignItems: 'center', gap: 7,
            padding: '9px 18px', borderRadius: 9,
            border: 'none',
            background: `linear-gradient(135deg, ${colors.navy} 0%, #1e40af 100%)`,
            color: '#fff', fontWeight: 700, fontSize: 13.5,
            cursor: 'pointer', fontFamily: fonts.body,
            boxShadow: '0 4px 12px rgba(11,24,82,0.25)',
          }}>
            <IconPlus /> Nouveau dossier
          </button>
        </div>
      </div>

      {/* ── Stats ── */}
      <div className="ap-stat-grid">
        <StatCard
          label="Total dossiers" value={total} sub="Toutes périodes"
          accent={colors.blue} iconBg="rgba(37,70,204,0.10)" iconColor={colors.blue}
          icon={<svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>}
        />
        <StatCard
          label="Validés" value={validated} sub="↑ 12% ce mois"
          accent={colors.success} iconBg="rgba(22,163,74,0.10)" iconColor={colors.success}
          icon={<svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>}
        />
        <StatCard
          label="En attente" value={pending} sub="À traiter"
          accent={colors.warning} iconBg="rgba(217,119,6,0.10)" iconColor={colors.warning}
          icon={<svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>}
        />
        <StatCard
          label="Urgents" value={urgent} sub="Deadline proche"
          accent={colors.danger} iconBg="rgba(220,38,38,0.10)" iconColor={colors.danger}
          icon={<svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>}
        />
      </div>

      {/* ── Tableau ── */}
      <div className="ap-table-card">
        {/* gradient top bar */}
        <div style={{ height: 3, background: `linear-gradient(90deg, ${colors.blue}, #7c3aed)` }} />

        {/* Toolbar */}
        <div className="ap-toolbar">
          <div className="ap-search-wrap">
            <span style={{
              position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)',
              color: colors.textMuted, display: 'flex', pointerEvents: 'none',
            }}>
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

        {/* Table */}
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
                {filtered.map(app => {
                  const [fg, bg] = avatarColor(app.student);
                  return (
                    <tr key={app.id}>
                      <td>
                        <div className="ap-student-cell">
                          <div className="ap-avatar" style={{ background: bg, color: fg }}>
                            {initials(app.student)}
                          </div>
                          <div>
                            <div style={{ fontWeight: 600, fontSize: 13.5, color: colors.textPrimary }}>
                              {app.student}
                            </div>
                            <div style={{ fontSize: 12, color: colors.textMuted }}>{app.email}</div>
                          </div>
                        </div>
                      </td>

                      <td style={{ fontWeight: 500, maxWidth: 180 }}>
                        <div style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                          {app.university}
                        </div>
                      </td>

                      <td style={{ color: colors.textSecondary, maxWidth: 160 }}>
                        <div style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                          {app.program}
                        </div>
                      </td>

                      <td>
                        <span style={{ fontSize: 13, color: colors.textSecondary }}>
                          {app.country === 'France' ? '🇫🇷' : '🇨🇦'} {app.country}
                        </span>
                      </td>

                      <td style={{ color: colors.textMuted, fontSize: 13, whiteSpace: 'nowrap' }}>
                        {new Date(app.date).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' })}
                      </td>

                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                          <div className="ap-score-bar">
                            <div className="ap-score-fill" style={{ width: `${app.score}%`, background: scoreColor(app.score) }} />
                          </div>
                          <span style={{ fontSize: 13, fontWeight: 700, color: scoreColor(app.score) }}>
                            {app.score}
                          </span>
                        </div>
                      </td>

                      <td>
                        <Badge variant={STATUS_BADGE[app.status]} dot>
                          {app.status}
                        </Badge>
                      </td>

                      <td style={{ textAlign: 'right' }}>
                        <div style={{ display: 'flex', gap: 6, justifyContent: 'flex-end' }}>
                          <button className="ap-action-btn" title="Voir le dossier">
                            <IconEye />
                          </button>
                          <button className="ap-action-btn" title="Modifier">
                            <IconEdit />
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

        {/* Footer */}
        {filtered.length > 0 && (
          <div className="ap-footer">
            <span style={{ fontSize: 13, color: colors.textMuted }}>
              {filtered.length} résultat{filtered.length > 1 ? 's' : ''} sur {total}
            </span>
            <div style={{ display: 'flex', gap: 6 }}>
              <button style={{
                padding: '6px 14px', borderRadius: 8, fontSize: 12, fontWeight: 600,
                border: `1.5px solid ${colors.borderInput}`, background: 'white',
                color: colors.textSecondary, cursor: 'pointer', fontFamily: fonts.body,
              }}>
                ← Précédent
              </button>
              <button style={{
                padding: '6px 14px', borderRadius: 8, fontSize: 12, fontWeight: 600,
                border: `1.5px solid ${colors.borderInput}`, background: 'white',
                color: colors.textSecondary, cursor: 'pointer', fontFamily: fonts.body,
              }}>
                Suivant →
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

/* ─── Icons ──────────────────────────────────────────────────────────────── */
function IconPlus()     { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>; }
function IconDownload() { return <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>; }
function IconSearch()   { return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>; }
function IconEye()      { return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>; }
function IconEdit()     { return <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>; }
