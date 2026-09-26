-- Bug reel : assign_default_role() attribuait le role "student" a TOUT
-- nouveau compte (y compris ceux crees par create-team-member via
-- inviteUserByEmail), en se basant sur un pg_sleep(0.1) cense "laisser
-- l'Edge Function agir en premier" -- raisonnement errone, puisque
-- l'Edge Function ne s'execute qu'apres le retour de inviteUserByEmail(),
-- donc apres que ce trigger (declenche dans la meme transaction que
-- l'insertion du compte) ait deja termine. Consequence : le trigger
-- inserait systematiquement "student" avant que create-team-member
-- ne tente d'inserer le role demande (ex. admin), qui echouait alors
-- sur la contrainte unique user_roles.user_id, et la verification de
-- "compte deja existant" de create-team-member se declenchait a tort
-- pour des comptes fraichement crees par invitation.
--
-- Correction : auth.users.invited_at n'est renseigne que pour les
-- comptes crees via un flux d'invitation admin (inviteUserByEmail) ;
-- le trigger ne doit s'appliquer qu'aux inscriptions directes (mobile),
-- qui n'ont pas invited_at renseigne. Le pg_sleep, inutile avec cette
-- verification fiable, est supprime.

CREATE OR REPLACE FUNCTION assign_default_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Les comptes crees par invitation admin (create-team-member) gerent
  -- eux-memes l'attribution du role ; ce trigger ne concerne que les
  -- inscriptions directes (mobile), reconnaissables a invited_at NULL.
  IF NEW.invited_at IS NOT NULL THEN
    RETURN NEW;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.user_roles WHERE user_id = NEW.id
  ) THEN
    INSERT INTO public.user_roles (user_id, role_id, status)
    SELECT NEW.id, id, 'active'
    FROM public.roles
    WHERE name = 'student';
  END IF;

  RETURN NEW;
END;
$$;
