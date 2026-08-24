# Budget Buddy — Technical Requirements Document (TRD)

**Version:** 1.0
**Companion to:** Budget_Buddy_PRD.md

---

## 1. Architecture Overview

```
Flutter App (Android-first, iOS-compatible)
     │
     ├── Auth: Supabase Auth (email/password) — direct, no Firebase bridge needed
     │
     ├── Database/Backend: Supabase (Postgres + RLS + Edge Functions)
     │
     └── AI: Google Gemini API (called via Supabase Edge Function, not directly from client)
```

**Key simplification from earlier discussion:** since the app now uses **email/password login only** (no phone OTP), there is no need for the Firebase Auth ↔ Supabase third-party JWT bridge. Use **Supabase Auth natively** — this reuses the same security patterns you already built for FitTrack (rate limiting, password policy, HIBP breach checks, RLS-based data isolation) instead of introducing a second auth system.

## 2. Critical Security Note — API Key Handling

You shared a Google API key directly in chat. Treat it as **compromised**:

1. Go to Google Cloud Console → APIs & Services → Credentials, and **regenerate** the key immediately.
2. **Restrict the new key**: limit it to the Generative Language API (Gemini) only, and if possible restrict by Android package name + SHA-1 signing certificate fingerprint.
3. **Never call Gemini directly from the Flutter client** with the key embedded in app code — a decompiled APK exposes any key baked into the binary. Instead:
   - Store the key as a Supabase Edge Function **secret** (`supabase secrets set GEMINI_API_KEY=...`).
   - Client calls your Edge Function → Edge Function calls Gemini → returns response to client.
   - This also lets you rate-limit/cache AI calls server-side to control cost.

## 3. Tech Stack

| Layer | Technology |
|---|---|
| Mobile framework | Flutter (Dart), Material 3 |
| State management | Riverpod (recommended for scalability) or Provider |
| Auth | Supabase Auth (email/password) |
| Database | Supabase Postgres |
| Realtime sync | Supabase Realtime (optional, for instant balance updates across devices) |
| Serverless logic | Supabase Edge Functions (Deno/TypeScript) — hosts the Gemini API proxy |
| AI | Google Gemini API (via Edge Function) |
| Local caching | Hive or Drift (SQLite) for offline-first transaction entry |
| Charts | `fl_chart` package |
| Animations | Flutter implicit animations, `Hero`, `flutter_animate` or `rive` for advanced motion |

## 4. Database Schema (Supabase / Postgres)

```sql
-- Users are managed by Supabase Auth (auth.users); extend with a profile table
create table public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  currency text default 'INR',
  language text default 'en',
  theme_preference text default 'system', -- 'light' | 'dark' | 'system'
  monthly_income numeric,
  created_at timestamptz default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  name text not null,
  icon text not null,
  is_default boolean default false,
  created_at timestamptz default now()
);

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  category_id uuid references public.categories(id),
  type text not null check (type in ('expense', 'income')),
  amount numeric not null check (amount > 0),
  note text,
  transaction_date date not null default current_date,
  created_at timestamptz default now()
);

create table public.budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  category_id uuid references public.categories(id), -- null = overall budget
  amount numeric not null,
  period_month date not null, -- first day of the budget month
  created_at timestamptz default now()
);

create table public.savings_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  title text not null,
  target_amount numeric not null,
  current_amount numeric default 0,
  target_date date,
  created_at timestamptz default now()
);

create table public.ai_chat_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  created_at timestamptz default now()
);
```

**Row Level Security (apply to every table above):**
```sql
alter table public.transactions enable row level security;
create policy "Users manage own transactions"
  on public.transactions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
-- Repeat the same pattern for categories, budgets, savings_goals,
-- ai_chat_history, and user_profiles.
```

Given your past issue with `get_user_role()` returning NULL on the medical store project: since every table here keys directly off `auth.uid()` (no custom role lookup needed for this app), that specific failure mode doesn't apply — but always seed a `user_profiles` row via a Postgres trigger on `auth.users` insert, so no user is ever left without a profile row.

```sql
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.user_profiles (id) values (new.id);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

## 5. AI Integration Design (Gemini via Edge Function)

**Edge Function: `ai-coach`**
1. Client sends: user message + (optionally) which quick-prompt was tapped.
2. Edge Function:
   - Fetches the user's last 30 days of transactions, current budgets, and savings goals from Postgres (using the caller's JWT, scoped by RLS).
   - Builds a system prompt with this context (e.g., "User's budget: ₹6,000/month, spent ₹3,720 so far, categories: ...").
   - Calls Gemini API with the system context + user message + short chat history (last 5–10 messages from `ai_chat_history`).
   - Streams or returns the response.
   - Saves both user message and AI response to `ai_chat_history`.
3. **Cost control:** cache category-level insights (e.g., weekly digest) and regenerate on a schedule (e.g., daily cron via Supabase scheduled function) rather than on every app open. Only real-time chat messages should trigger a live Gemini call.

## 6. Flutter Project Structure

```
lib/
├── main.dart
├── app/
│   ├── theme/              # light_theme.dart, dark_theme.dart, design_tokens.dart
│   ├── router/              # go_router setup
│   └── constants/
├── core/
│   ├── supabase_client.dart
│   ├── services/            # auth_service.dart, ai_service.dart, transaction_service.dart
│   └── models/               # transaction.dart, budget.dart, category.dart, chat_message.dart
├── features/
│   ├── onboarding/
│   ├── auth/
│   ├── dashboard/
│   ├── transactions/        # add/edit expense sheet, transaction list
│   ├── statistics/
│   ├── budgets/
│   ├── ai_coach/
│   └── settings/
└── shared/
    ├── widgets/               # glass_card.dart, animated_balance.dart, category_icon.dart
    └── animations/
```

## 7. Theming — Light/Dark Mode Implementation

- Define both token sets as Dart `ColorScheme` extensions, mapped 1:1 from the M3 tokens already in your Stitch `DESIGN.md` (the `-fixed`/`-fixed-dim` tokens you have are the correct dark-mode pairs — e.g., `primary` → `primary-fixed-dim` in dark mode).
- Use `ThemeMode.system` as default, with an explicit override stored in `user_profiles.theme_preference` and synced via `ThemeMode` provider.
- Test all glassmorphic surfaces in dark mode specifically — `rgba(255,255,255,0.4)` glass panels need a dark-mode equivalent (e.g., `rgba(30,35,32,0.4)`) or they'll look washed out.

## 8. Performance Requirements

- Cold start under 2.5s on a mid-range Android device (e.g., 4GB RAM, Snapdragon 4-series).
- 60fps target for all list scrolling and animations; test on a genuinely low-end device, not just a dev/emulator.
- Offline-first: transactions can be logged with no network; sync to Supabase when connectivity returns (use local Drift/Hive queue + background sync worker).
- Images/illustrations: use SVG or vector assets over large PNGs where possible to keep app size and memory footprint low.

## 9. Testing & Rollout

- Unit tests for transaction/budget calculation logic (Dart `test` package).
- Widget tests for critical flows (add expense, onboarding).
- Manual device-lab testing on at least one sub-₹10,000 Android phone.
- Staged rollout via Play Console (internal testing → closed beta → production).

## 10. Open Technical Decisions (to confirm before build)

- State management: Riverpod vs Provider (Riverpod recommended for testability at this scale).
- Offline sync conflict resolution strategy (last-write-wins is simplest for a single-user-per-account app like this).
- Push notifications: Firebase Cloud Messaging (FCM) can be used purely for notifications/budget alerts without touching auth, if you want push later.
