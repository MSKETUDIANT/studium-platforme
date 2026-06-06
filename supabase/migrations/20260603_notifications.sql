-- US-6.5 : Centre de notifications étudiant
-- Déclenché automatiquement via trigger sur changements de statut candidature

CREATE TABLE IF NOT EXISTS notifications (
  id         UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id    UUID        NOT NULL,  -- = auth.uid() (= student_profiles.id)
  type       TEXT        NOT NULL CHECK (type IN ('status_change', 'message', 'document_rejected', 'deadline')),
  title      TEXT        NOT NULL,
  body       TEXT,
  payload    JSONB       DEFAULT '{}',
  read_at    TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_created
  ON notifications(user_id, created_at DESC);

-- RLS : chaque étudiant voit uniquement ses propres notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "student_own_notifications" ON notifications
  FOR ALL TO authenticated
  USING (user_id = auth.uid());

-- Staff peut insérer (Edge Functions, triggers via service role)
CREATE POLICY "service_insert_notifications" ON notifications
  FOR INSERT WITH CHECK (true);

--  Trigger : notification automatique sur changement de statut candidature 

CREATE OR REPLACE FUNCTION notify_application_status()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  prog_name  TEXT;
  title_txt  TEXT;
  body_txt   TEXT;
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    SELECT program_name INTO prog_name FROM programs WHERE id = NEW.program_id;

    title_txt := CASE NEW.status
      WHEN 'needsfix'         THEN 'Correction requise'
      WHEN 'verified'         THEN 'Candidature validée'
      WHEN 'sent'             THEN 'Candidature envoyée'
      WHEN 'accepted'         THEN 'Candidature acceptée !'
      WHEN 'rejected'         THEN 'Candidature refusée'
      WHEN 'pending_decision' THEN 'Décision en attente'
      ELSE NULL
    END;

    -- Notifier uniquement les transitions significatives
    IF title_txt IS NOT NULL THEN
      body_txt := COALESCE(prog_name, 'Votre candidature') || '  statut mis à jour.';

      INSERT INTO notifications (user_id, type, title, body, payload)
      VALUES (
        NEW.student_profile_id,
        'status_change',
        title_txt,
        body_txt,
        jsonb_build_object(
          'application_id', NEW.id,
          'status',         NEW.status,
          'program_name',   COALESCE(prog_name, '')
        )
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_application_notification
  AFTER UPDATE ON applications
  FOR EACH ROW EXECUTE FUNCTION notify_application_status();

--  Trigger : notification sur rejet de document 

CREATE OR REPLACE FUNCTION notify_document_rejection()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status = 'rejected' AND OLD.status IS DISTINCT FROM 'rejected' THEN
    INSERT INTO notifications (user_id, type, title, body, payload)
    VALUES (
      NEW.student_profile_id,
      'document_rejected',
      'Document rejeté',
      'Un document de votre dossier a été rejeté.' ||
        CASE WHEN NEW.rejection_reason IS NOT NULL
          THEN ' Motif : ' || NEW.rejection_reason
          ELSE ''
        END,
      jsonb_build_object(
        'document_id',       NEW.id,
        'document_type',     NEW.type,
        'rejection_reason',  COALESCE(NEW.rejection_reason, '')
      )
    );
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_document_notification
  AFTER UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION notify_document_rejection();
