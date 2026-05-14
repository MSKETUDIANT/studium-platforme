import React, { useState } from 'react';
import { colors, fonts, radius, shadows } from '../../../shared/constants/theme';
import { Application, KANBAN_COLUMNS, RawStatus } from '../types/application';
import { updateApplicationStatus }               from '../services/applications_service';

interface Props {
  apps:     Application[];
  onUpdate: (id: string, patch: Partial<Application>) => void;
  onSelect: (app: Application) => void;
}

const COL_COLORS: Record<string, { accent: string; bg: string; badge: string }> = {
  received:   { accent: colors.blue,    bg: 'rgba(37,70,204,0.07)',  badge: 'rgba(37,70,204,0.12)'  },
  correction: { accent: colors.warning, bg: 'rgba(217,119,6,0.07)', badge: 'rgba(217,119,6,0.12)'  },
  verified:   { accent: '#7c3aed',      bg: 'rgba(124,58,237,0.07)',badge: 'rgba(124,58,237,0.12)' },
  sent:       { accent: '#0891b2',      bg: 'rgba(8,145,178,0.07)', badge: 'rgba(8,145,178,0.12)'  },
  accepted:   { accent: colors.success, bg: 'rgba(22,163,74,0.07)', badge: 'rgba(22,163,74,0.12)'  },
  rejected:   { accent: colors.danger,  bg: 'rgba(220,38,38,0.07)', badge: 'rgba(220,38,38,0.12)'  },
};

const STATUS_MAP_UI: Record<RawStatus, Application['status']> = {
  draft:            'En attente',
  submitted:        'En attente',
  needsfix:         'Urgent',
  verified:         'Validé',
  sent:             'Validé',
  accepted:         'Validé',
  rejected:         'Refusé',
  pending_decision: 'En attente',
  archived:         'Refusé',
};

export default function ApplicationKanban({ apps, onUpdate, onSelect }: Props) {
  const [dragId,     setDragId]     = useState<string | null>(null);
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
      display: 'flex', gap: 14, overflowX: 'auto',
      paddingBottom: 8, alignItems: 'flex-start',
    }}>
      {KANBAN_COLUMNS.map(col => {
        const colApps  = getColApps(col.id);
        const c        = COL_COLORS[col.id];
        const isOver   = dragOverCol === col.id;

        return (
          <div
            key={col.id}
            onDragOver={e => { e.preventDefault(); setDragOverCol(col.id); }}
            onDragLeave={() => setDragOverCol(null)}
            onDrop={() => handleDrop(col.id)}
            style={{
              minWidth: 230, flex: '0 0 230px',
              background: isOver ? c.bg : '#f8faff',
              border: `2px solid ${isOver ? c.accent : colors.border}`,
              borderRadius: radius.lg,
              padding: '12px 10px',
              transition: 'border-color .15s, background .15s',
            }}
          >
            {/* Column header */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12, padding: '0 4px' }}>
              <span style={{ fontSize: 12, fontWeight: 800, color: c.accent, textTransform: 'uppercase', letterSpacing: '.07em' }}>
                {col.label}
              </span>
              <span style={{
                background: c.badge, color: c.accent,
                fontSize: 11, fontWeight: 800,
                padding: '2px 8px', borderRadius: 20,
              }}>
                {colApps.length}
              </span>
            </div>

            {/* Cards */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {colApps.length === 0 ? (
                <div style={{
                  padding: '24px 12px', textAlign: 'center',
                  color: colors.textMuted, fontSize: 12,
                  border: `1.5px dashed ${colors.border}`,
                  borderRadius: radius.md,
                }}>
                  Aucun dossier
                </div>
              ) : (
                colApps.map(app => (
                  <KanbanCard
                    key={app.id}
                    app={app}
                    accent={c.accent}
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

/* ─── Kanban card ─────────────────────────────────────────────────────────── */

function KanbanCard({ app, accent, onDragStart, onDragEnd, onClick }: {
  app:         Application;
  accent:      string;
  onDragStart: () => void;
  onDragEnd:   () => void;
  onClick:     () => void;
}) {
  const initials = app.student.split(' ').map((n: string) => n[0]).join('').toUpperCase().slice(0, 2);

  return (
    <div
      draggable
      onDragStart={onDragStart}
      onDragEnd={onDragEnd}
      onClick={onClick}
      style={{
        background: 'white',
        borderRadius: radius.md,
        boxShadow: shadows.card,
        padding: '10px 12px',
        cursor: 'grab',
        userSelect: 'none',
        borderLeft: `3px solid ${accent}`,
        transition: 'box-shadow .15s, transform .1s',
      }}
      onMouseEnter={e => { (e.currentTarget as HTMLDivElement).style.boxShadow = shadows.modal ?? '0 4px 16px rgba(0,0,0,0.12)'; }}
      onMouseLeave={e => { (e.currentTarget as HTMLDivElement).style.boxShadow = shadows.card; }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
        <div style={{
          width: 28, height: 28, borderRadius: 7, flexShrink: 0,
          background: `${accent}18`, color: accent,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 10, fontWeight: 800, fontFamily: fonts.display,
        }}>
          {initials}
        </div>
        <div style={{ minWidth: 0 }}>
          <div style={{ fontSize: 12.5, fontWeight: 700, color: colors.navy, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {app.student}
          </div>
          <div style={{ fontSize: 11, color: colors.textMuted, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {app.email}
          </div>
        </div>
      </div>

      <div style={{ fontSize: 11.5, color: colors.textSecondary, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', marginBottom: 6 }}>
        {app.program}
      </div>
      <div style={{ fontSize: 11, color: colors.textMuted, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', marginBottom: 8 }}>
        {app.university}
      </div>

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
          <div style={{ width: 40, height: 4, borderRadius: 2, background: colors.border, overflow: 'hidden' }}>
            <div style={{
              height: '100%', borderRadius: 2,
              width: `${app.score}%`,
              background: app.score >= 80 ? colors.success : app.score >= 65 ? colors.warning : colors.danger,
            }} />
          </div>
          <span style={{ fontSize: 10.5, fontWeight: 700, color: app.score >= 80 ? colors.success : app.score >= 65 ? colors.warning : colors.danger }}>
            {app.score}%
          </span>
        </div>
        {app.date && (
          <span style={{ fontSize: 10.5, color: colors.textMuted }}>
            {new Date(app.date).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short' })}
          </span>
        )}
      </div>
    </div>
  );
}
