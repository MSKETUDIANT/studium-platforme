/**
 * PageHeader.tsx — En-tête de page Studium
 */
import { colors, fonts } from '../constants/theme';

interface PageHeaderProps {
  title: string;
  subtitle?: string;
  actions?: React.ReactNode;
}

export function PageHeader({ title, subtitle, actions }: PageHeaderProps) {
  return (
    <div style={{
      display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between',
      flexWrap: 'wrap', gap: 16, marginBottom: 28,
    }}>
      <div>
        <h1 style={{
          fontFamily: fonts.display, fontWeight: 800, fontSize: 22,
          color: colors.textPrimary, margin: '0 0 4px', letterSpacing: '-.4px',
        }}>
          {title}
        </h1>
        {subtitle && (
          <p style={{ fontSize: 14, color: colors.textSecondary, margin: 0 }}>
            {subtitle}
          </p>
        )}
      </div>
      {actions && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexShrink: 0 }}>
          {actions}
        </div>
      )}
    </div>
  );
}