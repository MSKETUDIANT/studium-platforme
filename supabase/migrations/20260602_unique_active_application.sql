-- Empêche les candidatures actives en double pour un même étudiant/programme.
-- Les statuts 'archived' et 'rejected' sont exclus pour autoriser une re-candidature.
CREATE UNIQUE INDEX IF NOT EXISTS uq_applications_active
  ON applications (student_profile_id, program_id)
  WHERE status NOT IN ('archived', 'rejected');
