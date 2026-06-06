// Monitoring léger sans dépendance externe
// Utilise window.onerror + fetch vers Supabase pour logger les erreurs critiques

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL as string | undefined
const SUPABASE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined
const IS_PROD      = import.meta.env.PROD

export function initMonitoring(): void {
  if (!IS_PROD) return

  //  Erreurs JS non catchées 
  window.onerror = (message, source, lineno, colno, error) => {
    logError({
      type:    'uncaught_error',
      message: String(message),
      source:  source ?? '',
      line:    lineno ?? 0,
      stack:   error?.stack?.substring(0, 500),
    })
    return false
  }

  //  Promesses rejetées non catchées 
  window.addEventListener('unhandledrejection', (e) => {
    logError({
      type:    'unhandled_rejection',
      message: String(e.reason),
      stack:   e.reason?.stack?.substring(0, 500),
    })
  })

  console.log('[Monitoring] Activé en production')
}

export function captureError(err: unknown, context?: Record<string, unknown>): void {
  if (!IS_PROD) {
    console.error('[Monitoring]', err, context)
    return
  }
  logError({
    type:    'captured_error',
    message: err instanceof Error ? err.message : String(err),
    stack:   err instanceof Error ? err.stack?.substring(0, 500) : undefined,
    context,
  })
}

async function logError(payload: Record<string, unknown>): Promise<void> {
  if (!SUPABASE_URL || !SUPABASE_KEY) return
  try {
    await fetch(`${SUPABASE_URL}/rest/v1/error_logs`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey':        SUPABASE_KEY,
        'Authorization': `Bearer ${SUPABASE_KEY}`,
        'Prefer':        'return=minimal',
      },
      body: JSON.stringify({
        ...payload,
        url:        window.location.href,
        user_agent: navigator.userAgent.substring(0, 200),
        created_at: new Date().toISOString(),
      }),
    })
  } catch (_) {
    // Silencieux  ne pas créer de boucle d'erreur
  }
}
