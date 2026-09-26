-- Bug reel : le bucket "profile-photos" n'existe pas en base, alors que
-- deux chemins de code (edit_profile_page.dart::_uploadPhoto et
-- ProfileRemoteDatasource.updatePhoto) uploadent dedans. L'upload echoue
-- silencieusement (erreur catchee, ancienne photoUrl -- souvent null --
-- retournee sans message), donnant l'impression que rien ne se passe :
-- l'avatar reste sur le placeholder par defaut apres "Modifier la photo".
--
-- Bucket public (photo de profil visible par l'equipe staff sur la fiche
-- etudiant, pas une piece sensible comme les documents) ; ecriture reservee
-- au proprietaire (premier segment du chemin = son user_id), meme
-- convention que les buckets "documents" et "large-file-transfers".

INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-photos', 'profile-photos', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public read profile photos" ON storage.objects;
CREATE POLICY "Public read profile photos" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'profile-photos');

DROP POLICY IF EXISTS "Owner upload profile photo" ON storage.objects;
CREATE POLICY "Owner upload profile photo" ON storage.objects
  FOR INSERT
  WITH CHECK (bucket_id = 'profile-photos' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "Owner update profile photo" ON storage.objects;
CREATE POLICY "Owner update profile photo" ON storage.objects
  FOR UPDATE
  USING (bucket_id = 'profile-photos' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "Owner delete profile photo" ON storage.objects;
CREATE POLICY "Owner delete profile photo" ON storage.objects
  FOR DELETE
  USING (bucket_id = 'profile-photos' AND (storage.foldername(name))[1] = auth.uid()::text);
