import type { UserRole } from './useRole';

export type Action = 'programs:write' | 'documents:review';

// Reflète exactement les policies RLS correspondantes ("team can manage
// programs", "team can update document status") : le rôle 'support' n'y
// figure pas côté base, donc l'UI ne doit pas lui proposer ces actions non
// plus — évite un clic qui aboutit à une erreur RLS silencieuse.
const PERMISSIONS: Record<Action, UserRole[]> = {
  'programs:write':   ['admin', 'admissions', 'manager'],
  'documents:review': ['admin', 'admissions', 'manager'],
};

export function can(role: UserRole | null, action: Action): boolean {
  if (!role) return false;
  return PERMISSIONS[action].includes(role);
}
