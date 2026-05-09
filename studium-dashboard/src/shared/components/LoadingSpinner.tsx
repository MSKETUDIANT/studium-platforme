/**
 * LoadingSpinner.tsx — Spinner de chargement Studium
 */
import { colors } from '../constants/theme';

interface SpinnerProps {
  size?: number;
  color?: string;
  fullPage?: boolean;
}

const CSS = `
  @keyframes st-spin { to { transform: rotate(360deg); } }
  .st-spinner { animation: st-spin .7s linear infinite; }
  .st-spinner-page {
    position: fixed; inset: 0; display: flex;
    align-items: center; justify-content: center;
    background: rgba(255,255,255,0.7); z-index: 999;
  }
`;

if (!document.getElementById('st-spinner-css')) {
  const s = document.createElement('style');
  s.id = 'st-spinner-css'; s.textContent = CSS;
  document.head.appendChild(s);
}

export function LoadingSpinner({ size = 32, color = colors.navy, fullPage = false }: SpinnerProps) {
  const spinner = (
    <svg
      className="st-spinner"
      width={size} height={size}
      viewBox="0 0 24 24" fill="none"
      aria-label="Chargement…" role="status"
    >
      <circle cx="12" cy="12" r="10" stroke={color} strokeOpacity=".15" strokeWidth="2.5"/>
      <path d="M22 12a10 10 0 0 0-10-10" stroke={color} strokeWidth="2.5" strokeLinecap="round"/>
    </svg>
  );

  if (fullPage) return <div className="st-spinner-page">{spinner}</div>;
  return spinner;
}