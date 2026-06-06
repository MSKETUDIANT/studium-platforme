-- Colonnes manquantes dans la table programs
-- Utilisées par le dashboard (ProgramsPage) et l'app mobile

ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS duration      TEXT,
  ADD COLUMN IF NOT EXISTS description   TEXT,
  ADD COLUMN IF NOT EXISTS domain        TEXT,
  ADD COLUMN IF NOT EXISTS requirements  TEXT[],
  ADD COLUMN IF NOT EXISTS contact_email TEXT;
