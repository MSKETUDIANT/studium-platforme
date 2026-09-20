-- Gestion d'equipe (CDC B1) : corrige trois problemes lies decouverts en
-- creusant "changer le role d'un membre existant" :
--
-- 1. La table "team_members" n'existe nulle part, alors que
--    supabase/functions/send-task-reminders/index.ts l'interroge pour
--    trouver les emails des destinataires des rappels de taches (relances
--    J+7/J+14 incluses) -> la requete echoue silencieusement, 0 destinataire
--    trouve, aucun email de rappel n'est jamais parti.
-- 2. La fonction "create-team-member" appelee par TeamPage.tsx pour inviter
--    un membre n'existe nulle part (ni fonction Edge, ni RPC) -> le bouton
--    "Inviter un membre" echoue toujours.
-- 3. update_member_status() (desactiver/reactiver un membre) n'a aucune
--    verification d'admin cote serveur : n'importe quel compte authentifie
--    peut l'appeler directement (GRANT ALL a "authenticated" sans check
--    dans le corps de la fonction) et desactiver n'importe qui.

CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid() AND r.name = 'admin'
  );
$$;

CREATE TABLE IF NOT EXISTS public.team_members (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email      text NOT NULL,
  full_name  text,
  is_active  boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id)
);

ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
-- Aucune policy pour authenticated/anon : uniquement accessible via
-- service_role (send-task-reminders, create-team-member) ou les RPC
-- SECURITY DEFINER ci-dessous.

-- Sauvegarde les membres d'equipe deja existants (crees avant que cette
-- table existe) pour que send-task-reminders les trouve immediatement,
-- sans attendre qu'ils soient reinvites.
INSERT INTO public.team_members (user_id, email, is_active)
SELECT u.id, u.email, (ur.status = 'active')
FROM auth.users u
JOIN public.user_roles ur ON ur.user_id = u.id
JOIN public.roles r ON r.id = ur.role_id
WHERE r.name IN ('admin', 'admissions', 'support', 'manager')
ON CONFLICT (user_id) DO NOTHING;

-- Changer le role d'un membre deja invite (le point manquant releve par
-- l'utilisateur). Admin uniquement, verifie cote serveur.
CREATE OR REPLACE FUNCTION update_member_role(target_user_id uuid, new_role text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  target_role_id uuid;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Seul un administrateur peut modifier le role d''un membre.';
  END IF;

  SELECT id INTO target_role_id FROM public.roles WHERE name = new_role;
  IF target_role_id IS NULL THEN
    RAISE EXCEPTION 'Role inconnu : %', new_role;
  END IF;

  UPDATE public.user_roles
  SET role_id = target_role_id
  WHERE user_id = target_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION update_member_role(uuid, text) TO authenticated;

-- Corrige update_member_status() : verification admin cote serveur (absente
-- jusqu'ici), et synchronise team_members.is_active pour que
-- send-task-reminders respecte reellement la desactivation d'un membre.
CREATE OR REPLACE FUNCTION update_member_status(target_user_id uuid, new_status text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Seul un administrateur peut modifier le statut d''un membre.';
  END IF;

  UPDATE public.user_roles
  SET status = new_status
  WHERE user_id = target_user_id;

  UPDATE public.team_members
  SET is_active = (new_status = 'active')
  WHERE user_id = target_user_id;
END;
$$;
