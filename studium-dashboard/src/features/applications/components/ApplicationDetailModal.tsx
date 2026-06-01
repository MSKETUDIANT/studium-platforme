import React, { useState, useEffect } from 'react';
import { colors, fonts, radius } from '../../../shared/constants/theme';
import { RAW_STATUS_LABELS } from '../types/application';
import type { Application, RawStatus } from '../types/application';
import { updateApplicationStatus, updateApplicationNotes, fetchStatusHistory } from '../services/applications_service';
import type { StatusHistoryEntry } from '../services/applications_service';

const AVAILABLE_STATUSES: RawStatus[] = [
  'submitted', 'needsfix', 'verified', 'sent', 'accepted', 'rejected', 'archived',
];

const STATUS_COLORS: Record<RawStatus, { bg: string; color: string }> = {
  draft:            { bg: '#f3f4f6', color: '#6b7280' },
  submitted:        { bg: '#eff6ff', color: '#2563eb' },
  needsfix:         { bg: '#fff7ed', color: '#d97706' },
  verified:         { bg: '#f0fdf4', color: '#16a34a' },
  sent:             { bg: '#eff6ff', color: '#2546cc' },
  accepted:         { bg: '#f0fdf4', color: '#15803d' },
  rejected:         { bg: '#fef2f2', color: '#dc2626' },
  pending_decision: { bg: '#fefce8', color: '#b45309' },
  archived:         { bg: '#f9fafb', color: '#6b7280' },
};

const TIMELINE_STEPS: { label: string; statuses: RawStatus[] }[] = [
  { label: 'Soumise',       statuses: ['submitted', 'needsfix', 'verified', 'sent', 'accepted', 'rejected', 'pending_decision', 'archived'] },
  { label: 'En vérification', statuses: ['verified', 'sent', 'accepted', 'rejected', 'archived'] },
  { label: 'Envoyée',       statuses: ['sent', 'accepted', 'rejected', 'archived'] },
  { label: 'Résultat',      statuses: ['accepted', 'rejected', 'archived'] },
];

interface Props {
  app:      Application;
  onClose:  () => void;
  onUpdate: (id: string, patch: Partial<Application>) => void;
}

export default function ApplicationDetailModal({ app, onClose, onUpdate }: Props) {
  const [status,  setStatus]  = useState<RawStatus>(app.rawStatus);
  const [notes,   setNotes]   = useState(app.notes ?? '');
  const [saving,  setSaving]  = useState(false);
  const [saved,   setSaved]   = useState(false);
  const [history, setHistory] = useState<StatusHistoryEntry[]>([]);

  useEffect(() => {
    setStatus(app.rawStatus);
    setNotes(app.notes ?? '');
    setSaved(false);
    fetchStatusHistory(app.id).then(setHistory).catch(() => setHistory([]));
  }, [app]);

  async function handleSave() {
    setSaving(true);
    try {
      const ops: Promise<void>[] = [];
      if (status !== app.rawStatus)       ops.push(updateApplicationStatus(app.id, status));
      if (notes  !== (app.notes ?? ''))   ops.push(updateApplicationNotes(app.id, notes));
      await Promise.all(ops);
      onUpdate(app.id, {
        rawStatus: status,
        status:    STATUS_MAP_UI[status],
        notes:     notes || undefined,
      });
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } finally {
      setSaving(false);
    }
  }

  const sc = STATUS_COLORS[status];
  const isDirty = status !== app.rawStatus || notes !== (app.notes ?? '');

  return (
    <div
      onClick={onClose}
      style={{
        position: 'fixed', inset: 0,
        background: 'rgba(10,14,40,0.55)',
        backdropFilter: 'blur(3px)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        zIndex: 1000, padding: 16,
      }}
    >
      <div
        onClick={e => e.stopPropagation()}
        style={{
          background: 'white',
          borderRadius: 16,
          width: '100%', maxWidth: 640,
          maxHeight: '90vh', overflowY: 'auto',
          boxShadow: '0 24px 64px rgba(0,0,0,0.18)',
          fontFamily: fonts.body,
        }}
      >
        {/* Header */}
        <div style={{
          padding: '20px 24px 16px',
          borderBottom: `1px solid ${colors.border}`,
          display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12,
        }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '.07em', textTransform: 'uppercase', color: colors.textMuted, marginBottom: 4 }}>
              Dossier candidature
            </div>
            <div style={{ fontSize: 18, fontWeight: 800, color: colors.navy, fontFamily: fonts.display }}>
              {app.student}
            </div>
            {app.email && <div style={{ fontSize: 13, color: colors.textMuted, marginTop: 2 }}>{app.email}</div>}
          </div>
          <button onClick={onClose} style={{
            background: colors.inputBg, border: 'none', borderRadius: 8,
            width: 32, height: 32, cursor: 'pointer', display: 'flex',
            alignItems: 'center', justifyContent: 'center', color: colors.textMuted,
            flexShrink: 0,
          }}>
            <svg width={16} height={16} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>

        <div style={{ padding: '20px 24px', display: 'flex', flexDirection: 'column', gap: 20 }}>

          {/* Programme */}
          <Section label="Programme">
            <div style={{
              background: colors.inputBg, borderRadius: radius.md,
              padding: '12px 16px',
            }}>
              <div style={{ fontWeight: 700, fontSize: 14, color: colors.navy }}>{app.program}</div>
              <div style={{ fontSize: 13, color: colors.textMuted, marginTop: 3 }}>{app.university}</div>
              <div style={{ display: 'flex', gap: 8, marginTop: 8, flexWrap: 'wrap' }}>
                {app.country && <Tag>{app.country}</Tag>}
                {app.level   && <Tag>{levelLabel(app.level)}</Tag>}
              </div>
            </div>
          </Section>

          {/* Score dossier */}
          <Section label="Score dossier">
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{
                flex: 1, height: 8, borderRadius: 4,
                background: colors.border, overflow: 'hidden',
              }}>
                <div style={{
                  height: '100%', borderRadius: 4,
                  width: `${app.score}%`,
                  background: app.score >= 80 ? colors.success : app.score >= 65 ? colors.warning : colors.danger,
                  transition: 'width .4s',
                }} />
              </div>
              <span style={{
                fontSize: 15, fontWeight: 800,
                color: app.score >= 80 ? colors.success : app.score >= 65 ? colors.warning : colors.danger,
                minWidth: 36,
              }}>
                {app.score}%
              </span>
            </div>
          </Section>

          {/* Complétude du dossier */}
          <Section label="Complétude du dossier">
            <ChecklistSection app={app} />
          </Section>

          {/* Timeline */}
          <Section label="Progression">
            <div style={{ display: 'flex', gap: 0 }}>
              {TIMELINE_STEPS.map((step, i) => {
                const done = step.statuses.includes(status);
                const isLast = i === TIMELINE_STEPS.length - 1;
                return (
                  <div key={step.label} style={{ display: 'flex', alignItems: 'center', flex: isLast ? 0 : 1 }}>
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                      <div style={{
                        width: 20, height: 20, borderRadius: '50%',
                        background: done ? colors.success : colors.border,
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        flexShrink: 0,
                      }}>
                        {done && <svg width={11} height={11} viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth={3} strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>}
                      </div>
                      <span style={{ fontSize: 10, color: done ? colors.success : colors.textMuted, fontWeight: done ? 700 : 500, whiteSpace: 'nowrap' }}>
                        {step.label}
                      </span>
                    </div>
                    {!isLast && <div style={{ flex: 1, height: 2, background: done ? colors.success : colors.border, margin: '0 4px', marginBottom: 18 }} />}
                  </div>
                );
              })}
            </div>
          </Section>

          {/* Changer le statut */}
          <Section label="Statut">
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {AVAILABLE_STATUSES.map(s => {
                const c = STATUS_COLORS[s];
                const active = s === status;
                return (
                  <button
                    key={s}
                    onClick={() => setStatus(s)}
                    style={{
                      padding: '6px 14px', borderRadius: 20, fontSize: 12.5,
                      fontWeight: 700, cursor: 'pointer', fontFamily: fonts.body,
                      border: `2px solid ${active ? c.color : 'transparent'}`,
                      background: active ? c.bg : colors.inputBg,
                      color: active ? c.color : colors.textSecondary,
                      transition: 'all .15s',
                    }}
                  >
                    {RAW_STATUS_LABELS[s]}
                  </button>
                );
              })}
            </div>
            <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 12, color: colors.textMuted }}>Statut actuel :</span>
              <span style={{
                padding: '3px 10px', borderRadius: 20, fontSize: 12, fontWeight: 700,
                background: sc.bg, color: sc.color,
              }}>
                {RAW_STATUS_LABELS[status]}
              </span>
            </div>
          </Section>

          {/* Historique des changements */}
          <Section label="Historique des changements">
            {history.length === 0 ? (
              <div style={{ fontSize: 13, color: colors.textMuted, fontStyle: 'italic' }}>
                Aucun changement enregistré pour le moment.
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 0 }}>
                {history.map((entry, i) => {
                  const isLast = i === history.length - 1;
                  const date = entry.createdAt
                    ? new Date(entry.createdAt).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' })
                    : '';
                  return (
                    <div key={entry.id} style={{ display: 'flex', gap: 12 }}>
                      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', flexShrink: 0 }}>
                        <div style={{
                          width: 10, height: 10, borderRadius: '50%',
                          background: colors.blue, marginTop: 3, flexShrink: 0,
                        }} />
                        {!isLast && <div style={{ width: 2, flex: 1, background: colors.border, minHeight: 24 }} />}
                      </div>
                      <div style={{ paddingBottom: isLast ? 0 : 12, minWidth: 0 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                          {entry.fromStatus && (
                            <>
                              <span style={{ fontSize: 12, color: colors.textMuted }}>{RAW_STATUS_LABELS[entry.fromStatus as RawStatus] ?? entry.fromStatus}</span>
                              <span style={{ fontSize: 11, color: colors.textMuted }}>→</span>
                            </>
                          )}
                          <span style={{ fontSize: 13, fontWeight: 700, color: colors.navy }}>
                            {RAW_STATUS_LABELS[entry.toStatus as RawStatus] ?? entry.toStatus}
                          </span>
                          {date && <span style={{ fontSize: 11, color: colors.textMuted, marginLeft: 4 }}>{date}</span>}
                        </div>
                        {entry.note && (
                          <div style={{ fontSize: 12, color: colors.textSecondary, fontStyle: 'italic', marginTop: 2 }}>
                            {entry.note}
                          </div>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </Section>

          {/* Notes internes */}
          <Section label="Notes internes (équipe)">
            <textarea
              value={notes}
              onChange={e => setNotes(e.target.value)}
              rows={3}
              placeholder="Ajouter une note interne visible uniquement par l'équipe…"
              style={{
                width: '100%', padding: '10px 14px', borderRadius: radius.md,
                border: `1.5px solid ${colors.borderInput}`,
                background: colors.inputBg, fontFamily: fonts.body,
                fontSize: 13.5, color: colors.textPrimary,
                resize: 'vertical', outline: 'none', boxSizing: 'border-box',
              }}
            />
          </Section>

        </div>

        {/* Footer */}
        <div style={{
          padding: '14px 24px',
          borderTop: `1px solid ${colors.border}`,
          display: 'flex', justifyContent: 'flex-end', gap: 10,
          background: '#fafbff', borderRadius: '0 0 16px 16px',
        }}>
          <button onClick={onClose} style={{
            padding: '9px 20px', borderRadius: radius.md,
            border: `1.5px solid ${colors.borderInput}`,
            background: 'white', color: colors.textSecondary,
            fontWeight: 600, fontSize: 13.5, cursor: 'pointer',
            fontFamily: fonts.body,
          }}>
            Fermer
          </button>
          <button
            onClick={handleSave}
            disabled={saving || !isDirty}
            style={{
              padding: '9px 22px', borderRadius: radius.md, border: 'none',
              background: saved
                ? colors.success
                : isDirty
                  ? `linear-gradient(135deg, ${colors.navy} 0%, #1e40af 100%)`
                  : colors.border,
              color: isDirty || saved ? 'white' : colors.textMuted,
              fontWeight: 700, fontSize: 13.5, cursor: isDirty ? 'pointer' : 'default',
              fontFamily: fonts.body, transition: 'all .2s',
              display: 'flex', alignItems: 'center', gap: 7,
            }}
          >
            {saving ? (
              <svg width={14} height={14} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round">
                <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
              </svg>
            ) : saved ? (
              <svg width={14} height={14} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>
            ) : null}
            {saved ? 'Enregistré' : saving ? 'Enregistrement…' : 'Enregistrer'}
          </button>
        </div>
      </div>
    </div>
  );
}

/* ─── Helpers ────────────────────────────────────────────────────────────── */

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

function levelLabel(level: string) {
  return level === 'bachelor' ? 'Licence' : level === 'master' ? 'Master' : level === 'phd' ? 'PhD' : level;
}

function Section({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '.07em', textTransform: 'uppercase', color: colors.textMuted, marginBottom: 8 }}>
        {label}
      </div>
      {children}
    </div>
  );
}

function Tag({ children }: { children: React.ReactNode }) {
  return (
    <span style={{
      padding: '3px 10px', borderRadius: 20, fontSize: 11.5, fontWeight: 600,
      background: 'rgba(37,70,204,0.08)', color: colors.blue,
    }}>
      {children}
    </span>
  );
}

function ChecklistSection({ app }: { app: Application }) {
  const items = [
    { label: 'Candidature soumise',   ok: app.rawStatus !== 'draft' },
    { label: 'Programme sélectionné', ok: app.program !== '—' && app.program !== '' },
    { label: 'Université renseignée', ok: app.university !== '—' && app.university !== '' },
    { label: 'Pays de destination',   ok: app.country !== '—' && app.country !== '' },
    { label: "Niveau d'études",       ok: !!app.level },
    { label: 'Score profil ≥ 70%',    ok: app.score >= 70, extra: `${app.score}%` },
  ];
  const okCount = items.filter(i => i.ok).length;
  const allOk = okCount === items.length;
  const summaryColor = allOk ? colors.success : okCount >= 4 ? colors.warning : colors.danger;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
        <span style={{ fontSize: 12, color: colors.textMuted }}>{okCount}/{items.length} critères remplis</span>
        <span style={{ fontSize: 12, fontWeight: 700, color: summaryColor, padding: '2px 10px', borderRadius: 20, background: `${summaryColor}18` }}>
          {allOk ? 'Dossier complet' : okCount >= 4 ? 'Presque complet' : 'Incomplet'}
        </span>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
        {items.map(item => (
          <div key={item.label} style={{ display: 'flex', alignItems: 'center', gap: 9 }}>
            <div style={{
              width: 18, height: 18, borderRadius: '50%', flexShrink: 0,
              background: item.ok ? `${colors.success}18` : `${colors.danger}12`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              {item.ok
                ? <svg width={10} height={10} viewBox="0 0 24 24" fill="none" stroke={colors.success} strokeWidth={3} strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                : <svg width={10} height={10} viewBox="0 0 24 24" fill="none" stroke={colors.danger} strokeWidth={3} strokeLinecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
              }
            </div>
            <span style={{ fontSize: 13, color: item.ok ? colors.textPrimary : colors.textMuted }}>
              {item.label}
              {'extra' in item && item.extra && (
                <span style={{ marginLeft: 6, fontSize: 11.5, fontWeight: 700, color: item.ok ? colors.success : colors.danger }}>
                  {item.extra}
                </span>
              )}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
