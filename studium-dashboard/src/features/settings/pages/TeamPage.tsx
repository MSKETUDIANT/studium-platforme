import { useEffect, useState, useMemo } from 'react';
import { supabase } from '../../../shared/services/supabase';
import { useRole } from '../../auth/hooks/useRole';
import { PageHeader }  from '../../../shared/components/PageHeader';
import { Pagination }  from '../../../shared/components/Pagination';
import { colors, fonts, radius, shadows } from '../../../shared/constants/theme';

interface TeamMember {
  id:         string;
  email:      string;
  role:       string;
  status:     string;
  created_at: string;
}

type SortKey = 'email' | 'role' | 'status' | 'created_at';

const ROLE_CFG: Record<string, { bg: string; color: string; label: string }> = {
  admin:      { bg: '#ede9fe', color: '#7c3aed',  label: 'Admin'      },
  manager:    { bg: '#dbeafe', color: '#1d4ed8',  label: 'Manager'    },
  admissions: { bg: '#dcfce7', color: '#15803d',  label: 'Admissions' },
  support:    { bg: '#f1f5f9', color: '#475569',  label: 'Support'    },
};

const AVATAR_PALETTE = [
  ['#2546cc', 'rgba(37,70,204,0.12)'],
  ['#7c3aed', 'rgba(124,58,237,0.12)'],
  ['#15803d', 'rgba(22,163,74,0.12)'],
  ['#d97706', 'rgba(217,119,6,0.12)'],
  ['#0891b2', 'rgba(8,145,178,0.12)'],
];
const avatarColor = (email: string) =>
  AVATAR_PALETTE[email.charCodeAt(0) % AVATAR_PALETTE.length];

const CSS = `
  .tp-stat-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
    margin-bottom: 24px;
  }
  @media (max-width: 700px) { .tp-stat-grid { grid-template-columns: 1fr; } }

  .tp-stat {
    background: white;
    border-radius: ${radius.lg}px;
    box-shadow: ${shadows.card};
    overflow: hidden;
  }
  .tp-stat-inner {
    padding: 16px 20px;
    display: flex;
    align-items: center;
    gap: 14px;
  }
  .tp-stat-icon {
    width: 46px; height: 46px;
    border-radius: 13px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }

  /* Toolbar */
  .tp-toolbar {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 16px;
    flex-wrap: wrap;
  }
  .tp-search-wrap {
    position: relative;
    flex: 1;
    min-width: 220px;
  }
  .tp-search-icon {
    position: absolute;
    left: 11px; top: 50%;
    transform: translateY(-50%);
    pointer-events: none;
    color: ${colors.textMuted};
  }
  .tp-search-input {
    width: 100%;
    border: 1.5px solid ${colors.borderInput};
    border-radius: ${radius.md}px;
    padding: 8px 34px 8px 34px;
    font-size: 13.5px;
    font-family: ${fonts.body};
    color: ${colors.textPrimary};
    background: white;
    outline: none;
    box-sizing: border-box;
    transition: border-color .18s, box-shadow .18s;
  }
  .tp-search-input:focus {
    border-color: ${colors.blue};
    box-shadow: 0 0 0 3px rgba(37,70,204,0.08);
  }
  .tp-search-input::placeholder { color: ${colors.textMuted}; }
  .tp-search-clear {
    position: absolute;
    right: 8px; top: 50%;
    transform: translateY(-50%);
    background: none; border: none;
    cursor: pointer; color: ${colors.textMuted};
    font-size: 16px; line-height: 1; padding: 2px 4px;
    border-radius: 4px; transition: color .12s, background .12s;
  }
  .tp-search-clear:hover { color: ${colors.textPrimary}; background: ${colors.inputBg}; }

  .tp-toolbar-select {
    border: 1.5px solid ${colors.borderInput};
    border-radius: ${radius.md}px;
    padding: 8px 32px 8px 12px;
    font-size: 13px;
    font-family: ${fonts.body};
    color: ${colors.textPrimary};
    background: white;
    outline: none;
    cursor: pointer;
    appearance: none;
    background-image: url("data:image/svg+xml,%3Csvg width='10' height='6' viewBox='0 0 10 6' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M1 1l4 4 4-4' stroke='%2394a3b8' stroke-width='1.5' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E");
    background-repeat: no-repeat;
    background-position: right 10px center;
    transition: border-color .18s;
  }
  .tp-toolbar-select:focus { border-color: ${colors.blue}; }
  .tp-toolbar-select--active { border-color: ${colors.blue}; color: ${colors.blue}; background-color: rgba(37,70,204,0.04); }

  .tp-filters {
    display: flex; gap: 6px; flex-wrap: wrap;
  }
  .tp-filter-btn {
    padding: 6px 14px; border-radius: 20px;
    font-size: 12px; font-weight: 600;
    border: 1.5px solid ${colors.borderInput};
    background: white; color: ${colors.textSecondary};
    cursor: pointer; transition: all .15s;
    font-family: ${fonts.body};
    white-space: nowrap;
  }
  .tp-filter-btn--active {
    background: ${colors.navy}; color: white; border-color: ${colors.navy};
  }
  .tp-filter-btn:hover:not(.tp-filter-btn--active) { border-color: ${colors.blue}; color: ${colors.blue}; }

  /* Reset filters */
  .tp-reset-btn {
    display: inline-flex; align-items: center; gap: 5px;
    padding: 6px 12px; border-radius: 8px;
    font-size: 12px; font-weight: 600;
    border: 1.5px solid #fca5a5;
    background: #fff5f5; color: #dc2626;
    cursor: pointer; font-family: ${fonts.body};
    transition: all .15s; white-space: nowrap;
  }
  .tp-reset-btn:hover { background: #fee2e2; }

  .tp-table-wrap {
    background: white;
    border-radius: ${radius.lg}px;
    box-shadow: ${shadows.card};
    overflow: hidden;
  }

  .tp-table {
    width: 100%;
    border-collapse: collapse;
    font-family: ${fonts.body};
  }

  .tp-table thead tr {
    background: linear-gradient(135deg, #f8faff 0%, ${colors.inputBg} 100%);
    border-bottom: 2px solid ${colors.border};
  }

  .tp-th {
    padding: 13px 20px;
    text-align: left;
    font-size: 11px;
    font-weight: 700;
    color: ${colors.textSecondary};
    text-transform: uppercase;
    letter-spacing: .6px;
    white-space: nowrap;
  }
  .tp-th-sort {
    cursor: pointer;
    user-select: none;
    transition: color .12s;
  }
  .tp-th-sort:hover { color: ${colors.blue}; }
  .tp-th-sort.tp-th-sort--active { color: ${colors.navy}; }
  .tp-th-sort-inner {
    display: inline-flex; align-items: center; gap: 5px;
  }
  .tp-sort-icon {
    display: inline-flex; flex-direction: column; gap: 1px;
    opacity: .35;
  }
  .tp-sort-icon--active { opacity: 1; }

  .tp-table td {
    padding: 13px 20px;
    font-size: 13.5px;
    color: ${colors.textPrimary};
    vertical-align: middle;
    border-bottom: 1px solid ${colors.border};
  }

  .tp-table tbody tr:last-child td { border-bottom: none; }
  .tp-table tbody tr { transition: background .12s; }
  .tp-table tbody tr:hover td { background: #f5f8ff; }
  .tp-table tbody tr.tp-inactive td { opacity: .55; }

  .tp-avatar {
    width: 36px; height: 36px;
    border-radius: 10px;
    display: flex; align-items: center; justify-content: center;
    font-weight: 700; font-size: 12px;
    flex-shrink: 0;
  }

  .tp-badge {
    display: inline-flex; align-items: center; gap: 5px;
    padding: 3px 10px; border-radius: 20px;
    font-size: 11.5px; font-weight: 700;
  }

  .tp-btn-act {
    display: inline-flex; align-items: center; gap: 5px;
    padding: 5px 12px; border-radius: 8px;
    font-size: 12px; font-weight: 600;
    border: 1.5px solid transparent;
    background: ${colors.inputBg};
    cursor: pointer; transition: all .15s;
    font-family: ${fonts.body}; white-space: nowrap;
  }
  .tp-btn-act:disabled { opacity: .4; cursor: not-allowed; }
  .tp-btn-disable { color: #dc2626; }
  .tp-btn-disable:hover { border-color: #dc2626; background: rgba(220,38,38,0.07); }
  .tp-btn-enable  { color: #15803d; }
  .tp-btn-enable:hover  { border-color: #15803d; background: rgba(22,163,74,0.07); }

  /* Invite form */
  .tp-form-card {
    background: white;
    border-radius: ${radius.lg}px;
    border: 1.5px solid ${colors.borderInput};
    padding: 22px 24px;
    margin-bottom: 20px;
    box-shadow: ${shadows.card};
  }
  .tp-input {
    width: 100%; border: 1.5px solid ${colors.borderInput};
    border-radius: ${radius.md}px; padding: 9px 12px;
    font-size: 13.5px; font-family: ${fonts.body};
    color: ${colors.textPrimary}; background: ${colors.inputBg};
    outline: none; box-sizing: border-box; transition: border-color .18s;
  }
  .tp-input:focus { border-color: ${colors.blue}; background: white; }
  .tp-select {
    width: 100%; border: 1.5px solid ${colors.borderInput};
    border-radius: ${radius.md}px; padding: 9px 12px;
    font-size: 13.5px; font-family: ${fonts.body};
    color: ${colors.textPrimary}; background: white;
    outline: none; box-sizing: border-box; cursor: pointer;
  }
  .tp-label {
    font-size: 11px; font-weight: 700; color: ${colors.textSecondary};
    text-transform: uppercase; letter-spacing: .5px;
    display: block; margin-bottom: 5px;
  }

  /* Alert */
  .tp-alert {
    border-radius: 10px; padding: 11px 14px; margin-bottom: 14px;
    font-size: 13.5px; display: flex; align-items: center;
    justify-content: space-between; gap: 10px;
  }
  .tp-alert--success { background: #f0fdf4; border: 1px solid #bbf7d0; color: #15803d; }
  .tp-alert--error   { background: #fef2f2; border: 1px solid #fecaca; color: #dc2626; }
  .tp-alert button   { background: none; border: none; cursor: pointer; font-size: 15px; color: inherit; opacity: .6; }
  .tp-alert button:hover { opacity: 1; }

  /* Results bar */
  .tp-results-bar {
    display: flex; align-items: center; justify-content: space-between;
    padding: 10px 20px;
    border-bottom: 1px solid ${colors.border};
    background: #fafbff;
    font-size: 12.5px;
    color: ${colors.textSecondary};
  }
  .tp-results-bar strong { color: ${colors.textPrimary}; }

  .tp-empty {
    text-align: center; padding: 52px 24px; color: ${colors.textMuted};
  }
  .tp-empty-icon {
    width: 44px; height: 44px; margin: 0 auto 12px;
    background: ${colors.inputBg}; border-radius: 14px;
    display: flex; align-items: center; justify-content: center;
  }

  .tp-stat-grid .tp-stat:nth-child(1) { animation: ph-fade-up .35s .08s ease both; }
  .tp-stat-grid .tp-stat:nth-child(2) { animation: ph-fade-up .35s .16s ease both; }
  .tp-stat-grid .tp-stat:nth-child(3) { animation: ph-fade-up .35s .24s ease both; }
  .tp-table-wrap { animation: ph-fade-up .35s .36s ease both; }
`;

export default function TeamPage() {
  const { isAdmin } = useRole();
  const [members,    setMembers]    = useState<TeamMember[]>([]);
  const [loading,    setLoading]    = useState(true);
  const [showForm,   setShowForm]   = useState(false);
  const [email,      setEmail]      = useState('');
  const [role,       setRole]       = useState('admissions');
  const [error,      setError]      = useState('');
  const [success,    setSuccess]    = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [actionId,   setActionId]   = useState<string | null>(null);
  const [filter,     setFilter]     = useState<'all' | 'active' | 'inactive'>('all');
  const [search,     setSearch]     = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [sortBy,     setSortBy]     = useState<SortKey>('created_at');
  const [sortDir,    setSortDir]    = useState<'asc' | 'desc'>('desc');
  const [page,       setPage]       = useState(1);
  const [pageSize,   setPageSize]   = useState(10);

  useEffect(() => { fetchMembers(); }, []);
  useEffect(() => { setPage(1); }, [filter, search, roleFilter, sortBy, sortDir]);

  async function fetchMembers() {
    setLoading(true);
    const { data } = await supabase.rpc('get_team_members');
    if (data) setMembers(data);
    setLoading(false);
  }

  async function inviteMember() {
    if (!email) { setError('Email requis.'); return; }
    setError(''); setSubmitting(true);
    try {
      const { data, error: invokeError } = await supabase.functions.invoke('create-team-member', {
        body: { email, role },
      });
      if (invokeError) throw new Error(data?.error ?? invokeError.message ?? 'Erreur inconnue');
      setSuccess(`Invitation envoyée à ${email}.`);
      setEmail(''); setRole('admissions'); setShowForm(false);
      fetchMembers();
    } catch (e: any) {
      setError(e.message ?? 'Erreur lors de l\'invitation');
    } finally { setSubmitting(false); }
  }

  async function disableMember(id: string, memberEmail: string) {
    if (!confirm(`Désactiver le compte de ${memberEmail} ?`)) return;
    setActionId(id);
    try {
      await supabase.rpc('update_member_status', { target_user_id: id, new_status: 'inactive' });
      setSuccess(`Compte ${memberEmail} désactivé.`);
      fetchMembers();
    } catch (e: any) {
      setError(e.message ?? 'Erreur');
    } finally { setActionId(null); }
  }

  async function reactivateMember(id: string, memberEmail: string) {
    if (!confirm(`Réactiver le compte de ${memberEmail} ?`)) return;
    setActionId(id);
    try {
      await supabase.rpc('update_member_status', { target_user_id: id, new_status: 'active' });
      setSuccess(`Compte ${memberEmail} réactivé.`);
      fetchMembers();
    } catch (e: any) {
      setError(e.message ?? 'Erreur');
    } finally { setActionId(null); }
  }

  function toggleSort(col: SortKey) {
    if (sortBy === col) setSortDir(d => d === 'asc' ? 'desc' : 'asc');
    else { setSortBy(col); setSortDir('asc'); }
  }

  const activeCount   = members.filter(m => m.status === 'active').length;
  const inactiveCount = members.filter(m => m.status === 'inactive').length;

  const filteredMembers = useMemo(() => {
    const q = search.trim().toLowerCase();
    return members
      .filter(m => filter === 'all' ? true : m.status === filter)
      .filter(m => !roleFilter || m.role === roleFilter)
      .filter(m => !q || m.email.toLowerCase().includes(q))
      .sort((a, b) => {
        const va = a[sortBy] ?? '';
        const vb = b[sortBy] ?? '';
        const cmp = va < vb ? -1 : va > vb ? 1 : 0;
        return sortDir === 'asc' ? cmp : -cmp;
      });
  }, [members, filter, roleFilter, search, sortBy, sortDir]);

  const totalPages = Math.max(1, Math.ceil(filteredMembers.length / pageSize));
  const paginated  = filteredMembers.slice((page - 1) * pageSize, page * pageSize);

  const hasActiveFilters = !!(search || roleFilter || filter !== 'all');

  function resetAllFilters() {
    setSearch(''); setRoleFilter(''); setFilter('all');
  }

  const fmtDate = (d: string) =>
    new Date(d).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' });

  function SortTh({ col, label, right }: { col: SortKey; label: string; right?: boolean }) {
    const active = sortBy === col;
    return (
      <th
        className={`tp-th tp-th-sort${active ? ' tp-th-sort--active' : ''}`}
        style={{ textAlign: right ? 'right' : 'left' }}
        onClick={() => toggleSort(col)}
      >
        <span className="tp-th-sort-inner">
          {label}
          <span className={`tp-sort-icon${active ? ' tp-sort-icon--active' : ''}`}>
            {active && sortDir === 'asc' ? (
              <svg width={10} height={10} viewBox="0 0 10 10" fill="none">
                <path d="M5 2L9 8H1L5 2Z" fill="currentColor"/>
              </svg>
            ) : active && sortDir === 'desc' ? (
              <svg width={10} height={10} viewBox="0 0 10 10" fill="none">
                <path d="M5 8L1 2H9L5 8Z" fill="currentColor"/>
              </svg>
            ) : (
              <svg width={10} height={12} viewBox="0 0 10 12" fill="none">
                <path d="M5 1L9 5H1L5 1Z" fill="currentColor" opacity=".4"/>
                <path d="M5 11L1 7H9L5 11Z" fill="currentColor" opacity=".4"/>
              </svg>
            )}
          </span>
        </span>
      </th>
    );
  }

  if (!isAdmin) return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 200 }}>
      <div style={{ background: '#fef2f2', border: '1px solid #fecaca', borderRadius: 12, padding: '20px 32px', textAlign: 'center' }}>
        <p style={{ color: '#dc2626', fontWeight: 600, display: 'flex', alignItems: 'center', gap: 8 }}>
          <svg width={16} height={16} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>
          </svg>
          Accès réservé à l'administrateur
        </p>
      </div>
    </div>
  );

  return (
    <>
      <style>{CSS}</style>

      <PageHeader
        title="Membres de l'équipe"
        subtitle={`${activeCount} actif${activeCount !== 1 ? 's' : ''}${inactiveCount > 0 ? ` · ${inactiveCount} inactif${inactiveCount !== 1 ? 's' : ''}` : ''}`}
        actions={
          <button
            onClick={() => { setShowForm(v => !v); setError(''); setSuccess(''); }}
            style={{
              background: 'rgba(255,255,255,0.15)',
              color: '#fff', border: '1.5px solid rgba(255,255,255,0.3)', borderRadius: 10,
              padding: '10px 20px', fontWeight: 700, fontSize: 14,
              cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 8,
              fontFamily: fonts.body, transition: 'background .15s',
            }}
          >
            <svg width={14} height={14} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
              <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Inviter un membre
          </button>
        }
      />

      {/* Stats */}
      <div className="tp-stat-grid">
        {[
          {
            label: 'Total membres', value: members.length,
            accent: colors.blue, iconBg: 'rgba(37,70,204,0.12)', iconColor: colors.blue,
            icon: (
              <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                <circle cx="9" cy="7" r="4"/>
                <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
              </svg>
            ),
          },
          {
            label: 'Membres actifs', value: activeCount,
            accent: colors.success, iconBg: 'rgba(22,163,74,0.12)', iconColor: colors.success,
            icon: (
              <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
                <polyline points="22 4 12 14.01 9 11.01"/>
              </svg>
            ),
          },
          {
            label: 'Comptes inactifs', value: inactiveCount,
            accent: '#dc2626', iconBg: 'rgba(220,38,38,0.12)', iconColor: '#dc2626',
            icon: (
              <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                <circle cx="12" cy="12" r="10"/>
                <line x1="8" y1="12" x2="16" y2="12"/>
              </svg>
            ),
          },
        ].map(s => (
          <div key={s.label} className="tp-stat">
            <div style={{ height: 3, background: s.accent }} />
            <div className="tp-stat-inner">
              <div className="tp-stat-icon" style={{ background: s.iconBg, color: s.iconColor }}>
                {s.icon}
              </div>
              <div>
                <div style={{ fontSize: 26, fontWeight: 800, color: s.accent, fontFamily: fonts.display, lineHeight: 1 }}>
                  {s.value}
                </div>
                <div style={{ fontSize: 12, color: colors.textMuted, marginTop: 4, fontWeight: 500 }}>{s.label}</div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Alerts */}
      {success && (
        <div className="tp-alert tp-alert--success">
          <span style={{ display:'flex', alignItems:'center', gap:6 }}>
            <svg width={16} height={16} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
            </svg>
            {success}
          </span>
          <button onClick={() => setSuccess('')}>&times;</button>
        </div>
      )}
      {error && (
        <div className="tp-alert tp-alert--error">
          <span style={{ display:'flex', alignItems:'center', gap:6 }}>
            <svg width={16} height={16} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
            </svg>
            {error}
          </span>
          <button onClick={() => setError('')}>&times;</button>
        </div>
      )}

      {/* Invite form */}
      {showForm && (
        <div className="tp-form-card">
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
            <h3 style={{ fontSize: 15, fontWeight: 700, color: colors.navy, margin: 0, fontFamily: fonts.display }}>
              Inviter un nouveau membre
            </h3>
            <button onClick={() => { setShowForm(false); setError(''); }}
              style={{ background: 'none', border: 'none', cursor: 'pointer', color: colors.textMuted, fontSize: 18 }}>
              &times;
            </button>
          </div>
          <div style={{ background: '#eff6ff', border: '1px solid #bfdbfe', borderRadius: 8, padding: '10px 14px', marginBottom: 16, fontSize: 13, color: '#1d4ed8', display: 'flex', alignItems: 'flex-start', gap: 8 }}>
            <svg width={15} height={15} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} style={{ flexShrink: 0, marginTop: 1 }}>
              <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
              <polyline points="22,6 12,13 2,6"/>
            </svg>
            <span>La personne recevra un email pour définir son mot de passe.</span>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14, marginBottom: 16 }}>
            <div>
              <label className="tp-label">Email</label>
              <input className="tp-input" type="email" placeholder="prenom@studium.com"
                value={email} onChange={e => setEmail(e.target.value)} />
            </div>
            <div>
              <label className="tp-label">Rôle</label>
              <select className="tp-select" value={role} onChange={e => setRole(e.target.value)}>
                <option value="admissions">Admissions</option>
                <option value="support">Support</option>
                <option value="manager">Manager</option>
                <option value="admin">Admin</option>
              </select>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 10 }}>
            <button onClick={inviteMember} disabled={submitting}
              style={{
                background: submitting ? colors.textMuted : `linear-gradient(135deg, ${colors.navy}, #1e40af)`,
                color: '#fff', border: 'none', borderRadius: 9,
                padding: '9px 20px', fontWeight: 700, fontSize: 13.5,
                cursor: submitting ? 'not-allowed' : 'pointer',
                fontFamily: fonts.body, display: 'flex', alignItems: 'center', gap: 7,
              }}>
              <svg width={14} height={14} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/>
              </svg>
              {submitting ? 'Envoi...' : "Envoyer l'invitation"}
            </button>
            <button onClick={() => { setShowForm(false); setError(''); }}
              style={{ background: 'white', color: colors.textSecondary, border: `1.5px solid ${colors.borderInput}`, borderRadius: 9, padding: '9px 18px', fontWeight: 500, fontSize: 13.5, cursor: 'pointer', fontFamily: fonts.body }}>
              Annuler
            </button>
          </div>
        </div>
      )}

      {/* Toolbar: search + role filter + status filters */}
      <div className="tp-toolbar">
        {/* Search */}
        <div className="tp-search-wrap">
          <span className="tp-search-icon">
            <svg width={15} height={15} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
              <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
          </span>
          <input
            type="text"
            className="tp-search-input"
            placeholder="Rechercher par email..."
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
          {search && (
            <button className="tp-search-clear" onClick={() => setSearch('')} title="Effacer">&times;</button>
          )}
        </div>

        {/* Role filter */}
        <select
          className={`tp-toolbar-select${roleFilter ? ' tp-toolbar-select--active' : ''}`}
          value={roleFilter}
          onChange={e => setRoleFilter(e.target.value)}
        >
          <option value="">Tous les rôles</option>
          <option value="admin">Admin</option>
          <option value="manager">Manager</option>
          <option value="admissions">Admissions</option>
          <option value="support">Support</option>
        </select>

        {/* Status filter pills */}
        <div className="tp-filters">
          {([
            { key: 'all',      label: `Tous (${members.length})`    },
            { key: 'active',   label: `Actifs (${activeCount})`     },
            { key: 'inactive', label: `Inactifs (${inactiveCount})` },
          ] as const).map(f => (
            <button
              key={f.key}
              className={`tp-filter-btn${filter === f.key ? ' tp-filter-btn--active' : ''}`}
              onClick={() => setFilter(f.key)}
            >
              {f.label}
            </button>
          ))}
        </div>

        {/* Reset */}
        {hasActiveFilters && (
          <button className="tp-reset-btn" onClick={resetAllFilters}>
            <svg width={12} height={12} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
            Réinitialiser
          </button>
        )}
      </div>

      {/* Table */}
      <div className="tp-table-wrap">
        <div style={{ height: 3, background: `linear-gradient(90deg, ${colors.blue}, #7c3aed)` }} />

        {/* Results info */}
        {!loading && (
          <div className="tp-results-bar">
            <span>
              <strong>{filteredMembers.length}</strong> membre{filteredMembers.length !== 1 ? 's' : ''}
              {hasActiveFilters && ' · filtrés'}
            </span>
            {hasActiveFilters && (
              <span style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                {search && (
                  <span style={{ background: 'rgba(37,70,204,0.08)', color: colors.blue, borderRadius: 6, padding: '2px 8px', fontSize: 11.5, fontWeight: 600 }}>
                    "{search}"
                  </span>
                )}
                {roleFilter && (
                  <span style={{ background: 'rgba(37,70,204,0.08)', color: colors.blue, borderRadius: 6, padding: '2px 8px', fontSize: 11.5, fontWeight: 600 }}>
                    {ROLE_CFG[roleFilter]?.label ?? roleFilter}
                  </span>
                )}
                {filter !== 'all' && (
                  <span style={{ background: 'rgba(37,70,204,0.08)', color: colors.blue, borderRadius: 6, padding: '2px 8px', fontSize: 11.5, fontWeight: 600 }}>
                    {filter === 'active' ? 'Actifs' : 'Inactifs'}
                  </span>
                )}
              </span>
            )}
          </div>
        )}

        <table className="tp-table">
          <thead>
            <tr>
              <SortTh col="email"      label="Membre"   />
              <SortTh col="role"       label="Rôle"     />
              <SortTh col="status"     label="Statut"   />
              <SortTh col="created_at" label="Créé le"  />
              <th className="tp-th" style={{ textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={5} style={{ textAlign: 'center', padding: 48, color: colors.textMuted }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
                    <svg width={16} height={16} fill="none" viewBox="0 0 24 24" stroke={colors.blue} strokeWidth={2} style={{ animation: 'spin 1s linear infinite' }}>
                      <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4"/>
                    </svg>
                    Chargement...
                  </div>
                </td>
              </tr>
            ) : paginated.length === 0 ? (
              <tr>
                <td colSpan={5}>
                  <div className="tp-empty">
                    <div className="tp-empty-icon">
                      <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke={colors.textMuted} strokeWidth={1.5}>
                        <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
                      </svg>
                    </div>
                    <div style={{ fontWeight: 600, marginBottom: 4, color: colors.textSecondary }}>Aucun membre trouvé</div>
                    <div style={{ fontSize: 12.5 }}>
                      {hasActiveFilters ? 'Essayez de modifier vos filtres ou votre recherche.' : 'Aucun membre dans cette équipe.'}
                    </div>
                    {hasActiveFilters && (
                      <button className="tp-reset-btn" style={{ margin: '12px auto 0' }} onClick={resetAllFilters}>
                        Réinitialiser les filtres
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ) : paginated.map(m => {
              const [fg, bg] = avatarColor(m.email);
              const roleCfg = ROLE_CFG[m.role] ?? { bg: '#f1f5f9', color: '#475569', label: m.role };
              const isInactive = m.status === 'inactive';
              return (
                <tr key={m.id} className={isInactive ? 'tp-inactive' : ''}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                      <div className="tp-avatar" style={{ background: bg, color: fg }}>
                        {m.email.slice(0, 2).toUpperCase()}
                      </div>
                      <span style={{ fontWeight: 600, fontSize: 13.5, color: colors.textPrimary }}>
                        {m.email}
                      </span>
                    </div>
                  </td>
                  <td>
                    <span className="tp-badge" style={{ background: roleCfg.bg, color: roleCfg.color }}>
                      {roleCfg.label}
                    </span>
                  </td>
                  <td>
                    <span className="tp-badge" style={{
                      background: isInactive ? colors.inputBg : 'rgba(22,163,74,0.10)',
                      color:      isInactive ? colors.textMuted : colors.success,
                    }}>
                      <span style={{
                        width: 6, height: 6, borderRadius: '50%',
                        background: isInactive ? colors.textMuted : colors.success,
                        display: 'inline-block',
                      }} />
                      {isInactive ? 'Inactif' : 'Actif'}
                    </span>
                  </td>
                  <td style={{ color: colors.textSecondary, fontSize: 13 }}>
                    {fmtDate(m.created_at)}
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    {isInactive ? (
                      <button
                        className="tp-btn-act tp-btn-enable"
                        disabled={actionId === m.id}
                        onClick={() => reactivateMember(m.id, m.email)}
                      >
                        <svg width={12} height={12} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                          <polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>
                        </svg>
                        {actionId === m.id ? '...' : 'Réactiver'}
                      </button>
                    ) : (
                      <button
                        className="tp-btn-act tp-btn-disable"
                        disabled={actionId === m.id}
                        onClick={() => disableMember(m.id, m.email)}
                      >
                        <svg width={12} height={12} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                          <circle cx="12" cy="12" r="10"/><line x1="8" y1="12" x2="16" y2="12"/>
                        </svg>
                        {actionId === m.id ? '...' : 'Désactiver'}
                      </button>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>

        <Pagination
          page={page}
          totalPages={totalPages}
          total={filteredMembers.length}
          pageSize={pageSize}
          onChange={setPage}
          onPageSizeChange={size => { setPageSize(size); setPage(1); }}
          label="membres"
        />
      </div>
    </>
  );
}
