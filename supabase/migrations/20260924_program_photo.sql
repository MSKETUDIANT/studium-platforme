-- Ajoute une photo/illustration optionnelle par programme (upload cote
-- dashboard), affichee a la place du placeholder degrade cote mobile quand
-- elle est renseignee. Bucket public, meme logique que "documents" avant sa
-- privatisation : simple, pas de donnee sensible (juste une photo d'illustration
-- d'universite/programme).

ALTER TABLE public.programs
  ADD COLUMN IF NOT EXISTS photo_url text;

INSERT INTO storage.buckets (id, name, public)
VALUES ('program-photos', 'program-photos', true)
ON CONFLICT (id) DO NOTHING;

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

DROP POLICY IF EXISTS "Public read program photos" ON storage.objects;
CREATE POLICY "Public read program photos" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'program-photos');

DROP POLICY IF EXISTS "Staff upload program photos" ON storage.objects;
CREATE POLICY "Staff upload program photos" ON storage.objects
  FOR INSERT
  WITH CHECK (bucket_id = 'program-photos' AND is_staff());

DROP POLICY IF EXISTS "Staff update program photos" ON storage.objects;
CREATE POLICY "Staff update program photos" ON storage.objects
  FOR UPDATE
  USING (bucket_id = 'program-photos' AND is_staff());

DROP POLICY IF EXISTS "Staff delete program photos" ON storage.objects;
CREATE POLICY "Staff delete program photos" ON storage.objects
  FOR DELETE
  USING (bucket_id = 'program-photos' AND is_staff());
