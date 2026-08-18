import React, { useState, useEffect, useRef } from 'react';
import { pdf } from '@react-pdf/renderer';
import { colors, fonts, radius } from '../../../shared/constants/theme';
import { RAW_STATUS_LABELS } from '../types/application';
import type { Application, RawStatus } from '../types/application';
import { updateApplicationStatus, updateApplicationNotes, fetchStatusHistory, sendApplicationEmail, fetchEmailLogs, logManualSend, sendCorrectionMessage, fetchApplicationDocuments, approveDocument, rejectDocument, docTypeLabel, fetchApplicationComments, addApplicationComment, deleteApplicationComment } from '../services/applications_service';
import type { StatusHistoryEntry, EmailLog, ApplicationDocument, ApplicationComment } from '../services/applications_service';
import ApplicationPDF from './ApplicationPDF';
import { useRole } from '../../auth/hooks/useRole';
import { can } from '../../auth/hooks/permissions';

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

const DOC_TYPE_SHORT: Record<string, string> = {
  cv:                'CV',
  transcript:        'Releve',
  recommendation:    'Recommandation',
  passport:          'Passeport',
  motivation_letter: 'Motivation',
  diploma:           'Diplome',
  language_cert:     'CertifLangue',
  financial_proof:   'JustifFinancement',
  other:             'Autre',
};

function buildDocFileName(studentName: string, docType: string, originalName: string | null): string {
  const ext      = originalName?.split('.').pop()?.toLowerCase() ?? 'pdf';
  const parts    = studentName.trim().split(/\s+/);
  const last     = (parts.pop() ?? '').toUpperCase().replace(/[^A-Z]/gi, '').toUpperCase();
  const first    = (parts[0] ?? '').replace(/[^a-zA-Z]/g, '');
  const typeSlug = DOC_TYPE_SHORT[docType] ?? docType.replace(/[^a-zA-Z0-9]/g, '').toUpperCase();
  const date     = new Date().toISOString().split('T')[0];
  return `${last}_${first}_${typeSlug}_${date}.${ext}`;
}

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
  const { role } = useRole();
  const canReviewDocs = can(role, 'documents:review');

  const [status,         setStatus]         = useState<RawStatus>(app.rawStatus);
  const [notes,          setNotes]          = useState(app.notes ?? '');
  const [correctionMsg,  setCorrectionMsg]  = useState('');
  const [rejectionReason, setRejectionReason] = useState('');
  const [manualSendNote, setManualSendNote] = useState('');
  const [manualSendWhere, setManualSendWhere] = useState('');
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
  const [toast,          setToast]          = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Documents
  const [docs,           setDocs]           = useState<ApplicationDocument[]>([]);
  const [docsLoading,    setDocsLoading]    = useState(false);
  const [rejectTarget,   setRejectTarget]   = useState<ApplicationDocument | null>(null);
  const [rejectReason,   setRejectReason]   = useState('');
  const [docActionId,    setDocActionId]    = useState<string | null>(null);

  // Commentaires internes (fil horodaté/multi-auteurs)
  const [comments,        setComments]        = useState<ApplicationComment[]>([]);
  const [commentsLoading, setCommentsLoading]  = useState(false);
  const [commentText,     setCommentText]      = useState('');
  const [commentSaving,   setCommentSaving]    = useState(false);

  useEffect(() => {
    setStatus(app.rawStatus);
    setNotes(app.notes ?? '');
    setCorrectionMsg('');
    setRejectionReason('');
    setManualSendNote('');
    setManualSendWhere('');
    setSaved(false);
    setSendError(null);
    setSendSuccess(false);
    setToast(null);
    setArchiveConfirm(false);
    setSendToEmail(app.contactEmail ?? '');
    setSendCc(app.ccEmails ?? '');
    fetchStatusHistory(app.id).then(setHistory).catch(() => setHistory([]));
    fetchEmailLogs(app.id).then(setEmailLogs).catch(() => setEmailLogs([]));
    setCommentText('');
    setCommentsLoading(true);
    fetchApplicationComments(app.id)
      .then(setComments)
      .catch(() => setComments([]))
      .finally(() => setCommentsLoading(false));
    if (app.studentId) {
      setDocsLoading(true);
      fetchApplicationDocuments(app.studentId)
        .then(setDocs)
        .finally(() => setDocsLoading(false));
    }
  }, [app]);

  async function handleApproveDoc(doc: ApplicationDocument) {
    setDocActionId(doc.id);
    try {
      const newName = buildDocFileName(app.student, doc.type, doc.file_name);
      await approveDocument(doc.id, newName);
      setDocs(prev => prev.map(d => d.id === doc.id
        ? { ...d, status: 'approved', rejection_reason: null, file_name: newName }
        : d
      ));
    } finally { setDocActionId(null); }
  }

  async function handleConfirmReject() {
    if (!rejectTarget || !rejectReason.trim()) return;
    setDocActionId(rejectTarget.id);
    try {
      await rejectDocument(rejectTarget.id, rejectReason.trim());
      setDocs(prev => prev.map(d => d.id === rejectTarget.id ? { ...d, status: 'rejected', rejection_reason: rejectReason.trim() } : d));
      setRejectTarget(null);
      setRejectReason('');
    } finally { setDocActionId(null); }
  }

  async function handleAddComment() {
    if (!commentText.trim()) return;
    setCommentSaving(true);
    try {
      const created = await addApplicationComment(app.id, commentText.trim());
      setComments(prev => [created, ...prev]);
      setCommentText('');
    } finally { setCommentSaving(false); }
  }

  async function handleDeleteComment(id: string) {
    await deleteApplicationComment(id);
    setComments(prev => prev.filter(c => c.id !== id));
  }

  async function handleSendEmail() {
    if (!sendToEmail.trim()) return;
    if (app.rawStatus !== 'verified' && app.rawStatus !== 'sent') {
      setSendError('Le dossier doit être au statut "Vérifiée" avant l\'envoi. Sauvegardez d\'abord.');
      return;
    }
    if (app.score < 70) {
      setSendError(`Score insuffisant (${app.score}%  minimum 70%). Demandez une correction à l'étudiant.`);
      return;
    }
    setSending(true);
    setSendError(null);
    setSendSuccess(false);
    try {
      const cc = sendCc.split(',').map(e => e.trim()).filter(Boolean);
      await sendApplicationEmail(app.id, sendToEmail.trim(), cc);
      setSendSuccess(true);
      onUpdate(app.id, { rawStatus: 'sent', status: 'Envoyée' });
      fetchEmailLogs(app.id).then(setEmailLogs).catch(() => {});
    } catch (err) {
      setSendError(err instanceof Error ? err.message : 'Erreur inconnue');
    } finally {
      setSending(false);
    }
  }

  function showToast(type: 'success' | 'error', message: string) {
    if (toastTimer.current) clearTimeout(toastTimer.current);
    setToast({ type, message });
    toastTimer.current = setTimeout(() => setToast(null), 4000);
  }

  const isManualSend = status === 'sent' && app.rawStatus !== 'sent';

  async function handleSave() {
    if (status === 'verified' && app.score < 70) {
      showToast('error', `Validation impossible : score ${app.score}% insuffisant (minimum 70%). Demandez une correction.`);
      return;
    }
    if (status === 'rejected' && !rejectionReason.trim()) {
      showToast('error', 'Veuillez indiquer la raison du refus avant de sauvegarder.');
      return;
    }
    if (isManualSend && !manualSendNote.trim()) {
      showToast('error', "Précisez comment ce dossier a été transmis à l'université avant de marquer \"Envoyée\".");
      return;
    }
    setSaving(true);
    try {
      const ops: Promise<void>[] = [];
      let correctionToSend: string | null = null;

      if (status !== app.rawStatus) {
        const note = status === 'needsfix' && correctionMsg.trim()
          ? correctionMsg.trim()
          : status === 'rejected' && rejectionReason.trim()
            ? rejectionReason.trim()
            : undefined;
        ops.push(updateApplicationStatus(app.id, status, note));
        if (status === 'needsfix' && correctionMsg.trim()) {
          correctionToSend = correctionMsg.trim();
        }
        if (status === 'rejected' && rejectionReason.trim()) {
          correctionToSend = `Votre candidature a été refusée. Motif : ${rejectionReason.trim()}`;
        }
        if (isManualSend) {
          ops.push(logManualSend(app.id, manualSendWhere.trim(), manualSendNote.trim()));
        }
      }
      if (notes !== (app.notes ?? '')) ops.push(updateApplicationNotes(app.id, notes));

      await Promise.all(ops);

      // Envoi message de correction : non bloquant — échec silencieux
      if (correctionToSend && app.studentId) {
        sendCorrectionMessage(app.studentId, correctionToSend).catch(console.error);
      }

      onUpdate(app.id, {
        rawStatus: status,
        status:    STATUS_MAP_UI[status],
        notes:     notes || undefined,
      });
      setSaved(true);
      setCorrectionMsg('');
      setRejectionReason('');
      setManualSendNote('');
      setManualSendWhere('');
      if (isManualSend) fetchEmailLogs(app.id).then(setEmailLogs).catch(() => {});
      setArchiveConfirm(false);
      setTimeout(() => setSaved(false), 3000);
      showToast('success',
        status !== app.rawStatus
          ? `Statut mis à jour : ${RAW_STATUS_LABELS[status]}. Modifications enregistrées.`
          : 'Notes enregistrées avec succès.'
      );
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : (typeof e === 'object' && e !== null && 'message' in e ? String((e as any).message) : String(e));
      showToast('error', msg || 'Une erreur est survenue. Veuillez réessayer.');
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
      const blob = await pdf(<ApplicationPDF app={app} history={history} docs={docs} />).toBlob();
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
  const canVerify = app.score >= 70;

  // Conformité : requis du programme vs docs soumis
  const requirements   = app.programRequirements ?? [];
  const conformity     = requirements.length > 0 ? computeConformity(requirements, docs) : [];
  const missingReqs    = conformity.filter(c => c.docStatus === 'missing');
  const docsAllPresent = requirements.length === 0 || missingReqs.length === 0;
  const canVerifyFull  = canVerify && docsAllPresent;

  const isDirty = status !== app.rawStatus || notes !== (app.notes ?? '') || (status === 'needsfix' && correctionMsg.trim() !== '') || (status === 'rejected' && rejectionReason.trim() !== '');

  return (
    <>
      <style>{`
        @keyframes adm-spin { to { transform: rotate(360deg); } }
        @keyframes adm-toast-in { from { opacity: 0; transform: translateY(-16px) scale(.96); } to { opacity: 1; transform: translateY(0) scale(1); } }
        .adm-spin { animation: adm-spin .7s linear infinite; transform-origin: center; }
        .adm-toast { animation: adm-toast-in .22s ease both; }
      `}</style>
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
          position: 'relative',
        }}
      >
        {/* Toast notification */}
        {toast && (
          <div className="adm-toast" style={{
            position: 'sticky', top: 12, zIndex: 10,
            margin: '12px 16px 0',
            padding: '12px 16px',
            borderRadius: 10,
            display: 'flex', alignItems: 'flex-start', gap: 10,
            background: toast.type === 'success' ? '#f0fdf4' : '#fef2f2',
            border: `1.5px solid ${toast.type === 'success' ? '#bbf7d0' : '#fecaca'}`,
            boxShadow: '0 4px 16px rgba(0,0,0,0.08)',
          }}>
            {toast.type === 'success' ? (
              <svg width={18} height={18} viewBox="0 0 24 24" fill="none" stroke="#16a34a" strokeWidth={2.5} strokeLinecap="round" style={{ flexShrink: 0, marginTop: 1 }}><circle cx="12" cy="12" r="10"/><polyline points="9 12 11 14 15 10"/></svg>
            ) : (
              <svg width={18} height={18} viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth={2.5} strokeLinecap="round" style={{ flexShrink: 0, marginTop: 1 }}><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            )}
            <span style={{
              flex: 1, fontSize: 13, fontWeight: 500, lineHeight: 1.5,
              color: toast.type === 'success' ? '#15803d' : '#dc2626',
            }}>
              {toast.message}
            </span>
            <button
              onClick={() => setToast(null)}
              style={{ background: 'none', border: 'none', cursor: 'pointer', padding: '0 2px', color: toast.type === 'success' ? '#86efac' : '#fca5a5', lineHeight: 1, fontSize: 16 }}
            >
              &#x2715;
            </button>
          </div>
        )}
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

          {/* Documents soumis — validation B5 CDC */}
          <Section label="Documents soumis">
            {docsLoading ? (
              <div style={{ fontSize: 13, color: colors.textMuted }}>Chargement…</div>
            ) : docs.length === 0 ? (
              <div style={{ fontSize: 13, color: colors.textMuted, fontStyle: 'italic' }}>Aucun document soumis.</div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {docs.map(doc => {
                  const isApproved = doc.status === 'approved';
                  const isRejected = doc.status === 'rejected';
                  const isActing   = docActionId === doc.id;
                  const isRejecting = rejectTarget?.id === doc.id;
                  const sizeMb = doc.size_bytes ? (doc.size_bytes / 1_048_576).toFixed(1) + ' Mo' : null;
                  return (
                    <div key={doc.id} style={{
                      border: `1.5px solid ${isApproved ? '#bbf7d0' : isRejected ? '#fecaca' : colors.border}`,
                      borderRadius: 10, padding: '10px 14px',
                      background: isApproved ? '#f0fdf4' : isRejected ? '#fef2f2' : colors.inputBg,
                    }}>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10, flexWrap: 'wrap' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10, minWidth: 0 }}>
                          {/* Icône statut */}
                          <div style={{
                            width: 28, height: 28, borderRadius: 7, flexShrink: 0,
                            background: isApproved ? '#dcfce7' : isRejected ? '#fee2e2' : '#e5e7eb',
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                          }}>
                            {isApproved
                              ? <svg width={13} height={13} viewBox="0 0 24 24" fill="none" stroke="#16a34a" strokeWidth={3} strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                              : isRejected
                              ? <svg width={13} height={13} viewBox="0 0 24 24" fill="none" stroke="#dc2626" strokeWidth={3} strokeLinecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                              : <svg width={13} height={13} viewBox="0 0 24 24" fill="none" stroke="#6b7280" strokeWidth={2} strokeLinecap="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                            }
                          </div>
                          <div style={{ minWidth: 0 }}>
                            <div style={{ fontSize: 13, fontWeight: 700, color: colors.navy, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                              {docTypeLabel(doc.type)}
                            </div>
                            <div style={{ fontSize: 11, color: colors.textMuted, marginTop: 1 }}>
                              {doc.file_name ?? 'Sans nom'}{sizeMb ? ` · ${sizeMb}` : ''}
                            </div>
                          </div>
                        </div>

                        {/* Actions */}
                        <div style={{ display: 'flex', gap: 6, flexShrink: 0, alignItems: 'center' }}>
                          {doc.file_url && (
                            <a
                              href={doc.file_url} target="_blank" rel="noreferrer"
                              style={{
                                height: 28, padding: '0 10px', borderRadius: 7,
                                border: `1px solid ${colors.border}`, background: 'white',
                                fontSize: 11.5, fontWeight: 600, color: colors.blue,
                                display: 'flex', alignItems: 'center', gap: 4, textDecoration: 'none',
                              }}
                            >
                              <svg width={11} height={11} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
                              Voir
                            </a>
                          )}
                          {!isApproved && canReviewDocs && (
                            <button
                              onClick={() => handleApproveDoc(doc)}
                              disabled={isActing}
                              style={{
                                height: 28, padding: '0 10px', borderRadius: 7,
                                border: 'none', background: '#16a34a',
                                fontSize: 11.5, fontWeight: 700, color: 'white',
                                cursor: 'pointer', opacity: isActing ? 0.6 : 1,
                              }}
                            >
                              Approuver
                            </button>
                          )}
                          {!isRejected && !isRejecting && canReviewDocs && (
                            <button
                              onClick={() => { setRejectTarget(doc); setRejectReason(''); }}
                              disabled={isActing}
                              style={{
                                height: 28, padding: '0 10px', borderRadius: 7,
                                border: '1.5px solid #dc2626', background: 'white',
                                fontSize: 11.5, fontWeight: 700, color: '#dc2626',
                                cursor: 'pointer', opacity: isActing ? 0.6 : 1,
                              }}
                            >
                              Rejeter
                            </button>
                          )}
                          {isRejecting && (
                            <button
                              onClick={() => { setRejectTarget(null); setRejectReason(''); }}
                              style={{
                                height: 28, padding: '0 10px', borderRadius: 7,
                                border: `1px solid ${colors.border}`, background: 'white',
                                fontSize: 11.5, color: colors.textSecondary, cursor: 'pointer',
                              }}
                            >
                              Annuler
                            </button>
                          )}
                        </div>
                      </div>

                      {/* Raison du rejet existante */}
                      {isRejected && doc.rejection_reason && !isRejecting && (
                        <div style={{ fontSize: 11.5, color: '#dc2626', marginTop: 6, paddingLeft: 38, fontStyle: 'italic' }}>
                          Raison : {doc.rejection_reason}
                        </div>
                      )}

                      {/* Inline reject form */}
                      {isRejecting && (
                        <div style={{ marginTop: 8, display: 'flex', gap: 6 }}>
                          <input
                            autoFocus
                            value={rejectReason}
                            onChange={e => setRejectReason(e.target.value)}
                            placeholder="Raison du rejet (ex: image floue, mauvais format…)"
                            style={{
                              flex: 1, height: 32, padding: '0 10px', borderRadius: 7,
                              border: `1.5px solid #dc2626`, background: 'white',
                              fontSize: 12.5, fontFamily: fonts.body, outline: 'none',
                            }}
                          />
                          <button
                            onClick={handleConfirmReject}
                            disabled={!rejectReason.trim() || isActing}
                            style={{
                              height: 32, padding: '0 12px', borderRadius: 7,
                              border: 'none', background: rejectReason.trim() ? '#dc2626' : colors.border,
                              fontSize: 12, fontWeight: 700, color: 'white', cursor: rejectReason.trim() ? 'pointer' : 'default',
                            }}
                          >
                            Confirmer
                          </button>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </Section>

          {/* Conformité dossier */}
          {requirements.length > 0 && (
            <Section label="Conformité dossier">
              {docsLoading ? (
                <div style={{ fontSize: 13, color: colors.textMuted }}>Vérification en cours…</div>
              ) : (
                <ConformitySection
                  conformity={conformity}
                  missingCount={missingReqs.length}
                  total={requirements.length}
                />
              )}
            </Section>
          )}

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
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {!canVerify && (
                <div style={{ fontSize: 12.5, color: colors.danger, padding: '7px 12px', background: '#fef2f2', borderRadius: 7 }}>
                  Validation impossible : score {app.score}% insuffisant (minimum 70%). Demandez une correction à l'étudiant.
                </div>
              )}
              <div style={{ display: 'flex', gap: 8 }}>
              <button
                onClick={() => canVerify && setStatus('verified')}
                disabled={!canVerify}
                style={{
                  flex: 1, padding: '10px 16px', borderRadius: 10, border: 'none',
                  background: !canVerify
                    ? colors.border
                    : canVerifyFull
                      ? `linear-gradient(135deg, ${colors.success} 0%, #15803d 100%)`
                      : `linear-gradient(135deg, #f59e0b 0%, #d97706 100%)`,
                  color: canVerify ? 'white' : colors.textMuted,
                  fontWeight: 700, fontSize: 13.5,
                  cursor: canVerify ? 'pointer' : 'not-allowed',
                  fontFamily: fonts.body, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 7,
                }}
              >
                <svg width={15} height={15} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                {canVerifyFull ? 'Valider le dossier' : 'Valider quand même'}
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
            </div>
          )}

          {/* Changer le statut */}
          <Section label="Statut">
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {AVAILABLE_STATUSES.map(s => {
                const c = STATUS_COLORS[s];
                const active = s === status;
                const blocked = s === 'verified' && !canVerify;
                return (
                  <button
                    key={s}
                    onClick={() => !blocked && setStatus(s)}
                    disabled={blocked}
                    title={blocked ? `Score ${app.score}% insuffisant  minimum 70% requis` : undefined}
                    style={{
                      padding: '6px 14px', borderRadius: 20, fontSize: 12.5,
                      fontWeight: 700, fontFamily: fonts.body,
                      border: `2px solid ${active ? c.color : 'transparent'}`,
                      background: active ? c.bg : colors.inputBg,
                      color: active ? c.color : colors.textSecondary,
                      transition: 'all .15s',
                      cursor: blocked ? 'not-allowed' : 'pointer',
                      opacity: blocked ? 0.4 : 1,
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
                placeholder="Expliquez à l'étudiant ce qui doit être corrigé ou complété"
                style={{
                  width: '100%', padding: '10px 14px', borderRadius: 10,
                  border: `1.5px solid #f59e0b`,
                  background: '#fffbeb', fontFamily: fonts.body,
                  fontSize: 13.5, color: colors.textPrimary,
                  resize: 'vertical', outline: 'none', boxSizing: 'border-box',
                }}
              />
              <div style={{ fontSize: 11.5, color: '#d97706', marginTop: 4, display: 'flex', alignItems: 'center', gap: 5 }}>
                <svg width={11} height={11} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
                Ce message sera envoyé à l'étudiant via la messagerie et visible dans son suivi.
              </div>
            </Section>
          )}

          {/* Raison du refus (obligatoire si statut = rejected) */}
          {status === 'rejected' && (
            <Section label="Raison du refus *">
              <textarea
                value={rejectionReason}
                onChange={e => setRejectionReason(e.target.value)}
                rows={3}
                placeholder="Expliquez à l'étudiant pourquoi sa candidature a été refusée..."
                style={{
                  width: '100%', padding: '10px 14px', borderRadius: 10,
                  border: `1.5px solid #dc2626`,
                  background: '#fef2f2', fontFamily: fonts.body,
                  fontSize: 13.5, color: colors.textPrimary,
                  resize: 'vertical', outline: 'none', boxSizing: 'border-box',
                }}
              />
              <div style={{ fontSize: 11.5, color: '#dc2626', marginTop: 4, display: 'flex', alignItems: 'center', gap: 5 }}>
                <svg width={11} height={11} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
                Ce message sera envoyé à l'étudiant via la messagerie. Ce champ est obligatoire.
              </div>
            </Section>
          )}

          {/* Dépôt manuel (statut "Envoyée" choisi sans passer par l'envoi email) */}
          {isManualSend && (
            <Section label="Dépôt manuel — hors envoi email *">
              <input
                type="text"
                value={manualSendWhere}
                onChange={e => setManualSendWhere(e.target.value)}
                placeholder="Où ? (ex : portail d'admission de l'université, dépôt en personne...)"
                style={{
                  width: '100%', padding: '10px 14px', borderRadius: 10,
                  border: `1.5px solid #7c3aed`, background: '#f5f3ff',
                  fontFamily: fonts.body, fontSize: 13.5, color: colors.textPrimary,
                  outline: 'none', boxSizing: 'border-box', marginBottom: 8,
                }}
              />
              <textarea
                value={manualSendNote}
                onChange={e => setManualSendNote(e.target.value)}
                rows={2}
                placeholder="Précisez comment ce dossier a été transmis à l'université"
                style={{
                  width: '100%', padding: '10px 14px', borderRadius: 10,
                  border: `1.5px solid #7c3aed`, background: '#f5f3ff',
                  fontFamily: fonts.body, fontSize: 13.5, color: colors.textPrimary,
                  resize: 'vertical', outline: 'none', boxSizing: 'border-box',
                }}
              />
              <div style={{ fontSize: 11.5, color: '#7c3aed', marginTop: 4, display: 'flex', alignItems: 'center', gap: 5 }}>
                <svg width={11} height={11} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>
                Ce statut n'est pas passé par l'envoi email automatique — cette précision apparaîtra dans l'historique, marquée "Manuel", pour que l'équipe ne la confonde pas avec un vrai envoi tracé.
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
                  const dotColor = STATUS_COLORS[entry.toStatus as RawStatus]?.color ?? colors.blue;
                  const noteColor = entry.toStatus === 'rejected'
                    ? '#dc2626'
                    : entry.toStatus === 'needsfix'
                      ? '#d97706'
                      : colors.textSecondary;
                  return (
                    <div key={entry.id} style={{ display: 'flex', gap: 12 }}>
                      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', flexShrink: 0 }}>
                        <div style={{
                          width: 10, height: 10, borderRadius: '50%',
                          background: dotColor, marginTop: 3, flexShrink: 0,
                        }} />
                        {!isLast && <div style={{ width: 2, flex: 1, background: colors.border, minHeight: 24 }} />}
                      </div>
                      <div style={{ paddingBottom: isLast ? 0 : 12, minWidth: 0 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
                          {entry.fromStatus && (
                            <>
                              <span style={{ fontSize: 12, color: colors.textMuted }}>{RAW_STATUS_LABELS[entry.fromStatus as RawStatus] ?? entry.fromStatus}</span>
                              <span style={{ fontSize: 11, color: colors.textMuted }}></span>
                            </>
                          )}
                          <span style={{ fontSize: 13, fontWeight: 700, color: colors.navy }}>
                            {RAW_STATUS_LABELS[entry.toStatus as RawStatus] ?? entry.toStatus}
                          </span>
                          {date && <span style={{ fontSize: 11, color: colors.textMuted, marginLeft: 4 }}>{date}</span>}
                        </div>
                        {entry.note && (
                          <div style={{ fontSize: 12, color: noteColor, fontStyle: 'italic', marginTop: 2 }}>
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
                    Email envoyé avec succès  statut mis à jour à "Envoyée".
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
                  {sending ? 'Envoi en cours' : sendSuccess ? 'Envoyé' : 'Envoyer à l\'université'}
                </button>
              </div>
            </Section>
          )}

          {/* Logs d'envoi email */}
          {emailLogs.length > 0 && (
            <Section label="Historique des envois">
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                {emailLogs.map(log => {
                  const isManual = log.provider === 'manual';
                  return (
                  <div key={log.id} style={{
                    padding: '9px 12px', borderRadius: 8,
                    background: isManual ? '#f5f3ff' : log.status === 'sent' ? '#f0fdf4' : '#fef2f2',
                    border: `1px solid ${isManual ? '#ddd6fe' : log.status === 'sent' ? '#bbf7d0' : '#fecaca'}`,
                    fontSize: 12.5,
                  }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                        <span style={{ fontWeight: 700, color: isManual ? '#7c3aed' : log.status === 'sent' ? colors.success : colors.danger }}>
                          {isManual ? 'Dépôt manuel' : log.status === 'sent' ? 'Envoyé' : log.status === 'failed' ? 'Échec' : 'Bounce'}
                        </span>
                        {!isManual && (
                          <span style={{ fontSize: 10, fontWeight: 700, padding: '1px 7px', borderRadius: 10, background: '#eff6ff', color: colors.blue }}>
                            EMAIL AUTOMATIQUE
                          </span>
                        )}
                      </span>
                      <span style={{ fontSize: 11, color: colors.textMuted }}>
                        {new Date(log.sentAt).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>
                    <div style={{ color: colors.textSecondary, marginTop: 2 }}> {log.toEmail}</div>
                    {isManual && log.subject && <div style={{ color: '#7c3aed', fontSize: 11.5, marginTop: 2 }}>{log.subject}</div>}
                    {!isManual && log.retryCount > 0 && (
                      <div style={{ color: colors.textMuted, fontSize: 11, marginTop: 2 }}>
                        {log.retryCount} nouvelle{log.retryCount > 1 ? 's' : ''} tentative{log.retryCount > 1 ? 's' : ''} avant {log.status === 'sent' ? 'succès' : "l'échec final"}
                      </div>
                    )}
                    {log.errorMessage && <div style={{ color: colors.danger, fontSize: 11.5, marginTop: 2 }}>{log.errorMessage}</div>}
                  </div>
                  );
                })}
              </div>
            </Section>
          )}

          {/* Lettre de motivation (rédigée par l'étudiant pour ce programme) */}
          {app.motivationLetter && (
            <Section label="Lettre de motivation">
              <div style={{
                padding: '10px 14px', borderRadius: radius.md,
                border: `1.5px solid ${colors.border}`,
                background: colors.inputBg, fontFamily: fonts.body,
                fontSize: 13.5, color: colors.textPrimary,
                lineHeight: 1.6, whiteSpace: 'pre-wrap',
              }}>
                {app.motivationLetter}
              </div>
            </Section>
          )}

          {/* Notes internes */}
          <Section label="Notes internes (équipe)">
            <textarea
              value={notes}
              onChange={e => setNotes(e.target.value)}
              rows={3}
              placeholder="Ajouter une note interne visible uniquement par l'équipe"
              style={{
                width: '100%', padding: '10px 14px', borderRadius: radius.md,
                border: `1.5px solid ${colors.borderInput}`,
                background: colors.inputBg, fontFamily: fonts.body,
                fontSize: 13.5, color: colors.textPrimary,
                resize: 'vertical', outline: 'none', boxSizing: 'border-box',
              }}
            />
          </Section>

          {/* Commentaires internes — fil horodaté/multi-auteurs */}
          <Section label="Commentaires internes (équipe)">
            <div style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
              <textarea
                value={commentText}
                onChange={e => setCommentText(e.target.value)}
                rows={2}
                placeholder="Ajouter un commentaire visible par toute l'équipe"
                style={{
                  flex: 1, padding: '10px 14px', borderRadius: radius.md,
                  border: `1.5px solid ${colors.borderInput}`,
                  background: colors.inputBg, fontFamily: fonts.body,
                  fontSize: 13.5, color: colors.textPrimary,
                  resize: 'vertical', outline: 'none', boxSizing: 'border-box',
                }}
              />
              <button
                onClick={handleAddComment}
                disabled={!commentText.trim() || commentSaving}
                style={{
                  alignSelf: 'flex-end', height: 34, padding: '0 14px', borderRadius: 7,
                  border: 'none', background: colors.blue, color: 'white',
                  fontSize: 12.5, fontWeight: 700,
                  cursor: !commentText.trim() || commentSaving ? 'not-allowed' : 'pointer',
                  opacity: !commentText.trim() || commentSaving ? 0.6 : 1,
                }}
              >
                {commentSaving ? '...' : 'Ajouter'}
              </button>
            </div>

            {commentsLoading ? (
              <div style={{ fontSize: 12.5, color: colors.textMuted }}>Chargement…</div>
            ) : comments.length === 0 ? (
              <div style={{ fontSize: 12.5, color: colors.textMuted }}>Aucun commentaire pour cette candidature.</div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {comments.map(c => (
                  <div key={c.id} style={{
                    padding: '10px 12px', borderRadius: radius.md,
                    border: `1px solid ${colors.border}`, background: colors.cardBg,
                  }}>
                    <div style={{ fontSize: 13, color: colors.textPrimary, whiteSpace: 'pre-wrap' }}>{c.content}</div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 6 }}>
                      <span style={{ fontSize: 11, color: colors.textMuted }}>
                        {c.author_email ?? 'Équipe'} · {new Date(c.created_at).toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
                      </span>
                      <button
                        onClick={() => handleDeleteComment(c.id)}
                        style={{ background: 'none', border: 'none', color: '#dc2626', fontSize: 11, fontWeight: 600, cursor: 'pointer' }}
                      >
                        Supprimer
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
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
                {saving ? 'Archivage' : 'Confirmer l\'archivage'}
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
                  {generatingPdf ? 'Génération' : 'PDF'}
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
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 8 }}>
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
                    <svg className="adm-spin" width={14} height={14} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round">
                      <path d="M21 12a9 9 0 1 1-6.219-8.56"/>
                    </svg>
                  ) : saved ? (
                    <svg width={14} height={14} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                  ) : null}
                  {saved ? 'Enregistré' : saving ? 'Enregistrement' : 'Enregistrer'}
                </button>
              </div>
            </div>
            </div>
          )}
        </div>
      </div>
    </div>
    </>
  );
}

/*  Helpers  */

function normalizeStr(s: string) {
  return s.toLowerCase()
    .replace(/[éèêë]/g, 'e').replace(/[àâ]/g, 'a')
    .replace(/[îï]/g, 'i').replace(/[ôö]/g, 'o')
    .replace(/[ûùü]/g, 'u').replace(/ç/g, 'c');
}

const DOC_TYPE_KEYWORDS: Record<string, string[]> = {
  'curriculum vitae':             ['cv', 'curriculum'],
  'releve de notes':              ['releve', 'notes', 'bulletin', 'transcript'],
  'lettre de recommandation':     ['recommandation'],
  'passeport / piece d\'identite':['passeport', 'passport', 'identite'],
  'lettre de motivation':         ['motivation'],
  'diplome':                      ['diplome', 'licence', 'master', 'bac', 'bachelor'],
  'attestation de langue':        ['attestation', 'langue', 'b1', 'b2', 'c1', 'c2', 'toefl', 'ielts', 'delf', 'dalf', 'tcf'],
  'justificatif de financement':  ['financement', 'bourse', 'bancaire', 'ressources'],
};

function matchesReq(docType: string, req: string): boolean {
  const label = normalizeStr(docTypeLabel(docType));
  const r     = normalizeStr(req);
  if (r.includes(label) || label.includes(r)) return true;
  const keywords = DOC_TYPE_KEYWORDS[label];
  if (keywords) return keywords.some(kw => r.includes(kw));
  return false;
}

type ReqStatus = 'ok' | 'pending' | 'missing';
interface ReqResult { req: string; docStatus: ReqStatus; doc: ApplicationDocument | null }

function computeConformity(requirements: string[], docs: ApplicationDocument[]): ReqResult[] {
  return requirements.map(req => {
    const matched  = docs.filter(d => matchesReq(d.type, req) && d.status !== 'rejected');
    const approved = matched.filter(d => d.status === 'approved');
    const docStatus: ReqStatus = matched.length === 0 ? 'missing' : approved.length > 0 ? 'ok' : 'pending';
    return { req, docStatus, doc: matched[0] ?? null };
  });
}

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

function ConformitySection({ conformity, missingCount, total }: {
  conformity:   ReqResult[];
  missingCount: number;
  total:        number;
}) {
  const covered      = total - missingCount;
  const allOk        = missingCount === 0;
  const summaryColor = allOk ? colors.success : missingCount < total ? colors.warning : colors.danger;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
        <span style={{ fontSize: 12, color: colors.textMuted }}>{covered}/{total} documents couverts</span>
        <span style={{
          fontSize: 12, fontWeight: 700, padding: '2px 10px', borderRadius: 20,
          color: summaryColor, background: `${summaryColor}18`,
        }}>
          {allOk ? 'Conforme' : missingCount === total ? 'Non conforme' : 'Partiel'}
        </span>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 0, borderRadius: 10, overflow: 'hidden', border: `1.5px solid ${colors.border}` }}>
        {conformity.map((item, i) => {
          const isLast  = i === conformity.length - 1;
          const iconColor = item.docStatus === 'ok'      ? colors.success
                          : item.docStatus === 'pending' ? colors.warning
                          : colors.danger;
          const rowBg     = item.docStatus === 'ok'      ? '#f0fdf4'
                          : item.docStatus === 'pending' ? '#fffbeb'
                          : '#fef2f2';
          const label     = item.docStatus === 'ok'      ? 'OK'
                          : item.docStatus === 'pending' ? 'En attente'
                          : 'Manquant';
          return (
            <div key={item.req} style={{
              display: 'flex', alignItems: 'center', gap: 10, padding: '9px 13px',
              background: rowBg,
              borderBottom: isLast ? 'none' : `1px solid ${colors.border}`,
            }}>
              <div style={{
                width: 22, height: 22, borderRadius: '50%', flexShrink: 0,
                background: `${iconColor}18`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {item.docStatus === 'ok' ? (
                  <svg width={11} height={11} viewBox="0 0 24 24" fill="none" stroke={colors.success} strokeWidth={3} strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                ) : item.docStatus === 'pending' ? (
                  <svg width={11} height={11} viewBox="0 0 24 24" fill="none" stroke={colors.warning} strokeWidth={2.5} strokeLinecap="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                ) : (
                  <svg width={11} height={11} viewBox="0 0 24 24" fill="none" stroke={colors.danger} strokeWidth={3} strokeLinecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                )}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, fontWeight: 600, color: colors.navy }}>{item.req}</div>
                {item.doc && (
                  <div style={{ fontSize: 11, color: colors.textMuted, marginTop: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {item.doc.file_name ?? docTypeLabel(item.doc.type)}
                  </div>
                )}
              </div>
              <span style={{
                fontSize: 10.5, fontWeight: 700, padding: '2px 8px', borderRadius: 20, flexShrink: 0,
                color: iconColor, background: `${iconColor}15`,
              }}>
                {label}
              </span>
            </div>
          );
        })}
      </div>
      {missingCount > 0 && (
        <div style={{
          marginTop: 8, padding: '7px 11px', borderRadius: 8,
          background: '#fff7ed', border: '1px solid #fed7aa', fontSize: 12.5, color: '#c2410c',
          display: 'flex', alignItems: 'center', gap: 6,
        }}>
          <svg width={13} height={13} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
          {missingCount} document{missingCount > 1 ? 's' : ''} requis manquant{missingCount > 1 ? 's' : ''}. Le bouton "Valider" passera en orange.
        </div>
      )}
    </div>
  );
}

function ChecklistSection({ app }: { app: Application }) {
  const items = [
    { label: 'Candidature soumise',   ok: app.rawStatus !== 'draft' },
    { label: 'Programme sélectionné', ok: app.program !== '' && app.program !== '' },
    { label: 'Université renseignée', ok: app.university !== '' && app.university !== '' },
    { label: 'Pays de destination',   ok: app.country !== '' && app.country !== '' },
    { label: "Niveau d'études",       ok: !!app.level },
    { label: 'Score profil  70%',    ok: app.score >= 70, extra: `${app.score}%` },
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
