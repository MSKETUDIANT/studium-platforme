-- La contrainte n'autorisait que sendgrid/mailgun/ses, mais la fonction
-- send-application-email insère provider='resend' (le prestataire
-- réellement utilisé, cf. RESEND_API_KEY). Chaque insertion échouait donc
-- silencieusement (l'appel .insert() de supabase-js ne lève pas d'erreur
-- JS, le code ne vérifiait pas son résultat) : email_logs restait vide
-- même quand l'envoi réussissait réellement côté Resend.

ALTER TABLE public.email_logs
  DROP CONSTRAINT email_logs_provider_check;

ALTER TABLE public.email_logs
  ADD CONSTRAINT email_logs_provider_check
    CHECK (provider = ANY (ARRAY['resend'::text, 'sendgrid'::text, 'mailgun'::text, 'ses'::text]));
