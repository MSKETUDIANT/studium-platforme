// @ts-nocheck  Deno Edge Function
// US-7.6 : Relances automatiques J+7 et J+14 pour candidatures sans réponse
// Déclencher via pg_cron : SELECT cron.schedule('check-reminders', '0 8 * * *', $$SELECT net.http_post(...)$$)
// Ou via Supabase Dashboard > Edge Functions > Schedule

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL  = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

    // Appel la fonction SQL qui génère les tâches de relance
    const { error } = await supabase.rpc('create_reminder_tasks');

    if (error) {
      console.error('Erreur create_reminder_tasks:', error);
      return new Response(
        JSON.stringify({ success: false, error: error.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Récupère les tâches créées aujourd'hui pour les retourner
    const today = new Date().toISOString().split('T')[0];
    const { data: newTasks } = await supabase
      .from('tasks')
      .select('id, title, task_type, application_id')
      .gte('created_at', today)
      .in('task_type', ['reminder_j7', 'reminder_j14']);

    console.log(`Relances créées : ${newTasks?.length ?? 0}`);

    return new Response(
      JSON.stringify({
        success: true,
        reminders_created: newTasks?.length ?? 0,
        tasks: newTasks ?? [],
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('Erreur inattendue:', err);
    return new Response(
      JSON.stringify({ success: false, error: String(err) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
