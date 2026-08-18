-- Le champ CC de "Envoyer à l'université" restait toujours vide à taper
-- manuellement : program_contacts.cc_emails existe mais n'a jamais eu
-- d'interface pour l'alimenter. Ajout d'un champ simple sur programs,
-- au meme niveau que contact_email (deja fonctionnel et rempli via le
-- formulaire de gestion des programmes) plutot que de construire une UI
-- complete pour program_contacts.

ALTER TABLE public.programs
  ADD COLUMN IF NOT EXISTS cc_emails text;
