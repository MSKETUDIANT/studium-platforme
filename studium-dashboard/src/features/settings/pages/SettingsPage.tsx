import React, { useState, useEffect } from 'react';
import { PageHeader } from '../../../shared/components/PageHeader';
import { colors, fonts, radius } from '../../../shared/constants/theme';
import {
  fetchEmailTemplates, upsertEmailTemplate, deleteEmailTemplate,
  TEMPLATE_VARIABLES, SCOPE_LABELS,
} from '../services/email_templates_service';
import type { EmailTemplate } from '../services/email_templates_service';

const DEFAULT_SUBJECT = '[Studium] Candidature – {{student_name}} – {{program_name}}';
const DEFAULT_BODY =
`Madame, Monsieur,

Nous vous transmettons la candidature de {{student_name}} pour le programme {{program_name}} à {{university_name}}{{country}}.

Vous trouverez en pièce jointe le dossier complet du candidat (CV, relevés de notes, lettre de motivation et documents requis).

Nous restons disponibles pour tout complément d'information.

Cordialement,
L'équipe Studium Admissions`;

const SCOPES = ['application_email', 'followup_email', 'correction_email'];
const LANGUAGES = [{ value: 'fr', label: 'Français' }, { value: 'en', label: 'English' }];

const EMPTY_FORM = {
  id:              undefined as string | undefined,
  scope:           'application_email',
  language:        'fr',
  programId:       null as string | null,
  subjectTemplate: DEFAULT_SUBJECT,
  bodyTemplate:    DEFAULT_BODY,
};

export default function SettingsPage() {
  const [templates, setTemplates] = useState<EmailTemplate[]>([]);
  const [loading,   setLoading]   = useState(true);
  const [form,      setForm]      = useState({ ...EMPTY_FORM });
  const [saving,    setSaving]    = useState(false);
  const [saved,     setSaved]     = useState(false);
  const [error,     setError]     = useState<string | null>(null);
  const [deleting,  setDeleting]  = useState<string | null>(null);

  useEffect(() => {
    fetchEmailTemplates()
      .then(setTemplates)
      .catch(() => setTemplates([]))
      .finally(() => setLoading(false));
  }, []);

  function handleEdit(t: EmailTemplate) {
    setForm({
      id:              t.id,
      scope:           t.scope,
      language:        t.language,
      programId:       t.programId,
      subjectTemplate: t.subjectTemplate,
      bodyTemplate:    t.bodyTemplate,
    });
    setSaved(false);
    setError(null);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function handleNew() {
    setForm({ ...EMPTY_FORM, id: undefined });
    setSaved(false);
    setError(null);
  }

  function insertVariable(variable: string) {
    setForm(f => ({ ...f, bodyTemplate: f.bodyTemplate + variable }));
  }

  async function handleSave() {
    if (!form.subjectTemplate.trim() || !form.bodyTemplate.trim()) return;
    setSaving(true);
    setError(null);
    try {
      await upsertEmailTemplate(form);
      const updated = await fetchEmailTemplates();
      setTemplates(updated);
      setSaved(true);
      setTimeout(() => setSaved(false), 2500);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Erreur lors de la sauvegarde');
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete(id: string) {
    setDeleting(id);
    try {
      await deleteEmailTemplate(id);
      setTemplates(t => t.filter(x => x.id !== id));
      if (form.id === id) handleNew();
    } finally {
      setDeleting(null);
    }
  }

  const isDirty = !!form.subjectTemplate.trim() && !!form.bodyTemplate.trim();

  return (
    <div style={{ minHeight: '100vh', background: '#f4f7fb', fontFamily: fonts.body }}>
      <PageHeader
        title="Paramètres"
        subtitle="Templates email et configuration de la plateforme"
      />

      <div style={{ maxWidth: 1100, margin: '0 auto', padding: '32px 24px', display: 'flex', gap: 24, alignItems: 'flex-start' }}>

        {/* Éditeur */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 20 }}>
          <div style={{
            background: 'white', borderRadius: 14, padding: 28,
            boxShadow: '0 2px 12px rgba(0,0,0,.06)',
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 22 }}>
              <div>
                <div style={{ fontSize: 16, fontWeight: 800, color: colors.navy }}>
                  {form.id ? 'Modifier le template' : 'Nouveau template'}
                </div>
                <div style={{ fontSize: 12.5, color: colors.textMuted, marginTop: 3 }}>
                  Utilisez les variables <code style={{ background: '#f0f4ff', padding: '1px 6px', borderRadius: 4, fontSize: 11 }}>{'{{variable}}'}</code> dans le sujet et le corps.
                </div>
              </div>
              {form.id && (
                <button onClick={handleNew} style={{
                  padding: '7px 14px', borderRadius: radius.md, border: `1.5px solid ${colors.borderInput}`,
                  background: 'white', color: colors.textSecondary, fontSize: 13, fontWeight: 600,
                  cursor: 'pointer', fontFamily: fonts.body,
                }}>
                  + Nouveau
                </button>
              )}
            </div>

            {/* Scope + Langue */}
            <div style={{ display: 'flex', gap: 12, marginBottom: 16 }}>
              <div style={{ flex: 1 }}>
                <Label>Type de template</Label>
                <select
                  value={form.scope}
                  onChange={e => setForm(f => ({ ...f, scope: e.target.value }))}
                  style={selectStyle}
                >
                  {SCOPES.map(s => (
                    <option key={s} value={s}>{SCOPE_LABELS[s] ?? s}</option>
                  ))}
                </select>
              </div>
              <div style={{ width: 140 }}>
                <Label>Langue</Label>
                <select
                  value={form.language}
                  onChange={e => setForm(f => ({ ...f, language: e.target.value }))}
                  style={selectStyle}
                >
                  {LANGUAGES.map(l => (
                    <option key={l.value} value={l.value}>{l.label}</option>
                  ))}
                </select>
              </div>
            </div>

            {/* Sujet */}
            <div style={{ marginBottom: 16 }}>
              <Label>Sujet de l'email</Label>
              <input
                type="text"
                value={form.subjectTemplate}
                onChange={e => setForm(f => ({ ...f, subjectTemplate: e.target.value }))}
                style={{
                  ...inputStyle,
                  fontWeight: 600,
                }}
                placeholder="[Studium] Candidature – {{student_name}} – {{program_name}}"
              />
            </div>

            {/* Corps */}
            <div style={{ marginBottom: 8 }}>
              <Label>Corps de l'email</Label>
              <textarea
                value={form.bodyTemplate}
                onChange={e => setForm(f => ({ ...f, bodyTemplate: e.target.value }))}
                rows={12}
                style={{ ...inputStyle, resize: 'vertical', lineHeight: 1.6 }}
                placeholder="Contenu de l'email…"
              />
            </div>

            {/* Variables rapides */}
            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 20 }}>
              <span style={{ fontSize: 11.5, color: colors.textMuted, alignSelf: 'center', marginRight: 4 }}>Insérer :</span>
              {TEMPLATE_VARIABLES.map(v => (
                <button
                  key={v.key}
                  onClick={() => insertVariable(v.key)}
                  style={{
                    padding: '3px 10px', borderRadius: 20, fontSize: 11.5, fontWeight: 600,
                    background: '#eff6ff', color: colors.blue, border: 'none', cursor: 'pointer',
                    fontFamily: fonts.body,
                  }}
                >
                  {v.key}
                </button>
              ))}
            </div>

            {error && (
              <div style={{ fontSize: 12.5, color: colors.danger, marginBottom: 12, padding: '8px 12px', background: '#fef2f2', borderRadius: 7 }}>
                {error}
              </div>
            )}

            <button
              onClick={handleSave}
              disabled={saving || !isDirty}
              style={{
                padding: '10px 24px', borderRadius: radius.md, border: 'none',
                background: saved
                  ? colors.success
                  : isDirty
                    ? `linear-gradient(135deg, ${colors.navy} 0%, #1e40af 100%)`
                    : colors.border,
                color: isDirty || saved ? 'white' : colors.textMuted,
                fontWeight: 700, fontSize: 14, cursor: isDirty && !saving ? 'pointer' : 'default',
                fontFamily: fonts.body, display: 'flex', alignItems: 'center', gap: 8, transition: 'all .2s',
              }}
            >
              {saved
                ? <><svg width={15} height={15} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>Enregistré</>
                : saving ? 'Enregistrement…'
                : <><svg width={15} height={15} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13"/><polyline points="7 3 7 8 15 8"/></svg>Enregistrer</>
              }
            </button>
          </div>
        </div>

        {/* Liste des templates existants */}
        <div style={{ width: 300, flexShrink: 0 }}>
          <div style={{
            background: 'white', borderRadius: 14, padding: 20,
            boxShadow: '0 2px 12px rgba(0,0,0,.06)',
          }}>
            <div style={{ fontSize: 13, fontWeight: 700, color: colors.navy, marginBottom: 14 }}>
              Templates existants
            </div>

            {loading ? (
              <div style={{ fontSize: 13, color: colors.textMuted, textAlign: 'center', padding: '20px 0' }}>Chargement…</div>
            ) : templates.length === 0 ? (
              <div style={{ fontSize: 13, color: colors.textMuted, fontStyle: 'italic', textAlign: 'center', padding: '20px 0' }}>
                Aucun template. Créez le premier ci-contre.
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {templates.map(t => (
                  <div
                    key={t.id}
                    style={{
                      padding: '10px 12px', borderRadius: 9,
                      border: `1.5px solid ${form.id === t.id ? colors.blue : colors.border}`,
                      background: form.id === t.id ? '#eff6ff' : '#fafbff',
                      cursor: 'pointer',
                    }}
                    onClick={() => handleEdit(t)}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                      <div>
                        <div style={{ fontSize: 12.5, fontWeight: 700, color: colors.navy }}>
                          {SCOPE_LABELS[t.scope] ?? t.scope}
                        </div>
                        <div style={{ display: 'flex', gap: 5, marginTop: 4 }}>
                          <span style={{ fontSize: 10.5, fontWeight: 600, padding: '1px 7px', borderRadius: 10, background: '#f0f4ff', color: colors.blue }}>
                            {t.language.toUpperCase()}
                          </span>
                        </div>
                      </div>
                      <button
                        onClick={e => { e.stopPropagation(); handleDelete(t.id); }}
                        disabled={deleting === t.id}
                        style={{
                          background: 'none', border: 'none', cursor: 'pointer',
                          color: colors.textMuted, padding: 2,
                        }}
                        title="Supprimer"
                      >
                        <svg width={13} height={13} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round">
                          <polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/>
                        </svg>
                      </button>
                    </div>
                    <div style={{ fontSize: 11, color: colors.textMuted, marginTop: 5, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {t.subjectTemplate}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

      </div>
    </div>
  );
}

/* ─── Helpers ────────────────────────────────────────────────────────────── */

function Label({ children }: { children: React.ReactNode }) {
  return (
    <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '.07em', textTransform: 'uppercase', color: colors.textMuted, marginBottom: 6 }}>
      {children}
    </div>
  );
}

const inputStyle: React.CSSProperties = {
  width: '100%', padding: '10px 14px', borderRadius: 9,
  border: `1.5px solid #e2e8f0`,
  background: '#f8fafc', fontFamily: fonts.body,
  fontSize: 13.5, color: '#0f172a', outline: 'none',
  boxSizing: 'border-box',
};

const selectStyle: React.CSSProperties = {
  ...inputStyle,
  cursor: 'pointer',
};
