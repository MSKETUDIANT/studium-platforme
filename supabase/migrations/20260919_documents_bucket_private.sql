-- Le bucket "documents" (passeports, releves de notes, CV...) est public
-- depuis sa creation manuelle via le Dashboard : n'importe qui connaissant
-- l'URL peut lire un document sensible, seule la table "documents" est
-- protegee par RLS (l'objet de stockage lui-meme ne l'est pas). Le CDC §7
-- exige un chiffrement/protection du stockage sensible.
--
-- Passage en bucket prive + policies RLS sur storage.objects (etudiant
-- proprietaire via le 1er segment du chemin = son id, staff via is_staff()).
-- Le code (mobile/dashboard/Edge Functions) est adapte en parallele pour
-- generer une URL signee a la demande au lieu d'utiliser l'URL publique
-- stockee en base (qui garde le meme format, juste pour en extraire le
-- chemin de facon fiable).

UPDATE storage.buckets SET public = false WHERE id = 'documents';

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

DROP POLICY IF EXISTS "student_own_documents_select" ON storage.objects;
CREATE POLICY "student_own_documents_select" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'documents' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "student_own_documents_insert" ON storage.objects;
CREATE POLICY "student_own_documents_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'documents' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "student_own_documents_update" ON storage.objects;
CREATE POLICY "student_own_documents_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'documents' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "student_own_documents_delete" ON storage.objects;
CREATE POLICY "student_own_documents_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'documents' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "staff_read_documents_storage" ON storage.objects;
CREATE POLICY "staff_read_documents_storage" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'documents' AND is_staff());
