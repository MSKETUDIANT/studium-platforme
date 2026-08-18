-- Colonne pour éviter les doublons de rappels email
ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS reminder_sent_at TIMESTAMPTZ;

-- Planification Edge Function (à exécuter manuellement après activation pg_cron)
-- SELECT cron.schedule(
--   'send-task-reminders-hourly',
--   '0 * * * *',
--   $$
--     SELECT net.http_post(
--       url     := current_setting('app.supabase_url') || '/functions/v1/send-task-reminders',
--       headers := jsonb_build_object(
--         'Authorization', 'Bearer ' || current_setting('app.service_role_key'),
--         'Content-Type',  'application/json'
--       ),
--       body    := '{}'::jsonb
--     )
--   $$
-- );
