-- Bug reel constate en test : create-team-member inserait un role sans
-- verifier qu'un role existe deja pour cet utilisateur (ex. un etudiant
-- invite comme membre d'equipe), et user_roles n'a aucune contrainte
-- d'unicite sur user_id -> un compte peut se retrouver avec 2 roles en
-- meme temps, ce qui casse useRole() (.maybeSingle() renvoie une erreur
-- des qu'il y a plus d'une ligne).
--
-- Nettoyage prealable a faire manuellement AVANT cette migration pour
-- chaque doublon existant (ex. voir la conversation) :
--   DELETE FROM public.user_roles
--   WHERE user_id = (SELECT id FROM auth.users WHERE email = '...')
--     AND role_id = (SELECT id FROM public.roles WHERE name = '...');

ALTER TABLE public.user_roles
  ADD CONSTRAINT user_roles_user_id_key UNIQUE (user_id);
