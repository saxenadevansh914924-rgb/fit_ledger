-- Private, account-scoped goals and period-by-period progress.

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) between 1 and 120),
  details text,
  cadence text not null,
  target_count integer not null check (target_count > 0),
  unit text,
  created_at timestamptz not null default now()
);

-- Keep this migration safe to re-run when adding cadence options later.
alter table public.goals drop constraint if exists goals_cadence_check;
alter table public.goals
  add constraint goals_cadence_check
  check (cadence in ('daily', 'weekly', 'monthly', 'yearly', 'once'));

create table if not exists public.goal_progress (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references public.goals(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  period_key date not null,
  completed_count integer not null default 0 check (completed_count >= 0),
  updated_at timestamptz not null default now(),
  unique (goal_id, period_key)
);

alter table public.goals enable row level security;
alter table public.goal_progress enable row level security;

drop policy if exists "Users manage their own goals" on public.goals;
create policy "Users manage their own goals"
  on public.goals for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users manage their own goal progress" on public.goal_progress;
create policy "Users manage their own goal progress"
  on public.goal_progress for all to authenticated
  using (
    auth.uid() = user_id
    and exists (
      select 1 from public.goals g
      where g.id = goal_id and g.user_id = auth.uid()
    )
  )
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.goals g
      where g.id = goal_id and g.user_id = auth.uid()
    )
  );

grant select, insert, update, delete on public.goals to authenticated;
grant select, insert, update, delete on public.goal_progress to authenticated;
