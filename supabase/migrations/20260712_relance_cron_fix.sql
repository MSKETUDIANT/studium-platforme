-- US-7.6 (suite) : ALTER DATABASE ... SET n'est pas autorisé sur Supabase
-- hébergé pour le rôle postgres du SQL Editor (permission denied).
-- send-task-reminders est désormais déployée avec --no-verify-jwt (fonction
-- interne, déclenchée uniquement par ce cron ; elle utilise sa propre
-- SUPABASE_SERVICE_ROLE_KEY en variable d'environnement pour ses écritures,
-- pas l'en-tête Authorization reçu). Le cron n'a donc plus besoin de
-- transporter de clé secrète.

SELECT cron.unschedule('send-task-reminders-hourly')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'send-task-reminders-hourly');

SELECT cron.schedule(
  'send-task-reminders-hourly',
  '0 * * * *',
  $$
    SELECT net.http_post(
      url     := 'https://mpqkujgmisodqtffvmwg.supabase.co/functions/v1/send-task-reminders',
      headers := jsonb_build_object('Content-Type', 'application/json'),
      body    := '{}'::jsonb
    )
  $$
);
