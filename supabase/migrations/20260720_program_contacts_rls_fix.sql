-- RLS activée sans aucune policy : program_contacts était totalement
-- inaccessible hors service_role. Le dashboard tente de pré-remplir le
-- destinataire de "Envoyer à l'université" depuis cette table (embed
-- program_contacts!left(email) dans applications_service.ts) — bloqué
-- silencieusement depuis toujours. Ajout de policies staff, cohérentes
-- avec le reste de la gestion programmes (cf. policies sur "programs").

CREATE POLICY "team_manage_program_contacts" ON public.program_contacts
  FOR ALL
  USING (public.is_team_member())
  WITH CHECK (public.is_team_member());
