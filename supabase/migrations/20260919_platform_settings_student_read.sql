-- L'app mobile doit pouvoir lire les limites d'upload configurees par
-- l'equipe (upload_max_size_mb, upload_allowed_formats) pour les
-- synchroniser cote client, mais la policy actuelle (team_all_platform_settings,
-- cf. 20260720_platform_settings_rls_fix.sql) restreint tout acces -- y
-- compris la LECTURE -- au staff (is_team_member()), car a l'epoque cette
-- table n'etait utilisee que par le dashboard.
--
-- Ajout d'une policy de LECTURE SEULE pour les etudiants (et tout
-- utilisateur authentifie), sans toucher a la policy d'ECRITURE qui reste
-- reservee au staff. Aucune valeur de cette table n'est sensible
-- (limites d'upload, email support, nom plateforme, langue, commission
-- ambassadeur) : les exposer en lecture ne pose pas de risque.

DROP POLICY IF EXISTS "authenticated_read_platform_settings" ON public.platform_settings;
CREATE POLICY "authenticated_read_platform_settings" ON public.platform_settings
  FOR SELECT TO authenticated
  USING (true);
