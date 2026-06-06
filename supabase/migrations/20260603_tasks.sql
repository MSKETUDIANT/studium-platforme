-- US-7.6 : Tâches internes et relances automatiques J+7 / J+14

CREATE TABLE IF NOT EXISTS tasks (
  id             UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  application_id UUID        REFERENCES applications(id) ON DELETE CASCADE,
  title          TEXT        NOT NULL,
  description    TEXT,
  task_type      TEXT        NOT NULL DEFAULT 'manual'
                             CHECK (task_type IN ('manual', 'reminder_j7', 'reminder_j14')),
  due_date       TIMESTAMPTZ,
  assigned_to    UUID        REFERENCES auth.users(id),
  completed_at   TIMESTAMPTZ,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  created_by     UUID        REFERENCES auth.users(id)
);

CREATE INDEX IF NOT EXISTS idx_tasks_application_id  ON tasks(application_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to     ON tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_pending_due     ON tasks(due_date) WHERE completed_at IS NULL;

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "team_tasks_all" ON tasks
  FOR ALL TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM auth.users
      WHERE raw_user_meta_data->>'role' IN ('admin', 'admissions', 'manager', 'support')
    )
  );

-- Service role (Edge Function relances) peut insérer
CREATE POLICY "service_insert_tasks" ON tasks
  FOR INSERT WITH CHECK (true);

--  Fonction : créer relances J+7 et J+14 pour candidatures envoyées sans réponse
-- Utilise email_logs.sent_at (date réelle d'envoi) plutôt qu'updated_at inexistant

CREATE OR REPLACE FUNCTION create_reminder_tasks()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  app RECORD;
BEGIN
  -- Relances J+7 : email envoyé il y a exactement 7 jours, encore en statut "sent"
  FOR app IN
    SELECT DISTINCT ON (a.id)
      a.id, p.program_name, p.university_name
    FROM applications a
    JOIN email_logs el  ON el.application_id = a.id AND el.status = 'sent'
    LEFT JOIN programs p ON p.id = a.program_id
    WHERE a.status = 'sent'
      AND el.sent_at::date = (NOW() - INTERVAL '7 days')::date
      AND NOT EXISTS (
        SELECT 1 FROM tasks t
        WHERE t.application_id = a.id
          AND t.task_type = 'reminder_j7'
      )
    ORDER BY a.id, el.sent_at DESC
  LOOP
    INSERT INTO tasks (application_id, title, description, task_type, due_date)
    VALUES (
      app.id,
      'Relance J+7  ' || COALESCE(app.university_name, 'Université'),
      'La candidature pour ' || COALESCE(app.program_name, 'ce programme') ||
        ' a été envoyée il y a 7 jours sans réponse. Envisager une relance.',
      'reminder_j7',
      NOW() + INTERVAL '2 days'
    );
  END LOOP;

  -- Relances J+14 : email envoyé il y a exactement 14 jours, encore en statut "sent"
  FOR app IN
    SELECT DISTINCT ON (a.id)
      a.id, p.program_name, p.university_name
    FROM applications a
    JOIN email_logs el  ON el.application_id = a.id AND el.status = 'sent'
    LEFT JOIN programs p ON p.id = a.program_id
    WHERE a.status = 'sent'
      AND el.sent_at::date = (NOW() - INTERVAL '14 days')::date
      AND NOT EXISTS (
        SELECT 1 FROM tasks t
        WHERE t.application_id = a.id
          AND t.task_type = 'reminder_j14'
      )
    ORDER BY a.id, el.sent_at DESC
  LOOP
    INSERT INTO tasks (application_id, title, description, task_type, due_date)
    VALUES (
      app.id,
      'Relance J+14  ' || COALESCE(app.university_name, 'Université'),
      'La candidature pour ' || COALESCE(app.program_name, 'ce programme') ||
        ' a été envoyée il y a 14 jours sans réponse. Relance urgente recommandée.',
      'reminder_j14',
      NOW() + INTERVAL '1 day'
    );
  END LOOP;
END;
$$;
