-- Lettre de motivation propre à chaque candidature (au lieu d'une seule
-- lettre générique sur le profil, réutilisée telle quelle pour tous les
-- programmes). Le champ student_profiles.motivation_letter reste en place
-- comme modèle de base, pré-rempli côté mobile à la création d'une
-- candidature puis adapté par l'étudiant pour le programme visé.

ALTER TABLE public.applications
  ADD COLUMN IF NOT EXISTS motivation_letter text;
