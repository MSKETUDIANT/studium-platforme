import React, { useState, useEffect } from 'react';
import { pdf } from '@react-pdf/renderer';
import { colors, fonts, radius } from '../../../shared/constants/theme';
import { RAW_STATUS_LABELS } from '../types/application';
import type { Application, RawStatus } from '../types/application';
import { updateApplicationStatus, updateApplicationNotes, fetchStatusHistory, sendApplicationEmail, fetchEmailLogs } from '../services/applications_service';
import type { StatusHistoryEntry, EmailLog } from '../services/applications_service';
import ApplicationPDF from './ApplicationPDF';

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
  const [status,         setStatus]         = useState<RawStatus>(app.rawStatus);
  const [notes,          setNotes]          = useState(app.notes ?? '');
  const [correctionMsg,  setCorrectionMsg]  = useState('');
  const [saving,         setSaving]         = useState(false);
  const [saved,          setSaved]          = useState(false);
  const [archiveConfirm, setArchiveConfirm] = useState(false);
  const [generatingPdf,  setGeneratingPdf]  = useState(false);
  const [history,        setHistory]        = useState<StatusHistoryEntry[]>([]);
  const [emailLogs,      setEmailLogs]      = useState<EmailLog[]>([]);
  const [sendToEmail,    setSendToEmail]     = useState('');
  const [sendCc,         setSendCc]         = useState('');
  const [sending,        setSending]        = useState(false);
  const [sendError,      setSendError]      = useState<string | null>(null);
  const [sendSuccess,    setSendSuccess]    = useState(false);

  useEffect(() => {
    setStatus(app.rawStatus);
    setNotes(app.notes ?? '');
    setCorrectionMsg('');
    setSaved(false);
    setSendError(null);
    setSendSuccess(false);
    setArchiveConfirm(false);
    setSendToEmail(app.contactEmail ?? '');
    fetchStatusHistory(app.id).then(setHistory).catch(() => setHistory([]));
    fetchEmailLogs(app.id).then(setEmailLogs).catch(() => setEmailLogs([]));
  }, [app]);

  async function handleSendEmail() {
    if (!sendToEmail.trim()) return;
    setSending(true);
    setSendError(null);
    setSendSuccess(false);
    try {
      const cc = sendCc.split(',').map(e => e.trim()).filter(Boolean);
      await sendApplicationEmail(app.id, sendToEmail.trim(), cc);
      setSendSuccess(true);
      onUpdate(app.id, { rawStatus: 'sent', status: 'Validé' });
      fetchEmailLogs(app.id).then(setEmailLogs).catch(() => {});
    } catch (err) {
      setSendError(err instanceof Error ? err.message : 'Erreur inconnue');
    } finally {
      setSending(false);
    }
  }

  async function handleSave() {
    setSaving(true);
    try {
      const ops: Promise<void>[] = [];
      if (status !== app.rawStatus) {
        const note = status === 'needsfix' && correctionMsg.trim() ? correctionMsg.trim() : undefined;
        ops.push(updateApplicationStatus(app.id, status, note));
      }
      if (notes !== (app.notes ?? '')) ops.push(updateApplicationNotes(app.id, notes));
      await Promise.all(ops);
      onUpdate(app.id, {
        rawStatus: status,
        status:    STATUS_MAP_UI[status],
        notes:     notes || undefined,
      });
      setSaved(true);
      setCorrectionMsg('');
      setArchiveConfirm(false);
      setTimeout(() => setSaved(false), 2000);
    } finally {
      setSaving(false);
    }
  }

  async function handleArchive() {
    setSaving(true);
    try {
      await updateApplicationStatus(app.id, 'archived');
      onUpdate(app.id, { rawStatus: 'archived', status: STATUS_MAP_UI['archived'] });
      onClose();
    } finally {
      setSaving(false);
    }
  }

  async function handleDownloadPdf() {
    setGeneratingPdf(true);
    try {
      const blob = await pdf(<ApplicationPDF app={app} history={history} />).toBlob();
      const url  = URL.createObjectURL(blob);
      const a    = document.createElement('a');
      a.href     = url;
      a.download = `Studium_${app.student.replace(/\s+/g, '_')}_${app.program.replace(/\s+/g, '_')}.pdf`;
      a.click();
      URL.revokeObjectURL(url);
    } finally {
      setGeneratingPdf(false);
    }
  }

  const sc = STATUS_COLORS[status];
  const isDirty = status !== app.rawStatus || notes !== (app.notes ?? '') || (status === 'needsfix' && correctionMsg.trim() !== '');

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

          {/* Actions rapides */}
          {app.rawStatus === 'submitted' && status !== 'verified' && (
            <div style={{ display: 'flex', gap: 8 }}>
              <button
                onClick={() => setStatus('verified')}
                style={{
                  flex: 1, padding: '10px 16px', borderRadius: 10, border: 'none',
                  background: `linear-gradient(135deg, ${colors.success} 0%, #15803d 100%)`,
                  color: 'white', fontWeight: 700, fontSize: 13.5, cursor: 'pointer',
                  fontFamily: fonts.body, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 7,
                }}
              >
                <svg width={15} height={15} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                Valider le dossier
              </button>
              <button
                onClick={() => setStatus('needsfix')}
                style={{
                  flex: 1, padding: '10px 16px', borderRadius: 10, border: 'none',
                  background: `linear-gradient(135deg, #f59e0b 0%, #d97706 100%)`,
                  color: 'white', fontWeight: 700, fontSize: 13.5, cursor: 'pointer',
                  fontFamily: fonts.body, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 7,
                }}
              >
                <svg width={15} height={15} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
                Demander correction
              </button>
            </div>
          )}

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

          {/* Message de correction (visible uniquement si NeedsFix) */}
          {status === 'needsfix' && (
            <Section label="Message de correction pour l'étudiant">
              <textarea
                value={correctionMsg}
                onChange={e => setCorrectionMsg(e.target.value)}
                rows={3}
                placeholder="Expliquez à l'étudiant ce qui doit être corrigé ou complété…"
                style={{
                  width: '100%', padding: '10px 14px', borderRadius: 10,
                  border: `1.5px solid #f59e0b`,
                  background: '#fffbeb', fontFamily: fonts.body,
                  fontSize: 13.5, color: colors.textPrimary,
                  resize: 'vertical', outline: 'none', boxSizing: 'border-box',
                }}
              />
              <div style={{ fontSize: 11.5, color: '#d97706', marginTop: 4 }}>
                Ce message sera visible par l'étudiant dans son suivi de candidature.
              </div>
            </Section>
          )}

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

          {/* Envoyer à l'université */}
          {(status === 'verified' || status === 'sent') && (
            <Section label="Envoyer à l'université">
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                <input
                  type="email"
                  value={sendToEmail}
                  onChange={e => setSendToEmail(e.target.value)}
                  placeholder="Email admissions université *"
                  style={{
                    width: '100%', padding: '9px 14px', borderRadius: 8,
                    border: `1.5px solid ${colors.borderInput}`,
                    background: colors.inputBg, fontFamily: fonts.body,
                    fontSize: 13.5, color: colors.textPrimary, outline: 'none', boxSizing: 'border-box',
                  }}
                />
                <input
                  type="text"
                  value={sendCc}
                  onChange={e => setSendCc(e.target.value)}
                  placeholder="CC (optionnel, séparés par des virgules)"
                  style={{
                    width: '100%', padding: '9px 14px', borderRadius: 8,
                    border: `1.5px solid ${colors.borderInput}`,
                    background: colors.inputBg, fontFamily: fonts.body,
                    fontSize: 13.5, color: colors.textPrimary, outline: 'none', boxSizing: 'border-box',
                  }}
                />
                {sendError && (
                  <div style={{ fontSize: 12.5, color: colors.danger, padding: '7px 12px', background: '#fef2f2', borderRadius: 7 }}>
                    {sendError}
                  </div>
                )}
                {sendSuccess && (
                  <div style={{ fontSize: 12.5, color: colors.success, padding: '7px 12px', background: '#f0fdf4', borderRadius: 7 }}>
                    Email envoyé avec succès — statut mis à jour à "Envoyée".
                  </div>
                )}
                <button
                  onClick={handleSendEmail}
                  disabled={sending || !sendToEmail.trim() || sendSuccess}
                  style={{
                    padding: '10px 18px', borderRadius: 9, border: 'none',
                    background: sendSuccess
                      ? colors.success
                      : sendToEmail.trim()
                        ? `linear-gradient(135deg, #1e3a8a 0%, #1e40af 100%)`
                        : colors.border,
                    color: sendToEmail.trim() || sendSuccess ? 'white' : colors.textMuted,
                    fontWeight: 700, fontSize: 13.5, cursor: sendToEmail.trim() && !sending && !sendSuccess ? 'pointer' : 'default',
                    fontFamily: fonts.body, display: 'flex', alignItems: 'center', gap: 8, alignSelf: 'flex-start',
                    opacity: sending ? 0.7 : 1, transition: 'all .2s',
                  }}
                >
                  <svg width={14} height={14} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
                  {sending ? 'Envoi en cours…' : sendSuccess ? 'Envoyé' : 'Envoyer à l\'université'}
                </button>
              </div>
            </Section>
          )}

          {/* Logs d'envoi email */}
          {emailLogs.length > 0 && (
            <Section label="Historique des envois email">
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                {emailLogs.map(log => (
                  <div key={log.id} style={{
                    padding: '9px 12px', borderRadius: 8,
                    background: log.status === 'sent' ? '#f0fdf4' : '#fef2f2',
                    border: `1px solid ${log.status === 'sent' ? '#bbf7d0' : '#fecaca'}`,
                    fontSize: 12.5,
                  }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span style={{ fontWeight: 700, color: log.status === 'sent' ? colors.success : colors.danger }}>
                        {log.status === 'sent' ? 'Envoyé' : log.status === 'failed' ? 'Échec' : 'Bounce'}
                      </span>
                      <span style={{ fontSize: 11, color: colors.textMuted }}>
                        {new Date(log.sentAt).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>
                    <div style={{ color: colors.textSecondary, marginTop: 2 }}>→ {log.toEmail}</div>
                    {log.errorMessage && <div style={{ color: colors.danger, fontSize: 11.5, marginTop: 2 }}>{log.errorMessage}</div>}
                  </div>
                ))}
              </div>
            </Section>
          )}

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
          background: '#fafbff', borderRadius: '0 0 16px 16px',
        }}>
          {archiveConfirm ? (
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, justifyContent: 'flex-end' }}>
              <span style={{ fontSize: 13, color: colors.textSecondary }}>Archiver définitivement ce dossier ?</span>
              <button
                onClick={() => setArchiveConfirm(false)}
                style={{
                  padding: '8px 16px', borderRadius: radius.md,
                  border: `1.5px solid ${colors.borderInput}`,
                  background: 'white', color: colors.textSecondary,
                  fontWeight: 600, fontSize: 13, cursor: 'pointer', fontFamily: fonts.body,
                }}
              >
                Annuler
              </button>
              <button
                onClick={handleArchive}
                disabled={saving}
                style={{
                  padding: '8px 18px', borderRadius: radius.md, border: 'none',
                  background: '#6b7280', color: 'white',
                  fontWeight: 700, fontSize: 13, cursor: 'pointer', fontFamily: fonts.body,
                }}
              >
                {saving ? 'Archivage…' : 'Confirmer l\'archivage'}
              </button>
            </div>
          ) : (
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 10 }}>
              <div style={{ display: 'flex', gap: 8 }}>
                <button
                  onClick={handleDownloadPdf}
                  disabled={generatingPdf}
                  style={{
                    padding: '9px 16px', borderRadius: radius.md,
                    border: `1.5px solid ${colors.blue}`,
                    background: 'white', color: colors.blue,
                    fontWeight: 600, fontSize: 13, cursor: 'pointer', fontFamily: fonts.body,
                    display: 'flex', alignItems: 'center', gap: 6, opacity: generatingPdf ? 0.6 : 1,
                  }}
                >
                  <svg width={13} height={13} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="12" y1="18" x2="12" y2="12"/><polyline points="9 15 12 18 15 15"/></svg>
                  {generatingPdf ? 'Génération…' : 'PDF'}
                </button>
                <button
                  onClick={() => setArchiveConfirm(true)}
                  style={{
                    padding: '9px 16px', borderRadius: radius.md,
                    border: `1.5px solid ${colors.borderInput}`,
                    background: 'white', color: '#6b7280',
                    fontWeight: 600, fontSize: 13, cursor: 'pointer', fontFamily: fonts.body,
                    display: 'flex', alignItems: 'center', gap: 6,
                  }}
                >
                  <svg width={13} height={13} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><polyline points="21 8 21 21 3 21 3 8"/><rect x="1" y="3" width="22" height="5"/><line x1="10" y1="12" x2="14" y2="12"/></svg>
                  Archiver
                </button>
              </div>
              <div style={{ display: 'flex', gap: 10 }}>
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
          )}
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
