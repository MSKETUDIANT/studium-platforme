import React from 'react';
import { colors, fonts } from '../constants/theme';

const PAGE_HEADER_CSS = `
  @keyframes ph-in { from { opacity: 0; transform: translateY(-8px); } to { opacity: 1; transform: translateY(0); } }
  @keyframes ph-fade-up { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
  .ph-root {
    position: relative;
    border-radius: 18px;
    overflow: hidden;
    margin-bottom: 28px;
    background: linear-gradient(135deg, ${colors.navy} 0%, ${colors.blue} 100%);
    box-shadow: 0 8px 28px rgba(11,24,82,0.22);
    animation: ph-in .38s ease both;
  }
  .ph-circle {
    position: absolute;
    border-radius: 50%;
    background: rgba(255,255,255,0.07);
    pointer-events: none;
  }
  .ph-inner {
    position: relative;
    z-index: 1;
    padding: 22px 26px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 14px;
  }
  .ph-actions .st-btn-primary {
    background: rgba(255,255,255,0.15);
    border: 1.5px solid rgba(255,255,255,0.3);
  }
  .ph-actions .st-btn-primary:not(:disabled):hover {
    background: rgba(255,255,255,0.25);
    box-shadow: none;
  }
`;

function injectCSS() {
  if (typeof document === 'undefined' || document.getElementById('ph-css')) return;
  const s = document.createElement('style');
  s.id = 'ph-css';
  s.textContent = PAGE_HEADER_CSS;
  document.head.appendChild(s);
}

injectCSS();

interface PageHeaderProps {
  title: string;
  subtitle?: string;
  actions?: React.ReactNode;
}

export function PageHeader({ title, subtitle, actions }: PageHeaderProps) {
  return (
    <div className="ph-root">
      <div className="ph-circle" style={{ width: 180, height: 180, top: -50, right: -30 }} />
      <div className="ph-circle" style={{ width: 90, height: 90, bottom: -35, right: 140 }} />
      <div className="ph-circle" style={{ width: 50, height: 50, top: 10, right: 165, opacity: 0.5 }} />
      <div className="ph-inner">
        <div>
          <h1 style={{
            fontFamily: fonts.display, fontWeight: 800, fontSize: 22,
            color: '#fff', margin: '0 0 4px', letterSpacing: '-.4px',
          }}>
            {title}
          </h1>
          {subtitle && (
            <p style={{ fontSize: 13.5, color: 'rgba(255,255,255,0.72)', margin: 0 }}>
              {subtitle}
            </p>
          )}
        </div>
        {actions && (
          <div className="ph-actions" style={{ display: 'flex', alignItems: 'center', gap: 10, flexShrink: 0 }}>
            {actions}
          </div>
        )}
      </div>
    </div>
  );
}
