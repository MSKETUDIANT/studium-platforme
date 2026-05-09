import { useEffect, useState } from 'react';
import { supabase } from '../../../shared/services/supabase';
import { useRole } from '../../auth/hooks/useRole';
import { colors, fonts, radius, shadows } from '../../../shared/constants/theme';

interface TeamMember {
  id:         string;
  email:      string;
  role:       string;
  status:     string;
  created_at: string;
}

/* ─── Config ─────────────────────────────────────────────────────────────── */
const PAGE_SIZE = 8;

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

/* ─── CSS ────────────────────────────────────────────────────────────────── */
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

  .tp-table th {
    padding: 13px 20px;
    text-align: left;
    font-size: 11px;
    font-weight: 700;
    color: ${colors.textSecondary};
    text-transform: uppercase;
    letter-spacing: .6px;
    white-space: nowrap;
  }

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

  /* Filters */
  .tp-filters {
    display: flex; gap: 6px; margin-bottom: 16px;
  }
  .tp-filter-btn {
    padding: 6px 16px; border-radius: 20px;
    font-size: 12px; font-weight: 600;
    border: 1.5px solid ${colors.borderInput};
    background: white; color: ${colors.textSecondary};
    cursor: pointer; transition: all .15s;
    font-family: ${fonts.body};
  }
  .tp-filter-btn--active {
    background: ${colors.navy}; color: white; border-color: ${colors.navy};
  }
  .tp-filter-btn:hover:not(.tp-filter-btn--active) { border-color: ${colors.blue}; color: ${colors.blue}; }

  /* Pagination */
  .tp-pagination {
    display: flex; align-items: center; justify-content: space-between;
    padding: 12px 20px;
    border-top: 1px solid ${colors.border};
    background: #fafbff;
  }
  .tp-page-btn {
    display: inline-flex; align-items: center; gap: 5px;
    padding: 6px 12px; border-radius: 8px;
    font-size: 12px; font-weight: 600;
    border: 1.5px solid ${colors.borderInput};
    background: white; color: ${colors.textSecondary};
    cursor: pointer; transition: all .15s;
    font-family: ${fonts.body};
  }
  .tp-page-btn:disabled { opacity: .4; cursor: not-allowed; }
  .tp-page-btn:hover:not(:disabled) { border-color: ${colors.blue}; color: ${colors.blue}; }
  .tp-page-num {
    display: inline-flex; align-items: center; justify-content: center;
    width: 30px; height: 30px; border-radius: 7px;
    font-size: 12.5px; font-weight: 600;
    border: 1.5px solid ${colors.borderInput};
    background: white; color: ${colors.textSecondary};
    cursor: pointer; transition: all .15s;
    font-family: ${fonts.body};
  }
  .tp-page-num--active {
    background: ${colors.blue}; color: white; border-color: ${colors.blue};
  }
  .tp-page-num:hover:not(.tp-page-num--active) { border-color: ${colors.blue}; color: ${colors.blue}; }

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
`;

/* ─── Page ───────────────────────────────────────────────────────────────── */
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
  const [page,       setPage]       = useState(1);

  useEffect(() => { fetchMembers(); }, []);
  useEffect(() => { setPage(1); }, [filter]);

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

  const activeCount   = members.filter(m => m.status === 'active').length;
  const inactiveCount = members.filter(m => m.status === 'inactive').length;

  const filteredMembers = members.filter(m =>
    filter === 'all' ? true : m.status === filter
  );

  const totalPages = Math.max(1, Math.ceil(filteredMembers.length / PAGE_SIZE));
  const paginated  = filteredMembers.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  const fmtDate = (d: string) =>
    new Date(d).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' });

  if (!isAdmin) return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: 200 }}>
      <div style={{ background: '#fef2f2', border: '1px solid #fecaca', borderRadius: 12, padding: '20px 32px', textAlign: 'center' }}>
        <p style={{ color: '#dc2626', fontWeight: 600 }}>🔒 Accès réservé à l'administrateur</p>
      </div>
    </div>
  );

  return (
    <>
      <style>{CSS}</style>

      {/* ── Header ── */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 800, color: colors.navy, margin: 0, fontFamily: fonts.display }}>
            Membres de l'équipe
          </h2>
          <p style={{ fontSize: 13.5, margin: '5px 0 0', color: colors.textMuted }}>
            <span style={{ color: colors.success, fontWeight: 700 }}>{activeCount} actif{activeCount !== 1 ? 's' : ''}</span>
            {inactiveCount > 0 && (
              <span style={{ color: '#dc2626', marginLeft: 8, fontWeight: 600 }}>
                · {inactiveCount} inactif{inactiveCount !== 1 ? 's' : ''}
              </span>
            )}
          </p>
        </div>
        <button
          onClick={() => { setShowForm(v => !v); setError(''); setSuccess(''); }}
          style={{
            background: `linear-gradient(135deg, ${colors.navy} 0%, #1e40af 100%)`,
            color: '#fff', border: 'none', borderRadius: 10,
            padding: '10px 20px', fontWeight: 700, fontSize: 14,
            cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 8,
            fontFamily: fonts.body,
            boxShadow: '0 4px 12px rgba(11,24,82,0.25)',
            transition: 'transform .15s, box-shadow .15s',
          }}
        >
          <svg width={14} height={14} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
            <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
          </svg>
          Inviter un membre
        </button>
      </div>

      {/* ── Stats ── */}
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

      {/* ── Alerts ── */}
      {success && (
        <div className="tp-alert tp-alert--success">
          <span>✅ {success}</span>
          <button onClick={() => setSuccess('')}>✕</button>
        </div>
      )}
      {error && (
        <div className="tp-alert tp-alert--error">
          <span>⚠️ {error}</span>
          <button onClick={() => setError('')}>✕</button>
        </div>
      )}

      {/* ── Formulaire invitation ── */}
      {showForm && (
        <div className="tp-form-card">
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
            <h3 style={{ fontSize: 15, fontWeight: 700, color: colors.navy, margin: 0, fontFamily: fonts.display }}>
              Inviter un nouveau membre
            </h3>
            <button onClick={() => { setShowForm(false); setError(''); }}
              style={{ background: 'none', border: 'none', cursor: 'pointer', color: colors.textMuted, fontSize: 18 }}>
              ✕
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
              {submitting ? 'Envoi...' : 'Envoyer l\'invitation'}
            </button>
            <button onClick={() => { setShowForm(false); setError(''); }}
              style={{ background: 'white', color: colors.textSecondary, border: `1.5px solid ${colors.borderInput}`, borderRadius: 9, padding: '9px 18px', fontWeight: 500, fontSize: 13.5, cursor: 'pointer', fontFamily: fonts.body }}>
              Annuler
            </button>
          </div>
        </div>
      )}

      {/* ── Filtres ── */}
      <div className="tp-filters">
        {([
          { key: 'all',      label: `Tous (${members.length})`          },
          { key: 'active',   label: `Actifs (${activeCount})`           },
          { key: 'inactive', label: `Inactifs (${inactiveCount})`       },
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

      {/* ── Table ── */}
      <div className="tp-table-wrap">
        <div style={{ height: 3, background: `linear-gradient(90deg, ${colors.blue}, #7c3aed)` }} />
        <table className="tp-table">
          <thead>
            <tr>
              <th>Membre</th>
              <th>Rôle</th>
              <th>Statut</th>
              <th>Créé le</th>
              <th style={{ textAlign: 'right' }}>Actions</th>
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
                <td colSpan={5} style={{ textAlign: 'center', padding: 48, color: colors.textMuted }}>
                  Aucun membre trouvé
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

        {/* ── Pagination ── */}
        {totalPages > 1 && (
          <div className="tp-pagination">
            <span style={{ fontSize: 13, color: colors.textMuted }}>
              {(page - 1) * PAGE_SIZE + 1}–{Math.min(page * PAGE_SIZE, filteredMembers.length)} sur {filteredMembers.length} membres
            </span>
            <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
              <button
                className="tp-page-btn"
                disabled={page === 1}
                onClick={() => setPage(p => p - 1)}
              >
                <svg width={12} height={12} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                  <polyline points="15 18 9 12 15 6"/>
                </svg>
                Précédent
              </button>
              {Array.from({ length: totalPages }, (_, i) => i + 1).map(p => (
                <button
                  key={p}
                  className={`tp-page-num${p === page ? ' tp-page-num--active' : ''}`}
                  onClick={() => setPage(p)}
                >
                  {p}
                </button>
              ))}
              <button
                className="tp-page-btn"
                disabled={page === totalPages}
                onClick={() => setPage(p => p + 1)}
              >
                Suivant
                <svg width={12} height={12} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                  <polyline points="9 18 15 12 9 6"/>
                </svg>
              </button>
            </div>
          </div>
        )}
      </div>
    </>
  );
}
