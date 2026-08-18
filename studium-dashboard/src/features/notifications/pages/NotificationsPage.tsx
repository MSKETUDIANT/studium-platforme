import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase }    from '../../../shared/services/supabase';
import { PageHeader }  from '../../../shared/components/PageHeader';
import { colors, fonts } from '../../../shared/constants/theme';

/*  Types  */
interface UnreadConv {
  id:        string;
  updatedAt: string;
  count:     number;
  student:   string;
  preview:   string;
}

interface PendingApp {
  id:          string;
  student:     string;
  program:     string | null;
  university:  string | null;
  status:      string;
  submittedAt: string;
}

interface UrgentTask {
  id:       string;
  title:    string;
  dueDate:  string;
  priority: string;
  status:   string;
  student:  string;
  appId:    string | null;
}

/*  Helpers  */
const STATUS_FR: Record<string, string> = {
  draft:            'Brouillon',
  submitted:        'En attente',
  needsfix:         'Correction demandée',
  verified:         'Vérifiée',
  sent:             'Envoyée',
  accepted:         'Acceptée',
  rejected:         'Refusée',
  pending_decision: 'En attente décision',
  archived:         'Archivée',
};

const STATUS_COLOR: Record<string, { bg: string; color: string }> = {
  submitted:        { bg: '#eff6ff', color: '#2563eb' },
  needsfix:         { bg: '#fff7ed', color: '#d97706' },
  verified:         { bg: '#f0fdf4', color: '#16a34a' },
  sent:             { bg: '#eff6ff', color: '#2546cc' },
  accepted:         { bg: '#f0fdf4', color: '#15803d' },
  rejected:         { bg: '#fef2f2', color: '#dc2626' },
  pending_decision: { bg: '#fefce8', color: '#b45309' },
  archived:         { bg: '#f9fafb', color: '#6b7280' },
};

const PRIORITY_COLOR: Record<string, { bg: string; color: string }> = {
  urgent: { bg: '#fef2f2', color: '#dc2626' },
  normal: { bg: '#eff6ff', color: '#2563eb' },
  low:    { bg: '#f9fafb', color: '#6b7280' },
};

const fmtTime = (iso: string) => {
  const d    = new Date(iso);
  const now  = new Date();
  const diff = Math.floor((now.getTime() - d.getTime()) / 60000);
  if (diff < 1)  return 'A l\'instant';
  if (diff < 60) return `Il y a ${diff} min`;
  const h = Math.floor(diff / 60);
  if (h < 24)   return `Il y a ${h}h`;
  const days = Math.floor(h / 24);
  if (days === 1) return 'Hier';
  if (days < 7)   return `Il y a ${days} jours`;
  return d.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit' });
};

const fmtDate = (iso: string) => {
  const d   = new Date(iso);
  const now = new Date();
  now.setHours(0, 0, 0, 0);
  d.setHours(0, 0, 0, 0);
  const diff = Math.floor((d.getTime() - now.getTime()) / 86400000);
  if (diff < 0)  return { label: `En retard de ${Math.abs(diff)} j`, overdue: true };
  if (diff === 0) return { label: 'Aujourd\'hui', overdue: false };
  if (diff === 1) return { label: 'Demain', overdue: false };
  return { label: `Dans ${diff} j`, overdue: false };
};

const studentInitials = (name: string) =>
  name.split(' ').map(w => w[0] ?? '').join('').slice(0, 2).toUpperCase() || '?';

const AVATAR_COLORS = [
  ['#2546cc', 'rgba(37,70,204,0.10)'],
  ['#7c3aed', 'rgba(124,58,237,0.10)'],
  ['#16a34a', 'rgba(22,163,74,0.10)'],
  ['#d97706', 'rgba(217,119,6,0.10)'],
  ['#0891b2', 'rgba(8,145,178,0.10)'],
];
const avatarColor = (name: string) => AVATAR_COLORS[name.charCodeAt(0) % AVATAR_COLORS.length];

/*  CSS  */
const CSS = `
  .np-section { margin-bottom: 28px; }
  .np-section-head {
    display: flex; align-items: center; gap: 10px;
    margin-bottom: 12px;
  }
  .np-section-title {
    font-family: ${fonts.display}; font-size: 14px; font-weight: 800;
    color: ${colors.navy}; letter-spacing: -.2px;
  }
  .np-section-count {
    min-width: 20px; height: 20px; border-radius: 10px;
    background: ${colors.blue}; color: white;
    font-size: 10.5px; font-weight: 700;
    display: flex; align-items: center; justify-content: center;
    padding: 0 5px;
  }
  .np-section-count--warn { background: #f59e0b; }
  .np-section-count--danger { background: #ef4444; }
  .np-section-action {
    margin-left: auto; background: none; border: none;
    font-size: 12px; font-weight: 600; color: ${colors.blue};
    cursor: pointer; font-family: ${fonts.body}; padding: 0;
    transition: opacity .15s;
  }
  .np-section-action:hover { opacity: .7; }

  .np-card {
    background: white; border-radius: 12px;
    border: 1px solid ${colors.border};
    box-shadow: 0 1px 3px rgba(11,24,82,0.04);
    overflow: hidden;
  }
  .np-item {
    display: flex; align-items: center; gap: 12px;
    padding: 13px 16px; border-bottom: 1px solid ${colors.border};
    cursor: pointer; transition: background .12s;
  }
  .np-item:last-child { border-bottom: none; }
  .np-item:hover { background: rgba(37,70,204,0.025); }

  .np-avatar {
    width: 38px; height: 38px; border-radius: 10px;
    display: flex; align-items: center; justify-content: center;
    font-family: ${fonts.display}; font-size: 12px; font-weight: 700;
    flex-shrink: 0;
  }
  .np-icon-box {
    width: 38px; height: 38px; border-radius: 10px;
    display: flex; align-items: center; justify-content: center;
    flex-shrink: 0;
  }

  .np-item-body { flex: 1; min-width: 0; }
  .np-item-top {
    display: flex; align-items: center; gap: 8px;
    justify-content: space-between;
  }
  .np-item-name {
    font-size: 13px; font-weight: 700; color: ${colors.textPrimary};
    overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  }
  .np-item-time {
    font-size: 11px; color: ${colors.textMuted}; flex-shrink: 0;
  }
  .np-item-sub {
    font-size: 12px; color: ${colors.textMuted}; margin-top: 2px;
    overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  }

  .np-chip {
    display: inline-flex; align-items: center;
    padding: 2px 8px; border-radius: 20px;
    font-size: 11px; font-weight: 700;
  }
  .np-chip--unread {
    min-width: 18px; height: 18px; border-radius: 9px;
    background: ${colors.blue}; color: white;
    font-size: 10px; font-weight: 700;
    display: flex; align-items: center; justify-content: center;
    padding: 0 4px; flex-shrink: 0;
  }

  .np-empty {
    padding: 32px 20px; text-align: center;
    font-size: 13px; color: ${colors.textMuted};
    background: white; border-radius: 12px;
    border: 1px solid ${colors.border};
  }

  .np-tabs {
    display: flex; gap: 4px; margin-bottom: 20px;
    background: white; border-radius: 10px; padding: 4px;
    border: 1px solid ${colors.border};
    width: fit-content;
  }
  .np-tab {
    padding: 6px 14px; border-radius: 7px; border: none;
    font-size: 12.5px; font-weight: 600; cursor: pointer;
    font-family: ${fonts.body}; color: ${colors.textSecondary};
    background: transparent; transition: all .15s;
    display: flex; align-items: center; gap: 6px;
  }
  .np-tab--active {
    background: ${colors.blue}; color: white;
  }
  .np-tab:not(.np-tab--active):hover { background: rgba(37,70,204,0.06); color: ${colors.blue}; }
`;

/*  Composant principal  */
export default function NotificationsPage() {
  const navigate = useNavigate();
  const [tab,       setTab]       = useState<'all' | 'messages' | 'pending' | 'tasks'>('all');
  const [convs,     setConvs]     = useState<UnreadConv[]>([]);
  const [pending,   setPending]   = useState<PendingApp[]>([]);
  const [tasks,     setTasks]     = useState<UrgentTask[]>([]);
  const [loading,   setLoading]   = useState(true);
  const [markingRead, setMarkingRead] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);

    const in7days = new Date(Date.now() + 7 * 86400000).toISOString().split('T')[0];

    const [convRes, pendingRes, taskRes] = await Promise.all([
      // 1. Messages non-lus
      supabase
        .from('conversations')
        .select(`
          id, updated_at, unread_staff,
          student_profiles!student_profile_id(first_name, last_name),
          messages(content, created_at, sender_type)
        `)
        .gt('unread_staff', 0)
        .order('updated_at', { ascending: false }),

      // 2. Candidatures à traiter (submitted + needsfix, les plus anciennes d'abord)
      supabase
        .from('applications')
        .select(`
          id, status, submitted_at,
          student_profiles!student_profile_id(first_name, last_name),
          programs!program_id(program_name, university_name)
        `)
        .in('status', ['submitted', 'needsfix'])
        .order('submitted_at', { ascending: true })
        .limit(30),

      // 3. Tâches urgentes/en retard (dans les 7 prochains jours ou déjà en retard)
      supabase
        .from('tasks')
        .select(`
          id, title, due_date, priority, status, task_type,
          applications!application_id(
            id,
            student_profiles!student_profile_id(first_name, last_name)
          )
        `)
        .neq('status', 'done')
        .not('due_date', 'is', null)
        .lte('due_date', in7days)
        .order('due_date', { ascending: true })
        .limit(20),
    ]);

    // Mapper conversations
    if (convRes.data) {
      setConvs(convRes.data.map((c: any) => {
        const sp   = c.student_profiles;
        const msgs: any[] = (c.messages ?? []).filter((m: any) => m.sender_type === 'student');
        const last = msgs.sort((a: any, b: any) =>
          new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
        )[0];
        return {
          id:        c.id,
          updatedAt: c.updated_at,
          count:     c.unread_staff ?? 0,
          student:   [sp?.first_name, sp?.last_name].filter(Boolean).join(' ') || 'Etudiant',
          preview:   last?.content ?? '',
        };
      }));
    }

    // Mapper candidatures à traiter
    if (pendingRes.data) {
      setPending(pendingRes.data.map((a: any) => {
        const sp = a.student_profiles;
        const pg = a.programs;
        return {
          id:          a.id,
          student:     [sp?.first_name, sp?.last_name].filter(Boolean).join(' ') || 'Etudiant',
          program:     pg?.program_name    ?? null,
          university:  pg?.university_name ?? null,
          status:      a.status,
          submittedAt: a.submitted_at,
        };
      }));
    }

    // Mapper tâches
    if (taskRes.data) {
      setTasks(taskRes.data.map((t: any) => {
        const app = t.applications;
        const sp  = app?.student_profiles;
        return {
          id:       t.id,
          title:    t.title,
          dueDate:  t.due_date,
          priority: t.priority ?? 'normal',
          status:   t.status,
          student:  [sp?.first_name, sp?.last_name].filter(Boolean).join(' ') || 'Etudiant',
          appId:    app?.id ?? null,
        };
      }));
    }

    setLoading(false);
  }, []);

  useEffect(() => { load(); }, [load]);

  const markAllRead = async () => {
    setMarkingRead(true);
    await supabase.from('conversations').update({ unread_staff: 0 }).gt('unread_staff', 0);
    setConvs([]);
    setMarkingRead(false);
  };

  const totalMsg     = convs.length;
  const totalPending = pending.length;
  const totalTasks   = tasks.length;
  const totalAll     = totalMsg + totalPending + totalTasks;
  const hasOverdue   = tasks.some(t => new Date(t.dueDate) < new Date());

  const showMessages = tab === 'all' || tab === 'messages';
  const showPending  = tab === 'all' || tab === 'pending';
  const showTasks    = tab === 'all' || tab === 'tasks';

  return (
    <>
      <style>{CSS}</style>
      <PageHeader
        title="Centre de notifications"
        subtitle={
          loading
            ? 'Chargement...'
            : totalAll === 0
              ? 'Aucune notification'
              : `${totalAll} notification${totalAll > 1 ? 's' : ''}`
        }
        actions={
          <button
            onClick={load}
            style={{
              padding: '8px 16px', borderRadius: 8, border: `1.5px solid ${colors.border}`,
              background: 'white', cursor: 'pointer', fontSize: 13, fontWeight: 600,
              color: colors.textSecondary, fontFamily: fonts.body, display: 'flex',
              alignItems: 'center', gap: 6, transition: 'all .15s',
            }}
          >
            <svg width={13} height={13} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.2} strokeLinecap="round">
              <polyline points="23 4 23 10 17 10"/>
              <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>
            </svg>
            Actualiser
          </button>
        }
      />

      {/* Tabs */}
      <div className="np-tabs">
        {([
          ['all',      'Tout',          totalAll],
          ['messages', 'Messages',  totalMsg],
          ['pending',  'A traiter', totalPending],
          ['tasks',    'Tâches',    totalTasks],
        ] as const).map(([key, label, count]) => (
          <button
            key={key}
            className={`np-tab${tab === key ? ' np-tab--active' : ''}`}
            onClick={() => setTab(key)}
          >
            {label}
            {count > 0 && (
              <span style={{
                minWidth: 16, height: 16, borderRadius: 8,
                background: tab === key ? 'rgba(255,255,255,0.3)' : colors.blue,
                color: 'white', fontSize: 10, fontWeight: 700,
                display: 'inline-flex', alignItems: 'center', justifyContent: 'center', padding: '0 4px',
              }}>
                {count}
              </span>
            )}
          </button>
        ))}
      </div>

      {loading ? (
        <div style={{ display: 'flex', gap: 6, padding: 32, justifyContent: 'center' }}>
          {[0, 1, 2].map(i => (
            <div key={i} style={{
              width: 8, height: 8, borderRadius: '50%', background: colors.blue, opacity: .3,
              animation: 'np-dot-pulse 1.2s infinite', animationDelay: `${i * 0.2}s`,
            }} />
          ))}
          <style>{`@keyframes np-dot-pulse { 0%,80%,100%{opacity:.3} 40%{opacity:1} }`}</style>
        </div>
      ) : (
        <>
          {/* Section 1 : Messages non-lus */}
          {showMessages && (
            <div className="np-section">
              <div className="np-section-head">
                <svg width={16} height={16} fill="none" viewBox="0 0 24 24" stroke={colors.blue} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
                  <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                </svg>
                <span className="np-section-title">Messages non-lus</span>
                {totalMsg > 0 && <span className="np-section-count">{totalMsg}</span>}
                {totalMsg > 0 && (
                  <button
                    className="np-section-action"
                    onClick={markAllRead}
                    disabled={markingRead}
                  >
                    {markingRead ? 'Traitement...' : 'Tout marquer lu'}
                  </button>
                )}
              </div>
              {convs.length === 0 ? (
                <div className="np-empty">Aucun message non lu</div>
              ) : (
                <div className="np-card">
                  {convs.map(c => {
                    const [fg, bg] = avatarColor(c.student);
                    return (
                      <div
                        key={c.id}
                        className="np-item"
                        onClick={() => navigate('/messaging')}
                      >
                        <div className="np-avatar" style={{ background: bg, color: fg }}>
                          {studentInitials(c.student)}
                        </div>
                        <div className="np-item-body">
                          <div className="np-item-top">
                            <span className="np-item-name">{c.student}</span>
                            <span className="np-item-time">{fmtTime(c.updatedAt)}</span>
                          </div>
                          <div className="np-item-sub">{c.preview || 'Nouveau message'}</div>
                        </div>
                        <span className="np-chip--unread">{c.count}</span>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          )}

          {/* Section 2 : Candidatures a traiter */}
          {showPending && (
            <div className="np-section">
              <div className="np-section-head">
                <svg width={16} height={16} fill="none" viewBox="0 0 24 24" stroke={colors.blue} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
                  <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
                  <polyline points="14 2 14 8 20 8"/>
                  <line x1="16" y1="13" x2="8" y2="13"/>
                </svg>
                <span className="np-section-title">Candidatures a traiter</span>
                {totalPending > 0 && <span className="np-section-count" style={{ background: '#7c3aed' }}>{totalPending}</span>}
                {totalPending > 0 && (
                  <button className="np-section-action" onClick={() => navigate('/applications')}>
                    Voir toutes les candidatures
                  </button>
                )}
              </div>
              {pending.length === 0 ? (
                <div className="np-empty">Aucune candidature en attente</div>
              ) : (
                <div className="np-card">
                  {pending.map(p => {
                    const sc = STATUS_COLOR[p.status] ?? { bg: '#f9fafb', color: '#6b7280' };
                    const [fg, bg] = avatarColor(p.student);
                    return (
                      <div
                        key={p.id}
                        className="np-item"
                        onClick={() => navigate('/applications')}
                      >
                        <div className="np-avatar" style={{ background: bg, color: fg }}>
                          {studentInitials(p.student)}
                        </div>
                        <div className="np-item-body">
                          <div className="np-item-top">
                            <span className="np-item-name">{p.student}</span>
                            <span className="np-item-time">{fmtTime(p.submittedAt)}</span>
                          </div>
                          {(p.program || p.university) && (
                            <div style={{ fontSize: 11.5, color: colors.textMuted, marginTop: 1 }}>
                              {[p.program, p.university].filter(Boolean).join(' — ')}
                            </div>
                          )}
                          <div className="np-item-sub" style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 4 }}>
                            <span className="np-chip" style={{ background: sc.bg, color: sc.color }}>
                              {STATUS_FR[p.status] ?? p.status}
                            </span>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          )}

          {/* Section 3 : Tâches urgentes */}
          {showTasks && (
            <div className="np-section">
              <div className="np-section-head">
                <svg width={16} height={16} fill="none" viewBox="0 0 24 24" stroke={colors.blue} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
                  <path d="M9 11l3 3L22 4"/>
                  <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
                </svg>
                <span className="np-section-title">Tâches urgentes / en retard</span>
                {totalTasks > 0 && (
                  <span className={`np-section-count${hasOverdue ? ' np-section-count--danger' : ' np-section-count--warn'}`}>
                    {totalTasks}
                  </span>
                )}
                {totalTasks > 0 && (
                  <button className="np-section-action" onClick={() => navigate('/tasks')}>
                    Voir toutes les tâches
                  </button>
                )}
              </div>
              {tasks.length === 0 ? (
                <div className="np-empty">Aucune tâche urgente</div>
              ) : (
                <div className="np-card">
                  {tasks.map(t => {
                    const pc  = PRIORITY_COLOR[t.priority] ?? PRIORITY_COLOR.normal;
                    const { label: dueLabel, overdue } = fmtDate(t.dueDate);
                    const [fg, bg] = avatarColor(t.student);
                    return (
                      <div
                        key={t.id}
                        className="np-item"
                        onClick={() => navigate('/tasks')}
                      >
                        <div className="np-icon-box" style={{ background: overdue ? '#fef2f2' : '#fff7ed' }}>
                          <svg width={16} height={16} fill="none" viewBox="0 0 24 24" stroke={overdue ? '#dc2626' : '#d97706'} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
                            <circle cx="12" cy="12" r="10"/>
                            <line x1="12" y1="8" x2="12" y2="12"/>
                            <line x1="12" y1="16" x2="12.01" y2="16"/>
                          </svg>
                        </div>
                        <div className="np-item-body">
                          <div className="np-item-top">
                            <span className="np-item-name">{t.title}</span>
                            <span style={{
                              fontSize: 11, fontWeight: 700,
                              color: overdue ? '#dc2626' : '#d97706',
                              flexShrink: 0,
                            }}>
                              {dueLabel}
                            </span>
                          </div>
                          <div className="np-item-sub" style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 3 }}>
                            <div className="np-avatar" style={{ width: 18, height: 18, borderRadius: 5, background: bg, color: fg, fontSize: 8, fontWeight: 800 }}>
                              {studentInitials(t.student)}
                            </div>
                            <span>{t.student}</span>
                            <span className="np-chip" style={{ background: pc.bg, color: pc.color, marginLeft: 2 }}>
                              {t.priority === 'urgent' ? 'Urgent' : t.priority === 'low' ? 'Faible' : 'Normal'}
                            </span>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          )}
        </>
      )}
    </>
  );
}