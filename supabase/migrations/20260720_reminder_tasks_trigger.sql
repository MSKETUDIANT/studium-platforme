-- Les taches de relance J+7/J+14 (US-7.6) n'etaient creees que par le
-- chemin dropdown manuel (updateApplicationStatus, cote client), jamais
-- par le vrai envoi email automatique : l'edge function
-- send-application-email met a jour applications.status directement en
-- base, sans jamais passer par ce code client. Un trigger, qui reagit au
-- changement de statut quelle que soit la source (client ou edge
-- function), couvre les deux chemins de facon fiable — meme pattern que
-- handle_application_accepted() pour les commissions ambassadeurs.

CREATE OR REPLACE FUNCTION public.create_reminder_tasks_on_sent()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status AND NEW.status = 'sent' THEN
    -- Evite les doublons si le statut repasse plusieurs fois par "sent"
    IF NOT EXISTS (
      SELECT 1 FROM public.tasks
      WHERE application_id = NEW.id AND task_type IN ('reminder_j7', 'reminder_j14')
    ) THEN
      INSERT INTO public.tasks
        (application_id, title, task_type, due_date, priority, assignee_label, reminder_hours)
      VALUES
        (NEW.id, 'Relance J+7 — vérifier réponse université',  'reminder_j7',  now() + interval '7 days',  'normal', 'Admissions', 24),
        (NEW.id, 'Relance J+14 — suivi candidature',            'reminder_j14', now() + interval '14 days', 'urgent', 'Admissions', 24);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_create_reminder_tasks_on_sent
  AFTER UPDATE ON public.applications
  FOR EACH ROW EXECUTE FUNCTION public.create_reminder_tasks_on_sent();
