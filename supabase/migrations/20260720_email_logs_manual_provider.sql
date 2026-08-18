-- Autorise provider='manual' dans email_logs, pour tracer une candidature
-- marquee "Envoyee" via le selecteur de statut manuel (depot sur portail
-- externe, cf. CDC section 1) plutot que via l'envoi email automatique.
-- Permet de distinguer visuellement les deux cas dans l'historique
-- d'envoi au lieu de les confondre silencieusement.

ALTER TABLE public.email_logs
  DROP CONSTRAINT email_logs_provider_check;

ALTER TABLE public.email_logs
  ADD CONSTRAINT email_logs_provider_check
    CHECK (provider = ANY (ARRAY['resend'::text, 'manual'::text, 'sendgrid'::text, 'mailgun'::text, 'ses'::text]));
