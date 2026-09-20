-- Le badge "Deja ambassadeur" (fiche etudiant, dashboard) revenait a l'etat
-- initial apres rafraichissement de page : seule la policy "users_read_own_role"
-- existe sur user_roles (auth.uid() = user_id), donc un membre du staff qui
-- relit le role d'UN AUTRE utilisateur recoit 0 ligne via RLS (pas une
-- erreur) -- la promotion avait pourtant bien ete enregistree en base.

CREATE OR REPLACE FUNCTION is_staff()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid()
      AND r.name IN ('admin', 'admissions', 'manager', 'support')
  );
$$;

DROP POLICY IF EXISTS "staff_read_all_user_roles" ON user_roles;
CREATE POLICY "staff_read_all_user_roles" ON user_roles
  FOR SELECT USING (is_staff());
