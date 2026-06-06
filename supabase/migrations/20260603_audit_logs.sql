-- US-9.5 : Journal d'audit des actions internes (staff)

CREATE TABLE IF NOT EXISTS audit_logs (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  actor_id    UUID        REFERENCES auth.users(id),
  actor_email TEXT,
  action      TEXT        NOT NULL,
  -- Ex: 'status_update' | 'document_approve' | 'document_reject'
  --     'email_sent'    | 'program_create'   | 'program_update'
  entity_type TEXT        NOT NULL,  -- 'application' | 'document' | 'program'
  entity_id   UUID,
  old_value   TEXT,
  new_value   TEXT,
  metadata    JSONB       DEFAULT '{}',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at  ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity      ON audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor       ON audit_logs(actor_id);

-- RLS : lecture uniquement pour admin et manager
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_manager_read_audit" ON audit_logs
  FOR SELECT TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM auth.users
      WHERE raw_user_meta_data->>'role' IN ('admin', 'manager')
    )
  );

-- Insertion libre (service role depuis Edge Functions / triggers)
CREATE POLICY "service_insert_audit" ON audit_logs
  FOR INSERT WITH CHECK (true);

--  Trigger auto-log : changements de statut candidature 

CREATE OR REPLACE FUNCTION audit_application_status()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO audit_logs (action, entity_type, entity_id, old_value, new_value, metadata)
    VALUES (
      'status_update',
      'application',
      NEW.id,
      OLD.status,
      NEW.status,
      jsonb_build_object('student_profile_id', NEW.student_profile_id)
    );
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_audit_application_status
  AFTER UPDATE ON applications
  FOR EACH ROW EXECUTE FUNCTION audit_application_status();

--  Trigger auto-log : changements de statut document 

CREATE OR REPLACE FUNCTION audit_document_status()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO audit_logs (action, entity_type, entity_id, old_value, new_value, metadata)
    VALUES (
      CASE WHEN NEW.status = 'approved' THEN 'document_approve' ELSE 'document_reject' END,
      'document',
      NEW.id,
      OLD.status,
      NEW.status,
      jsonb_build_object(
        'document_type',    NEW.type,
        'rejection_reason', COALESCE(NEW.rejection_reason, '')
      )
    );
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_audit_document_status
  AFTER UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION audit_document_status();
