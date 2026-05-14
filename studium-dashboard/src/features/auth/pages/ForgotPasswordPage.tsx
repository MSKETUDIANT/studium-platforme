import { useState, useId } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../../shared/services/supabase';
import stlogo from '../../../assets/stlogo.png';

/* ─── CSS partagé (même guard que LoginPage) ────────────────────────────── */
const CSS = `
  @import url('https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,700;12..96,800&family=Plus+Jakarta+Sans:wght@400;500;600&display=swap');

  @keyframes stFadeUp { from{opacity:0;transform:translateY(18px)} to{opacity:1;transform:none} }
  @keyframes stSpin   { to{transform:rotate(360deg)} }
  @keyframes stShake  { 0%,100%{transform:translateX(0)} 20%,60%{transform:translateX(-5px)} 40%,80%{transform:translateX(5px)} }
  @keyframes stPop    { 0%{transform:scale(.6);opacity:0} 70%{transform:scale(1.1)} 100%{transform:scale(1);opacity:1} }

  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after { animation-duration:0.01ms !important; transition-duration:0.01ms !important; }
  }

  .stl-root  { display:flex; flex:1; min-height:100vh; width:100%; font-family:'Plus Jakarta Sans',sans-serif; }

  .stl-left  {
    flex: 0 0 44%; min-height: 100vh;
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

  .stl-right {
    flex: 1; min-height: 100vh;
    background: #eef0f7;
    display: flex; align-items: center; justify-content: center;
    padding: 40px 32px;
  }

  .stl-input {
    width: 100%; font-size: 16px; font-family: 'Plus Jakarta Sans', sans-serif;
    padding: 13px 16px; line-height: 1.5;
    border: 1.5px solid #dde1f0; border-radius: 10px;
    color: #0b1852; background: #f5f7fc;
    transition: border-color .18s, box-shadow .18s, background .18s;
    -webkit-appearance: none; appearance: none; box-sizing: border-box;
  }
  .stl-input:hover:not(:focus-visible) { border-color: #c2cadf; }
  .stl-input:focus-visible {
    outline: none; border-color: #1e3fb8;
    box-shadow: 0 0 0 4px rgba(30,63,184,0.15); background: #fff;
  }
  .stl-input.stl-input-error { border-color: #f87171 !important; background: #fff8f8; }

  .stl-btn {
    width: 100%; min-height: 52px; padding: 14px 20px;
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

  .stl-link {
    font-size:13.5px; color:#4e5a78; font-weight:500; text-decoration:none;
    cursor:pointer; transition:color .15s; padding:4px 2px;
  }
  .stl-link:hover { color:#1e3fb8; text-decoration:underline; }

  .stl-error { display:flex; align-items:flex-start; gap:10px; background:#fef2f2; border:1.5px solid #fca5a5; border-radius:10px; padding:12px 14px; margin-bottom:22px; }

  @media (max-width: 900px) {
    .stl-left  { flex:0 0 38%; padding:48px 32px; }
    .stl-right { padding:32px 20px; }
    .stl-logo  { width:240px !important; }
  }
  @media (max-width: 640px) {
    .stl-root  { flex-direction:column; }
    .stl-left  { flex:none; min-height:auto; width:100%; padding:44px 24px 36px; }
    .stl-logo  { width:200px !important; }
    .stl-right { flex:none; min-height:auto; width:100%; padding:28px 16px 52px; }
    .stl-card  { padding:32px 22px !important; border-radius:16px !important; }
  }
`;

if (!document.getElementById('stl-css')) {
  const s = document.createElement('style');
  s.id = 'stl-css';
  s.textContent = CSS;
  document.head.appendChild(s);
}

/* ─── Icons ─────────────────────────────────────────────────────────────── */
const IconMail = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="rgba(255,255,255,0.80)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
    <polyline points="22,6 12,13 2,6"/>
  </svg>
);
const IconShield = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="rgba(255,255,255,0.80)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
  </svg>
);
const IconClock = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="rgba(255,255,255,0.80)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="12" r="10"/>
    <polyline points="12 6 12 12 16 14"/>
  </svg>
);

const FP_FEATURES: { label: string; Icon: () => React.ReactElement }[] = [
  { label: 'Lien sécurisé', Icon: IconShield },
  { label: 'Par email',     Icon: IconMail   },
  { label: 'Valide 1h',     Icon: IconClock  },
];

const Orb = ({ style }: { style: React.CSSProperties }) => (
  <div aria-hidden="true" style={{
    position:'absolute', borderRadius:'50%', pointerEvents:'none',
    background:'radial-gradient(circle, rgba(72,128,255,0.22) 0%, transparent 65%)',
    ...style,
  }} />
);

const Spinner = () => (
  <svg width="17" height="17" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="#fff" strokeWidth="2.5" strokeLinecap="round"
    style={{ animation:'stSpin .75s linear infinite', flexShrink:0 }}>
    <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/>
  </svg>
);

/* ═══════════════════════════════════════════════════════════════════════════ */
export default function ForgotPasswordPage() {
  const navigate = useNavigate();
  const emailId  = useId();

  const [email, setEmail]     = useState('');
  const [loading, setLoading] = useState(false);
  const [sent, setSent]       = useState(false);
  const [error, setError]     = useState('');

  const labelStyle: React.CSSProperties = {
    display:'block', marginBottom:9,
    fontSize:12.5, fontWeight:700, letterSpacing:'0.09em',
    textTransform:'uppercase', color:'#3d4a68',
  };

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!email) { setError('Veuillez saisir votre adresse email.'); return; }
    setError(''); setLoading(true);
    try {
      const { error: err } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: 'http://localhost:5173/reset-password',
      });
      if (err) throw err;
      setSent(true);
    } catch (e: any) {
      setError(e.message ?? 'Une erreur est survenue.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="stl-root">

      {/* ══════════ PANEL GAUCHE ══════════ */}
      <aside className="stl-left" aria-label="Présentation Studium">
        <Orb style={{ width:400, height:400, top:-120, right:-100 }} />
        <Orb style={{ width:280, height:280, bottom:-70, left:-80, opacity:0.6 }} />

        <div style={{ zIndex:1 }}>
          <img
            src={stlogo} alt="Studium" className="stl-logo"
            style={{ width:300, display:'block', margin:'0 auto', filter:'brightness(0) invert(1)' }}
          />
        </div>

        <div aria-hidden="true" style={{
          zIndex:1, width:36, height:2,
          background:'rgba(255,255,255,0.15)', borderRadius:2, margin:'28px auto',
        }} />

        <p style={{
          zIndex:1, fontSize:14.5, color:'rgba(255,255,255,0.70)',
          lineHeight:1.9, maxWidth:270, textAlign:'center',
        }}>
          Réinitialisez votre mot de passe pour accéder au{' '}
          <strong style={{ color:'#ffffff', fontWeight:600 }}>dashboard Studium</strong>.
        </p>

        {/* Feature chips */}
        <div style={{
          zIndex:1, display:'flex', gap:10, marginTop:32,
          flexWrap:'wrap', justifyContent:'center',
        }}>
          {FP_FEATURES.map(f => (
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
            background:'#fff', borderRadius:20, padding:0,
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

              {sent ? (
                /* ── État envoyé ── */
                <div style={{ textAlign:'center', padding:'8px 0' }}>
                  <div style={{
                    width:72, height:72, borderRadius:'50%', margin:'0 auto 20px',
                    background:'linear-gradient(135deg, #e0f2fe, #dbeafe)',
                    display:'flex', alignItems:'center', justifyContent:'center',
                    animation:'stPop .5s cubic-bezier(.34,1.56,.64,1) both',
                  }}>
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none"
                      stroke="#2546cc" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                      <polyline points="22,6 12,13 2,6"/>
                    </svg>
                  </div>
                  <h2 style={{
                    fontFamily:"'Bricolage Grotesque',sans-serif",
                    fontSize:22, fontWeight:800, color:'#0b1852', marginBottom:10,
                  }}>
                    Email envoyé !
                  </h2>
                  <p style={{ fontSize:14, color:'#6b7a9e', lineHeight:1.7, marginBottom:28 }}>
                    Un lien de réinitialisation a été envoyé à<br/>
                    <strong style={{ color:'#0b1852' }}>{email}</strong>
                  </p>
                  <p style={{ fontSize:12.5, color:'#9ba3bc', marginBottom:28 }}>
                    Pensez à vérifier vos spams si vous ne le recevez pas.
                  </p>
                  <button onClick={() => navigate('/login')} className="stl-btn">
                    ← Retour à la connexion
                  </button>
                </div>
              ) : (
                <>
                  {/* ── En-tête ── */}
                  <div style={{ marginBottom:32, paddingBottom:24, borderBottom:'1px solid #eceef6' }}>
                    <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:12 }}>
                      <div style={{
                        width:32, height:32, borderRadius:8,
                        background:'linear-gradient(135deg,#0b1852,#2546cc)',
                        display:'flex', alignItems:'center', justifyContent:'center',
                      }}>
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none"
                          stroke="#fff" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                          <polyline points="22,6 12,13 2,6"/>
                        </svg>
                      </div>
                      <span style={{ fontSize:11.5, fontWeight:700, letterSpacing:'1px', color:'#9ba3bc', textTransform:'uppercase' }}>
                        Récupération de compte
                      </span>
                    </div>
                    <h1 style={{
                      fontFamily:"'Bricolage Grotesque', sans-serif",
                      fontWeight:800, fontSize:26, color:'#0b1852',
                      margin:'0 0 8px', letterSpacing:'-.5px',
                    }}>
                      Mot de passe oublié
                    </h1>
                    <p style={{ fontSize:14.5, color:'#6b7a9e', lineHeight:1.5 }}>
                      Entrez votre email pour recevoir un lien de réinitialisation.
                    </p>
                  </div>

                  {/* ── Form ── */}
                  <form onSubmit={handleSubmit} noValidate>
                    <div style={{ marginBottom:24 }}>
                      <label htmlFor={emailId} style={labelStyle}>Adresse email</label>
                      <input
                        id={emailId}
                        className="stl-input"
                        type="email"
                        placeholder="admin@studium.com"
                        value={email}
                        onChange={e => { setEmail(e.target.value); if (error) setError(''); }}
                        required
                        autoComplete="email"
                        autoFocus
                      />
                    </div>

                    {error && (
                      <div className="stl-error" style={{ marginBottom:22 }}>
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true"
                          stroke="#b91c1c" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"
                          style={{ flexShrink:0, marginTop:2 }}>
                          <circle cx="12" cy="12" r="10"/>
                          <line x1="12" y1="8" x2="12" y2="12"/>
                          <line x1="12" y1="16" x2="12.01" y2="16"/>
                        </svg>
                        <span style={{ fontSize:13.5, color:'#b91c1c', lineHeight:1.55 }}>{error}</span>
                      </div>
                    )}

                    <button type="submit" disabled={loading} className="stl-btn">
                      {loading ? <><Spinner />Envoi en cours…</> : 'Envoyer le lien'}
                    </button>

                    <div style={{ textAlign:'center', marginTop:20 }}>
                      <span className="stl-link" onClick={() => navigate('/login')}>
                        ← Retour à la connexion
                      </span>
                    </div>
                  </form>
                </>
              )}
            </div>
          </main>

          <p style={{ textAlign:'center', marginTop:24, fontSize:12, color:'#aab2cc', lineHeight:1.6 }}>
            © 2025 Studium Platform — Tous droits réservés
          </p>
        </div>
      </div>
    </div>
  );
}