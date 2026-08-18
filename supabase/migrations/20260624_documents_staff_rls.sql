-- ===========================================================================
-- RLS policies sur documents pour le staff du dashboard
-- Problème : la table documents n'a aucune policy UPDATE/SELECT pour le staff,
-- donc les actions Approuver/Rejeter échouent silencieusement côté dashboard.
-- Le trigger de notification ne se déclenche jamais non plus.
-- ===========================================================================

-- Helper : is_staff() pour éviter de répéter le EXISTS sur user_roles partout
CREATE OR REPLACE FUNCTION is_staff()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid()
      AND r.name IN ('admin', 'admissions', 'manager', 'support')
  );
$$;

-- Lecture : le staff peut lire tous les documents
DROP POLICY IF EXISTS "staff_read_documents" ON documents;
CREATE POLICY "staff_read_documents" ON documents
  FOR SELECT TO authenticated
  USING (is_staff());

-- Mise à jour : le staff peut changer le status (approve/reject)
DROP POLICY IF EXISTS "staff_update_documents" ON documents;
CREATE POLICY "staff_update_documents" ON documents
  FOR UPDATE TO authenticated
  USING (is_staff())
  WITH CHECK (is_staff());