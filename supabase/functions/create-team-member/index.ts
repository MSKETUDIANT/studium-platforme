// @ts-nocheck  Deno Edge Function — invite un membre d'equipe (dashboard).
// Cree le compte auth (email d'invitation Supabase), l'entree user_roles et
// l'entree team_members. Reserve aux admins (verifie via le JWT de l'appelant,
// pas seulement cote UI).
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const ALLOWED_ROLES = ['admin', 'admissions', 'support', 'manager'];

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin':  '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };
}

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status, headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders() });

  try {
    const authHeader = req.headers.get('Authorization');
    const callerJwt = authHeader?.replace('Bearer ', '');
    if (!callerJwt) return jsonError('Non authentifié', 401);

    const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

    // Verifie que l'appelant est bien admin (pas seulement le bouton cache
    // cote UI) avant d'utiliser les privileges admin de la service role.
    const { data: { user: caller } } = await supabase.auth.getUser(callerJwt);
    if (!caller) return jsonError('Non authentifié', 401);

    const { data: callerRole } = await supabase
      .from('user_roles')
      .select('roles!role_id(name)')
      .eq('user_id', caller.id)
      .maybeSingle();
    if ((callerRole?.roles as any)?.name !== 'admin') {
      return jsonError('Réservé aux administrateurs', 403);
    }

    const { email, role } = await req.json();
    if (!email || !role) return jsonError('email et role requis', 400);
    if (!ALLOWED_ROLES.includes(role)) return jsonError(`Rôle invalide : ${role}`, 400);

    const { data: roleRow, error: roleErr } = await supabase
      .from('roles')
      .select('id')
      .eq('name', role)
      .single();
    if (roleErr || !roleRow) return jsonError(`Rôle introuvable en base : ${role}`, 400);

    // Cree le compte + envoie l'email d'invitation (definir mot de passe).
    const { data: invited, error: inviteErr } = await supabase.auth.admin.inviteUserByEmail(email, {
      redirectTo: 'http://localhost:5173/reset-password',
    });
    if (inviteErr || !invited?.user) return jsonError(inviteErr?.message ?? "Échec de l'invitation", 400);

    const userId = invited.user.id;

    // Le trigger assign_default_role() attribue "student" par defaut a la
    // creation du compte auth (avant que invited_at ne soit renseigne par
    // un appel separe juste apres) : un compte fraichement cree par CET
    // appel a donc toujours un role "student" a ce stade, sans que ce soit
    // un vrai conflit. On ne bloque que si le compte existait deja AVANT
    // cet appel (cree il y a plus de quelques secondes).
    const isFreshlyCreated =
      Date.now() - new Date(invited.user.created_at).getTime() < 5000;

    if (!isFreshlyCreated) {
      // inviteUserByEmail peut reussir (renvoi d'invitation) sur un compte
      // deja existant avec un role (ex. un etudiant) : sans cette verification,
      // l'insertion suivante creerait un 2e role pour le meme utilisateur —
      // constate en test, casse useRole() cote client (.maybeSingle() sur
      // plusieurs lignes).
      const { data: existingRole } = await supabase
        .from('user_roles')
        .select('roles!role_id(name)')
        .eq('user_id', userId)
        .maybeSingle();
      if (existingRole) {
        const currentRoleName = (existingRole.roles as any)?.name ?? 'inconnu';
        return jsonError(
          `Cet email est déjà associé à un compte existant (rôle actuel : ${currentRoleName}). ` +
          `Utilisez "Changer le rôle" sur ce membre au lieu de l'inviter à nouveau.`,
          409,
        );
      }
    }

    // upsert plutot qu'insert : ecrase le role "student" assigne par
    // defaut par le trigger sur ce compte fraichement cree.
    const { error: roleInsertErr } = await supabase.from('user_roles')
      .upsert({ user_id: userId, role_id: roleRow.id, status: 'active' }, { onConflict: 'user_id' });
    if (roleInsertErr) return jsonError(`Compte créé mais rôle non attribué : ${roleInsertErr.message}`, 500);

    const { error: memberInsertErr } = await supabase.from('team_members').insert({
      user_id: userId, email, is_active: true,
    });
    // Ne bloque pas l'invitation si cette ligne echoue (deja logue) — le
    // compte + role sont l'essentiel, team_members ne sert qu'aux rappels.
    if (memberInsertErr) console.error(`team_members insert failed for ${email}: ${memberInsertErr.message}`);

    return new Response(JSON.stringify({ success: true, user_id: userId }), {
      headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
    });
  } catch (err) {
    return jsonError(String(err), 500);
  }
});
