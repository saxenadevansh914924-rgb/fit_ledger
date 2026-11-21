-- Public, user-scoped profile rows for FitLedger.
-- Run this once in Supabase SQL Editor. Existing auth users are backfilled below.

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text,
  full_name text,
  hobby text,
  occupation text,
  mobile_number text,
  contact_email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "Users can view their own profile" on public.profiles;
create policy "Users can view their own profile"
  on public.profiles for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Users can create their own profile" on public.profiles;
create policy "Users can create their own profile"
  on public.profiles for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
  on public.profiles for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Create a profile automatically whenever a new Supabase Auth account is created.
create or replace function public.create_fitledger_profile_for_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, username, full_name)
  values (
    new.id,
    new.raw_user_meta_data ->> 'username',
    coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      new.raw_user_meta_data ->> 'display_name'
    )
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists fitledger_profile_after_auth_signup on auth.users;
create trigger fitledger_profile_after_auth_signup
  after insert on auth.users
  for each row execute function public.create_fitledger_profile_for_auth_user();

-- Backfill accounts that existed before this migration.
insert into public.profiles (user_id, username, full_name)
select
  id,
  coalesce(raw_user_meta_data ->> 'username', split_part(email, '@', 1)),
  coalesce(
    raw_user_meta_data ->> 'full_name',
    raw_user_meta_data ->> 'name',
    raw_user_meta_data ->> 'display_name'
  )
from auth.users
on conflict (user_id) do nothing;

grant select, insert, update on public.profiles to authenticated;
