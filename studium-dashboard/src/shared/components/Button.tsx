/**
 * Button.tsx — Bouton réutilisable Studium
 * Variantes : primary | secondary | danger | ghost
 * Tailles    : sm | md | lg
 */
import { colors, fonts, radius } from '../constants/theme';

type Variant = 'primary' | 'secondary' | 'danger' | 'ghost';
type Size    = 'sm' | 'md' | 'lg';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?:  Variant;
  size?:     Size;
  loading?:  boolean;
  iconLeft?: React.ReactNode;
  iconRight?: React.ReactNode;
  fullWidth?: boolean;
}

const CSS = `
  .st-btn-base {
    display: inline-flex; align-items: center; justify-content: center; gap: 8px;
    font-family: ${fonts.display}; font-weight: 700; border: none; border-radius: ${radius.md}px;
    cursor: pointer; transition: background .18s, box-shadow .18s, transform .1s, opacity .18s;
    -webkit-tap-highlight-color: transparent; white-space: nowrap;
    text-decoration: none;
  }
  .st-btn-base:disabled { opacity: .5; cursor: not-allowed; pointer-events: none; }
  .st-btn-base:focus-visible { outline: 3px solid ${colors.blueLight}; outline-offset: 3px; }
  .st-btn-base:not(:disabled):active { transform: scale(0.97); }

  /* Variants */
  .st-btn-primary   { background: ${colors.navy}; color: #fff; }
  .st-btn-primary:not(:disabled):hover   { background: ${colors.navyLight}; box-shadow: 0 6px 20px rgba(11,24,82,0.28); }
  .st-btn-secondary { background: ${colors.inputBg}; color: ${colors.textPrimary}; border: 1.5px solid ${colors.borderInput}; }
  .st-btn-secondary:not(:disabled):hover { background: #e4e8f4; border-color: ${colors.borderHover}; }
  .st-btn-danger    { background: ${colors.danger}; color: #fff; }
  .st-btn-danger:not(:disabled):hover    { background: #b91c1c; box-shadow: 0 6px 20px rgba(185,28,28,0.28); }
  .st-btn-ghost     { background: transparent; color: ${colors.textSecondary}; }
  .st-btn-ghost:not(:disabled):hover     { background: ${colors.inputBg}; color: ${colors.textPrimary}; }

  /* Sizes */
  .st-btn-sm { font-size: 13px; padding: 7px 14px;  min-height: 34px; }
  .st-btn-md { font-size: 14px; padding: 10px 20px; min-height: 42px; }
  .st-btn-lg { font-size: 15px; padding: 13px 26px; min-height: 50px; }
  .st-btn-full { width: 100%; }

  @keyframes st-btn-spin { to { transform: rotate(360deg); } }
  .st-btn-spinner {
    width: 15px; height: 15px; border-radius: 50%;
    border: 2px solid rgba(255,255,255,0.3); border-top-color: #fff;
    animation: st-btn-spin .65s linear infinite; flex-shrink: 0;
  }
  .st-btn-secondary .st-btn-spinner,
  .st-btn-ghost .st-btn-spinner {
    border-color: rgba(11,24,82,0.2); border-top-color: ${colors.navy};
  }
`;

if (!document.getElementById('st-btn-css')) {
  const s = document.createElement('style');
  s.id = 'st-btn-css'; s.textContent = CSS;
  document.head.appendChild(s);
}

export function Button({
  variant = 'primary', size = 'md', loading = false,
  iconLeft, iconRight, fullWidth, children, className = '', ...rest
}: ButtonProps) {
  const cls = [
    'st-btn-base',
    `st-btn-${variant}`,
    `st-btn-${size}`,
    fullWidth ? 'st-btn-full' : '',
    className,
  ].filter(Boolean).join(' ');

  return (
    <button className={cls} disabled={loading || rest.disabled} aria-busy={loading} {...rest}>
      {loading && <span className="st-btn-spinner" aria-hidden="true" />}
      {!loading && iconLeft}
      {children}
      {!loading && iconRight}
    </button>
  );
}