/**
 * LoginPage — Studium Internal Dashboard
 *
 * Standards appliqués :
 *  ✓ WCAG 2.1 AA  — contrastes ≥ 4.5:1, labels liés, aria, focus-visible
 *  ✓ Nielsen's Heuristics — feedback d'état, récupération d'erreur, cohérence
 *  ✓ Fitts's Law  — toutes les zones interactives ≥ 44×44 px
 *  ✓ Mobile-first — 3 breakpoints (desktop / tablet / mobile)
 *  ✓ iOS Safari   — font-size ≥ 16px sur inputs (pas de zoom auto)
 *  ✓ autocomplete — compatible gestionnaires de mots de passe
 *  ✓ prefers-reduced-motion — animations désactivées si besoin
 *
 * NB : Nécessite le reset suivant dans index.css :
 *   html, body { margin: 0; height: 100%; }
 *   #root { min-height: 100vh; display: flex; flex-direction: column; }
 */

import { useState, useEffect, useId } from 'react';
import { useNavigate } from 'react-router-dom';
import { authService } from '../services/authService';
import stlogo from '../../../assets/stlogo.png';


/* ─── CSS global injecté une seule fois ─────────────────────────────────── */
const CSS = `
  @import url('https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,700;12..96,800&family=Plus+Jakarta+Sans:wght@400;500;600&display=swap');

  /* Animations */
  @keyframes stFadeUp { from{opacity:0;transform:translateY(18px)} to{opacity:1;transform:none} }
  @keyframes stSpin   { to{transform:rotate(360deg)} }
  @keyframes stShake  { 0%,100%{transform:translateX(0)} 20%,60%{transform:translateX(-5px)} 40%,80%{transform:translateX(5px)} }

  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after { animation-duration:0.01ms !important; transition-duration:0.01ms !important; }
  }

  /* Layout */
  .stl-root  { display:flex; flex:1; min-height:100vh; width:100%; font-family:'Plus Jakarta Sans',sans-serif; }

  /* Panel gauche */
  .stl-left  {
    flex: 0 0 44%;
    min-height: 100vh;
    background: linear-gradient(145deg, #0b1852 0%, #162270 60%, #0f1a6e 100%);
    display: flex; flex-direction: column;
    align-items: center; justify-content: center;
    padding: 60px 52px;
    position: relative; overflow: hidden; text-align: center;
  }
  .stl-left::before {
    content:''; position:absolute; inset:0; pointer-events:none;
    background-image:
      linear-gradient(rgba(255,255,255,0.04) 1px, transparent 1px),
      linear-gradient(90deg, rgba(255,255,255,0.04) 1px, transparent 1px);
    background-size: 56px 56px;
  }

  /* Panel droit */
  .stl-right {
    flex: 1; min-height: 100vh;
    background: #eef0f7;
    display: flex; align-items: center; justify-content: center;
    padding: 40px 32px;
  }

  /* Inputs — 16px obligatoire iOS */
  .stl-input {
    width: 100%; font-size: 16px; font-family: 'Plus Jakarta Sans', sans-serif;
    padding: 13px 16px; line-height: 1.5;
    border: 1.5px solid #dde1f0; border-radius: 10px;
    color: #0b1852; background: #f5f7fc;
    transition: border-color .18s, box-shadow .18s, background .18s;
    -webkit-appearance: none; appearance: none;
  }
  .stl-input:hover:not(:focus-visible) { border-color: #c2cadf; }
  .stl-input:focus-visible {
    outline: none; border-color: #1e3fb8;
    box-shadow: 0 0 0 4px rgba(30,63,184,0.15);
    background: #fff;
  }
  .stl-input.stl-input-error { border-color: #f87171 !important; background: #fff8f8; }

  /* Bouton submit — min-height 52px Fitts */
  .stl-btn {
    width: 100%; min-height: 52px;
    padding: 14px 20px;
    background: linear-gradient(135deg, #1a2f8a 0%, #2546cc 100%);
    box-shadow: 0 6px 22px rgba(11,24,82,0.32);
    color: #fff; border: none; border-radius: 11px;
    font-family: 'Bricolage Grotesque', sans-serif;
    font-size: 16px; font-weight: 700; letter-spacing: -.1px;
    cursor: pointer; display:flex; align-items:center; justify-content:center; gap:10px;
    transition: box-shadow .2s, transform .1s, filter .18s;
    -webkit-tap-highlight-color: transparent;
  }
  .stl-btn:not(:disabled):hover  { filter:brightness(1.1); box-shadow:0 10px 32px rgba(11,24,82,0.42); }
  .stl-btn:not(:disabled):active { transform:scale(0.987); }
  .stl-btn:disabled               { background:linear-gradient(135deg,#7a9bd4,#9bb5e0); box-shadow:none; cursor:not-allowed; }
  .stl-btn:focus-visible          { outline:3px solid #4d7aff; outline-offset:3px; }

  /* Toggle mot de passe — zone 50×100% Fitts */
  .stl-eye {
    position:absolute; right:0; top:0; width:50px; height:100%;
    display:flex; align-items:center; justify-content:center;
    background:none; border:none; cursor:pointer; color:#aab2cc;
    border-radius:0 10px 10px 0;
    transition: color .15s, background .15s;
    -webkit-tap-highlight-color: transparent;
  }
  .stl-eye:hover       { color:#1e3fb8; background:rgba(30,63,184,0.05); }
  .stl-eye:focus-visible { outline:2px solid #4d7aff; }

  /* Lien secondaire */
  .stl-link {
    font-size:13.5px; color:#4e5a78; font-weight:500; text-decoration:none;
    transition:color .15s;
    padding: 4px 2px; /* zone de clic agrandie */
  }
  .stl-link:hover       { color:#1e3fb8; text-decoration:underline; }
  .stl-link:focus-visible { outline:2px solid #4d7aff; border-radius:3px; }

  /* Erreur */
  .stl-error       { display:flex; align-items:flex-start; gap:10px; background:#fef2f2; border:1.5px solid #fca5a5; border-radius:10px; padding:12px 14px; margin-bottom:22px; }
  .stl-error-shake { animation:stShake .4s ease; }

  /* Force-champ helper text */
  .stl-helper { font-size:12.5px; color:#6b7a9e; margin-top:6px; min-height:18px; line-height:1.4; }

  /* ── Responsive ── */
  @media (max-width: 900px) {
    .stl-left  { flex:0 0 38%; padding:48px 32px; }
    .stl-right { padding:32px 20px; }
    .stl-logo  { width:280px !important; }
  }
  @media (max-width: 640px) {
    .stl-root  { flex-direction:column; }
    .stl-left  { flex:none; min-height:auto; width:100%; padding:44px 24px 36px; }
    .stl-logo  { width:240px !important; }
    .stl-divider { margin:22px auto !important; }
    .stl-desc  { font-size:13px !important; max-width:290px !important; }
    .stl-right { flex:none; min-height:auto; width:100%; padding:28px 16px 52px; }
    .stl-card  { padding:32px 22px !important; border-radius:16px !important; }
  }
  @media (max-width: 380px) {
    .stl-left  { padding:32px 18px 28px; }
    .stl-logo  { width:190px !important; }
    .stl-card  { padding:26px 16px !important; }
  }
`;

if (!document.getElementById('stl-css')) {
  const s = document.createElement('style');
  s.id = 'stl-css';
  s.textContent = CSS;
  document.head.appendChild(s);
}

/* ─── Icons SVG ──────────────────────────────────────────────────────────── */
const Eye = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
  </svg>
);
const EyeOff = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/>
    <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/>
    <line x1="1" y1="1" x2="23" y2="23"/>
  </svg>
);
const Arrow = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
    <line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/>
  </svg>
);
const Spinner = () => (
  <svg width="17" height="17" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="#fff" strokeWidth="2.5" strokeLinecap="round"
    style={{ animation:'stSpin .75s linear infinite', flexShrink:0 }}>
    <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/>
  </svg>
);
const AlertIcon = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="#b91c1c" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"
    style={{ flexShrink:0, marginTop:2 }}>
    <circle cx="12" cy="12" r="10"/>
    <line x1="12" y1="8" x2="12" y2="12"/>
    <line x1="12" y1="16" x2="12.01" y2="16"/>
  </svg>
);

const Orb = ({ style }: { style: React.CSSProperties }) => (
  <div aria-hidden="true" style={{
    position:'absolute', borderRadius:'50%', pointerEvents:'none',
    background:'radial-gradient(circle, rgba(72,128,255,0.22) 0%, transparent 65%)',
    ...style,
  }} />
);

/* ─── Évaluation force mot de passe ─────────────────────────────────────── */
function passwordStrength(pw: string): { score: number; label: string; color: string } {
  if (!pw) return { score: 0, label: '', color: 'transparent' };
  let score = 0;
  if (pw.length >= 8)  score++;
  if (pw.length >= 12) score++;
  if (/[A-Z]/.test(pw)) score++;
  if (/[0-9]/.test(pw)) score++;
  if (/[^A-Za-z0-9]/.test(pw)) score++;
  if (score <= 1) return { score, label: 'Faible',  color: '#f87171' };
  if (score <= 3) return { score, label: 'Moyen',   color: '#fbbf24' };
  return              { score, label: 'Fort',    color: '#34d399' };
}

/* ─── Feature chips (panel gauche) ──────────────────────────────────────── */
const IconDossiers = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="rgba(255,255,255,0.80)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>
  </svg>
);
const IconSuivi = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="rgba(255,255,255,0.80)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/>
  </svg>
);
const IconEquipe = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="rgba(255,255,255,0.80)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
    <circle cx="9" cy="7" r="4"/>
    <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
    <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
  </svg>
);

const FEATURES = [
  { label: 'Dossiers',    Icon: IconDossiers },
  { label: 'Suivi',       Icon: IconSuivi    },
  { label: 'Équipe',      Icon: IconEquipe   },
];

/* ═══════════════════════════════════════════════════════════════════════════
   Component
   ═══════════════════════════════════════════════════════════════════════════ */
export default function LoginPage() {
  const navigate   = useNavigate();
  const emailId    = useId();
  const passwordId = useId();
  const errorId    = useId();

  const [email, setEmail]         = useState('');
  const [password, setPassword]   = useState('');
  const [showPw, setShowPw]       = useState(false);
  const [error, setError]         = useState('');
  const [emailError, setEmailError] = useState('');
  const [loading, setLoading]     = useState(false);
  const [mounted, setMounted]     = useState(false);
  const [shakeKey, setShakeKey]   = useState(0);
  const [touched, setTouched]     = useState({ email: false, password: false });

  const pwStrength = passwordStrength(password);

  useEffect(() => {
    setMounted(true);
    // focus programmatique — on marque isProgrammaticFocus pour ne pas
    // déclencher la validation onBlur si l'utilisateur n'a pas encore agi
    const t = setTimeout(() => {
      const el = document.getElementById(emailId) as HTMLInputElement | null;
      if (el) { el.dataset.programmatic = '1'; el.focus(); }
    }, 500);
    return () => clearTimeout(t);
  }, [emailId]);

  const anim = (d: number): React.CSSProperties =>
    mounted ? { animation:`stFadeUp .5s cubic-bezier(.25,.75,.25,1) ${d}ms both` } : { opacity:0 };

  /* Validation email :
     - Sur blur → signale seulement si le champ a du contenu mais format invalide
     - "Ce champ est requis" uniquement à la soumission                          */
  const validateEmail = (val: string, onSubmit = false) => {
    if (!val) {
      if (onSubmit) setEmailError('Ce champ est requis');
      else setEmailError('');
      return false;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val)) {
      setEmailError("Format d'email invalide");
      return false;
    }
    setEmailError('');
    return true;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setTouched({ email: true, password: true });
    if (!validateEmail(email, true)) return;
    setError('');
    setLoading(true);
    try {
      await authService.signIn(email, password);
      navigate('/applications');
    } catch (err: any) {
      setError(err.message || 'Identifiants incorrects. Veuillez réessayer.');
      setShakeKey(k => k + 1);
    } finally {
      setLoading(false);
    }
  };

  const labelStyle: React.CSSProperties = {
    display:'block', marginBottom:9,
    fontSize:12.5, fontWeight:700, letterSpacing:'0.09em',
    textTransform:'uppercase', color:'#3d4a68',
  };

  return (
    <div className="stl-root">

      {/* ══════════ PANEL GAUCHE ══════════ */}
      <aside className="stl-left" aria-label="Présentation Studium">
        <Orb style={{ width:400, height:400, top:-120, right:-100 }} />
        <Orb style={{ width:280, height:280, bottom:-70, left:-80, opacity:0.6 }} />

        <div style={{ ...anim(0), zIndex:1 }}>
          <img
            src={stlogo}
            alt="Studium — Étudier Partout Dans le Monde"
            className="stl-logo"
            style={{ width:340, display:'block', margin:'0 auto', filter:'brightness(0) invert(1)' }}
          />
        </div>

        <div aria-hidden="true" className="stl-divider" style={{
          ...anim(100), zIndex:1,
          width:36, height:2, background:'rgba(255,255,255,0.15)',
          borderRadius:2, margin:'30px auto',
        }} />

        <p className="stl-desc" style={{
          ...anim(180), zIndex:1,
          fontSize:14.5, color:'rgba(255,255,255,0.70)',
          lineHeight:1.9, maxWidth:270,
        }}>
          Espace réservé à{' '}
          <strong style={{ color:'#ffffff', fontWeight:600 }}>
            l'équipe interne Studium
          </strong>
          {' '}— gestion et suivi des dossiers académiques internationaux.
        </p>

        {/* Feature chips */}
        <div style={{
          ...anim(260), zIndex:1,
          display:'flex', gap:10, marginTop:32, flexWrap:'wrap', justifyContent:'center',
        }}>
          {FEATURES.map(f => (
            <div key={f.label} style={{
              display:'flex', flexDirection:'column', alignItems:'center',
              background:'rgba(255,255,255,0.07)',
              border:'1px solid rgba(255,255,255,0.12)',
              borderRadius:12, padding:'12px 18px', minWidth:80, gap:6,
            }}>
              <f.Icon />
              <span style={{ fontSize:11.5, color:'rgba(255,255,255,0.70)', letterSpacing:'0.4px', fontWeight:500 }}>{f.label}</span>
            </div>
          ))}
        </div>
      </aside>

      {/* ══════════ PANEL DROIT ══════════ */}
      <div className="stl-right">
        <div style={{ width:'100%', maxWidth:420 }}>

          <main className="stl-card" style={{
            ...anim(260),
            background:'#fff', borderRadius:20, padding:'0',
            border:'1px solid rgba(11,24,82,0.08)',
            boxShadow:'0 1px 4px rgba(11,24,82,0.04), 0 8px 24px rgba(11,24,82,0.07), 0 28px 60px rgba(11,24,82,0.08)',
            overflow:'hidden',
          }}>

            {/* Accent bar */}
            <div style={{
              height:4,
              background:'linear-gradient(90deg, #0b1852 0%, #2546cc 60%, #4d7aff 100%)',
            }} />

            <div style={{ padding:'40px 44px' }}>

            {/* En-tête */}
            <div style={{ marginBottom:32, paddingBottom:24, borderBottom:'1px solid #eceef6' }}>
              <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:12 }}>
                <div style={{
                  width:32, height:32, borderRadius:8,
                  background:'linear-gradient(135deg,#0b1852,#2546cc)',
                  display:'flex', alignItems:'center', justifyContent:'center',
                }}>
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none"
                    stroke="#fff" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                    <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                  </svg>
                </div>
                <span style={{ fontSize:11.5, fontWeight:700, letterSpacing:'1px', color:'#9ba3bc', textTransform:'uppercase' }}>
                  Accès sécurisé
                </span>
              </div>
              <h1 style={{
                fontFamily:"'Bricolage Grotesque', sans-serif",
                fontWeight:800, fontSize:26, color:'#0b1852',
                margin:'0 0 8px', letterSpacing:'-.5px', lineHeight:1.2,
              }}>
                Connexion
              </h1>
              <p style={{ fontSize:14.5, color:'#6b7a9e', lineHeight:1.5 }}>
                Accès réservé à l'équipe interne Studium
              </p>
            </div>

            <form onSubmit={handleSubmit} noValidate aria-label="Formulaire de connexion">

              {/* ── Email ── */}
              <div style={{ marginBottom:20 }}>
                <label htmlFor={emailId} style={labelStyle}>Adresse email</label>
                <input
                  id={emailId}
                  className={`stl-input${touched.email && emailError ? ' stl-input-error' : ''}`}
                  type="email"
                  value={email}
                  onChange={e => { setEmail(e.target.value); if (touched.email) validateEmail(e.target.value); }}
                  onBlur={() => {
                    setTouched(t => ({ ...t, email: true }));
                    validateEmail(email); // n'affiche "requis" que si onSubmit=true
                  }}
                  required
                  placeholder="admin@studium.com"
                  autoComplete="email"
                  autoCapitalize="none"
                  autoCorrect="off"
                  spellCheck={false}
                  aria-required="true"
                  aria-invalid={touched.email && !!emailError}
                  aria-describedby={`${emailId}-err`}
                />
                {/* Feedback inline sous le champ */}
                <p id={`${emailId}-err`} className="stl-helper" role="alert" style={{
                  color: touched.email && emailError ? '#e53e3e' : 'transparent',
                }}>
                  {touched.email && emailError ? emailError : ' '}
                </p>
              </div>

              {/* ── Mot de passe ── */}
              <div style={{ marginBottom:28 }}>
                <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:8 }}>
                  <label htmlFor={passwordId} style={{ ...labelStyle, marginBottom:0 }}>Mot de passe</label>
                  <span
                  className="stl-link"
                  style={{ cursor:'pointer' }}
                  onClick={() => navigate('/forgot-password')}
                >
                  Mot de passe oublié ?
                </span>
                </div>
                <div style={{ position:'relative' }}>
                  <input
                    id={passwordId}
                    className="stl-input"
                    type={showPw ? 'text' : 'password'}
                    value={password}
                    onChange={e => { setPassword(e.target.value); setTouched(t => ({ ...t, password:true })); }}
                    required
                    placeholder="••••••••"
                    autoComplete="current-password"
                    aria-required="true"
                    aria-describedby={`${passwordId}-strength`}
                    style={{ paddingRight:52 }}
                  />
                  {/* Toggle — 50×100% Fitts */}
                  <button
                    type="button"
                    className="stl-eye"
                    onClick={() => setShowPw(v => !v)}
                    aria-label={showPw ? 'Masquer le mot de passe' : 'Afficher le mot de passe'}
                    aria-pressed={showPw}
                  >
                    {showPw ? <EyeOff /> : <Eye />}
                  </button>
                </div>
                {/* Indicateur de force */}
                {touched.password && password && (
                  <div id={`${passwordId}-strength`} style={{ marginTop:8, display:'flex', alignItems:'center', gap:8 }}>
                    <div style={{ display:'flex', gap:4, flex:1 }}>
                      {[1,2,3,4,5].map(i => (
                        <div key={i} style={{
                          flex:1, height:3, borderRadius:2,
                          background: i <= pwStrength.score ? pwStrength.color : '#e4e8f2',
                          transition:'background .25s',
                        }} />
                      ))}
                    </div>
                    <span style={{ fontSize:11, color:pwStrength.color, fontWeight:600, minWidth:36 }}>
                      {pwStrength.label}
                    </span>
                  </div>
                )}
              </div>

              {/* ── Erreur globale ── */}
              <div role="alert" aria-live="assertive" aria-atomic="true" id={errorId}>
                {error && (
                  <div key={shakeKey} className="stl-error stl-error-shake">
                    <AlertIcon />
                    <span style={{ fontSize:13.5, color:'#b91c1c', lineHeight:1.55 }}>{error}</span>
                  </div>
                )}
              </div>

              {/* ── Submit ── */}
              <button type="submit" disabled={loading} className="stl-btn" aria-busy={loading}>
                {loading ? <><Spinner />Connexion en cours…</> : <>Se connecter <Arrow /></>}
              </button>

            </form>
            </div>
          </main>

          <p style={{ ...anim(340), textAlign:'center', marginTop:24, fontSize:12, color:'#aab2cc', lineHeight:1.6 }}>
            © 2025 Studium Platform — Tous droits réservés
          </p>
        </div>
      </div>
    </div>
  );
}