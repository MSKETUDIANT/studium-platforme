-- Corrige deux notifications etudiant prevues au CDC (A6) mais jamais
-- declenchees en pratique :
--
-- 1. "Candidature recue" : notify_application_status() ne tourne qu'en
--    AFTER UPDATE, donc une candidature creee directement avec
--    status='submitted' (soumission immediate, sans brouillon prealable)
--    ne declenche jamais rien. Et meme via UPDATE (brouillon -> soumise,
--    ou renvoi apres correction), le CASE n'a pas de branche 'submitted' :
--    aucune notification de confirmation de reception n'est jamais creee,
--    quel que soit le chemin de soumission.
-- 2. "Deadline approche" : le type existe dans le CHECK constraint et a un
--    rendu dedie cote mobile (notifications_page.dart), mais aucun cron ne
--    l'insere jamais. Seul generate_relance_tasks() existe, et il ne
--    concerne que les taches internes de l'equipe (B7), pas les etudiants.

-- 1) notify_application_status() : ajoute le cas 'submitted' et fait
--    tourner le trigger aussi sur INSERT (candidature soumise directement).
CREATE OR REPLACE FUNCTION notify_application_status()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  prog_name TEXT;
  title_txt TEXT;
  body_txt  TEXT;
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  SELECT program_name INTO prog_name FROM programs WHERE id = NEW.program_id;

  title_txt := CASE NEW.status
    WHEN 'submitted'        THEN 'Candidature recue'
    WHEN 'needsfix'         THEN 'Correction requise'
    WHEN 'verified'         THEN 'Candidature validee'
    WHEN 'sent'             THEN 'Candidature envoyee'
    WHEN 'accepted'         THEN 'Candidature acceptee !'
    WHEN 'rejected'         THEN 'Candidature refusee'
    WHEN 'pending_decision' THEN 'Decision en attente'
    ELSE NULL
  END;

  IF title_txt IS NOT NULL THEN
    body_txt := CASE NEW.status
      WHEN 'submitted' THEN COALESCE(prog_name, 'Votre candidature') || ' a bien ete recue et sera examinee par notre equipe.'
      ELSE COALESCE(prog_name, 'Votre candidature') || ' - statut mis a jour.'
    END;

    INSERT INTO notifications (user_id, type, title, body, payload)
    VALUES (
      NEW.student_profile_id,
      'app_status',
      title_txt,
      body_txt,
      jsonb_build_object(
        'application_id', NEW.id,
        'status',         NEW.status,
        'program_name',   COALESCE(prog_name, '')
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_application_notification ON applications;
CREATE TRIGGER trg_application_notification
  AFTER INSERT OR UPDATE ON applications
  FOR EACH ROW EXECUTE FUNCTION notify_application_status();

-- 2) Notifications "deadline approche" : une candidature encore actionnable
--    par l'etudiant (brouillon pas encore soumis, ou a corriger) dont le
--    programme arrive a echeance sous 7 jours. Dedoublonnage par
--    NOT EXISTS sur (user_id, type, application_id) : notifie une seule
--    fois par candidature, meme si le cron tourne tous les jours.
CREATE OR REPLACE FUNCTION notify_approaching_deadlines()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  app RECORD;
BEGIN
  FOR app IN
    SELECT a.id AS application_id, a.student_profile_id, p.program_name, p.deadline
    FROM applications a
    JOIN programs p ON p.id = a.program_id
    WHERE
      a.status IN ('draft', 'needsfix')
      AND p.deadline IS NOT NULL
      AND p.deadline BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
      AND NOT EXISTS (
        SELECT 1 FROM notifications n
        WHERE n.user_id = a.student_profile_id
          AND n.type = 'deadline'
          AND (n.payload->>'application_id')::uuid = a.id
      )
  LOOP
    INSERT INTO notifications (user_id, type, title, body, payload)
    VALUES (
      app.student_profile_id,
      'deadline',
      'Deadline qui approche',
      COALESCE(app.program_name, 'Un programme') || ' : date limite le ' ||
        to_char(app.deadline, 'DD/MM/YYYY') || '. Finalisez votre candidature avant cette date.',
      jsonb_build_object(
        'application_id', app.application_id,
        'program_name',   COALESCE(app.program_name, ''),
        'deadline',       app.deadline
      )
    );
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION notify_approaching_deadlines() TO service_role;

CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.unschedule('notify-approaching-deadlines-daily')
WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'notify-approaching-deadlines-daily');

SELECT cron.schedule(
  'notify-approaching-deadlines-daily',
  '0 7 * * *',
  'SELECT notify_approaching_deadlines()'
);
