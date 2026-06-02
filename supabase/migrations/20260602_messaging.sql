-- Une conversation par étudiant (1:1 avec student_profiles)
CREATE TABLE IF NOT EXISTS conversations (
  id                 UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  student_profile_id UUID        NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  unread_staff       INT         NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_conversations_student ON conversations(student_profile_id);

-- Messages de la conversation
CREATE TABLE IF NOT EXISTS messages (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID        NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_type     TEXT        NOT NULL CHECK (sender_type IN ('student', 'staff')),
  sender_id       UUID,
  content         TEXT        NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  read_at         TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id, created_at);

-- Mise à jour auto de updated_at + unread_staff sur la conversation
CREATE OR REPLACE FUNCTION update_conversation_on_message()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE conversations SET
    updated_at   = NOW(),
    unread_staff = CASE WHEN NEW.sender_type = 'student' THEN unread_staff + 1 ELSE unread_staff END
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_message_insert
AFTER INSERT ON messages
FOR EACH ROW EXECUTE FUNCTION update_conversation_on_message();

-- RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages      ENABLE ROW LEVEL SECURITY;

-- Staff voit tout
CREATE POLICY "staff_conversations_all" ON conversations FOR ALL TO authenticated USING (true);
CREATE POLICY "staff_messages_all"      ON messages      FOR ALL TO authenticated USING (true);
