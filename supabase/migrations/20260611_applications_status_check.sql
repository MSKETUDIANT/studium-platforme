-- Élargir le CHECK constraint sur applications.status
-- pour inclure 'needsfix' et 'pending_decision' manquants

ALTER TABLE applications DROP CONSTRAINT IF EXISTS applications_status_check;

ALTER TABLE applications
  ADD CONSTRAINT applications_status_check
  CHECK (status IN (
    'draft',
    'submitted',
    'needsfix',
    'verified',
    'sent',
    'accepted',
    'rejected',
    'pending_decision',
    'archived'
  ));
