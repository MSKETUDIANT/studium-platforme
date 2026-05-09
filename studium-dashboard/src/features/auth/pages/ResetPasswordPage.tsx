/**
 * ResetPasswordPage — Studium Internal Dashboard
 * Style uniforme avec LoginPage
 */

import { useState, useEffect, useId } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../../shared/services/supabase';
import stlogo from '../../../assets/stlogo.png';

const CSS = `
  @import url('https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,700;12..96,800&family=Plus+Jakarta+Sans:wght@400;500;600&display=swap');

  @keyframes stFadeUp { from{opacity:0;transform:translateY(18px)} to{opacity:1;transform:none} }
  @keyframes stSpin   { to{transform:rotate(360deg)} }

  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after { animation-duration:0.01ms !important; transition-duration:0.01ms !important; }
  }

  .stl-root  { display:flex; flex:1; min-height:100vh; width:100%; font-family:'Plus Jakarta Sans',sans-serif; }

  .stl-left  {
    flex: 0 0 44%; min-height: 100vh; background: #0b1852;
    display: flex; flex-direction: column;
    align-items: center; justify-content: center;
    padding: 60px 52px; position: relative; overflow: hidden; text-align: center;
  }
  .stl-left::before {
    content:''; position:absolute; inset:0; pointer-events:none;
    background-image:
      linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px),
      linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px);
    background-size: 56px 56px;
  }

  .stl-right {
    flex: 1; min-height: 100vh; background: #eef0f7;
    display: flex; align-items: center; justify-content: center;
    padding: 40px 32px;
  }

  .stl-input {
    width: 100%; font-size: 16px; font-family: 'Plus Jakarta Sans', sans-serif;
    padding: 13px 16px; line-height: 1.5;
    border: 1.5px solid #dde1f0; border-radius: 10px;
    color: #0b1852; background: #f5f7fc;
    transition: border-color .18s, box-shadow .18s, background .18s;
    -webkit-appearance: none; appearance: none;
  }
  .stl-input:focus-visible {
    outline: none; border-color: #1e3fb8;
    box-shadow: 0 0 0 4px rgba(30,63,184,0.15); background: #fff;
  }

  .stl-btn {
    width: 100%; min-height: 52px; padding: 14px 20px;
    background: #0b1852; color: #fff; border: none; border-radius: 11px;
    font-family: 'Bricolage Grotesque', sans-serif;
    font-size: 16px; font-weight: 700; letter-spacing: -.1px;
    cursor: pointer; display:flex; align-items:center; justify-content:center; gap:10px;
    transition: background .18s, box-shadow .2s, transform .1s;
    -webkit-tap-highlight-color: transparent;
  }
  .stl-btn:not(:disabled):hover  { background:#16298f; box-shadow:0 8px 28px rgba(11,24,82,0.28); }
  .stl-btn:not(:disabled):active { transform:scale(0.987); }
  .stl-btn:disabled               { background:#7a9bd4; cursor:not-allowed; }

  @media (max-width: 900px) {
    .stl-left  { flex:0 0 38%; padding:48px 32px; }
    .stl-right { padding:32px 20px; }
  }
  @media (max-width: 640px) {
    .stl-root  { flex-direction:column; }
    .stl-left  { flex:none; min-height:auto; width:100%; padding:44px 24px 36px; }
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

const Spinner = () => (
  <svg width="17" height="17" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="#fff" strokeWidth="2.5" strokeLinecap="round"
    style={{ animation:'stSpin .75s linear infinite', flexShrink:0 }}>
    <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/>
  </svg>
);

const Arrow = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
    <line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/>
  </svg>
);

const Orb = ({ style }: { style: React.CSSProperties }) => (
  <div aria-hidden="true" style={{
    position:'absolute', borderRadius:'50%', pointerEvents:'none',
    background:'radial-gradient(circle, rgba(72,128,255,0.22) 0%, transparent 65%)',
    ...style,
  }} />
);

export default function ResetPasswordPage() {
  const navigate    = useNavigate();
  const passwordId  = useId();
  const confirmId   = useId();

  const [password, setPassword]         = useState('');
  const [confirm, setConfirm]           = useState('');
  const [loading, setLoading]           = useState(false);
  const [error, setError]               = useState('');
  const [success, setSuccess]           = useState(false);
  const [sessionReady, setSessionReady] = useState(false);
  const [mounted, setMounted]           = useState(false);

  useEffect(() => {
    setMounted(true);

    const hash = window.location.hash;
    const params = new URLSearchParams(hash.substring(1));
    const accessToken = params.get('access_token');
    const type = params.get('type');

    if (accessToken && (type === 'invite' || type === 'recovery')) {
      // ✅ Échanger le token contre une session
      supabase.auth.verifyOtp({
        token_hash: accessToken,
        type: type === 'invite' ? 'invite' : 'recovery',
      }).then(({ data, error: otpError }) => {
        if (otpError) {
          // Fallback : vérifier session existante
          supabase.auth.getSession().then(({ data: { session } }) => {
            if (session) setSessionReady(true);
            else setError('Lien invalide ou expiré. Demandez une nouvelle invitation.');
          });
        } else if (data.session) {
          setSessionReady(true);
        }
      });
      return;
    }

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if ((event === 'PASSWORD_RECOVERY' || event === 'SIGNED_IN') && session) {
        setSessionReady(true);
      }
    });

    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) setSessionReady(true);
    });

    return () => subscription.unsubscribe();
  }, []);

  const anim = (d: number): React.CSSProperties =>
    mounted ? { animation:`stFadeUp .5s cubic-bezier(.25,.75,.25,1) ${d}ms both` } : { opacity:0 };

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (password !== confirm) { setError('Les mots de passe ne correspondent pas.'); return; }
    if (password.length < 8)  { setError('Minimum 8 caractères requis.'); return; }
    setError(''); setLoading(true);
    try {
      const { error: updateError } = await supabase.auth.updateUser({ password });
      if (updateError) throw updateError;
      setSuccess(true);
      setTimeout(() => navigate('/applications'), 2500);
    } catch (e: any) {
      setError(e.message ?? 'Erreur lors de la mise à jour.');
    } finally {
      setLoading(false);
    }
  }

  const labelStyle: React.CSSProperties = {
    display:'block', marginBottom:9,
    fontSize:12.5, fontWeight:700, letterSpacing:'0.09em',
    textTransform:'uppercase', color:'#3d4a68',
  };

  if (success) return (
    <div className="stl-root">
      <aside className="stl-left">
        <Orb style={{ width:400, height:400, top:-120, right:-100 }} />
        <Orb style={{ width:280, height:280, bottom:-70, left:-80, opacity:0.6 }} />
        <img src={stlogo} alt="Studium" style={{ width:300, filter:'brightness(0) invert(1)', zIndex:1 }} />
      </aside>
      <div className="stl-right">
        <div style={{ textAlign:'center' }}>
          <div style={{ fontSize:64, marginBottom:16 }}>✅</div>
          <h2 style={{ fontFamily:"'Bricolage Grotesque',sans-serif", fontSize:26, color:'#0b1852', marginBottom:8 }}>
            Mot de passe défini !
          </h2>
          <p style={{ color:'#6b7a9e' }}>Redirection vers le dashboard...</p>
        </div>
      </div>
    </div>
  );

  if (!sessionReady) return (
    <div className="stl-root">
      <aside className="stl-left">
        <Orb style={{ width:400, height:400, top:-120, right:-100 }} />
        <Orb style={{ width:280, height:280, bottom:-70, left:-80, opacity:0.6 }} />
        <img src={stlogo} alt="Studium" style={{ width:300, filter:'brightness(0) invert(1)', zIndex:1 }} />
      </aside>
      <div className="stl-right">
        <div style={{ textAlign:'center' }}>
          {error ? (
            <>
              <div style={{ fontSize:48, marginBottom:16 }}>⚠️</div>
              <p style={{ color:'#dc2626', fontSize:15 }}>{error}</p>
            </>
          ) : (
            <>
              <Spinner />
              <p style={{ color:'#6b7a9e', marginTop:16 }}>Vérification du lien d'invitation...</p>
            </>
          )}
        </div>
      </div>
    </div>
  );

  return (
    <div className="stl-root">

      {/* ══════════ PANEL GAUCHE ══════════ */}
      <aside className="stl-left" aria-label="Présentation Studium">
        <Orb style={{ width:400, height:400, top:-120, right:-100 }} />
        <Orb style={{ width:280, height:280, bottom:-70, left:-80, opacity:0.6 }} />

        <div style={{ ...anim(0), zIndex:1 }}>
          <img src={stlogo} alt="Studium — Étudier Partout Dans le Monde"
            style={{ width:300, display:'block', margin:'0 auto', filter:'brightness(0) invert(1)' }} />
        </div>

        <div aria-hidden="true" style={{
          ...anim(100), zIndex:1,
          width:36, height:2, background:'rgba(255,255,255,0.15)',
          borderRadius:2, margin:'30px auto',
        }} />

        <p style={{
          ...anim(180), zIndex:1,
          fontSize:14.5, color:'rgba(255,255,255,0.70)',
          lineHeight:1.9, maxWidth:270,
        }}>
          Bienvenue dans{' '}
          <strong style={{ color:'#ffffff', fontWeight:600 }}>l'équipe Studium</strong>
          {' '}— définissez votre mot de passe pour accéder au dashboard.
        </p>
      </aside>

      {/* ══════════ PANEL DROIT ══════════ */}
      <div className="stl-right">
        <div style={{ width:'100%', maxWidth:420 }}>
          <main className="stl-card" style={{
            ...anim(260),
            background:'#fff', borderRadius:20, padding:'48px 44px',
            border:'1px solid rgba(11,24,82,0.08)',
            boxShadow:'0 1px 4px rgba(11,24,82,0.04), 0 8px 24px rgba(11,24,82,0.07), 0 28px 60px rgba(11,24,82,0.08)',
          }}>

            <div style={{ marginBottom:32, paddingBottom:24, borderBottom:'1px solid #eceef6' }}>
              <h1 style={{
                fontFamily:"'Bricolage Grotesque', sans-serif",
                fontWeight:800, fontSize:26, color:'#0b1852',
                margin:'0 0 8px', letterSpacing:'-.5px', lineHeight:1.2,
              }}>
                Définir mon mot de passe
              </h1>
              <p style={{ fontSize:14.5, color:'#6b7a9e', lineHeight:1.5 }}>
                Choisissez un mot de passe sécurisé pour votre compte.
              </p>
            </div>

            <form onSubmit={handleSubmit} noValidate>

              <div style={{ marginBottom:20 }}>
                <label htmlFor={passwordId} style={labelStyle}>Mot de passe</label>
                <input
                  id={passwordId}
                  className="stl-input"
                  type="password"
                  placeholder="Minimum 8 caractères"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  required
                  autoComplete="new-password"
                />
              </div>

              <div style={{ marginBottom:28 }}>
                <label htmlFor={confirmId} style={labelStyle}>Confirmer le mot de passe</label>
                <input
                  id={confirmId}
                  className="stl-input"
                  type="password"
                  placeholder="Répétez le mot de passe"
                  value={confirm}
                  onChange={e => setConfirm(e.target.value)}
                  required
                  autoComplete="new-password"
                />
              </div>

              {error && (
                <div style={{
                  display:'flex', alignItems:'flex-start', gap:10,
                  background:'#fef2f2', border:'1.5px solid #fca5a5',
                  borderRadius:10, padding:'12px 14px', marginBottom:22,
                }}>
                  <span style={{ fontSize:13.5, color:'#b91c1c', lineHeight:1.55 }}>⚠️ {error}</span>
                </div>
              )}

              <button type="submit" disabled={loading} className="stl-btn">
                {loading
                  ? <><Spinner />Enregistrement...</>
                  : <>🔐 Définir mon mot de passe <Arrow /></>
                }
              </button>

            </form>
          </main>

          <p style={{ ...anim(340), textAlign:'center', marginTop:24, fontSize:12, color:'#aab2cc', lineHeight:1.6 }}>
            © 2025 Studium Platform — Tous droits réservés
          </p>
        </div>
      </div>
    </div>
  );
}