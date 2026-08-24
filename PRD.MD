# Budget Buddy — Product Requirements Document (PRD)

**Version:** 1.0
**Platform:** Flutter (Android-first, iOS-compatible)
**Author:** Smarty
**Date:** July 2026

---

## 1. Product Vision

Budget Buddy is an AI-powered personal budgeting and savings app built for everyday Indian users — especially in Tier-2/Tier-3 cities — who want a simple, trustworthy way to track spending, set budgets, and get plain-language financial guidance. Unlike SMS-reading finance apps, Budget Buddy is **fully manual-entry and privacy-first**: no bank/SMS permissions required, just email login and a few taps to log a transaction. An AI coach (powered by Google's Gemini API) sits on top of this data to answer questions, suggest budgets, and nudge better habits.

## 2. Problem Statement

- Existing budgeting apps either require risky SMS/bank access or are too complex (built for urban, English-first, salaried professionals).
- Most people don't know *why* they overspend or *how* to plan a realistic budget — they need a coach, not just a dashboard.
- Trust is the biggest barrier to fintech adoption outside metros — permissions-heavy apps scare users away.

## 3. Target Users

- Students, young professionals, small business owners, and households in Tier-2/3 Indian cities.
- Users with irregular or informal income who don't fit rigid "monthly salary" budgeting templates.
- Users who prefer control (manual entry) over automation they don't trust.

## 4. Goals & Non-Goals

**Goals**
- Make logging an expense take under 5 seconds.
- Give genuinely useful AI budget advice, not generic tips.
- Feel premium, fast, and trustworthy — smooth animations, light/dark mode, no jank even on budget Android phones.

**Non-Goals (v1)**
- No SMS/bank auto-read (removed by product decision — manual entry only).
- No direct payments, UPI transactions, or money movement — Budget Buddy is a **tracking and advisory** tool only, not a payments app.
- No investment execution (no buying stocks/gold) — advisory only in v1.

## 5. Authentication

- **Email + password login/signup only** (no phone OTP, no SMS permission, no social login required for v1).
- Password reset via email link.
- Session persistence via secure token storage on-device.

## 6. Core Features

### 6.1 Onboarding (4 screens max)
1. **Welcome/Splash** — animated logo, value proposition, "Initializing AI..." loading state (as in your Stitch splash design).
2. **Value carousel** (2 screens) — swipeable, illustrating (a) manual tracking simplicity and (b) AI-powered insights, with progress dots.
3. **Auth screen** — email + password fields, glass-panel card, "Continue with Email" primary action.
4. **Starting balance setup** — user manually enters their current balance and, optionally, average monthly income, to seed the AI's first budget suggestion.

### 6.2 Dashboard (Home)
- Circular/arc balance gauge showing current balance and "spent today" (per your Stitch design reference).
- Quick actions: **Add Expense**, **Add Income**, **View Statistics**.
- Recent activity list (last 5–10 manual entries) with category icons, amount, date.
- Budget progress card (e.g., "Budget for this month: ₹6,000 — 62% used").
- Bottom navigation: Home, Statistics, AI Coach (center, highlighted), Wallet/Categories, Settings.

### 6.3 Manual Expense/Income Entry
- Single floating "+" action → bottom sheet with: amount (numeric keypad), category (icon grid: Food, Transport, Bills, Shopping, Entertainment, Health, Other — user-editable), note (optional), date (defaults to today).
- Entry should complete in **2 taps + amount entry** — no more.
- Optimistic UI: balance updates instantly on save, syncs to Supabase in background.
- Edit/delete any past entry from the transaction detail view.

### 6.4 Statistics
- Weekly / Monthly / Yearly toggle.
- Bar chart of spend by period (per your Stitch statistics design).
- Category breakdown (pie or horizontal bar) with percentage of total spend.
- Budget-vs-actual comparison per category.

### 6.5 Budgets & Goals
- Set a monthly overall budget and/or per-category budgets.
- Savings goals (e.g., "Save ₹5,000 for Diwali by Nov 1") with progress bar.
- Alerts when a category crosses 80%/100% of its budget.

### 6.6 AI Coach (Gemini-powered)
- Dedicated chat screen (per your Stitch AI-chat design: "Hi Mel, how is your budgeting going?").
- Suggested quick-prompt chips: **Secure**, **Invest** (advisory only), **Plan**.
- User can type free-form questions: *"Can I afford a new phone this month?"*, *"Where did I overspend this week?"*
- AI responses are grounded in the user's actual logged transactions and budgets (not generic financial advice) — retrieved from Supabase and passed as context to the Gemini API call.
- **Proactive weekly digest**: AI generates a short summary notification/card ("You're 80% through your food budget with 10 days left in the month").
- Voice input option (microphone icon, as shown in your Stitch design) for hands-free logging/questions — optional v1.1 feature if timeline is tight.

### 6.7 Settings
- Light/Dark mode toggle (also respects system default).
- Language selection (English + Hindi minimum for v1; expandable).
- Category management (add/edit/remove custom categories).
- Notification preferences.
- Account/profile, logout, delete account.
- Data export (CSV) — builds trust, gives users ownership of their data.

## 7. Design System (from provided Stitch reference)

- **Theme name:** Premium Emerald Fintech
- **Typography:** Manrope, weights 400–800, with a defined type scale (display-lg 40px/700 down to label-sm 12px/500).
- **Color system:** Material 3–style token set (primary `#006c49`, primary-container `#10b981`, secondary `#2b6954`, surface `#f4fbf4`, on-background `#161d19`), each requiring a **parallel dark-mode token set** (M3 dark equivalents — primary shifts toward `#4edea3`/`#6ffbbe` per the "fixed-dim" tokens already defined in your reference, which are the dark-mode-ready variants).
- **Visual language:** glassmorphic cards (`backdrop-filter: blur`) used *selectively* — hero illustrations, AI chat bubbles, floating icon badges — not on core numeric/balance displays, to preserve legibility.
- **Iconography:** Material Symbols Outlined (variable weight/fill).
- **Corner radius:** large, soft (24–48px "squircle" style) for a premium, approachable feel.

## 8. Animation & Motion Requirements

- Splash: floating logo (subtle Y-axis float loop), animated progress bar, soft parallax on load.
- Onboarding: staggered fade/slide-in for text and illustration on screen entry; animated progress dots on swipe.
- Buttons: scale-down (0.96) on press, shimmer sweep on primary CTAs.
- Balance updates: animated number roll-up (not an instant jump) when balance changes.
- Screen transitions: Hero animations between dashboard cards and detail views.
- AI chat: pulsing glow on the AI avatar while "thinking"; typing-indicator animation before response renders.
- All animations must degrade gracefully (respect Android's reduce-motion setting) and stay performant on sub-₹15,000 Android devices.

## 9. Success Metrics (v1)

- % of signups who complete onboarding + log first transaction within 24 hours.
- Average transactions logged per active user per week.
- AI Coach engagement rate (chats per active user per week).
- Day-7 and Day-30 retention.
- Crash-free session rate (target 99.5%+, critical for low-end device trust).

## 10. Out of Scope / Future Roadmap

- SMS/bank auto-sync (explicitly rejected for v1 — manual-first by design).
- UPI/payment execution.
- Investment execution (gold, mutual funds, stocks).
- Multi-user/family shared budgets.
- Web dashboard companion (Next.js) — post-MVP only.
