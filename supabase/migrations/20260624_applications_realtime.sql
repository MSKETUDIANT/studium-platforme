-- Activer Realtime sur applications pour mise à jour instantanée mobile
ALTER TABLE applications REPLICA IDENTITY FULL;

DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE applications;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END;
$$;