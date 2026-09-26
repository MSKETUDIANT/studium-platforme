-- Meme classe de faille que 20260923_fix_application_documents_metadata_rls.sql,
-- retrouvee sur 3 autres tables jamais corrigees a l'epoque : les policies
-- s'appuient sur raw_user_meta_data->>'role' (auth.users), un champ que le
-- client peut modifier lui-meme via supabase.auth.updateUser({ data: { role:
-- 'admin' } }). N'importe quel etudiant authentifie pouvait ainsi s'auto-
-- attribuer un role staff et obtenir un acces complet (lecture/ecriture) a :
--   - tasks (taches internes et relances)
--   - email_logs (historique d'envoi des candidatures aux universites)
--   - student_notes (notes internes sur les etudiants)
--
-- De plus, service_insert_tasks et team_insert_email_logs autorisaient
-- l'insertion (WITH CHECK (true)) a tout utilisateur authentifie, sans aucune
-- restriction : le service_role (utilise par les Edge Functions) contourne
-- RLS de toute facon, donc ces policies ne servaient qu'a laisser n'importe
-- quel etudiant injecter de fausses taches ou de faux journaux d'envoi.
--
-- is_staff() peut ne pas exister selon l'etat reel de la base : redefinie
-- ici de facon idempotente (deja fait ailleurs sur ce projet).
CREATE OR REPLACE FUNCTION is_staff()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid()
      AND r.name IN ('admin', 'admissions', 'manager', 'support')
  );
$$;

-- tasks
DROP POLICY IF EXISTS "team_tasks_all" ON tasks;
CREATE POLICY "team_tasks_all" ON tasks
  FOR ALL TO authenticated
  USING (is_staff())
  WITH CHECK (is_staff());

DROP POLICY IF EXISTS "service_insert_tasks" ON tasks;
CREATE POLICY "service_insert_tasks" ON tasks
  FOR INSERT
  WITH CHECK (is_staff());

-- email_logs
DROP POLICY IF EXISTS "team_read_email_logs" ON email_logs;
CREATE POLICY "team_read_email_logs" ON email_logs
  FOR SELECT
  USING (is_staff());

DROP POLICY IF EXISTS "team_insert_email_logs" ON email_logs;
CREATE POLICY "team_insert_email_logs" ON email_logs
  FOR INSERT
  WITH CHECK (is_staff());

-- student_notes
DROP POLICY IF EXISTS "team_manage_notes" ON student_notes;
CREATE POLICY "team_manage_notes" ON student_notes
  FOR ALL TO authenticated
  USING (is_staff())
  WITH CHECK (is_staff());
