-- ============================================================
-- Budget Buddy: Migration 003 — Loan Payments, Adjustments &
-- Investment Valuation History
-- ============================================================

-- 1. Loan Payments Table
-- Records each individual EMI payment against a saved loan calculation.
-- The loan_id references the emi_calculations table's text-based ID (not UUID)
-- because the app uses string IDs locally. We store it as text to match.
create table if not exists public.loan_payments (
  id text primary key,
  loan_id text not null,
  user_id uuid references auth.users(id) on delete cascade,
  emi_number integer not null check (emi_number >= 1),
  amount_paid numeric not null check (amount_paid > 0),
  principal_component numeric not null default 0 check (principal_component >= 0),
  interest_component numeric not null default 0 check (interest_component >= 0),
  payment_date date not null default current_date,
  status text not null default 'paid' check (status in ('paid', 'partial', 'missed')),
  reference text,
  note text,
  created_at timestamptz default now(),
  -- Prevent duplicate EMI payments for the same loan
  unique(loan_id, emi_number, user_id)
);

-- 2. Loan Adjustments Table
-- Records extra principal repayments and manual balance corrections.
create table if not exists public.loan_adjustments (
  id text primary key,
  loan_id text not null,
  user_id uuid references auth.users(id) on delete cascade,
  adjustment_type text not null check (
    adjustment_type in ('extra_principal', 'balance_correction', 'other')
  ),
  amount numeric not null check (amount > 0),
  note text,
  date date not null default current_date,
  created_at timestamptz default now()
);

-- 3. Investment Valuation History Table
-- Records each growth/decrease update to an investment's market value.
create table if not exists public.investment_valuation_history (
  id text primary key,
  investment_id text not null,
  user_id uuid references auth.users(id) on delete cascade,
  previous_value numeric not null check (previous_value >= 0),
  new_value numeric not null check (new_value >= 0),
  amount_changed numeric not null,
  percentage_changed numeric not null,
  update_type text not null check (
    update_type in (
      'manual_growth', 'manual_decrease', 'market_update',
      'purchase', 'sale', 'other'
    )
  ),
  timestamp timestamptz not null default now(),
  note text,
  created_at timestamptz default now()
);

-- ============================================================
-- Row Level Security
-- ============================================================

alter table public.loan_payments enable row level security;
alter table public.loan_adjustments enable row level security;
alter table public.investment_valuation_history enable row level security;

-- loan_payments policies
create policy "Users can view own loan payments"
  on public.loan_payments for select
  using (auth.uid() = user_id);

create policy "Users can insert own loan payments"
  on public.loan_payments for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own loan payments"
  on public.loan_payments for delete
  using (auth.uid() = user_id);

-- loan_adjustments policies
create policy "Users can view own loan adjustments"
  on public.loan_adjustments for select
  using (auth.uid() = user_id);

create policy "Users can insert own loan adjustments"
  on public.loan_adjustments for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own loan adjustments"
  on public.loan_adjustments for delete
  using (auth.uid() = user_id);

-- investment_valuation_history policies
create policy "Users can view own investment history"
  on public.investment_valuation_history for select
  using (auth.uid() = user_id);

create policy "Users can insert own investment history"
  on public.investment_valuation_history for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own investment history"
  on public.investment_valuation_history for delete
  using (auth.uid() = user_id);

-- ============================================================
-- Indexes
-- ============================================================

create index if not exists idx_loan_payments_loan_user
  on public.loan_payments(loan_id, user_id);

create index if not exists idx_loan_payments_user
  on public.loan_payments(user_id, payment_date desc);

create index if not exists idx_loan_adjustments_loan_user
  on public.loan_adjustments(loan_id, user_id);

create index if not exists idx_inv_valuation_history_inv
  on public.investment_valuation_history(investment_id, user_id);

create index if not exists idx_inv_valuation_history_user
  on public.investment_valuation_history(user_id, timestamp desc);
