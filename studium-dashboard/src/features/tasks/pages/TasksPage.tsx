import { useState, useEffect, useRef, useCallback } from 'react';
import { colors, fonts } from '../../../shared/constants/theme';
import { PageHeader } from '../../../shared/components/PageHeader';
import { Button } from '../../../shared/components/Button';
import { fetchTasks, createTask, updateTask, completeTask, deleteTask, searchApplications } from '../services/tasks_service';
import type { Task } from '../services/tasks_service';
import { useRole } from '../../auth/hooks/useRole';
import { supabase } from '../../../shared/services/supabase';

const CSS = `
  .tasks-root { animation: fadeInUp .25s ease; }
  @keyframes fadeInUp { from{opacity:0;transform:translateY(8px)} to{opacity:1;transform:none} }

  .tasks-toggle {
    height:36px; padding:0 14px; border:1.5px solid rgba(255,255,255,0.3);
    border-radius:8px; font-size:13px; font-family:${fonts.body};
    background:rgba(255,255,255,0.12); cursor:pointer; color:white;
    transition:background .15s;
  }
  .tasks-toggle:hover { background:rgba(255,255,255,0.22); }

  .tasks-tabs { display:flex; gap:6px; margin-bottom:20px; }
  .tasks-tab {
    padding:6px 14px; border-radius:20px; font-size:12px; font-weight:600;
    cursor:pointer; border:none; font-family:${fonts.body};
    transition:background .15s, color .15s;
  }
  .tasks-tab.active { background:${colors.navy}; color:white; }
  .tasks-tab:not(.active) { background:${colors.pageBg}; color:${colors.textSecondary}; }
  .tasks-tab:not(.active):hover { background:#e2e6f3; }

  .tasks-list { display:flex; flex-direction:column; gap:10px; }

  .task-card {
    background:white; border-radius:12px; border:1px solid ${colors.border};
    padding:16px 16px 16px 18px; display:flex; gap:14px; align-items:flex-start;
    box-shadow:0 2px 6px rgba(11,24,82,0.04); transition:box-shadow .15s;
    border-left:3px solid transparent;
  }
  .task-card:hover { box-shadow:0 4px 16px rgba(11,24,82,0.09); }
  .task-card.completed { opacity:.5; }
  .task-card.pri-urgent:not(.completed) { border-left-color:#dc2626; }
  .task-card.pri-faible:not(.completed)  { border-left-color:#16a34a; }
  .task-card.pri-normal:not(.completed)  { border-left-color:${colors.blue}; }

  .task-status-dot {
    width:8px; height:8px; border-radius:50%; flex-shrink:0; margin-top:6px;
    background:${colors.blue};
  }
  .pri-urgent .task-status-dot  { background:#dc2626; }
  .pri-faible .task-status-dot  { background:#16a34a; }
  .pri-normal .task-status-dot  { background:${colors.blue}; }
  .task-card.completed .task-status-dot { background:#10b981; }

  .task-body { flex:1; min-width:0; }

  .task-header { display:flex; align-items:flex-start; justify-content:space-between; gap:12px; margin-bottom:4px; flex-wrap:nowrap; }
  .task-title { font-size:14px; font-weight:700; color:${colors.navy}; margin:0; line-height:1.4; flex:1; min-width:0; }
  .task-card.completed .task-title { text-decoration:line-through; color:${colors.textSecondary}; font-weight:500; }

  .task-due-chip {
    display:inline-flex; align-items:center; gap:4px; flex-shrink:0;
    padding:3px 9px; border-radius:20px; font-size:10.5px; font-weight:600;
    background:${colors.pageBg}; color:${colors.textSecondary};
    white-space:nowrap;
  }
  .task-due-chip.overdue { background:#fef2f2; color:#dc2626; }
  .task-due-chip.soon    { background:#fffbeb; color:#d97706; }

  .task-desc { font-size:12px; color:${colors.textSecondary}; margin:0 0 10px; line-height:1.55; }
  .task-meta { display:flex; gap:6px; flex-wrap:wrap; align-items:center; }

  .task-badge {
    display:inline-flex; padding:2px 8px; border-radius:20px; font-size:10px; font-weight:700;
  }
  .task-type-manual       { background:#eff6ff; color:#2563eb; }
  .task-type-reminder_j7  { background:#fef9c3; color:#a16207; }
  .task-type-reminder_j14 { background:#fef2f2; color:#dc2626; }
  .task-priority-urgent { background:#fef2f2; color:#dc2626; }
  .task-priority-faible { background:#f0fdf4; color:#16a34a; }

  .task-meta-sep { color:${colors.border}; font-size:14px; line-height:1; margin:0 1px; }

  .task-assignee-pill {
    display:inline-flex; align-items:center; gap:4px;
    padding:2px 8px; border-radius:10px;
    background:rgba(37,70,204,0.07); color:${colors.blue};
    font-size:10.5px; font-weight:600;
  }

  .task-context { font-size:11px; color:${colors.textMuted}; display:flex; align-items:center; gap:3px; }

  .task-side {
    display:flex; flex-direction:column; align-items:flex-end; justify-content:space-between;
    flex-shrink:0; min-width:130px; align-self:stretch;
  }

  .task-actions { display:flex; align-items:center; gap:6px; margin-top:auto; }

  .task-complete-btn {
    display:inline-flex; align-items:center; gap:5px;
    height:30px; padding:0 14px; border-radius:20px;
    border:none; background:#16a34a;
    font-size:11.5px; font-weight:700; font-family:${fonts.body};
    color:white; cursor:pointer; flex-shrink:0;
    box-shadow:0 2px 8px rgba(22,163,74,0.30);
    transition:background .15s, box-shadow .15s, transform .1s;
    white-space:nowrap;
  }
  .task-complete-btn:hover {
    background:#15803d;
    box-shadow:0 4px 14px rgba(22,163,74,0.40);
    transform:translateY(-1px);
  }
  .task-complete-btn:active { transform:translateY(0); box-shadow:none; }

  .task-actions-sep {
    width:1px; height:16px; background:${colors.border}; flex-shrink:0;
  }

  .task-delete-btn {
    width:28px; height:28px; border-radius:7px; border:none;
    background:none; cursor:pointer; color:${colors.textSecondary};
    display:flex; align-items:center; justify-content:center;
    transition:background .15s, color .15s; flex-shrink:0;
  }
  .task-delete-btn:hover { background:#fef2f2; color:#ef4444; }

  .tasks-empty {
    text-align:center; padding:60px 20px; background:white;
    border-radius:14px; border:1px solid ${colors.border};
  }
  .tasks-empty-icon { display:block; margin:0 auto 12px; }
  .tasks-empty-text { font-size:14px; color:${colors.textSecondary}; }

  /* ── Modal ── */
  .task-modal-overlay {
    position:fixed; inset:0; background:rgba(0,0,0,0.45);
    display:flex; align-items:center; justify-content:center;
    z-index:1000; padding:20px;
  }
  .task-modal {
    background:white; border-radius:16px; padding:28px;
    width:100%; max-width:560px;
    box-shadow:0 20px 60px rgba(11,24,82,0.22);
    animation: fadeInUp .2s ease;
    max-height:90vh; overflow-y:auto;
  }
  .task-modal-field { margin-bottom:14px; }
  .task-modal-label {
    display:block; font-size:11.5px; font-weight:600;
    color:${colors.textSecondary}; margin-bottom:5px;
    text-transform:uppercase; letter-spacing:.05em;
  }
  .task-modal-input, .task-modal-select {
    width:100%; height:38px; padding:0 12px;
    border:1px solid ${colors.borderInput}; border-radius:8px;
    font-size:13.5px; font-family:${fonts.body};
    color:${colors.textPrimary}; outline:none;
    box-sizing:border-box; transition:border-color .15s; background:white;
  }
  .task-modal-input:focus, .task-modal-select:focus { border-color:${colors.navy}; }
  .task-modal-textarea {
    width:100%; padding:10px 12px; border:1px solid ${colors.borderInput};
    border-radius:8px; font-size:13px; font-family:${fonts.body};
    color:${colors.textPrimary}; outline:none; resize:vertical; min-height:72px;
    box-sizing:border-box; transition:border-color .15s; line-height:1.5;
  }
  .task-modal-textarea:focus { border-color:${colors.navy}; }
  .task-modal-grid-2 { display:grid; grid-template-columns:1fr 1fr; gap:14px; margin-bottom:14px; }
  .task-modal-footer {
    display:flex; gap:10px; justify-content:flex-end;
    margin-top:20px; padding-top:16px; border-top:1px solid ${colors.border};
  }
  .task-modal-cancel {
    height:38px; padding:0 16px; border:1px solid ${colors.border};
    border-radius:8px; font-size:13px; font-family:${fonts.body};
    background:white; cursor:pointer; color:${colors.textSecondary};
    transition:background .15s;
  }
  .task-modal-cancel:hover { background:${colors.pageBg}; }
  .task-modal-save {
    height:38px; padding:0 22px; border:none; border-radius:8px;
    font-size:13px; font-weight:600; font-family:${fonts.body};
    background:${colors.navy}; color:white; cursor:pointer; transition:opacity .15s;
  }
  .task-modal-save:hover { opacity:.85; }
  .task-modal-save:disabled { opacity:.45; cursor:default; }

  /* Priorité boutons */
  .task-priority-btns { display:flex; gap:8px; }
  .task-priority-btn {
    flex:1; height:36px; border-radius:8px; font-size:12.5px; font-weight:600;
    font-family:${fonts.body}; cursor:pointer; transition:all .15s; border:1.5px solid ${colors.borderInput};
    background:white; color:${colors.textSecondary};
  }
  .task-priority-btn.sel-normal { background:#eff6ff; color:${colors.navy}; border-color:${colors.navy}; }
  .task-priority-btn.sel-urgent { background:#fef2f2; color:#dc2626; border-color:#dc2626; }
  .task-priority-btn.sel-faible { background:#f0fdf4; color:#16a34a; border-color:#16a34a; }

  /* App search */
  .task-app-wrap { position:relative; }
  .task-app-dropdown {
    position:absolute; top:calc(100% + 2px); left:0; right:0; z-index:10;
    background:white; border:1px solid ${colors.borderInput}; border-radius:8px;
    box-shadow:0 8px 24px rgba(11,24,82,0.12); max-height:180px; overflow-y:auto;
  }
  .task-app-option {
    padding:9px 12px; font-size:13px; color:${colors.textPrimary};
    cursor:pointer; border-bottom:1px solid ${colors.border}; transition:background .12s;
  }
  .task-app-option:last-child { border-bottom:none; }
  .task-app-option:hover { background:#f0f4ff; }

  /* Filtres avancés */
  .tasks-filters {
    display:flex; gap:8px; margin-bottom:14px; flex-wrap:wrap; align-items:center;
  }
  .tasks-filter-select {
    height:32px; padding:0 10px; border:1px solid ${colors.borderInput}; border-radius:8px;
    font-size:12px; font-family:${fonts.body}; color:${colors.textPrimary};
    background:white; outline:none; cursor:pointer; transition:border-color .15s;
  }
  .tasks-filter-select:focus { border-color:${colors.navy}; }
  .tasks-filter-clear {
    height:32px; padding:0 12px; border:1px solid ${colors.border}; border-radius:8px;
    font-size:11.5px; font-family:${fonts.body}; color:${colors.textSecondary};
    background:white; cursor:pointer; transition:background .15s;
  }
  .tasks-filter-clear:hover { background:${colors.pageBg}; }
  .tasks-filter-label {
    font-size:11.5px; color:${colors.textSecondary}; font-weight:600;
  }

  /* Bouton édition carte */
  .task-edit-btn {
    width:28px; height:28px; border-radius:7px; border:none;
    background:none; cursor:pointer; color:${colors.textSecondary};
    display:flex; align-items:center; justify-content:center;
    transition:background .15s, color .15s; flex-shrink:0;
  }
  .task-edit-btn:hover { background:#eff6ff; color:${colors.blue}; }

  /* Rappel toggle */
  .task-reminder-row { display:flex; align-items:center; gap:12px; flex-wrap:wrap; }
  .task-toggle-track {
    width:36px; height:20px; border-radius:10px; background:#d1d5db;
    cursor:pointer; position:relative; flex-shrink:0; transition:background .2s;
  }
  .task-toggle-track.on { background:${colors.blue}; }
  .task-toggle-thumb {
    width:16px; height:16px; border-radius:50%; background:white;
    position:absolute; top:2px; left:2px;
    transition:left .2s; box-shadow:0 1px 3px rgba(0,0,0,0.18);
  }
  .task-toggle-track.on .task-toggle-thumb { left:18px; }
`;

(() => {
  let el = document.getElementById('tasks-css') as HTMLStyleElement | null;
  if (!el) { el = document.createElement('style'); el.id = 'tasks-css'; document.head.appendChild(el); }
  el.textContent = CSS;
})();

const TYPE_LABELS: Record<string, string> = {
  manual:        'Manuel',
  reminder_j7:   'Relance J+7',
  reminder_j14:  'Relance J+14',
};

const PRIORITY_LABELS: Record<string, string> = {
  normal: 'Normal',
  urgent: 'Urgent',
  faible: 'Faible',
};

const ASSIGNEE_OPTIONS = ['Admissions', 'Support', 'Manager', 'Admin'];

function isOverdue(due: string | null): boolean {
  if (!due) return false;
  return new Date(due) < new Date();
}

function fmtDue(due: string | null): string {
  if (!due) return '';
  const d    = new Date(due);
  const now  = new Date();
  const diff = Math.ceil((d.getTime() - now.getTime()) / 86400000);
  if (diff < 0)   return `En retard de ${Math.abs(diff)}j`;
  if (diff === 0) return "Aujourd'hui";
  if (diff === 1) return 'Demain';
  return `Dans ${diff}j`;
}

type TabType = 'all' | 'mine' | 'reminder_j7' | 'reminder_j14' | 'manual';

export default function TasksPage() {
  const { role } = useRole();
  const [tasks,            setTasks]            = useState<Task[]>([]);
  const [loading,          setLoading]          = useState(true);
  const [loadError,        setLoadError]         = useState<string | null>(null);
  const [showDone,         setShowDone]         = useState(false);
  const [activeTab,        setActiveTab]        = useState<TabType>('all');
  const [modalOpen,        setModalOpen]        = useState(false);
  const [editingTask,      setEditingTask]      = useState<Task | null>(null);

  // Filtres
  const [filterPriority,   setFilterPriority]   = useState<string>('');
  const [filterAssignee,   setFilterAssignee]   = useState<string>('');

  // Form fields
  const [newTitle,         setNewTitle]         = useState('');
  const [newDesc,          setNewDesc]          = useState('');
  const [newDue,           setNewDue]           = useState('');
  const [newAssignee,      setNewAssignee]      = useState('');
  const [newPriority,      setNewPriority]      = useState<'normal' | 'urgent' | 'faible'>('normal');
  const [newAppSearch,     setNewAppSearch]     = useState('');
  const [newAppId,         setNewAppId]         = useState<string | null>(null);
  const [appResults,       setAppResults]       = useState<{ id: string; label: string }[]>([]);
  const [appSearching,     setAppSearching]     = useState(false);
  const [newReminder,      setNewReminder]      = useState(false);
  const [newReminderHours, setNewReminderHours] = useState(24);
  const [saving,           setSaving]           = useState(false);
  const [saveError,        setSaveError]         = useState<string | null>(null);

  const appTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setLoadError(null);
    try { setTasks(await fetchTasks(showDone)); }
    catch (err: any) { setLoadError(err?.message ?? 'Erreur de chargement'); }
    finally { setLoading(false); }
  }, [showDone]);

  useEffect(() => { load(); }, [load]);

  useEffect(() => {
    const channel = supabase
      .channel('tp-tasks-realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tasks' }, load)
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [load]);

  function resetForm() {
    setNewTitle(''); setNewDesc(''); setNewDue('');
    setNewAssignee(''); setNewPriority('normal');
    setNewAppSearch(''); setNewAppId(null); setAppResults([]);
    setNewReminder(false); setNewReminderHours(24);
    setEditingTask(null);
  }

  function closeModal() { resetForm(); setSaveError(null); setModalOpen(false); }

  function openEdit(task: Task) {
    setEditingTask(task);
    setNewTitle(task.title);
    setNewDesc(task.description ?? '');
    setNewDue(task.due_date ? task.due_date.substring(0, 10) : '');
    setNewAssignee(task.assignee_label ?? '');
    setNewPriority(task.priority ?? 'normal');
    setNewAppId(task.application_id ?? null);
    setNewAppSearch('');
    setNewReminder(task.reminder_hours != null);
    setNewReminderHours(task.reminder_hours ?? 24);
    setSaveError(null);
    setModalOpen(true);
  }

  function handleAppInput(value: string) {
    setNewAppSearch(value);
    setNewAppId(null);
    if (appTimerRef.current) clearTimeout(appTimerRef.current);
    if (value.length < 2) { setAppResults([]); return; }
    appTimerRef.current = setTimeout(async () => {
      setAppSearching(true);
      try { setAppResults(await searchApplications(value)); }
      finally { setAppSearching(false); }
    }, 350);
  }

  function selectApp(id: string, label: string) {
    setNewAppId(id);
    setNewAppSearch(label);
    setAppResults([]);
  }

  async function handleComplete(id: string) {
    await completeTask(id);
    setTasks(prev => prev.map(t => t.id === id ? { ...t, completed_at: new Date().toISOString() } : t));
    if (!showDone) setTasks(prev => prev.filter(t => t.id !== id));
  }

  async function handleDelete(id: string) {
    await deleteTask(id);
    setTasks(prev => prev.filter(t => t.id !== id));
  }

  async function handleSave() {
    if (!newTitle.trim() || !newAssignee) return;
    setSaving(true);
    setSaveError(null);
    try {
      if (editingTask) {
        await updateTask(editingTask.id, {
          title:          newTitle.trim(),
          description:    newDesc.trim() || null,
          due_date:       newDue || null,
          application_id: newAppId || null,
          priority:       newPriority,
          assignee_label: newAssignee,
          reminder_hours: newReminder ? newReminderHours : null,
        });
      } else {
        await createTask({
          title:          newTitle.trim(),
          description:    newDesc.trim() || undefined,
          due_date:       newDue || undefined,
          application_id: newAppId || undefined,
          priority:       newPriority,
          assignee_label: newAssignee,
          reminder_hours: newReminder ? newReminderHours : undefined,
          creator_role:   role as 'admin' | 'manager' | 'admissions' | 'support' | undefined,
        });
      }
      closeModal();
      await load();
    } catch (err: any) {
      setSaveError(err?.message ?? 'Erreur inconnue');
    } finally {
      setSaving(false);
    }
  }

  const myTasks = tasks.filter(t => t.assignee_label?.toLowerCase() === role);
  const filtered =
    activeTab === 'all'  ? tasks :
    activeTab === 'mine' ? myTasks :
    tasks.filter(t => t.task_type === activeTab);

  const filtered2 = filtered
    .filter(t => !filterPriority || (t.priority ?? 'normal') === filterPriority)
    .filter(t => !filterAssignee || t.assignee_label?.toLowerCase() === filterAssignee.toLowerCase());

  const hasActiveFilters = !!(filterPriority || filterAssignee);

  const counts = {
    all:          tasks.length,
    mine:         myTasks.length,
    reminder_j7:  tasks.filter(t => t.task_type === 'reminder_j7').length,
    reminder_j14: tasks.filter(t => t.task_type === 'reminder_j14').length,
    manual:       tasks.filter(t => t.task_type === 'manual').length,
  };

  return (
    <div className="tasks-root">
      <PageHeader
        title="Tâches & Relances"
        subtitle={`${tasks.length} tâche${tasks.length !== 1 ? 's' : ''} en cours · relances J+7 / J+14`}
        actions={
          <>
            <button className="tasks-toggle" onClick={() => setShowDone(v => !v)}>
              {showDone ? 'Masquer terminées' : 'Voir terminées'}
            </button>
            <Button onClick={() => setModalOpen(true)}>+ Nouvelle tâche</Button>
          </>
        }
      />

      <div className="tasks-tabs">
        {(['all', 'mine', 'reminder_j7', 'reminder_j14', 'manual'] as TabType[]).map(tab => (
          <button
            key={tab}
            className={`tasks-tab ${activeTab === tab ? 'active' : ''}`}
            onClick={() => setActiveTab(tab)}
          >
            {tab === 'all'          ? `Tout (${counts.all})` :
             tab === 'mine'         ? `Mes tâches (${counts.mine})` :
             tab === 'reminder_j7'  ? `Relances J+7 (${counts.reminder_j7})` :
             tab === 'reminder_j14' ? `Relances J+14 (${counts.reminder_j14})` :
                                      `Manuel (${counts.manual})`}
          </button>
        ))}
      </div>

      {loadError && (
        <div style={{
          background: '#fef2f2', border: '1px solid #fca5a5', borderRadius: 10,
          padding: '12px 16px', marginBottom: 16, fontSize: 13, color: '#dc2626',
        }}>
          {loadError}
        </div>
      )}

      <div className="tasks-filters">
        <span className="tasks-filter-label">Filtrer :</span>
        <select
          className="tasks-filter-select"
          value={filterPriority}
          onChange={e => setFilterPriority(e.target.value)}
        >
          <option value="">Toutes priorités</option>
          <option value="urgent">Urgent</option>
          <option value="normal">Normal</option>
          <option value="faible">Faible</option>
        </select>
        <select
          className="tasks-filter-select"
          value={filterAssignee}
          onChange={e => setFilterAssignee(e.target.value)}
        >
          <option value="">Tous les assignés</option>
          {ASSIGNEE_OPTIONS.map(opt => (
            <option key={opt} value={opt}>{opt}</option>
          ))}
        </select>
        {hasActiveFilters && (
          <button
            className="tasks-filter-clear"
            onClick={() => { setFilterPriority(''); setFilterAssignee(''); }}
          >
            Effacer filtres
          </button>
        )}
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '40px', color: colors.textSecondary, fontSize: 14 }}>
          Chargement
        </div>
      ) : filtered2.length === 0 ? (
        <div className="tasks-empty">
          <svg className="tasks-empty-icon" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
          </svg>
          <div className="tasks-empty-text">Aucune tâche correspondante.</div>
        </div>
      ) : (
        <div className="tasks-list">
          {filtered2.map(task => {
            const pri          = task.priority ?? 'normal';
            // Terminer : assigné à ce rôle OU admin
            const canComplete  = !task.completed_at &&
              (role === 'admin' || task.assignee_label?.toLowerCase() === role);
            // Modifier/Supprimer : créateur de la tâche OU admin
            const canEditDelete = role === 'admin' ||
              task.creator_role?.toLowerCase() === role;
            const overdue = isOverdue(task.due_date) && !task.completed_at;
            const dueText = fmtDue(task.due_date);
            const soonDays = task.due_date
              ? Math.ceil((new Date(task.due_date).getTime() - Date.now()) / 86400000)
              : null;
            const isSoon = soonDays !== null && soonDays >= 0 && soonDays <= 2 && !task.completed_at;

            return (
              <div key={task.id} className={`task-card ${task.completed_at ? 'completed' : ''} pri-${pri}`}>
                <div className="task-status-dot" title={task.completed_at ? 'Terminée' : 'En cours'} />

                <div className="task-body">
                  <div className="task-header">
                    <p className="task-title">{task.title}</p>
                  </div>

                  {task.description && <p className="task-desc">{task.description}</p>}

                  <div className="task-meta">
                    <span className={`task-badge task-type-${task.task_type}`}>
                      {TYPE_LABELS[task.task_type]}
                    </span>
                    {pri !== 'normal' && (
                      <span className={`task-badge task-priority-${pri}`}>
                        {PRIORITY_LABELS[pri]}
                      </span>
                    )}

                    {(task.assignee_label || task.student_name || task.program_name) && (
                      <span className="task-meta-sep">·</span>
                    )}

                    {task.assignee_label && (
                      <span className="task-assignee-pill">
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
                          <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>
                        </svg>
                        {task.assignee_label}
                      </span>
                    )}

                    {task.student_name && (
                      <span className="task-context">
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                          <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>
                        </svg>
                        {task.student_name}
                      </span>
                    )}
                    {task.student_name && task.program_name && (
                      <span className="task-meta-sep">·</span>
                    )}
                    {task.program_name && (
                      <span className="task-context">
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                          <path d="M22 10v6M2 10l10-5 10 5-10 5z"/>
                        </svg>
                        {task.program_name}
                      </span>
                    )}
                  </div>
                </div>

                <div className="task-side">
                  {task.due_date && (
                    <span className={`task-due-chip ${overdue ? 'overdue' : isSoon ? 'soon' : ''}`}>
                      <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
                        <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
                      </svg>
                      {dueText}
                    </span>
                  )}
                  <div className="task-actions">
                    {canComplete && (
                      <button
                        className="task-complete-btn"
                        onClick={() => handleComplete(task.id)}
                        title="Marquer comme terminée"
                      >
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                          <polyline points="20 6 9 17 4 12"/>
                        </svg>
                        Terminer
                      </button>
                    )}
                    {canEditDelete && canComplete && <div className="task-actions-sep" />}
                    {canEditDelete && !task.completed_at && (
                      <button className="task-edit-btn" onClick={() => openEdit(task)} title="Modifier">
                        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                          <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                        </svg>
                      </button>
                    )}
                    {canEditDelete && (
                      <button className="task-delete-btn" onClick={() => handleDelete(task.id)} title="Supprimer">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                          <polyline points="3 6 5 6 21 6"/>
                          <path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>
                          <path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/>
                        </svg>
                      </button>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {modalOpen && (
        <div className="task-modal-overlay" onClick={e => e.target === e.currentTarget && closeModal()}>
          <div className="task-modal">

            {/* En-tête gradient */}
            <div style={{
              margin: '-28px -28px 24px',
              padding: '20px 24px 18px',
              background: `linear-gradient(135deg, ${colors.navy} 0%, #1e3a8a 100%)`,
              borderRadius: '16px 16px 0 0',
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            }}>
              <div>
                <div style={{ fontSize: 17, fontWeight: 800, color: 'white', fontFamily: fonts.display }}>
                  {editingTask ? 'Modifier la tâche' : 'Nouvelle tâche'}
                </div>
                <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.65)', marginTop: 2 }}>
                  {editingTask ? 'Mettre à jour les informations de la tâche' : 'Créer et assigner une tâche à l\'équipe'}
                </div>
              </div>
              <button
                onClick={closeModal}
                style={{
                  width: 32, height: 32, borderRadius: 8, border: 'none',
                  background: 'rgba(255,255,255,0.12)', cursor: 'pointer',
                  display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white',
                }}
              >
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                  <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                </svg>
              </button>
            </div>

            {/* Titre */}
            <div className="task-modal-field">
              <label className="task-modal-label">
                Titre <span style={{ color: colors.danger }}>*</span>
              </label>
              <input
                className="task-modal-input"
                value={newTitle}
                onChange={e => setNewTitle(e.target.value)}
                placeholder="Ex: Relancer l'université de Paris"
                autoFocus
              />
            </div>

            {/* Assigné à | Date d'échéance */}
            <div className="task-modal-grid-2">
              <div>
                <label className="task-modal-label">
                  Assigné à <span style={{ color: colors.danger }}>*</span>
                </label>
                <select
                  className="task-modal-select"
                  value={newAssignee}
                  onChange={e => setNewAssignee(e.target.value)}
                >
                  <option value="">-- Choisir --</option>
                  {ASSIGNEE_OPTIONS.map(opt => (
                    <option key={opt} value={opt}>{opt}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="task-modal-label">Date d'échéance</label>
                <input
                  type="date"
                  className="task-modal-input"
                  value={newDue}
                  onChange={e => setNewDue(e.target.value)}
                />
              </div>
            </div>

            {/* Description */}
            <div className="task-modal-field">
              <label className="task-modal-label">Description</label>
              <textarea
                className="task-modal-textarea"
                value={newDesc}
                onChange={e => setNewDesc(e.target.value)}
                placeholder="Détails supplémentaires sur la tâche"
              />
            </div>

            {/* Priorité */}
            <div className="task-modal-field">
              <label className="task-modal-label">Priorité</label>
              <div className="task-priority-btns">
                {(['normal', 'urgent', 'faible'] as const).map(p => (
                  <button
                    key={p}
                    className={`task-priority-btn ${newPriority === p ? `sel-${p}` : ''}`}
                    onClick={() => setNewPriority(p)}
                    type="button"
                  >
                    {PRIORITY_LABELS[p]}
                  </button>
                ))}
              </div>
            </div>

            {/* Lié à une candidature */}
            <div className="task-modal-field">
              <label className="task-modal-label">Lié à une candidature</label>
              <div className="task-app-wrap">
                <input
                  className="task-modal-input"
                  value={newAppSearch}
                  onChange={e => handleAppInput(e.target.value)}
                  onBlur={() => setTimeout(() => setAppResults([]), 180)}
                  placeholder={appSearching ? 'Recherche...' : "Rechercher par nom d'étudiant"}
                  style={{ paddingRight: newAppId ? 36 : 12 }}
                />
                {newAppId && (
                  <button
                    type="button"
                    onClick={() => { setNewAppId(null); setNewAppSearch(''); }}
                    style={{
                      position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)',
                      border: 'none', background: 'none', cursor: 'pointer',
                      color: colors.textMuted, display: 'flex', padding: 2,
                    }}
                  >
                    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
                      <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                    </svg>
                  </button>
                )}
                {appResults.length > 0 && (
                  <div className="task-app-dropdown">
                    {appResults.map(r => (
                      <div
                        key={r.id}
                        className="task-app-option"
                        onMouseDown={() => selectApp(r.id, r.label)}
                      >
                        {r.label}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Rappel */}
            <div className="task-modal-field">
              <label className="task-modal-label">Rappel</label>
              <div className="task-reminder-row">
                <div
                  className={`task-toggle-track ${newReminder ? 'on' : ''}`}
                  onClick={() => setNewReminder(v => !v)}
                >
                  <div className="task-toggle-thumb" />
                </div>
                {newReminder && (
                  <select
                    className="task-modal-select"
                    style={{ width: 'auto', flex: 1, maxWidth: 220 }}
                    value={newReminderHours}
                    onChange={e => setNewReminderHours(Number(e.target.value))}
                  >
                    <option value="1">1 heure avant l'échéance</option>
                    <option value="6">6 heures avant l'échéance</option>
                    <option value="24">1 jour avant l'échéance</option>
                    <option value="72">3 jours avant l'échéance</option>
                  </select>
                )}
              </div>
            </div>

            {/* Footer */}
            {saveError && (
              <div style={{
                background: '#fef2f2', border: '1px solid #fca5a5', borderRadius: 8,
                padding: '10px 14px', marginBottom: 12,
                fontSize: 12.5, color: '#dc2626', lineHeight: 1.5,
              }}>
                {saveError}
              </div>
            )}
            <div className="task-modal-footer">
              <button className="task-modal-cancel" onClick={closeModal}>Annuler</button>
              <button
                className="task-modal-save"
                onClick={handleSave}
                disabled={saving || !newTitle.trim() || !newAssignee}
              >
                {saving ? 'Enregistrement...' : editingTask ? 'Enregistrer' : 'Créer la tâche'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
