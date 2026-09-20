-- Le staff (dashboard) n'a aucune policy de lecture sur academic_backgrounds
-- et experiences (seule l'etudiant proprietaire peut lire les siennes) :
-- le dashboard recupere donc 0 ligne silencieusement pour ces deux tables
-- (ex. export PDF interne "ApplicationPDF.tsx", section Formations/Experiences
-- toujours vide). Meme pattern que 20260624_documents_staff_rls.sql.

-- is_staff() peut ne pas exister selon l'etat reel de la base (deja constate
-- a plusieurs reprises sur ce projet) : redefinie ici de façon idempotente.
CREATE OR REPLACE FUNCTION is_staff()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid()
      AND r.name IN ('admin', 'admissions', 'manager', 'support')
  );
$$;

DROP POLICY IF EXISTS "staff_read_academic_backgrounds" ON academic_backgrounds;
CREATE POLICY "staff_read_academic_backgrounds" ON academic_backgrounds
  FOR SELECT TO authenticated
  USING (is_staff());

DROP POLICY IF EXISTS "staff_read_experiences" ON experiences;
CREATE POLICY "staff_read_experiences" ON experiences
  FOR SELECT TO authenticated
  USING (is_staff());
