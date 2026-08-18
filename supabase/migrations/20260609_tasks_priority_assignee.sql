-- Colonnes manquantes pour le formulaire de creation de taches (CDC)
-- priority, assignee_label, reminder_hours

ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS priority       TEXT    DEFAULT 'normal'
    CHECK (priority IN ('normal', 'urgent', 'faible')),
  ADD COLUMN IF NOT EXISTS assignee_label TEXT,
  ADD COLUMN IF NOT EXISTS reminder_hours INT;
