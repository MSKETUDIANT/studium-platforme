-- Active Supabase Realtime sur la table programs : necessaire pour que
-- le catalogue mobile se mette a jour automatiquement (invalidation du
-- cache local) des qu'un programme est ajoute/modifie/supprime cote
-- tableau de bord, sans attendre le TTL de 6h du cache ni geste manuel.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'programs'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.programs;
  END IF;
END $$;
