-- ============================================================
-- Budget Buddy — Migration 004: AI Coach (idempotent)
-- Run with: supabase db push
-- ============================================================

-- ============================================================
-- 1. ai_usage TABLE (rate limiting: 30 questions/user/day)
-- ============================================================

create table if not exists public.ai_usage (
  user_id uuid references auth.users(id) on delete cascade,
  day     date not null,
  count   int  not null default 0,
  primary key (user_id, day)
);

-- RLS for ai_usage
alter table public.ai_usage enable row level security;

-- Allow users to read their own usage
do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_usage'
      and policyname = 'ai_usage: own select'
  ) then
    create policy "ai_usage: own select"
      on public.ai_usage for select
      using (auth.uid() = user_id);
  end if;
end $$;

-- Allow users to insert their own usage rows
do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_usage'
      and policyname = 'ai_usage: own insert'
  ) then
    create policy "ai_usage: own insert"
      on public.ai_usage for insert
      with check (auth.uid() = user_id);
  end if;
end $$;

-- Allow users to update their own usage rows
do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_usage'
      and policyname = 'ai_usage: own update'
  ) then
    create policy "ai_usage: own update"
      on public.ai_usage for update
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;
end $$;

-- ============================================================
-- 2. ENSURE RLS IS ENABLED on all AI-coach-related tables
--    (already enabled in 001, but ALTER TABLE ... ENABLE is idempotent)
-- ============================================================

alter table public.user_profiles     enable row level security;
alter table public.categories        enable row level security;
alter table public.transactions      enable row level security;
alter table public.budgets           enable row level security;
alter table public.savings_goals     enable row level security;
alter table public.ai_chat_history   enable row level security;

-- ============================================================
-- 3. CATEGORIES — fix policy to allow reading default categories
--    (user_id IS NULL means it is a global default row)
-- ============================================================

-- Drop the old broad "for all" policy that blocked default-category reads
do $$ begin
  if exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'categories'
      and policyname = 'Users manage own categories'
  ) then
    drop policy "Users manage own categories" on public.categories;
  end if;
end $$;

-- SELECT: own + global default categories
do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'categories'
      and policyname = 'categories: select own or default'
  ) then
    create policy "categories: select own or default"
      on public.categories for select
      using (user_id = auth.uid() or user_id is null);
  end if;
end $$;

-- INSERT: own only
do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'categories'
      and policyname = 'categories: insert own'
  ) then
    create policy "categories: insert own"
      on public.categories for insert
      with check (auth.uid() = user_id);
  end if;
end $$;

-- UPDATE: own only
do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'categories'
      and policyname = 'categories: update own'
  ) then
    create policy "categories: update own"
      on public.categories for update
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;
end $$;

-- DELETE: own only
do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'categories'
      and policyname = 'categories: delete own'
  ) then
    create policy "categories: delete own"
      on public.categories for delete
      using (auth.uid() = user_id);
  end if;
end $$;

-- ============================================================
-- 4. transactions — ensure separate policies exist
-- ============================================================

-- Keep existing "Users manage own transactions" if present; else create
do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'transactions'
      and policyname = 'Users manage own transactions'
  ) then
    create policy "Users manage own transactions"
      on public.transactions for all
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;
end $$;

-- ============================================================
-- 5. budgets — ensure policy exists
-- ============================================================

do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'budgets'
      and policyname = 'Users manage own budgets'
  ) then
    create policy "Users manage own budgets"
      on public.budgets for all
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;
end $$;

-- ============================================================
-- 6. savings_goals — ensure policy exists
-- ============================================================

do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'savings_goals'
      and policyname = 'Users manage own savings goals'
  ) then
    create policy "Users manage own savings goals"
      on public.savings_goals for all
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;
end $$;

-- ============================================================
-- 7. user_profiles — ensure policy exists
-- ============================================================

do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'user_profiles'
      and policyname = 'Users manage own profile'
  ) then
    create policy "Users manage own profile"
      on public.user_profiles for all
      using (auth.uid() = id)
      with check (auth.uid() = id);
  end if;
end $$;

-- ============================================================
-- 8. ai_chat_history — granular policies (select, insert, delete)
-- ============================================================

-- Drop the old broad "for all" policy if it exists
do $$ begin
  if exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_chat_history'
      and policyname = 'Users manage own chat history'
  ) then
    drop policy "Users manage own chat history" on public.ai_chat_history;
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_chat_history'
      and policyname = 'ai_chat: own select'
  ) then
    create policy "ai_chat: own select"
      on public.ai_chat_history for select
      using (auth.uid() = user_id);
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_chat_history'
      and policyname = 'ai_chat: own insert'
  ) then
    create policy "ai_chat: own insert"
      on public.ai_chat_history for insert
      with check (auth.uid() = user_id);
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_chat_history'
      and policyname = 'ai_chat: own delete'
  ) then
    create policy "ai_chat: own delete"
      on public.ai_chat_history for delete
      using (auth.uid() = user_id);
  end if;
end $$;

-- ============================================================
-- 9. INDEXES (all IF NOT EXISTS — safe to re-run)
-- ============================================================

create index if not exists idx_transactions_user_date
  on public.transactions(user_id, transaction_date desc);

create index if not exists idx_budgets_user_month
  on public.budgets(user_id, period_month);

create index if not exists idx_ai_chat_user_date
  on public.ai_chat_history(user_id, created_at desc);

create index if not exists idx_ai_usage_user_day
  on public.ai_usage(user_id, day desc);

