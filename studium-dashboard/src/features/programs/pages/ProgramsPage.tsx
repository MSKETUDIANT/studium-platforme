import { useState, useEffect, useMemo, useCallback, type ReactNode } from 'react';
import { supabase }       from '../../../shared/services/supabase';
import { Button }         from '../../../shared/components/Button';
import { PageHeader }     from '../../../shared/components/PageHeader';
import { LoadingSpinner } from '../../../shared/components/LoadingSpinner';
import { EmptyState }     from '../../../shared/components/EmptyState';
import { colors, fonts, radius, shadows } from '../../../shared/constants/theme';

/* ─── Types ──────────────────────────────────────────────────────────────── */
interface Program {
  id:              string;
  program_name:    string;
  university_name: string;
  country:         string | null;
  language:        string | null;
  level:           string | null;
  duration:        string | null;
  cost:            number | null;
  deadline:        string | null;
  description:     string | null;
  domain:          string | null;
  requirements:    string[] | null;
  contact_email:   string | null;
  is_active:       boolean;
  created_at:      string | null;
}

type FormData = Omit<Program, 'id' | 'created_at'>;

const EMPTY_FORM: FormData = {
  program_name:    '',
  university_name: '',
  country:         '',
  language:        '',
  level:           '',
  duration:        '',
  cost:            null,
  deadline:        '',
  description:     '',
  domain:          '',
  requirements:    null,
  contact_email:   '',
  is_active:       true,
};

const DOMAINS = [
  'Informatique', 'Ingénierie', 'Commerce / Gestion', 'Droit',
  'Médecine / Santé', 'Sciences', 'Arts & Humanités',
  'Sciences Sociales', 'Éducation', 'Architecture', 'Autre',
];

const LEVELS: { value: string; label: string }[] = [
  { value: 'bachelor', label: 'Licence (Bachelor)' },
  { value: 'master',   label: 'Master'              },
  { value: 'phd',      label: 'Doctorat (PhD)'      },
];

const LEVEL_LABEL: Record<string, string> = {
  bachelor: 'Licence',
  master:   'Master',
  phd:      'Doctorat',
};

const COUNTRIES = [
  'Afghanistan', 'Afrique du Sud', 'Albanie', 'Algérie', 'Allemagne',
  'Andorre', 'Angola', 'Antigua-et-Barbuda', 'Arabie Saoudite', 'Argentine',
  'Arménie', 'Australie', 'Autriche', 'Azerbaïdjan',
  'Bahamas', 'Bahreïn', 'Bangladesh', 'Barbade', 'Bélarus', 'Belgique',
  'Belize', 'Bénin', 'Bhoutan', 'Bolivie', 'Bosnie-Herzégovine', 'Botswana',
  'Brésil', 'Brunéi', 'Bulgarie', 'Burkina Faso', 'Burundi',
  'Cabo Verde', 'Cambodge', 'Cameroun', 'Canada', 'Centrafrique', 'Chili',
  'Chine', 'Chypre', 'Colombie', 'Comores', 'Congo', 'Corée du Nord',
  'Corée du Sud', 'Costa Rica', 'Côte d\'Ivoire', 'Croatie', 'Cuba',
  'Danemark', 'Djibouti', 'Dominique',
  'Égypte', 'Émirats Arabes Unis', 'Équateur', 'Érythrée', 'Espagne',
  'Estonie', 'Eswatini', 'États-Unis', 'Éthiopie',
  'Fidji', 'Finlande', 'France',
  'Gabon', 'Gambie', 'Géorgie', 'Ghana', 'Grèce', 'Grenade',
  'Guatemala', 'Guinée', 'Guinée équatoriale', 'Guinée-Bissau', 'Guyana',
  'Haïti', 'Honduras', 'Hongrie',
  'Îles Marshall', 'Îles Salomon', 'Inde', 'Indonésie', 'Irak', 'Iran',
  'Irlande', 'Islande', 'Israël', 'Italie',
  'Jamaïque', 'Japon', 'Jordanie',
  'Kazakhstan', 'Kenya', 'Kirghizistan', 'Kiribati', 'Koweït',
  'Laos', 'Lesotho', 'Lettonie', 'Liban', 'Libéria', 'Libye',
  'Liechtenstein', 'Lituanie', 'Luxembourg',
  'Macédoine du Nord', 'Madagascar', 'Malaisie', 'Malawi', 'Maldives',
  'Mali', 'Malte', 'Maroc', 'Maurice', 'Mauritanie', 'Mexique',
  'Micronésie', 'Moldavie', 'Monaco', 'Mongolie', 'Monténégro',
  'Mozambique', 'Myanmar',
  'Namibie', 'Nauru', 'Népal', 'Nicaragua', 'Niger', 'Nigéria',
  'Norvège', 'Nouvelle-Zélande',
  'Oman', 'Ouganda',
  'Pakistan', 'Palaos', 'Palestine', 'Panama', 'Papouasie-Nouvelle-Guinée',
  'Paraguay', 'Pays-Bas', 'Pérou', 'Philippines', 'Pologne', 'Portugal',
  'Qatar',
  'République Démocratique du Congo', 'République Dominicaine',
  'République Tchèque', 'Roumanie', 'Royaume-Uni', 'Russie', 'Rwanda',
  'Saint-Kitts-et-Nevis', 'Saint-Marin', 'Saint-Vincent-et-les-Grenadines',
  'Sainte-Lucie', 'Salvador', 'Samoa', 'São Tomé-et-Príncipe',
  'Sénégal', 'Serbie', 'Seychelles', 'Sierra Leone', 'Singapour',
  'Slovaquie', 'Slovénie', 'Somalie', 'Soudan', 'Soudan du Sud',
  'Sri Lanka', 'Suède', 'Suisse', 'Suriname', 'Syrie',
  'Tadjikistan', 'Tanzanie', 'Tchad', 'Thaïlande', 'Timor-Leste',
  'Togo', 'Tonga', 'Trinité-et-Tobago', 'Tunisie', 'Turkménistan',
  'Turquie', 'Tuvalu',
  'Ukraine', 'Uruguay', 'Ouzbékistan',
  'Vanuatu', 'Vatican', 'Venezuela', 'Viêt Nam',
  'Yémen',
  'Zambie', 'Zimbabwe',
];

const LANGUAGES = [
  'Français', 'Anglais', 'Arabe', 'Espagnol', 'Allemand',
  'Portugais', 'Italien', 'Néerlandais', 'Chinois', 'Japonais',
];

const DURATIONS = [
  '6 mois', '1 an', '18 mois', '2 ans', '3 ans', '4 ans', '5 ans', '6 ans',
];

const CURRENCIES: { symbol: string; code: string; label: string }[] = [
  { symbol: '€',   code: 'EUR', label: 'EUR — Euro'             },
  { symbol: '$',   code: 'USD', label: 'USD — Dollar américain' },
  { symbol: '£',   code: 'GBP', label: 'GBP — Livre sterling'   },
  { symbol: 'CA$', code: 'CAD', label: 'CAD — Dollar canadien'  },
  { symbol: 'CHF', code: 'CHF', label: 'CHF — Franc suisse'     },
  { symbol: 'CFA', code: 'XOF', label: 'XOF — Franc CFA UEMOA' },
  { symbol: 'CFA', code: 'XAF', label: 'XAF — Franc CFA CEMAC' },
  { symbol: 'MAD', code: 'MAD', label: 'MAD — Dirham marocain'  },
  { symbol: 'DZD', code: 'DZD', label: 'DZD — Dinar algérien'  },
  { symbol: 'TND', code: 'TND', label: 'TND — Dinar tunisien'   },
];

const LEVEL_CFG: Record<string, { color: string; bg: string }> = {
  bachelor: { color: colors.blue,    bg: 'rgba(37,70,204,0.10)'   },
  master:   { color: '#7c3aed',      bg: 'rgba(124,58,237,0.10)'  },
  phd:      { color: colors.success, bg: 'rgba(22,163,74,0.10)'   },
};

/* ─── CSS ─────────────────────────────────────────────────────────────────── */
const CSS = `
  .pp-stat-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 16px;
    margin-bottom: 20px;
  }
  @media (max-width: 900px) { .pp-stat-grid { grid-template-columns: repeat(2,1fr); } }

  .pp-toolbar-card {
    background: white;
    border-radius: ${radius.lg}px;
    box-shadow: ${shadows.card};
    padding: 14px 16px;
    margin-bottom: 20px;
  }

  .pp-toolbar {
    display: flex;
    gap: 10px;
    align-items: center;
    flex-wrap: wrap;
  }

  .pp-search-wrap { position: relative; flex: 1; min-width: 200px; }
  .pp-search-icon {
    position: absolute; left: 12px; top: 50%; transform: translateY(-50%);
    color: ${colors.textMuted}; font-size: 14px; pointer-events: none;
  }
  .pp-search {
    width: 100%;
    padding: 8px 14px 8px 38px;
    border: 1.5px solid ${colors.borderInput};
    border-radius: ${radius.md}px;
    font-size: 13.5px;
    color: ${colors.textPrimary};
    background: ${colors.inputBg};
    outline: none;
    box-sizing: border-box;
    font-family: ${fonts.body};
    transition: border-color .18s;
  }
  .pp-search:focus { border-color: ${colors.blue}; }

  .pp-select {
    padding: 8px 12px;
    border: 1.5px solid ${colors.borderInput};
    border-radius: ${radius.md}px;
    font-size: 13.5px;
    color: ${colors.textPrimary};
    background: ${colors.inputBg};
    outline: none;
    font-family: ${fonts.body};
    cursor: pointer;
    transition: border-color .18s;
  }
  .pp-select:focus { border-color: ${colors.blue}; }

  .pp-table-wrap {
    overflow-x: auto;
    border-radius: ${radius.lg}px;
    box-shadow: ${shadows.card};
  }

  .pp-table {
    width: 100%;
    border-collapse: collapse;
    background: white;
    border-radius: ${radius.lg}px;
    overflow: hidden;
    font-family: ${fonts.body};
  }

  .pp-table thead tr {
    background: linear-gradient(135deg, #f8faff 0%, ${colors.inputBg} 100%);
    border-bottom: 2px solid ${colors.border};
  }

  .pp-table th {
    padding: 13px 16px;
    text-align: left;
    font-size: 11px;
    font-weight: 700;
    color: ${colors.textSecondary};
    text-transform: uppercase;
    letter-spacing: .6px;
    white-space: nowrap;
  }

  .pp-table td {
    padding: 13px 16px;
    border-bottom: 1px solid ${colors.border};
    font-size: 13.5px;
    color: ${colors.textPrimary};
    vertical-align: middle;
  }

  .pp-table tbody tr:last-child td { border-bottom: none; }
  .pp-table tbody tr { transition: background .12s; }
  .pp-table tbody tr:hover td { background: #f5f8ff; }

  .pp-prog-name {
    font-weight: 600;
    font-size: 13.5px;
    color: ${colors.blue};
    display: block;
    cursor: pointer;
    background: none;
    border: none;
    padding: 0;
    font-family: ${fonts.body};
    text-align: left;
    text-decoration: underline;
    text-decoration-color: transparent;
    transition: text-decoration-color .15s;
  }
  .pp-prog-name:hover { text-decoration-color: ${colors.blue}; }

  .pp-univ-name {
    font-size: 12px;
    color: ${colors.textSecondary};
    display: block;
    margin-top: 2px;
  }

  .pp-level-badge {
    display: inline-block;
    padding: 3px 10px;
    border-radius: 20px;
    font-size: 11px;
    font-weight: 600;
    white-space: nowrap;
  }

  .pp-active-badge {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 3px 10px;
    border-radius: 20px;
    font-size: 11px;
    font-weight: 600;
  }

  .pp-action-btn {
    padding: 5px 9px;
    border-radius: 8px;
    border: 1.5px solid transparent;
    background: ${colors.inputBg};
    display: inline-flex; align-items: center; gap: 4px;
    cursor: pointer;
    font-size: 11.5px;
    font-family: ${fonts.body};
    font-weight: 600;
    transition: all .15s;
    white-space: nowrap;
  }
  .pp-action-edit  { color: ${colors.blue}; }
  .pp-action-edit:hover  { border-color: ${colors.blue}; background: rgba(37,70,204,0.07); }
  .pp-action-archive { color: ${colors.warning}; }
  .pp-action-archive:hover { border-color: ${colors.warning}; background: rgba(217,119,6,0.07); }
  .pp-action-restore { color: ${colors.success}; }
  .pp-action-restore:hover { border-color: ${colors.success}; background: rgba(22,163,74,0.07); }
  .pp-action-delete { color: ${colors.danger}; }
  .pp-action-delete:hover { border-color: ${colors.danger}; background: rgba(220,38,38,0.07); }

  .pp-overlay {
    position: fixed; inset: 0;
    background: rgba(11,24,82,0.35);
    backdrop-filter: blur(3px);
    display: flex; align-items: center; justify-content: center;
    z-index: 1000;
    padding: 20px;
  }

  .pp-modal {
    background: white;
    border-radius: ${radius.lg}px;
    padding: 28px;
    width: 100%;
    max-width: 560px;
    max-height: 90vh;
    overflow-y: auto;
    box-shadow: 0 24px 60px rgba(11,24,82,0.18);
  }

  .pp-form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 14px;
  }
  @media (max-width: 500px) { .pp-form-grid { grid-template-columns: 1fr; } }
  .pp-form-full { grid-column: 1 / -1; }

  .pp-field {
    display: flex;
    flex-direction: column;
    gap: 5px;
  }
  .pp-label {
    font-size: 12px;
    font-weight: 600;
    color: ${colors.textSecondary};
  }
  .pp-input, .pp-textarea, .pp-form-select {
    padding: 9px 12px;
    border: 1.5px solid ${colors.borderInput};
    border-radius: ${radius.md}px;
    font-size: 13.5px;
    color: ${colors.textPrimary};
    background: ${colors.inputBg};
    font-family: ${fonts.body};
    outline: none;
    transition: border-color .18s;
    box-sizing: border-box;
    width: 100%;
  }
  .pp-input:focus, .pp-textarea:focus, .pp-form-select:focus {
    border-color: ${colors.blue};
  }
  .pp-input.error, .pp-form-select.error {
    border-color: ${colors.danger};
    background: #fff8f8;
  }
  .pp-textarea { resize: vertical; min-height: 80px; }
  .pp-field-error { font-size: 11px; color: ${colors.danger}; margin-top: 2px; }

  /* ─── Cost input group ─── */
  .pp-cost-group {
    display: flex;
    border: 1.5px solid ${colors.borderInput};
    border-radius: ${radius.md}px;
    overflow: hidden;
    background: ${colors.inputBg};
    transition: border-color .18s;
  }
  .pp-cost-group:focus-within { border-color: ${colors.blue}; }
  .pp-cost-currency {
    padding: 9px 10px;
    background: white;
    border-right: 1.5px solid ${colors.borderInput};
    font-size: 13px;
    color: ${colors.textSecondary};
    cursor: pointer;
    outline: none;
    font-family: ${fonts.body};
    min-width: 90px;
  }
  .pp-cost-amount {
    flex: 1;
    padding: 9px 12px;
    border: none;
    background: transparent;
    font-size: 13.5px;
    color: ${colors.textPrimary};
    font-family: ${fonts.body};
    outline: none;
    width: 100%;
    box-sizing: border-box;
  }
  .pp-gratuit-btn {
    padding: 4px 10px;
    border-radius: 20px;
    border: 1.5px solid ${colors.borderInput};
    background: white;
    font-size: 12px;
    font-family: ${fonts.body};
    cursor: pointer;
    color: ${colors.success};
    font-weight: 600;
    transition: all .15s;
    white-space: nowrap;
    align-self: center;
  }
  .pp-gratuit-btn.active {
    background: rgba(22,163,74,0.10);
    border-color: ${colors.success};
  }
  .pp-gratuit-btn:hover { border-color: ${colors.success}; }

  /* ─── Toast ─── */
  .pp-toast {
    position: fixed;
    bottom: 28px;
    right: 28px;
    z-index: 2000;
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 13px 18px;
    border-radius: 12px;
    box-shadow: 0 8px 32px rgba(11,24,82,0.18);
    font-family: ${fonts.body};
    font-size: 14px;
    font-weight: 500;
    animation: pp-toast-in .22s ease;
    max-width: 340px;
  }
  .pp-toast-success { background: #ecfdf5; border: 1.5px solid #86efac; color: #166534; }
  .pp-toast-error   { background: #fef2f2; border: 1.5px solid #fca5a5; color: #991b1b; }
  @keyframes pp-toast-in {
    from { opacity: 0; transform: translateY(12px); }
    to   { opacity: 1; transform: translateY(0); }
  }

  /* ─── Detail modal ─── */
  .pp-detail-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0;
  }
  .pp-detail-row {
    display: contents;
  }
  .pp-detail-label {
    padding: 10px 0;
    font-size: 12px;
    font-weight: 600;
    color: ${colors.textSecondary};
    text-transform: uppercase;
    letter-spacing: .4px;
    border-bottom: 1px solid ${colors.border};
  }
  .pp-detail-value {
    padding: 10px 0;
    font-size: 13.5px;
    color: ${colors.textPrimary};
    border-bottom: 1px solid ${colors.border};
  }
  .pp-detail-desc {
    margin-top: 16px;
    padding: 14px;
    background: ${colors.inputBg};
    border-radius: ${radius.md}px;
    font-size: 13.5px;
    line-height: 1.65;
    color: ${colors.textPrimary};
    white-space: pre-wrap;
  }
`;

function injectCSS() {
  if (typeof document === 'undefined') return;
  if (document.getElementById('pp-styles')) return;
  const s = document.createElement('style');
  s.id = 'pp-styles';
  s.textContent = CSS;
  document.head.appendChild(s);
}

/* ─── Helpers ─────────────────────────────────────────────────────────────── */
function fmtCost(cost: number | null) {
  if (cost == null) return '—';
  if (cost === 0) return 'Gratuit';
  return new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 0 }).format(cost);
}

function fmtDate(d: string | null) {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' });
}

const STAT_ICONS: Record<string, ReactNode> = {
  total: (
    <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3.33 1.67 8.67 1.67 12 0v-5"/>
    </svg>
  ),
  active: (
    <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
    </svg>
  ),
  master: (
    <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="3"/>
      <line x1="12" y1="2" x2="12" y2="4"/><line x1="12" y1="20" x2="12" y2="22"/>
      <line x1="2" y1="12" x2="4" y2="12"/><line x1="20" y1="12" x2="22" y2="12"/>
    </svg>
  ),
  licence: (
    <svg width={20} height={20} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>
    </svg>
  ),
};

function StatCard({ label, value, color, iconKey }: { label: string; value: number | string; color: string; iconKey: keyof typeof STAT_ICONS }) {
  return (
    <div style={{
      background: 'white',
      borderRadius: radius.lg,
      boxShadow: shadows.card,
      overflow: 'hidden',
    }}>
      <div style={{ height: 3, background: color }} />
      <div style={{ padding: '16px 20px', display: 'flex', alignItems: 'center', gap: 14 }}>
        <div style={{
          width: 46, height: 46, borderRadius: 13, flexShrink: 0,
          background: color + '18',
          color,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          {STAT_ICONS[iconKey]}
        </div>
        <div>
          <div style={{ fontSize: 26, fontWeight: 800, color, fontFamily: fonts.display, lineHeight: 1 }}>{value}</div>
          <div style={{ fontSize: 12, color: colors.textMuted, marginTop: 4, fontWeight: 500 }}>{label}</div>
        </div>
      </div>
    </div>
  );
}

/* ─── Detail Modal ────────────────────────────────────────────────────────── */
function ProgramDetailModal({ program, onClose, onEdit }: {
  program: Program;
  onClose: () => void;
  onEdit: () => void;
}) {
  const lvlCfg = program.level ? LEVEL_CFG[program.level] : null;
  return (
    <div className="pp-overlay" onClick={e => e.target === e.currentTarget && onClose()}>
      <div className="pp-modal" style={{ maxWidth: 600 }}>
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 20 }}>
          <div style={{ flex: 1, marginRight: 16 }}>
            {lvlCfg && program.level && (
              <span className="pp-level-badge" style={{ color: lvlCfg.color, background: lvlCfg.bg, marginBottom: 8, display: 'inline-block' }}>
                {LEVEL_LABEL[program.level] ?? program.level}
              </span>
            )}
            <h2 style={{ margin: '6px 0 4px', fontSize: 20, fontWeight: 800, fontFamily: fonts.display, color: colors.textPrimary, lineHeight: 1.3 }}>
              {program.program_name}
            </h2>
            <div style={{ fontSize: 14, color: colors.textSecondary }}>🏛 {program.university_name}</div>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', fontSize: 20, cursor: 'pointer', color: colors.textMuted, flexShrink: 0 }}>✕</button>
        </div>

        <div className="pp-detail-grid">
          {[
            ['Pays',     program.country   ?? '—'],
            ['Langue',   program.language  ?? '—'],
            ['Durée',    program.duration  ?? '—'],
            ['Coût',     fmtCost(program.cost)],
            ['Deadline', fmtDate(program.deadline)],
            ['Statut',   program.is_active ? 'Actif' : 'Inactif'],
          ].map(([label, value]) => (
            <div key={label} className="pp-detail-row">
              <div className="pp-detail-label">{label}</div>
              <div className="pp-detail-value" style={label === 'Statut' ? { color: program.is_active ? colors.success : colors.textMuted, fontWeight: 600 } : {}}>{value}</div>
            </div>
          ))}
        </div>

        {program.description && program.description.trim() && (
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: colors.textSecondary, textTransform: 'uppercase', letterSpacing: '.4px', marginTop: 16, marginBottom: 6 }}>Description</div>
            <div className="pp-detail-desc">{program.description}</div>
          </div>
        )}

        {program.requirements && program.requirements.length > 0 && (
          <div style={{ marginTop: 16 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: colors.textSecondary, textTransform: 'uppercase', letterSpacing: '.4px', marginBottom: 8 }}>Documents requis</div>
            <ul style={{ margin: 0, paddingLeft: 18 }}>
              {program.requirements.map((r, i) => (
                <li key={i} style={{ fontSize: 13.5, color: colors.textPrimary, marginBottom: 4 }}>{r}</li>
              ))}
            </ul>
          </div>
        )}

        {program.contact_email && program.contact_email.trim() && (
          <div style={{ marginTop: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: colors.textSecondary, textTransform: 'uppercase', letterSpacing: '.4px', minWidth: 80 }}>Contact</div>
            <a href={`mailto:${program.contact_email}`} style={{ fontSize: 13.5, color: colors.blue }}>{program.contact_email}</a>
          </div>
        )}

        <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end', marginTop: 24 }}>
          <Button variant="secondary" onClick={onClose}>Fermer</Button>
          <Button onClick={onEdit}>✏️ Modifier</Button>
        </div>
      </div>
    </div>
  );
}

/* ─── Modal Form ──────────────────────────────────────────────────────────── */
function ProgramModal({
  initial,
  onSave,
  onClose,
  saving,
  error,
}: {
  initial: FormData;
  onSave: (data: FormData) => void;
  onClose: () => void;
  saving: boolean;
  error: string | null;
}) {
  const [form, setForm] = useState<FormData>(initial);
  const [submitted, setSubmitted] = useState(false);
  const [costCurrency, setCostCurrency] = useState('EUR');
  const set = (k: keyof FormData, v: unknown) => setForm(f => ({ ...f, [k]: v }));
  const isGratuit = form.cost === 0;

  const nameEmpty = form.program_name.trim() === '';
  const univEmpty = form.university_name.trim() === '';
  const valid = !nameEmpty && !univEmpty;

  function handleSubmit() {
    setSubmitted(true);
    if (!valid) return;
    onSave(form);
  }

  return (
    <div className="pp-overlay" onClick={e => e.target === e.currentTarget && onClose()}>
      <div className="pp-modal">
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
          <h2 style={{ margin: 0, fontSize: 18, fontWeight: 700, fontFamily: fonts.display, color: colors.textPrimary }}>
            {initial.program_name ? 'Modifier le programme' : 'Nouveau programme'}
          </h2>
          <button onClick={onClose} style={{ background: 'none', border: 'none', fontSize: 20, cursor: 'pointer', color: colors.textMuted }}>✕</button>
        </div>

        <div className="pp-form-grid">
          <div className="pp-field pp-form-full">
            <label className="pp-label">Nom du programme *</label>
            <input
              className={`pp-input${submitted && nameEmpty ? ' error' : ''}`}
              placeholder="Ex : Master Informatique"
              value={form.program_name}
              onChange={e => set('program_name', e.target.value)}
            />
            {submitted && nameEmpty && <span className="pp-field-error">Ce champ est obligatoire</span>}
          </div>
          <div className="pp-field pp-form-full">
            <label className="pp-label">Université *</label>
            <input
              className={`pp-input${submitted && univEmpty ? ' error' : ''}`}
              placeholder="Ex : Université Paris-Saclay"
              value={form.university_name}
              onChange={e => set('university_name', e.target.value)}
            />
            {submitted && univEmpty && <span className="pp-field-error">Ce champ est obligatoire</span>}
          </div>

          <div className="pp-field">
            <label className="pp-label">Niveau</label>
            <select className="pp-form-select" value={form.level ?? ''} onChange={e => set('level', e.target.value || null)}>
              <option value="">— Sélectionner —</option>
              {LEVELS.map(l => <option key={l.value} value={l.value}>{l.label}</option>)}
            </select>
          </div>
          <div className="pp-field">
            <label className="pp-label">Pays</label>
            <select className="pp-form-select" value={form.country ?? ''} onChange={e => set('country', e.target.value || null)}>
              <option value="">— Sélectionner —</option>
              {COUNTRIES.map(c => <option key={c} value={c}>{c}</option>)}
            </select>
          </div>

          <div className="pp-field">
            <label className="pp-label">Langue</label>
            <select className="pp-form-select" value={form.language ?? ''} onChange={e => set('language', e.target.value || null)}>
              <option value="">— Sélectionner —</option>
              {LANGUAGES.map(l => <option key={l} value={l}>{l}</option>)}
            </select>
          </div>
          <div className="pp-field">
            <label className="pp-label">Durée</label>
            <select className="pp-form-select" value={form.duration ?? ''} onChange={e => set('duration', e.target.value || null)}>
              <option value="">— Sélectionner —</option>
              {DURATIONS.map(d => <option key={d} value={d}>{d}</option>)}
            </select>
          </div>

          <div className="pp-field">
            <label className="pp-label" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span>Coût</span>
              <button
                type="button"
                className={`pp-gratuit-btn${isGratuit ? ' active' : ''}`}
                onClick={() => set('cost', isGratuit ? null : 0)}
              >
                {isGratuit ? '✓ Gratuit' : 'Gratuit ?'}
              </button>
            </label>
            {!isGratuit ? (
              <div className="pp-cost-group">
                <select
                  className="pp-cost-currency"
                  value={costCurrency}
                  onChange={e => setCostCurrency(e.target.value)}
                >
                  {CURRENCIES.map(c => (
                    <option key={c.code} value={c.code}>{c.symbol} {c.code}</option>
                  ))}
                </select>
                <input
                  className="pp-cost-amount"
                  type="number"
                  min={1}
                  placeholder="Ex : 5 000"
                  value={form.cost ?? ''}
                  onChange={e => set('cost', e.target.value ? Number(e.target.value) : null)}
                />
              </div>
            ) : (
              <div style={{ padding: '9px 12px', background: 'rgba(22,163,74,0.06)', border: `1.5px solid ${colors.success}`, borderRadius: radius.md, fontSize: 13.5, color: colors.success, fontWeight: 600 }}>
                ✓ Programme gratuit
              </div>
            )}
          </div>
          <div className="pp-field">
            <label className="pp-label">Date limite candidature</label>
            <input className="pp-input" type="date" value={form.deadline ?? ''} onChange={e => set('deadline', e.target.value || null)} />
          </div>

          <div className="pp-field pp-form-full">
            <label className="pp-label">Description</label>
            <textarea className="pp-textarea" placeholder="Présentation du programme..." value={form.description ?? ''} onChange={e => set('description', e.target.value || null)} />
          </div>

          <div className="pp-field">
            <label className="pp-label">Domaine</label>
            <select className="pp-form-select" value={form.domain ?? ''} onChange={e => set('domain', e.target.value || null)}>
              <option value="">— Sélectionner —</option>
              {DOMAINS.map(d => <option key={d} value={d}>{d}</option>)}
            </select>
          </div>

          <div className="pp-field">
            <label className="pp-label">Email de contact</label>
            <input
              className="pp-input"
              type="email"
              placeholder="Ex : admissions@universite.fr"
              value={form.contact_email ?? ''}
              onChange={e => set('contact_email', e.target.value || null)}
            />
          </div>

          <div className="pp-field pp-form-full">
            <label className="pp-label">Documents requis <span style={{ fontWeight: 400, color: '#9ca3af' }}>(un par ligne)</span></label>
            <textarea
              className="pp-textarea"
              placeholder={"CV\nRelevé de notes\nLettre de motivation\nPasseport"}
              value={form.requirements?.join('\n') ?? ''}
              onChange={e => {
                const lines = e.target.value.split('\n').map(l => l.trim()).filter(Boolean);
                set('requirements', lines.length ? lines : null);
              }}
            />
          </div>

          <div className="pp-field" style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
            <input type="checkbox" id="pp-active" checked={form.is_active} onChange={e => set('is_active', e.target.checked)} style={{ width: 16, height: 16, cursor: 'pointer' }} />
            <label htmlFor="pp-active" className="pp-label" style={{ cursor: 'pointer', fontSize: 13 }}>Programme actif (visible par les étudiants)</label>
          </div>
        </div>

        {error && (
          <div style={{ marginTop: 16, padding: '10px 14px', background: '#fef2f2', border: '1px solid #fca5a5', borderRadius: radius.md, fontSize: 13, color: colors.danger }}>
            ⚠️ {error}
          </div>
        )}
        <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end', marginTop: 16 }}>
          <Button variant="secondary" onClick={onClose} disabled={saving}>Annuler</Button>
          <Button onClick={handleSubmit} disabled={saving}>
            {saving ? 'Enregistrement...' : 'Enregistrer'}
          </Button>
        </div>
      </div>
    </div>
  );
}

/* ─── Page principale ─────────────────────────────────────────────────────── */
export default function ProgramsPage() {
  injectCSS();

  const [programs, setPrograms] = useState<Program[]>([]);
  const [loading,  setLoading]  = useState(true);
  const [search,   setSearch]   = useState('');
  const [filterLevel,   setFilterLevel]   = useState('');
  const [filterCountry, setFilterCountry] = useState('');
  const [filterLang,    setFilterLang]    = useState('');
  const [filterActive,  setFilterActive]  = useState<'all' | 'active' | 'inactive'>('all');

  const [modal, setModal]   = useState<{ open: boolean; program: Program | null }>({ open: false, program: null });
  const [saving, setSaving] = useState(false);

  const [deleteTarget, setDeleteTarget] = useState<Program | null>(null);
  const [deleting, setDeleting]         = useState(false);
  const [saveError, setSaveError]       = useState<string | null>(null);

  const [detailProgram, setDetailProgram] = useState<Program | null>(null);

  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const showToast = useCallback((message: string, type: 'success' | 'error' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3500);
  }, []);

  /* ─── Fetch ─── */
  async function fetchPrograms() {
    setLoading(true);
    const { data, error } = await supabase
      .from('programs')
      .select('*')
      .order('created_at', { ascending: false });
    if (!error && data) setPrograms(data as Program[]);
    setLoading(false);
  }

  useEffect(() => { fetchPrograms(); }, []);

  /* ─── Valeurs dynamiques pour les selects ─── */
  const countries = useMemo(() =>
    [...new Set(programs.map(p => p.country).filter(Boolean) as string[])].sort()
  , [programs]);

  const langs = useMemo(() =>
    [...new Set(programs.map(p => p.language).filter(Boolean) as string[])].sort()
  , [programs]);

  const anyFilter = search || filterLevel || filterCountry || filterLang || filterActive !== 'all';

  /* ─── Filtres ─── */
  const filtered = useMemo(() => programs.filter(p => {
    const q = search.toLowerCase();
    const matchSearch  = !q ||
      p.program_name.toLowerCase().includes(q) ||
      p.university_name.toLowerCase().includes(q) ||
      (p.country ?? '').toLowerCase().includes(q);
    const matchLevel   = !filterLevel   || p.level    === filterLevel;
    const matchCountry = !filterCountry || p.country  === filterCountry;
    const matchLang    = !filterLang    || p.language === filterLang;
    const matchActive  = filterActive === 'all' ? true : filterActive === 'active' ? p.is_active : !p.is_active;
    return matchSearch && matchLevel && matchCountry && matchLang && matchActive;
  }), [programs, search, filterLevel, filterCountry, filterLang, filterActive]);

  /* ─── Stats ─── */
  const total    = programs.length;
  const active   = programs.filter(p => p.is_active).length;
  const masters  = programs.filter(p => p.level === 'master').length;
  const licences = programs.filter(p => p.level === 'bachelor').length;

  /* ─── Save (create / update) ─── */
  async function handleSave(form: FormData) {
    setSaving(true);
    setSaveError(null);
    const payload = {
      program_name:    form.program_name.trim(),
      university_name: form.university_name.trim(),
      country:         form.country    || null,
      language:        form.language   || null,
      level:           form.level      || null,
      duration:        form.duration   || null,
      cost:            form.cost       ?? null,
      deadline:        form.deadline   || null,
      description:     form.description || null,
      domain:          form.domain       || null,
      requirements:    form.requirements?.length ? form.requirements : null,
      contact_email:   form.contact_email  || null,
      is_active:       form.is_active,
    };

    let error;
    if (modal.program) {
      ({ error } = await supabase.from('programs').update(payload).eq('id', modal.program.id));
    } else {
      ({ error } = await supabase.from('programs').insert(payload));
    }

    setSaving(false);
    if (error) {
      setSaveError(error.message);
      return;
    }
    setModal({ open: false, program: null });
    fetchPrograms();
    showToast(modal.program ? 'Programme modifié avec succès' : 'Programme créé avec succès');
  }

  /* ─── Toggle actif / archiver ─── */
  async function handleToggleActive(p: Program) {
    const { error } = await supabase.from('programs').update({ is_active: !p.is_active }).eq('id', p.id);
    if (!error) {
      fetchPrograms();
      showToast(p.is_active ? `"${p.program_name}" archivé` : `"${p.program_name}" réactivé`);
    } else {
      showToast('Erreur lors de la mise à jour', 'error');
    }
  }

  /* ─── Supprimer ─── */
  async function handleDelete() {
    if (!deleteTarget) return;
    setDeleting(true);
    const { error } = await supabase.from('programs').delete().eq('id', deleteTarget.id);
    setDeleting(false);
    if (!error) {
      showToast(`"${deleteTarget.program_name}" supprimé définitivement`);
    } else {
      showToast('Erreur lors de la suppression', 'error');
    }
    setDeleteTarget(null);
    fetchPrograms();
  }

  /* ─── Render ─── */
  if (loading) return <LoadingSpinner />;

  return (
    <div>
      <PageHeader
        title="Programmes"
        subtitle={`${total} programme${total > 1 ? 's' : ''} · ${active} actif${active > 1 ? 's' : ''}`}
        actions={<Button onClick={() => setModal({ open: true, program: null })}>+ Nouveau programme</Button>}
      />

      {/* Stats */}
      <div className="pp-stat-grid">
        <StatCard label="Total programmes" value={total}    color={colors.blue}    iconKey="total"   />
        <StatCard label="Actifs"           value={active}   color={colors.success} iconKey="active"  />
        <StatCard label="Masters"          value={masters}  color="#7c3aed"        iconKey="master"  />
        <StatCard label="Licences"         value={licences} color={colors.warning} iconKey="licence" />
      </div>

      {/* Toolbar */}
      <div className="pp-toolbar-card">
      <div className="pp-toolbar">
        <div className="pp-search-wrap">
          <span className="pp-search-icon">🔍</span>
          <input
            className="pp-search"
            placeholder="Rechercher programme, université, pays…"
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        <select className="pp-select" value={filterLevel} onChange={e => setFilterLevel(e.target.value)}>
          <option value="">Tous les niveaux</option>
          {LEVELS.map(l => <option key={l.value} value={l.value}>{l.label}</option>)}
        </select>
        <select className="pp-select" value={filterCountry} onChange={e => setFilterCountry(e.target.value)}>
          <option value="">Tous les pays</option>
          {countries.map(c => <option key={c} value={c}>{c}</option>)}
        </select>
        <select className="pp-select" value={filterLang} onChange={e => setFilterLang(e.target.value)}>
          <option value="">Toutes les langues</option>
          {langs.map(l => <option key={l} value={l}>{l}</option>)}
        </select>
        <select className="pp-select" value={filterActive} onChange={e => setFilterActive(e.target.value as typeof filterActive)}>
          <option value="all">Tous</option>
          <option value="active">Actifs</option>
          <option value="inactive">Archivés</option>
        </select>
        {anyFilter && (
          <button
            onClick={() => { setSearch(''); setFilterLevel(''); setFilterCountry(''); setFilterLang(''); setFilterActive('all'); }}
            style={{ padding: '7px 13px', borderRadius: 8, border: `1.5px solid ${colors.borderInput}`, background: 'white', cursor: 'pointer', fontSize: 13, color: colors.textSecondary, whiteSpace: 'nowrap', fontFamily: fonts.body }}
          >
            ✕ Réinitialiser
          </button>
        )}
      </div>
      </div>

      {/* Table */}
      {filtered.length === 0 ? (
        <EmptyState
          icon="🎓"
          title="Aucun programme trouvé"
          description={search || filterLevel ? 'Essayez d\'autres filtres.' : 'Créez votre premier programme.'}
          action={!search && !filterLevel ? <Button onClick={() => setModal({ open: true, program: null })}>+ Nouveau programme</Button> : undefined}
        />
      ) : (
        <div className="pp-table-wrap">
          <table className="pp-table">
            <thead>
              <tr>
                <th>Programme</th>
                <th>Niveau</th>
                <th>Pays · Langue</th>
                <th>Durée</th>
                <th>Coût</th>
                <th>Deadline</th>
                <th>Statut</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {filtered.map(p => {
                const lvlCfg = p.level ? (LEVEL_CFG[p.level] ?? null) : null;
                const accentColor = lvlCfg?.color ?? colors.textMuted;
                const deadlineSoon = p.deadline
                  ? (new Date(p.deadline).getTime() - Date.now()) / 86400000 < 30
                  : false;
                const deadlinePast = p.deadline
                  ? new Date(p.deadline) < new Date()
                  : false;
                const deadlineColor = deadlinePast
                  ? colors.danger
                  : deadlineSoon ? colors.warning : colors.textPrimary;

                return (
                  <tr key={p.id}>
                    <td style={{ paddingLeft: 0 }}>
                      <div style={{ display: 'flex', alignItems: 'stretch', gap: 0 }}>
                        {/* accent gauche coloré */}
                        <div style={{ width: 3, borderRadius: '3px 0 0 3px', background: accentColor, marginRight: 14, flexShrink: 0 }} />
                        <div>
                          <button className="pp-prog-name" onClick={() => setDetailProgram(p)}>
                            {p.program_name}
                          </button>
                          <span className="pp-univ-name">🏛 {p.university_name}</span>
                        </div>
                      </div>
                    </td>
                    <td>
                      {lvlCfg && p.level ? (
                        <span className="pp-level-badge" style={{ color: lvlCfg.color, background: lvlCfg.bg }}>
                          {LEVEL_LABEL[p.level] ?? p.level}
                        </span>
                      ) : <span style={{ color: colors.textMuted }}>—</span>}
                    </td>
                    <td>
                      <div style={{ fontSize: 13, color: colors.textSecondary }}>
                        {p.country && <span>🌍 {p.country}</span>}
                      </div>
                      <div style={{ fontSize: 12, color: colors.textMuted, marginTop: 2 }}>
                        {p.language ?? ''}
                      </div>
                    </td>
                    <td style={{ color: colors.textSecondary, fontSize: 13 }}>
                      {p.duration ? `⏱ ${p.duration}` : '—'}
                    </td>
                    <td>
                      <span style={{
                        fontSize: 13, fontWeight: 600,
                        color: p.cost === 0 ? colors.success : p.cost ? colors.textPrimary : colors.textMuted,
                      }}>
                        {p.cost === 0 ? '🆓 Gratuit' : p.cost
                          ? `${new Intl.NumberFormat('fr-FR').format(p.cost)} €`
                          : '—'}
                      </span>
                    </td>
                    <td>
                      {p.deadline ? (
                        <span style={{ fontSize: 13, color: deadlineColor, fontWeight: deadlineSoon ? 600 : 400 }}>
                          {deadlinePast ? '⚠️ ' : deadlineSoon ? '🔔 ' : ''}{fmtDate(p.deadline)}
                        </span>
                      ) : <span style={{ color: colors.textMuted }}>—</span>}
                    </td>
                    <td>
                      <span
                        className="pp-active-badge"
                        style={p.is_active
                          ? { color: colors.success, background: 'rgba(22,163,74,0.10)' }
                          : { color: colors.textMuted, background: colors.inputBg }}
                      >
                        <span style={{ width: 6, height: 6, borderRadius: '50%', background: p.is_active ? colors.success : colors.textMuted, display: 'inline-block' }} />
                        {p.is_active ? 'Actif' : 'Archivé'}
                      </span>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: 5 }}>
                        <button
                          className="pp-action-btn pp-action-edit"
                          title="Modifier"
                          onClick={() => setModal({ open: true, program: p })}
                        >
                          <svg width={12} height={12} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                          </svg>
                          Modifier
                        </button>
                        <button
                          className={`pp-action-btn ${p.is_active ? 'pp-action-archive' : 'pp-action-restore'}`}
                          title={p.is_active ? 'Archiver' : 'Réactiver'}
                          onClick={() => handleToggleActive(p)}
                        >
                          {p.is_active ? (
                            <svg width={12} height={12} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path d="M21 8v13H3V8M1 3h22v5H1zM10 12h4"/></svg>
                          ) : (
                            <svg width={12} height={12} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/></svg>
                          )}
                          {p.is_active ? 'Archiver' : 'Réactiver'}
                        </button>
                        <button
                          className="pp-action-btn pp-action-delete"
                          title="Supprimer"
                          onClick={() => setDeleteTarget(p)}
                        >
                          <svg width={12} height={12} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                            <polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4h6v2"/>
                          </svg>
                          Supprimer
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Modal Détail */}
      {detailProgram && (
        <ProgramDetailModal
          program={detailProgram}
          onClose={() => setDetailProgram(null)}
          onEdit={() => {
            setModal({ open: true, program: detailProgram });
            setDetailProgram(null);
          }}
        />
      )}

      {/* Modal Création / Édition */}
      {modal.open && (
        <ProgramModal
          initial={modal.program
            ? {
                program_name:    modal.program.program_name,
                university_name: modal.program.university_name,
                country:         modal.program.country,
                language:        modal.program.language,
                level:           modal.program.level,
                duration:        modal.program.duration,
                cost:            modal.program.cost,
                deadline:        modal.program.deadline,
                description:     modal.program.description,
                domain:          modal.program.domain,
                requirements:    modal.program.requirements,
                contact_email:   modal.program.contact_email,
                is_active:       modal.program.is_active,
              }
            : EMPTY_FORM
          }
          onSave={handleSave}
          onClose={() => { setModal({ open: false, program: null }); setSaveError(null); }}
          saving={saving}
          error={saveError}
        />
      )}

      {/* Modal Suppression */}
      {deleteTarget && (
        <div className="pp-overlay" onClick={e => e.target === e.currentTarget && setDeleteTarget(null)}>
          <div className="pp-modal" style={{ maxWidth: 420 }}>
            <h2 style={{ margin: '0 0 12px', fontSize: 17, fontWeight: 700, fontFamily: fonts.display, color: colors.textPrimary }}>
              Supprimer définitivement ?
            </h2>
            <p style={{ margin: '0 0 6px', fontSize: 14, color: colors.textSecondary }}>
              <strong>{deleteTarget.program_name}</strong> — {deleteTarget.university_name}
            </p>
            <p style={{ margin: '0 0 4px', fontSize: 13, color: colors.textSecondary }}>
              💡 Si vous souhaitez seulement le masquer aux étudiants, utilisez plutôt <strong>Archiver</strong>.
            </p>
            <p style={{ margin: '0 0 24px', fontSize: 13, color: colors.danger }}>
              La suppression est définitive et irréversible.
            </p>
            <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
              <Button variant="secondary" onClick={() => setDeleteTarget(null)} disabled={deleting}>Annuler</Button>
              <Button
                onClick={handleDelete}
                disabled={deleting}
                style={{ background: colors.danger }}
              >
                {deleting ? 'Suppression...' : 'Supprimer définitivement'}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Toast */}
      {toast && (
        <div className={`pp-toast pp-toast-${toast.type}`}>
          <span>{toast.type === 'success' ? '✅' : '⚠️'}</span>
          {toast.message}
        </div>
      )}
    </div>
  );
}
