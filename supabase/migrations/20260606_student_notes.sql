-- Notes internes sur les étudiants (visibles uniquement par l'équipe)

CREATE TABLE IF NOT EXISTS student_notes (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  student_id  UUID        NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
  author_id   UUID        REFERENCES auth.users(id),
  author_email TEXT,
  content     TEXT        NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_student_notes_student ON student_notes(student_id);

ALTER TABLE student_notes ENABLE ROW LEVEL SECURITY;

-- Seule l'équipe interne peut lire/écrire
CREATE POLICY "team_manage_notes" ON student_notes
  FOR ALL TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM auth.users
      WHERE raw_user_meta_data->>'role' IN ('admin','admissions','manager','support')
    )
  );
