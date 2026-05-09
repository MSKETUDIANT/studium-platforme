import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../../features/auth/hooks/useAuth';
import { useRole } from '../../features/auth/hooks/useRole';
import { supabase } from '../services/supabase';

export default function ProtectedRoute() {
  const { user, loading: authLoading } = useAuth();
  const { isTeam, role, loading: roleLoading } = useRole();

  console.log('ProtectedRoute:', { authLoading, roleLoading, user: user?.email, role, isTeam });

  if (authLoading || roleLoading) {
    return <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>Chargement...</div>;
  }

  if (!user) return <Navigate to="/login" replace />;

  if (!isTeam) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', height: '100vh', gap: 16 }}>
        <h2 style={{ color: '#ff4d4f' }}>Accès refusé</h2>
        <p style={{ color: '#666' }}>Vous n'avez pas les permissions pour accéder au dashboard interne.</p>
        <button
          onClick={async () => { await supabase.auth.signOut(); window.location.href = '/login'; }}
          style={{ padding: '10px 24px', background: '#1677ff', color: '#fff', border: 'none', borderRadius: 6, cursor: 'pointer' }}
        >
          Se déconnecter
        </button>
      </div>
    );
  }

  return <Outlet />;
}