import type { ReactNode } from 'react';
import { colors, fonts, radius, shadows } from '../constants/theme';

export interface StatCardProps {
  icon:      ReactNode;
  iconBg:    string;
  iconColor: string;
  label:     string;
  value:     number | string;
  sub?:      string;
  accent:    string;
}

/** Carte statistique unique, réutilisée par toutes les pages avec des
 * grilles de KPI (Students/Team/Applications/Audit/Programs/Reporting) —
 * remplace 6 réimplémentations locales dont le padding/taille d'icône/taille
 * de valeur avaient dérivé les unes des autres. */
export function StatCard({ icon, iconBg, iconColor, label, value, sub, accent }: StatCardProps) {
  return (
    <div style={{ background: 'white', borderRadius: radius.lg, boxShadow: shadows.card, overflow: 'hidden' }}>
      <div style={{ height: 3, background: accent }} />
      <div style={{ padding: '18px 20px', display: 'flex', alignItems: 'center', gap: 16 }}>
        <div style={{
          width: 44, height: 44, borderRadius: 12, flexShrink: 0,
          background: iconBg, color: iconColor,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          {icon}
        </div>
        <div>
          <div style={{ fontSize: 28, fontWeight: 800, color: accent, fontFamily: fonts.display, lineHeight: 1 }}>
            {value}
          </div>
          <div style={{ fontSize: 12, color: colors.textMuted, marginTop: 5, fontWeight: 500 }}>{label}</div>
          {sub && <div style={{ fontSize: 11, color: colors.textMuted, marginTop: 2 }}>{sub}</div>}
        </div>
      </div>
    </div>
  );
}
