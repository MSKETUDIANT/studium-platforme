/**
 * Badge.tsx — Statuts colorés Studium
 * Variantes : pending | validated | urgent | info | default
 */

type BadgeVariant = 'pending' | 'validated' | 'urgent' | 'info' | 'default';

interface BadgeProps {
  variant?: BadgeVariant;
  children: React.ReactNode;
  dot?: boolean;
}

const STYLES: Record<BadgeVariant, { bg: string; color: string; dot: string }> = {
  pending:   { bg: 'rgba(234,179,8,0.12)',   color: '#92400e', dot: '#d97706' },
  validated: { bg: 'rgba(22,163,74,0.10)',   color: '#14532d', dot: '#16a34a' },
  urgent:    { bg: 'rgba(220,38,38,0.10)',   color: '#7f1d1d', dot: '#dc2626' },
  info:      { bg: 'rgba(37,70,204,0.10)',   color: '#1e3a8a', dot: '#2546cc' },
  default:   { bg: 'rgba(11,24,82,0.07)',    color: '#4e5a78', dot: '#9ba3bc' },
};

export function Badge({ variant = 'default', children, dot = false }: BadgeProps) {
  const s = STYLES[variant];
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      background: s.bg, color: s.color,
      fontSize: 11.5, fontWeight: 600, letterSpacing: '.02em',
      padding: '3px 10px', borderRadius: 999,
      whiteSpace: 'nowrap',
    }}>
      {dot && (
        <span style={{
          width: 6, height: 6, borderRadius: '50%',
          background: s.dot, flexShrink: 0,
        }} />
      )}
      {children}
    </span>
  );
}