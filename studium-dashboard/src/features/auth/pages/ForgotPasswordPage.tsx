import { useState, useId } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../../shared/services/supabase';
import stlogo from '../../../assets/stlogo.png';

const Orb = ({ style }: { style: React.CSSProperties }) => (
  <div aria-hidden="true" style={{
    position:'absolute', borderRadius:'50%', pointerEvents:'none',
    background:'radial-gradient(circle, rgba(72,128,255,0.22) 0%, transparent 65%)',
    ...style,
  }} />
);

export default function ForgotPasswordPage() {
  const navigate  = useNavigate();
  const emailId   = useId();
  const [email, setEmail]     = useState('');
  const [loading, setLoading] = useState(false);
  const [sent, setSent]       = useState(false);
  const [error, setError]     = useState('');

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

  const labelStyle: React.CSSProperties = {
    display:'block', marginBottom:9,
    fontSize:12.5, fontWeight:700, letterSpacing:'0.09em',
    textTransform:'uppercase', color:'#3d4a68',
  };

  return (
    <div className="stl-root">
      {/* Panel gauche */}
      <aside className="stl-left" aria-label="Présentation Studium">
        <Orb style={{ width:400, height:400, top:-120, right:-100 }} />
        <Orb style={{ width:280, height:280, bottom:-70, left:-80, opacity:0.6 }} />
        <div style={{ zIndex:1 }}>
          <img src={stlogo} alt="Studium" style={{ width:300, display:'block', margin:'0 auto', filter:'brightness(0) invert(1)' }} />
        </div>
        <div aria-hidden="true" style={{ zIndex:1, width:36, height:2, background:'rgba(255,255,255,0.15)', borderRadius:2, margin:'30px auto' }} />
        <p style={{ zIndex:1, fontSize:14.5, color:'rgba(255,255,255,0.70)', lineHeight:1.9, maxWidth:270, textAlign:'center' }}>
          Réinitialisez votre mot de passe pour accéder au{' '}
          <strong style={{ color:'#ffffff', fontWeight:600 }}>dashboard Studium</strong>.
        </p>
      </aside>

      {/* Panel droit */}
      <div className="stl-right">
        <div style={{ width:'100%', maxWidth:420 }}>
          <main style={{
            background:'#fff', borderRadius:20, padding:'48px 44px',
            border:'1px solid rgba(11,24,82,0.08)',
            boxShadow:'0 1px 4px rgba(11,24,82,0.04), 0 8px 24px rgba(11,24,82,0.07)',
          }}>
            {sent ? (
              <div style={{ textAlign:'center' }}>
                <div style={{ fontSize:52, marginBottom:16 }}>📧</div>
                <h2 style={{ fontFamily:"'Bricolage Grotesque',sans-serif", fontSize:22, fontWeight:800, color:'#0b1852', marginBottom:10 }}>
                  Email envoyé !
                </h2>
                <p style={{ fontSize:14, color:'#6b7a9e', lineHeight:1.6, marginBottom:28 }}>
                  Un lien de réinitialisation a été envoyé à <strong>{email}</strong>.<br/>
                  Vérifiez votre boîte mail.
                </p>
                <button
                  onClick={() => navigate('/login')}
                  className="stl-btn"
                  style={{ background:'#0b1852', cursor:'pointer' }}
                >
                  Retour à la connexion
                </button>
              </div>
            ) : (
              <>
                <div style={{ marginBottom:32, paddingBottom:24, borderBottom:'1px solid #eceef6' }}>
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

                <form onSubmit={handleSubmit} noValidate>
                  <div style={{ marginBottom:24 }}>
                    <label htmlFor={emailId} style={labelStyle}>Adresse email</label>
                    <input
                      id={emailId}
                      className="stl-input"
                      type="email"
                      placeholder="admin@studium.com"
                      value={email}
                      onChange={e => setEmail(e.target.value)}
                      required
                      autoComplete="email"
                    />
                  </div>

                  {error && (
                    <div style={{
                      display:'flex', gap:10,
                      background:'#fef2f2', border:'1.5px solid #fca5a5',
                      borderRadius:10, padding:'12px 14px', marginBottom:22,
                    }}>
                      <span style={{ fontSize:13.5, color:'#b91c1c' }}>⚠️ {error}</span>
                    </div>
                  )}

                  <button type="submit" disabled={loading} className="stl-btn" style={{
                    background: loading ? '#7a9bd4' : '#0b1852',
                    cursor: loading ? 'not-allowed' : 'pointer',
                  }}>
                    {loading ? 'Envoi...' : 'Envoyer le lien'}
                  </button>

                  <div style={{ textAlign:'center', marginTop:20 }}>
                    <span
                      onClick={() => navigate('/login')}
                      style={{ fontSize:13.5, color:'#4e5a78', cursor:'pointer', textDecoration:'underline' }}
                    >
                      ← Retour à la connexion
                    </span>
                  </div>
                </form>
              </>
            )}
          </main>
          <p style={{ textAlign:'center', marginTop:24, fontSize:12, color:'#aab2cc' }}>
            © 2025 Studium Platform — Tous droits réservés
          </p>
        </div>
      </div>
    </div>
  );
}