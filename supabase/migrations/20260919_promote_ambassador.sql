-- A8/B10 CDC : le role "ambassador" existe (roles.name), mais rien ne permet
-- de l'attribuer autrement qu'a la main en SQL Editor -- aucune UI, aucune
-- RPC. Ajoute une promotion validee par le staff (admin/manager, meme
-- perimetre RBAC que /commissions, B10 CDC), appelee depuis la fiche
-- etudiant du dashboard.

CREATE OR REPLACE FUNCTION promote_to_ambassador(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  ambassador_role_id uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid() AND r.name IN ('admin', 'manager')
  ) THEN
    RAISE EXCEPTION 'Seul un administrateur ou un manager peut promouvoir un ambassadeur.';
  END IF;

  SELECT id INTO ambassador_role_id FROM roles WHERE name = 'ambassador';

  UPDATE user_roles
  SET role_id = ambassador_role_id
  WHERE user_id = target_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Utilisateur introuvable dans user_roles.';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION promote_to_ambassador(uuid) TO authenticated;
