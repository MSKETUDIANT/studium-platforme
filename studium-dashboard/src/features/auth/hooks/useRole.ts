import { useEffect, useState } from 'react';
import { supabase } from '../../../shared/services/supabase';
import { useAuth } from './useAuth';

export type UserRole = 'admin' | 'admissions' | 'support' | 'manager' | 'student' | 'ambassador';

export function useRole() {
  const { user, loading: authLoading } = useAuth();
  const [role, setRole]     = useState<UserRole | null>(null);
  const [status, setStatus] = useState<string | null>(null);  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (authLoading) return;

    if (!user) {
      setRole(null);
      setStatus(null);
      setLoading(false);
      return;
    }

    supabase
      .from('user_roles')
      .select('roles(name), status')      .eq('user_id', user.id)
      .maybeSingle()
      .then(({ data, error }) => {
        if (error || !data) {
          setRole(null);
          setStatus(null);
        } else {
          const roleName = (data?.roles as any)?.name as UserRole;
          setRole(roleName ?? null);
          setStatus((data as any).status ?? null);        }
        setLoading(false);
      });
  }, [user, authLoading]);

  const isAdmin    = role === 'admin';
  const isTeam     = ['admin', 'admissions', 'support', 'manager'].includes(role ?? '');
  const isStudent  = role === 'student';
  const isActive   = status === 'active';    const isInactive = status === 'inactive';
  return { role, status, loading, isAdmin, isTeam, isStudent, isActive, isInactive };
}