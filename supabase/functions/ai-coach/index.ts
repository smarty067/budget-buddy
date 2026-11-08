import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

export {
  MAX_QUESTION_LENGTH,
  DAILY_LIMIT,
  DEFAULT_MODEL,
  OPENROUTER_URL,
  SUPPORT_EMAIL,
  SYSTEM_PROMPT,
  CANNED_GREETING_REGEX,
  matchCannedGreeting,
  filterAnswer,
  isPersonalMoneyQuestion,
  hasRupeeAmount,
  shouldTriggerAntiGuessGuard,
  TOOLS,
  validateSpendingSummaryArgs,
  validateRecentTransactionsArgs,
  validateSearchHelpDocsArgs,
  evaluateToolSelectionHarness,
} from "./agent_core.ts";

import {
  MAX_QUESTION_LENGTH,
  DAILY_LIMIT,
  DEFAULT_MODEL,
  OPENROUTER_URL,
  SYSTEM_PROMPT,
  matchCannedGreeting,
  filterAnswer,
  shouldTriggerAntiGuessGuard,
  TOOLS,
  validateSpendingSummaryArgs,
  validateRecentTransactionsArgs,
  validateSearchHelpDocsArgs,
} from "./agent_core.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, content-type, apikey, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const JSON_HEADERS = { ...CORS_HEADERS, "Content-Type": "application/json" };

// ──────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: JSON_HEADERS,
  });
}

/** Formats today's date in Asia/Kolkata (IST) as "YYYY-MM-DD". */
export function todayIST(): string {
  const now = new Date();
  const istOffsetMs = 5.5 * 60 * 60 * 1000;
  const ist = new Date(now.getTime() + istOffsetMs);
  const y = ist.getUTCFullYear();
  const m = String(ist.getUTCMonth() + 1).padStart(2, "0");
  const d = String(ist.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/** Returns the first day of an IST month offset (0 = this month, -1 = last month). */
export function firstOfMonthIST(offset: 0 | -1): string {
  const now = new Date();
  const istOffsetMs = 5.5 * 60 * 60 * 1000;
  const ist = new Date(now.getTime() + istOffsetMs);
  const year = ist.getUTCFullYear();
  const month = ist.getUTCMonth() + 1 + offset;
  const normalised = new Date(Date.UTC(year, month - 1, 1));
  const y = normalised.getUTCFullYear();
  const m = String(normalised.getUTCMonth() + 1).padStart(2, "0");
  return `${y}-${m}-01`;
}

/** Returns the last day of the previous calendar month in IST as "YYYY-MM-DD". */
export function lastOfLastMonthIST(): string {
  const first = new Date(firstOfMonthIST(0) + "T00:00:00Z");
  first.setUTCDate(first.getUTCDate() - 1);
  const y = first.getUTCFullYear();
  const m = String(first.getUTCMonth() + 1).padStart(2, "0");
  const d = String(first.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/** Rounds amount to the nearest whole rupee. */
export function rupee(n: number): number {
  return Math.round(n);
}

/** Calculates calendar months between two dates in IST. */
export function monthsUntil(targetDateStr: string): number {
  const now = new Date();
  const istOffsetMs = 5.5 * 60 * 60 * 1000;
  const ist = new Date(now.getTime() + istOffsetMs);
  const target = new Date(targetDateStr + "T00:00:00Z");
  const diffMs = target.getTime() - ist.getTime();
  const diffMonths = diffMs / (1000 * 60 * 60 * 24 * 30.44);
  return Math.max(1, Math.ceil(diffMonths));
}

// ──────────────────────────────────────────────────────────────
// Tool Implementations (User-scoped Supabase client)
// ──────────────────────────────────────────────────────────────

async function executeGetSpendingSummary(
  supabase: any,
  userId: string,
  args: unknown
): Promise<Record<string, unknown>> {
  try {
    const { month } = validateSpendingSummaryArgs(args);
    const startDate = month === "this" ? firstOfMonthIST(0) : firstOfMonthIST(-1);
    const endDate = month === "this" ? todayIST() : lastOfLastMonthIST();

    const { data: rows, error } = await supabase
      .from("transactions")
      .select("type, amount, transaction_date, categories(name)")
      .eq("user_id", userId)
      .gte("transaction_date", startDate)
      .lte("transaction_date", endDate)
      .order("transaction_date", { ascending: false });

    if (error) {
      return { error: `Failed to fetch transactions: ${error.message}` };
    }

    let incomeTotal = 0;
    let expenseTotal = 0;
    const byCategory: Record<string, number> = {};

    for (const r of rows ?? []) {
      const amt = rupee(Number(r.amount ?? 0));
      const cat = r.categories?.name ?? "Uncategorized";
      if (r.type === "income") {
        incomeTotal += amt;
      } else {
        expenseTotal += amt;
        byCategory[cat] = (byCategory[cat] ?? 0) + amt;
      }
    }

    const top5 = Object.entries(byCategory)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([category, amount]) => ({ category, amount }));

    return {
      month: month === "this" ? "current_month" : "last_month",
      period_start: startDate,
      period_end: endDate,
      income_total: rupee(incomeTotal),
      expense_total: rupee(expenseTotal),
      expense_by_category: byCategory,
      top_5_expense_categories: top5,
    };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return { error: msg };
  }
}

async function executeGetBudgets(
  supabase: any,
  userId: string
): Promise<Record<string, unknown>> {
  try {
    const thisMonthStart = firstOfMonthIST(0);
    const nextMonthDate = new Date(thisMonthStart + "T00:00:00Z");
    nextMonthDate.setUTCMonth(nextMonthDate.getUTCMonth() + 1);
    const nextMonthStart = nextMonthDate.toISOString().slice(0, 10);

    const [budgetsRes, txRes] = await Promise.all([
      supabase
        .from("budgets")
        .select("amount, period_month, categories(name)")
        .eq("user_id", userId)
        .gte("period_month", thisMonthStart)
        .lt("period_month", nextMonthStart),
      supabase
        .from("transactions")
        .select("amount, categories(name)")
        .eq("user_id", userId)
        .eq("type", "expense")
        .gte("transaction_date", thisMonthStart),
    ]);

    if (budgetsRes.error) {
      return { error: `Failed to fetch budgets: ${budgetsRes.error.message}` };
    }

    const spentByCat: Record<string, number> = {};
    for (const tx of txRes.data ?? []) {
      const cat = tx.categories?.name ?? "Uncategorized";
      spentByCat[cat] = (spentByCat[cat] ?? 0) + rupee(Number(tx.amount ?? 0));
    }

    const budgets = (budgetsRes.data ?? []).map((b: any) => {
      const category = b.categories?.name ?? "Overall";
      const budget = rupee(Number(b.amount ?? 0));
      const spent = spentByCat[category] ?? 0;
      return {
        category,
        budget,
        spent: rupee(spent),
        remaining: rupee(budget - spent),
      };
    });

    return {
      period: thisMonthStart.slice(0, 7),
      budgets,
    };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return { error: msg };
  }
}

async function executeGetGoals(
  supabase: any,
  userId: string
): Promise<Record<string, unknown>> {
  try {
    const { data: rows, error } = await supabase
      .from("savings_goals")
      .select("title, target_amount, current_amount, target_date")
      .eq("user_id", userId);

    if (error) {
      return { error: `Failed to fetch savings goals: ${error.message}` };
    }

    const goals = (rows ?? []).map((g: any) => {
      const target = rupee(Number(g.target_amount ?? 0));
      const saved = rupee(Number(g.current_amount ?? 0));
      const remaining = rupee(Math.max(0, target - saved));
      const targetDate = g.target_date ?? null;
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

    return { goals };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return { error: msg };
  }
}

async function executeGetLoans(
  supabase: any,
  userId: string
): Promise<Record<string, unknown>> {
  try {
    const today = todayIST();

    const [loansRes, profileRes] = await Promise.all([
      supabase
        .from("loans")
        .select("id, name, principal, interest_rate, emi_amount, tenure_months, start_date, status")
        .eq("user_id", userId)
        .eq("status", "active")
        .order("created_at", { ascending: false }),
      supabase
        .from("user_profiles")
        .select("monthly_income")
        .eq("id", userId)
        .maybeSingle(),
    ]);

    if (loansRes.error) {
      return { error: `Failed to fetch loans: ${loansRes.error.message}` };
    }

    const monthlyIncome = profileRes.data?.monthly_income != null
      ? rupee(Number(profileRes.data.monthly_income))
      : null;

    let totalMonthlyEmi = 0;
    let totalEstimatedOutstanding = 0;

    const items = (loansRes.data ?? []).map((l: any) => {
      const principal = rupee(Number(l.principal ?? 0));
      const annualRate = Number(l.interest_rate ?? 0);
      const emi = rupee(Number(l.emi_amount ?? 0));
      const tenure = Number(l.tenure_months ?? 0);
      const startDate = l.start_date ?? today;

      const sYear = parseInt(startDate.slice(0, 4), 10);
      const sMonth = parseInt(startDate.slice(5, 7), 10);
      const tYear = parseInt(today.slice(0, 4), 10);
      const tMonth = parseInt(today.slice(5, 7), 10);
      const rawElapsed = (tYear - sYear) * 12 + (tMonth - sMonth);

      let outstanding = principal;
      let monthsLeft = tenure;

      if (rawElapsed <= 0) {
        // Future start date or first month
        outstanding = principal;
        monthsLeft = tenure;
      } else if (rawElapsed >= tenure) {
        // Completed tenure
        outstanding = 0;
        monthsLeft = 0;
      } else {
        monthsLeft = Math.max(0, tenure - rawElapsed);
        const r = (annualRate / 12) / 100;
        if (r === 0 || annualRate <= 0) {
          // Straight-line deduction for 0% loans
          outstanding = Math.max(0, principal - (emi * rawElapsed));
        } else {
          // Reducing-balance formula
          const factor = Math.pow(1 + r, rawElapsed);
          const bal = principal * factor - (emi * (factor - 1)) / r;
          outstanding = Math.max(0, rupee(bal));
        }
      }

      totalMonthlyEmi += emi;
      totalEstimatedOutstanding += outstanding;

      return {
        id: l.id,
        name: l.name,
        principal,
        interest_rate: annualRate,
        emi_amount: emi,
        tenure_months: tenure,
        start_date: startDate,
        months_left: monthsLeft,
        estimated_outstanding: outstanding,
      };
    });

    const emiPctOfIncome = monthlyIncome && monthlyIncome > 0
      ? Number(((totalMonthlyEmi / monthlyIncome) * 100).toFixed(1))
      : null;

    return {
      active_loans_count: items.length,
      total_monthly_emi: rupee(totalMonthlyEmi),
      total_estimated_outstanding: rupee(totalEstimatedOutstanding),
      emi_as_pct_of_income: emiPctOfIncome,
      loans: items,
      note: "Loan outstanding balances are mathematical estimates assuming all scheduled EMIs were paid on time.",
    };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return { error: msg };
  }
}

async function executeGetRecentTransactions(
  supabase: any,
  userId: string,
  args: unknown
): Promise<Record<string, unknown>> {
  try {
    const { limit } = validateRecentTransactionsArgs(args);
    const { data: rows, error } = await supabase
      .from("transactions")
      .select("type, amount, transaction_date, note, categories(name)")
      .eq("user_id", userId)
      .order("transaction_date", { ascending: false })
      .limit(limit);

    if (error) {
      return { error: `Failed to fetch recent transactions: ${error.message}` };
    }

    const txs = (rows ?? []).map((r: any) => ({
      date: r.transaction_date,
      type: r.type,
      amount: rupee(Number(r.amount ?? 0)),
      category: r.categories?.name ?? "Uncategorized",
      note: r.note ?? null,
    }));

    return {
      count: txs.length,
      transactions: txs,
    };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return { error: msg };
  }
}

async function executeSearchHelpDocs(
  supabase: any,
  args: unknown
): Promise<Record<string, unknown>> {
  try {
    const { query } = validateSearchHelpDocsArgs(args);
    if (!query) {
      return { matches: [], note: "Query was empty" };
    }

    // Embed query using native Supabase.ai.Session with GTE-Small
    // @ts-ignore: Supabase.ai is provided in Edge runtime
    const ai = (globalThis as any).Supabase?.ai;
    if (!ai?.Session) {
      return { error: "Search help docs embedding unavailable in runtime" };
    }

    const session = new ai.Session("gte-small");
    const embedding = await session.run(query, {
      mean_pool: true,
      normalize: true,
    });

    const { data: matches, error } = await supabase.rpc("match_kb_chunks", {
      query_embedding: Array.from(embedding),
      match_count: 3,
      min_similarity: 0.55,
    });

    if (error) {
      return { error: `Vector search failed: ${error.message}` };
    }

    const results = (matches ?? []).map((m: any) => ({
      title: m.title,
      content: m.content,
    }));

    return { matches: results };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return { error: msg };
  }
}

/** Dispatches a tool call by name and returns stringified JSON result truncated to 6000 chars. */
async function dispatchTool(
  name: string,
  args: unknown,
  supabase: any,
  userId: string
): Promise<string> {
  let result: Record<string, unknown>;

  switch (name) {
    case "get_spending_summary":
      result = await executeGetSpendingSummary(supabase, userId, args);
      break;
    case "get_budgets":
      result = await executeGetBudgets(supabase, userId);
      break;
    case "get_goals":
      result = await executeGetGoals(supabase, userId);
      break;
    case "get_loans":
      result = await executeGetLoans(supabase, userId);
      break;
    case "get_recent_transactions":
      result = await executeGetRecentTransactions(supabase, userId, args);
      break;
    case "search_help_docs":
      result = await executeSearchHelpDocs(supabase, args);
      break;
    default:
      result = { error: `Unknown tool: ${name}` };
  }

  const jsonStr = JSON.stringify(result);
  return jsonStr.slice(0, 6000);
}

// ──────────────────────────────────────────────────────────────
// Agent Loop (Up to 3 Tool Rounds)
// ──────────────────────────────────────────────────────────────

interface ChatMessage {
  role: "system" | "user" | "assistant" | "tool";
  content?: string | null;
  tool_calls?: any[];
  tool_call_id?: string;
  name?: string;
}

async function runAgentLoop({
  messages,
  openRouterKey,
  aiModel,
  supabase,
  userId,
  forceToolChoice = "auto",
}: {
  messages: ChatMessage[];
  openRouterKey: string;
  aiModel: string;
  supabase: any;
  userId: string;
  forceToolChoice?: "auto" | "required" | "none";
}): Promise<{
  answer: string;
  toolsCalled: string[];
  modelUsed: string;
}> {
  const toolsCalledSet = new Set<string>();
  const workingMessages = [...messages];
  let finalAnswer = "";
  let modelUsed = aiModel;

  // Up to 3 tool rounds
  for (let round = 0; round < 3; round++) {
    const isLastRound = round === 2;
    // On round 2 (last round), force a final text answer
    let toolChoice: "auto" | "required" | "none" = isLastRound
      ? "none"
      : (round === 0 ? forceToolChoice : "auto");

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 25_000);

    let orResponse: Response;
    try {
      orResponse = await fetch(OPENROUTER_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${openRouterKey}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "https://budgetbuddy.app",
          "X-Title": "Budget Buddy",
        },
        body: JSON.stringify({
          model: aiModel,
          models: [aiModel, DEFAULT_MODEL],
          route: "fallback",
          messages: workingMessages,
          tools: TOOLS,
          tool_choice: toolChoice,
          max_tokens: 500,
          temperature: 0.2,
        }),
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timeoutId);
    }

    if (!orResponse.ok) {
      const errText = await orResponse.text().catch(() => "unknown");
      throw new Error(`OpenRouter HTTP ${orResponse.status}: ${errText.slice(0, 200)}`);
    }

    const orJson = await orResponse.json();
    modelUsed = orJson?.model ?? aiModel;
    const choice = orJson?.choices?.[0];
    const message = choice?.message;

    if (!message) {
      throw new Error("OpenRouter returned empty message");
    }

    // Check for tool calls
    if (message.tool_calls && Array.isArray(message.tool_calls) && message.tool_calls.length > 0) {
      workingMessages.push(message);

      // Max 4 tool calls per round
      const toolCalls = message.tool_calls.slice(0, 4);

      for (const tc of toolCalls) {
        const toolName = tc.function?.name ?? "";
        toolsCalledSet.add(toolName);

        let parsedArgs: unknown = {};
        try {
          parsedArgs = JSON.parse(tc.function?.arguments ?? "{}");
        } catch {
          parsedArgs = {};
        }

        const toolResult = await dispatchTool(toolName, parsedArgs, supabase, userId);

        workingMessages.push({
          role: "tool",
          tool_call_id: tc.id,
          content: toolResult,
        });
      }

      // Continue to next round so model can inspect tool results
      continue;
    }

    // Text answer produced
    if (typeof message.content === "string" && message.content.trim()) {
      finalAnswer = message.content.trim();
      break;
    }
  }

  // If no final text answer was produced after 3 rounds, force 1 final synthesis call
  if (!finalAnswer) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 25_000);
    try {
      const finalRes = await fetch(OPENROUTER_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${openRouterKey}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "https://budgetbuddy.app",
          "X-Title": "Budget Buddy",
        },
        body: JSON.stringify({
          model: aiModel,
          models: [aiModel, DEFAULT_MODEL],
          route: "fallback",
          messages: workingMessages,
          tools: TOOLS,
          tool_choice: "none",
          max_tokens: 500,
          temperature: 0.2,
        }),
        signal: controller.signal,
      });

      if (finalRes.ok) {
        const finalJson = await finalRes.json();
        finalAnswer = (finalJson?.choices?.[0]?.message?.content ?? "").trim();
      }
    } finally {
      clearTimeout(timeoutId);
    }
  }

  return {
    answer: finalAnswer || "I couldn't process your request just now, please try again.",
    toolsCalled: Array.from(toolsCalledSet),
    modelUsed,
  };
}

// ──────────────────────────────────────────────────────────────
// Main HTTP Handler
// ──────────────────────────────────────────────────────────────

serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    // 1. Validate request body
    let body: { question?: unknown; debug?: unknown };
    try {
      body = await req.json();
    } catch {
      return jsonResponse({ error: "Invalid JSON body" }, 400);
    }

    const question = typeof body.question === "string" ? body.question.trim() : "";
    if (!question) {
      return jsonResponse({ error: "question is required" }, 400);
    }
    if (question.length > MAX_QUESTION_LENGTH) {
      return jsonResponse(
        { error: `Question must be ${MAX_QUESTION_LENGTH} characters or fewer` },
        400
      );
    }
    const debugRequested = body.debug === true;

    // 2. Canned Greeting Shortcut (full match only; no data, no rate-limit use)
    const cannedGreeting = matchCannedGreeting(question);
    if (cannedGreeting) {
      const payload: Record<string, unknown> = {
        answer: cannedGreeting,
        model: "canned_response",
      };
      if (debugRequested && Deno.env.get("DEBUG_MODE") === "true") {
        payload.tools_called = [];
      }
      return jsonResponse(payload, 200);
    }

    // 3. Authenticate caller (user-scoped JWT client, never service role)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

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

    // 4. Read secrets & check rate limits
    const openRouterKey = (Deno.env.get("OPENROUTER_API_KEY") ?? "").trim();
    if (!openRouterKey) {
      return jsonResponse({ error: "AI service is not configured. Contact support." }, 503);
    }
    const aiModel = Deno.env.get("AI_MODEL") ?? DEFAULT_MODEL;
    const debugModeEnabled = Deno.env.get("DEBUG_MODE") === "true";

    const today = todayIST();
    const { data: usageRow } = await supabase
      .from("ai_usage")
      .select("count")
      .eq("user_id", userId)
      .eq("day", today)
      .maybeSingle();

    const currentCount = (usageRow?.count as number | null) ?? 0;
    if (currentCount >= DAILY_LIMIT) {
      return jsonResponse(
        { error: "You've reached your 30 questions for today. Come back tomorrow! 😊" },
        429
      );
    }

    // 5. Fetch previous conversation history (oldest first)
    const { data: historyRows } = await supabase
      .from("ai_chat_history")
      .select("role, content")
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .limit(6);

    const history: ChatMessage[] = (historyRows ?? [])
      .reverse()
      .map((h: any) => ({ role: h.role, content: h.content }));

    const initialMessages: ChatMessage[] = [
      { role: "system", content: SYSTEM_PROMPT },
      ...history,
      { role: "user", content: question },
    ];

    // 6. Run Agent Loop
    let agentResult = await runAgentLoop({
      messages: initialMessages,
      openRouterKey,
      aiModel,
      supabase,
      userId,
      forceToolChoice: "auto",
    });

    // 7. Anti-Guess Guard
    // If personal money question + rupee amounts in answer + no tool was called:
    if (shouldTriggerAntiGuessGuard(question, agentResult.answer, agentResult.toolsCalled)) {
      console.warn("[ai-coach] Anti-guess guard triggered. Retrying with tool_choice: required.");
      const retryMessages: ChatMessage[] = [
        ...initialMessages,
        {
          role: "system",
          content: "You must use the provided tools to check real user data before citing specific rupee amounts.",
        },
      ];

      agentResult = await runAgentLoop({
        messages: retryMessages,
        openRouterKey,
        aiModel,
        supabase,
        userId,
        forceToolChoice: "required",
      });

      // If it still has amounts and no tool was called, return safe fallback
      if (shouldTriggerAntiGuessGuard(question, agentResult.answer, agentResult.toolsCalled)) {
        agentResult.answer = "I couldn't check your data just now, please try again.";
      }
    }

    // 8. Answer Leak & Secret Filter
    const sanitizedAnswer = filterAnswer(agentResult.answer);

    // 9. Increment Rate-Limit Counter (only after successful AI answer)
    try {
      if (currentCount === 0 && !usageRow) {
        await supabase
          .from("ai_usage")
          .insert({ user_id: userId, day: today, count: 1 });
      } else {
        await supabase
          .from("ai_usage")
          .upsert(
            { user_id: userId, day: today, count: currentCount + 1 },
            { onConflict: "user_id,day" }
          );
      }
    } catch (rateErr: unknown) {
      const msg = rateErr instanceof Error ? rateErr.message : String(rateErr);
      console.error("[ai-coach] ai_usage update error:", msg);
    }

    // 10. Save conversation turn to ai_chat_history
    try {
      await supabase.from("ai_chat_history").insert([
        { user_id: userId, role: "user", content: question },
        { user_id: userId, role: "assistant", content: sanitizedAnswer },
      ]);
    } catch (saveErr: unknown) {
      const msg = saveErr instanceof Error ? saveErr.message : String(saveErr);
      console.error("[ai-coach] chat history save error:", msg);
    }

    // 11. Format final HTTP response
    const responseBody: Record<string, unknown> = {
      answer: sanitizedAnswer,
      model: agentResult.modelUsed,
    };

    if (debugRequested && debugModeEnabled) {
      responseBody.tools_called = agentResult.toolsCalled;
    }

    return jsonResponse(responseBody, 200);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("[ai-coach] Unhandled error:", msg);
    return jsonResponse({ error: "AI is unavailable, please try again" }, 502);
  }
});
