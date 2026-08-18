import { useState } from 'react';
import { colors, fonts, radius, shadows } from '../../../shared/constants/theme';
import { KANBAN_COLUMNS }            from '../types/application';
import type { Application, RawStatus } from '../types/application';
import { updateApplicationStatus }               from '../services/applications_service';

interface Props {
  apps:     Application[];
  onUpdate: (id: string, patch: Partial<Application>) => void;
  onSelect: (app: Application) => void;
}

const COL_COLORS: Record<string, { accent: string; bg: string; badge: string }> = {
  received:   { accent: colors.blue,    bg: 'rgba(37,70,204,0.06)',  badge: 'rgba(37,70,204,0.12)'  },
  correction: { accent: colors.warning, bg: 'rgba(217,119,6,0.06)', badge: 'rgba(217,119,6,0.12)'  },
  verified:   { accent: '#7c3aed',      bg: 'rgba(124,58,237,0.06)',badge: 'rgba(124,58,237,0.12)' },
  sent:       { accent: '#0891b2',      bg: 'rgba(8,145,178,0.06)', badge: 'rgba(8,145,178,0.12)'  },
  accepted:   { accent: colors.success, bg: 'rgba(22,163,74,0.06)', badge: 'rgba(22,163,74,0.12)'  },
  rejected:   { accent: colors.danger,  bg: 'rgba(220,38,38,0.06)', badge: 'rgba(220,38,38,0.12)'  },
};

const STATUS_MAP_UI: Record<RawStatus, Application['status']> = {
  draft:            'Brouillon',
  submitted:        'Soumise',
  needsfix:         'Correction',
  verified:         'Vérifiée',
  sent:             'Envoyée',
  accepted:         'Acceptée',
  rejected:         'Refusée',
  pending_decision: 'En attente',
  archived:         'Archivée',
};

export default function ApplicationKanban({ apps, onUpdate, onSelect }: Props) {
  const [dragId,      setDragId]      = useState<string | null>(null);
  const [dragOverCol, setDragOverCol] = useState<string | null>(null);

  function getColApps(colId: string) {
    const col = KANBAN_COLUMNS.find(c => c.id === colId)!;
    return apps.filter(a => col.statuses.includes(a.rawStatus));
  }

  async function handleDrop(colId: string) {
    if (!dragId) return;
    const col = KANBAN_COLUMNS.find(c => c.id === colId)!;
    const app = apps.find(a => a.id === dragId);
    if (!app || app.rawStatus === col.target) return;
    // "Envoyée" ne doit être atteint qu'après un envoi email réussi (règle
    // métier CDC §10) — un glisser-déposer ici ne doit pas court-circuiter
    // l'action réelle d'envoi. On ouvre plutôt la fiche pour que l'agent
    // utilise le bouton "Envoyer à l'université".
    if (col.target === 'sent') {
      setDragId(null);
      setDragOverCol(null);
      onSelect(app);
      return;
    }
    try {
      await updateApplicationStatus(dragId, col.target);
      onUpdate(dragId, { rawStatus: col.target, status: STATUS_MAP_UI[col.target] });
    } catch {
      // revert handled by parent re-fetch
    }
    setDragId(null);
    setDragOverCol(null);
  }

  return (
    <div style={{
      display: 'flex', gap: 12, overflowX: 'auto',
      paddingBottom: 12, alignItems: 'flex-start',
    }}>
      {KANBAN_COLUMNS.map(col => {
        const colApps = getColApps(col.id);
        const c       = COL_COLORS[col.id];
        const isOver  = dragOverCol === col.id;

        return (
          <div
            key={col.id}
            onDragOver={e => { e.preventDefault(); setDragOverCol(col.id); }}
            onDragLeave={() => setDragOverCol(null)}
            onDrop={() => handleDrop(col.id)}
            style={{
              minWidth: 268, flex: '0 0 268px',
              background: isOver ? c.bg : 'white',
              border: `1.5px solid ${isOver ? c.accent : colors.border}`,
              borderRadius: radius.lg,
              boxShadow: isOver ? `0 0 0 3px ${c.accent}20, ${shadows.card}` : shadows.card,
              overflow: 'hidden',
              transition: 'border-color .15s, box-shadow .15s, background .15s',
            }}
          >
            {/* Top accent bar */}
            <div style={{ height: 3, background: c.accent }} />

            {/* Column header */}
            <div style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              padding: '11px 14px 10px',
              borderBottom: `1px solid ${colors.border}`,
              background: isOver ? c.bg : '#fafbff',
            }}>
              <span style={{
                fontSize: 11, fontWeight: 800, color: c.accent,
                textTransform: 'uppercase', letterSpacing: '.08em',
              }}>
                {col.label}
              </span>
              <span style={{
                background: c.badge, color: c.accent,
                fontSize: 11, fontWeight: 700,
                padding: '2px 9px', borderRadius: 20,
                minWidth: 22, textAlign: 'center',
              }}>
                {colApps.length}
              </span>
            </div>

            {/* Cards */}
            <div style={{ padding: '10px 10px 12px', display: 'flex', flexDirection: 'column', gap: 8, minHeight: 80 }}>
              {colApps.length === 0 ? (
                <div style={{
                  display: 'flex', flexDirection: 'column', alignItems: 'center',
                  justifyContent: 'center', gap: 6,
                  padding: '28px 12px',
                  border: `1.5px dashed ${colors.border}`,
                  borderRadius: radius.md,
                  color: colors.textMuted, fontSize: 12,
                }}>
                  <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5} opacity={.4}>
                    <rect x="3" y="3" width="18" height="18" rx="2"/>
                    <path d="M9 9h6M9 12h6M9 15h4"/>
                  </svg>
                  Aucun dossier
                </div>
              ) : (
                colApps.map(app => (
                  <KanbanCard
                    key={app.id}
                    app={app}
                    accent={c.accent}
                    isDragging={dragId === app.id}
                    onDragStart={() => setDragId(app.id)}
                    onDragEnd={() => { setDragId(null); setDragOverCol(null); }}
                    onClick={() => onSelect(app)}
                  />
                ))
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}

/*  Kanban card  */
function KanbanCard({ app, accent, isDragging, onDragStart, onDragEnd, onClick }: {
  app:         Application;
  accent:      string;
  isDragging:  boolean;
  onDragStart: () => void;
  onDragEnd:   () => void;
  onClick:     () => void;
}) {
  const initials = app.student.split(' ').map((n: string) => n[0]).join('').toUpperCase().slice(0, 2);
  const isDeadlinePast = app.deadline ? new Date(app.deadline) < new Date() : false;
  const sc = app.score >= 80 ? colors.success : app.score >= 65 ? colors.warning : colors.danger;

  const fmtDate = (d: string) =>
    new Date(d).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short' });

  return (
    <div
      draggable
      onDragStart={onDragStart}
      onDragEnd={onDragEnd}
      onClick={onClick}
      style={{
        background: 'white',
        borderRadius: radius.md,
        border: `1.5px solid ${colors.border}`,
        padding: '10px 12px 10px',
        cursor: 'grab',
        userSelect: 'none',
        opacity: isDragging ? .45 : 1,
        transform: isDragging ? 'rotate(2deg) scale(.97)' : 'none',
        transition: 'box-shadow .15s, transform .12s, border-color .15s, opacity .15s',
        position: 'relative',
        overflow: 'hidden',
      }}
      onMouseEnter={e => {
        const el = e.currentTarget as HTMLDivElement;
        el.style.boxShadow = `0 4px 16px rgba(0,0,0,0.10)`;
        el.style.borderColor = accent;
        el.style.transform = 'translateY(-2px)';
      }}
      onMouseLeave={e => {
        const el = e.currentTarget as HTMLDivElement;
        el.style.boxShadow = 'none';
        el.style.borderColor = colors.border;
        el.style.transform = 'none';
      }}
    >
      {/* Left accent stripe */}
      <div style={{
        position: 'absolute', left: 0, top: 0, bottom: 0,
        width: 3, background: accent, borderRadius: '4px 0 0 4px',
      }} />

      {/* Student row */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 9, marginBottom: 8, paddingLeft: 6 }}>
        <div style={{
          width: 32, height: 32, borderRadius: '50%', flexShrink: 0,
          background: `${accent}18`, color: accent,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 11, fontWeight: 800, fontFamily: fonts.display,
          boxShadow: `0 0 0 2px white, 0 0 0 3px ${accent}30`,
        }}>
          {initials}
        </div>
        <div style={{ minWidth: 0, flex: 1 }}>
          <div style={{
            fontSize: 12.5, fontWeight: 700, color: colors.navy,
            overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
          }}>
            {app.student}
          </div>
          <div style={{
            fontSize: 10.5, color: colors.textMuted,
            display: 'flex', alignItems: 'center', gap: 3,
            overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
          }}>
            <svg width={9} height={9} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} style={{ flexShrink: 0 }}>
              <circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/>
              <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>
            </svg>
            {app.country}
          </div>
        </div>
        {app.level && (
          <span style={{
            fontSize: 9.5, fontWeight: 700, padding: '2px 6px',
            borderRadius: 4, background: `${accent}10`, color: accent,
            flexShrink: 0, textTransform: 'uppercase', letterSpacing: '.03em',
          }}>
            {app.level}
          </span>
        )}
      </div>

      {/* Program + university */}
      <div style={{ paddingLeft: 6, marginBottom: 9 }}>
        <div style={{
          fontSize: 11.5, fontWeight: 600, color: colors.textPrimary,
          overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
          marginBottom: 2,
        }}>
          {app.program}
        </div>
        <div style={{
          fontSize: 10.5, color: colors.textMuted,
          overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
        }}>
          {app.university}
        </div>
      </div>

      {/* Score + date */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        paddingLeft: 6,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
          <div style={{ width: 44, height: 5, borderRadius: 3, background: colors.border, overflow: 'hidden' }}>
            <div style={{
              height: '100%', borderRadius: 3,
              width: `${app.score}%`, background: sc,
            }} />
          </div>
          <span style={{ fontSize: 10.5, fontWeight: 800, color: sc }}>
            {app.score}%
          </span>
        </div>
        {app.date && (
          <span style={{
            fontSize: 10.5, color: colors.textMuted,
            display: 'flex', alignItems: 'center', gap: 3,
          }}>
            <svg width={9} height={9} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>
            </svg>
            {fmtDate(app.date)}
          </span>
        )}
      </div>

      {/* Deadline badge */}
      {isDeadlinePast && (
        <div style={{
          marginTop: 7, paddingLeft: 6,
          display: 'inline-flex', alignItems: 'center', gap: 4,
          background: 'rgba(220,38,38,0.07)',
          borderRadius: 4, padding: '3px 7px',
          border: '1px solid rgba(220,38,38,0.18)',
        }}>
          <svg width={9} height={9} fill="none" viewBox="0 0 24 24" stroke={colors.danger} strokeWidth={2.5}>
            <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
          <span style={{ fontSize: 10, fontWeight: 700, color: colors.danger }}>Délai dépassé</span>
        </div>
      )}
    </div>
  );
}
