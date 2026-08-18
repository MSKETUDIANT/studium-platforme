-- ===========================================================================
-- Fix messagerie temps réel + notifications documents
-- État avant migration :
--   - unread_student colonne : OK (déjà présente)
--   - trigger update_conversation_on_message : OK (déjà correct)
--   - supabase_realtime publication : VIDE (problème critique)
--   - notifications types : app_status, doc_rejected, message_received, deadline
--   - triggers notification documents : ABSENTS
-- ===========================================================================

-- 1. Activer Realtime sur messages et conversations (problème critique)
ALTER TABLE messages      REPLICA IDENTITY FULL;
ALTER TABLE conversations REPLICA IDENTITY FULL;

DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE messages;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END;
$$;

-- 2. Ajouter doc_approved au check constraint notifications.type
--    (suppression dynamique car le nom de constraint est auto-généré par Postgres)
DO $$
DECLARE
  cname TEXT;
BEGIN
  SELECT conname INTO cname
  FROM pg_constraint
  WHERE conrelid = 'notifications'::regclass
    AND contype = 'c';
  IF cname IS NOT NULL THEN
    EXECUTE format('ALTER TABLE notifications DROP CONSTRAINT %I', cname);
  END IF;
END;
$$;

ALTER TABLE notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type IN (
    'app_status',
    'doc_rejected',
    'doc_approved',
    'message_received',
    'deadline'
  ));

-- 3. Trigger : notification en base sur rejet de document (absent)
CREATE OR REPLACE FUNCTION notify_document_rejection()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status = 'rejected' AND OLD.status IS DISTINCT FROM 'rejected' THEN
    INSERT INTO notifications (user_id, type, title, body, payload)
    VALUES (
      NEW.student_profile_id,
      'doc_rejected',
      'Document rejeté',
      'Un document de votre dossier a été rejeté.' ||
        CASE WHEN NEW.rejection_reason IS NOT NULL
          THEN ' Motif : ' || NEW.rejection_reason
          ELSE ''
        END,
      jsonb_build_object(
        'document_id',      NEW.id,
        'document_type',    NEW.type,
        'rejection_reason', COALESCE(NEW.rejection_reason, '')
      )
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_document_rejection_notification ON documents;
CREATE TRIGGER trg_document_rejection_notification
  AFTER UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION notify_document_rejection();

-- 4. Trigger : notification en base sur approbation de document (absent)
CREATE OR REPLACE FUNCTION notify_document_approval()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status IS DISTINCT FROM 'approved' THEN
    INSERT INTO notifications (user_id, type, title, body, payload)
    VALUES (
      NEW.student_profile_id,
      'doc_approved',
      'Document approuvé',
      'Un document de votre dossier a été approuvé par l''équipe Studium.',
      jsonb_build_object(
        'document_id',   NEW.id,
        'document_type', NEW.type
      )
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_document_approval_notification ON documents;
CREATE TRIGGER trg_document_approval_notification
  AFTER UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION notify_document_approval();