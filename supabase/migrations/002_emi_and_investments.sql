-- ============================================================
-- Budget Buddy: Migration 002 — EMI Calculations & Investments
-- ============================================================

-- 1. EMI Calculations Table
create table if not exists public.emi_calculations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  title text not null default 'Loan Calculation',
  loan_amount numeric not null,
  interest_rate numeric not null,
  tenure_years integer not null,
  monthly_emi numeric not null,
  total_interest numeric not null,
  total_payment numeric not null,
  created_at timestamptz default now()
);

-- 2. Investments & Assets Table
create table if not exists public.investments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  name text not null,
  type text not null check (type in ('sip', 'mutual_fund', 'stocks', 'gold', 'fd', 'ppf', 'crypto', 'real_estate', 'other')),
  invested_amount numeric not null check (invested_amount >= 0),
  current_value numeric not null check (current_value >= 0),
  expected_return_rate numeric default 12.0,
  monthly_contribution numeric default 0,
  start_date date default current_date,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 3. Row Level Security (RLS)
alter table public.emi_calculations enable row level security;
alter table public.investments enable row level security;

create policy "Users can view own EMI calculations"
  on public.emi_calculations for select
  using (auth.uid() = user_id);

create policy "Users can insert own EMI calculations"
  on public.emi_calculations for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own EMI calculations"
  on public.emi_calculations for delete
  using (auth.uid() = user_id);

create policy "Users can view own investments"
  on public.investments for select
  using (auth.uid() = user_id);

create policy "Users can insert own investments"
  on public.investments for insert
  with check (auth.uid() = user_id);

create policy "Users can update own investments"
  on public.investments for update
  using (auth.uid() = user_id);

create policy "Users can delete own investments"
  on public.investments for delete
  using (auth.uid() = user_id);

-- Indexes
create index if not exists idx_emi_calculations_user
  on public.emi_calculations(user_id, created_at desc);

create index if not exists idx_investments_user
  on public.investments(user_id, created_at desc);
