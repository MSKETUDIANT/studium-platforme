-- RPC permettant à un étudiant de supprimer son propre compte
-- Supprime d'abord toutes les données liées, puis le compte auth

CREATE OR REPLACE FUNCTION delete_my_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  _uid uuid := auth.uid();
BEGIN
  IF _uid IS NULL THEN
    RAISE EXCEPTION 'Non authentifié';
  END IF;

  -- Données liées au profil
  DELETE FROM student_documents  WHERE student_id = _uid;
  DELETE FROM student_profiles   WHERE id         = _uid;

  -- Candidatures et pièces jointes
  DELETE FROM application_documents WHERE application_id IN (
    SELECT id FROM applications WHERE student_id = _uid
  );
  DELETE FROM applications WHERE student_id = _uid;

  -- Messages et notifications
  DELETE FROM messages      WHERE sender_id    = _uid;
  DELETE FROM notifications WHERE student_id   = _uid;

  -- Compte auth (doit être en dernier)
  DELETE FROM auth.users WHERE id = _uid;
END;
$$;

-- Seul le propriétaire peut appeler cette fonction
REVOKE ALL ON FUNCTION delete_my_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION delete_my_account() TO authenticated;
