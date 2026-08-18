import { colors, fonts } from '../constants/theme';

const CSS = `
  .pg-wrap {
    display: flex; align-items: center; justify-content: space-between;
    padding: 12px 20px;
    border-top: 1px solid ${colors.border};
    background: #fafbff;
    flex-wrap: wrap; gap: 10px;
  }
  .pg-left  { display: flex; align-items: center; gap: 14px; flex-wrap: wrap; }
  .pg-info  { font-size: 12.5px; color: ${colors.textMuted}; font-family: ${fonts.body}; }
  .pg-info b { color: ${colors.textSecondary}; font-weight: 600; }
  .pg-sizer-wrap {
    display: flex; align-items: center; gap: 7px;
    font-size: 12.5px; color: ${colors.textMuted}; font-family: ${fonts.body};
  }
  .pg-sizer {
    height: 32px; padding: 0 8px; border-radius: 8px;
    border: 1.5px solid ${colors.borderInput};
    background: white; color: ${colors.textSecondary};
    font-size: 12.5px; font-weight: 600; font-family: ${fonts.body};
    cursor: pointer; outline: none; transition: border-color .15s;
    appearance: none; -webkit-appearance: none;
    padding-right: 22px;
    background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='6' fill='none' viewBox='0 0 10 6'%3E%3Cpath d='M1 1l4 4 4-4' stroke='%239ca3af' stroke-width='1.5' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E");
    background-repeat: no-repeat;
    background-position: right 7px center;
  }
  .pg-sizer:focus { border-color: ${colors.blue}; }
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

const PAGE_SIZE_OPTIONS = [10, 25, 50];

interface PaginationProps {
  page:             number;
  totalPages:       number;
  total:            number;
  pageSize:         number;
  onChange:         (page: number) => void;
  onPageSizeChange?: (size: number) => void;
  label?:           string;
}

function pageNums(current: number, total: number): (number | '...')[] {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
  if (current <= 4) return [1, 2, 3, 4, 5, '...', total];
  if (current >= total - 3) return [1, '...', total - 4, total - 3, total - 2, total - 1, total];
  return [1, '...', current - 1, current, current + 1, '...', total];
}

export function Pagination({
  page, totalPages, total, pageSize,
  onChange, onPageSizeChange, label = 'elements',
}: PaginationProps) {
  if (total === 0) return null;

  const from = (page - 1) * pageSize + 1;
  const to   = Math.min(page * pageSize, total);
  const nums = pageNums(page, totalPages);

  return (
    <div className="pg-wrap">
      <div className="pg-left">
        {onPageSizeChange && (
          <div className="pg-sizer-wrap">
            <span>Afficher</span>
            <select
              className="pg-sizer"
              value={pageSize}
              onChange={e => { onPageSizeChange(Number(e.target.value)); onChange(1); }}
            >
              {PAGE_SIZE_OPTIONS.map(n => (
                <option key={n} value={n}>{n}</option>
              ))}
            </select>
            <span>par page</span>
          </div>
        )}
        <span className="pg-info">
          <b>{from}–{to}</b> sur <b>{total}</b> {label}
        </span>
      </div>

      {totalPages > 1 && (
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
      )}
    </div>
  );
}
