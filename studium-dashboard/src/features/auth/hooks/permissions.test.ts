import { describe, it, expect } from 'vitest';
import { can } from './permissions';
import type { UserRole } from './useRole';

describe('can()', () => {
  it('refuse tout si le rôle est null', () => {
    expect(can(null, 'programs:write')).toBe(false);
    expect(can(null, 'documents:review')).toBe(false);
  });

  it('autorise admin, admissions et manager pour programs:write', () => {
    (['admin', 'admissions', 'manager'] as UserRole[]).forEach(role => {
      expect(can(role, 'programs:write')).toBe(true);
    });
  });

  it('autorise admin, admissions et manager pour documents:review', () => {
    (['admin', 'admissions', 'manager'] as UserRole[]).forEach(role => {
      expect(can(role, 'documents:review')).toBe(true);
    });
  });

  it('refuse support pour les deux actions (aucune policy RLS correspondante)', () => {
    expect(can('support', 'programs:write')).toBe(false);
    expect(can('support', 'documents:review')).toBe(false);
  });

  it('refuse les rôles non-staff (student, ambassador)', () => {
    (['student', 'ambassador'] as UserRole[]).forEach(role => {
      expect(can(role, 'programs:write')).toBe(false);
      expect(can(role, 'documents:review')).toBe(false);
    });
  });
});
