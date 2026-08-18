-- La policy team_all_platform_settings s'appelait "team_..." mais utilisait
-- USING (true) : n'importe quel utilisateur connecté (etudiant, ambassadeur)
-- pouvait lire ET modifier les parametres globaux de la plateforme. Cette
-- table n'est utilisee que par le dashboard interne (SettingsPage), jamais
-- par l'app mobile — la restreindre a is_team_member() ne casse rien cote
-- etudiant.

DROP POLICY IF EXISTS "team_all_platform_settings" ON public.platform_settings;

CREATE POLICY "team_all_platform_settings" ON public.platform_settings
  FOR ALL
  USING (public.is_team_member())
  WITH CHECK (public.is_team_member());
