import { useState, useEffect } from 'react';
import { colors, fonts } from '../../../shared/constants/theme';
import { PageHeader } from '../../../shared/components/PageHeader';
import { Button } from '../../../shared/components/Button';
import { fetchTasks, createTask, completeTask, deleteTask } from '../services/tasks_service';
import type { Task } from '../services/tasks_service';

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
    padding:16px; display:flex; gap:14px; align-items:flex-start;
    box-shadow:0 2px 6px rgba(11,24,82,0.04);
    transition:box-shadow .15s;
  }
  .task-card:hover { box-shadow:0 4px 14px rgba(11,24,82,0.08); }
  .task-card.completed { opacity:.55; }

  .task-check {
    width:20px; height:20px; border-radius:50%;
    border:2px solid ${colors.border}; background:white;
    cursor:pointer; flex-shrink:0; margin-top:1px;
    display:flex; align-items:center; justify-content:center;
    transition:border-color .15s, background .15s;
  }
  .task-check:hover { border-color:#10b981; }
  .task-card.completed .task-check {
    background:#10b981; border-color:#10b981;
  }

  .task-body { flex:1; min-width:0; }
  .task-title { font-size:14px; font-weight:600; color:${colors.navy}; margin:0 0 4px; }
  .task-card.completed .task-title { text-decoration:line-through; color:${colors.textSecondary}; }
  .task-desc { font-size:12px; color:${colors.textSecondary}; margin:0 0 8px; line-height:1.5; }
  .task-meta { display:flex; gap:8px; flex-wrap:wrap; align-items:center; }

  .task-type-badge {
    display:inline-flex; padding:2px 8px; border-radius:20px;
    font-size:10px; font-weight:700;
  }
  .task-type-manual      { background:#eff6ff; color:#2563eb; }
  .task-type-reminder_j7  { background:#fef9c3; color:#a16207; }
  .task-type-reminder_j14 { background:#fef2f2; color:#dc2626; }

  .task-due {
    font-size:11px; color:${colors.textSecondary};
    display:flex; align-items:center; gap:4px;
  }
  .task-due.overdue { color:#ef4444; font-weight:600; }

  .task-context { font-size:11px; color:${colors.textSecondary}; }

  .task-delete-btn {
    width:28px; height:28px; border-radius:7px; border:none;
    background:none; cursor:pointer; color:${colors.textSecondary};
    display:flex; align-items:center; justify-content:center;
    transition:background .15s, color .15s; flex-shrink:0;
  }
  .task-delete-btn:hover { background:#fef2f2; color:#ef4444; }

  .tasks-empty { text-align:center; padding:60px 20px; background:white; border-radius:14px; border:1px solid ${colors.border}; }
  .tasks-empty-icon { display:block; margin:0 auto 12px; }
  .tasks-empty-text { font-size:14px; color:${colors.textSecondary}; }

  /*  Modal création tâche  */
  .task-modal-overlay {
    position:fixed; inset:0; background:rgba(0,0,0,0.4);
    display:flex; align-items:center; justify-content:center;
    z-index:1000; padding:20px;
  }
  .task-modal {
    background:white; border-radius:16px; padding:28px;
    width:100%; max-width:480px;
    box-shadow:0 20px 60px rgba(11,24,82,0.2);
    animation: fadeInUp .2s ease;
  }
  .task-modal-title { font-family:${fonts.display}; font-size:18px; font-weight:800; color:${colors.navy}; margin:0 0 20px; }
  .task-modal-field { margin-bottom:14px; }
  .task-modal-label { display:block; font-size:12px; font-weight:600; color:${colors.textSecondary}; margin-bottom:5px; text-transform:uppercase; letter-spacing:.05em; }
  .task-modal-input {
    width:100%; height:38px; padding:0 12px; border:1px solid ${colors.border};
    border-radius:8px; font-size:14px; font-family:${fonts.body};
    color:${colors.textPrimary}; outline:none; box-sizing:border-box;
    transition:border-color .15s;
  }
  .task-modal-input:focus { border-color:${colors.navy}; }
  .task-modal-textarea {
    width:100%; padding:10px 12px; border:1px solid ${colors.border};
    border-radius:8px; font-size:13px; font-family:${fonts.body};
    color:${colors.textPrimary}; outline:none; resize:vertical; min-height:80px;
    box-sizing:border-box; transition:border-color .15s; line-height:1.5;
  }
  .task-modal-textarea:focus { border-color:${colors.navy}; }
  .task-modal-actions { display:flex; gap:10px; justify-content:flex-end; margin-top:20px; }
  .task-modal-cancel {
    height:38px; padding:0 16px; border:1px solid ${colors.border};
    border-radius:8px; font-size:13px; font-family:${fonts.body};
    background:white; cursor:pointer; color:${colors.textSecondary};
  }
  .task-modal-cancel:hover { background:${colors.pageBg}; }
  .task-modal-save {
    height:38px; padding:0 20px; border:none; border-radius:8px;
    font-size:13px; font-weight:600; font-family:${fonts.body};
    background:${colors.navy}; color:white; cursor:pointer;
  }
  .task-modal-save:hover { opacity:.85; }
  .task-modal-save:disabled { opacity:.5; cursor:default; }
`;

if (!document.getElementById('tasks-css')) {
  const s = document.createElement('style');
  s.id = 'tasks-css';
  s.textContent = CSS;
  document.head.appendChild(s);
}

const TYPE_LABELS: Record<string, string> = {
  manual:        'Manuel',
  reminder_j7:   'Relance J+7',
  reminder_j14:  'Relance J+14',
};

function isOverdue(due: string | null): boolean {
  if (!due) return false;
  return new Date(due) < new Date();
}

function fmtDue(due: string | null): string {
  if (!due) return '';
  const d   = new Date(due);
  const now = new Date();
  const diff = Math.ceil((d.getTime() - now.getTime()) / 86400000);
  if (diff < 0)  return `En retard de ${Math.abs(diff)}j`;
  if (diff === 0) return 'Aujourd\'hui';
  if (diff === 1) return 'Demain';
  return `Dans ${diff}j`;
}

type TabType = 'all' | 'reminder_j7' | 'reminder_j14' | 'manual';

export default function TasksPage() {
  const [tasks,        setTasks]        = useState<Task[]>([]);
  const [loading,      setLoading]      = useState(true);
  const [showDone,     setShowDone]     = useState(false);
  const [activeTab,    setActiveTab]    = useState<TabType>('all');
  const [modalOpen,    setModalOpen]    = useState(false);
  const [newTitle,     setNewTitle]     = useState('');
  const [newDesc,      setNewDesc]      = useState('');
  const [newDue,       setNewDue]       = useState('');
  const [saving,       setSaving]       = useState(false);

  async function load() {
    setLoading(true);
    try {
      const data = await fetchTasks(showDone);
      setTasks(data);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, [showDone]); // eslint-disable-line

  async function handleComplete(id: string) {
    await completeTask(id);
    setTasks(prev => prev.map(t => t.id === id ? { ...t, completed_at: new Date().toISOString() } : t));
    if (!showDone) setTasks(prev => prev.filter(t => t.id !== id));
  }

  async function handleDelete(id: string) {
    await deleteTask(id);
    setTasks(prev => prev.filter(t => t.id !== id));
  }

  async function handleCreate() {
    if (!newTitle.trim()) return;
    setSaving(true);
    try {
      await createTask({
        title:       newTitle.trim(),
        description: newDesc.trim() || undefined,
        due_date:    newDue || undefined,
      });
      setNewTitle(''); setNewDesc(''); setNewDue('');
      setModalOpen(false);
      await load();
    } finally {
      setSaving(false);
    }
  }

  const filtered = tasks.filter(t => activeTab === 'all' || t.task_type === activeTab);

  const counts = {
    all:           tasks.length,
    reminder_j7:   tasks.filter(t => t.task_type === 'reminder_j7').length,
    reminder_j14:  tasks.filter(t => t.task_type === 'reminder_j14').length,
    manual:        tasks.filter(t => t.task_type === 'manual').length,
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
        {(['all', 'reminder_j7', 'reminder_j14', 'manual'] as TabType[]).map(tab => (
          <button
            key={tab}
            className={`tasks-tab ${activeTab === tab ? 'active' : ''}`}
            onClick={() => setActiveTab(tab)}
          >
            {tab === 'all' ? `Tout (${counts.all})` :
             tab === 'reminder_j7'  ? `Relances J+7 (${counts.reminder_j7})` :
             tab === 'reminder_j14' ? `Relances J+14 (${counts.reminder_j14})` :
             `Manuel (${counts.manual})`}
          </button>
        ))}
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '40px', color: colors.textSecondary, fontSize: 14 }}>
          Chargement
        </div>
      ) : filtered.length === 0 ? (
        <div className="tasks-empty">
          <svg className="tasks-empty-icon" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
            <path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
          </svg>
          <div className="tasks-empty-text">Aucune tâche en cours.</div>
        </div>
      ) : (
        <div className="tasks-list">
          {filtered.map(task => (
            <div key={task.id} className={`task-card ${task.completed_at ? 'completed' : ''}`}>
              <button
                className="task-check"
                onClick={() => !task.completed_at && handleComplete(task.id)}
                title={task.completed_at ? 'Terminée' : 'Marquer terminée'}
              >
                {task.completed_at && (
                  <svg width="11" height="11" viewBox="0 0 12 12" fill="none">
                    <path d="M2 6l3 3 5-5" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                )}
              </button>

              <div className="task-body">
                <p className="task-title">{task.title}</p>
                {task.description && <p className="task-desc">{task.description}</p>}
                <div className="task-meta">
                  <span className={`task-type-badge task-type-${task.task_type}`}>
                    {TYPE_LABELS[task.task_type]}
                  </span>
                  {task.due_date && (
                    <span className={`task-due ${isOverdue(task.due_date) && !task.completed_at ? 'overdue' : ''}`}>
                      <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" style={{marginRight:3}}><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                      {fmtDue(task.due_date)}
                    </span>
                  )}
                  {task.student_name && (
                    <span className="task-context">
                      <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" style={{marginRight:3}}><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                      {task.student_name}
                    </span>
                  )}
                  {task.program_name && (
                    <span className="task-context">
                      <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" style={{marginRight:3}}><path d="M22 10v6M2 10l10-5 10 5-10 5z"/></svg>
                      {task.program_name}
                    </span>
                  )}
                </div>
              </div>

              <button className="task-delete-btn" onClick={() => handleDelete(task.id)} title="Supprimer">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                  <polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/>
                  <path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/>
                </svg>
              </button>
            </div>
          ))}
        </div>
      )}

      {modalOpen && (
        <div className="task-modal-overlay" onClick={e => e.target === e.currentTarget && setModalOpen(false)}>
          <div className="task-modal">
            <h2 className="task-modal-title">Nouvelle tâche</h2>
            <div className="task-modal-field">
              <label className="task-modal-label">Titre *</label>
              <input
                className="task-modal-input"
                value={newTitle}
                onChange={e => setNewTitle(e.target.value)}
                placeholder="Ex: Relancer l'université de Paris"
                autoFocus
              />
            </div>
            <div className="task-modal-field">
              <label className="task-modal-label">Description</label>
              <textarea
                className="task-modal-textarea"
                value={newDesc}
                onChange={e => setNewDesc(e.target.value)}
                placeholder="Détails sur la tâche"
              />
            </div>
            <div className="task-modal-field">
              <label className="task-modal-label">Date d'échéance</label>
              <input
                type="date"
                className="task-modal-input"
                value={newDue}
                onChange={e => setNewDue(e.target.value)}
              />
            </div>
            <div className="task-modal-actions">
              <button className="task-modal-cancel" onClick={() => setModalOpen(false)}>Annuler</button>
              <button
                className="task-modal-save"
                onClick={handleCreate}
                disabled={saving || !newTitle.trim()}
              >
                {saving ? 'Enregistrement' : 'Créer la tâche'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
