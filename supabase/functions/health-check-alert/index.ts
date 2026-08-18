// @ts-nocheck  Deno Edge Function
// Déclenchée par pg_cron (voir migration 20260817_health_check_alert_cron.sql)
// toutes les 15 min : appelle health-check, et si le statut n'est pas
// "healthy", envoie une alerte email (avec cooldown anti-spam) à l'adresse
// support configurée dans platform_settings. health-check lui-même reste un
// simple endpoint passif — c'est ici que vit la logique d'alerte "active".

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!;
const SUPABASE_URL   = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_KEY   = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const FROM_EMAIL      = 'onboarding@resend.dev'; // même expéditeur que send-application-email
const FROM_NAME        = 'Studium Monitoring';
const COOLDOWN_MS      = 60 * 60 * 1000; // 1h entre deux alertes pendant une panne prolongée
const ALERT_COOLDOWN_KEY = 'last_health_alert_at';

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin':  '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders() });

  const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

  let health: any;
  try {
    const res = await fetch(`${SUPABASE_URL}/functions/v1/health-check`);
    health = await res.json();
  } catch (e) {
    health = { status: 'degraded', checks: { fetch: { ok: false, error: String(e) } } };
  }

  if (health.status === 'healthy') {
    return new Response(JSON.stringify({ ok: true, status: 'healthy', alerted: false }), {
      headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
    });
  }

  //  Cooldown anti-spam (stocké dans platform_settings, réutilisé tel quel)
  const { data: cooldownRow } = await supabase
    .from('platform_settings')
    .select('value')
    .eq('key', ALERT_COOLDOWN_KEY)
    .maybeSingle();

  const lastAlertAt = cooldownRow?.value ? new Date(cooldownRow.value).getTime() : 0;
  if (Date.now() - lastAlertAt < COOLDOWN_MS) {
    return new Response(JSON.stringify({ ok: true, status: health.status, alerted: false, reason: 'cooldown' }), {
      headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
    });
  }

  //  Destinataire (réglages plateforme, avec repli)
  const { data: emailRow } = await supabase
    .from('platform_settings')
    .select('value')
    .eq('key', 'support_email')
    .maybeSingle();
  const supportEmail = emailRow?.value || 'support@studium.app';

  const checksText = Object.entries(health.checks ?? {})
    .map(([name, c]: [string, any]) => `- ${name} : ${c.ok ? 'OK' : `ÉCHEC (${c.error ?? 'inconnu'})`}`)
    .join('\n');

  const subject = `[Studium] Alerte système — statut ${health.status}`;
  const text = `Le contrôle de santé de la plateforme Studium a détecté un problème.

Statut : ${health.status}
Horodatage : ${health.timestamp ?? new Date().toISOString()}

Vérifications :
${checksText}

Cette alerte ne sera pas renvoyée avant ${COOLDOWN_MS / 60000} minutes même si le problème persiste.`;

  let emailError: string | null = null;
  try {
    const resendRes = await fetch('https://api.resend.com/emails', {
      method:  'POST',
      headers: { 'Authorization': `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from:    `${FROM_NAME} <${FROM_EMAIL}>`,
        to:      [supportEmail],
        subject,
        text,
      }),
    });
    if (!resendRes.ok) emailError = await resendRes.text();
  } catch (e) {
    emailError = String(e);
  }

  // Marque le cooldown même si l'email a échoué : on ne veut pas retenter
  // frénétiquement un envoi qui échoue systématiquement (ex: clé Resend
  // invalide) — la prochaine alerte partira à la fin du cooldown normal.
  await supabase.from('platform_settings').upsert({
    key:        ALERT_COOLDOWN_KEY,
    value:      new Date().toISOString(),
    updated_at: new Date().toISOString(),
  });

  // Trace persistée même sans visualiseur dédié dans le dashboard.
  await supabase.from('error_logs').insert({
    type:    'health_check_alert',
    message: `Système ${health.status} : ${checksText.replace(/\n/g, ' | ')}`,
    context: health,
  });

  return new Response(JSON.stringify({
    ok:      true,
    status:  health.status,
    alerted: !emailError,
    ...(emailError ? { emailError } : {}),
  }), {
    headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
  });
});
