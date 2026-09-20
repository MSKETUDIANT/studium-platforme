-- delete_my_account() referencait des tables/colonnes inexistantes
-- (student_documents, applications.student_id, notifications.student_id),
-- ce qui faisait echouer la fonction des sa premiere instruction : aucune
-- suppression n'avait jamais lieu (droit RGPD a l'effacement non honore).
--
-- Le schema applique deja ON DELETE CASCADE depuis student_profiles et
-- auth.users vers toutes les tables dependantes (applications, documents,
-- conversations/messages, favoris, notifications, tokens...) : supprimer
-- auth.users suffit a tout nettoyer par cascade.

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

  DELETE FROM auth.users WHERE id = _uid;
END;
$$;
