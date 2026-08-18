-- ===========================================================================
-- Fix schéma notifications + création student_notes
-- Problème : la migration 20260603_notifications.sql n'a jamais été appliquée
-- sur la base de production. La table notifications existe mais manque la
-- colonne "title". La table student_notes n'existe pas du tout.
-- ===========================================================================

-- 1. Ajouter les colonnes manquantes title et body
--    La table existe mais a été créée sans ces colonnes.
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS title TEXT NOT NULL DEFAULT 'Notification';
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS body  TEXT;
-- Enlever le default temporaire sur title
ALTER TABLE notifications ALTER COLUMN title DROP DEFAULT;

-- 2. Créer student_notes si elle n'existe pas
CREATE TABLE IF NOT EXISTS student_notes (
  id           UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  student_id   UUID        NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
  author_id    UUID        REFERENCES auth.users(id),
  author_email TEXT,
  content      TEXT        NOT NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_student_notes_student ON student_notes(student_id);

ALTER TABLE student_notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "team_manage_notes" ON student_notes;
CREATE POLICY "team_manage_notes" ON student_notes
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.id
      WHERE ur.user_id = auth.uid()
        AND r.name IN ('admin', 'admissions', 'manager', 'support')
    )
  );