-- ============================================================
-- Budget Buddy — Initial Database Schema
-- Version: 1.0
-- Generated from TRD section 4
-- ============================================================

-- ============================================================
-- 1. TABLES
-- ============================================================

-- Users are managed by Supabase Auth (auth.users);
-- extend with a profile table for app-specific preferences.
create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  currency text default 'INR',
  language text default 'en',
  theme_preference text default 'system', -- 'light' | 'dark' | 'system'
  monthly_income numeric,
  created_at timestamptz default now()
);

-- Spending/income categories (user-customizable + seeded defaults).
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  name text not null,
  icon text not null,
  is_default boolean default false,
  created_at timestamptz default now()
);

-- All expense and income entries.
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  category_id uuid references public.categories(id),
  type text not null check (type in ('expense', 'income')),
  amount numeric not null check (amount > 0),
  note text,
  transaction_date date not null default current_date,
  created_at timestamptz default now()
);

-- Monthly budgets (overall or per-category).
create table if not exists public.budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  category_id uuid references public.categories(id), -- null = overall budget
  amount numeric not null,
  period_month date not null, -- first day of the budget month
  created_at timestamptz default now()
);

-- Savings goals with progress tracking.
create table if not exists public.savings_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  title text not null,
  target_amount numeric not null,
  current_amount numeric default 0,
  target_date date,
  created_at timestamptz default now()
);

-- AI Coach conversation history.
create table if not exists public.ai_chat_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  created_at timestamptz default now()
);

-- ============================================================
-- 2. INDEXES (for common query patterns)
-- ============================================================

create index if not exists idx_transactions_user_date
  on public.transactions(user_id, transaction_date desc);

create index if not exists idx_transactions_user_type
  on public.transactions(user_id, type);

create index if not exists idx_categories_user
  on public.categories(user_id);

create index if not exists idx_budgets_user_month
  on public.budgets(user_id, period_month);

create index if not exists idx_savings_goals_user
  on public.savings_goals(user_id);

create index if not exists idx_ai_chat_user_date
  on public.ai_chat_history(user_id, created_at desc);

-- ============================================================
-- 3. ROW LEVEL SECURITY (RLS)
-- ============================================================

-- user_profiles
alter table public.user_profiles enable row level security;
create policy "Users manage own profile"
  on public.user_profiles for all
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- categories
alter table public.categories enable row level security;
create policy "Users manage own categories"
  on public.categories for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- transactions
alter table public.transactions enable row level security;
create policy "Users manage own transactions"
  on public.transactions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- budgets
alter table public.budgets enable row level security;
create policy "Users manage own budgets"
  on public.budgets for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- savings_goals
alter table public.savings_goals enable row level security;
create policy "Users manage own savings goals"
  on public.savings_goals for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ai_chat_history
alter table public.ai_chat_history enable row level security;
create policy "Users manage own chat history"
  on public.ai_chat_history for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ============================================================
-- 4. TRIGGERS — Auto-create profile + seed default categories
-- ============================================================

-- Function: create user_profile + seed default categories on signup.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  -- Create profile row
  insert into public.user_profiles (id) values (new.id);

  -- Seed default categories
  insert into public.categories (user_id, name, icon, is_default) values
    (new.id, 'Food',          'restaurant',       true),
    (new.id, 'Transport',     'directions_car',   true),
    (new.id, 'Bills',         'receipt_long',     true),
    (new.id, 'Shopping',      'shopping_bag',     true),
    (new.id, 'Entertainment', 'movie',            true),
    (new.id, 'Health',        'medical_services', true),
    (new.id, 'Education',     'school',           true),
    (new.id, 'Other',         'more_horiz',       true);

  return new;
end;
$$ language plpgsql security definer;

-- Trigger: fire after new user signup in auth.users.
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
