import { useEffect, useState } from 'react';
import { type User } from '@supabase/supabase-js';
import { supabase } from '../../../shared/services/supabase';

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      console.log('useAuth session:', data.session?.user?.email);
      setUser(data.session?.user ?? null);
      setLoading(false);
    });

    const { data: listener } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        console.log('useAuth onChange:', session?.user?.email);
        setUser(session?.user ?? null);
        setLoading(false);
      }
    );

    return () => listener.subscription.unsubscribe();
  }, []);

  return { user, loading };
}