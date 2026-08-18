-- Trace le nombre de tentatives d'envoi (retry automatique dans
-- send-application-email) pour repondre au besoin CDC "logs & preuves :
-- ... retries".

ALTER TABLE "public"."email_logs"
    ADD COLUMN IF NOT EXISTS "retry_count" integer DEFAULT 0 NOT NULL;
