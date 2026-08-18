-- RLS pour student_profiles : chaque utilisateur gère uniquement son propre profil.
-- Sans ces policies, l'upsert depuis l'app mobile échoue silencieusement (403).

ALTER TABLE student_profiles ENABLE ROW LEVEL SECURITY;

-- Lecture : l'étudiant lit son propre profil
DROP POLICY IF EXISTS "student_read_own_profile" ON student_profiles;
CREATE POLICY "student_read_own_profile" ON student_profiles
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

-- Création : l'étudiant crée son profil (onboarding)
DROP POLICY IF EXISTS "student_insert_own_profile" ON student_profiles;
CREATE POLICY "student_insert_own_profile" ON student_profiles
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

-- Mise à jour : l'étudiant modifie son propre profil
DROP POLICY IF EXISTS "student_update_own_profile" ON student_profiles;
CREATE POLICY "student_update_own_profile" ON student_profiles
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Lecture staff : le staff peut lire tous les profils (pour le dashboard)
DROP POLICY IF EXISTS "staff_read_all_profiles" ON student_profiles;
CREATE POLICY "staff_read_all_profiles" ON student_profiles
  FOR SELECT TO authenticated
  USING (is_staff());