/**
 * Card.tsx — Carte blanche réutilisable Studium
 */
import { colors, radius, shadows } from '../constants/theme';

interface CardProps {
  children: React.ReactNode;
  padding?: string | number;
  style?: React.CSSProperties;
  className?: string;
  onClick?: () => void;
  hoverable?: boolean;
}

const CSS = `
  .st-card {
    background: #fff;
    border-radius: ${radius.xl}px;
    border: 1px solid ${colors.border};
    box-shadow: ${shadows.card};
  }
  .st-card-hoverable {
    cursor: pointer;
    transition: box-shadow .18s, transform .15s;
  }
  .st-card-hoverable:hover {
    box-shadow: 0 4px 16px rgba(11,24,82,0.10), 0 16px 40px rgba(11,24,82,0.10);
    transform: translateY(-2px);
  }
`;

if (!document.getElementById('st-card-css')) {
  const s = document.createElement('style');
  s.id = 'st-card-css'; s.textContent = CSS;
  document.head.appendChild(s);
}

export function Card({ children, padding = '24px', style, className = '', onClick, hoverable }: CardProps) {
  return (
    <div
      className={`st-card${hoverable || onClick ? ' st-card-hoverable' : ''} ${className}`}
      style={{ padding, ...style }}
      onClick={onClick}
      role={onClick ? 'button' : undefined}
      tabIndex={onClick ? 0 : undefined}
    >
      {children}
    </div>
  );
}