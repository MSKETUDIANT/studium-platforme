import { useState, useEffect, useId } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../../shared/services/supabase';
import stlogo from '../../../assets/stlogo.png';

/* ─── CSS partagé (même guard que LoginPage / ForgotPasswordPage) ─────── */
const CSS = `
  @import url('https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,700;12..96,800&family=Plus+Jakarta+Sans:wght@400;500;600&display=swap');

  @keyframes stFadeUp { from{opacity:0;transform:translateY(18px)} to{opacity:1;transform:none} }
  @keyframes stSpin   { to{transform:rotate(360deg)} }
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
    padding: 60px 52px; position: relative; overflow: hidden; text-align: center;
  }
  .stl-left::before {
    content:''; position:absolute; inset:0; pointer-events:none;
    background-image:
      linear-gradient(rgba(255,255,255,0.04) 1px, transparent 1px),
      linear-gradient(90deg, rgba(255,255,255,0.04) 1px, transparent 1px);
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

  .stl-eye {
    position:absolute; right:0; top:0; width:50px; height:100%;
    display:flex; align-items:center; justify-content:center;
    background:none; border:none; cursor:pointer; color:#aab2cc;
    border-radius:0 10px 10px 0; transition: color .15s;
    -webkit-tap-highlight-color: transparent;
  }
  .stl-eye:hover { color:#1e3fb8; }

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
const IconLock = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="rgba(255,255,255,0.80)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
    <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
  </svg>
);
const IconShieldCheck = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="rgba(255,255,255,0.80)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
    <polyline points="9 12 11 14 15 10"/>
  </svg>
);
const IconKey = () => (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="rgba(255,255,255,0.80)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"/>
  </svg>
);

const RP_FEATURES: { label: string; Icon: () => React.ReactElement }[] = [
  { label: 'Chiffré',   Icon: IconShieldCheck },
  { label: 'Sécurisé',  Icon: IconLock        },
  { label: 'Nouveau',   Icon: IconKey         },
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

const Arrow = () => (
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true"
    stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
    <line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/>
  </svg>
);

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

/* ─── Password strength ──────────────────────────────────────────────────── */
function passwordStrength(pw: string) {
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

/* ─── Shared left panel ──────────────────────────────────────────────────── */
function LeftPanel() {
  return (
    <aside className="stl-left" aria-label="Présentation Studium">
      <Orb style={{ width:400, height:400, top:-120, right:-100 }} />
      <Orb style={{ width:280, height:280, bottom:-70, left:-80, opacity:0.6 }} />

      <div style={{ zIndex:1 }}>
        <img src={stlogo} alt="Studium" className="stl-logo"
          style={{ width:300, display:'block', margin:'0 auto', filter:'brightness(0) invert(1)' }} />
      </div>

      <div aria-hidden="true" style={{
        zIndex:1, width:36, height:2,
        background:'rgba(255,255,255,0.15)', borderRadius:2, margin:'28px auto',
      }} />

      <p style={{
        zIndex:1, fontSize:14.5, color:'rgba(255,255,255,0.70)',
        lineHeight:1.9, maxWidth:270, textAlign:'center',
      }}>
        Bienvenue dans{' '}
        <strong style={{ color:'#ffffff', fontWeight:600 }}>l'équipe Studium</strong>
        {' '}— définissez votre mot de passe pour accéder au dashboard.
      </p>

      <div style={{
        zIndex:1, display:'flex', gap:10, marginTop:32,
        flexWrap:'wrap', justifyContent:'center',
      }}>
        {RP_FEATURES.map(f => (
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
  );
}

/* ═══════════════════════════════════════════════════════════════════════════ */
export default function ResetPasswordPage() {
  const navigate   = useNavigate();
  const passwordId = useId();
  const confirmId  = useId();

  const [password, setPassword]         = useState('');
  const [confirm, setConfirm]           = useState('');
  const [showPw, setShowPw]             = useState(false);
  const [showConfirm, setShowConfirm]   = useState(false);
  const [loading, setLoading]           = useState(false);
  const [error, setError]               = useState('');
  const [success, setSuccess]           = useState(false);
  const [sessionReady, setSessionReady] = useState(false);
  const [mounted, setMounted]           = useState(false);

  const pwStrength = passwordStrength(password);

  useEffect(() => {
    setMounted(true);

    const hash   = window.location.hash;
    const params = new URLSearchParams(hash.substring(1));
    const accessToken = params.get('access_token');
    const type        = params.get('type');

    if (accessToken && (type === 'invite' || type === 'recovery')) {
      supabase.auth.verifyOtp({
        token_hash: accessToken,
        type: type === 'invite' ? 'invite' : 'recovery',
      }).then(({ data, error: otpError }) => {
        if (otpError) {
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
    if (password.length < 8)      { setError('Minimum 8 caractères requis.'); return; }
    if (password !== confirm)     { setError('Les mots de passe ne correspondent pas.'); return; }
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

  /* ── État succès ── */
  if (success) return (
    <div className="stl-root">
      <LeftPanel />
      <div className="stl-right">
        <div style={{ textAlign:'center', maxWidth:340 }}>
          <div style={{
            width:80, height:80, borderRadius:'50%', margin:'0 auto 20px',
            background:'linear-gradient(135deg, #d1fae5, #a7f3d0)',
            display:'flex', alignItems:'center', justifyContent:'center',
            animation:'stPop .55s cubic-bezier(.34,1.56,.64,1) both',
          }}>
            <svg width="36" height="36" viewBox="0 0 24 24" fill="none"
              stroke="#059669" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
              <polyline points="20 6 9 17 4 12"/>
            </svg>
          </div>
          <h2 style={{ fontFamily:"'Bricolage Grotesque',sans-serif", fontSize:26, fontWeight:800, color:'#0b1852', marginBottom:8 }}>
            Mot de passe défini !
          </h2>
          <p style={{ color:'#6b7a9e', fontSize:14.5, lineHeight:1.6, marginBottom:6 }}>
            Votre compte est maintenant sécurisé.
          </p>
          <p style={{ color:'#9ba3bc', fontSize:13 }}>Redirection vers le dashboard…</p>
        </div>
      </div>
    </div>
  );

  /* ── État chargement / lien invalide ── */
  if (!sessionReady) return (
    <div className="stl-root">
      <LeftPanel />
      <div className="stl-right">
        <div style={{ textAlign:'center', maxWidth:320 }}>
          {error ? (
            <>
              <div style={{
                width:72, height:72, borderRadius:'50%', margin:'0 auto 20px',
                background:'#fef2f2', display:'flex', alignItems:'center', justifyContent:'center',
                animation:'stPop .5s cubic-bezier(.34,1.56,.64,1) both',
              }}>
                <svg width="30" height="30" viewBox="0 0 24 24" fill="none"
                  stroke="#dc2626" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <circle cx="12" cy="12" r="10"/>
                  <line x1="12" y1="8" x2="12" y2="12"/>
                  <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
              </div>
              <h3 style={{ fontFamily:"'Bricolage Grotesque',sans-serif", fontSize:20, color:'#0b1852', marginBottom:8 }}>
                Lien invalide
              </h3>
              <p style={{ color:'#6b7a9e', fontSize:14, lineHeight:1.6, marginBottom:24 }}>{error}</p>
              <button className="stl-btn" onClick={() => navigate('/login')}>
                Retour à la connexion
              </button>
            </>
          ) : (
            <>
              <div style={{ display:'flex', justifyContent:'center', marginBottom:20 }}>
                <Spinner />
              </div>
              <p style={{ color:'#6b7a9e', fontSize:14 }}>Vérification du lien…</p>
            </>
          )}
        </div>
      </div>
    </div>
  );

  /* ── Formulaire principal ── */
  return (
    <div className="stl-root">

      <LeftPanel />

      <div className="stl-right">
        <div style={{ width:'100%', maxWidth:420 }}>

          <main className="stl-card" style={{
            ...anim(260),
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
                    Sécurisation du compte
                  </span>
                </div>
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

                {/* Mot de passe */}
                <div style={{ marginBottom:20 }}>
                  <label htmlFor={passwordId} style={labelStyle}>Mot de passe</label>
                  <div style={{ position:'relative' }}>
                    <input
                      id={passwordId}
                      className="stl-input"
                      type={showPw ? 'text' : 'password'}
                      placeholder="Minimum 8 caractères"
                      value={password}
                      onChange={e => { setPassword(e.target.value); if (error) setError(''); }}
                      required
                      autoComplete="new-password"
                      autoFocus
                      style={{ paddingRight:52 }}
                    />
                    <button type="button" className="stl-eye"
                      onClick={() => setShowPw(v => !v)}
                      aria-label={showPw ? 'Masquer' : 'Afficher'}>
                      {showPw ? <EyeOff /> : <Eye />}
                    </button>
                  </div>
                  {/* Strength bar */}
                  {password && (
                    <div style={{ marginTop:8, display:'flex', alignItems:'center', gap:8 }}>
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

                {/* Confirmer */}
                <div style={{ marginBottom:28 }}>
                  <label htmlFor={confirmId} style={labelStyle}>Confirmer le mot de passe</label>
                  <div style={{ position:'relative' }}>
                    <input
                      id={confirmId}
                      className={`stl-input${confirm && confirm !== password ? ' stl-input-error' : ''}`}
                      type={showConfirm ? 'text' : 'password'}
                      placeholder="Répétez le mot de passe"
                      value={confirm}
                      onChange={e => { setConfirm(e.target.value); if (error) setError(''); }}
                      required
                      autoComplete="new-password"
                      style={{ paddingRight:52 }}
                    />
                    <button type="button" className="stl-eye"
                      onClick={() => setShowConfirm(v => !v)}
                      aria-label={showConfirm ? 'Masquer' : 'Afficher'}>
                      {showConfirm ? <EyeOff /> : <Eye />}
                    </button>
                  </div>
                  {confirm && confirm !== password && (
                    <p style={{ fontSize:12.5, color:'#e53e3e', marginTop:6 }}>
                      Les mots de passe ne correspondent pas
                    </p>
                  )}
                </div>

                {/* Erreur globale */}
                {error && (
                  <div className="stl-error">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
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
                  {loading
                    ? <><Spinner />Enregistrement…</>
                    : <>Définir mon mot de passe <Arrow /></>
                  }
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