-- Table de liaison candidature <-> documents sélectionnés
-- Permet de savoir exactement quels documents ont été soumis pour chaque candidature

CREATE TABLE IF NOT EXISTS application_documents (
  application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  document_id    UUID NOT NULL REFERENCES documents(id)    ON DELETE CASCADE,
  PRIMARY KEY (application_id, document_id)
);

ALTER TABLE application_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "student_read_own_app_docs"   ON application_documents;
DROP POLICY IF EXISTS "student_insert_own_app_docs" ON application_documents;
DROP POLICY IF EXISTS "student_delete_own_app_docs" ON application_documents;
DROP POLICY IF EXISTS "staff_all_app_docs"           ON application_documents;

-- L'étudiant lit ses propres liaisons
CREATE POLICY "student_read_own_app_docs" ON application_documents
  FOR SELECT TO authenticated
  USING (
    application_id IN (
      SELECT id FROM applications WHERE student_profile_id = auth.uid()
    )
  );

-- L'étudiant peut lier ses documents lors de la soumission
CREATE POLICY "student_insert_own_app_docs" ON application_documents
  FOR INSERT TO authenticated
  WITH CHECK (
    application_id IN (
      SELECT id FROM applications WHERE student_profile_id = auth.uid()
    )
  );

-- L'étudiant peut modifier ses liaisons (pour resoumission)
CREATE POLICY "student_delete_own_app_docs" ON application_documents
  FOR DELETE TO authenticated
  USING (
    application_id IN (
      SELECT id FROM applications WHERE student_profile_id = auth.uid()
    )
  );

-- Le staff voit tout
CREATE POLICY "staff_all_app_docs" ON application_documents
  FOR ALL TO authenticated
  USING (is_staff());