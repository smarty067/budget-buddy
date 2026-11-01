import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ──────────────────────────────────────────────────────────────
// Constants
// ──────────────────────────────────────────────────────────────

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, content-type, apikey, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const JSON_HEADERS = { ...CORS_HEADERS, "Content-Type": "application/json" };

/** Maximum characters allowed in the question field. */
const MAX_QUESTION_LENGTH = 500;

/** Max AI questions per user per calendar day (IST). */
const DAILY_LIMIT = 30;

/** Default OpenRouter model (overridden by AI_MODEL secret). */
const DEFAULT_MODEL = "meta-llama/llama-3.3-70b-instruct";

/** OpenRouter endpoint. */
const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";

/** System prompt embedded as a constant — never sent to logs. */
const SYSTEM_PROMPT = `You are Budget Buddy's AI coach inside a personal budgeting app for Indian users. Currency is ₹. Be friendly, practical and short (under 120 words). Reply in the user's language (English, Hindi, Hinglish or Kannada).
You receive a JSON summary of the user's data. It is all you can see. Totals are already calculated; use them and do not re-add raw rows.
You can help with: spending totals and breakdowns by category, this month vs last month, remaining budget per category, savings-goal progress and monthly saving needed, whether a purchase is affordable based on income, this month's expenses and goals, and 1-2 concrete tips at the end.
Rules: use only the data provided. If something is missing (a category with no data, EMIs, loans, bank balance), say so; never invent numbers. State the period you used and format amounts like ₹12,500. Give no stock, crypto or specific investment advice, only general concepts. You are not a licensed financial advisor. You can only read and advise; you cannot change data in the app.`;

// ──────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────

/** Returns a JSON Response with the given status. */
function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: JSON_HEADERS,
  });
}

/**
 * Returns today's date string in Asia/Kolkata (IST) as "YYYY-MM-DD".
 * Deno does not have a built-in Intl.DateTimeFormat with 'dateStyle',
 * so we format manually.
 */
function todayIST(): string {
  const now = new Date();
  // Offset IST = UTC+5:30
  const istOffsetMs = 5.5 * 60 * 60 * 1000;
  const ist = new Date(now.getTime() + istOffsetMs);
  const y = ist.getUTCFullYear();
  const m = String(ist.getUTCMonth() + 1).padStart(2, "0");
  const d = String(ist.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/**
 * Returns the first day of a given IST month offset.
 * offset=0 → this month, offset=-1 → last month.
 */
function firstOfMonthIST(offset: 0 | -1): string {
  const now = new Date();
  const istOffsetMs = 5.5 * 60 * 60 * 1000;
  const ist = new Date(now.getTime() + istOffsetMs);
  const year = ist.getUTCFullYear();
  const month = ist.getUTCMonth() + 1 + offset; // may be 0 → Dec of prev year
  const normalised = new Date(Date.UTC(year, month - 1, 1)); // JS Date handles roll-over
  const y = normalised.getUTCFullYear();
  const m = String(normalised.getUTCMonth() + 1).padStart(2, "0");
  return `${y}-${m}-01`;
}

/** Returns a string "YYYY-MM-DD" for the last day of the previous month (i.e. the day before firstOfMonthIST(0)). */
function lastOfLastMonthIST(): string {
  const first = new Date(firstOfMonthIST(0) + "T00:00:00Z");
  first.setUTCDate(first.getUTCDate() - 1);
  const y = first.getUTCFullYear();
  const m = String(first.getUTCMonth() + 1).padStart(2, "0");
  const d = String(first.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/** Rounds a number to the nearest whole rupee. */
function rupee(n: number): number {
  return Math.round(n);
}

/** Number of whole months between two ISO date strings (start inclusive). */
function monthsUntil(targetDateStr: string): number {
  const now = new Date();
  const istOffsetMs = 5.5 * 60 * 60 * 1000;
  const ist = new Date(now.getTime() + istOffsetMs);
  const target = new Date(targetDateStr + "T00:00:00Z");
  const diffMs = target.getTime() - ist.getTime();
  const diffMonths = diffMs / (1000 * 60 * 60 * 24 * 30.44);
  return Math.max(1, Math.ceil(diffMonths));
}

// ──────────────────────────────────────────────────────────────
// Main handler
// ──────────────────────────────────────────────────────────────

serve(async (req: Request): Promise<Response> => {
  // ── CORS preflight ──
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  // ── Only POST is allowed ──
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    // ── 1. Parse and validate request body ──
    let body: { question?: unknown; debug?: unknown };
    try {
      body = await req.json();
    } catch {
      return jsonResponse({ error: "Invalid JSON body" }, 400);
    }

    const question =
      typeof body.question === "string" ? body.question.trim() : "";
    if (!question) {
      return jsonResponse({ error: "question is required" }, 400);
    }
    if (question.length > MAX_QUESTION_LENGTH) {
      return jsonResponse(
        {
          error: `Question must be ${MAX_QUESTION_LENGTH} characters or fewer`,
        },
        400
      );
    }
    const debugRequested = body.debug === true;

    // ── 2. Authenticate caller — JWT is verified by Supabase (verify_jwt=true) ──
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

    // Create a user-scoped client — RLS applies automatically.
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    });

    const token = authHeader.replace(/^Bearer\s+/i, "");
    const { data: userData, error: userError } = await supabase.auth.getUser(token);
    if (userError || !userData?.user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }
    const userId = userData.user.id;

    // ── 3. Read secrets ──
    const openRouterKey = (Deno.env.get("OPENROUTER_API_KEY") ?? "").trim();
    if (!openRouterKey) {
      return jsonResponse(
        { error: "AI service is not configured. Contact support." },
        503
      );
    }
    const aiModel = Deno.env.get("AI_MODEL") ?? DEFAULT_MODEL;
    const debugModeEnabled = Deno.env.get("DEBUG_MODE") === "true";

    // ── 4. Rate limit: 30 questions per user per IST day ──
    const today = todayIST();
    const { data: usageRow, error: usageErr } = await supabase
      .from("ai_usage")
      .select("count")
      .eq("user_id", userId)
      .eq("day", today)
      .maybeSingle();

    if (usageErr) {
      // Log only the error message — never user data
      console.error("[ai-coach] ai_usage select error:", usageErr.message);
    }

    const currentCount: number = (usageRow?.count as number | null) ?? 0;
    if (currentCount >= DAILY_LIMIT) {
      return jsonResponse(
        {
          error:
            "You've reached your 30 questions for today. Come back tomorrow! 😊",
        },
        429
      );
    }

    // ── 5. Fetch user data in parallel (RLS scopes each query automatically) ──
    const thisMonthStart = firstOfMonthIST(0);
    const lastMonthStart = firstOfMonthIST(-1);
    const lastMonthEnd = lastOfLastMonthIST();

    const [
      profileResult,
      txResult,
      budgetResult,
      goalsResult,
      historyResult,
    ] = await Promise.all([
      // user profile
      supabase
        .from("user_profiles")
        .select("monthly_income, currency, language")
        .eq("id", userId)
        .maybeSingle(),

      // transactions for this + last calendar month with category names
      supabase
        .from("transactions")
        .select("type, amount, transaction_date, note, categories(name)")
        .eq("user_id", userId)
        .gte("transaction_date", lastMonthStart)
        .lte("transaction_date", lastOfLastMonthIST()) // will be augmented below
        .order("transaction_date", { ascending: false }),

      // budgets for this month
      supabase
        .from("budgets")
        .select("amount, period_month, categories(name)")
        .eq("user_id", userId)
        .gte("period_month", thisMonthStart)
        .lt(
          "period_month",
          // first of next month
          (() => {
            const d = new Date(thisMonthStart + "T00:00:00Z");
            d.setUTCMonth(d.getUTCMonth() + 1);
            return d.toISOString().slice(0, 10);
          })()
        ),

      // savings goals
      supabase
        .from("savings_goals")
        .select("title, target_amount, current_amount, target_date")
        .eq("user_id", userId),

      // last 6 chat messages oldest-first
      supabase
        .from("ai_chat_history")
        .select("role, content")
        .eq("user_id", userId)
        .order("created_at", { ascending: false })
        .limit(6),
    ]);

    // Also fetch this month's transactions in a second query since we need a
    // different date range. We re-run for the current month only.
    const txThisMonthResult = await supabase
      .from("transactions")
      .select("type, amount, transaction_date, note, categories(name)")
      .eq("user_id", userId)
      .gte("transaction_date", thisMonthStart)
      .order("transaction_date", { ascending: false });

    // Log only error messages — never row data
    if (profileResult.error) {
      console.error("[ai-coach] profile fetch:", profileResult.error.message);
    }
    if (txResult.error) {
      console.error("[ai-coach] tx last-month fetch:", txResult.error.message);
    }
    if (txThisMonthResult.error) {
      console.error(
        "[ai-coach] tx this-month fetch:",
        txThisMonthResult.error.message
      );
    }
    if (budgetResult.error) {
      console.error("[ai-coach] budget fetch:", budgetResult.error.message);
    }
    if (goalsResult.error) {
      console.error("[ai-coach] goals fetch:", goalsResult.error.message);
    }
    if (historyResult.error) {
      console.error("[ai-coach] history fetch:", historyResult.error.message);
    }

    // ── 6. Build context entirely in code ──

    const profile = profileResult.data ?? null;
    const txLastMonth: Array<Record<string, unknown>> =
      (txResult.data as Array<Record<string, unknown>> | null) ?? [];
    const txThisMonth: Array<Record<string, unknown>> =
      (txThisMonthResult.data as Array<Record<string, unknown>> | null) ?? [];
    const budgets: Array<Record<string, unknown>> =
      (budgetResult.data as Array<Record<string, unknown>> | null) ?? [];
    const goals: Array<Record<string, unknown>> =
      (goalsResult.data as Array<Record<string, unknown>> | null) ?? [];
    // History arrives newest-first; reverse to chronological order
    const history: Array<{ role: string; content: string }> =
      ((historyResult.data as Array<{ role: string; content: string }> | null) ??
        []).reverse();

    /** Helper: aggregate income/expense/by-category from a transaction array. */
    function aggregateTx(rows: Array<Record<string, unknown>>) {
      let income = 0;
      let expense = 0;
      const byCat: Record<string, number> = {};
      for (const r of rows) {
        const amt = rupee(Number(r.amount ?? 0));
        const catName =
          ((r.categories as Record<string, unknown> | null)?.name as
            | string
            | undefined) ?? "Uncategorized";
        if (r.type === "income") {
          income += amt;
        } else {
          expense += amt;
          byCat[catName] = (byCat[catName] ?? 0) + amt;
        }
      }
      return { income_total: rupee(income), expense_total: rupee(expense), expense_by_category: byCat };
    }

    const thisMonthAgg = aggregateTx(txThisMonth);
    const lastMonthAgg = aggregateTx(txLastMonth);

    // Top 5 expense categories this month
    const top5 = Object.entries(thisMonthAgg.expense_by_category)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([cat, amt]) => ({ category: cat, amount: amt }));

    // Budgets with spent amounts
    const budgetSummary = budgets.map((b) => {
      const catName =
        ((b.categories as Record<string, unknown> | null)?.name as
          | string
          | undefined) ?? "Overall";
      const budgeted = rupee(Number(b.amount ?? 0));
      const spent =
        thisMonthAgg.expense_by_category[catName] ?? 0;
      return {
        category: catName,
        budget: budgeted,
        spent: rupee(spent),
        remaining: rupee(budgeted - spent),
      };
    });

    // Goals with monthly need
    const goalSummary = goals.map((g) => {
      const target = rupee(Number(g.target_amount ?? 0));
      const saved = rupee(Number(g.current_amount ?? 0));
      const remaining = rupee(target - saved);
      const targetDate = (g.target_date as string | null) ?? null;
      const neededPerMonth = targetDate
        ? rupee(remaining / monthsUntil(targetDate))
        : null;
      return {
        title: g.title,
        target,
        saved,
        remaining,
        target_date: targetDate,
        needed_per_month: neededPerMonth,
      };
    });

    // Recent 15 transactions (this month first, then last month if needed)
    const allTx = [...txThisMonth, ...txLastMonth];
    const recent15 = allTx.slice(0, 15).map((r) => ({
      date: r.transaction_date,
      type: r.type,
      amount: rupee(Number(r.amount ?? 0)),
      category:
        ((r.categories as Record<string, unknown> | null)?.name as
          | string
          | undefined) ?? "Uncategorized",
      note: (r.note as string | null) ?? null,
    }));

    const context = {
      today: todayIST(),
      profile: {
        monthly_income: profile?.monthly_income != null
          ? rupee(Number(profile.monthly_income))
          : null,
        currency: (profile?.currency as string | null) ?? "INR",
        language: (profile?.language as string | null) ?? "en",
      },
      this_month: {
        ...thisMonthAgg,
        period: thisMonthStart.slice(0, 7),
      },
      last_month: {
        ...lastMonthAgg,
        period: lastMonthStart.slice(0, 7),
      },
      top_expense_categories_this_month: top5,
      budgets_this_month: budgetSummary,
      goals: goalSummary,
      recent_transactions: recent15,
    };

    // ── 7. Call OpenRouter with 25 s timeout ──
    const userMessageContent = JSON.stringify({
      data: context,
      question,
    });

    const openRouterMessages = [
      { role: "system", content: SYSTEM_PROMPT },
      // Inject chat history (oldest first, already reversed above)
      ...history.map((h) => ({ role: h.role, content: h.content })),
      // Current user message with full context
      { role: "user", content: userMessageContent },
    ];

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 25_000);

    let answer: string;
    let respondedModel = aiModel;
    try {
      const orResponse = await fetch(OPENROUTER_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${openRouterKey}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "https://budgetbuddy.app",
          "X-Title": "Budget Buddy",
        },
        body: JSON.stringify({
          model: aiModel,
          models: [
            aiModel,
            "meta-llama/llama-3.3-70b-instruct",
          ],
          route: "fallback",
          messages: openRouterMessages,
          max_tokens: 500,
          temperature: 0.3,
        }),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!orResponse.ok) {
        const errMsg = await orResponse.text().catch(() => "unknown");
        console.error(
          `[ai-coach] OpenRouter HTTP ${orResponse.status}:`,
          errMsg.slice(0, 200)
        );
        const errPayload: Record<string, unknown> = {
          error: "AI is unavailable, please try again",
        };
        if (debugRequested) {
          errPayload["detail"] = `OpenRouter HTTP ${orResponse.status}: ${errMsg}`;
        }
        return jsonResponse(errPayload, 502);
      }

      const orJson = await orResponse.json();
      const content = orJson?.choices?.[0]?.message?.content;
      if (typeof content !== "string" || !content.trim()) {
        console.error("[ai-coach] OpenRouter returned empty content");
        const errPayload: Record<string, unknown> = {
          error: "AI is unavailable, please try again",
        };
        if (debugRequested) {
          errPayload["detail"] = "OpenRouter returned empty content";
        }
        return jsonResponse(errPayload, 502);
      }
      answer = content.trim();
      respondedModel = orJson?.model ?? aiModel;
    } catch (fetchErr: unknown) {
      clearTimeout(timeoutId);
      const msg =
        fetchErr instanceof Error ? fetchErr.message : String(fetchErr);
      console.error("[ai-coach] OpenRouter fetch error:", msg);
      const errPayload: Record<string, unknown> = {
        error: "AI is unavailable, please try again",
      };
      if (debugRequested) {
        errPayload["detail"] = msg;
      }
      return jsonResponse(errPayload, 502);
    }

    // ── 8. Increment rate-limit counter (only after a successful AI response) ──
    try {
      if (currentCount === 0 && !usageRow) {
        // First question today — insert
        await supabase
          .from("ai_usage")
          .insert({ user_id: userId, day: today, count: 1 });
      } else {
        // Subsequent question — upsert to handle race conditions
        await supabase
          .from("ai_usage")
          .upsert(
            { user_id: userId, day: today, count: currentCount + 1 },
            { onConflict: "user_id,day" }
          );
      }
    } catch (rateErr: unknown) {
      const msg =
        rateErr instanceof Error ? rateErr.message : String(rateErr);
      console.error("[ai-coach] ai_usage update error:", msg);
      // Non-fatal — do not fail the request
    }

    // ── 9. Save conversation turn to ai_chat_history (non-fatal if it fails) ──
    try {
      await supabase.from("ai_chat_history").insert([
        { user_id: userId, role: "user", content: question },
        { user_id: userId, role: "assistant", content: answer },
      ]);
    } catch (saveErr: unknown) {
      const msg =
        saveErr instanceof Error ? saveErr.message : String(saveErr);
      console.error("[ai-coach] chat history save error:", msg);
    }

    // ── 10. Return answer (context only in full debug mode) ──
    const responseBody: Record<string, unknown> = {
      answer,
      model: respondedModel,
    };
    if (debugRequested && debugModeEnabled) {
      responseBody["context"] = context;
    }

    return jsonResponse(responseBody, 200);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("[ai-coach] Unhandled error:", msg);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});
