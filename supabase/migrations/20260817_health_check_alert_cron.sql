-- Planifie l'appel de health-check-alert toutes les 15 min (meme pattern
-- que send-task-reminders-hourly / 20260712_relance_cron_fix.sql).
-- health-check-alert doit etre deployee avec --no-verify-jwt (fonction
-- interne, declenchee uniquement par ce cron).

SELECT cron.unschedule('health-check-alert-15min')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'health-check-alert-15min');

SELECT cron.schedule(
  'health-check-alert-15min',
  '*/15 * * * *',
  $$
    SELECT net.http_post(
      url     := 'https://mpqkujgmisodqtffvmwg.supabase.co/functions/v1/health-check-alert',
      headers := jsonb_build_object('Content-Type', 'application/json'),
      body    := '{}'::jsonb
    )
  $$
);
