-- ==============================================================================
-- Migration: 20261108000000_loans.sql
-- Description: Creates public.loans table with RLS and indexes for tracking user loans
-- ==============================================================================

create table if not exists public.loans (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    name text not null,
    principal numeric not null check (principal > 0),
    interest_rate numeric not null check (interest_rate >= 0),
    emi_amount numeric not null check (emi_amount > 0),
    tenure_months integer not null check (tenure_months > 0),
    start_date date not null default current_date,
    status text not null default 'active' check (status in ('active', 'closed')),
    created_at timestamptz not null default now()
);

-- Enable Row Level Security (idempotent)
alter table public.loans enable row level security;

-- Idempotent RLS Policy: own rows for ALL operations (select, insert, update, delete)
drop policy if exists "loans: own rows" on public.loans;
create policy "loans: own rows"
    on public.loans
    for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- Indexes for efficient queries
create index if not exists idx_loans_user_status on public.loans(user_id, status);
create index if not exists idx_loans_user_created on public.loans(user_id, created_at desc);

