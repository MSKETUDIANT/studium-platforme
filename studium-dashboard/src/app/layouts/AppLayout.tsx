/**
 * AppLayout.tsx — Layout principal Studium
 * Sidebar fixe + zone de contenu principale.
 * Navigation filtrée par rôle.
 */

import { useState, useEffect } from 'react';
import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import stlogo from '../../assets/stlogo.png';
import { authService } from '../../features/auth/services/authService';
import { useRole } from '../../features/auth/hooks/useRole';
import { useAuth } from '../../features/auth/hooks/useAuth';
import { colors, fonts } from '../../shared/constants/theme';

const CSS = `
  @keyframes layoutFadeIn { from{opacity:0;transform:translateX(-8px)} to{opacity:1;transform:none} }

  .sl-root { display:flex; min-height:100vh; width:100%; font-family:${fonts.body}; background:${colors.pageBg}; }

  .sl-sidebar {
    width: 240px; min-height: 100vh;
    background: ${colors.sidebarBg};
    display: flex; flex-direction: column;
    position: sticky; top: 0; height: 100vh;
    flex-shrink: 0; z-index: 100;
    transition: width .25s cubic-bezier(.4,0,.2,1);
  }
  .sl-sidebar.collapsed { width: 68px; }

  .sl-brand {
    padding: 28px 16px 24px;
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    gap: 10px; border-bottom: 1px solid rgba(255,255,255,0.07);
    min-height: 130px; overflow: hidden;
  }
  .sl-brand img { width: 180px; filter: brightness(0) invert(1); flex-shrink:0; transition: width .2s; }
  .sl-sidebar.collapsed .sl-brand img { width: 36px; }
  .sl-brand-tag {
    font-size: 10px; font-weight: 500; letter-spacing: .09em;
    color: rgba(255,255,255,0.55); text-transform: uppercase;
    white-space: nowrap; transition: opacity .2s;
  }
  .sl-sidebar.collapsed .sl-brand-tag { opacity: 0; height: 0; overflow: hidden; }

  .sl-nav { flex:1; padding: 16px 10px; display:flex; flex-direction:column; gap:2px; overflow:hidden; }
  .sl-section-label {
    font-size:10px; font-weight:600; letter-spacing:.12em; text-transform:uppercase;
    color:rgba(255,255,255,0.28); padding:12px 10px 6px;
    white-space:nowrap; overflow:hidden; transition: opacity .2s;
  }
  .sl-sidebar.collapsed .sl-section-label { opacity:0; height:0; padding:0; }

  .sl-nav-item {
    display: flex; align-items: center; gap: 12px;
    padding: 10px 12px; border-radius: 9px;
    color: ${colors.sidebarText};
    text-decoration: none; font-size: 14px; font-weight: 500;
    transition: background .15s, color .15s, border-left-color .15s;
    border-left: 2px solid transparent;
    white-space: nowrap; overflow: hidden; position: relative;
  }
  .sl-nav-item:hover { background:rgba(255,255,255,0.07); color:${colors.sidebarTextHover}; }
  .sl-nav-item.active {
    background: rgba(255,255,255,0.11); color: #ffffff;
    border-left-color: ${colors.sidebarActiveBorder};
  }
  .sl-nav-icon { width:18px; height:18px; flex-shrink:0; }
  .sl-nav-label { transition:opacity .2s; }
  .sl-sidebar.collapsed .sl-nav-label { opacity:0; width:0; overflow:hidden; }

  .sl-sidebar.collapsed .sl-nav-item:hover::after {
    content: attr(data-label);
    position: absolute; left: 72px; top: 50%; transform: translateY(-50%);
    background: #1a2f8a; color:#fff; font-size:12px; font-weight:500;
    padding: 5px 10px; border-radius:6px; white-space:nowrap;
    pointer-events:none; z-index:200;
    box-shadow: 0 4px 12px rgba(0,0,0,0.25);
  }

  .sl-toggle {
    margin: 0 10px 16px;
    display:flex; align-items:center; justify-content:center;
    width:36px; height:36px; border-radius:8px;
    background:rgba(255,255,255,0.06); border:none;
    cursor:pointer; color:rgba(255,255,255,0.5);
    transition:background .15s, color .15s; flex-shrink:0; align-self: flex-start;
  }
  .sl-sidebar.collapsed .sl-toggle { align-self:center; }
  .sl-toggle:hover { background:rgba(255,255,255,0.12); color:#fff; }

  .sl-user {
    padding: 12px 10px; border-top: 1px solid rgba(255,255,255,0.07);
    display:flex; align-items:center; gap:10px; overflow:hidden;
  }
  .sl-avatar {
    width:34px; height:34px; border-radius:9px;
    background: rgba(77,122,255,0.30);
    display:flex; align-items:center; justify-content:center;
    font-family:${fonts.display}; font-size:13px; font-weight:700;
    color:#fff; flex-shrink:0;
  }
  .sl-user-info { overflow:hidden; }
  .sl-user-name  { font-size:13px; font-weight:600; color:rgba(255,255,255,0.88); white-space:nowrap; }
  .sl-user-role  { font-size:11px; color:rgba(255,255,255,0.38); white-space:nowrap; }
  .sl-sidebar.collapsed .sl-user-info { display:none; }
  .sl-logout {
    margin-left:auto; background:none; border:none; cursor:pointer;
    color:rgba(255,255,255,0.35); padding:6px; border-radius:6px;
    transition:color .15s, background .15s; flex-shrink:0;
  }
  .sl-logout:hover { color:#f87171; background:rgba(248,113,113,0.12); }
  .sl-sidebar.collapsed .sl-logout { margin:0 auto; }

  .sl-main { flex:1; display:flex; flex-direction:column; min-width:0; overflow:hidden; }

  .sl-topbar {
    height: 60px; background:${colors.cardBg};
    border-bottom: 1px solid ${colors.border};
    display:flex; align-items:center; padding:0 28px;
    gap:16px; flex-shrink:0;
    box-shadow: 0 1px 3px rgba(11,24,82,0.04);
  }
  .sl-page-title {
    font-family:${fonts.display}; font-weight:800; font-size:17px;
    color:${colors.textPrimary}; letter-spacing:-.3px;
  }
  .sl-topbar-right { margin-left:auto; display:flex; align-items:center; gap:12px; }
  .sl-topbar-btn {
    width:36px; height:36px; border-radius:9px; border:none;
    background:${colors.inputBg}; cursor:pointer; display:flex;
    align-items:center; justify-content:center; color:${colors.textSecondary};
    transition:background .15s, color .15s;
  }
  .sl-topbar-btn:hover { background:#e2e6f3; color:${colors.navy}; }

  .sl-content { flex:1; padding:28px; overflow-y:auto; }

  .sl-overlay {
    display:none; position:fixed; inset:0;
    background:rgba(0,0,0,0.45); z-index:99;
  }
  .sl-hamburger {
    display:none; background:none; border:none; cursor:pointer;
    color:${colors.textPrimary}; padding:4px;
  }

  /* ── Tablette (769px – 1100px) : padding réduit ── */
  @media (min-width: 769px) and (max-width: 1100px) {
    .sl-content { padding:20px; }
    .sl-topbar  { padding:0 20px; }
  }

  /* ── Mobile (≤ 768px) : sidebar hors-écran, hamburger ── */
  @media (max-width: 768px) {
    .sl-sidebar {
      position: fixed; left:0; top:0; bottom:0;
      transform: translateX(-100%);
      transition: transform .28s cubic-bezier(.4,0,.2,1), width .25s;
    }
    .sl-sidebar.mobile-open { transform: translateX(0); width:240px !important; }
    .sl-sidebar.mobile-open .sl-nav-label { opacity:1; width:auto; }
    .sl-sidebar.mobile-open .sl-section-label { opacity:1; height:auto; padding:12px 10px 6px; }
    .sl-overlay.visible { display:block; }
    .sl-hamburger { display:flex; align-items:center; justify-content:center; }
    .sl-toggle { display:none; }
    .sl-content { padding:14px; }
    .sl-topbar { padding:0 14px; height:54px; }
    .sl-page-title { font-size:15px; }
    .sl-topbar-btn { width:32px; height:32px; }
  }

  /* ── Grands écrans (> 1400px) : sidebar légèrement plus large ── */
  @media (min-width: 1400px) {
    .sl-sidebar:not(.collapsed) { width: 260px; }
  }
`;

if (!document.getElementById('sl-css')) {
  const s = document.createElement('style');
  s.id = 'sl-css';
  s.textContent = CSS;
  document.head.appendChild(s);
}

/* ─── Nav items avec contrôle par rôle ──────────────────────────────────── */
type RoleKey = 'admin' | 'manager' | 'admissions' | 'support';

const ALL_NAV_ITEMS = [
  {
    section: 'Principal',
    items: [
      { to: '/applications', label: 'Applications', icon: <IconApplications />, roles: ['admin','manager','admissions'] },
      { to: '/students',     label: 'Étudiants',    icon: <IconStudents />,     roles: ['admin','manager','admissions','support'] },
      { to: '/programs',     label: 'Programmes',   icon: <IconPrograms />,     roles: ['admin','manager','admissions'] },
    ],
  },
  {
    section: 'Outils',
    items: [
      { to: '/messaging',  label: 'Messagerie', icon: <IconMessaging />, roles: ['admin','manager','admissions','support'] },
      { to: '/reporting',  label: 'Rapports',   icon: <IconReporting />, roles: ['admin','manager'] },
      { to: '/team',       label: 'Équipe',     icon: <IconTeam />,      roles: ['admin'] },
      { to: '/settings',   label: 'Paramètres', icon: <IconSettings />,  roles: ['admin','manager'] },
    ],
  },
];

const PAGE_TITLES: Record<string, string> = {
  '/applications': 'Applications',
  '/students':     'Gestion des étudiants',
  '/programs':     'Programmes',
  '/messaging':    'Messagerie',
  '/reporting':    'Rapports',
  '/team':         'Équipe Studium',
  '/settings':     'Paramètres',
};

const ROLE_LABELS: Record<string, string> = {
  admin:      'Administrateur',
  manager:    'Manager',
  admissions: 'Admissions',
  support:    'Support',
};

/* ─── SVG Icons ──────────────────────────────────────────────────────────── */
function IconApplications() {
  return <svg className="sl-nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>;
}
function IconStudents() {
  return <svg className="sl-nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>;
}
function IconPrograms() {
  return <svg className="sl-nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/></svg>;
}
function IconMessaging() {
  return <svg className="sl-nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>;
}
function IconReporting() {
  return <svg className="sl-nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>;
}
function IconTeam() {
  return <svg className="sl-nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>;
}
function IconSettings() {
  return <svg className="sl-nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>;
}
function IconCollapse() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="15 18 9 12 15 6"/></svg>;
}
function IconExpand() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="9 18 15 12 9 6"/></svg>;
}
function IconMenu() {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>;
}
function IconLogout() {
  return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>;
}
function IconNotif() {
  return <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>;
}

/* ═══════════════════════════════════════════════════════════════════════════
   AppLayout
   ═══════════════════════════════════════════════════════════════════════════ */
export default function AppLayout() {
  const navigate  = useNavigate();
  const { user }  = useAuth();
  const { role }  = useRole();

  const [collapsed,  setCollapsed]  = useState(() => window.innerWidth <= 1100 && window.innerWidth > 768);
  const [mobileOpen, setMobileOpen] = useState(false);

  useEffect(() => {
    const onResize = () => {
      if (window.innerWidth <= 768) {
        setMobileOpen(false);
      }
    };
    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, []);

  const pathname  = window.location.pathname;
  const pageTitle = PAGE_TITLES[pathname] ?? 'Dashboard';

  // Filtrer le menu selon le rôle
  const navItems = ALL_NAV_ITEMS.map(section => ({
    ...section,
    items: section.items.filter(item =>
      !role || item.roles.includes(role as RoleKey)
    ),
  })).filter(section => section.items.length > 0);

  // Initiales de l'email
  const initials = user?.email?.slice(0, 2).toUpperCase() ?? 'AD';
  const roleLabel = ROLE_LABELS[role ?? ''] ?? 'Équipe Studium';

  const handleLogout = async () => {
    await authService.signOut?.();
    navigate('/login');
  };

  const sidebarClass = [
    'sl-sidebar',
    collapsed  ? 'collapsed'   : '',
    mobileOpen ? 'mobile-open' : '',
  ].filter(Boolean).join(' ');

  return (
    <div className="sl-root">

      <div
        className={`sl-overlay${mobileOpen ? ' visible' : ''}`}
        onClick={() => setMobileOpen(false)}
      />

      {/* ══════════ SIDEBAR ══════════ */}
      <aside className={sidebarClass} aria-label="Navigation principale">

        <div className="sl-brand">
          <img src={stlogo} alt="Studium" />
          <span className="sl-brand-tag">Étudier Partout Dans le Monde</span>
        </div>

        <nav className="sl-nav">
          {navItems.map(({ section, items }) => (
            <div key={section}>
              <div className="sl-section-label">{section}</div>
              {items.map(({ to, label, icon }) => (
                <NavLink
                  key={to}
                  to={to}
                  data-label={label}
                  className={({ isActive }) => `sl-nav-item${isActive ? ' active' : ''}`}
                  onClick={() => setMobileOpen(false)}
                >
                  {icon}
                  <span className="sl-nav-label">{label}</span>
                </NavLink>
              ))}
            </div>
          ))}
        </nav>

        <button
          className="sl-toggle"
          onClick={() => setCollapsed(v => !v)}
          aria-label={collapsed ? 'Agrandir la sidebar' : 'Réduire la sidebar'}
        >
          {collapsed ? <IconExpand /> : <IconCollapse />}
        </button>

        {/* User zone */}
        <div className="sl-user">
          <div className="sl-avatar">{initials}</div>
          <div className="sl-user-info">
            <div className="sl-user-name">{user?.email?.split('@')[0] ?? 'Admin'}</div>
            <div className="sl-user-role">{roleLabel}</div>
          </div>
          <button className="sl-logout" onClick={handleLogout} aria-label="Se déconnecter" title="Se déconnecter">
            <IconLogout />
          </button>
        </div>
      </aside>

      {/* ══════════ MAIN ══════════ */}
      <div className="sl-main">

        <header className="sl-topbar">
          <button className="sl-hamburger" onClick={() => setMobileOpen(v => !v)} aria-label="Ouvrir le menu">
            <IconMenu />
          </button>

          <h1 className="sl-page-title">{pageTitle}</h1>

          <div className="sl-topbar-right">
            <button className="sl-topbar-btn" aria-label="Notifications">
              <IconNotif />
            </button>
            <div style={{
              width:34, height:34, borderRadius:9,
              background: colors.navy,
              display:'flex', alignItems:'center', justifyContent:'center',
              fontFamily: fonts.display, fontSize:13, fontWeight:700, color:'#fff',
              cursor:'pointer',
            }}>
              {initials}
            </div>
          </div>
        </header>

        <main className="sl-content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}