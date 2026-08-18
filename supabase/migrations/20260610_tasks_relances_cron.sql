-- ============================================================
-- Relances automatiques J+7 / J+14
-- Génère des tâches de relance pour les candidatures en attente
-- Planifiées via pg_cron tous les jours à 8h00
-- ============================================================

-- Activer pg_cron (doit être activé dans le dashboard Supabase → Extensions)
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Fonction de génération des relances
CREATE OR REPLACE FUNCTION generate_relance_tasks()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  app RECORD;
BEGIN
  -- J+7 : candidatures soumises il y a exactement 7 jours, encore en attente
  FOR app IN
    SELECT
      a.id          AS application_id,
      sp.first_name,
      sp.last_name,
      p.program_name
    FROM applications a
    LEFT JOIN student_profiles sp ON sp.id = a.student_profile_id
    LEFT JOIN programs          p  ON p.id  = a.program_id
    WHERE
      a.status IN ('submitted', 'pending', 'en_attente', 'incomplete')
      AND a.created_at::date = (CURRENT_DATE - INTERVAL '7 days')::date
      AND NOT EXISTS (
        SELECT 1 FROM tasks t
        WHERE t.application_id = a.id
          AND t.task_type = 'reminder_j7'
      )
  LOOP
    INSERT INTO tasks (
      application_id,
      title,
      task_type,
      assignee_label,
      priority,
      due_date
    ) VALUES (
      app.application_id,
      'Relance J+7 — ' || COALESCE(app.first_name || ' ' || app.last_name, 'Candidat') ||
        CASE WHEN app.program_name IS NOT NULL THEN ' (' || app.program_name || ')' ELSE '' END,
      'reminder_j7',
      'Admissions',
      'normal',
      CURRENT_DATE + INTERVAL '2 days'
    );
  END LOOP;

  -- J+14 : candidatures soumises il y a exactement 14 jours, encore en attente
  FOR app IN
    SELECT
      a.id          AS application_id,
      sp.first_name,
      sp.last_name,
      p.program_name
    FROM applications a
    LEFT JOIN student_profiles sp ON sp.id = a.student_profile_id
    LEFT JOIN programs          p  ON p.id  = a.program_id
    WHERE
      a.status IN ('submitted', 'pending', 'en_attente', 'incomplete')
      AND a.created_at::date = (CURRENT_DATE - INTERVAL '14 days')::date
      AND NOT EXISTS (
        SELECT 1 FROM tasks t
        WHERE t.application_id = a.id
          AND t.task_type = 'reminder_j14'
      )
  LOOP
    INSERT INTO tasks (
      application_id,
      title,
      task_type,
      assignee_label,
      priority,
      due_date
    ) VALUES (
      app.application_id,
      'Relance J+14 — ' || COALESCE(app.first_name || ' ' || app.last_name, 'Candidat') ||
        CASE WHEN app.program_name IS NOT NULL THEN ' (URGENT — ' || app.program_name || ')' ELSE ' (URGENT)' END,
      'reminder_j14',
      'Admissions',
      'urgent',
      CURRENT_DATE + INTERVAL '1 day'
    );
  END LOOP;
END;
$$;

-- Permissions : la fonction peut insérer dans tasks
GRANT EXECUTE ON FUNCTION generate_relance_tasks() TO service_role;

-- Planification : tous les jours à 8h00 UTC
-- À exécuter manuellement dans le SQL Editor Supabase après activation pg_cron :
--
--   SELECT cron.schedule(
--     'generate-relances-daily',
--     '0 8 * * *',
--     'SELECT generate_relance_tasks()'
--   );
--
-- Pour vérifier les jobs planifiés : SELECT * FROM cron.job;
-- Pour tester immédiatement : SELECT generate_relance_tasks();
