import { useState, useEffect, useMemo, useCallback, useRef, type ReactNode } from 'react';
import { supabase }       from '../../../shared/services/supabase';
import { Button }         from '../../../shared/components/Button';
import { PageHeader }     from '../../../shared/components/PageHeader';
import { Pagination }     from '../../../shared/components/Pagination';
import { LoadingSpinner } from '../../../shared/components/LoadingSpinner';
import { EmptyState }     from '../../../shared/components/EmptyState';
import { colors, fonts, radius, shadows } from '../../../shared/constants/theme';
import { downloadCsv }    from '../../../shared/utils/export_csv';
import { useRole }        from '../../auth/hooks/useRole';
import { can }            from '../../auth/hooks/permissions';

/*  Types  */
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
  cc_emails:       string | null;
  is_active:       boolean;
  created_at:      string | null;
  min_average:             number | null;
  required_language_level: string | null;
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
  cc_emails:       '',
  is_active:       true,
  min_average:             null,
  required_language_level: '',
};

// Niveaux CECR — s'applique a la langue du programme (champ "Langue")
const LANGUAGE_LEVELS: { value: string; label: string }[] = [
  { value: 'A1', label: 'A1 — Debutant'      },
  { value: 'A2', label: 'A2 — Elementaire'   },
  { value: 'B1', label: 'B1 — Intermediaire' },
  { value: 'B2', label: 'B2 — Intermediaire avance' },
  { value: 'C1', label: 'C1 — Avance'        },
  { value: 'C2', label: 'C2 — Maitrise'      },
];

const LANGUAGE_LEVEL_LABEL: Record<string, string> =
  Object.fromEntries(LANGUAGE_LEVELS.map(l => [l.value, l.label]));

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
  { symbol: '',  code: 'EUR', label: 'EUR  Euro'             },
  { symbol: '$', code: 'USD', label: 'USD  Dollar américain' },
];

const LEVEL_CFG: Record<string, { color: string; bg: string }> = {
  bachelor: { color: colors.blue,    bg: 'rgba(37,70,204,0.10)'   },
  master:   { color: '#7c3aed',      bg: 'rgba(124,58,237,0.10)'  },
  phd:      { color: colors.success, bg: 'rgba(22,163,74,0.10)'   },
};

/*  CSS  */
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

  .pp-table-wrap { overflow-x: auto; }

  .pp-card {
    border-radius: ${radius.lg}px;
    box-shadow: ${shadows.card};
    overflow: hidden;
  }

  .pp-table {
    width: 100%;
    border-collapse: collapse;
    background: white;
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
  .pp-table tbody tr:hover td { background: #f5f7ff; }

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

  .pp-icon-btn {
    width: 32px; height: 32px;
    border-radius: 8px;
    border: 1.5px solid ${colors.border};
    background: white;
    display: inline-flex; align-items: center; justify-content: center;
    cursor: pointer;
    transition: all .15s;
    flex-shrink: 0;
  }
  .pp-icon-btn:hover { border-color: transparent; transform: translateY(-1px); box-shadow: 0 3px 10px rgba(0,0,0,0.10); }
  .pp-action-edit  { color: ${colors.blue}; }
  .pp-action-edit:hover  { background: rgba(37,70,204,0.08); color: ${colors.blue}; }
  .pp-action-archive { color: ${colors.warning}; }
  .pp-action-archive:hover { background: rgba(217,119,6,0.08); color: ${colors.warning}; }
  .pp-action-restore { color: ${colors.success}; }
  .pp-action-restore:hover { background: rgba(22,163,74,0.08); color: ${colors.success}; }
  .pp-action-delete { color: ${colors.danger}; }
  .pp-action-delete:hover { background: rgba(220,38,38,0.08); color: ${colors.danger}; }

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

  /*  Cost input group  */
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

  /*  Section divider  */
  .pp-section-sep {
    grid-column: 1 / -1;
    border: none;
    border-top: 1px solid ${colors.border};
    margin: 2px 0;
  }
  .pp-section-label {
    grid-column: 1 / -1;
    font-size: 10.5px;
    font-weight: 700;
    color: ${colors.textMuted};
    text-transform: uppercase;
    letter-spacing: .6px;
    margin-top: 2px;
  }

  /*  Tag input (documents requis)  */
  .pp-tags-wrap {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    align-items: center;
    padding: 8px 10px;
    border: 1.5px solid ${colors.borderInput};
    border-radius: ${radius.md}px;
    background: ${colors.inputBg};
    transition: border-color .18s;
    min-height: 42px;
  }
  .pp-tags-wrap:focus-within { border-color: ${colors.blue}; background: white; }
  .pp-tag {
    display: inline-flex; align-items: center; gap: 5px;
    padding: 3px 10px 3px 10px;
    background: rgba(37,70,204,0.09); color: ${colors.blue};
    border-radius: 20px; font-size: 12px; font-weight: 600; font-family: ${fonts.body};
  }
  .pp-tag-x {
    background: none; border: none; cursor: pointer; padding: 0; line-height: 1;
    color: ${colors.blue}; opacity: .7; display: flex; align-items: center;
  }
  .pp-tag-x:hover { opacity: 1; }
  .pp-tag-field {
    border: none; outline: none; background: transparent;
    font-size: 13px; font-family: ${fonts.body}; color: ${colors.textPrimary};
    flex: 1; min-width: 140px;
  }
  .pp-tag-hint { font-size: 11px; color: ${colors.textMuted}; margin-top: 4px; }

  /*  Toggle switch  */
  .pp-toggle-row {
    grid-column: 1 / -1;
    display: flex; align-items: center; justify-content: space-between;
    padding: 12px 14px; border-radius: 10px;
    border: 1.5px solid ${colors.borderInput};
    background: ${colors.inputBg};
    transition: all .15s;
  }
  .pp-toggle-row.active { background: rgba(22,163,74,0.05); border-color: ${colors.success}; }
  .pp-toggle-label { font-size: 13px; font-weight: 600; color: ${colors.textPrimary}; }
  .pp-toggle-sub { font-size: 11.5px; color: ${colors.textMuted}; margin-top: 1px; }
  .pp-toggle { position: relative; display: inline-block; width: 40px; height: 22px; flex-shrink: 0; }
  .pp-toggle input { opacity: 0; width: 0; height: 0; }
  .pp-toggle-track {
    position: absolute; inset: 0; border-radius: 11px;
    background: ${colors.borderInput}; cursor: pointer; transition: background .2s;
  }
  .pp-toggle input:checked + .pp-toggle-track { background: ${colors.success}; }
  .pp-toggle-track::after {
    content: ''; position: absolute; width: 16px; height: 16px;
    border-radius: 50%; background: white; top: 3px; left: 3px;
    transition: transform .2s; box-shadow: 0 1px 3px rgba(0,0,0,.2);
  }
  .pp-toggle input:checked + .pp-toggle-track::after { transform: translateX(18px); }

  /*  Toast  */
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

  /*  Detail modal  */
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

  .pp-stat-grid > div:nth-child(1) { animation: ph-fade-up .35s .08s ease both; }
  .pp-stat-grid > div:nth-child(2) { animation: ph-fade-up .35s .16s ease both; }
  .pp-stat-grid > div:nth-child(3) { animation: ph-fade-up .35s .24s ease both; }
  .pp-stat-grid > div:nth-child(4) { animation: ph-fade-up .35s .32s ease both; }
  .pp-toolbar-card { animation: ph-fade-up .35s .40s ease both; }
  .pp-card         { animation: ph-fade-up .35s .48s ease both; }
`;

function injectCSS() {
  if (typeof document === 'undefined') return;
  if (document.getElementById('pp-styles')) return;
  const s = document.createElement('style');
  s.id = 'pp-styles';
  s.textContent = CSS;
  document.head.appendChild(s);
}

/*  Helpers  */
function fmtCost(cost: number | null) {
  if (cost == null) return '';
  if (cost === 0) return 'Gratuit';
  return new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 0 }).format(cost);
}

function fmtDate(d: string | null) {
  if (!d) return '';
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
      padding: '18px 20px',
      display: 'flex',
      alignItems: 'center',
      gap: 16,
      borderLeft: `4px solid ${color}`,
    }}>
      <div style={{
        width: 44, height: 44, borderRadius: 12, flexShrink: 0,
        background: color + '15',
        color,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {STAT_ICONS[iconKey]}
      </div>
      <div>
        <div style={{ fontSize: 28, fontWeight: 800, color: colors.navy, fontFamily: fonts.display, lineHeight: 1 }}>{value}</div>
        <div style={{ fontSize: 12, color: colors.textMuted, marginTop: 5, fontWeight: 500, letterSpacing: '.01em' }}>{label}</div>
      </div>
    </div>
  );
}

/*  Detail Modal  */
function ProgramDetailModal({ program, onClose, onEdit }: {
  program: Program;
  onClose: () => void;
  onEdit?: () => void;
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
            <div style={{ fontSize: 14, color: colors.textSecondary }}>{program.university_name}</div>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', fontSize: 20, cursor: 'pointer', color: colors.textMuted, flexShrink: 0 }}></button>
        </div>

        <div className="pp-detail-grid">
          {[
            ['Pays',     program.country   ?? ''],
            ['Langue',   program.language  ?? ''],
            ['Durée',    program.duration  ?? ''],
            ['Coût',     fmtCost(program.cost)],
            ['Deadline', fmtDate(program.deadline)],
            ['Moyenne min.', program.min_average != null ? `${program.min_average}/20` : 'Non précisée'],
            ['Langue requise', program.required_language_level ? (LANGUAGE_LEVEL_LABEL[program.required_language_level] ?? program.required_language_level) : 'Aucun prérequis'],
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

        {program.cc_emails && program.cc_emails.trim() && (
          <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: colors.textSecondary, textTransform: 'uppercase', letterSpacing: '.4px', minWidth: 80 }}>CC</div>
            <span style={{ fontSize: 13.5, color: colors.textPrimary }}>{program.cc_emails}</span>
          </div>
        )}

        <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end', marginTop: 24 }}>
          <Button variant="secondary" onClick={onClose}>Fermer</Button>
          {onEdit && <Button onClick={onEdit}>Modifier</Button>}
        </div>
      </div>
    </div>
  );
}

/*  Modal Form  */
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
  const isEdit = !!initial.program_name;

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
      <div className="pp-modal" style={{ maxWidth: 620 }}>

        {/* Bande couleur + header */}
        <div style={{
          margin: '-28px -28px 24px',
          padding: '20px 24px 18px',
          background: `linear-gradient(135deg, ${colors.navy} 0%, #1e3a8a 100%)`,
          borderRadius: '16px 16px 0 0',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 600, color: 'rgba(255,255,255,0.55)', letterSpacing: '.6px', textTransform: 'uppercase', marginBottom: 4 }}>
              {isEdit ? 'Modification' : 'Creation'}
            </div>
            <h2 style={{ margin: 0, fontSize: 17, fontWeight: 800, fontFamily: fonts.display, color: 'white', lineHeight: 1.2 }}>
              {isEdit ? initial.program_name : 'Nouveau programme'}
            </h2>
          </div>
          <button onClick={onClose} style={{
            background: 'rgba(255,255,255,0.12)', border: '1.5px solid rgba(255,255,255,0.18)',
            borderRadius: 8, width: 34, height: 34, cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: 'white', flexShrink: 0, transition: 'background .15s',
          }}>
            <svg width={13} height={13} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5} strokeLinecap="round">
              <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>

        <div className="pp-form-grid">
          {/* Nom */}
          <div className="pp-field pp-form-full">
            <label className="pp-label">Nom du programme <span style={{ color: colors.danger }}>*</span></label>
            <input
              className={`pp-input${submitted && nameEmpty ? ' error' : ''}`}
              placeholder="Ex : Master Informatique"
              value={form.program_name}
              onChange={e => set('program_name', e.target.value)}
            />
            {submitted && nameEmpty && <span className="pp-field-error">Ce champ est obligatoire</span>}
          </div>

          {/* Universite */}
          <div className="pp-field pp-form-full">
            <label className="pp-label">Universite <span style={{ color: colors.danger }}>*</span></label>
            <input
              className={`pp-input${submitted && univEmpty ? ' error' : ''}`}
              placeholder="Ex : Universite Paris-Saclay"
              value={form.university_name}
              onChange={e => set('university_name', e.target.value)}
            />
            {submitted && univEmpty && <span className="pp-field-error">Ce champ est obligatoire</span>}
          </div>

          {/* Niveau / Pays */}
          <div className="pp-field">
            <label className="pp-label">Niveau</label>
            <select className="pp-form-select" value={form.level ?? ''} onChange={e => set('level', e.target.value || null)}>
              <option value="">Selectionner</option>
              {LEVELS.map(l => <option key={l.value} value={l.value}>{l.label}</option>)}
            </select>
          </div>
          <div className="pp-field">
            <label className="pp-label">Pays</label>
            <select className="pp-form-select" value={form.country ?? ''} onChange={e => set('country', e.target.value || null)}>
              <option value="">Selectionner</option>
              {COUNTRIES.map(c => <option key={c} value={c}>{c}</option>)}
            </select>
          </div>

          {/* Langue / Duree */}
          <div className="pp-field">
            <label className="pp-label">Langue</label>
            <select className="pp-form-select" value={form.language ?? ''} onChange={e => set('language', e.target.value || null)}>
              <option value="">Selectionner</option>
              {LANGUAGES.map(l => <option key={l} value={l}>{l}</option>)}
            </select>
          </div>
          <div className="pp-field">
            <label className="pp-label">Duree</label>
            <select className="pp-form-select" value={form.duration ?? ''} onChange={e => set('duration', e.target.value || null)}>
              <option value="">Selectionner</option>
              {DURATIONS.map(d => <option key={d} value={d}>{d}</option>)}
            </select>
          </div>

          {/* Cout / Deadline */}
          <div className="pp-field">
            <label className="pp-label" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span>Cout</span>
              <button type="button" className={`pp-gratuit-btn${isGratuit ? ' active' : ''}`} onClick={() => set('cost', isGratuit ? null : 0)}>
                {isGratuit ? 'Gratuit' : 'Gratuit ?'}
              </button>
            </label>
            {!isGratuit ? (
              <div className="pp-cost-group">
                <select className="pp-cost-currency" value={costCurrency} onChange={e => setCostCurrency(e.target.value)}>
                  {CURRENCIES.map(c => <option key={c.code} value={c.code}>{c.symbol} {c.code}</option>)}
                </select>
                <input
                  className="pp-cost-amount" type="number" min={1} placeholder="Ex : 5 000"
                  value={form.cost ?? ''}
                  onChange={e => set('cost', e.target.value ? Number(e.target.value) : null)}
                />
              </div>
            ) : (
              <div style={{ padding: '9px 12px', background: 'rgba(22,163,74,0.06)', border: `1.5px solid ${colors.success}`, borderRadius: radius.md, fontSize: 13.5, color: colors.success, fontWeight: 600 }}>
                Programme gratuit
              </div>
            )}
          </div>
          <div className="pp-field">
            <label className="pp-label">Date limite candidature</label>
            <input className="pp-input" type="date" value={form.deadline ?? ''} onChange={e => set('deadline', e.target.value || null)} />
          </div>

          {/* Description pleine largeur */}
          <div className="pp-field pp-form-full">
            <label className="pp-label">Description</label>
            <textarea className="pp-textarea" placeholder="Presentation du programme, debouches, points forts..." rows={3} value={form.description ?? ''} onChange={e => set('description', e.target.value || null)} />
          </div>

          {/* Domaine / Email */}
          <div className="pp-field">
            <label className="pp-label">Domaine</label>
            <select className="pp-form-select" value={form.domain ?? ''} onChange={e => set('domain', e.target.value || null)}>
              <option value="">Selectionner</option>
              {DOMAINS.map(d => <option key={d} value={d}>{d}</option>)}
            </select>
          </div>
          <div className="pp-field">
            <label className="pp-label">Email de contact</label>
            <input className="pp-input" type="email" placeholder="Ex : admissions@universite.fr" value={form.contact_email ?? ''} onChange={e => set('contact_email', e.target.value || null)} />
          </div>
          <div className="pp-field">
            <label className="pp-label">
              CC
              <span style={{ fontWeight: 400, color: colors.textMuted, marginLeft: 6, fontSize: 11 }}>(emails separes par des virgules)</span>
            </label>
            <input className="pp-input" type="text" placeholder="Ex : doyen@universite.fr, secretariat@universite.fr" value={form.cc_emails ?? ''} onChange={e => set('cc_emails', e.target.value || null)} />
          </div>

          {/* Eligibilite : moyenne minimale / niveau de langue requis */}
          <div className="pp-field">
            <label className="pp-label">
              Moyenne minimale requise
              <span style={{ fontWeight: 400, color: colors.textMuted, marginLeft: 6, fontSize: 11 }}>(sur 20, optionnel)</span>
            </label>
            <input
              className="pp-input" type="number" min={0} max={20} step={0.25}
              placeholder="Ex : 14"
              value={form.min_average ?? ''}
              onChange={e => set('min_average', e.target.value ? Number(e.target.value) : null)}
            />
          </div>
          <div className="pp-field">
            <label className="pp-label">Niveau de langue requis</label>
            <select className="pp-form-select" value={form.required_language_level ?? ''} onChange={e => set('required_language_level', e.target.value || null)}>
              <option value="">Aucun prerequis</option>
              {LANGUAGE_LEVELS.map(l => <option key={l.value} value={l.value}>{l.label}</option>)}
            </select>
          </div>

          {/* Documents requis */}
          <div className="pp-field pp-form-full">
            <label className="pp-label">
              Documents requis
              <span style={{ fontWeight: 400, color: colors.textMuted, marginLeft: 6, fontSize: 11 }}>(un par ligne)</span>
            </label>
            <textarea
              className="pp-textarea"
              rows={4}
              placeholder={"CV\nReleve de notes\nLettre de motivation\nPasseport"}
              value={form.requirements?.join('\n') ?? ''}
              onChange={e => {
                const lines = e.target.value.split('\n').map(l => l.trim()).filter(Boolean);
                set('requirements', lines.length ? lines : null);
              }}
            />
          </div>

        </div>

        {error && (
          <div style={{ marginTop: 16, padding: '10px 14px', background: '#fef2f2', border: '1px solid #fca5a5', borderRadius: radius.md, fontSize: 13, color: colors.danger }}>
            {error}
          </div>
        )}

        {/* Footer */}
        <div style={{
          display: 'flex', gap: 10, justifyContent: 'flex-end',
          marginTop: 20, paddingTop: 16, borderTop: `1px solid ${colors.border}`,
        }}>
          <Button variant="secondary" onClick={onClose} disabled={saving}>Annuler</Button>
          <Button onClick={handleSubmit} disabled={saving}>
            {saving ? 'Enregistrement...' : isEdit ? 'Enregistrer les modifications' : 'Creer le programme'}
          </Button>
        </div>
      </div>
    </div>
  );
}

/*  Page principale  */
export default function ProgramsPage() {
  injectCSS();

  const { role } = useRole();
  const canWrite = can(role, 'programs:write');

  const [programs, setPrograms] = useState<Program[]>([]);
  const [loading,  setLoading]  = useState(true);
  const [search,   setSearch]   = useState('');
  const [filterLevel,   setFilterLevel]   = useState('');
  const [filterCountry, setFilterCountry] = useState('');
  const [filterLang,    setFilterLang]    = useState('');
  const [filterActive,  setFilterActive]  = useState<'all' | 'active' | 'inactive'>('all');

  const [page,     setPage]     = useState(1);
  const [pageSize, setPageSize] = useState(10);
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

  /*  Fetch  */
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

  /*  Valeurs dynamiques pour les selects  */
  const countries = useMemo(() =>
    [...new Set(programs.map(p => p.country).filter(Boolean) as string[])].sort()
  , [programs]);

  const langs = useMemo(() =>
    [...new Set(programs.map(p => p.language).filter(Boolean) as string[])].sort()
  , [programs]);

  const anyFilter = search || filterLevel || filterCountry || filterLang || filterActive !== 'all';

  /*  Filtres  */
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

  useEffect(() => setPage(1), [search, filterLevel, filterCountry, filterLang, filterActive]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const paginated  = filtered.slice((page - 1) * pageSize, page * pageSize);

  /*  Stats  */
  const total    = programs.length;
  const active   = programs.filter(p => p.is_active).length;
  const masters  = programs.filter(p => p.level === 'master').length;
  const licences = programs.filter(p => p.level === 'bachelor').length;

  /*  Save (create / update)  */
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
      cc_emails:       form.cc_emails      || null,
      is_active:       form.is_active,
      min_average:             form.min_average ?? null,
      required_language_level: form.required_language_level || null,
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

  /*  Toggle actif / archiver  */
  async function handleToggleActive(p: Program) {
    const { error } = await supabase.from('programs').update({ is_active: !p.is_active }).eq('id', p.id);
    if (!error) {
      fetchPrograms();
      showToast(p.is_active ? `"${p.program_name}" archivé` : `"${p.program_name}" réactivé`);
    } else {
      showToast('Erreur lors de la mise à jour', 'error');
    }
  }

  /*  Supprimer  */
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

  /*  Export / Import CSV  */
  const importRef = useRef<HTMLInputElement>(null);
  const [importLoading, setImportLoading] = useState(false);

  function handleExportCsv() {
    const rows = filtered.map(p => ({
      programme:     p.program_name,
      universite:    p.university_name,
      pays:          p.country        ?? '',
      langue:        p.language       ?? '',
      niveau:        p.level          ?? '',
      duree:         p.duration       ?? '',
      cout:          p.cost           ?? '',
      deadline:      p.deadline       ?? '',
      description:   p.description    ?? '',
      domaine:       p.domain         ?? '',
      exigences:     (p.requirements  ?? []).join(' | '),
      email_contact: p.contact_email  ?? '',
      cc:            p.cc_emails      ?? '',
      moyenne_min:   p.min_average    ?? '',
      niveau_langue_requis: p.required_language_level ?? '',
      actif:         p.is_active ? 'oui' : 'non',
    }));
    downloadCsv(`programmes_${new Date().toISOString().split('T')[0]}.csv`, rows);
  }

  function parseCsvLine(line: string): string[] {
    const result: string[] = [];
    let cur = ''; let inQuote = false;
    for (let i = 0; i < line.length; i++) {
      const ch = line[i];
      if (ch === '"') {
        if (inQuote && line[i + 1] === '"') { cur += '"'; i++; }
        else { inQuote = !inQuote; }
      } else if (ch === ',' && !inQuote) {
        result.push(cur); cur = '';
      } else { cur += ch; }
    }
    result.push(cur);
    return result;
  }

  async function handleImportCsv(file: File) {
    setImportLoading(true);
    try {
      const text    = await file.text();
      const lines   = text.split('\n').map(l => l.trim()).filter(Boolean);
      if (lines.length < 2) { showToast('Fichier vide ou sans données', 'error'); return; }

      const headers = parseCsvLine(lines[0]).map(h => h.toLowerCase().trim());
      const get     = (obj: Record<string, string>, ...keys: string[]) =>
        keys.reduce<string>((acc, k) => acc || (obj[k] ?? ''), '').trim();

      const inserts = lines.slice(1).map(line => {
        const vals: Record<string, string> = {};
        parseCsvLine(line).forEach((v, i) => { if (headers[i]) vals[headers[i]] = v.trim(); });
        const costRaw = get(vals, 'cout', 'cost');
        const avgRaw  = get(vals, 'moyenne_min', 'min_average');
        return {
          program_name:    get(vals, 'programme', 'program_name'),
          university_name: get(vals, 'universite', 'university_name'),
          country:         get(vals, 'pays', 'country')        || null,
          language:        get(vals, 'langue', 'language')     || null,
          level:           get(vals, 'niveau', 'level')        || null,
          duration:        get(vals, 'duree', 'duration')      || null,
          cost:            costRaw ? (Number(costRaw) || null) : null,
          deadline:        get(vals, 'deadline')               || null,
          description:     get(vals, 'description')            || null,
          domain:          get(vals, 'domaine', 'domain')      || null,
          requirements:    get(vals, 'exigences', 'requirements')
                             .split('|').map(s => s.trim()).filter(Boolean),
          contact_email:   get(vals, 'email_contact', 'contact_email') || null,
          cc_emails:       get(vals, 'cc', 'cc_emails') || null,
          min_average:             avgRaw ? (Number(avgRaw) || null) : null,
          required_language_level: get(vals, 'niveau_langue_requis', 'required_language_level') || null,
          is_active:       get(vals, 'actif', 'is_active').toLowerCase() !== 'non',
        };
      }).filter(r => r.program_name && r.university_name);

      if (!inserts.length) {
        showToast('Aucune ligne valide (colonnes "programme" et "universite" requises)', 'error');
        return;
      }

      const { error } = await supabase.from('programs').insert(inserts);
      if (error) {
        showToast(`Erreur import : ${error.message}`, 'error');
      } else {
        showToast(`${inserts.length} programme${inserts.length > 1 ? 's' : ''} importé${inserts.length > 1 ? 's' : ''}`);
        fetchPrograms();
      }
    } finally {
      setImportLoading(false);
    }
  }

  /*  Render  */
  if (loading) return <LoadingSpinner />;

  return (
    <div>
      <PageHeader
        title="Programmes"
        subtitle={`${total} programme${total > 1 ? 's' : ''} · ${active} actif${active > 1 ? 's' : ''}`}
        actions={
          <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
            <Button variant="secondary" onClick={handleExportCsv} disabled={!filtered.length}>
              Export CSV
            </Button>
            {canWrite && (
              <label style={{ cursor: importLoading ? 'not-allowed' : 'pointer' }}>
                <Button
                  variant="secondary"
                  loading={importLoading}
                  onClick={() => importRef.current?.click()}
                >
                  Import CSV
                </Button>
                <input
                  ref={importRef}
                  type="file"
                  accept=".csv"
                  style={{ display: 'none' }}
                  onChange={e => { const f = e.target.files?.[0]; if (f) handleImportCsv(f); e.target.value = ''; }}
                />
              </label>
            )}
            {canWrite && (
              <Button onClick={() => setModal({ open: true, program: null })}>+ Nouveau programme</Button>
            )}
          </div>
        }
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
          <span className="pp-search-icon" style={{ display:'flex' }}><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg></span>
          <input
            className="pp-search"
            placeholder="Rechercher programme, université, pays"
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
             Réinitialiser
          </button>
        )}
      </div>
      </div>

      {/* Table */}
      {filtered.length === 0 ? (
        <EmptyState
          icon={<svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/></svg>}
          title="Aucun programme trouvé"
          description={search || filterLevel ? 'Essayez d\'autres filtres.' : 'Créez votre premier programme.'}
          action={!search && !filterLevel && canWrite ? <Button onClick={() => setModal({ open: true, program: null })}>+ Nouveau programme</Button> : undefined}
        />
      ) : (
        <div className="pp-card">
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
              {paginated.map(p => {
                const lvlCfg = p.level ? (LEVEL_CFG[p.level] ?? null) : null;
                const today = new Date(); today.setHours(0,0,0,0);
                const dl = p.deadline ? new Date(p.deadline) : null;
                const deadlinePast = dl ? dl < today : false;
                const deadlineSoon = dl && !deadlinePast
                  ? (dl.getTime() - today.getTime()) / 86400000 < 30
                  : false;

                return (
                  <tr key={p.id} style={{ cursor: 'pointer' }} onClick={() => setDetailProgram(p)}>
                    <td>
                      <button className="pp-prog-name">
                        {p.program_name}
                      </button>
                      <span className="pp-univ-name">{p.university_name}</span>
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
                        {p.country || '—'}
                      </div>
                      <div style={{ fontSize: 12, color: colors.textMuted, marginTop: 2 }}>
                        {p.language ?? ''}
                      </div>
                    </td>
                    <td style={{ color: colors.textSecondary, fontSize: 13 }}>
                      {p.duration ?? '—'}
                    </td>
                    <td>
                      {p.cost === 0 ? (
                        <span style={{ fontSize: 12, fontWeight: 700, color: colors.success, background: 'rgba(22,163,74,0.08)', padding: '2px 8px', borderRadius: 20 }}>
                          Gratuit
                        </span>
                      ) : p.cost ? (
                        <span style={{ fontSize: 13, fontWeight: 600, color: colors.textPrimary }}>
                          {new Intl.NumberFormat('fr-FR').format(p.cost)}
                          <span style={{ fontSize: 11, fontWeight: 500, color: colors.textMuted, marginLeft: 3 }}>EUR</span>
                        </span>
                      ) : (
                        <span style={{ color: colors.textMuted }}>—</span>
                      )}
                    </td>
                    <td>
                      {p.deadline ? (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                          <span style={{
                            fontSize: 13,
                            color: deadlinePast ? colors.textMuted : deadlineSoon ? colors.warning : colors.textPrimary,
                            fontWeight: deadlineSoon ? 600 : 400,
                            textDecoration: deadlinePast ? 'line-through' : 'none',
                          }}>
                            {fmtDate(p.deadline)}
                          </span>
                          {deadlinePast && (
                            <span style={{ fontSize: 10.5, fontWeight: 700, color: colors.danger, background: 'rgba(220,38,38,0.08)', padding: '1px 6px', borderRadius: 4, width: 'fit-content' }}>
                              Expirée
                            </span>
                          )}
                          {deadlineSoon && (
                            <span style={{ fontSize: 10.5, fontWeight: 700, color: colors.warning, background: 'rgba(217,119,6,0.08)', padding: '1px 6px', borderRadius: 4, width: 'fit-content' }}>
                              Bientôt
                            </span>
                          )}
                        </div>
                      ) : <span style={{ color: colors.textMuted }}>—</span>}
                    </td>
                    <td>
                      <span
                        className="pp-active-badge"
                        style={p.is_active
                          ? { color: colors.success, background: 'rgba(22,163,74,0.10)' }
                          : { color: colors.textMuted, background: colors.inputBg }}
                      >
                        <span style={{ width: 6, height: 6, borderRadius: '50%', background: p.is_active ? colors.success : colors.textMuted, display: 'inline-block', flexShrink: 0 }} />
                        {p.is_active ? 'Actif' : 'Archivé'}
                      </span>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: 4, justifyContent: 'flex-end', alignItems: 'center' }}>
                        {canWrite ? (
                          <>
                            <button
                              className="pp-icon-btn pp-action-edit"
                              title="Modifier"
                              onClick={e => { e.stopPropagation(); setModal({ open: true, program: p }); }}
                            >
                              <svg width={14} height={14} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
                                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                              </svg>
                            </button>
                            <button
                              className={`pp-icon-btn ${p.is_active ? 'pp-action-archive' : 'pp-action-restore'}`}
                              title={p.is_active ? 'Archiver' : 'Réactiver'}
                              onClick={e => { e.stopPropagation(); handleToggleActive(p); }}
                            >
                              {p.is_active ? (
                                <svg width={14} height={14} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path d="M21 8v13H3V8M1 3h22v5H1zM10 12h4"/></svg>
                              ) : (
                                <svg width={14} height={14} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/></svg>
                              )}
                            </button>
                            <button
                              className="pp-icon-btn pp-action-delete"
                              title="Supprimer"
                              onClick={e => { e.stopPropagation(); setDeleteTarget(p); }}
                            >
                              <svg width={14} height={14} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                                <polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4h6v2"/>
                              </svg>
                            </button>
                          </>
                        ) : (
                          <span style={{ color: colors.textMuted, fontSize: 11.5 }}>Lecture seule</span>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          </div>
          <Pagination
            page={page}
            totalPages={totalPages}
            total={filtered.length}
            pageSize={pageSize}
            onChange={setPage}
            onPageSizeChange={size => { setPageSize(size); setPage(1); }}
            label="programmes"
          />
        </div>
      )}

      {/* Modal Détail */}
      {detailProgram && (
        <ProgramDetailModal
          program={detailProgram}
          onClose={() => setDetailProgram(null)}
          onEdit={canWrite ? () => {
            setModal({ open: true, program: detailProgram });
            setDetailProgram(null);
          } : undefined}
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
                cc_emails:       modal.program.cc_emails,
                is_active:       modal.program.is_active,
                min_average:             modal.program.min_average,
                required_language_level: modal.program.required_language_level,
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
              <strong>{deleteTarget.program_name}</strong>  {deleteTarget.university_name}
            </p>
            <p style={{ margin: '0 0 4px', fontSize: 13, color: colors.textSecondary }}>
               Si vous souhaitez seulement le masquer aux étudiants, utilisez plutôt <strong>Archiver</strong>.
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
          <span style={{ display:'flex' }}>{toast.type === 'success'
            ? <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
            : <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
          }</span>
          {toast.message}
        </div>
      )}
    </div>
  );
}
