-- Recree application_packs (supprimee par 20260720_drop_dead_tables.sql car
-- jamais implementee) pour la vraie fonctionnalite de pack PDF assemble
-- (generate-application-pack), qui remplace l'envoi de documents individuels.

-- is_staff() est definie dans 20260624_documents_staff_rls.sql, mais cette
-- migration ne semble jamais avoir ete appliquee sur la base reelle (constate
-- via l'erreur "function is_staff() does not exist"). Redefinie ici de façon
-- idempotente pour ne plus dependre de l'etat des migrations precedentes.
CREATE OR REPLACE FUNCTION is_staff()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles ur
    JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid()
      AND r.name IN ('admin', 'admissions', 'manager', 'support')
  );
$$;

CREATE TABLE IF NOT EXISTS "public"."application_packs" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() PRIMARY KEY,
    "application_id" "uuid" NOT NULL REFERENCES "public"."applications"("id") ON DELETE CASCADE,
    "pack_url" "text" NOT NULL,
    "version" integer DEFAULT 1 NOT NULL,
    "generated_by" "uuid",
    "generated_at" timestamp with time zone DEFAULT "now"()
);

CREATE INDEX IF NOT EXISTS idx_application_packs_application_id
  ON "public"."application_packs"("application_id");

ALTER TABLE "public"."application_packs" ENABLE ROW LEVEL SECURITY;

-- Etudiant : lecture de ses propres packs (meme pattern que
-- student_read_own_application_documents dans le schema de base)
DROP POLICY IF EXISTS "student_read_own_application_packs" ON "public"."application_packs";
CREATE POLICY "student_read_own_application_packs" ON "public"."application_packs"
  FOR SELECT
  USING (("auth"."uid"() = ( SELECT "applications"."student_profile_id"
     FROM "public"."applications"
    WHERE ("applications"."id" = "application_packs"."application_id"))));

-- Staff (admin/admissions/manager/support) : lecture de tous les packs
DROP POLICY IF EXISTS "staff_read_application_packs" ON "public"."application_packs";
CREATE POLICY "staff_read_application_packs" ON "public"."application_packs"
  FOR SELECT TO authenticated
  USING (is_staff());

-- Ecriture reservee au service_role (Edge Function generate-application-pack) :
-- aucune policy INSERT/UPDATE/DELETE pour authenticated => refusee par defaut,
-- le service_role contourne RLS.

-- Bucket de stockage pour les packs assembles (public, meme logique que le
-- bucket "documents" existant)
INSERT INTO storage.buckets (id, name, public)
VALUES ('application-packs', 'application-packs', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Upload application packs" ON storage.objects;
CREATE POLICY "Upload application packs"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'application-packs');

DROP POLICY IF EXISTS "Read application packs" ON storage.objects;
CREATE POLICY "Read application packs"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'application-packs');
