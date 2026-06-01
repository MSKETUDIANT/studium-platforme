import { colors, fonts } from '../constants/theme';

const CSS = `
  .pg-wrap {
    display: flex; align-items: center; justify-content: space-between;
    padding: 12px 20px;
    border-top: 1px solid ${colors.border};
    background: #fafbff;
    flex-wrap: wrap; gap: 10px;
  }
  .pg-info { font-size: 12.5px; color: ${colors.textMuted}; font-family: ${fonts.body}; }
  .pg-info b { color: ${colors.textSecondary}; font-weight: 600; }
  .pg-controls { display: flex; gap: 4px; align-items: center; flex-wrap: wrap; }
  .pg-btn {
    display: inline-flex; align-items: center; gap: 4px;
    height: 32px; padding: 0 11px; border-radius: 8px;
    font-size: 12.5px; font-weight: 600;
    border: 1.5px solid ${colors.borderInput};
    background: white; color: ${colors.textSecondary};
    cursor: pointer; transition: all .15s; font-family: ${fonts.body};
    white-space: nowrap;
  }
  .pg-btn:disabled { opacity: .4; cursor: not-allowed; }
  .pg-btn:not(:disabled):hover { border-color: ${colors.blue}; color: ${colors.blue}; }
  .pg-num {
    display: inline-flex; align-items: center; justify-content: center;
    min-width: 32px; height: 32px; padding: 0 4px; border-radius: 8px;
    font-size: 13px; font-weight: 600;
    border: 1.5px solid ${colors.borderInput};
    background: white; color: ${colors.textSecondary};
    cursor: pointer; transition: all .15s; font-family: ${fonts.body};
  }
  .pg-num--active { background: ${colors.navy}; color: white; border-color: ${colors.navy}; }
  .pg-num:not(.pg-num--active):hover { border-color: ${colors.blue}; color: ${colors.blue}; }
  .pg-dot {
    display: inline-flex; align-items: center; justify-content: center;
    width: 28px; height: 32px;
    font-size: 14px; color: ${colors.textMuted}; font-family: ${fonts.body};
    letter-spacing: 1px;
  }
`;

function injectCSS() {
  if (typeof document === 'undefined' || document.getElementById('pg-css')) return;
  const s = document.createElement('style');
  s.id = 'pg-css';
  s.textContent = CSS;
  document.head.appendChild(s);
}

injectCSS();

interface PaginationProps {
  page: number;
  totalPages: number;
  total: number;
  pageSize: number;
  onChange: (page: number) => void;
  label?: string;
}

function pageNums(current: number, total: number): (number | '...')[] {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
  if (current <= 4) return [1, 2, 3, 4, 5, '...', total];
  if (current >= total - 3) return [1, '...', total - 4, total - 3, total - 2, total - 1, total];
  return [1, '...', current - 1, current, current + 1, '...', total];
}

export function Pagination({ page, totalPages, total, pageSize, onChange, label = 'elements' }: PaginationProps) {
  if (totalPages <= 1) return null;

  const from = (page - 1) * pageSize + 1;
  const to   = Math.min(page * pageSize, total);
  const nums = pageNums(page, totalPages);

  return (
    <div className="pg-wrap">
      <span className="pg-info">
        <b>{from}–{to}</b> sur <b>{total}</b> {label}
      </span>
      <div className="pg-controls">
        <button
          className="pg-btn"
          disabled={page === 1}
          onClick={() => onChange(page - 1)}
        >
          <svg width={11} height={11} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}><polyline points="15 18 9 12 15 6"/></svg>
          Préc.
        </button>
        {nums.map((n, i) =>
          n === '...'
            ? <span key={`e${i}`} className="pg-dot">...</span>
            : <button
                key={n}
                className={`pg-num${n === page ? ' pg-num--active' : ''}`}
                onClick={() => onChange(n as number)}
              >
                {n}
              </button>
        )}
        <button
          className="pg-btn"
          disabled={page === totalPages}
          onClick={() => onChange(page + 1)}
        >
          Suiv.
          <svg width={11} height={11} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}><polyline points="9 18 15 12 9 6"/></svg>
        </button>
      </div>
    </div>
  );
}
