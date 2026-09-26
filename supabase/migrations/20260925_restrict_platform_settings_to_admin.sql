-- Ecart signale en revue de rapport PFE : l'ecran Parametres est reserve a
-- l'administrateur cote interface, mais la policy RLS d'ecriture
-- (team_all_platform_settings, is_team_member()) autorisait aussi
-- Admissions, Manager et Support a modifier les reglages globaux
-- (regles d'upload, seuil de la lettre de motivation, montant de
-- commission, informations generales) directement via l'API, en
-- contournant la restriction d'interface.
--
-- Resserree a is_admin() pour l'ecriture, coherente avec l'interface.
-- La lecture reste ouverte a tous les utilisateurs authentifies
-- (authenticated_read_platform_settings, deja en place) : ces reglages
-- sont necessaires au fonctionnement normal de l'app cote client.

DROP POLICY IF EXISTS "team_all_platform_settings" ON platform_settings;

DROP POLICY IF EXISTS "admin_write_platform_settings" ON platform_settings;
CREATE POLICY "admin_write_platform_settings" ON platform_settings
  FOR INSERT
  WITH CHECK (is_admin());

DROP POLICY IF EXISTS "admin_update_platform_settings" ON platform_settings;
CREATE POLICY "admin_update_platform_settings" ON platform_settings
  FOR UPDATE
  USING (is_admin())
  WITH CHECK (is_admin());

DROP POLICY IF EXISTS "admin_delete_platform_settings" ON platform_settings;
CREATE POLICY "admin_delete_platform_settings" ON platform_settings
  FOR DELETE
  USING (is_admin());
