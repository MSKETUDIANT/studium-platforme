-- Politique de retention documents (CDC section 7 : "24 mois puis purge").
-- Planifie l'appel quotidien a la fonction purge-expired-documents, meme
-- pattern que send-task-reminders-hourly (net.http_post, fonction deployee
-- avec --no-verify-jwt et sa propre SUPABASE_SERVICE_ROLE_KEY).

SELECT cron.unschedule('purge-expired-documents-daily')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'purge-expired-documents-daily');

SELECT cron.schedule(
  'purge-expired-documents-daily',
  '0 3 * * *',
  $$
    SELECT net.http_post(
      url     := 'https://mpqkujgmisodqtffvmwg.supabase.co/functions/v1/purge-expired-documents',
      headers := jsonb_build_object('Content-Type', 'application/json'),
      body    := '{}'::jsonb
    )
  $$
);
