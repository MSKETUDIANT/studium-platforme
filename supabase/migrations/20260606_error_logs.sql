-- Table de logs d'erreurs pour le monitoring dashboard

CREATE TABLE IF NOT EXISTS error_logs (
  id         UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  type       TEXT        NOT NULL,
  message    TEXT,
  source     TEXT,
  line       INT,
  stack      TEXT,
  context    JSONB       DEFAULT '{}',
  url        TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_error_logs_created_at ON error_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_error_logs_type       ON error_logs(type);

-- Seul le service role peut lire (admin monitoring)
ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_all_error_logs" ON error_logs
  FOR ALL USING (true);

-- Nettoyage auto des logs > 30 jours (à planifier via pg_cron)
-- SELECT cron.schedule('cleanup-error-logs', '0 2 * * *',
--   'DELETE FROM error_logs WHERE created_at < NOW() - INTERVAL ''30 days''');
