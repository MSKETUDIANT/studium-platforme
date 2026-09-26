-- Bug reel : la suppression d'un compte (auth.users) echoue avec
-- "Database error deleting user" des que l'utilisateur a au moins une
-- ligne dans referrals, commissions, audit_logs ou student_notes.
--
-- Cause : ces 4 tables referencent auth.users(id) sans ON DELETE
-- specifie -> Postgres applique NO ACTION par defaut, qui bloque la
-- suppression tant que la ligne dependante existe. Contrairement aux
-- autres tables du schema (deja en CASCADE), un CASCADE serait ici une
-- mauvaise reponse : on ne veut pas effacer l'historique d'audit, les
-- notes internes ou les commissions au moment ou un compte est
-- supprime (traçabilite, obligations comptables). On garde donc la
-- ligne mais on detache la reference a l'utilisateur (SET NULL),
-- verifie compatible avec les colonnes concernees (toutes nullable).

ALTER TABLE referrals DROP CONSTRAINT IF EXISTS referrals_ambassador_user_id_fkey;
ALTER TABLE referrals ADD CONSTRAINT referrals_ambassador_user_id_fkey
  FOREIGN KEY (ambassador_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE referrals DROP CONSTRAINT IF EXISTS referrals_student_user_id_fkey;
ALTER TABLE referrals ADD CONSTRAINT referrals_student_user_id_fkey
  FOREIGN KEY (student_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE commissions DROP CONSTRAINT IF EXISTS commissions_ambassador_user_id_fkey;
ALTER TABLE commissions ADD CONSTRAINT commissions_ambassador_user_id_fkey
  FOREIGN KEY (ambassador_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE audit_logs DROP CONSTRAINT IF EXISTS audit_logs_actor_id_fkey;
ALTER TABLE audit_logs ADD CONSTRAINT audit_logs_actor_id_fkey
  FOREIGN KEY (actor_id) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE student_notes DROP CONSTRAINT IF EXISTS student_notes_author_id_fkey;
ALTER TABLE student_notes ADD CONSTRAINT student_notes_author_id_fkey
  FOREIGN KEY (author_id) REFERENCES auth.users(id) ON DELETE SET NULL;
