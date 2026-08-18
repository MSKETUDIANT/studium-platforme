-- US-7.6 : nettoyage des relances J+7/J+14 mortes/dupliquées + activation
-- de l'envoi automatique des rappels de tâches (send-task-reminders).
--
-- La création des tâches reminder_j7/reminder_j14 se fait déjà côté
-- dashboard (tasks_service.ts::createReminderTasks) au moment où une
-- candidature passe au statut "sent" — ces deux fonctions SQL faisaient
-- doublon et generate_relance_tasks() testait des statuts inexistants
-- (pending/en_attente/incomplete au lieu de l'enum réel), donc ne
-- trouvait jamais rien.

DROP FUNCTION IF EXISTS generate_relance_tasks();
DROP FUNCTION IF EXISTS create_reminder_tasks();

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

SELECT cron.unschedule('send-task-reminders-hourly')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'send-task-reminders-hourly');

SELECT cron.schedule(
  'send-task-reminders-hourly',
  '0 * * * *',
  $$
    SELECT net.http_post(
      url     := 'https://mpqkujgmisodqtffvmwg.supabase.co/functions/v1/send-task-reminders',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || current_setting('app.service_role_key', true),
        'Content-Type',  'application/json'
      ),
      body    := '{}'::jsonb
    )
  $$
);
