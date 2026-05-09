/**
 * EmptyState.tsx — Écran vide réutilisable Studium
 */
import { colors, fonts } from '../constants/theme';

interface EmptyStateProps {
  icon?: React.ReactNode;
  title: string;
  description?: string;
  action?: React.ReactNode;
}

export function EmptyState({ icon, title, description, action }: EmptyStateProps) {
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center',
      justifyContent: 'center', padding: '64px 24px', textAlign: 'center',
    }}>
      {icon && (
        <div style={{
          width: 64, height: 64, borderRadius: 16,
          background: colors.inputBg,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          marginBottom: 20, color: colors.textMuted,
        }}>
          {icon}
        </div>
      )}
      <h3 style={{
        fontFamily: fonts.display, fontWeight: 700, fontSize: 17,
        color: colors.textPrimary, margin: '0 0 8px',
      }}>
        {title}
      </h3>
      {description && (
        <p style={{ fontSize: 14, color: colors.textSecondary, margin: '0 0 24px', maxWidth: 320 }}>
          {description}
        </p>
      )}
      {action}
    </div>
  );
}