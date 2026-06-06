// @ts-nocheck  Deno Edge Function
// Envoie une notification FCM à un ou plusieurs utilisateurs
// Payload attendu : { user_ids: string[], title: string, body: string, data?: Record<string,string> }

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL        = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')!
const FIREBASE_SA         = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!  // JSON string

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

//  JWT pour OAuth2 Firebase 

function pemToBinary(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '')
  const bin = atob(b64)
  const buf = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i)
  return buf.buffer
}

function b64url(data: ArrayBuffer | string): string {
  const bytes = typeof data === 'string'
    ? new TextEncoder().encode(data)
    : new Uint8Array(data)
  let bin = ''
  for (const b of bytes) bin += String.fromCharCode(b)
  return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}

async function getFirebaseAccessToken(sa: any): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const header  = { alg: 'RS256', typ: 'JWT' }
  const payload = {
    iss: sa.client_email,
    sub: sa.client_email,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  }

  const toSign = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(payload))}`

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToBinary(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(toSign))
  const jwt = `${toSign}.${b64url(sig)}`

  const resp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })
  const { access_token } = await resp.json()
  return access_token
}

//  Envoi FCM 

async function sendFcm(
  accessToken: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string> = {},
): Promise<{ success: boolean; error?: string }> {
  const url = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`
  const resp = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token,
        notification: { title, body },
        data,
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      },
    }),
  })

  if (!resp.ok) {
    const err = await resp.text()
    return { success: false, error: err }
  }
  return { success: true }
}

//  Handler principal 

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { user_ids, title, body, data = {} } = await req.json()

    if (!user_ids?.length || !title || !body) {
      return new Response(JSON.stringify({ error: 'user_ids, title, body requis' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const supabase    = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    const sa          = JSON.parse(FIREBASE_SA)
    const accessToken = await getFirebaseAccessToken(sa)

    // Récupérer les tokens FCM des utilisateurs ciblés
    const { data: rows, error } = await supabase
      .from('fcm_tokens')
      .select('token')
      .in('user_id', user_ids)

    if (error) throw error

    const tokens = rows?.map((r) => r.token) ?? []
    if (tokens.length === 0) {
      return new Response(JSON.stringify({ success: true, sent: 0, message: 'Aucun token FCM enregistré' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // Envoi en parallèle
    const results = await Promise.allSettled(
      tokens.map((token) => sendFcm(accessToken, token, title, body, data))
    )

    const sent   = results.filter((r) => r.status === 'fulfilled' && r.value.success).length
    const failed = results.length - sent

    console.log(`Push envoyé : ${sent} succès, ${failed} échecs`)

    return new Response(JSON.stringify({ success: true, sent, failed }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (err) {
    console.error('Erreur send-push-notification:', err)
    return new Response(JSON.stringify({ success: false, error: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
