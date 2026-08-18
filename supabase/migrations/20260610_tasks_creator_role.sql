-- Colonne creator_role : rôle de l'utilisateur qui a créé la tâche
-- Règle PFE : créateur = propriétaire = droit modifier/supprimer
-- Seul l'Admin peut modifier/supprimer les tâches des autres
ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS creator_role TEXT
    CHECK (creator_role IN ('admin', 'manager', 'admissions', 'support'));
