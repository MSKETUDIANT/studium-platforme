-- Nettoyage : tables du modele de donnees initial jamais utilisees par le
-- code (0 ligne depuis toujours, aucune reference dans le dashboard ni le
-- mobile), remplacees en pratique par d'autres tables :
--   educations          -> academic_backgrounds
--   favorites            -> program_favorites
--   application_fields   -> jamais implementee (champs dynamiques par programme)
--   application_packs    -> jamais implementee (pack PDF genere a la volee, non stocke)
-- Verifie avant suppression : aucune table ne reference celles-ci par FK,
-- aucune migration ulterieure ni aucun trigger/fonction n'en depend.

DROP TABLE IF EXISTS public.educations;
DROP TABLE IF EXISTS public.favorites;
DROP TABLE IF EXISTS public.application_fields;
DROP TABLE IF EXISTS public.application_packs;
