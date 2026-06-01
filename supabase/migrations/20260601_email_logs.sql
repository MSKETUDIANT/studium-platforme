-- Table email_logs : historique des envois de candidatures par email
create table if not exists email_logs (
  id                   uuid        default gen_random_uuid() primary key,
  application_id       uuid        not null references applications(id) on delete cascade,
  to_email             text        not null,
  cc_emails            text[],
  subject              text        not null,
  status               text        not null default 'sent' check (status in ('sent', 'failed', 'bounced')),
  provider_message_id  text,
  error_message        text,
  sent_by              uuid        references auth.users(id),
  sent_at              timestamptz default now()
);

-- Index pour accès rapide par candidature
create index if not exists email_logs_application_id_idx on email_logs(application_id);

-- RLS : lecture pour les rôles internes uniquement
alter table email_logs enable row level security;

create policy "team_read_email_logs" on email_logs
  for select using (
    exists (
      select 1 from auth.users
      where auth.users.id = auth.uid()
      and auth.users.raw_user_meta_data->>'role' in ('admin', 'admissions', 'manager', 'support')
    )
  );

create policy "team_insert_email_logs" on email_logs
  for insert with check (true); -- Edge Function utilise service role, contourne RLS
