-- Bucket privé pour les fichiers volumineux (Mode 2 > 25 MB)
INSERT INTO storage.buckets (id, name, public)
VALUES ('large-file-transfers', 'large-file-transfers', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Upload large file transfers"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'large-file-transfers');

CREATE POLICY "Read large file transfers"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'large-file-transfers');