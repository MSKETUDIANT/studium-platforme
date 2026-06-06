import React, { useState, useEffect } from 'react';
import { PageHeader } from '../../../shared/components/PageHeader';
import { colors, fonts, radius } from '../../../shared/constants/theme';
import {
  fetchEmailTemplates, upsertEmailTemplate, deleteEmailTemplate,
  TEMPLATE_VARIABLES, SCOPE_LABELS,
} from '../services/email_templates_service';
import type { EmailTemplate } from '../services/email_templates_service';
import {
  fetchPlatformSettings, savePlatformSettings,
} from '../services/platform_settings_service';
import type { PlatformSettings } from '../services/platform_settings_service';

/*  Constants  */

const DEFAULT_SUBJECT = '[Studium] Candidature  {{student_name}}  {{program_name}}';
const DEFAULT_BODY =
`Madame, Monsieur,

Nous vous transmettons la candidature de {{student_name}} pour le programme {{program_name}} à {{university_name}}{{country}}.

Vous trouverez en pièce jointe le dossier complet du candidat.

Cordialement,
L'équipe Studium Admissions`;

const SCOPES    = ['global', 'program', 'followup', 'correction'];
const LANGUAGES = [{ value: 'fr', label: 'Français' }, { value: 'en', label: 'English' }];
const TABS      = ['Templates email', 'Règles & Limites', 'Général'] as const;
type Tab = typeof TABS[number];

const EMPTY_FORM = {
  id:              undefined as string | undefined,
  scope:           'global',
  language:        'fr',
  programId:       null as string | null,
  subjectTemplate: DEFAULT_SUBJECT,
  bodyTemplate:    DEFAULT_BODY,
};

/*  Page  */

export default function SettingsPage() {
  const [activeTab, setActiveTab] = useState<Tab>('Templates email');

  return (
    <div style={{ fontFamily: fonts.body }}>
      <PageHeader
        title="Paramètres"
        subtitle="Templates email, règles de validation et configuration de la plateforme"
      />

      {/* Onglets */}
      <div>
        <div style={{
          display: 'flex', gap: 4,
          background: 'white', borderRadius: 12, padding: 4,
          boxShadow: '0 2px 12px rgba(0,0,0,.06)', width: 'fit-content',
        }}>
          {TABS.map(tab => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              style={{
                padding: '9px 20px', borderRadius: 9, border: 'none',
                background: activeTab === tab
                  ? `linear-gradient(135deg, ${colors.navy} 0%, #1e40af 100%)`
                  : 'transparent',
                color: activeTab === tab ? 'white' : colors.textSecondary,
                fontWeight: activeTab === tab ? 700 : 500,
                fontSize: 13.5, cursor: 'pointer', fontFamily: fonts.body,
                transition: 'all .2s',
              }}
            >
              {tab}
            </button>
          ))}
        </div>
      </div>

      <div style={{ padding: '20px 0 40px' }}>
        {activeTab === 'Templates email' && <TemplatesTab />}
        {activeTab === 'Règles & Limites' && <RulesTab />}
        {activeTab === 'Général'          && <GeneralTab />}
      </div>
    </div>
  );
}

/*  Tab 1 : Templates email  */

function TemplatesTab() {
  const [templates, setTemplates] = useState<EmailTemplate[]>([]);
  const [loading,   setLoading]   = useState(true);
  const [form,      setForm]      = useState({ ...EMPTY_FORM });
  const [saving,    setSaving]    = useState(false);
  const [saved,     setSaved]     = useState(false);
  const [error,     setError]     = useState<string | null>(null);
  const [deleting,  setDeleting]  = useState<string | null>(null);

  useEffect(() => {
    fetchEmailTemplates()
      .then(setTemplates).catch(() => setTemplates([]))
      .finally(() => setLoading(false));
  }, []);

  function handleEdit(t: EmailTemplate) {
    setForm({ id: t.id, scope: t.scope, language: t.language, programId: t.programId, subjectTemplate: t.subjectTemplate, bodyTemplate: t.bodyTemplate });
    setSaved(false); setError(null);
  }

  function handleNew() {
    setForm({ ...EMPTY_FORM, id: undefined });
    setSaved(false); setError(null);
  }

  async function handleSave() {
    if (!form.subjectTemplate.trim() || !form.bodyTemplate.trim()) return;
    setSaving(true); setError(null);
    try {
      const isNew = !form.id;
      await upsertEmailTemplate(form);
      const updated = await fetchEmailTemplates();
      setTemplates(updated);
      if (isNew) {
        const created = updated.find(t => t.scope === form.scope && t.language === form.language && !t.programId);
        if (created) setForm(f => ({ ...f, id: created.id }));
      }
      setSaved(true);
      setTimeout(() => setSaved(false), 2500);
    } catch (e: any) {
      setError(e?.message ?? JSON.stringify(e));
    } finally { setSaving(false); }
  }

  async function handleDelete(id: string) {
    setDeleting(id);
    try {
      await deleteEmailTemplate(id);
      setTemplates(t => t.filter(x => x.id !== id));
      if (form.id === id) handleNew();
    } finally { setDeleting(null); }
  }

  return (
    <div style={{ display: 'flex', gap: 24, alignItems: 'flex-start' }}>
      {/* Éditeur */}
      <div style={{ flex: 1 }}>
        <Card>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 22 }}>
            <div>
              <div style={{ fontSize: 16, fontWeight: 800, color: colors.navy }}>
                {form.id ? 'Modifier le template' : 'Nouveau template'}
              </div>
              <div style={{ fontSize: 12.5, color: colors.textMuted, marginTop: 3 }}>
                Utilisez <code style={{ background: '#f0f4ff', padding: '1px 6px', borderRadius: 4, fontSize: 11 }}>{'{{variable}}'}</code> dans le sujet et le corps.
              </div>
            </div>
            {form.id && <BtnOutline onClick={handleNew}>+ Nouveau</BtnOutline>}
          </div>

          <div style={{ display: 'flex', gap: 12, marginBottom: 16 }}>
            <div style={{ flex: 1 }}>
              <Label>Type de template</Label>
              <select value={form.scope} onChange={e => setForm(f => ({ ...f, scope: e.target.value }))} style={selectStyle}>
                {SCOPES.map(s => <option key={s} value={s}>{SCOPE_LABELS[s] ?? s}</option>)}
              </select>
            </div>
            <div style={{ width: 140 }}>
              <Label>Langue</Label>
              <select value={form.language} onChange={e => setForm(f => ({ ...f, language: e.target.value }))} style={selectStyle}>
                {LANGUAGES.map(l => <option key={l.value} value={l.value}>{l.label}</option>)}
              </select>
            </div>
          </div>

          <div style={{ marginBottom: 16 }}>
            <Label>Sujet de l'email</Label>
            <input type="text" value={form.subjectTemplate} onChange={e => setForm(f => ({ ...f, subjectTemplate: e.target.value }))} style={{ ...inputStyle, fontWeight: 600 }} />
          </div>

          <div style={{ marginBottom: 8 }}>
            <Label>Corps de l'email</Label>
            <textarea value={form.bodyTemplate} onChange={e => setForm(f => ({ ...f, bodyTemplate: e.target.value }))} rows={12} style={{ ...inputStyle, resize: 'vertical', lineHeight: 1.6 }} />
          </div>

          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 20 }}>
            <span style={{ fontSize: 11.5, color: colors.textMuted, alignSelf: 'center', marginRight: 4 }}>Insérer :</span>
            {TEMPLATE_VARIABLES.map(v => (
              <button key={v.key} onClick={() => setForm(f => ({ ...f, bodyTemplate: f.bodyTemplate + v.key }))}
                style={{ padding: '3px 10px', borderRadius: 20, fontSize: 11.5, fontWeight: 600, background: '#eff6ff', color: colors.blue, border: 'none', cursor: 'pointer', fontFamily: fonts.body }}>
                {v.key}
              </button>
            ))}
          </div>

          {error && <div style={{ fontSize: 12.5, color: colors.danger, marginBottom: 12, padding: '8px 12px', background: '#fef2f2', borderRadius: 7 }}>{error}</div>}

          <BtnPrimary onClick={handleSave} disabled={saving || !form.subjectTemplate.trim()} saved={saved} saving={saving}>
            {saved ? 'Enregistré' : saving ? 'Enregistrement' : 'Enregistrer'}
          </BtnPrimary>
        </Card>
      </div>

      {/* Sidebar templates */}
      <div style={{ width: 300, flexShrink: 0 }}>
        <Card>
          <div style={{ fontSize: 13, fontWeight: 700, color: colors.navy, marginBottom: 14 }}>Templates existants</div>
          {loading ? (
            <div style={{ fontSize: 13, color: colors.textMuted, textAlign: 'center', padding: '20px 0' }}>Chargement</div>
          ) : templates.length === 0 ? (
            <div style={{ fontSize: 13, color: colors.textMuted, fontStyle: 'italic', textAlign: 'center', padding: '20px 0' }}>Aucun template.</div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {templates.map(t => (
                <div key={t.id}
                  style={{ padding: '10px 12px', borderRadius: 9, border: `1.5px solid ${form.id === t.id ? colors.blue : colors.border}`, background: form.id === t.id ? '#eff6ff' : '#fafbff', cursor: 'pointer' }}
                  onClick={() => handleEdit(t)}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <div>
                      <div style={{ fontSize: 12.5, fontWeight: 700, color: colors.navy }}>{SCOPE_LABELS[t.scope] ?? t.scope}</div>
                      <span style={{ fontSize: 10.5, fontWeight: 600, padding: '1px 7px', borderRadius: 10, background: '#f0f4ff', color: colors.blue, marginTop: 4, display: 'inline-block' }}>{t.language.toUpperCase()}</span>
                    </div>
                    <button onClick={e => { e.stopPropagation(); handleDelete(t.id); }} disabled={deleting === t.id}
                      style={{ background: 'none', border: 'none', cursor: 'pointer', color: colors.textMuted, padding: 2 }}>
                      <svg width={13} height={13} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/></svg>
                    </button>
                  </div>
                  <div style={{ fontSize: 11, color: colors.textMuted, marginTop: 5, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{t.subjectTemplate}</div>
                </div>
              ))}
            </div>
          )}
        </Card>
      </div>
    </div>
  );
}

/*  Tab 2 : Règles & Limites  */

function RulesTab() {
  const [settings, setSettings] = useState<PlatformSettings>({
    uploadMaxSizeMb: 10, uploadAllowedFormats: 'pdf,doc,docx,jpg,jpeg,png',
    motivationMinWords: 300, supportEmail: 'support@studium.app',
    platformName: 'Studium', defaultLanguage: 'fr',
  });
  const [saving, setSaving] = useState(false);
  const [saved,  setSaved]  = useState(false);
  const [error,  setError]  = useState<string | null>(null);

  useEffect(() => {
    fetchPlatformSettings().then(setSettings).catch(() => {});
  }, []);

  async function handleSave() {
    setSaving(true); setError(null);
    try {
      await savePlatformSettings(settings);
      setSaved(true); setTimeout(() => setSaved(false), 2500);
    } catch (e: any) { setError(e?.message ?? 'Erreur inconnue'); }
    finally { setSaving(false); }
  }

  return (
    <div style={{ maxWidth: 680 }}>
      <Card>
        <SectionTitle title="Upload documents" subtitle="Limites appliquées à tous les uploads étudiants" />

        <div style={{ display: 'flex', gap: 16, marginBottom: 18 }}>
          <div style={{ flex: 1 }}>
            <Label>Taille max par fichier (MB)</Label>
            <input type="number" min={1} max={100} value={settings.uploadMaxSizeMb}
              onChange={e => setSettings(s => ({ ...s, uploadMaxSizeMb: Number(e.target.value) }))}
              style={inputStyle} />
            <div style={{ fontSize: 11, color: colors.textMuted, marginTop: 4 }}>Recommandé : 10 MB</div>
          </div>
          <div style={{ flex: 2 }}>
            <Label>Formats autorisés (séparés par des virgules)</Label>
            <input type="text" value={settings.uploadAllowedFormats}
              onChange={e => setSettings(s => ({ ...s, uploadAllowedFormats: e.target.value }))}
              style={inputStyle} placeholder="pdf,doc,docx,jpg,jpeg,png" />
          </div>
        </div>

        <Divider />
        <SectionTitle title="Lettre de motivation" subtitle="Contrainte de longueur minimale" />

        <div style={{ maxWidth: 300, marginBottom: 18 }}>
          <Label>Nombre de mots minimum</Label>
          <input type="number" min={50} max={2000} value={settings.motivationMinWords}
            onChange={e => setSettings(s => ({ ...s, motivationMinWords: Number(e.target.value) }))}
            style={inputStyle} />
          <div style={{ fontSize: 11, color: colors.textMuted, marginTop: 4 }}>Recommandé : 300 mots</div>
        </div>

        {error && <div style={{ fontSize: 12.5, color: colors.danger, marginBottom: 12, padding: '8px 12px', background: '#fef2f2', borderRadius: 7 }}>{error}</div>}
        <BtnPrimary onClick={handleSave} disabled={saving} saved={saved} saving={saving}>
          {saved ? 'Enregistré' : saving ? 'Enregistrement' : 'Enregistrer les règles'}
        </BtnPrimary>
      </Card>
    </div>
  );
}

/*  Tab 3 : Général  */

function GeneralTab() {
  const [settings, setSettings] = useState<PlatformSettings>({
    uploadMaxSizeMb: 10, uploadAllowedFormats: 'pdf,doc,docx,jpg,jpeg,png',
    motivationMinWords: 300, supportEmail: 'support@studium.app',
    platformName: 'Studium', defaultLanguage: 'fr',
  });
  const [saving, setSaving] = useState(false);
  const [saved,  setSaved]  = useState(false);
  const [error,  setError]  = useState<string | null>(null);

  useEffect(() => {
    fetchPlatformSettings().then(setSettings).catch(() => {});
  }, []);

  async function handleSave() {
    setSaving(true); setError(null);
    try {
      await savePlatformSettings(settings);
      setSaved(true); setTimeout(() => setSaved(false), 2500);
    } catch (e: any) { setError(e?.message ?? 'Erreur inconnue'); }
    finally { setSaving(false); }
  }

  return (
    <div style={{ maxWidth: 680 }}>
      <Card>
        <SectionTitle title="Plateforme" subtitle="Informations générales de la plateforme" />

        <div style={{ marginBottom: 16 }}>
          <Label>Nom de la plateforme</Label>
          <input type="text" value={settings.platformName}
            onChange={e => setSettings(s => ({ ...s, platformName: e.target.value }))}
            style={inputStyle} />
        </div>

        <div style={{ marginBottom: 16 }}>
          <Label>Email de support</Label>
          <input type="email" value={settings.supportEmail}
            onChange={e => setSettings(s => ({ ...s, supportEmail: e.target.value }))}
            style={inputStyle} placeholder="support@studium.app" />
        </div>

        <Divider />
        <SectionTitle title="Langue par défaut" subtitle="Langue utilisée pour les emails et l'interface" />

        <div style={{ maxWidth: 200, marginBottom: 18 }}>
          <Label>Langue</Label>
          <select value={settings.defaultLanguage}
            onChange={e => setSettings(s => ({ ...s, defaultLanguage: e.target.value }))}
            style={selectStyle}>
            <option value="fr">Français</option>
            <option value="en">English</option>
          </select>
        </div>

        {error && <div style={{ fontSize: 12.5, color: colors.danger, marginBottom: 12, padding: '8px 12px', background: '#fef2f2', borderRadius: 7 }}>{error}</div>}
        <BtnPrimary onClick={handleSave} disabled={saving} saved={saved} saving={saving}>
          {saved ? 'Enregistré' : saving ? 'Enregistrement' : 'Enregistrer'}
        </BtnPrimary>
      </Card>
    </div>
  );
}

/*  Shared components  */

function Card({ children }: { children: React.ReactNode }) {
  return (
    <div style={{ background: 'white', borderRadius: 14, padding: 28, boxShadow: '0 2px 12px rgba(0,0,0,.06)' }}>
      {children}
    </div>
  );
}

function SectionTitle({ title, subtitle }: { title: string; subtitle: string }) {
  return (
    <div style={{ marginBottom: 18 }}>
      <div style={{ fontSize: 15, fontWeight: 800, color: colors.navy }}>{title}</div>
      <div style={{ fontSize: 12.5, color: colors.textMuted, marginTop: 3 }}>{subtitle}</div>
    </div>
  );
}

function Divider() {
  return <div style={{ height: 1, background: colors.border, margin: '20px 0' }} />;
}

function Label({ children }: { children: React.ReactNode }) {
  return (
    <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '.07em', textTransform: 'uppercase', color: colors.textMuted, marginBottom: 6 }}>
      {children}
    </div>
  );
}

function BtnOutline({ children, onClick }: { children: React.ReactNode; onClick: () => void }) {
  return (
    <button onClick={onClick} style={{ padding: '7px 14px', borderRadius: radius.md, border: `1.5px solid ${colors.borderInput}`, background: 'white', color: colors.textSecondary, fontSize: 13, fontWeight: 600, cursor: 'pointer', fontFamily: fonts.body }}>
      {children}
    </button>
  );
}

function BtnPrimary({ children, onClick, disabled, saved, saving }: { children: React.ReactNode; onClick: () => void; disabled?: boolean; saved?: boolean; saving?: boolean }) {
  return (
    <button onClick={onClick} disabled={disabled}
      style={{
        padding: '10px 24px', borderRadius: radius.md, border: 'none',
        background: saved ? colors.success : disabled ? colors.border : `linear-gradient(135deg, ${colors.navy} 0%, #1e40af 100%)`,
        color: !disabled || saved ? 'white' : colors.textMuted,
        fontWeight: 700, fontSize: 14, cursor: disabled ? 'default' : 'pointer',
        fontFamily: fonts.body, display: 'flex', alignItems: 'center', gap: 8, transition: 'all .2s',
        opacity: saving ? 0.7 : 1,
      }}>
      {saved && <svg width={15} height={15} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>}
      {children}
    </button>
  );
}

const inputStyle: React.CSSProperties = {
  width: '100%', padding: '10px 14px', borderRadius: 9,
  border: `1.5px solid #e2e8f0`, background: '#f8fafc',
  fontFamily: fonts.body, fontSize: 13.5, color: '#0f172a',
  outline: 'none', boxSizing: 'border-box',
};

const selectStyle: React.CSSProperties = { ...inputStyle, cursor: 'pointer' };
