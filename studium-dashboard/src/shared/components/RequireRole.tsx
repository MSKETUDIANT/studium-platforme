import { Navigate, Outlet } from 'react-router-dom';
import { useRole } from '../../features/auth/hooks/useRole';
import type { UserRole } from '../../features/auth/hooks/useRole';

interface Props {
  roles: UserRole[];
}

export default function RequireRole({ roles }: Props) {
  const { role, loading } = useRole();
  if (loading) return null;
  if (!role || !roles.includes(role)) return <Navigate to="/applications" replace />;
  return <Outlet />;
}
