-- Tags sur les conversations de messagerie

ALTER TABLE conversations
  ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

CREATE INDEX IF NOT EXISTS idx_conversations_tags ON conversations USING GIN(tags);
