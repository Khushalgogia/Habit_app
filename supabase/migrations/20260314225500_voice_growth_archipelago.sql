create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  email text not null default '',
  photo_url text,
  timezone text not null default 'UTC',
  theme_mode text not null default 'dark',
  onboarding_state text not null default 'pending',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.habits (
  user_id uuid not null references auth.users (id) on delete cascade,
  id text not null,
  name text not null,
  subtitle text not null default '',
  icon_key text not null,
  icon_color text not null,
  base_color text not null,
  glow_color text not null,
  x_pct double precision not null,
  y_pct double precision not null,
  frequency text not null,
  days_due integer[] not null default '{}'::integer[],
  scope_mode text not null,
  is_core boolean not null default false,
  category text not null,
  category_color text not null,
  status text not null default 'active',
  created_at timestamptz not null default timezone('utc', now()),
  archived_at timestamptz,
  deleted_at timestamptz,
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, id)
);

create table if not exists public.daily_logs (
  user_id uuid not null references auth.users (id) on delete cascade,
  date_key text not null,
  completed_habit_ids text[] not null default '{}'::text[],
  completed_at_by_habit jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, date_key)
);

create index if not exists habits_user_status_created_at_idx
on public.habits (user_id, status, created_at);

create index if not exists daily_logs_user_date_key_idx
on public.daily_logs (user_id, date_key);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

drop trigger if exists habits_set_updated_at on public.habits;
create trigger habits_set_updated_at
before update on public.habits
for each row
execute function public.set_updated_at();

drop trigger if exists daily_logs_set_updated_at on public.daily_logs;
create trigger daily_logs_set_updated_at
before update on public.daily_logs
for each row
execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.habits enable row level security;
alter table public.daily_logs enable row level security;

drop policy if exists "profiles_select_self" on public.profiles;
create policy "profiles_select_self"
on public.profiles
for select
to authenticated
using (id = auth.uid());

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self"
on public.profiles
for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self"
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "profiles_delete_self" on public.profiles;
create policy "profiles_delete_self"
on public.profiles
for delete
to authenticated
using (id = auth.uid());

drop policy if exists "habits_select_self" on public.habits;
create policy "habits_select_self"
on public.habits
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "habits_insert_self" on public.habits;
create policy "habits_insert_self"
on public.habits
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "habits_update_self" on public.habits;
create policy "habits_update_self"
on public.habits
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "habits_delete_self" on public.habits;
create policy "habits_delete_self"
on public.habits
for delete
to authenticated
using (user_id = auth.uid());

drop policy if exists "daily_logs_select_self" on public.daily_logs;
create policy "daily_logs_select_self"
on public.daily_logs
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "daily_logs_insert_self" on public.daily_logs;
create policy "daily_logs_insert_self"
on public.daily_logs
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "daily_logs_update_self" on public.daily_logs;
create policy "daily_logs_update_self"
on public.daily_logs
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "daily_logs_delete_self" on public.daily_logs;
create policy "daily_logs_delete_self"
on public.daily_logs
for delete
to authenticated
using (user_id = auth.uid());
