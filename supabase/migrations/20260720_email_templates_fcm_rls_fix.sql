-- Audit RLS complet (suite) : deux failles du meme type que
-- platform_settings/error_logs deja corrigees.
--
-- email_templates : 4 policies nommees "team_..." mais scopees {public}
-- avec qual/with_check = true — n'importe qui (meme non connecte) peut
-- lire, creer, modifier ou supprimer les templates d'email envoyes aux
-- universites.
--
-- fcm_tokens : policy "service_read_tokens" (SELECT, {public}, true) —
-- expose les tokens push de tous les utilisateurs a tout le monde ;
-- fait doublon avec user_own_tokens qui gere deja l'acces legitime
-- (chacun ses propres tokens).

DROP POLICY IF EXISTS "team_select_email_templates" ON public.email_templates;
DROP POLICY IF EXISTS "team_insert_email_templates" ON public.email_templates;
DROP POLICY IF EXISTS "team_update_email_templates" ON public.email_templates;
DROP POLICY IF EXISTS "team_delete_email_templates" ON public.email_templates;

CREATE POLICY "team_all_email_templates" ON public.email_templates
  FOR ALL
  USING (public.is_team_member())
  WITH CHECK (public.is_team_member());

DROP POLICY IF EXISTS "service_read_tokens" ON public.fcm_tokens;

-- Oubliee lors du nettoyage precedent (20260720_drop_dead_tables.sql) :
-- toujours 0 ligne, toujours aucune reference dans le code.
DROP TABLE IF EXISTS public.program_requirements;
