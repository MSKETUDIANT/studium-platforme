-- Champs d'éligibilité sur les programmes, pour des recommandations
-- réellement prédictives (comparables à academic_backgrounds.average,
-- sur 20, échelle déjà utilisée par le profil étudiant).

ALTER TABLE public.programs
  ADD COLUMN IF NOT EXISTS min_average numeric,
  ADD COLUMN IF NOT EXISTS required_language_level text;

ALTER TABLE public.programs
  ADD CONSTRAINT programs_min_average_check
    CHECK (min_average IS NULL OR (min_average >= 0 AND min_average <= 20));

ALTER TABLE public.programs
  ADD CONSTRAINT programs_required_language_level_check
    CHECK (required_language_level IS NULL OR required_language_level IN ('A1','A2','B1','B2','C1','C2'));
