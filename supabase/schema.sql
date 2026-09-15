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
  "createdAt" bigint default 0
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
  "createdAt" bigint default 0
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
  "collabId" text default '',
  "createdAt" bigint default 0
);

create table if not exists settings (
  id text primary key default 'main',
  goal numeric default 45000,
  rates jsonb default '{"DKK":1,"EUR":7.46,"USD":6.4}'::jsonb
);
insert into settings (id) values ('main') on conflict (id) do nothing;

-- Row Level Security: any signed-in user (your team, via Supabase Auth) can
-- read and write every table. There's no per-row ownership in this app --
-- it's a small shared team CRM, not a multi-tenant product.
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
  foreach t in array array['contacts','collabs','deliverables','ideas','tasks','settings'] loop
    execute format('drop policy if exists "authenticated access" on %I', t);
    execute format('create policy "authenticated access" on %I for all using (auth.role() = ''authenticated'') with check (auth.role() = ''authenticated'')', t);
  end loop;
end $$;

-- Realtime: let the app subscribe to live changes on every table.
alter publication supabase_realtime add table contacts, collabs, deliverables, ideas, tasks, settings;
