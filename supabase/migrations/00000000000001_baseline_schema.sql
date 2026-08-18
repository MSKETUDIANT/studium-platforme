


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE OR REPLACE FUNCTION "public"."assign_default_role"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Attendre 100ms pour laisser l'Edge Function agir en premier
  -- Assigner student SEULEMENT si aucun rôle n'existe encore
  PERFORM pg_sleep(0.1);
  
  IF NOT EXISTS (
    SELECT 1 FROM public.user_roles WHERE user_id = NEW.id
  ) THEN
    INSERT INTO public.user_roles (user_id, role_id, status)
    SELECT NEW.id, id, 'active'
    FROM public.roles
    WHERE name = 'student';
  END IF;
  
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."assign_default_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_team_member"("member_email" "text", "member_password" "text", "member_role" "text") RETURNS json
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  new_user_id UUID;
  role_id UUID;
BEGIN
  SELECT id INTO role_id FROM public.roles WHERE name = member_role;
  IF role_id IS NULL THEN
    RETURN json_build_object('error', 'Rôle introuvable');
  END IF;

  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    role,
    aud
  )
  VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000',
    member_email,
    crypt(member_password, gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    false,
    'authenticated',
    'authenticated'
  )
  RETURNING id INTO new_user_id;

  -- Créer l'identité email
  INSERT INTO auth.identities (
    id, user_id, identity_data, provider, 
    last_sign_in_at, created_at, updated_at, provider_id
  )
  VALUES (
    gen_random_uuid(),
    new_user_id,
    json_build_object('sub', new_user_id::text, 'email', member_email),
    'email',
    NOW(), NOW(), NOW(),
    member_email
  );

  INSERT INTO public.user_roles (user_id, role_id, status)
  VALUES (new_user_id, role_id, 'active');

  RETURN json_build_object('success', true, 'user_id', new_user_id);
END;
$$;


ALTER FUNCTION "public"."create_team_member"("member_email" "text", "member_password" "text", "member_role" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."fn_log_application_status_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO application_status_history
      (application_id, from_status, to_status, changed_by, created_at)
    VALUES
      (NEW.id, OLD.status, NEW.status, auth.uid(), now());
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."fn_log_application_status_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_team_members"() RETURNS TABLE("id" "uuid", "email" "text", "role" "text", "status" "text", "created_at" timestamp with time zone)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.email::TEXT,
    r.name::TEXT as role,
    ur.status::TEXT,
    u.created_at
  FROM auth.users u
  JOIN public.user_roles ur ON ur.user_id = u.id
  JOIN public.roles r ON r.id = ur.role_id
  WHERE r.name IN ('admin', 'admissions', 'support', 'manager')
  ORDER BY u.created_at DESC;
END;
$$;


ALTER FUNCTION "public"."get_team_members"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_team_member"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = auth.uid()
      AND r.name IN ('admin', 'admissions', 'manager', 'support')
  );
$$;


ALTER FUNCTION "public"."is_team_member"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_application_status"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO audit_logs (action, entity_type, entity_id, old_value, new_value, actor_id, actor_email)
    VALUES ('status_update', 'application', NEW.id, OLD.status, NEW.status,
            auth.uid(), (auth.jwt() ->> 'email'));
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."log_application_status"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_document_status"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO audit_logs (action, entity_type, entity_id, old_value, new_value, actor_id, actor_email)
    VALUES (
      CASE NEW.status
        WHEN 'approved' THEN 'document_approve'
        WHEN 'rejected' THEN 'document_reject'
        ELSE 'status_update'
      END,
      'document', NEW.id, OLD.status, NEW.status,
      auth.uid(), (auth.jwt() ->> 'email')
    );
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."log_document_status"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_program_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO audit_logs (action, entity_type, entity_id, actor_id, actor_email)
  VALUES (
    CASE TG_OP WHEN 'INSERT' THEN 'program_create' ELSE 'program_update' END,
    'program', NEW.id,
    auth.uid(), (auth.jwt() ->> 'email')
  );
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."log_program_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_application_status"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  prog_name TEXT;
  title_txt TEXT;
  body_txt  TEXT;
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    SELECT program_name INTO prog_name FROM programs WHERE id = NEW.program_id;

    title_txt := CASE NEW.status
      WHEN 'needsfix'         THEN 'Correction requise'
      WHEN 'verified'         THEN 'Candidature validee'
      WHEN 'sent'             THEN 'Candidature envoyee'
      WHEN 'accepted'         THEN 'Candidature acceptee !'
      WHEN 'rejected'         THEN 'Candidature refusee'
      WHEN 'pending_decision' THEN 'Decision en attente'
      ELSE NULL
    END;

    IF title_txt IS NOT NULL THEN
      body_txt := COALESCE(prog_name, 'Votre candidature') || ' - statut mis a jour.';
      INSERT INTO notifications (user_id, type, title, body, payload)
      VALUES (
        NEW.student_profile_id,
        'app_status',
        title_txt,
        body_txt,
        jsonb_build_object(
          'application_id', NEW.id,
          'status',         NEW.status,
          'program_name',   COALESCE(prog_name, '')
        )
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_application_status"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_document_approval"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status IS DISTINCT FROM 'approved' THEN
    INSERT INTO notifications (user_id, type, title, body, payload)
    VALUES (
      NEW.student_profile_id, 'doc_approved', 'Document approuvé',
      'Un document de votre dossier a été approuvé par l''équipe Studium.',
      jsonb_build_object('document_id', NEW.id, 'document_type', NEW.type)
    );
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_document_approval"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_document_rejection"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  IF NEW.status = 'rejected' AND OLD.status IS DISTINCT FROM 'rejected' THEN
    INSERT INTO notifications (user_id, type, title, body, payload)
    VALUES (
      NEW.student_profile_id, 'doc_rejected', 'Document rejeté',
      'Un document de votre dossier a été rejeté.' ||
        CASE WHEN NEW.rejection_reason IS NOT NULL
          THEN ' Motif : ' || NEW.rejection_reason ELSE '' END,
      jsonb_build_object('document_id', NEW.id, 'document_type', NEW.type,
        'rejection_reason', COALESCE(NEW.rejection_reason, ''))
    );
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."notify_document_rejection"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."notify_message_received"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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


ALTER FUNCTION "public"."notify_message_received"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_conversation_on_message"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  UPDATE conversations SET
    updated_at     = NOW(),
    unread_staff   = CASE WHEN NEW.sender_type = 'student' 
                      THEN unread_staff + 1   ELSE unread_staff   END,
    unread_student = CASE WHEN NEW.sender_type = 'staff'   
                      THEN unread_student + 1 ELSE unread_student END
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_conversation_on_message"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_member_status"("target_user_id" "uuid", "new_status" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  UPDATE public.user_roles
  SET status = new_status
  WHERE user_id = target_user_id;
END;
$$;


ALTER FUNCTION "public"."update_member_status"("target_user_id" "uuid", "new_status" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."academic_backgrounds" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "degree" "text" NOT NULL,
    "university" "text" NOT NULL,
    "year" integer,
    "average" numeric(4,2),
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."academic_backgrounds" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."application_documents" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "application_id" "uuid",
    "document_id" "uuid",
    "required_flag" boolean DEFAULT true,
    "status" "text" DEFAULT 'missing'::"text",
    "rejection_reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "application_documents_status_check" CHECK (("status" = ANY (ARRAY['missing'::"text", 'provided'::"text", 'under_review'::"text", 'approved'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."application_documents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."application_fields" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "application_id" "uuid",
    "key" "text" NOT NULL,
    "value" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."application_fields" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."application_packs" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "application_id" "uuid",
    "pack_url" "text" NOT NULL,
    "version" integer DEFAULT 1,
    "generated_by" "uuid",
    "generated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."application_packs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."application_status_history" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "application_id" "uuid",
    "from_status" "text",
    "to_status" "text" NOT NULL,
    "changed_by" "uuid",
    "note" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."application_status_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."applications" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "student_profile_id" "uuid",
    "program_id" "uuid",
    "status" "text" DEFAULT 'draft'::"text",
    "submitted_at" timestamp with time zone,
    "assigned_to" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "notes" "text",
    CONSTRAINT "applications_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'submitted'::"text", 'needsfix'::"text", 'verified'::"text", 'sent'::"text", 'accepted'::"text", 'rejected'::"text", 'pending_decision'::"text", 'archived'::"text"])))
);

ALTER TABLE ONLY "public"."applications" REPLICA IDENTITY FULL;


ALTER TABLE "public"."applications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_logs" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "actor_id" "uuid",
    "action" "text" NOT NULL,
    "entity_type" "text",
    "entity_id" "uuid",
    "metadata" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "actor_email" "text",
    "old_value" "text",
    "new_value" "text"
);


ALTER TABLE "public"."audit_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."commissions" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "ambassador_user_id" "uuid",
    "amount" numeric NOT NULL,
    "status" "text",
    "period_start" "date",
    "period_end" "date",
    "paid_at" timestamp with time zone,
    CONSTRAINT "commissions_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'payable'::"text", 'paid'::"text"])))
);


ALTER TABLE "public"."commissions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."conversations" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "student_profile_id" "uuid",
    "application_id" "uuid",
    "type" "text",
    "assigned_to" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "unread_staff" integer DEFAULT 0 NOT NULL,
    "unread_student" integer DEFAULT 0 NOT NULL,
    "tags" "text"[] DEFAULT '{}'::"text"[],
    CONSTRAINT "conversations_type_check" CHECK (("type" = ANY (ARRAY['team_chat'::"text", 'support_ticket'::"text"])))
);

ALTER TABLE ONLY "public"."conversations" REPLICA IDENTITY FULL;


ALTER TABLE "public"."conversations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."device_tokens" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid",
    "token" "text" NOT NULL,
    "platform" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "device_tokens_platform_check" CHECK (("platform" = ANY (ARRAY['ios'::"text", 'android'::"text"])))
);


ALTER TABLE "public"."device_tokens" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."documents" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "student_profile_id" "uuid",
    "type" "text",
    "file_url" "text" NOT NULL,
    "file_name" "text",
    "mime_type" "text",
    "size_bytes" integer,
    "status" "text" DEFAULT 'uploaded'::"text",
    "rejection_reason" "text",
    "reviewed_by" "uuid",
    "reviewed_at" timestamp with time zone,
    "ai_rejection_suggestion" "text",
    "ai_analyzed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "documents_status_check" CHECK (("status" = ANY (ARRAY['uploaded'::"text", 'under_review'::"text", 'approved'::"text", 'rejected'::"text"]))),
    CONSTRAINT "documents_type_check" CHECK (("type" = ANY (ARRAY['cv'::"text", 'transcript'::"text", 'recommendation'::"text", 'passport'::"text", 'motivation_letter'::"text", 'diploma'::"text", 'language_cert'::"text", 'financial_proof'::"text", 'other'::"text"])))
);


ALTER TABLE "public"."documents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."educations" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "student_profile_id" "uuid",
    "degree" "text" NOT NULL,
    "institution" "text" NOT NULL,
    "graduation_year" integer,
    "gpa" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."educations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."email_logs" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "application_id" "uuid",
    "to_email" "text" NOT NULL,
    "cc_emails" "text"[],
    "subject" "text",
    "provider" "text",
    "provider_message_id" "text",
    "status" "text" DEFAULT 'queued'::"text",
    "error_message" "text",
    "sent_by" "uuid",
    "sent_at" timestamp with time zone,
    "is_followup" boolean DEFAULT false,
    CONSTRAINT "email_logs_provider_check" CHECK (("provider" = ANY (ARRAY['sendgrid'::"text", 'mailgun'::"text", 'ses'::"text"]))),
    CONSTRAINT "email_logs_status_check" CHECK (("status" = ANY (ARRAY['queued'::"text", 'sent'::"text", 'failed'::"text", 'bounced'::"text"])))
);


ALTER TABLE "public"."email_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."email_templates" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "scope" "text",
    "program_id" "uuid",
    "language" "text",
    "subject_template" "text" NOT NULL,
    "body_template" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "email_templates_language_check" CHECK (("language" = ANY (ARRAY['fr'::"text", 'en'::"text"]))),
    CONSTRAINT "email_templates_scope_check" CHECK (("scope" = ANY (ARRAY['global'::"text", 'program'::"text", 'followup'::"text", 'correction'::"text"])))
);


ALTER TABLE "public"."email_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."error_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "type" "text" NOT NULL,
    "message" "text",
    "source" "text",
    "line" integer,
    "stack" "text",
    "context" "jsonb" DEFAULT '{}'::"jsonb",
    "url" "text",
    "user_agent" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."error_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."experiences" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "student_profile_id" "uuid",
    "company" "text" NOT NULL,
    "position" "text" NOT NULL,
    "start_date" "date",
    "end_date" "date",
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."experiences" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."favorites" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "student_profile_id" "uuid",
    "program_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."favorites" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."fcm_tokens" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "token" "text" NOT NULL,
    "platform" "text",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "fcm_tokens_platform_check" CHECK (("platform" = ANY (ARRAY['android'::"text", 'ios'::"text", 'web'::"text"])))
);


ALTER TABLE "public"."fcm_tokens" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."message_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "content" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."message_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "conversation_id" "uuid",
    "sender_id" "uuid",
    "content" "text" NOT NULL,
    "attachments" "jsonb",
    "read_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "sender_type" "text",
    "file_url" "text",
    "file_name" "text",
    CONSTRAINT "messages_sender_type_check" CHECK (("sender_type" = ANY (ARRAY['student'::"text", 'staff'::"text"])))
);

ALTER TABLE ONLY "public"."messages" REPLICA IDENTITY FULL;


ALTER TABLE "public"."messages" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid",
    "type" "text",
    "payload" "jsonb",
    "read_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "title" "text" NOT NULL,
    "body" "text",
    CONSTRAINT "notifications_type_check" CHECK (("type" = ANY (ARRAY['app_status'::"text", 'doc_rejected'::"text", 'doc_approved'::"text", 'message_received'::"text", 'deadline'::"text"])))
);

ALTER TABLE ONLY "public"."notifications" REPLICA IDENTITY FULL;


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."platform_settings" (
    "key" "text" NOT NULL,
    "value" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."platform_settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."program_contacts" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "program_id" "uuid",
    "email" "text" NOT NULL,
    "name" "text",
    "cc_emails" "text"[],
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."program_contacts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."program_favorites" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "student_profile_id" "uuid" NOT NULL,
    "program_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."program_favorites" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."program_requirements" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "program_id" "uuid",
    "document_type" "text",
    "required" boolean DEFAULT true,
    "constraints" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "program_requirements_document_type_check" CHECK (("document_type" = ANY (ARRAY['cv'::"text", 'transcript'::"text", 'recommendation'::"text", 'passport'::"text", 'other'::"text"])))
);


ALTER TABLE "public"."program_requirements" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."programs" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "university_name" "text" NOT NULL,
    "program_name" "text" NOT NULL,
    "country" "text",
    "language" "text",
    "level" "text",
    "duration" "text",
    "cost" numeric,
    "deadline" "date",
    "description" "text",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "domain" "text",
    "requirements" "text"[],
    "contact_email" "text",
    CONSTRAINT "programs_level_check" CHECK (("level" = ANY (ARRAY['bachelor'::"text", 'master'::"text", 'phd'::"text", 'other'::"text"])))
);


ALTER TABLE "public"."programs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."referrals" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "ambassador_user_id" "uuid",
    "student_user_id" "uuid",
    "status" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "referrals_status_check" CHECK (("status" = ANY (ARRAY['clicked'::"text", 'registered'::"text", 'converted'::"text"])))
);


ALTER TABLE "public"."referrals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."roles" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    CONSTRAINT "roles_name_check" CHECK (("name" = ANY (ARRAY['admin'::"text", 'admissions'::"text", 'support'::"text", 'manager'::"text", 'student'::"text", 'ambassador'::"text"])))
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."student_notes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "student_id" "uuid" NOT NULL,
    "author_id" "uuid",
    "author_email" "text",
    "content" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."student_notes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."student_profiles" (
    "id" "uuid" NOT NULL,
    "first_name" "text",
    "last_name" "text",
    "birth_date" "date",
    "nationality" "text",
    "country_residence" "text",
    "phone" "text",
    "address" "text",
    "photo_url" "text",
    "completeness_score" integer DEFAULT 0,
    "motivation_letter" "text",
    "academic_goals" "text",
    "career_goals" "text",
    "ai_completeness_score" integer,
    "ai_summary" "text",
    "ai_score_generated_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "student_profiles_completeness_score_check" CHECK ((("completeness_score" >= 0) AND ("completeness_score" <= 100)))
);


ALTER TABLE "public"."student_profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tasks" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "application_id" "uuid",
    "assigned_to" "uuid",
    "created_by" "uuid",
    "type" "text",
    "title" "text" NOT NULL,
    "description" "text",
    "status" "text" DEFAULT 'open'::"text",
    "due_date" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "priority" "text" DEFAULT 'normal'::"text",
    "assignee_label" "text",
    "reminder_hours" integer,
    "task_type" "text" DEFAULT 'manual'::"text" NOT NULL,
    "completed_at" timestamp with time zone,
    "creator_role" "text",
    "reminder_sent_at" timestamp with time zone,
    CONSTRAINT "tasks_creator_role_check" CHECK (("creator_role" = ANY (ARRAY['admin'::"text", 'manager'::"text", 'admissions'::"text", 'support'::"text"]))),
    CONSTRAINT "tasks_priority_check" CHECK (("priority" = ANY (ARRAY['normal'::"text", 'urgent'::"text", 'faible'::"text"]))),
    CONSTRAINT "tasks_status_check" CHECK (("status" = ANY (ARRAY['open'::"text", 'in_progress'::"text", 'done'::"text", 'canceled'::"text"]))),
    CONSTRAINT "tasks_task_type_check" CHECK (("task_type" = ANY (ARRAY['manual'::"text", 'reminder_j7'::"text", 'reminder_j14'::"text"]))),
    CONSTRAINT "tasks_type_check" CHECK (("type" = ANY (ARRAY['follow_up'::"text", 'doc_request'::"text", 'internal_review'::"text", 'deadline_reminder'::"text"])))
);


ALTER TABLE "public"."tasks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_roles" (
    "user_id" "uuid" NOT NULL,
    "role_id" "uuid" NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL
);


ALTER TABLE "public"."user_roles" OWNER TO "postgres";


ALTER TABLE ONLY "public"."academic_backgrounds"
    ADD CONSTRAINT "academic_backgrounds_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."application_documents"
    ADD CONSTRAINT "application_documents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."application_fields"
    ADD CONSTRAINT "application_fields_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."application_packs"
    ADD CONSTRAINT "application_packs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."application_status_history"
    ADD CONSTRAINT "application_status_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."applications"
    ADD CONSTRAINT "applications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."commissions"
    ADD CONSTRAINT "commissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."device_tokens"
    ADD CONSTRAINT "device_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."device_tokens"
    ADD CONSTRAINT "device_tokens_token_key" UNIQUE ("token");



ALTER TABLE ONLY "public"."documents"
    ADD CONSTRAINT "documents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."educations"
    ADD CONSTRAINT "educations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."email_logs"
    ADD CONSTRAINT "email_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."email_templates"
    ADD CONSTRAINT "email_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."error_logs"
    ADD CONSTRAINT "error_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."experiences"
    ADD CONSTRAINT "experiences_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_student_profile_id_program_id_key" UNIQUE ("student_profile_id", "program_id");



ALTER TABLE ONLY "public"."fcm_tokens"
    ADD CONSTRAINT "fcm_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."fcm_tokens"
    ADD CONSTRAINT "fcm_tokens_user_id_token_key" UNIQUE ("user_id", "token");



ALTER TABLE ONLY "public"."message_templates"
    ADD CONSTRAINT "message_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."platform_settings"
    ADD CONSTRAINT "platform_settings_pkey" PRIMARY KEY ("key");



ALTER TABLE ONLY "public"."program_contacts"
    ADD CONSTRAINT "program_contacts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."program_favorites"
    ADD CONSTRAINT "program_favorites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."program_favorites"
    ADD CONSTRAINT "program_favorites_student_profile_id_program_id_key" UNIQUE ("student_profile_id", "program_id");



ALTER TABLE ONLY "public"."program_requirements"
    ADD CONSTRAINT "program_requirements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."programs"
    ADD CONSTRAINT "programs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."referrals"
    ADD CONSTRAINT "referrals_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."student_notes"
    ADD CONSTRAINT "student_notes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."student_profiles"
    ADD CONSTRAINT "student_profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_pkey" PRIMARY KEY ("user_id", "role_id");



CREATE INDEX "idx_error_logs_created_at" ON "public"."error_logs" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_error_logs_type" ON "public"."error_logs" USING "btree" ("type");



CREATE INDEX "idx_fcm_tokens_user" ON "public"."fcm_tokens" USING "btree" ("user_id");



CREATE INDEX "idx_student_notes_student" ON "public"."student_notes" USING "btree" ("student_id");



CREATE UNIQUE INDEX "uq_applications_active" ON "public"."applications" USING "btree" ("student_profile_id", "program_id") WHERE ("status" <> ALL (ARRAY['archived'::"text", 'rejected'::"text"]));



CREATE UNIQUE INDEX "uq_conversations_student" ON "public"."conversations" USING "btree" ("student_profile_id");



CREATE OR REPLACE TRIGGER "trg_application_notification" AFTER UPDATE ON "public"."applications" FOR EACH ROW EXECUTE FUNCTION "public"."notify_application_status"();



CREATE OR REPLACE TRIGGER "trg_application_status_history" AFTER UPDATE ON "public"."applications" FOR EACH ROW EXECUTE FUNCTION "public"."fn_log_application_status_change"();



CREATE OR REPLACE TRIGGER "trg_applications_updated" BEFORE UPDATE ON "public"."applications" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "trg_audit_application_status" AFTER UPDATE ON "public"."applications" FOR EACH ROW EXECUTE FUNCTION "public"."log_application_status"();



CREATE OR REPLACE TRIGGER "trg_audit_document_status" AFTER UPDATE ON "public"."documents" FOR EACH ROW EXECUTE FUNCTION "public"."log_document_status"();



CREATE OR REPLACE TRIGGER "trg_audit_program" AFTER INSERT OR UPDATE ON "public"."programs" FOR EACH ROW EXECUTE FUNCTION "public"."log_program_change"();



CREATE OR REPLACE TRIGGER "trg_document_approval_notification" AFTER UPDATE ON "public"."documents" FOR EACH ROW EXECUTE FUNCTION "public"."notify_document_approval"();



CREATE OR REPLACE TRIGGER "trg_document_rejection_notification" AFTER UPDATE ON "public"."documents" FOR EACH ROW EXECUTE FUNCTION "public"."notify_document_rejection"();



CREATE OR REPLACE TRIGGER "trg_documents_updated" BEFORE UPDATE ON "public"."documents" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



CREATE OR REPLACE TRIGGER "trg_message_insert" AFTER INSERT ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."update_conversation_on_message"();



CREATE OR REPLACE TRIGGER "trg_message_received_notification" AFTER INSERT ON "public"."messages" FOR EACH ROW EXECUTE FUNCTION "public"."notify_message_received"();



CREATE OR REPLACE TRIGGER "trg_student_profiles_updated" BEFORE UPDATE ON "public"."student_profiles" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at"();



ALTER TABLE ONLY "public"."academic_backgrounds"
    ADD CONSTRAINT "academic_backgrounds_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."student_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."application_documents"
    ADD CONSTRAINT "application_documents_application_id_fkey" FOREIGN KEY ("application_id") REFERENCES "public"."applications"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."application_documents"
    ADD CONSTRAINT "application_documents_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "public"."documents"("id");



ALTER TABLE ONLY "public"."application_fields"
    ADD CONSTRAINT "application_fields_application_id_fkey" FOREIGN KEY ("application_id") REFERENCES "public"."applications"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."application_packs"
    ADD CONSTRAINT "application_packs_application_id_fkey" FOREIGN KEY ("application_id") REFERENCES "public"."applications"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."application_packs"
    ADD CONSTRAINT "application_packs_generated_by_fkey" FOREIGN KEY ("generated_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."application_status_history"
    ADD CONSTRAINT "application_status_history_application_id_fkey" FOREIGN KEY ("application_id") REFERENCES "public"."applications"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."application_status_history"
    ADD CONSTRAINT "application_status_history_changed_by_fkey" FOREIGN KEY ("changed_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."applications"
    ADD CONSTRAINT "applications_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."applications"
    ADD CONSTRAINT "applications_program_id_fkey" FOREIGN KEY ("program_id") REFERENCES "public"."programs"("id");



ALTER TABLE ONLY "public"."applications"
    ADD CONSTRAINT "applications_student_profile_id_fkey" FOREIGN KEY ("student_profile_id") REFERENCES "public"."student_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."commissions"
    ADD CONSTRAINT "commissions_ambassador_user_id_fkey" FOREIGN KEY ("ambassador_user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_application_id_fkey" FOREIGN KEY ("application_id") REFERENCES "public"."applications"("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_student_profile_id_fkey" FOREIGN KEY ("student_profile_id") REFERENCES "public"."student_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."device_tokens"
    ADD CONSTRAINT "device_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."documents"
    ADD CONSTRAINT "documents_reviewed_by_fkey" FOREIGN KEY ("reviewed_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."documents"
    ADD CONSTRAINT "documents_student_profile_id_fkey" FOREIGN KEY ("student_profile_id") REFERENCES "public"."student_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."educations"
    ADD CONSTRAINT "educations_student_profile_id_fkey" FOREIGN KEY ("student_profile_id") REFERENCES "public"."student_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."email_logs"
    ADD CONSTRAINT "email_logs_application_id_fkey" FOREIGN KEY ("application_id") REFERENCES "public"."applications"("id");



ALTER TABLE ONLY "public"."email_logs"
    ADD CONSTRAINT "email_logs_sent_by_fkey" FOREIGN KEY ("sent_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."email_templates"
    ADD CONSTRAINT "email_templates_program_id_fkey" FOREIGN KEY ("program_id") REFERENCES "public"."programs"("id");



ALTER TABLE ONLY "public"."experiences"
    ADD CONSTRAINT "experiences_student_profile_id_fkey" FOREIGN KEY ("student_profile_id") REFERENCES "public"."student_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_program_id_fkey" FOREIGN KEY ("program_id") REFERENCES "public"."programs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."favorites"
    ADD CONSTRAINT "favorites_student_profile_id_fkey" FOREIGN KEY ("student_profile_id") REFERENCES "public"."student_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."fcm_tokens"
    ADD CONSTRAINT "fcm_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."program_contacts"
    ADD CONSTRAINT "program_contacts_program_id_fkey" FOREIGN KEY ("program_id") REFERENCES "public"."programs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."program_favorites"
    ADD CONSTRAINT "program_favorites_program_id_fkey" FOREIGN KEY ("program_id") REFERENCES "public"."programs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."program_favorites"
    ADD CONSTRAINT "program_favorites_student_profile_id_fkey" FOREIGN KEY ("student_profile_id") REFERENCES "public"."student_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."program_requirements"
    ADD CONSTRAINT "program_requirements_program_id_fkey" FOREIGN KEY ("program_id") REFERENCES "public"."programs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."referrals"
    ADD CONSTRAINT "referrals_ambassador_user_id_fkey" FOREIGN KEY ("ambassador_user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."referrals"
    ADD CONSTRAINT "referrals_student_user_id_fkey" FOREIGN KEY ("student_user_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."student_notes"
    ADD CONSTRAINT "student_notes_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."student_notes"
    ADD CONSTRAINT "student_notes_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "public"."student_profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."student_profiles"
    ADD CONSTRAINT "student_profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_application_id_fkey" FOREIGN KEY ("application_id") REFERENCES "public"."applications"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."tasks"
    ADD CONSTRAINT "tasks_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_roles"
    ADD CONSTRAINT "user_roles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Admin peut modifier user_roles" ON "public"."user_roles" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM ("public"."user_roles" "ur"
     JOIN "public"."roles" "r" ON (("r"."id" = "ur"."role_id")))
  WHERE (("ur"."user_id" = "auth"."uid"()) AND ("r"."name" = 'admin'::"text"))))) WITH CHECK (true);



CREATE POLICY "Team can read all student profiles" ON "public"."student_profiles" FOR SELECT TO "authenticated" USING ((("auth"."uid"() = "id") OR (EXISTS ( SELECT 1
   FROM ("public"."user_roles" "ur"
     JOIN "public"."roles" "r" ON (("r"."id" = "ur"."role_id")))
  WHERE (("ur"."user_id" = "auth"."uid"()) AND ("r"."name" = ANY (ARRAY['admin'::"text", 'admissions'::"text", 'manager'::"text", 'support'::"text"])) AND ("ur"."status" = 'active'::"text"))))));



ALTER TABLE "public"."academic_backgrounds" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."application_documents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."application_fields" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."application_packs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."application_status_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."applications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."audit_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "authenticated can read active programs" ON "public"."programs" FOR SELECT TO "authenticated" USING ((("is_active" = true) OR (EXISTS ( SELECT 1
   FROM ("public"."user_roles" "ur"
     JOIN "public"."roles" "r" ON (("r"."id" = "ur"."role_id")))
  WHERE (("ur"."user_id" = "auth"."uid"()) AND ("r"."name" = ANY (ARRAY['admin'::"text", 'admissions'::"text", 'manager'::"text"])) AND ("ur"."status" = 'active'::"text"))))));



ALTER TABLE "public"."commissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."conversations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."device_tokens" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."documents" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."educations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."email_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."email_templates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."error_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."experiences" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."favorites" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."fcm_tokens" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."message_templates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "own_applications" ON "public"."applications" USING (("auth"."uid"() = "student_profile_id"));



CREATE POLICY "own_device_tokens" ON "public"."device_tokens" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_documents" ON "public"."documents" USING (("auth"."uid"() = "student_profile_id"));



CREATE POLICY "own_favorites" ON "public"."program_favorites" TO "authenticated" USING (("auth"."uid"() = "student_profile_id")) WITH CHECK (("auth"."uid"() = "student_profile_id"));



CREATE POLICY "own_notifications" ON "public"."notifications" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "own_profile" ON "public"."student_profiles" USING (("auth"."uid"() = "id"));



ALTER TABLE "public"."platform_settings" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."program_contacts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."program_favorites" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."program_requirements" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."programs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."referrals" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."roles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "roles_read_all" ON "public"."roles" FOR SELECT USING (true);



CREATE POLICY "service_all_error_logs" ON "public"."error_logs" USING (true);



CREATE POLICY "service_insert_tasks" ON "public"."tasks" FOR INSERT WITH CHECK (true);



CREATE POLICY "service_read_tokens" ON "public"."fcm_tokens" FOR SELECT USING (true);



CREATE POLICY "staff_all_application_documents" ON "public"."application_documents" USING (((("auth"."jwt"() -> 'user_metadata'::"text") ->> 'role'::"text") = ANY (ARRAY['admin'::"text", 'staff'::"text"])));



CREATE POLICY "staff_all_conversations" ON "public"."conversations" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."user_roles" "ur"
     JOIN "public"."roles" "r" ON (("r"."id" = "ur"."role_id")))
  WHERE (("ur"."user_id" = "auth"."uid"()) AND ("r"."name" = ANY (ARRAY['admin'::"text", 'manager'::"text", 'admissions'::"text", 'support'::"text", 'ambassador'::"text"]))))));



CREATE POLICY "staff_all_messages" ON "public"."messages" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."user_roles" "ur"
     JOIN "public"."roles" "r" ON (("r"."id" = "ur"."role_id")))
  WHERE (("ur"."user_id" = "auth"."uid"()) AND ("r"."name" = ANY (ARRAY['admin'::"text", 'manager'::"text", 'admissions'::"text", 'support'::"text", 'ambassador'::"text"]))))));



CREATE POLICY "student_delete_own_application_documents" ON "public"."application_documents" FOR DELETE USING (("auth"."uid"() = ( SELECT "applications"."student_profile_id"
   FROM "public"."applications"
  WHERE ("applications"."id" = "application_documents"."application_id"))));



CREATE POLICY "student_insert_own_application_documents" ON "public"."application_documents" FOR INSERT WITH CHECK (("auth"."uid"() = ( SELECT "applications"."student_profile_id"
   FROM "public"."applications"
  WHERE ("applications"."id" = "application_documents"."application_id"))));



ALTER TABLE "public"."student_notes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "student_own_conversation" ON "public"."conversations" TO "authenticated" USING (("student_profile_id" = "auth"."uid"()));



CREATE POLICY "student_own_messages" ON "public"."messages" TO "authenticated" USING (("conversation_id" IN ( SELECT "conversations"."id"
   FROM "public"."conversations"
  WHERE ("conversations"."student_profile_id" = "auth"."uid"()))));



ALTER TABLE "public"."student_profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "student_read_own_application_documents" ON "public"."application_documents" FOR SELECT USING (("auth"."uid"() = ( SELECT "applications"."student_profile_id"
   FROM "public"."applications"
  WHERE ("applications"."id" = "application_documents"."application_id"))));



CREATE POLICY "student_read_own_history" ON "public"."application_status_history" FOR SELECT USING (("application_id" IN ( SELECT "applications"."id"
   FROM "public"."applications"
  WHERE ("applications"."student_profile_id" = "auth"."uid"()))));



ALTER TABLE "public"."tasks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "team can manage programs" ON "public"."programs" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."user_roles" "ur"
     JOIN "public"."roles" "r" ON (("r"."id" = "ur"."role_id")))
  WHERE (("ur"."user_id" = "auth"."uid"()) AND ("r"."name" = ANY (ARRAY['admin'::"text", 'manager'::"text", 'admissions'::"text"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."user_roles" "ur"
     JOIN "public"."roles" "r" ON (("r"."id" = "ur"."role_id")))
  WHERE (("ur"."user_id" = "auth"."uid"()) AND ("r"."name" = ANY (ARRAY['admin'::"text", 'manager'::"text", 'admissions'::"text"]))))));



CREATE POLICY "team can read all documents" ON "public"."documents" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."user_roles" "ur"
     JOIN "public"."roles" "r" ON (("r"."id" = "ur"."role_id")))
  WHERE (("ur"."user_id" = "auth"."uid"()) AND ("r"."name" = ANY (ARRAY['admin'::"text", 'admissions'::"text", 'manager'::"text", 'support'::"text"])) AND ("ur"."status" = 'active'::"text")))));



CREATE POLICY "team can update document status" ON "public"."documents" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."user_roles" "ur"
     JOIN "public"."roles" "r" ON (("r"."id" = "ur"."role_id")))
  WHERE (("ur"."user_id" = "auth"."uid"()) AND ("r"."name" = ANY (ARRAY['admin'::"text", 'admissions'::"text", 'manager'::"text"])) AND ("ur"."status" = 'active'::"text")))));



CREATE POLICY "team_all_platform_settings" ON "public"."platform_settings" USING (true) WITH CHECK (true);



CREATE POLICY "team_delete_email_templates" ON "public"."email_templates" FOR DELETE USING (true);



CREATE POLICY "team_insert_email_templates" ON "public"."email_templates" FOR INSERT WITH CHECK (true);



CREATE POLICY "team_manage_notes" ON "public"."student_notes" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."user_roles" "ur"
     JOIN "public"."roles" "r" ON (("ur"."role_id" = "r"."id")))
  WHERE (("ur"."user_id" = "auth"."uid"()) AND ("r"."name" = ANY (ARRAY['admin'::"text", 'admissions'::"text", 'manager'::"text", 'support'::"text"]))))));



CREATE POLICY "team_read_all_history" ON "public"."application_status_history" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM ("public"."user_roles" "ur"
     JOIN "public"."roles" "r" ON (("r"."id" = "ur"."role_id")))
  WHERE (("ur"."user_id" = "auth"."uid"()) AND ("r"."name" = ANY (ARRAY['admin'::"text", 'admissions'::"text", 'support'::"text", 'manager'::"text"]))))));



CREATE POLICY "team_read_audit" ON "public"."audit_logs" FOR SELECT USING ("public"."is_team_member"());



CREATE POLICY "team_select_all_applications" ON "public"."applications" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."user_roles" "ur"
     JOIN "public"."roles" "r" ON (("r"."id" = "ur"."role_id")))
  WHERE (("ur"."user_id" = "auth"."uid"()) AND ("r"."name" = ANY (ARRAY['admin'::"text", 'admissions'::"text", 'support'::"text", 'manager'::"text"]))))));



CREATE POLICY "team_select_email_templates" ON "public"."email_templates" FOR SELECT USING (true);



CREATE POLICY "team_tasks_all" ON "public"."tasks" TO "authenticated" USING ("public"."is_team_member"()) WITH CHECK ("public"."is_team_member"());



CREATE POLICY "team_templates_all" ON "public"."message_templates" USING ("public"."is_team_member"());



CREATE POLICY "team_update_applications" ON "public"."applications" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."user_roles" "ur"
     JOIN "public"."roles" "r" ON (("r"."id" = "ur"."role_id")))
  WHERE (("ur"."user_id" = "auth"."uid"()) AND ("r"."name" = ANY (ARRAY['admin'::"text", 'admissions'::"text", 'support'::"text", 'manager'::"text"]))))));



CREATE POLICY "team_update_email_templates" ON "public"."email_templates" FOR UPDATE USING (true);



CREATE POLICY "user can manage own academic" ON "public"."academic_backgrounds" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "user can manage own experiences" ON "public"."experiences" USING (("auth"."uid"() = "student_profile_id"));



CREATE POLICY "user_own_tokens" ON "public"."fcm_tokens" TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."user_roles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "users_read_own_role" ON "public"."user_roles" FOR SELECT USING (("auth"."uid"() = "user_id"));



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."assign_default_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."assign_default_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."assign_default_role"() TO "service_role";



GRANT ALL ON FUNCTION "public"."create_team_member"("member_email" "text", "member_password" "text", "member_role" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."create_team_member"("member_email" "text", "member_password" "text", "member_role" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_team_member"("member_email" "text", "member_password" "text", "member_role" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."fn_log_application_status_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."fn_log_application_status_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."fn_log_application_status_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_team_members"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_team_members"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_team_members"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_team_member"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_team_member"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_team_member"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_application_status"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_application_status"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_application_status"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_document_status"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_document_status"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_document_status"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_program_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_program_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_program_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_application_status"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_application_status"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_application_status"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_document_approval"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_document_approval"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_document_approval"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_document_rejection"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_document_rejection"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_document_rejection"() TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_message_received"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_message_received"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_message_received"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_conversation_on_message"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_conversation_on_message"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_conversation_on_message"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_member_status"("target_user_id" "uuid", "new_status" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_member_status"("target_user_id" "uuid", "new_status" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_member_status"("target_user_id" "uuid", "new_status" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at"() TO "service_role";



GRANT ALL ON TABLE "public"."academic_backgrounds" TO "anon";
GRANT ALL ON TABLE "public"."academic_backgrounds" TO "authenticated";
GRANT ALL ON TABLE "public"."academic_backgrounds" TO "service_role";



GRANT ALL ON TABLE "public"."application_documents" TO "anon";
GRANT ALL ON TABLE "public"."application_documents" TO "authenticated";
GRANT ALL ON TABLE "public"."application_documents" TO "service_role";



GRANT ALL ON TABLE "public"."application_fields" TO "anon";
GRANT ALL ON TABLE "public"."application_fields" TO "authenticated";
GRANT ALL ON TABLE "public"."application_fields" TO "service_role";



GRANT ALL ON TABLE "public"."application_packs" TO "anon";
GRANT ALL ON TABLE "public"."application_packs" TO "authenticated";
GRANT ALL ON TABLE "public"."application_packs" TO "service_role";



GRANT ALL ON TABLE "public"."application_status_history" TO "anon";
GRANT ALL ON TABLE "public"."application_status_history" TO "authenticated";
GRANT ALL ON TABLE "public"."application_status_history" TO "service_role";



GRANT ALL ON TABLE "public"."applications" TO "anon";
GRANT ALL ON TABLE "public"."applications" TO "authenticated";
GRANT ALL ON TABLE "public"."applications" TO "service_role";



GRANT ALL ON TABLE "public"."audit_logs" TO "anon";
GRANT ALL ON TABLE "public"."audit_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_logs" TO "service_role";



GRANT ALL ON TABLE "public"."commissions" TO "anon";
GRANT ALL ON TABLE "public"."commissions" TO "authenticated";
GRANT ALL ON TABLE "public"."commissions" TO "service_role";



GRANT ALL ON TABLE "public"."conversations" TO "anon";
GRANT ALL ON TABLE "public"."conversations" TO "authenticated";
GRANT ALL ON TABLE "public"."conversations" TO "service_role";



GRANT ALL ON TABLE "public"."device_tokens" TO "anon";
GRANT ALL ON TABLE "public"."device_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."device_tokens" TO "service_role";



GRANT ALL ON TABLE "public"."documents" TO "anon";
GRANT ALL ON TABLE "public"."documents" TO "authenticated";
GRANT ALL ON TABLE "public"."documents" TO "service_role";



GRANT ALL ON TABLE "public"."educations" TO "anon";
GRANT ALL ON TABLE "public"."educations" TO "authenticated";
GRANT ALL ON TABLE "public"."educations" TO "service_role";



GRANT ALL ON TABLE "public"."email_logs" TO "anon";
GRANT ALL ON TABLE "public"."email_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."email_logs" TO "service_role";



GRANT ALL ON TABLE "public"."email_templates" TO "anon";
GRANT ALL ON TABLE "public"."email_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."email_templates" TO "service_role";



GRANT ALL ON TABLE "public"."error_logs" TO "anon";
GRANT ALL ON TABLE "public"."error_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."error_logs" TO "service_role";



GRANT ALL ON TABLE "public"."experiences" TO "anon";
GRANT ALL ON TABLE "public"."experiences" TO "authenticated";
GRANT ALL ON TABLE "public"."experiences" TO "service_role";



GRANT ALL ON TABLE "public"."favorites" TO "anon";
GRANT ALL ON TABLE "public"."favorites" TO "authenticated";
GRANT ALL ON TABLE "public"."favorites" TO "service_role";



GRANT ALL ON TABLE "public"."fcm_tokens" TO "anon";
GRANT ALL ON TABLE "public"."fcm_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."fcm_tokens" TO "service_role";



GRANT ALL ON TABLE "public"."message_templates" TO "anon";
GRANT ALL ON TABLE "public"."message_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."message_templates" TO "service_role";



GRANT ALL ON TABLE "public"."messages" TO "anon";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";
GRANT ALL ON TABLE "public"."messages" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."platform_settings" TO "anon";
GRANT ALL ON TABLE "public"."platform_settings" TO "authenticated";
GRANT ALL ON TABLE "public"."platform_settings" TO "service_role";



GRANT ALL ON TABLE "public"."program_contacts" TO "anon";
GRANT ALL ON TABLE "public"."program_contacts" TO "authenticated";
GRANT ALL ON TABLE "public"."program_contacts" TO "service_role";



GRANT ALL ON TABLE "public"."program_favorites" TO "anon";
GRANT ALL ON TABLE "public"."program_favorites" TO "authenticated";
GRANT ALL ON TABLE "public"."program_favorites" TO "service_role";



GRANT ALL ON TABLE "public"."program_requirements" TO "anon";
GRANT ALL ON TABLE "public"."program_requirements" TO "authenticated";
GRANT ALL ON TABLE "public"."program_requirements" TO "service_role";



GRANT ALL ON TABLE "public"."programs" TO "anon";
GRANT ALL ON TABLE "public"."programs" TO "authenticated";
GRANT ALL ON TABLE "public"."programs" TO "service_role";



GRANT ALL ON TABLE "public"."referrals" TO "anon";
GRANT ALL ON TABLE "public"."referrals" TO "authenticated";
GRANT ALL ON TABLE "public"."referrals" TO "service_role";



GRANT ALL ON TABLE "public"."roles" TO "anon";
GRANT ALL ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";



GRANT ALL ON TABLE "public"."student_notes" TO "anon";
GRANT ALL ON TABLE "public"."student_notes" TO "authenticated";
GRANT ALL ON TABLE "public"."student_notes" TO "service_role";



GRANT ALL ON TABLE "public"."student_profiles" TO "anon";
GRANT ALL ON TABLE "public"."student_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."student_profiles" TO "service_role";



GRANT ALL ON TABLE "public"."tasks" TO "anon";
GRANT ALL ON TABLE "public"."tasks" TO "authenticated";
GRANT ALL ON TABLE "public"."tasks" TO "service_role";



GRANT ALL ON TABLE "public"."user_roles" TO "anon";
GRANT ALL ON TABLE "public"."user_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."user_roles" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







