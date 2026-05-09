/**
 * theme.ts — Design tokens Studium
 * Source unique de vérité pour toute l'application.
 * Importer depuis n'importe quel composant : import { colors, fonts } from '@/shared/constants/theme'
 */

export const colors = {
  /* Marque */
  navy:        '#0b1852',
  navyLight:   '#1a2f8a',
  blue:        '#2546cc',
  blueLight:   '#4d7aff',
  blueFocus:   'rgba(37,70,204,0.15)',

  /* Fonds */
  pageBg:      '#eef0f7',
  cardBg:      '#ffffff',
  inputBg:     '#f5f7fc',
  sidebarBg:   '#0b1852',

  /* Textes */
  textPrimary:   '#0b1852',
  textSecondary: '#6b7a9e',
  textMuted:     '#9ba3bc',
  textInverse:   '#ffffff',

  /* Bordures */
  border:       'rgba(11,24,82,0.08)',
  borderInput:  '#dde1f0',
  borderHover:  '#c2cadf',

  /* Sémantiques */
  danger:       '#dc2626',
  dangerBg:     '#fef2f2',
  dangerBorder: '#fca5a5',
  success:      '#16a34a',
  warning:      '#d97706',

  /* Sidebar */
  sidebarText:        'rgba(255,255,255,0.60)',
  sidebarTextHover:   'rgba(255,255,255,0.90)',
  sidebarActive:      'rgba(255,255,255,0.12)',
  sidebarActiveBorder:'#4d7aff',
} as const;

export const fonts = {
  display: "'Bricolage Grotesque', sans-serif",
  body:    "'Plus Jakarta Sans', sans-serif",
} as const;

export const radius = {
  sm:   6,
  md:   10,
  lg:   14,
  xl:   20,
  full: 9999,
} as const;

export const shadows = {
  card: '0 1px 4px rgba(11,24,82,0.04), 0 8px 24px rgba(11,24,82,0.07), 0 28px 60px rgba(11,24,82,0.08)',
  btn:  '0 8px 28px rgba(11,24,82,0.28)',
} as const;

/* Injection Google Fonts (une seule fois) */
if (typeof document !== 'undefined' && !document.getElementById('studium-fonts')) {
  const l = document.createElement('link');
  l.id   = 'studium-fonts';
  l.rel  = 'stylesheet';
  l.href = 'https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,700;12..96,800&family=Plus+Jakarta+Sans:wght@400;500;600&display=swap';
  document.head.appendChild(l);
}