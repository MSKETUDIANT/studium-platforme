-- Pièces jointes dans les messages (US A5 / B8)
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS file_url  TEXT,
  ADD COLUMN IF NOT EXISTS file_name TEXT;

-- Bucket de stockage dédié aux pièces jointes de messagerie
-- À exécuter dans le dashboard Supabase Storage si le bucket n'existe pas :
--   INSERT INTO storage.buckets (id, name, public)
--   VALUES ('message-attachments', 'message-attachments', true)
--   ON CONFLICT DO NOTHING;

-- Politique : les étudiants peuvent uploader dans leur propre dossier
-- CREATE POLICY "Students upload own attachments" ON storage.objects
--   FOR INSERT WITH CHECK (
--     bucket_id = 'message-attachments'
--     AND (storage.foldername(name))[1] = auth.uid()::text
--   );

-- Politique : lecture publique
-- CREATE POLICY "Public read message-attachments" ON storage.objects
--   FOR SELECT USING (bucket_id = 'message-attachments');