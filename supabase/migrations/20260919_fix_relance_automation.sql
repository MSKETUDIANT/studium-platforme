-- Corrige les relances J+7/J+14 (CDC B7), qui n'ont jamais fonctionne :
-- - generate_relance_tasks() (20260610) testait des statuts inexistants
--   ('pending','en_attente','incomplete' au lieu de l'enum reel applications_status_check)
--   et comparait sur created_at (soumission a Studium) au lieu de la date
--   d'envoi reelle a l'universite -> ne trouvait jamais rien, et a ete
--   supprimee par 20260712_relance_cleanup.sql.
-- - Le remplacement annonce dans ce meme fichier ("tasks_service.ts::createReminderTasks")
--   n'existe nulle part dans le dashboard : aucune tache reminder_j7/reminder_j14
--   n'a jamais ete creee automatiquement, seul le type existe dans l'UI.
--
-- Nouvelle logique : une candidature "sans reponse" = toujours en statut
-- sent/pending_decision N jours apres son passage reel a "sent" (calcule
-- depuis application_status_history, pas created_at). Dedoublonnage par
-- NOT EXISTS sur task_type, donc un cron quotidien qui rate un jour rattrape
-- sans creer de doublon.

CREATE OR REPLACE FUNCTION generate_relance_tasks()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  app RECORD;
BEGIN
  -- J+7 : envoyees a l'universite depuis >= 7 jours, toujours sans decision
  FOR app IN
    SELECT
      a.id AS application_id,
      sp.first_name,
      sp.last_name,
      p.program_name,
      sent_at.sent_at
    FROM applications a
    LEFT JOIN student_profiles sp ON sp.id = a.student_profile_id
    LEFT JOIN programs         p  ON p.id  = a.program_id
    JOIN LATERAL (
      SELECT MAX(h.created_at) AS sent_at
      FROM application_status_history h
      WHERE h.application_id = a.id AND h.to_status = 'sent'
    ) sent_at ON sent_at.sent_at IS NOT NULL
    WHERE
      a.status IN ('sent', 'pending_decision')
      AND sent_at.sent_at <= now() - INTERVAL '7 days'
      AND NOT EXISTS (
        SELECT 1 FROM tasks t
        WHERE t.application_id = a.id AND t.task_type = 'reminder_j7'
      )
  LOOP
    INSERT INTO tasks (
      application_id, title, task_type, assignee_label, priority,
      due_date, reminder_hours
    ) VALUES (
      app.application_id,
      'Relance J+7 — ' || COALESCE(app.first_name || ' ' || app.last_name, 'Candidat') ||
        CASE WHEN app.program_name IS NOT NULL THEN ' (' || app.program_name || ')' ELSE '' END,
      'reminder_j7',
      'Admissions',
      'normal',
      now() + INTERVAL '1 hour',
      1
    );
  END LOOP;

  -- J+14 : envoyees a l'universite depuis >= 14 jours, toujours sans decision
  FOR app IN
    SELECT
      a.id AS application_id,
      sp.first_name,
      sp.last_name,
      p.program_name,
      sent_at.sent_at
    FROM applications a
    LEFT JOIN student_profiles sp ON sp.id = a.student_profile_id
    LEFT JOIN programs         p  ON p.id  = a.program_id
    JOIN LATERAL (
      SELECT MAX(h.created_at) AS sent_at
      FROM application_status_history h
      WHERE h.application_id = a.id AND h.to_status = 'sent'
    ) sent_at ON sent_at.sent_at IS NOT NULL
    WHERE
      a.status IN ('sent', 'pending_decision')
      AND sent_at.sent_at <= now() - INTERVAL '14 days'
      AND NOT EXISTS (
        SELECT 1 FROM tasks t
        WHERE t.application_id = a.id AND t.task_type = 'reminder_j14'
      )
  LOOP
    INSERT INTO tasks (
      application_id, title, task_type, assignee_label, priority,
      due_date, reminder_hours
    ) VALUES (
      app.application_id,
      'Relance J+14 — ' || COALESCE(app.first_name || ' ' || app.last_name, 'Candidat') ||
        CASE WHEN app.program_name IS NOT NULL THEN ' (URGENT — ' || app.program_name || ')' ELSE ' (URGENT)' END,
      'reminder_j14',
      'Admissions',
      'urgent',
      now() + INTERVAL '1 hour',
      1
    );
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION generate_relance_tasks() TO service_role;

CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.unschedule('generate-relances-daily')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'generate-relances-daily');

-- Planification reelle (le fichier d'origine la laissait en commentaire,
-- jamais activee) : tous les jours a 8h00 UTC.
SELECT cron.schedule(
  'generate-relances-daily',
  '0 8 * * *',
  'SELECT generate_relance_tasks()'
);
