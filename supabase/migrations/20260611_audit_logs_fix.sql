-- Fix 1 : RLS policy audit_logs
-- L'ancienne policy utilisait raw_user_meta_data->>'role' qui ne correspond pas
-- au modèle de rôles du projet (table user_roles + roles).

DROP POLICY IF EXISTS "admin_manager_read_audit" ON audit_logs;
DROP POLICY IF EXISTS "team_read_audit"           ON audit_logs;

CREATE POLICY "admin_manager_read_audit" ON audit_logs
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN roles r ON ur.role_id = r.id
      WHERE ur.user_id = auth.uid()
        AND r.name IN ('admin', 'manager')
    )
  );

-- Fix 2 : Triggers — capturer actor_id + actor_email
-- (les premières versions ne capturaient pas l'acteur)

CREATE OR REPLACE FUNCTION audit_application_status()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO audit_logs (
      actor_id, actor_email,
      action, entity_type, entity_id,
      old_value, new_value, metadata
    ) VALUES (
      auth.uid(),
      (auth.jwt() ->> 'email'),
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

CREATE OR REPLACE FUNCTION audit_document_status()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO audit_logs (
      actor_id, actor_email,
      action, entity_type, entity_id,
      old_value, new_value, metadata
    ) VALUES (
      auth.uid(),
      (auth.jwt() ->> 'email'),
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

CREATE OR REPLACE FUNCTION audit_program_changes()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audit_logs (
      actor_id, actor_email,
      action, entity_type, entity_id, metadata
    ) VALUES (
      auth.uid(), (auth.jwt() ->> 'email'),
      'program_create', 'program', NEW.id,
      jsonb_build_object('program_name', NEW.program_name)
    );
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_logs (
      actor_id, actor_email,
      action, entity_type, entity_id, metadata
    ) VALUES (
      auth.uid(), (auth.jwt() ->> 'email'),
      'program_update', 'program', NEW.id,
      jsonb_build_object('program_name', NEW.program_name)
    );
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO audit_logs (
      actor_id, actor_email,
      action, entity_type, entity_id, metadata
    ) VALUES (
      auth.uid(), (auth.jwt() ->> 'email'),
      'program_delete', 'program', OLD.id,
      jsonb_build_object('program_name', OLD.program_name)
    );
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;
