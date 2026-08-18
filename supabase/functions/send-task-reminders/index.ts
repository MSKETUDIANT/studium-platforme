// @ts-nocheck  Deno Edge Function — rappels de tâches par email (Resend)
// Déclencher via cron Supabase : 0 * * * *  (toutes les heures)
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!;
const SUPABASE_URL   = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_KEY   = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const FROM_EMAIL     = 'onboarding@resend.dev'; // TODO: noreply@studium.app après vérification domaine
const FROM_NAME      = 'Studium';

const corsHeaders = () => ({
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
});

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders() });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
  const now      = new Date();
  let   sent     = 0;
  const errors: string[] = [];

  // 1. Récupérer les tâches non terminées avec rappel configuré
  const { data: tasks, error: fetchError } = await supabase
    .from('tasks')
    .select('id, title, description, due_date, reminder_hours, assignee_label, reminder_sent_at')
    .is('completed_at', null)
    .not('reminder_hours', 'is', null)
    .not('due_date', 'is', null);

  if (fetchError) {
    return new Response(JSON.stringify({ error: fetchError.message }), {
      status: 500, headers: { ...corsHeaders(), 'Content-Type': 'application/json' },
    });
  }

  // 2. Filtrer les tâches dont le rappel est dû et pas encore envoyé
  const dueTasks = (tasks ?? []).filter((t: any) => {
    if (t.reminder_sent_at) return false; // déjà envoyé
    const dueAt      = new Date(t.due_date);
    const reminderAt = new Date(dueAt.getTime() - t.reminder_hours * 3_600_000);
    return reminderAt <= now && dueAt > now;
  });

  // 3. Pour chaque tâche, trouver les emails des utilisateurs du rôle assigné
  for (const task of dueTasks) {
    if (!task.assignee_label) continue;

    // Trouver les user_ids du rôle correspondant
    const { data: userRoles } = await supabase
      .from('user_roles')
      .select('user_id, roles!role_id(name)')
      .eq('roles.name', task.assignee_label.toLowerCase());

    const userIds = (userRoles ?? []).map((ur: any) => ur.user_id);
    if (!userIds.length) continue;

    // Récupérer les emails via la table team_members (évite auth.users)
    const { data: members } = await supabase
      .from('team_members')
      .select('email, full_name')
      .in('user_id', userIds)
      .eq('is_active', true);

    const recipients = (members ?? []).filter((m: any) => m.email);
    if (!recipients.length) continue;

    const dueDate = new Date(task.due_date).toLocaleDateString('fr-FR', {
      weekday: 'long', day: 'numeric', month: 'long', year: 'numeric',
    });

    // 4. Envoyer l'email via Resend
    for (const member of recipients) {
      const html = `
        <div style="font-family:sans-serif;max-width:560px;margin:auto;color:#1a1a1a">
          <div style="background:#0b1852;padding:24px 28px;border-radius:12px 12px 0 0">
            <h2 style="color:white;margin:0;font-size:20px">Rappel de tâche</h2>
            <p style="color:rgba(255,255,255,.65);margin:4px 0 0;font-size:13px">Studium — Gestion des tâches</p>
          </div>
          <div style="background:#f9fafc;padding:24px 28px;border-radius:0 0 12px 12px;border:1px solid #e5e7eb">
            <p style="margin:0 0 8px">Bonjour ${member.full_name ?? ''},</p>
            <p style="margin:0 0 20px">La tâche suivante arrive bientôt à échéance :</p>
            <div style="background:white;border:1px solid #e5e7eb;border-left:4px solid #0b1852;border-radius:8px;padding:16px 20px;margin-bottom:20px">
              <strong style="font-size:15px">${task.title}</strong>
              ${task.description ? `<p style="color:#6b7280;font-size:13px;margin:8px 0 0">${task.description}</p>` : ''}
              <p style="margin:12px 0 0;font-size:13px;color:#374151">
                Echéance : <strong>${dueDate}</strong>
              </p>
            </div>
            <a href="${SUPABASE_URL.replace('.supabase.co', '')}/tasks"
               style="display:inline-block;background:#0b1852;color:white;padding:10px 22px;border-radius:8px;text-decoration:none;font-weight:600;font-size:13px">
              Voir la tâche
            </a>
            <p style="margin:24px 0 0;font-size:11px;color:#9ca3af">Studium Platform — rappel automatique</p>
          </div>
        </div>`;

      const res = await fetch('https://api.resend.com/emails', {
        method:  'POST',
        headers: {
          'Authorization': `Bearer ${RESEND_API_KEY}`,
          'Content-Type':  'application/json',
        },
        body: JSON.stringify({
          from:    `${FROM_NAME} <${FROM_EMAIL}>`,
          to:      [member.email],
          subject: `Rappel : ${task.title}`,
          html,
        }),
      });

      if (res.ok) {
        sent++;
      } else {
        const err = await res.text();
        errors.push(`task ${task.id} → ${member.email} : ${err}`);
      }
    }

    // 5. Marquer le rappel comme envoyé
    await supabase
      .from('tasks')
      .update({ reminder_sent_at: now.toISOString() })
      .eq('id', task.id);
  }

  return new Response(
    JSON.stringify({ processed: dueTasks.length, sent, errors }),
    { headers: { ...corsHeaders(), 'Content-Type': 'application/json' } },
  );
});
