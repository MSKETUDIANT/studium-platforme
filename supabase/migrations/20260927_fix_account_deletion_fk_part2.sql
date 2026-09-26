-- Suite de 20260927_fix_account_deletion_fk.sql : le meme bug de
-- suppression de compte ("Database error deleting user") touche en
-- realite 9 autres tables, decouvertes en listant systematiquement
-- toutes les FK vers auth.users sans ON DELETE CASCADE ni SET NULL.
-- Meme logique : on garde l'historique (candidatures, conversations,
-- taches, documents, journaux) et on detache seulement la reference a
-- l'utilisateur supprime, plutot que d'effacer ces lignes en cascade.
-- Toutes les colonnes concernees sont nullable (verifie au prealable).

ALTER TABLE conversations DROP CONSTRAINT IF EXISTS conversations_assigned_to_fkey;
ALTER TABLE conversations ADD CONSTRAINT conversations_assigned_to_fkey
  FOREIGN KEY (assigned_to) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE documents DROP CONSTRAINT IF EXISTS documents_reviewed_by_fkey;
ALTER TABLE documents ADD CONSTRAINT documents_reviewed_by_fkey
  FOREIGN KEY (reviewed_by) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_sender_id_fkey;
ALTER TABLE messages ADD CONSTRAINT messages_sender_id_fkey
  FOREIGN KEY (sender_id) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE applications DROP CONSTRAINT IF EXISTS applications_assigned_to_fkey;
ALTER TABLE applications ADD CONSTRAINT applications_assigned_to_fkey
  FOREIGN KEY (assigned_to) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE application_status_history DROP CONSTRAINT IF EXISTS application_status_history_changed_by_fkey;
ALTER TABLE application_status_history ADD CONSTRAINT application_status_history_changed_by_fkey
  FOREIGN KEY (changed_by) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE email_logs DROP CONSTRAINT IF EXISTS email_logs_sent_by_fkey;
ALTER TABLE email_logs ADD CONSTRAINT email_logs_sent_by_fkey
  FOREIGN KEY (sent_by) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_assigned_to_fkey;
ALTER TABLE tasks ADD CONSTRAINT tasks_assigned_to_fkey
  FOREIGN KEY (assigned_to) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE tasks DROP CONSTRAINT IF EXISTS tasks_created_by_fkey;
ALTER TABLE tasks ADD CONSTRAINT tasks_created_by_fkey
  FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE application_comments DROP CONSTRAINT IF EXISTS application_comments_author_id_fkey;
ALTER TABLE application_comments ADD CONSTRAINT application_comments_author_id_fkey
  FOREIGN KEY (author_id) REFERENCES auth.users(id) ON DELETE SET NULL;
