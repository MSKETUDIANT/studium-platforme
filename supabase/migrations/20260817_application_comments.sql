-- Fil de commentaires internes horodates/multi-auteurs par candidature,
-- sur le meme modele que student_notes (deja en prod pour les etudiants).
-- Vient en complement de applications.notes (champ unique, conserve tel
-- quel car repris dans le pack PDF) : ceci est la discussion d'equipe.

CREATE TABLE IF NOT EXISTS "public"."application_comments" (
    "id"             "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "application_id" "uuid" NOT NULL,
    "author_id"      "uuid",
    "author_email"   "text",
    "content"        "text" NOT NULL,
    "created_at"     timestamp with time zone DEFAULT "now"(),
    "updated_at"     timestamp with time zone DEFAULT "now"()
);

ALTER TABLE "public"."application_comments" OWNER TO "postgres";

ALTER TABLE ONLY "public"."application_comments"
    ADD CONSTRAINT "application_comments_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."application_comments"
    ADD CONSTRAINT "application_comments_application_id_fkey"
    FOREIGN KEY ("application_id") REFERENCES "public"."applications"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."application_comments"
    ADD CONSTRAINT "application_comments_author_id_fkey"
    FOREIGN KEY ("author_id") REFERENCES "auth"."users"("id");

CREATE INDEX "idx_application_comments_application"
    ON "public"."application_comments" USING "btree" ("application_id");

ALTER TABLE "public"."application_comments" ENABLE ROW LEVEL SECURITY;

-- Meme perimetre de roles que team_manage_notes (student_notes) : toute
-- l'equipe interne peut lire/ecrire, y compris support.
CREATE POLICY "team_manage_application_comments" ON "public"."application_comments"
    TO "authenticated"
    USING ((EXISTS ( SELECT 1
       FROM ("public"."user_roles" "ur"
         JOIN "public"."roles" "r" ON (("ur"."role_id" = "r"."id")))
      WHERE (("ur"."user_id" = "auth"."uid"())
        AND ("r"."name" = ANY (ARRAY['admin'::"text", 'admissions'::"text", 'manager'::"text", 'support'::"text"]))))));
