// @ts-nocheck  Deno Edge Function — purge des documents au-delà de la
// politique de rétention (CDC §7 : "24 mois puis purge").
// Déclenchée via cron Supabase : 0 3 * * *  (une fois par jour, 3h du matin)
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const RETENTION_MONTHS = 24;
const DOCS_BUCKET = 'documents';

const corsHeaders = () => ({
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
});

// Extrait le chemin de stockage relatif depuis une URL publique Supabase
// Storage (…/object/public/documents/<path>).
function storagePathFrom(fileUrl: string): string | null {
  const marker = `/object/public/${DOCS_BUCKET}/`;
  const idx = fileUrl.indexOf(marker);
  if (idx === -1) return null;
  return decodeURIComponent(fileUrl.slice(idx + marker.length));
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders() });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
  const cutoff = new Date();
  cutoff.setMonth(cutoff.getMonth() - RETENTION_MONTHS);

  const { data: expired, error: fetchError } = await supabase
    .from('documents')
    .select('id, student_profile_id, type, file_url, created_at')
    .lt('created_at', cutoff.toISOString());

  if (fetchError) {
    return new Response(JSON.stringify({ error: fetchError.message }), {
      status: 500, headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
    });
  }

  let purged = 0;
  const errors: string[] = [];

  for (const doc of expired ?? []) {
    try {
      const path = doc.file_url ? storagePathFrom(doc.file_url) : null;
      if (path) {
        const { error: storageErr } = await supabase.storage.from(DOCS_BUCKET).remove([path]);
        if (storageErr) errors.push(`storage ${doc.id}: ${storageErr.message}`);
      }
      const { error: deleteErr } = await supabase.from('documents').delete().eq('id', doc.id);
      if (deleteErr) {
        errors.push(`db ${doc.id}: ${deleteErr.message}`);
        continue;
      }
      purged++;
    } catch (e) {
      errors.push(`${doc.id}: ${String(e)}`);
    }
  }

  if (purged > 0 || errors.length > 0) {
    await supabase.from('audit_logs').insert({
      action:      'documents_purged',
      entity_type: 'documents',
      metadata:    { retention_months: RETENTION_MONTHS, purged, errors: errors.length, cutoff: cutoff.toISOString() },
    });
  }

  return new Response(
    JSON.stringify({ candidates: (expired ?? []).length, purged, errors }),
    { headers: { ...corsHeaders(), 'Content-Type': 'application/json' } },
  );
});
