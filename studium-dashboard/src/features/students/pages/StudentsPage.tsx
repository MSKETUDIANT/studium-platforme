import React, { useState, useEffect, useMemo, useRef } from 'react';
import { supabase }       from '../../../shared/services/supabase';
import { Button }         from '../../../shared/components/Button';
import { PageHeader }     from '../../../shared/components/PageHeader';
import { downloadCsv }   from '../../../shared/utils/export_csv';
import { Pagination }     from '../../../shared/components/Pagination';
import { LoadingSpinner } from '../../../shared/components/LoadingSpinner';
import { colors, fonts, radius, shadows } from '../../../shared/constants/theme';

/*  Types  */
interface Student {
  id:                 string;
  first_name:         string | null;
  last_name:          string | null;
  photo_url:          string | null;
  completeness_score: number;
  nationality:        string | null;
}

interface StudentNote {
  id:           string;
  content:      string;
  author_email: string | null;
  created_at:   string;
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

interface StudentApp {
  id:              string;
  status:          string;
  submitted_at:    string | null;
  program_name:    string;
  university_name: string;
  country:         string;
  level:           string;
}

interface StudentProfileDetail {
  phone:                 string | null;
  birth_date:            string | null;
  country_residence:     string | null;
  address:               string | null;
  motivation_letter:     string | null;
  academic_goals:        string | null;
  career_goals:          string | null;
  ai_completeness_score: number | null;
  ai_summary:            string | null;
}

type ScoreFilter = '' | 'low' | 'mid' | 'high';
type SortKey     = 'score' | 'name' | 'apps';
type SortDir     = 'asc' | 'desc';

const APP_STATUS_CFG: Record<string, { label: string; color: string; bg: string; step: number }> = {
  draft:            { label: 'Brouillon',       color: '#6b7280', bg: '#f3f4f6', step: 0 },
  submitted:        { label: 'Soumise',         color: '#2563eb', bg: '#eff6ff', step: 1 },
  needsfix:         { label: 'Correction req.', color: '#d97706', bg: '#fff7ed', step: 1 },
  verified:         { label: 'Verifiee',        color: '#16a34a', bg: '#f0fdf4', step: 2 },
  sent:             { label: 'Envoyee',         color: '#2546cc', bg: '#eff6ff', step: 3 },
  accepted:         { label: 'Acceptee',        color: '#15803d', bg: '#dcfce7', step: 4 },
  rejected:         { label: 'Refusee',         color: '#dc2626', bg: '#fef2f2', step: 4 },
  pending_decision: { label: 'En attente',      color: '#b45309', bg: '#fefce8', step: 3 },
  archived:         { label: 'Archivee',        color: '#6b7280', bg: '#f9fafb', step: 4 },
};

const TYPE_LABELS: Record<string, string> = {
  cv: 'CV', transcript: 'Releve de notes',
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
  cv:             { bg: 'rgba(37,70,204,0.10)',   color: '#2546cc', icon: DOC_ICONS.cv             },
  transcript:     { bg: 'rgba(124,58,237,0.10)',  color: '#7c3aed', icon: DOC_ICONS.transcript     },
  recommendation: { bg: 'rgba(22,163,74,0.10)',   color: '#16a34a', icon: DOC_ICONS.recommendation },
  passport:       { bg: 'rgba(217,119,6,0.10)',   color: '#d97706', icon: DOC_ICONS.passport       },
  other:          { bg: 'rgba(107,122,158,0.10)', color: '#6b7a9e', icon: DOC_ICONS.other          },
};

const STATUS_CFG: Record<string, { label: string; color: string; bg: string; dot: string }> = {
  uploaded:     { label: 'Uploade',     color: '#2546cc', bg: 'rgba(37,70,204,0.10)',  dot: '#2546cc' },
  under_review: { label: 'En revision', color: '#d97706', bg: 'rgba(217,119,6,0.10)',  dot: '#d97706' },
  approved:     { label: 'Approuve',    color: '#16a34a', bg: 'rgba(22,163,74,0.10)',  dot: '#16a34a' },
  rejected:     { label: 'Rejete',      color: '#dc2626', bg: 'rgba(220,38,38,0.10)',  dot: '#dc2626' },
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

const APP_STEPS = ['Soumise', 'En verification', 'Envoyee', 'Resultat'];

/*  CSS  */
const CSS = `
  .sp-grid { display:grid; grid-template-columns:repeat(4,1fr); gap:16px; margin-bottom:24px; }
  @media(max-width:900px){ .sp-grid{ grid-template-columns:repeat(2,1fr); } }
  .sp-layout { display:grid; grid-template-columns:380px 1fr; gap:20px; align-items:start; }
  @media(max-width:1100px){ .sp-layout{ grid-template-columns:1fr; } }

  .sp-stat {
    background:white; border-radius:${radius.lg}px;
    box-shadow:${shadows.card}; overflow:hidden;
  }
  .sp-stat-top  { height:3px; }
  .sp-stat-inner { padding:16px 20px; display:flex; align-items:center; gap:14px; }
  .sp-stat-icon {
    width:42px; height:42px; border-radius:12px;
    display:flex; align-items:center; justify-content:center; flex-shrink:0;
  }

  .sp-panel { background:white; border-radius:${radius.lg}px; box-shadow:${shadows.card}; overflow:hidden; }

  .sp-tabs { display:flex; gap:4px; padding:12px 14px 0; border-bottom:1px solid ${colors.border}; }
  .sp-tab {
    padding:7px 12px; font-size:12px; font-weight:600; cursor:pointer;
    border-radius:7px 7px 0 0; border:none; background:none;
    color:${colors.textMuted}; font-family:${fonts.body};
    border-bottom:2px solid transparent; margin-bottom:-1px; transition:all .15s;
  }
  .sp-tab--active { color:${colors.blue}; border-bottom-color:${colors.blue}; background:rgba(37,70,204,0.04); }
  .sp-tab:hover:not(.sp-tab--active) { color:${colors.textSecondary}; background:${colors.inputBg}; }

  /* Toolbar */
  .sp-toolbar {
    padding:10px 14px; border-bottom:1px solid ${colors.border};
    display:flex; gap:8px; align-items:center; flex-wrap:wrap; background:#fafbff;
  }
  .sp-search-wrap { flex:1; min-width:140px; position:relative; }
  .sp-search {
    width:100%; padding:8px 10px 8px 32px;
    border:1.5px solid ${colors.borderInput}; border-radius:${radius.md}px;
    font-size:13px; color:${colors.textPrimary}; background:white;
    outline:none; box-sizing:border-box; font-family:${fonts.body};
    transition:border-color .18s;
  }
  .sp-search:focus { border-color:${colors.blue}; }
  .sp-toolbar-select {
    padding:8px 10px; border:1.5px solid ${colors.borderInput};
    border-radius:${radius.md}px; font-size:12px; font-weight:600;
    color:${colors.textSecondary}; background:white; font-family:${fonts.body};
    cursor:pointer; outline:none; transition:border-color .15s;
  }
  .sp-toolbar-select:focus,.sp-toolbar-select:hover { border-color:${colors.blue}; }
  .sp-toolbar-select--active { border-color:${colors.blue}; color:${colors.blue}; background:rgba(37,70,204,0.05); }
  .sp-sort-btn {
    padding:8px 11px; border:1.5px solid ${colors.borderInput};
    border-radius:${radius.md}px; font-size:12px; font-weight:600;
    color:${colors.textSecondary}; background:white; font-family:${fonts.body};
    cursor:pointer; display:flex; align-items:center; gap:5px;
    transition:all .15s; white-space:nowrap;
  }
  .sp-sort-btn:hover { border-color:${colors.blue}; color:${colors.blue}; }
  .sp-sort-btn--active { border-color:${colors.blue}; color:${colors.blue}; background:rgba(37,70,204,0.05); }
  .sp-reset-btn {
    padding:8px 11px; border:1.5px solid ${colors.border};
    border-radius:${radius.md}px; font-size:12px; font-weight:600;
    color:${colors.textMuted}; background:white; font-family:${fonts.body};
    cursor:pointer; transition:all .15s;
  }
  .sp-reset-btn:hover { border-color:${colors.danger}; color:${colors.danger}; background:rgba(220,38,38,0.04); }

  .sp-results-bar {
    padding:6px 14px; border-bottom:1px solid ${colors.border};
    font-size:11.5px; color:${colors.textMuted};
    display:flex; align-items:center; gap:8px; flex-wrap:wrap;
    background:white;
  }
  .sp-results-tag {
    display:inline-flex; align-items:center; gap:4px;
    padding:2px 8px; border-radius:20px;
    background:rgba(37,70,204,0.08); color:${colors.blue};
    font-size:11px; font-weight:600;
  }

  .sp-row {
    display:flex; align-items:center; gap:12px;
    padding:11px 14px; cursor:pointer;
    border-bottom:1px solid ${colors.border}; transition:background .12s;
  }
  .sp-row:hover { background:${colors.inputBg}; }
  .sp-row--active { background:rgba(37,70,204,0.05); border-left:3px solid ${colors.blue}; padding-left:11px; }
  .sp-row:last-child { border-bottom:none; }

  .sp-avatar {
    width:38px; height:38px; border-radius:11px;
    display:flex; align-items:center; justify-content:center;
    font-size:12px; font-weight:800; font-family:${fonts.display}; flex-shrink:0;
  }

  .sp-bar-bg  { height:4px; border-radius:2px; background:${colors.border}; margin-top:5px; width:100%; }
  .sp-bar-fill{ height:4px; border-radius:2px; transition:width .4s; }

  .sp-doc-card {
    margin:8px 14px; border-radius:${radius.md}px;
    border:1.5px solid ${colors.border}; overflow:hidden; transition:border-color .15s;
  }
  .sp-doc-card:hover { border-color:${colors.borderHover}; }
  .sp-doc-card--rejected { border-color:rgba(220,38,38,0.25); background:rgba(220,38,38,0.02); }

  .sp-btn-act {
    display:inline-flex; align-items:center; gap:5px;
    padding:5px 10px; border-radius:8px; font-size:11.5px; font-weight:600;
    border:1.5px solid transparent; background:${colors.inputBg}; cursor:pointer;
    font-family:${fonts.body}; transition:all .15s; white-space:nowrap;
  }
  .sp-btn-act:disabled { opacity:.4; cursor:not-allowed; }
  .sp-btn-act--view:hover   { border-color:${colors.blue};    background:rgba(37,70,204,0.07);  color:${colors.blue};    }
  .sp-btn-act--approve:hover{ border-color:${colors.success}; background:rgba(22,163,74,0.07);  color:${colors.success}; }
  .sp-btn-act--reject:hover { border-color:${colors.danger};  background:rgba(220,38,38,0.07);  color:${colors.danger};  }

  .sp-note-card {
    padding:12px 14px; border-radius:${radius.md}px;
    border:1px solid ${colors.border}; margin:0 14px 10px;
    background:white; transition:border-color .15s;
  }
  .sp-note-card:hover { border-color:${colors.borderHover}; }
  .sp-note-content { font-size:13px; color:${colors.textPrimary}; line-height:1.5; white-space:pre-wrap; }
  .sp-note-meta { font-size:11px; color:${colors.textMuted}; margin-top:6px; display:flex; justify-content:space-between; align-items:center; }
  .sp-note-del { background:none; border:none; cursor:pointer; color:${colors.textMuted}; padding:2px 4px; border-radius:4px; font-size:11px; }
  .sp-note-del:hover { color:${colors.danger}; background:rgba(220,38,38,0.08); }
  .sp-note-input {
    width:100%; padding:10px 12px; border:1.5px solid ${colors.borderInput};
    border-radius:${radius.md}px; font-size:13px; font-family:${fonts.body};
    color:${colors.textPrimary}; resize:vertical; min-height:80px; outline:none;
    box-sizing:border-box; transition:border-color .15s;
  }
  .sp-note-input:focus { border-color:${colors.blue}; }

  .sp-detail-tabs {
    display:flex; gap:6px; padding:12px 16px;
    border-bottom:1px solid ${colors.border};
    background:#f8faff; flex-wrap:wrap;
  }
  .sp-detail-tab {
    display:inline-flex; align-items:center; gap:6px;
    padding:6px 12px; font-size:12px; font-weight:600; border:none;
    background:white; cursor:pointer; border-radius:20px;
    color:${colors.textSecondary}; font-family:${fonts.body};
    border:1.5px solid ${colors.borderInput}; transition:all .18s; white-space:nowrap;
  }
  .sp-detail-tab--active {
    background:${colors.navy}; color:white; border-color:${colors.navy};
    box-shadow:0 2px 8px rgba(11,24,82,0.18);
  }
  .sp-detail-tab:hover:not(.sp-detail-tab--active) {
    border-color:${colors.blue}; color:${colors.blue}; background:rgba(37,70,204,0.04);
  }
  .sp-detail-tab-count {
    display:inline-flex; align-items:center; justify-content:center;
    min-width:17px; height:17px; padding:0 4px;
    border-radius:9px; font-size:10px; font-weight:700;
  }
  .sp-detail-tab--active .sp-detail-tab-count { background:rgba(255,255,255,0.20); color:rgba(255,255,255,0.95); }
  .sp-detail-tab:not(.sp-detail-tab--active) .sp-detail-tab-count { background:rgba(37,70,204,0.10); color:${colors.blue}; }

  .sp-badge {
    display:inline-flex; align-items:center; gap:5px;
    padding:3px 10px; border-radius:${radius.full}px; font-size:11px; font-weight:700;
  }

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

  .sp-app-card {
    margin:8px 14px; border-radius:${radius.md}px;
    border:1.5px solid ${colors.border}; overflow:hidden;
    background:white; transition:border-color .15s, box-shadow .15s;
  }
  .sp-app-card:hover { border-color:${colors.borderHover}; box-shadow:0 2px 8px rgba(37,70,204,0.07); }

  .sp-score-breakdown {
    display:flex; gap:14px; padding:10px 20px 12px;
    background:${colors.inputBg}; border-bottom:1px solid ${colors.border};
    align-items:center; flex-wrap:wrap;
  }

  .sp-profile-body { padding:16px 18px; overflow-y:auto; max-height:560px; }
  .sp-profile-section { margin-bottom:20px; }
  .sp-profile-section-title {
    font-size:11px; font-weight:700; letter-spacing:.5px; text-transform:uppercase;
    color:${colors.textMuted}; margin-bottom:10px; padding-bottom:6px;
    border-bottom:1px solid ${colors.border};
  }
  .sp-profile-grid { display:grid; grid-template-columns:1fr 1fr; gap:10px; }
  @media(max-width:700px){ .sp-profile-grid{ grid-template-columns:1fr; } }
  .sp-profile-field {
    background:${colors.inputBg}; border-radius:10px;
    padding:10px 12px; border:1px solid ${colors.border};
  }
  .sp-profile-field--full { grid-column:1/-1; }
  .sp-profile-label { font-size:11px; font-weight:600; color:${colors.textMuted}; margin-bottom:3px; }
  .sp-profile-value { font-size:13px; font-weight:500; color:${colors.textPrimary}; line-height:1.5; }
  .sp-profile-value--empty { color:${colors.textMuted}; font-style:italic; font-weight:400; }
  .sp-profile-text {
    font-size:13px; color:${colors.textPrimary}; line-height:1.65;
    white-space:pre-wrap; word-break:break-word;
    background:${colors.inputBg}; border-radius:10px;
    padding:12px 14px; border:1px solid ${colors.border};
    max-height:180px; overflow-y:auto;
  }
  .sp-profile-text--empty { color:${colors.textMuted}; font-style:italic; }

  .sp-empty { display:flex; flex-direction:column; align-items:center;
    justify-content:center; min-height:260px; gap:10px;
    color:${colors.textMuted}; font-size:14px; text-align:center; }

  /* App timeline */
  .sp-app-timeline {
    display:flex; align-items:center; padding:10px 14px 0;
    gap:0;
  }
  .sp-timeline-step { display:flex; align-items:center; flex:1; }
  .sp-timeline-dot {
    width:20px; height:20px; border-radius:50%; flex-shrink:0;
    display:flex; align-items:center; justify-content:center;
  }
  .sp-timeline-line { flex:1; height:2px; }
  .sp-timeline-labels {
    display:flex; padding:4px 14px 12px; gap:0;
  }
  .sp-timeline-label { flex:1; font-size:9px; text-align:center; font-weight:600; white-space:nowrap; }

  .sp-grid .sp-stat:nth-child(1) { animation: ph-fade-up .35s .08s ease both; }
  .sp-grid .sp-stat:nth-child(2) { animation: ph-fade-up .35s .16s ease both; }
  .sp-grid .sp-stat:nth-child(3) { animation: ph-fade-up .35s .24s ease both; }
  .sp-grid .sp-stat:nth-child(4) { animation: ph-fade-up .35s .32s ease both; }
  .sp-layout { animation: ph-fade-up .35s .42s ease both; }
`;

export default function StudentsPage() {
  const [students,       setStudents]       = useState<Student[]>([]);
  const [loading,        setLoading]        = useState(true);
  const [search,         setSearch]         = useState('');
  const [tab,            setTab]            = useState<'all'|'complete'|'pending'>('all');
  const [scoreFilter,    setScoreFilter]    = useState<ScoreFilter>('');
  const [sortKey,        setSortKey]        = useState<SortKey>('score');
  const [sortDir,        setSortDir]        = useState<SortDir>('desc');
  const [selected,       setSelected]       = useState<Student | null>(null);
  const [docs,           setDocs]           = useState<StudentDoc[]>([]);
  const [docsLoading,    setDocsLoading]    = useState(false);
  const [rejectTarget,   setRejectTarget]   = useState<{ id: string; fileName: string } | null>(null);
  const [rejectReason,   setRejectReason]   = useState('');
  const [actionLoading,  setActionLoading]  = useState<string | null>(null);
  const [studentPage,    setStudentPage]    = useState(1);
  const [pageSize,       setPageSize]       = useState(10);
  const [detailTab,      setDetailTab]      = useState<'profile'|'docs'|'notes'|'apps'>('docs');
  const [notes,          setNotes]          = useState<StudentNote[]>([]);
  const [notesLoading,   setNotesLoading]   = useState(false);
  const [noteText,       setNoteText]       = useState('');
  const [savingNote,     setSavingNote]     = useState(false);
  const [apps,           setApps]           = useState<StudentApp[]>([]);
  const [appsLoading,    setAppsLoading]    = useState(false);
  const [profileData,    setProfileData]    = useState<StudentProfileDetail | null>(null);
  const [profileLoading, setProfileLoading] = useState(false);
  const [appCounts,      setAppCounts]      = useState<Record<string, number>>({});
  const reasonRef = useRef<HTMLTextAreaElement>(null);

  /* Charger étudiants + comptes candidatures */
  useEffect(() => {
    (async () => {
      setLoading(true);
      const [{ data: studs }, { data: appData }] = await Promise.all([
        supabase
          .from('student_profiles')
          .select('id, first_name, last_name, photo_url, completeness_score, nationality')
          .order('completeness_score', { ascending: false }),
        supabase
          .from('applications')
          .select('student_profile_id'),
      ]);
      setStudents(studs ?? []);
      const counts: Record<string, number> = {};
      (appData ?? []).forEach((a: any) => {
        counts[a.student_profile_id] = (counts[a.student_profile_id] ?? 0) + 1;
      });
      setAppCounts(counts);
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

  /* Charger profil détaillé */
  useEffect(() => {
    if (!selected) { setProfileData(null); return; }
    setProfileLoading(true);
    supabase
      .from('student_profiles')
      .select('phone, birth_date, country_residence, address, motivation_letter, academic_goals, career_goals, ai_completeness_score, ai_summary')
      .eq('id', selected.id)
      .single()
      .then(({ data }) => { setProfileData(data ?? null); setProfileLoading(false); });
  }, [selected]);

  /* Charger notes */
  useEffect(() => {
    if (!selected) { setNotes([]); setDetailTab('docs'); return; }
    setNotesLoading(true);
    supabase
      .from('student_notes')
      .select('id, content, author_email, created_at')
      .eq('student_id', selected.id)
      .order('created_at', { ascending: false })
      .then(({ data }) => { setNotes(data ?? []); setNotesLoading(false); });
  }, [selected]);

  /* Charger candidatures */
  useEffect(() => {
    if (!selected) { setApps([]); return; }
    setAppsLoading(true);
    supabase
      .from('applications')
      .select('id, status, submitted_at, programs!program_id(program_name, university_name, country, level)')
      .eq('student_profile_id', selected.id)
      .order('submitted_at', { ascending: false })
      .then(({ data }) => {
        setApps((data ?? []).map((a: any) => ({
          id:              a.id,
          status:          a.status,
          submitted_at:    a.submitted_at,
          program_name:    a.programs?.program_name    ?? 'Programme inconnu',
          university_name: a.programs?.university_name ?? '',
          country:         a.programs?.country         ?? '',
          level:           a.programs?.level           ?? '',
        })));
        setAppsLoading(false);
      });
  }, [selected]);

  const addNote = async () => {
    if (!noteText.trim() || !selected) return;
    setSavingNote(true);
    const { data: { user } } = await supabase.auth.getUser();
    const { data } = await supabase
      .from('student_notes')
      .insert({ student_id: selected.id, content: noteText.trim(), author_email: user?.email })
      .select('id, content, author_email, created_at')
      .single();
    if (data) setNotes(prev => [data, ...prev]);
    setNoteText('');
    setSavingNote(false);
  };

  const deleteNote = async (id: string) => {
    await supabase.from('student_notes').delete().eq('id', id);
    setNotes(prev => prev.filter(n => n.id !== id));
  };

  const approve = async (docId: string) => {
    setActionLoading(docId);
    const { error } = await supabase.from('documents')
      .update({ status: 'approved', rejection_reason: null }).eq('id', docId);
    if (error) {
      console.error('[approve] Supabase error:', error.message, error.details);
      setActionLoading(null);
      return;
    }
    setDocs(prev => prev.map(d =>
      d.id === docId ? { ...d, status: 'approved', rejection_reason: null } : d));
    if (selected) {
      supabase.functions.invoke('send-push-notification', {
        body: {
          user_ids: [selected.id],
          title:    'Document approuve',
          body:     'Un document de votre dossier a ete approuve par l\'equipe Studium.',
          data:     { type: 'document_approved', document_id: docId },
        },
      }).catch(console.error);
    }
    setActionLoading(null);
  };

  const confirmReject = async () => {
    if (!rejectTarget || !rejectReason.trim()) return;
    setActionLoading(rejectTarget.id);
    const reason = rejectReason.trim();
    const { error } = await supabase.from('documents')
      .update({ status: 'rejected', rejection_reason: reason })
      .eq('id', rejectTarget.id);
    if (error) {
      console.error('[confirmReject] Supabase error:', error.message, error.details);
      setActionLoading(null);
      setRejectTarget(null);
      setRejectReason('');
      return;
    }
    setDocs(prev => prev.map(d =>
      d.id === rejectTarget.id ? { ...d, status: 'rejected', rejection_reason: reason } : d));
    if (selected) {
      supabase.functions.invoke('send-push-notification', {
        body: {
          user_ids: [selected.id],
          title:    'Document rejete',
          body:     `Un de vos documents a ete rejete. Motif : ${reason.length > 80 ? reason.substring(0, 77) + '...' : reason}`,
          data:     { type: 'document_rejected', document_id: rejectTarget.id },
        },
      }).catch(console.error);
    }
    setActionLoading(null);
    setRejectTarget(null);
    setRejectReason('');
  };

  const toggleSort = (key: SortKey) => {
    if (sortKey === key) setSortDir(d => d === 'desc' ? 'asc' : 'desc');
    else { setSortKey(key); setSortDir('desc'); }
  };

  /* Filtres + tri */
  const filtered = useMemo(() => {
    let list = students.filter(s =>
      fullName(s).toLowerCase().includes(search.toLowerCase()) ||
      (s.nationality ?? '').toLowerCase().includes(search.toLowerCase()));
    if (tab === 'complete') list = list.filter(s => s.completeness_score >= 80);
    if (tab === 'pending')  list = list.filter(s => s.completeness_score < 80);
    if (scoreFilter === 'low')  list = list.filter(s => s.completeness_score < 50);
    if (scoreFilter === 'mid')  list = list.filter(s => s.completeness_score >= 50 && s.completeness_score < 80);
    if (scoreFilter === 'high') list = list.filter(s => s.completeness_score >= 80);

    return [...list].sort((a, b) => {
      if (sortKey === 'score') {
        return sortDir === 'desc'
          ? b.completeness_score - a.completeness_score
          : a.completeness_score - b.completeness_score;
      }
      if (sortKey === 'apps') {
        const ca = appCounts[a.id] ?? 0;
        const cb = appCounts[b.id] ?? 0;
        return sortDir === 'desc' ? cb - ca : ca - cb;
      }
      const cmp = fullName(a).localeCompare(fullName(b), 'fr');
      return sortDir === 'asc' ? cmp : -cmp;
    });
  }, [students, search, tab, scoreFilter, sortKey, sortDir, appCounts]);

  const hasActiveFilters = !!(search || scoreFilter || tab !== 'all' || sortKey !== 'score');
  const resetFilters = () => { setSearch(''); setScoreFilter(''); setTab('all'); setSortKey('score'); setSortDir('desc'); };

  useEffect(() => { setStudentPage(1); }, [search, tab, scoreFilter, sortKey]);

  const studentTotalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const paginatedStudents = filtered.slice((studentPage - 1) * pageSize, studentPage * pageSize);

  const avgScore  = students.length
    ? Math.round(students.reduce((a, s) => a + s.completeness_score, 0) / students.length) : 0;
  const totalApps = Object.values(appCounts).reduce((s, c) => s + c, 0);

  const stats = [
    { label: 'Total etudiants', value: String(students.length), accent: colors.blue,    iconBg: 'rgba(37,70,204,0.12)',  iconColor: colors.blue,
      icon: <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg> },
    { label: 'Profils complets', value: String(students.filter(s => s.completeness_score >= 80).length), accent: colors.success, iconBg: 'rgba(22,163,74,0.12)', iconColor: colors.success,
      icon: <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg> },
    { label: 'Total candidatures', value: String(totalApps), accent: colors.warning, iconBg: 'rgba(217,119,6,0.12)', iconColor: colors.warning,
      icon: <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}><path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/></svg> },
    { label: 'Score moyen', value: `${avgScore}%`, accent: '#0891b2', iconBg: 'rgba(8,145,178,0.12)', iconColor: '#0891b2',
      icon: <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg> },
  ];

  const SortBtn = ({ k, label }: { k: SortKey; label: string }) => (
    <button
      className={`sp-sort-btn${sortKey === k ? ' sp-sort-btn--active' : ''}`}
      onClick={() => toggleSort(k)}
    >
      {label}
      <svg width={10} height={10} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} style={{
        transform: sortKey === k && sortDir === 'asc' ? 'rotate(180deg)' : 'rotate(0deg)',
        transition: 'transform .15s',
        opacity: sortKey === k ? 1 : 0.35,
      }}>
        <polyline points="6 9 12 15 18 9"/>
      </svg>
    </button>
  );

  return (
    <>
      <style>{CSS}</style>

      <PageHeader
        title="Gestion des etudiants"
        subtitle={`${students.length} etudiant${students.length !== 1 ? 's' : ''} enregistre${students.length !== 1 ? 's' : ''}`}
        actions={
          <Button variant="secondary" size="sm" onClick={() =>
            downloadCsv(`etudiants_${new Date().toISOString().split('T')[0]}.csv`,
              students.map(s => ({
                'Prenom':       s.first_name ?? '',
                'Nom':          s.last_name ?? '',
                'Nationalite':  s.nationality ?? '',
                'Completude %': s.completeness_score,
                'Candidatures': appCounts[s.id] ?? 0,
              }))
            )
          }>Export CSV</Button>
        }
      />

      {/* Stats */}
      <div className="sp-grid">
        {stats.map(s => (
          <div key={s.label} className="sp-stat">
            <div className="sp-stat-top" style={{ background: s.accent }} />
            <div className="sp-stat-inner">
              <div className="sp-stat-icon" style={{ background: s.iconBg, color: s.iconColor }}>
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

      <div className="sp-layout">

        {/* Liste étudiants */}
        <div className="sp-panel">
          <div style={{ height: 3, background: `linear-gradient(90deg, ${colors.blue}, #7c3aed)` }} />

          {/* Tabs */}
          <div className="sp-tabs">
            {([
              { key: 'all',      label: 'Tous',       count: students.length },
              { key: 'complete', label: 'Complets',    count: students.filter(s => s.completeness_score >= 80).length },
              { key: 'pending',  label: 'Incomplets',  count: students.filter(s => s.completeness_score < 80).length },
            ] as const).map(t => (
              <button
                key={t.key}
                className={`sp-tab${tab === t.key ? ' sp-tab--active' : ''}`}
                onClick={() => setTab(t.key)}
              >
                {t.label}
                <span style={{
                  marginLeft: 5, padding: '1px 6px', borderRadius: 10,
                  background: tab === t.key ? 'rgba(37,70,204,0.12)' : colors.border,
                  color: tab === t.key ? colors.blue : colors.textMuted, fontSize: 11,
                }}>
                  {t.count}
                </span>
              </button>
            ))}
          </div>

          {/* Toolbar */}
          <div className="sp-toolbar">
            {/* Recherche */}
            <div className="sp-search-wrap">
              <svg style={{ position:'absolute', left:9, top:'50%', transform:'translateY(-50%)', color: colors.textMuted }}
                width={14} height={14} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
              </svg>
              <input
                className="sp-search"
                placeholder="Nom, nationalite..."
                value={search}
                onChange={e => setSearch(e.target.value)}
              />
            </div>

            {/* Filtre score */}
            <select
              className={`sp-toolbar-select${scoreFilter ? ' sp-toolbar-select--active' : ''}`}
              value={scoreFilter}
              onChange={e => setScoreFilter(e.target.value as ScoreFilter)}
            >
              <option value="">Score : tous</option>
              <option value="low">0 – 49 %</option>
              <option value="mid">50 – 79 %</option>
              <option value="high">80 % +</option>
            </select>

            {/* Tri */}
            <SortBtn k="score" label="Score" />
            <SortBtn k="name"  label="Nom"   />
            <SortBtn k="apps"  label="Candid." />

            {hasActiveFilters && (
              <button className="sp-reset-btn" onClick={resetFilters}>Reinitialiser</button>
            )}
          </div>

          {/* Barre résultats */}
          <div className="sp-results-bar">
            <span style={{ fontWeight: 600, color: colors.textSecondary }}>
              {filtered.length} / {students.length} etudiant{students.length !== 1 ? 's' : ''}
            </span>
            {search && (
              <span className="sp-results-tag">"{search}"</span>
            )}
            {scoreFilter === 'low'  && <span className="sp-results-tag">Score 0-49%</span>}
            {scoreFilter === 'mid'  && <span className="sp-results-tag">Score 50-79%</span>}
            {scoreFilter === 'high' && <span className="sp-results-tag">Score 80%+</span>}
            {tab === 'complete' && <span className="sp-results-tag">Complets</span>}
            {tab === 'pending'  && <span className="sp-results-tag">Incomplets</span>}
          </div>

          {/* Rows */}
          {loading ? (
            <div style={{ padding: 48, textAlign: 'center' }}><LoadingSpinner /></div>
          ) : filtered.length === 0 ? (
            <div className="sp-empty">
              <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke={colors.textMuted} strokeWidth="1.5" strokeLinecap="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
              <span>Aucun etudiant trouve</span>
            </div>
          ) : (
            <>
              <div>
                {paginatedStudents.map(student => {
                  const [fg, bg] = avatarColor(fullName(student));
                  const active   = selected?.id === student.id;
                  const sc       = student.completeness_score;
                  const appCount = appCounts[student.id] ?? 0;
                  return (
                    <div
                      key={student.id}
                      className={`sp-row${active ? ' sp-row--active' : ''}`}
                      onClick={() => setSelected(student)}
                    >
                      <div className="sp-avatar" style={{ background: bg, color: fg }}>{initials(student)}</div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 6 }}>
                          <span style={{ fontWeight: 600, fontSize: 13, color: colors.textPrimary, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' }}>
                            {fullName(student)}
                          </span>
                          <span style={{ fontSize: 12, fontWeight: 700, color: SCORE_COLOR(sc), flexShrink: 0 }}>
                            {sc}%
                          </span>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 2 }}>
                          <span style={{ fontSize: 11, color: colors.textMuted }}>
                            {student.nationality ?? 'Nationalite inconnue'}
                          </span>
                          {appCount > 0 && (
                            <span style={{
                              fontSize: 10, fontWeight: 700, padding: '1px 6px', borderRadius: 10,
                              background: 'rgba(37,70,204,0.08)', color: colors.blue,
                            }}>
                              {appCount} candid.
                            </span>
                          )}
                        </div>
                        <div className="sp-bar-bg">
                          <div className="sp-bar-fill" style={{ width: `${sc}%`, background: SCORE_COLOR(sc) }} />
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
              <Pagination
                page={studentPage}
                totalPages={studentTotalPages}
                total={filtered.length}
                pageSize={pageSize}
                onChange={setStudentPage}
                onPageSizeChange={size => { setPageSize(size); setStudentPage(1); }}
                label="etudiants"
              />
            </>
          )}
        </div>

        {/* Panel détail */}
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
              <div style={{ fontWeight: 700, fontSize: 15, color: colors.textSecondary, marginTop: 4 }}>Selectionnez un etudiant</div>
              <div style={{ fontSize: 12, color: colors.textMuted }}>pour consulter et gerer son profil</div>
            </div>
          ) : (
            <>
              {/* Header */}
              <div style={{
                padding: '16px 20px 14px',
                borderBottom: `1px solid ${colors.border}`,
                background: 'linear-gradient(135deg, #f8faff 0%, #fff 100%)',
              }}>
                <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 }}>
                  <div style={{ display: 'flex', gap: 14, alignItems: 'center', minWidth: 0 }}>
                    {(() => {
                      const [fg, bg] = avatarColor(fullName(selected));
                      return (
                        <div style={{
                          width: 50, height: 50, borderRadius: 15, flexShrink: 0,
                          background: bg, color: fg, fontSize: 16, fontWeight: 800,
                          fontFamily: fonts.display,
                          display: 'flex', alignItems: 'center', justifyContent: 'center',
                          boxShadow: `0 0 0 3px white, 0 0 0 4px ${bg}`,
                        }}>
                          {initials(selected)}
                        </div>
                      );
                    })()}
                    <div style={{ minWidth: 0 }}>
                      <div style={{ fontWeight: 800, fontSize: 16, color: colors.navy, fontFamily: fonts.display, letterSpacing: '-.2px' }}>
                        {fullName(selected)}
                      </div>
                      <div style={{ display: 'flex', gap: 7, marginTop: 4, alignItems: 'center', flexWrap: 'wrap' }}>
                        {selected.nationality && (
                          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 11.5, color: colors.textSecondary }}>
                            <svg width={10} height={10} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>
                            {selected.nationality}
                          </span>
                        )}
                        <span style={{
                          fontSize: 11, fontWeight: 700, padding: '2px 8px', borderRadius: 20,
                          background: `${SCORE_COLOR(selected.completeness_score)}18`,
                          color: SCORE_COLOR(selected.completeness_score),
                        }}>
                          {selected.completeness_score}% complet
                        </span>
                        {/* Mini-stats dans le header */}
                        {!docsLoading && docs.length > 0 && (
                          <span style={{ fontSize: 11, fontWeight: 600, color: colors.textMuted, padding: '2px 8px', borderRadius: 20, background: colors.inputBg }}>
                            {docs.filter(d => d.status === 'approved').length}/{docs.length} docs
                          </span>
                        )}
                        {(appCounts[selected.id] ?? 0) > 0 && (
                          <span style={{ fontSize: 11, fontWeight: 600, color: colors.textMuted, padding: '2px 8px', borderRadius: 20, background: colors.inputBg }}>
                            {appCounts[selected.id]} candid.
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                  <button
                    onClick={() => setSelected(null)}
                    style={{
                      width: 28, height: 28, borderRadius: 8, flexShrink: 0,
                      border: `1.5px solid ${colors.borderInput}`,
                      background: 'white', cursor: 'pointer',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      color: colors.textMuted,
                    }}
                  >
                    <svg width={12} height={12} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                  </button>
                </div>
              </div>

              {/* Score bar */}
              {!docsLoading && docs.length > 0 && (() => {
                const approved = docs.filter(d => d.status === 'approved').length;
                const rejected = docs.filter(d => d.status === 'rejected').length;
                const pending  = docs.length - approved - rejected;
                const sc       = selected.completeness_score;
                const barColor = SCORE_COLOR(sc);
                return (
                  <div className="sp-score-breakdown">
                    <div style={{ flex: 1, minWidth: 160 }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 5 }}>
                        <span style={{ fontSize: 11.5, fontWeight: 600, color: colors.textSecondary }}>Score de completude</span>
                        <span style={{ fontSize: 12, fontWeight: 800, color: barColor }}>{sc}%</span>
                      </div>
                      <div className="sp-bar-bg" style={{ height: 6, borderRadius: 3 }}>
                        <div className="sp-bar-fill" style={{ width: `${sc}%`, background: barColor, height: 6, borderRadius: 3 }} />
                      </div>
                    </div>
                    <div style={{ display: 'flex', gap: 8, flexShrink: 0 }}>
                      {approved > 0 && <span style={{ fontSize: 11, fontWeight: 600, color: '#16a34a', background: 'rgba(22,163,74,0.10)', padding: '2px 8px', borderRadius: 6 }}>{approved} approuv{approved > 1 ? 'es' : 'e'}</span>}
                      {pending  > 0 && <span style={{ fontSize: 11, fontWeight: 600, color: '#d97706', background: 'rgba(217,119,6,0.10)',  padding: '2px 8px', borderRadius: 6 }}>{pending} en attente</span>}
                      {rejected > 0 && <span style={{ fontSize: 11, fontWeight: 600, color: '#dc2626', background: 'rgba(220,38,38,0.10)', padding: '2px 8px', borderRadius: 6 }}>{rejected} rejet{rejected > 1 ? 'es' : 'e'}</span>}
                    </div>
                  </div>
                );
              })()}

              {/* Onglets */}
              <div className="sp-detail-tabs">
                {([
                  { key: 'profile', label: 'Profil',       count: null        },
                  { key: 'docs',    label: 'Documents',    count: docs.length },
                  { key: 'apps',    label: 'Candidatures', count: apps.length },
                  { key: 'notes',   label: 'Notes',        count: notes.length },
                ] as const).map(t => (
                  <button
                    key={t.key}
                    className={`sp-detail-tab${detailTab === t.key ? ' sp-detail-tab--active' : ''}`}
                    onClick={() => setDetailTab(t.key)}
                  >
                    {t.label}
                    {t.count !== null && <span className="sp-detail-tab-count">{t.count}</span>}
                  </button>
                ))}
              </div>

              {/* Profil */}
              {detailTab === 'profile' && (
                profileLoading ? (
                  <div style={{ padding: 48, textAlign: 'center' }}><LoadingSpinner /></div>
                ) : (
                  <div className="sp-profile-body">
                    <div className="sp-profile-section">
                      <div className="sp-profile-section-title">Coordonnees</div>
                      <div className="sp-profile-grid">
                        {([
                          { label: 'Telephone',         value: profileData?.phone },
                          { label: 'Nationalite',       value: selected.nationality },
                          { label: 'Date de naissance', value: profileData?.birth_date ? fmtDate(profileData.birth_date) : null },
                          { label: 'Pays de residence', value: profileData?.country_residence },
                          { label: 'Adresse',           value: profileData?.address },
                        ] as { label: string; value: string | null | undefined }[]).map(f => (
                          <div key={f.label} className="sp-profile-field">
                            <div className="sp-profile-label">{f.label}</div>
                            <div className={`sp-profile-value${!f.value ? ' sp-profile-value--empty' : ''}`}>
                              {f.value || 'Non renseigne'}
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>

                    <div className="sp-profile-section">
                      <div className="sp-profile-section-title">Projet academique</div>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                        <div>
                          <div className="sp-profile-label" style={{ marginBottom: 6 }}>Lettre de motivation</div>
                          <div className={`sp-profile-text${!profileData?.motivation_letter ? ' sp-profile-text--empty' : ''}`}>
                            {profileData?.motivation_letter || 'Aucune lettre redigee'}
                          </div>
                        </div>
                        <div className="sp-profile-grid">
                          <div className="sp-profile-field sp-profile-field--full">
                            <div className="sp-profile-label">Objectifs academiques</div>
                            <div className={`sp-profile-value${!profileData?.academic_goals ? ' sp-profile-value--empty' : ''}`}
                              style={{ whiteSpace: 'pre-wrap', lineHeight: 1.6 }}>
                              {profileData?.academic_goals || 'Non renseigne'}
                            </div>
                          </div>
                          <div className="sp-profile-field sp-profile-field--full">
                            <div className="sp-profile-label">Objectifs professionnels</div>
                            <div className={`sp-profile-value${!profileData?.career_goals ? ' sp-profile-value--empty' : ''}`}
                              style={{ whiteSpace: 'pre-wrap', lineHeight: 1.6 }}>
                              {profileData?.career_goals || 'Non renseigne'}
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    {(profileData?.ai_summary || profileData?.ai_completeness_score != null) && (
                      <div className="sp-profile-section">
                        <div className="sp-profile-section-title" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <span>Analyse IA</span>
                          {profileData?.ai_completeness_score != null && (
                            <span style={{ fontSize: 11, fontWeight: 700, padding: '2px 8px', borderRadius: 6, background: 'rgba(124,58,237,0.10)', color: '#7c3aed', textTransform: 'none' }}>
                              Score IA : {profileData.ai_completeness_score}%
                            </span>
                          )}
                        </div>
                        {profileData?.ai_summary && (
                          <div className="sp-profile-text" style={{ fontSize: 12.5, color: colors.textSecondary }}>
                            {profileData.ai_summary}
                          </div>
                        )}
                      </div>
                    )}

                    <div className="sp-profile-section">
                      <div className="sp-profile-section-title">Completude du profil</div>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                        {(() => {
                          const p = profileData;
                          const sections = [
                            { label: 'Identite',    score: [selected.first_name, selected.last_name, p?.phone, selected.nationality].filter(Boolean).length / 4 * 100 },
                            { label: 'Objectifs',   score: [p?.motivation_letter, p?.academic_goals, p?.career_goals].filter(Boolean).length / 3 * 100 },
                            { label: 'Documents',   score: docs.filter(d => d.status === 'approved').length > 0 ? 100 : 0 },
                          ];
                          return sections.map(s => (
                            <div key={s.label}>
                              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                                <span style={{ fontSize: 12, fontWeight: 600, color: colors.textSecondary }}>{s.label}</span>
                                <span style={{ fontSize: 12, fontWeight: 700, color: SCORE_COLOR(s.score) }}>{Math.round(s.score)}%</span>
                              </div>
                              <div className="sp-bar-bg" style={{ height: 5, borderRadius: 3 }}>
                                <div className="sp-bar-fill" style={{ width: `${s.score}%`, background: SCORE_COLOR(s.score), height: 5, borderRadius: 3 }} />
                              </div>
                            </div>
                          ));
                        })()}
                      </div>
                    </div>
                  </div>
                )
              )}

              {/* Notes */}
              {detailTab === 'notes' && (
                <div style={{ padding: '14px 0', overflowY: 'auto', maxHeight: 520 }}>
                  <div style={{ padding: '0 14px 14px' }}>
                    <textarea
                      className="sp-note-input"
                      placeholder="Ajouter une note interne (visible uniquement par l'equipe)..."
                      value={noteText}
                      onChange={e => setNoteText(e.target.value)}
                    />
                    <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: 8 }}>
                      <Button size="sm" loading={savingNote} onClick={addNote} disabled={!noteText.trim()}>
                        Enregistrer la note
                      </Button>
                    </div>
                  </div>
                  {notesLoading ? (
                    <div style={{ padding: 32, textAlign: 'center' }}><LoadingSpinner /></div>
                  ) : notes.length === 0 ? (
                    <div className="sp-empty" style={{ padding: '32px 20px' }}>
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke={colors.textMuted} strokeWidth="1.5" strokeLinecap="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                      <span>Aucune note pour cet etudiant</span>
                    </div>
                  ) : (
                    notes.map(note => (
                      <div key={note.id} className="sp-note-card">
                        <div className="sp-note-content">{note.content}</div>
                        <div className="sp-note-meta">
                          <span>{note.author_email ?? 'Equipe'} · {new Date(note.created_at).toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })}</span>
                          <button className="sp-note-del" onClick={() => deleteNote(note.id)}>Supprimer</button>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              )}

              {/* Candidatures */}
              {detailTab === 'apps' && (
                appsLoading ? (
                  <div style={{ padding: 48, textAlign: 'center' }}><LoadingSpinner /></div>
                ) : apps.length === 0 ? (
                  <div className="sp-empty">
                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke={colors.textMuted} strokeWidth="1.5" strokeLinecap="round">
                      <path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/>
                    </svg>
                    <span>Aucune candidature pour cet etudiant</span>
                  </div>
                ) : (
                  <div style={{ overflowY: 'auto', maxHeight: 560, paddingBottom: 14, paddingTop: 6 }}>
                    {/* Mini-stats candidatures */}
                    <div style={{ display: 'flex', gap: 8, padding: '8px 14px 2px', flexWrap: 'wrap' }}>
                      {(['accepted', 'submitted', 'rejected'] as const).map(st => {
                        const count = apps.filter(a => a.status === st).length;
                        if (!count) return null;
                        const cfg = APP_STATUS_CFG[st];
                        return (
                          <span key={st} style={{ fontSize: 11, fontWeight: 700, padding: '2px 9px', borderRadius: 20, background: cfg.bg, color: cfg.color }}>
                            {count} {cfg.label.toLowerCase()}
                          </span>
                        );
                      })}
                    </div>
                    {apps.map(app => {
                      const cfg  = APP_STATUS_CFG[app.status] ?? APP_STATUS_CFG.submitted;
                      const step = cfg.step;
                      const isRejected  = app.status === 'rejected';
                      const isAccepted  = app.status === 'accepted';
                      const isNeedsFix  = app.status === 'needsfix';
                      const date = app.submitted_at
                        ? new Date(app.submitted_at).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' })
                        : null;

                      return (
                        <div key={app.id} className="sp-app-card">
                          {/* Accent top bar */}
                          <div style={{ height: 2.5, background: isRejected ? '#dc2626' : isAccepted ? '#16a34a' : isNeedsFix ? '#f59e0b' : cfg.color }} />

                          <div style={{ padding: '11px 14px 0' }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 10 }}>
                              <div style={{ minWidth: 0, flex: 1 }}>
                                <div style={{ fontWeight: 700, fontSize: 13, color: colors.navy, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                  {app.program_name}
                                </div>
                                {app.university_name && (
                                  <div style={{ fontSize: 11.5, color: colors.textSecondary, marginTop: 2, display: 'flex', gap: 5, alignItems: 'center' }}>
                                    <svg width={10} height={10} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round">
                                      <path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/>
                                    </svg>
                                    {app.university_name}
                                    {app.country && <span style={{ color: colors.textMuted }}>· {app.country}</span>}
                                    {app.level && <span style={{ color: colors.textMuted }}>· {app.level}</span>}
                                  </div>
                                )}
                              </div>
                              <span style={{
                                fontSize: 10.5, fontWeight: 700, padding: '3px 8px',
                                borderRadius: 6, whiteSpace: 'nowrap', flexShrink: 0,
                                background: cfg.bg, color: cfg.color,
                              }}>
                                {cfg.label}
                              </span>
                            </div>
                          </div>

                          {/* Mini-timeline */}
                          {!isRejected && !isNeedsFix && (
                            <div>
                              <div className="sp-app-timeline">
                                {APP_STEPS.map((_, i) => {
                                  const done  = i <= step;
                                  const isLast = i === APP_STEPS.length - 1;
                                  return (
                                    <div key={i} className="sp-timeline-step">
                                      <div className="sp-timeline-dot" style={{
                                        background: done
                                          ? (isAccepted && i === step ? '#16a34a' : colors.blue)
                                          : colors.border,
                                        width: i === step ? 22 : 16,
                                        height: i === step ? 22 : 16,
                                      }}>
                                        {done && (
                                          <svg width={i === step ? 11 : 8} height={i === step ? 11 : 8} viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth={3} strokeLinecap="round">
                                            <polyline points="20 6 9 17 4 12"/>
                                          </svg>
                                        )}
                                      </div>
                                      {!isLast && (
                                        <div className="sp-timeline-line" style={{ background: done ? colors.blue : colors.border }} />
                                      )}
                                    </div>
                                  );
                                })}
                              </div>
                              <div className="sp-timeline-labels">
                                {APP_STEPS.map((label, i) => (
                                  <span key={i} className="sp-timeline-label" style={{
                                    color: i <= step ? (isAccepted ? '#16a34a' : colors.blue) : colors.textMuted,
                                  }}>
                                    {label}
                                  </span>
                                ))}
                              </div>
                            </div>
                          )}

                          {/* Correction requise */}
                          {isNeedsFix && (
                            <div style={{ margin: '8px 12px 0', padding: '7px 10px', background: '#fff7ed', borderRadius: 7, border: '1px solid #fed7aa', fontSize: 11.5, color: '#c2410c', display: 'flex', gap: 6, alignItems: 'center' }}>
                              <svg width={12} height={12} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
                              Correction demandee a l'etudiant
                            </div>
                          )}

                          {date && (
                            <div style={{ padding: '6px 14px 10px', fontSize: 10.5, color: colors.textMuted, display: 'flex', alignItems: 'center', gap: 4 }}>
                              <svg width={9} height={9} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} strokeLinecap="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                              Soumise le {date}
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                )
              )}

              {/* Documents */}
              {detailTab === 'docs' && docsLoading ? (
                <div style={{ padding: 48, textAlign: 'center' }}><LoadingSpinner /></div>
              ) : detailTab === 'docs' && docs.length === 0 ? (
                <div className="sp-empty">
                  <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke={colors.textMuted} strokeWidth="1.5" strokeLinecap="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                  <span>Aucun document uploade</span>
                </div>
              ) : detailTab === 'docs' ? (
                <div style={{ overflowY: 'auto', maxHeight: 560, paddingBottom: 14 }}>
                  {docs.map(doc => {
                    const cfg  = STATUS_CFG[doc.status] ?? STATUS_CFG.uploaded;
                    const tc   = TYPE_COLOR[doc.type]   ?? TYPE_COLOR.other;
                    const busy = actionLoading === doc.id;
                    const isRejected = doc.status === 'rejected';
                    return (
                      <div key={doc.id} className={`sp-doc-card${isRejected ? ' sp-doc-card--rejected' : ''}`}>
                        <div style={{ display: 'flex', gap: 12, padding: '13px 15px', alignItems: 'flex-start' }}>
                          <div style={{
                            width: 40, height: 40, borderRadius: 10,
                            background: tc.bg, color: tc.color,
                            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                          }}>
                            {tc.icon}
                          </div>
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
                        {isRejected && doc.rejection_reason && (
                          <div style={{
                            margin: '0 14px 10px', padding: '8px 11px',
                            background: 'rgba(220,38,38,0.06)', borderRadius: 7,
                            border: '1px solid rgba(220,38,38,0.15)',
                            fontSize: 12, color: colors.danger,
                          }}>
                            <strong>Motif :</strong> {doc.rejection_reason}
                          </div>
                        )}
                        <div style={{
                          display: 'flex', gap: 8, padding: '9px 14px',
                          borderTop: `1px solid ${colors.border}`,
                          background: colors.inputBg, flexWrap: 'wrap',
                        }}>
                          <a href={doc.file_url} target="_blank" rel="noreferrer"
                            className="sp-btn-act sp-btn-act--view"
                            style={{ color: colors.blue }}>
                            <svg width={12} height={12} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                            Voir le fichier
                          </a>
                          {doc.status !== 'approved' && (
                            <button className="sp-btn-act sp-btn-act--approve" disabled={busy} onClick={() => approve(doc.id)}
                              style={{ color: colors.success }}>
                              <svg width={12} height={12} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}><path d="M20 6 9 17l-5-5"/></svg>
                              {busy ? 'En cours' : 'Approuver'}
                            </button>
                          )}
                          {doc.status !== 'rejected' && (
                            <button className="sp-btn-act sp-btn-act--reject" disabled={busy}
                              onClick={() => setRejectTarget({ id: doc.id, fileName: doc.file_name })}
                              style={{ color: colors.danger }}>
                              <svg width={12} height={12} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}><path d="M18 6 6 18M6 6l12 12"/></svg>
                              Rejeter
                            </button>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              ) : null}
            </>
          )}
        </div>
      </div>

      {/* Modal rejet */}
      {rejectTarget && (
        <div className="sp-overlay" onClick={() => { setRejectTarget(null); setRejectReason(''); }}>
          <div className="sp-modal" onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16 }}>
              <div style={{ width: 40, height: 40, borderRadius: 11, background: 'rgba(220,38,38,0.10)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <svg width={18} height={18} fill="none" viewBox="0 0 24 24" stroke={colors.danger} strokeWidth={2}><path d="M18 6 6 18M6 6l12 12"/></svg>
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