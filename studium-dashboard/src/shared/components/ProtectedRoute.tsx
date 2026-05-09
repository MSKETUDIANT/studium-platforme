import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../../features/auth/hooks/useAuth';
import { useRole } from '../../features/auth/hooks/useRole';
import { supabase } from '../services/supabase';

export default function ProtectedRoute() {
  const { user, loading: authLoading } = useAuth();
  const { isTeam, isInactive, loading: roleLoading } = useRole();
  const location = useLocation();

  if (authLoading || roleLoading) {
    return (
      <div style={{ display:'flex', justifyContent:'center', alignItems:'center', height:'100vh' }}>
        Chargement...
      </div>
    );
  }

  // ✅ Si l'URL contient un token d'invitation, laisser passer vers /reset-password
  const hash = window.location.hash;
  if (hash.includes('type=invite') || hash.includes('type=recovery') || location.pathname === '/reset-password') {
    return <Navigate to="/reset-password" replace />;
  }

  if (!user) return <Navigate to="/login" replace />;

  if (!isTeam) {
    return (
      <div style={{ display:'flex', flexDirection:'column', justifyContent:'center', alignItems:'center', height:'100vh', gap:16 }}>
        <h2 style={{ color:'#ff4d4f' }}>Accès refusé</h2>
        <p style={{ color:'#666' }}>Vous n'avez pas les permissions pour accéder au dashboard interne.</p>
        <button
          onClick={async () => { await supabase.auth.signOut(); window.location.href = '/login'; }}
          style={{ padding:'10px 24px', background:'#1677ff', color:'#fff', border:'none', borderRadius:6, cursor:'pointer' }}
        >
          Se déconnecter
        </button>
      </div>
    );
  }

  if (isInactive) {
    return (
      <div style={{ display:'flex', flexDirection:'column', justifyContent:'center', alignItems:'center', height:'100vh', gap:16 }}>
        <div style={{ fontSize:48 }}>🔒</div>
        <h2 style={{ color:'#ff4d4f', margin:0 }}>Compte désactivé</h2>
        <p style={{ color:'#666', textAlign:'center', maxWidth:360 }}>
          Votre compte a été désactivé par l'administrateur.<br />
          Contactez l'équipe Studium pour plus d'informations.
        </p>
        <button
          onClick={async () => { await supabase.auth.signOut(); window.location.href = '/login'; }}
          style={{ padding:'10px 24px', background:'#ff4d4f', color:'#fff', border:'none', borderRadius:6, cursor:'pointer', fontWeight:600 }}
        >
          Se déconnecter
        </button>
      </div>
    );
  }

  return <Outlet />;
}