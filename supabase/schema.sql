-- Collabs CRM schema
-- Run this once in your Supabase project's SQL editor (Dashboard -> SQL Editor -> New query).
-- It creates the five data tables plus a single-row settings table, and locks
-- them down so only signed-in users (your team) can read or write.

create table if not exists contacts (
  id text primary key,
  brand text default '',
  person text default '',
  email text default '',
  website text default '',
  social text default '',
  folder text default '',
  "lastContactDate" text default '',
  "followUpDate" text default '',
  status text default '',
  notes text default '',
  "createdAt" bigint default 0
);

create table if not exists collabs (
  id text primary key,
  "contactId" text default '',
  brand text default '',
  owner text default '',
  price numeric default 0,
  currency text default 'DKK',
  "finStatus" text default '',
  stage text default '',
  kanban text default '',
  pitch text default '',
  notes text default '',
  folder text default '',
  contract text default '',
  "startDate" text default '',
  "endDate" text default '',
  invoice text default '',
  archived boolean default false,
  "createdAt" bigint default 0,
  "wonAt" bigint
);

create table if not exists deliverables (
  id text primary key,
  "collabId" text default '',
  name text default '',
  platform text default '',
  type text default '',
  status text default '',
  "shootDate" text default '',
  "editDeadline" text default '',
  "publishDate" text default '',
  notes text default '',
  link text default '',
  price numeric,
  "createdAt" bigint default 0,
  "publishedAt" bigint
);

create table if not exists ideas (
  id text primary key,
  title text default '',
  hook text default '',
  concept text default '',
  platform text default '',
  type text default '',
  "collabId" text default '',
  "scheduledDate" text default '',
  "createdAt" bigint default 0
);

create table if not exists tasks (
  id text primary key,
  "group" text default '',
  title text default '',
  meta text default '',
  done boolean default false,
  archived boolean default false,
  "collabId" text default '',
  "createdAt" bigint default 0,
  "completedAt" bigint
);

create table if not exists settings (
  id text primary key default 'main',
  goal numeric default 45000,
  rates jsonb default '{"DKK":1,"EUR":7.46,"USD":6.4}'::jsonb
);
insert into settings (id) values ('main') on conflict (id) do nothing;

-- Weekly Ta da list. These are null until the app stamps them (epoch ms) the
-- moment a task is checked off, a deal is won (moved to Ongoing/Completed, or
-- booked), or a deliverable is marked Published. Existing rows stay null, so
-- nothing finished before this column existed is rewritten. Safe to re-run.
alter table tasks add column if not exists "completedAt" bigint;
alter table collabs add column if not exists "wonAt" bigint;
alter table deliverables add column if not exists "publishedAt" bigint;

-- Row Level Security: any signed-in user (your team, via Supabase Auth) can
-- read and write the shared tables. Tasks are the exception: the to-do list
-- is the owner's, and other logins only reach the ov-ws / ov-shop rows.
alter table contacts enable row level security;
alter table collabs enable row level security;
alter table deliverables enable row level security;
alter table ideas enable row level security;
alter table tasks enable row level security;
alter table settings enable row level security;

do $$
declare
  t text;
begin
  foreach t in array array['contacts','collabs','deliverables','ideas','settings'] loop
    execute format('drop policy if exists "authenticated access" on %I', t);
    execute format('create policy "authenticated access" on %I for all using (auth.role() = ''authenticated'') with check (auth.role() = ''authenticated'')', t);
  end loop;
end $$;

-- Tasks are the owner's to-do list. Other signed-in users only reach the two
-- shared rows that the rest of the CRM needs: the "waiting on brand" clock
-- (id ov-ws-*) and a hand-typed Shopify month (id ov-shop-*). Change the
-- uuid and email together with TADA_OWNER_ID / TADA_OWNER_EMAIL in config.js.
drop policy if exists "authenticated access" on tasks;
drop policy if exists "tasks owner" on tasks;
drop policy if exists "tasks shared memory" on tasks;
create policy "tasks owner" on tasks
  for all
  using (
    auth.role() = 'authenticated'
    and (
      auth.uid() = 'cb41ead3-e62a-4320-91bf-8fe8f8c3e284'::uuid
      or lower(coalesce(auth.jwt() ->> 'email', '')) = 'contact@byggeligt.com'
    )
  )
  with check (
    auth.role() = 'authenticated'
    and (
      auth.uid() = 'cb41ead3-e62a-4320-91bf-8fe8f8c3e284'::uuid
      or lower(coalesce(auth.jwt() ->> 'email', '')) = 'contact@byggeligt.com'
    )
  );
create policy "tasks shared memory" on tasks
  for all
  using (
    auth.role() = 'authenticated'
    and (id like 'ov-ws-%' or id like 'ov-shop-%')
  )
  with check (
    auth.role() = 'authenticated'
    and (id like 'ov-ws-%' or id like 'ov-shop-%')
  );

-- Realtime: let the app subscribe to live changes on every table.
alter publication supabase_realtime add table contacts, collabs, deliverables, ideas, tasks, settings;
