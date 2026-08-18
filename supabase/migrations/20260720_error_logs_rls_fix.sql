-- service_all_error_logs (USING true, ALL) laissait n'importe qui LIRE
-- les logs d'erreurs internes (stack traces, URLs, user-agent). L'écriture
-- doit rester ouverte : monitoring.ts (dashboard) insère avec la cle anon
-- brute, y compris avant connexion (ex: erreurs sur l'écran de login) —
-- restreindre l'INSERT casserait la capture d'erreurs pré-authentification.
-- Seule la lecture doit être réservée à l'équipe.

DROP POLICY IF EXISTS "service_all_error_logs" ON public.error_logs;

CREATE POLICY "anyone_insert_error_logs" ON public.error_logs
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "team_select_error_logs" ON public.error_logs
  FOR SELECT
  USING (public.is_team_member());
