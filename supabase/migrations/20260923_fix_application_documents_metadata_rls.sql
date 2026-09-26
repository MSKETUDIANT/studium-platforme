-- Faille critique detectee par Supabase Security Advisor : la policy
-- staff_all_application_documents s'appuyait sur
-- auth.jwt()->'user_metadata'->>'role', un champ modifiable par le client
-- lui-meme via supabase.auth.updateUser({ data: { role: 'admin' } }).
-- N'importe quel etudiant authentifie pouvait ainsi s'auto-attribuer le
-- role admin/staff et obtenir un acces complet (lecture, ecriture,
-- suppression) a application_documents, y compris pour des candidatures
-- qui ne sont pas les siennes.
--
-- Remplacee par is_staff(), basee sur les tables user_roles/roles
-- (non modifiables par le client), deja utilisee par toutes les autres
-- policies "staff" du projet.

-- is_staff() peut ne pas exister selon l'etat reel de la base (deja
-- constate a plusieurs reprises sur ce projet) : redefinie ici de facon
-- idempotente.
CREATE OR REPLACE FUNCTION is_staff()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid()
      AND r.name IN ('admin', 'admissions', 'manager', 'support')
  );
$$;

DROP POLICY IF EXISTS "staff_all_application_documents" ON application_documents;
CREATE POLICY "staff_all_application_documents" ON application_documents
  FOR ALL
  USING (is_staff())
  WITH CHECK (is_staff());
