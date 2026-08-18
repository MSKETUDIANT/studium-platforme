-- Trigger : notification en base quand le staff envoie un message à un étudiant
-- Le type message_received est déjà dans le check constraint

CREATE OR REPLACE FUNCTION notify_message_received()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  student_id UUID;
  preview    TEXT;
BEGIN
  -- Uniquement les messages envoyés par le staff
  IF NEW.sender_type = 'staff' THEN
    SELECT student_profile_id INTO student_id
    FROM conversations
    WHERE id = NEW.conversation_id;

    IF student_id IS NOT NULL THEN
      -- Apercu du message (100 chars max)
      preview := LEFT(TRIM(NEW.content), 100);
      IF LENGTH(TRIM(NEW.content)) > 100 THEN
        preview := preview || '...';
      END IF;

      INSERT INTO notifications (user_id, type, title, body, payload)
      VALUES (
        student_id,
        'message_received',
        'Nouveau message de l''equipe Studium',
        preview,
        jsonb_build_object('conversation_id', NEW.conversation_id)
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_message_received_notification ON messages;
CREATE TRIGGER trg_message_received_notification
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION notify_message_received();