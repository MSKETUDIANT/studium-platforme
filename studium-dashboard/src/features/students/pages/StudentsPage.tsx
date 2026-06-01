import React, { useState, useEffect, useMemo, useRef } from 'react';
import { supabase }       from '../../../shared/services/supabase';
import { Button }         from '../../../shared/components/Button';
import { PageHeader }     from '../../../shared/components/PageHeader';
import { Pagination }     from '../../../shared/components/Pagination';
import { LoadingSpinner } from '../../../shared/components/LoadingSpinner';
import { colors, fonts, radius, shadows } from '../../../shared/constants/theme';

/* ─── Types ──────────────────────────────────────────────────────────────── */
interface Student {
  id:                 string;
  first_name:         string | null;
  last_name:          string | null;
  photo_url:          string | null;
  completeness_score: number;
  nationality:        string | null;
}

interface StudentDoc {
  id:               string;
  type:             string;
  file_url:         string;
  file_name:        string;
  size_bytes:       number;
  status:           string;
  rejection_reason: string | null;
  created_at:       string | null;
}

/* ─── Constantes ─────────────────────────────────────────────────────────── */
const TYPE_LABELS: Record<string, string> = {
  cv: 'CV', transcript: 'Relevé de notes',
  recommendation: 'Lettre de recommandation', passport: 'Passeport', other: 'Autre',
};

const DOC_ICONS: Record<string, React.ReactElement> = {
  cv:             <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>,
  transcript:     <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/></svg>,
  recommendation: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>,
  passport:       <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="12" cy="10" r="3"/><path d="M6 21v-1a6 6 0 0 1 12 0v1"/></svg>,
  other:          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"/></svg>,
};

const TYPE_COLOR: Record<string, { bg: string; color: string; icon: React.ReactElement }> = {
  cv:             { bg: 'rgba(37,70,204,0.10)',  color: '#2546cc', icon: DOC_ICONS.cv             },
  transcript:     { bg: 'rgba(124,58,237,0.10)', color: '#7c3aed', icon: DOC_ICONS.transcript     },
  recommendation: { bg: 'rgba(22,163,74,0.10)',  color: '#16a34a', icon: DOC_ICONS.recommendation },
  passport:       { bg: 'rgba(217,119,6,0.10)',  color: '#d97706', icon: DOC_ICONS.passport       },
  other:          { bg: 'rgba(107,122,158,0.10)', color: '#6b7a9e', icon: DOC_ICONS.other         },
};

const STATUS_CFG: Record<string, { label: string; color: string; bg: string; dot: string }> = {
  uploaded:     { label: 'Uploadé',     color: '#2546cc', bg: 'rgba(37,70,204,0.10)',  dot: '#2546cc' },
  under_review: { label: 'En révision', color: '#d97706', bg: 'rgba(217,119,6,0.10)',  dot: '#d97706' },
  approved:     { label: 'Approuvé',    color: '#16a34a', bg: 'rgba(22,163,74,0.10)',  dot: '#16a34a' },
  rejected:     { label: 'Rejeté',      color: '#dc2626', bg: 'rgba(220,38,38,0.10)',  dot: '#dc2626' },
};

const SCORE_COLOR = (s: number) =>
  s >= 80 ? colors.success : s >= 50 ? colors.warning : colors.danger;

const AVATAR_COLORS = [
  ['#2546cc','rgba(37,70,204,0.12)'],
  ['#7c3aed','rgba(124,58,237,0.12)'],
  ['#16a34a','rgba(22,163,74,0.12)'],
  ['#d97706','rgba(217,119,6,0.12)'],
  ['#dc2626','rgba(220,38,38,0.12)'],
  ['#0891b2','rgba(8,145,178,0.12)'],
];

const avatarColor = (name: string) => AVATAR_COLORS[name.charCodeAt(0) % AVATAR_COLORS.length];

/* ─── Helpers ─────────────────────────────────────────────────────────────── */
const initials = (s: Student) =>
  `${s.first_name?.[0] ?? ''}${s.last_name?.[0] ?? ''}`.toUpperCase() || '?';
const fullName = (s: Student) =>
  [s.first_name, s.last_name].filter(Boolean).join(' ') || 'Sans nom';
const fmtSize = (b: number) =>
  b < 1024 ? `${b} B` : b < 1024*1024 ? `${(b/1024).toFixed(1)} KB` : `${(b/1024/1024).toFixed(1)} MB`;
const fmtDate = (s: string | null) => {
  if (!s) return '';
  const d = new Date(s);
  return `${String(d.getDate()).padStart(2,'0')}/${String(d.getMonth()+1).padStart(2,'0')}/${d.getFullYear()}`;
};

/* ─── CSS ─────────────────────────────────────────────────────────────────── */
const CSS = `
  /* Layout */
  .sp-grid { display:grid; grid-template-columns:repeat(4,1fr); gap:16px; margin-bottom:24px; }
  @media(max-width:900px){ .sp-grid{ grid-template-columns:repeat(2,1fr); } }
  .sp-layout { display:grid; grid-template-columns:360px 1fr; gap:20px; align-items:start; }
  @media(max-width:1100px){ .sp-layout{ grid-template-columns:1fr; } }

  /* Stat card */
  .sp-stat {
    background:white; border-radius:${radius.lg}px;
    box-shadow:${shadows.card}; overflow:hidden;
  }
  .sp-stat-inner {
    padding:16px 20px; display:flex; align-items:center; gap:14px;
  }
  .sp-stat-icon {
    width:46px; height:46px; border-radius:13px;
    display:flex; align-items:center; justify-content:center;
    flex-shrink:0;
  }

  /* Panel */
  .sp-panel { background:white; border-radius:${radius.lg}px; box-shadow:${shadows.card}; overflow:hidden; }

  /* Tabs */
  .sp-tabs { display:flex; gap:4px; padding:14px 16px 0; border-bottom:1px solid ${colors.border}; }
  .sp-tab {
    padding:8px 14px; font-size:12px; font-weight:600; cursor:pointer;
    border-radius:8px 8px 0 0; border:none; background:none;
    color:${colors.textMuted}; font-family:${fonts.body};
    border-bottom:2px solid transparent; margin-bottom:-1px;
    transition:all .15s;
  }
  .sp-tab--active { color:${colors.blue}; border-bottom-color:${colors.blue}; background:rgba(37,70,204,0.04); }
  .sp-tab:hover:not(.sp-tab--active) { color:${colors.textSecondary}; background:${colors.inputBg}; }

  /* Search */
  .sp-search-wrap { padding:12px 14px; border-bottom:1px solid ${colors.border}; }
  .sp-search {
    width:100%; padding:9px 12px 9px 36px;
    border:1.5px solid ${colors.borderInput}; border-radius:${radius.md}px;
    font-size:13px; color:${colors.textPrimary}; background:${colors.inputBg};
    outline:none; box-sizing:border-box; font-family:${fonts.body};
    transition:border-color .18s;
  }
  .sp-search:focus { border-color:${colors.blue}; background:white; }

  /* Student row */
  .sp-row {
    display:flex; align-items:center; gap:12px;
    padding:13px 16px; cursor:pointer;
    border-bottom:1px solid ${colors.border};
    transition:background .12s;
  }
  .sp-row:hover { background:${colors.inputBg}; }
  .sp-row--active { background:rgba(37,70,204,0.05); border-left:3px solid ${colors.blue}; }
  .sp-row:last-child { border-bottom:none; }

  /* Avatar */
  .sp-avatar {
    width:40px; height:40px; border-radius:12px;
    display:flex; align-items:center; justify-content:center;
    font-size:13px; font-weight:700; font-family:${fonts.display};
    flex-shrink:0;
  }

  /* Progress bar */
  .sp-bar-bg { height:4px; border-radius:2px; background:${colors.border}; margin-top:5px; width:100%; }
  .sp-bar-fill { height:4px; border-radius:2px; transition:width .4s; }

  /* Doc header */
  .sp-doc-head {
    padding:18px 22px; border-bottom:1px solid ${colors.border};
    display:flex; align-items:flex-start; justify-content:space-between;
    gap:12px;
  }

  /* Doc card */
  .sp-doc-card {
    margin:10px 14px; border-radius:${radius.md}px;
    border:1.5px solid ${colors.border}; overflow:hidden;
    transition:border-color .15s;
  }
  .sp-doc-card:hover { border-color:${colors.borderHover}; }
  .sp-doc-card--rejected { border-color:rgba(220,38,38,0.25); background:rgba(220,38,38,0.02); }

  /* Action buttons */
  .sp-btn-act {
    display:inline-flex; align-items:center; gap:5px;
    padding:5px 10px; border-radius:8px; font-size:11.5px; font-weight:600;
    border:1.5px solid transparent; background:${colors.inputBg}; cursor:pointer;
    font-family:${fonts.body}; transition:all .15s; white-space:nowrap;
  }
  .sp-btn-act:disabled { opacity:.4; cursor:not-allowed; }
  .sp-btn-act--view   { color:${colors.blue};    }
  .sp-btn-act--view:hover   { border-color:${colors.blue};    background:rgba(37,70,204,0.07); }
  .sp-btn-act--approve{ color:${colors.success}; }
  .sp-btn-act--approve:hover{ border-color:${colors.success}; background:rgba(22,163,74,0.07); }
  .sp-btn-act--reject { color:${colors.danger};  }
  .sp-btn-act--reject:hover { border-color:${colors.danger};  background:rgba(220,38,38,0.07); }

  /* Badge */
  .sp-badge {
    display:inline-flex; align-items:center; gap:5px;
    padding:3px 10px; border-radius:${radius.full}px;
    font-size:11px; font-weight:700;
  }

  /* Modal */
  .sp-overlay {
    position:fixed; inset:0; background:rgba(11,24,82,0.35);
    backdrop-filter:blur(4px); display:flex; align-items:center;
    justify-content:center; z-index:1000; padding:20px;
  }
  .sp-modal {
    background:white; border-radius:${radius.xl}px; padding:28px;
    width:100%; max-width:460px; box-shadow:0 24px 60px rgba(11,24,82,0.2);
  }
  .sp-reason {
    width:100%; padding:12px 14px;
    border:1.5px solid ${colors.borderInput}; border-radius:${radius.md}px;
    font-size:14px; color:${colors.textPrimary}; font-family:${fonts.body};
    resize:vertical; outline:none; box-sizing:border-box; transition:border-color .18s;
  }
  .sp-reason:focus { border-color:${colors.danger}; }

  /* Empty */
  .sp-empty { display:flex; flex-direction:column; align-items:center;
    justify-content:center; min-height:280px; gap:10px;
    color:${colors.textMuted}; font-size:14px; text-align:center; }

  .sp-grid .sp-stat:nth-child(1) { animation: ph-fade-up .35s .08s ease both; }
  .sp-grid .sp-stat:nth-child(2) { animation: ph-fade-up .35s .16s ease both; }
  .sp-grid .sp-stat:nth-child(3) { animation: ph-fade-up .35s .24s ease both; }
  .sp-grid .sp-stat:nth-child(4) { animation: ph-fade-up .35s .32s ease both; }
  .sp-layout { animation: ph-fade-up .35s .42s ease both; }
`;

const STUDENT_PAGE_SIZE = 10;

/* ─── Composant ───────────────────────────────────────────────────────────── */
export default function StudentsPage() {
  const [students,      setStudents]      = useState<Student[]>([]);
  const [loading,       setLoading]       = useState(true);
  const [search,        setSearch]        = useState('');
  const [tab,           setTab]           = useState<'all'|'complete'|'pending'>('all');
  const [selected,      setSelected]      = useState<Student | null>(null);
  const [docs,          setDocs]          = useState<StudentDoc[]>([]);
  const [docsLoading,   setDocsLoading]   = useState(false);
  const [rejectTarget,  setRejectTarget]  = useState<{ id: string; fileName: string } | null>(null);
  const [rejectReason,  setRejectReason]  = useState('');
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [studentPage,   setStudentPage]   = useState(1);
  const reasonRef = useRef<HTMLTextAreaElement>(null);

  /* Charger étudiants */
  useEffect(() => {
    (async () => {
      setLoading(true);
      const { data } = await supabase
        .from('student_profiles')
        .select('id, first_name, last_name, photo_url, completeness_score, nationality')
        .order('completeness_score', { ascending: false });
      setStudents(data ?? []);
      setLoading(false);
    })();
  }, []);

  /* Charger documents */
  useEffect(() => {
    if (!selected) { setDocs([]); return; }
    setDocsLoading(true);
    supabase
      .from('documents')
      .select('id, type, file_url, file_name, size_bytes, status, rejection_reason, created_at')
      .eq('student_profile_id', selected.id)
      .order('created_at', { ascending: false })
      .then(({ data }) => { setDocs(data ?? []); setDocsLoading(false); });
  }, [selected]);

  /* Actions */
  const approve = async (docId: string) => {
    setActionLoading(docId);
    await supabase.from('documents')
      .update({ status: 'approved', rejection_reason: null }).eq('id', docId);
    setDocs(prev => prev.map(d =>
      d.id === docId ? { ...d, status: 'approved', rejection_reason: null } : d));
    setActionLoading(null);
  };

  const confirmReject = async () => {
    if (!rejectTarget || !rejectReason.trim()) return;
    setActionLoading(rejectTarget.id);
    await supabase.from('documents')
      .update({ status: 'rejected', rejection_reason: rejectReason.trim() })
      .eq('id', rejectTarget.id);
    setDocs(prev => prev.map(d =>
      d.id === rejectTarget.id ? { ...d, status: 'rejected', rejection_reason: rejectReason.trim() } : d));
    setActionLoading(null);
    setRejectTarget(null);
    setRejectReason('');
  };

  /* Filtres */
  const filtered = useMemo(() => {
    let list = students.filter(s =>
      fullName(s).toLowerCase().includes(search.toLowerCase()) ||
      (s.nationality ?? '').toLowerCase().includes(search.toLowerCase()));
    if (tab === 'complete') list = list.filter(s => s.completeness_score >= 80);
    if (tab === 'pending')  list = list.filter(s => s.completeness_score < 80);
    return list;
  }, [students, search, tab]);

  useEffect(() => setStudentPage(1), [search, tab]);

  const studentTotalPages = Math.max(1, Math.ceil(filtered.length / STUDENT_PAGE_SIZE));
  const paginatedStudents = filtered.slice((studentPage - 1) * STUDENT_PAGE_SIZE, studentPage * STUDENT_PAGE_SIZE);

  const avgScore = students.length
    ? Math.round(students.reduce((a, s) => a + s.completeness_score, 0) / students.length)
    : 0;

  const pendingDocs = docs.filter(d => d.status === 'uploaded' || d.status === 'under_review').length;

  /* ── Stats SVG icons ── */
  const statIcons: Record<string, React.ReactNode> = {
    students: (
      <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/>
        <path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>
      </svg>
    ),
    complete: (
      <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
      </svg>
    ),
    docs: (
      <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/>
        <polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/>
        <line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/>
      </svg>
    ),
    score: (
      <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
        <line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/>
        <line x1="6" y1="20" x2="6" y2="14"/>
      </svg>
    ),
  };

  /* ── Stats ── */
  const stats = [
    {
      label: 'Total étudiants', value: String(students.length),
      iconKey: 'students', accentColor: colors.blue,
      iconBg: 'rgba(37,70,204,0.12)', iconColor: colors.blue,
    },
    {
      label: 'Profils ≥ 80%', value: String(students.filter(s => s.completeness_score >= 80).length),
      iconKey: 'complete', accentColor: colors.success,
      iconBg: 'rgba(22,163,74,0.12)', iconColor: colors.success,
    },
    {
      label: 'Docs à examiner', value: String(pendingDocs),
      iconKey: 'docs', accentColor: colors.warning,
      iconBg: 'rgba(217,119,6,0.12)', iconColor: colors.warning,
    },
    {
      label: 'Score moyen', value: `${avgScore}%`,
      iconKey: 'score', accentColor: '#0891b2',
      iconBg: 'rgba(8,145,178,0.12)', iconColor: '#0891b2',
    },
  ];

  return (
    <>
      <style>{CSS}</style>

      <PageHeader
        title="Gestion des étudiants"
        subtitle={`${students.length} étudiant${students.length !== 1 ? 's' : ''} enregistré${students.length !== 1 ? 's' : ''}`}
      />

      {/* ── Stats ── */}
      <div className="sp-grid">
        {stats.map(s => (
          <div key={s.label} className="sp-stat">
            <div style={{ height: 3, background: s.accentColor }} />
            <div className="sp-stat-inner">
              <div className="sp-stat-icon" style={{ background: s.iconBg, color: s.iconColor }}>
                {statIcons[s.iconKey]}
              </div>
              <div>
                <div style={{ fontSize: 26, fontWeight: 800, color: s.accentColor, fontFamily: fonts.display, lineHeight: 1 }}>
                  {s.value}
                </div>
                <div style={{ fontSize: 12, color: colors.textMuted, marginTop: 4, fontWeight: 500 }}>{s.label}</div>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="sp-layout">

        {/* ── Liste étudiants ── */}
        <div className="sp-panel">
          <div style={{ height: 3, background: `linear-gradient(90deg, ${colors.blue}, #7c3aed)` }} />
          {/* Tabs */}
          <div className="sp-tabs">
            {([
              { key: 'all',      label: 'Tous',          count: students.length },
              { key: 'complete', label: 'Complets',       count: students.filter(s => s.completeness_score >= 80).length },
              { key: 'pending',  label: 'Incomplets',     count: students.filter(s => s.completeness_score < 80).length },
            ] as const).map(t => (
              <button
                key={t.key}
                className={`sp-tab${tab === t.key ? ' sp-tab--active' : ''}`}
                onClick={() => setTab(t.key)}
              >
                {t.label}
                <span style={{
                  marginLeft: 6, padding: '1px 6px', borderRadius: 10,
                  background: tab === t.key ? 'rgba(37,70,204,0.12)' : colors.border,
                  color: tab === t.key ? colors.blue : colors.textMuted,
                  fontSize: 11,
                }}>
                  {t.count}
                </span>
              </button>
            ))}
          </div>

          {/* Search */}
          <div className="sp-search-wrap">
            <div style={{ position: 'relative' }}>
              <svg style={{ position:'absolute', left:10, top:'50%', transform:'translateY(-50%)', color: colors.textMuted }}
                width={15} height={15} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
              </svg>
              <input
                className="sp-search"
                placeholder="Nom, nationalité..."
                value={search}
                onChange={e => setSearch(e.target.value)}
              />
            </div>
          </div>

          {/* Rows */}
          {loading ? (
            <div style={{ padding: 48, textAlign: 'center' }}><LoadingSpinner /></div>
          ) : filtered.length === 0 ? (
            <div className="sp-empty">
              <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke={colors.textMuted} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
              <span>Aucun étudiant trouvé</span>
            </div>
          ) : (
            <>
              <div>
                {paginatedStudents.map(student => {
                const [fg, bg] = avatarColor(fullName(student));
                const active = selected?.id === student.id;
                return (
                  <div
                    key={student.id}
                    className={`sp-row${active ? ' sp-row--active' : ''}`}
                    onClick={() => setSelected(student)}
                  >
                    <div className="sp-avatar" style={{ background: bg, color: fg }}>
                      {initials(student)}
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontWeight: 600, fontSize: 13, color: colors.textPrimary, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' }}>
                        {fullName(student)}
                      </div>
                      <div style={{ fontSize: 11, color: colors.textMuted, marginTop: 1 }}>
                        {student.nationality ?? 'Nationalité non renseignée'}
                      </div>
                      {/* Progress bar */}
                      <div className="sp-bar-bg">
                        <div
                          className="sp-bar-fill"
                          style={{
                            width: `${student.completeness_score}%`,
                            background: SCORE_COLOR(student.completeness_score),
                          }}
                        />
                      </div>
                    </div>
                    <div style={{ fontSize: 12, fontWeight: 700, color: SCORE_COLOR(student.completeness_score), flexShrink: 0, marginLeft: 8 }}>
                      {student.completeness_score}%
                    </div>
                  </div>
                );
                })}
              </div>
              <Pagination
                page={studentPage}
                totalPages={studentTotalPages}
                total={filtered.length}
                pageSize={STUDENT_PAGE_SIZE}
                onChange={setStudentPage}
                label="étudiants"
              />
            </>
          )}
        </div>

        {/* ── Panel documents ── */}
        <div className="sp-panel" style={{ minHeight: 400, overflow: 'hidden' }}>
          <div style={{ height: 3, background: `linear-gradient(90deg, #7c3aed, ${colors.blue})` }} />
          {!selected ? (
            <div className="sp-empty">
              <div style={{
                width: 72, height: 72, borderRadius: 20,
                background: 'linear-gradient(135deg, rgba(37,70,204,0.10) 0%, rgba(124,58,237,0.10) 100%)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <svg width={32} height={32} fill="none" viewBox="0 0 24 24" stroke={colors.blue} strokeWidth={1.5}>
                  <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>
                </svg>
              </div>
              <div style={{ fontWeight: 700, fontSize: 15, color: colors.textSecondary, marginTop: 4 }}>Sélectionnez un étudiant</div>
              <div style={{ fontSize: 12, color: colors.textMuted }}>pour consulter et gérer ses documents</div>
            </div>
          ) : (
            <>
              {/* Header étudiant */}
              <div className="sp-doc-head">
                <div style={{ display: 'flex', gap: 14, alignItems: 'center' }}>
                  {(() => {
                    const [fg, bg] = avatarColor(fullName(selected));
                    return (
                      <div className="sp-avatar" style={{ width: 46, height: 46, background: bg, color: fg, fontSize: 15, borderRadius: 14 }}>
                        {initials(selected)}
                      </div>
                    );
                  })()}
                  <div>
                    <div style={{ fontWeight: 700, fontSize: 15, color: colors.navy }}>
                      {fullName(selected)}
                    </div>
                    <div style={{ display: 'flex', gap: 10, marginTop: 4, alignItems: 'center' }}>
                      {selected.nationality && (
                        <span style={{ fontSize: 12, color: colors.textMuted }}>
                          {selected.nationality}
                        </span>
                      )}
                      <span style={{
                        fontSize: 11, fontWeight: 700, padding: '2px 8px',
                        borderRadius: 6,
                        background: SCORE_COLOR(selected.completeness_score) === colors.success
                          ? 'rgba(22,163,74,0.10)' : SCORE_COLOR(selected.completeness_score) === colors.warning
                          ? 'rgba(217,119,6,0.10)' : 'rgba(220,38,38,0.10)',
                        color: SCORE_COLOR(selected.completeness_score),
                      }}>
                        {selected.completeness_score}% complet
                      </span>
                    </div>
                  </div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <span style={{ fontSize: 12, color: colors.textMuted }}>
                    {docsLoading ? '…' : `${docs.length} doc${docs.length !== 1 ? 's' : ''}`}
                  </span>
                  <button
                    onClick={() => setSelected(null)}
                    style={{
                      width: 28, height: 28, borderRadius: 8, border: `1.5px solid ${colors.borderInput}`,
                      background: 'white', cursor: 'pointer', display: 'flex', alignItems: 'center',
                      justifyContent: 'center', fontSize: 14, color: colors.textMuted,
                    }}
                  >✕</button>
                </div>
              </div>

              {/* Docs */}
              {docsLoading ? (
                <div style={{ padding: 48, textAlign: 'center' }}><LoadingSpinner /></div>
              ) : docs.length === 0 ? (
                <div className="sp-empty">
                  <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke={colors.textMuted} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                  <span>Aucun document uploadé</span>
                </div>
              ) : (
                <div style={{ overflowY: 'auto', maxHeight: 560, paddingBottom: 14 }}>
                  {docs.map(doc => {
                    const cfg  = STATUS_CFG[doc.status] ?? STATUS_CFG.uploaded;
                    const tc   = TYPE_COLOR[doc.type]   ?? TYPE_COLOR.other;
                    const busy = actionLoading === doc.id;
                    const isRejected = doc.status === 'rejected';
                    return (
                      <div key={doc.id} className={`sp-doc-card${isRejected ? ' sp-doc-card--rejected' : ''}`}>
                        {/* Ligne principale */}
                        <div style={{ display: 'flex', gap: 12, padding: '14px 16px', alignItems: 'flex-start' }}>
                          {/* Icône type */}
                          <div style={{
                            width: 42, height: 42, borderRadius: 11,
                            background: tc.bg, color: tc.color,
                            display: 'flex', alignItems: 'center',
                            justifyContent: 'center', flexShrink: 0,
                          }}>
                            {tc.icon}
                          </div>

                          {/* Infos */}
                          <div style={{ flex: 1, minWidth: 0 }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
                              <span style={{ fontWeight: 700, fontSize: 13, color: colors.textPrimary }}>
                                {TYPE_LABELS[doc.type] ?? doc.type}
                              </span>
                              <span className="sp-badge" style={{ background: cfg.bg, color: cfg.color }}>
                                <span style={{ width: 5, height: 5, borderRadius: '50%', background: cfg.dot, display: 'inline-block' }} />
                                {cfg.label}
                              </span>
                            </div>
                            <div style={{ fontSize: 11, color: colors.textMuted, marginTop: 3 }}>
                              {doc.file_name} · {fmtSize(doc.size_bytes)}
                              {doc.created_at && <span> · {fmtDate(doc.created_at)}</span>}
                            </div>
                          </div>
                        </div>

                        {/* Motif rejet */}
                        {isRejected && doc.rejection_reason && (
                          <div style={{
                            margin: '0 16px 12px', padding: '10px 12px',
                            background: 'rgba(220,38,38,0.06)',
                            borderRadius: 8, border: '1px solid rgba(220,38,38,0.15)',
                            fontSize: 12, color: colors.danger,
                          }}>
                            <strong>Motif :</strong> {doc.rejection_reason}
                          </div>
                        )}

                        {/* Actions */}
                        <div style={{
                          display: 'flex', gap: 8, padding: '10px 16px',
                          borderTop: `1px solid ${colors.border}`,
                          background: colors.inputBg, flexWrap: 'wrap',
                        }}>
                          <a
                            href={doc.file_url}
                            target="_blank"
                            rel="noreferrer"
                            className="sp-btn-act sp-btn-act--view"
                          >
                            <svg width={13} height={13} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                              <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                              <circle cx="12" cy="12" r="3"/>
                            </svg>
                            Voir le fichier
                          </a>
                          {doc.status !== 'approved' && (
                            <button
                              className="sp-btn-act sp-btn-act--approve"
                              disabled={busy}
                              onClick={() => approve(doc.id)}
                            >
                              <svg width={13} height={13} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                                <path d="M20 6 9 17l-5-5"/>
                              </svg>
                              {busy ? 'En cours…' : 'Approuver'}
                            </button>
                          )}
                          {doc.status !== 'rejected' && (
                            <button
                              className="sp-btn-act sp-btn-act--reject"
                              disabled={busy}
                              onClick={() => setRejectTarget({ id: doc.id, fileName: doc.file_name })}
                            >
                              <svg width={13} height={13} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                                <path d="M18 6 6 18M6 6l12 12"/>
                              </svg>
                              Rejeter
                            </button>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </>
          )}
        </div>
      </div>

      {/* ── Modal rejet ── */}
      {rejectTarget && (
        <div className="sp-overlay" onClick={() => { setRejectTarget(null); setRejectReason(''); }}>
          <div className="sp-modal" onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
              <div style={{
                width: 40, height: 40, borderRadius: 11,
                background: 'rgba(220,38,38,0.10)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <svg width={18} height={18} fill="none" viewBox="0 0 24 24" stroke={colors.danger} strokeWidth={2}>
                  <path d="M18 6 6 18M6 6l12 12"/>
                </svg>
              </div>
              <div>
                <div style={{ fontWeight: 700, fontSize: 16, color: colors.navy }}>Rejeter le document</div>
                <div style={{ fontSize: 12, color: colors.textMuted, marginTop: 2 }}>{rejectTarget.fileName}</div>
              </div>
            </div>

            <label style={{ fontSize: 13, fontWeight: 600, color: colors.textPrimary, display: 'block', marginBottom: 8 }}>
              Motif de rejet <span style={{ color: colors.danger }}>*</span>
            </label>
            <textarea
              ref={reasonRef}
              className="sp-reason"
              placeholder="Ex : Document illisible, format incorrect, signature manquante..."
              value={rejectReason}
              onChange={e => setRejectReason(e.target.value)}
              rows={4}
              autoFocus
            />

            <div style={{ display: 'flex', gap: 10, marginTop: 20, justifyContent: 'flex-end' }}>
              <Button variant="secondary" size="sm" onClick={() => { setRejectTarget(null); setRejectReason(''); }}>
                Annuler
              </Button>
              <Button
                variant="danger" size="sm"
                disabled={!rejectReason.trim() || actionLoading === rejectTarget.id}
                loading={actionLoading === rejectTarget.id}
                onClick={confirmReject}
              >
                Confirmer le rejet
              </Button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
