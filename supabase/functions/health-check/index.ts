// @ts-nocheck  Deno Edge Function
// Endpoint de monitoring : vérifie la DB, le storage et les fonctions clés
// GET /functions/v1/health-check  { status, checks, timestamp }

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

async function checkDb(supabase: any): Promise<{ ok: boolean; latencyMs: number; error?: string }> {
  const t0 = Date.now()
  try {
    const { error } = await supabase.from('programs').select('id').limit(1)
    return { ok: !error, latencyMs: Date.now() - t0, error: error?.message }
  } catch (e) {
    return { ok: false, latencyMs: Date.now() - t0, error: String(e) }
  }
}

async function checkStorage(supabase: any): Promise<{ ok: boolean; error?: string }> {
  try {
    const { error } = await supabase.storage.listBuckets()
    return { ok: !error, error: error?.message }
  } catch (e) {
    return { ok: false, error: String(e) }
  }
}

async function checkCriticalCounts(supabase: any): Promise<Record<string, number>> {
  const tables = ['programs', 'student_profiles', 'applications', 'documents']
  const counts: Record<string, number> = {}
  for (const t of tables) {
    try {
      const { count } = await supabase.from(t).select('*', { count: 'exact', head: true })
      counts[t] = count ?? 0
    } catch (_) {
      counts[t] = -1
    }
  }
  return counts
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  const supabase = createClient(SUPABASE_URL, SUPABASE_KEY)
  const started  = Date.now()

  const [db, storage, counts] = await Promise.all([
    checkDb(supabase),
    checkStorage(supabase),
    checkCriticalCounts(supabase),
  ])

  const allOk  = db.ok && storage.ok
  const status = allOk ? 'healthy' : 'degraded'

  const body = {
    status,
    timestamp: new Date().toISOString(),
    responseMs: Date.now() - started,
    checks: {
      database: { ok: db.ok, latencyMs: db.latencyMs, ...(db.error ? { error: db.error } : {}) },
      storage:  { ok: storage.ok, ...(storage.error ? { error: storage.error } : {}) },
    },
    counts,
    version: '1.0.0',
  }

  return new Response(JSON.stringify(body, null, 2), {
    status: allOk ? 200 : 503,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
})
