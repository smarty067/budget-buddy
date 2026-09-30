import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-title, http-referer",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  // CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Parse request body
    const reqBody = await req.json().catch(() => ({}));
    const {
      message,
      messages: conversationHistory,
      quick_prompt_type,
      model = "openai/gpt-4o-mini",
      transaction_context: clientTxContext,
    } = reqBody;

    if (!message && (!conversationHistory || conversationHistory.length === 0)) {
      return new Response(
        JSON.stringify({ error: "Message or messages array is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Extract auth & Supabase client (optional for guest users)
    const authHeader = req.headers.get("Authorization");
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    let user: any = null;
    let supabaseClient: any = null;

    if (supabaseUrl && supabaseAnonKey && authHeader) {
      try {
        supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
          global: { headers: { Authorization: authHeader } },
        });
        const { data: userData } = await supabaseClient.auth.getUser();
        user = userData?.user ?? null;
      } catch (e) {
        console.warn("Auth check error (proceeding as guest):", e);
      }
    }

    // 3. Resolve OpenRouter / AI API Key
    const openRouterApiKey = Deno.env.get("OPENROUTER_API_KEY") || Deno.env.get("GEMINI_API_KEY");
    if (!openRouterApiKey) {
      return new Response(
        JSON.stringify({
          error: "AI service configuration missing. Please set OPENROUTER_API_KEY in Supabase secrets.",
          reply: "I am currently undergoing scheduled maintenance. Please check back shortly! 🌟"
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Build Financial Context
    let transactionContextStr = "";
    if (clientTxContext && typeof clientTxContext === "string") {
      transactionContextStr = "\n\nUser Transaction Context:\n" + clientTxContext;
    } else if (Array.isArray(clientTxContext) && clientTxContext.length > 0) {
      transactionContextStr = "\n\nUser Recent Transactions:\n" +
        clientTxContext.map((t: any) => {
          const type = t.type ?? "expense";
          const amt = t.amount ?? 0;
          const cat = t.category_name ?? t.categories?.name ?? "Other";
          const date = t.transaction_date ?? "";
          const note = t.note ? ` (${t.note})` : "";
          return `- ${type.toUpperCase()}: ₹${amt} for ${cat} on ${date}${note}`;
        }).join("\n");
    } else if (user && supabaseClient) {
      try {
        const { data: transactions } = await supabaseClient
          .from("transactions")
          .select("amount, type, category_id, transaction_date, note, categories(name)")
          .order("transaction_date", { ascending: false })
          .limit(15);

        if (transactions && transactions.length > 0) {
          transactionContextStr = "\n\nUser Recent Transactions:\n" +
            transactions.map((t: any) => {
              const catName = t.categories?.name ?? "Other";
              return `- ${t.type.toUpperCase()}: ₹${t.amount} for ${catName} on ${t.transaction_date}${t.note ? ` (${t.note})` : ""}`;
            }).join("\n");
        }
      } catch (e) {
        console.warn("Failed to fetch user transactions for context:", e);
      }
    }

    // 5. Build system prompt & messages array for OpenRouter
    const systemPrompt = `You are Budget Buddy, an empathetic, smart, and ultra-practical AI Financial Coach for users in India (including Tier-2 and Tier-3 cities).
Key guidelines:
- Use Indian Rupee (₹) and Indian numbering system (Lakhs, Crores, Thousands) when relevant.
- Give crisp, actionable, encouraging advice on budgeting, 50/30/20 rule, emergency funds, debt repayment, SIPs, and smart saving.
- Keep responses concise, structured with bullet points or bold highlights. Avoid long walls of text.
- If asked about loans or EMIs, explain how interest tenure impacts total cost.
- If asked about investments, explain low-risk options (FD, PPF, Sovereign Gold Bonds, Index Funds/SIP) plainly.
${transactionContextStr}`;

    const apiMessages: Array<{ role: string; content: string }> = [
      { role: "system", content: systemPrompt }
    ];

    if (Array.isArray(conversationHistory) && conversationHistory.length > 0) {
      for (const m of conversationHistory) {
        if (m.role && m.content) {
          apiMessages.push({
            role: m.role === "assistant" ? "assistant" : "user",
            content: m.content
          });
        }
      }
    } else if (message) {
      apiMessages.push({ role: "user", content: message });
    }

    // 6. Call OpenRouter API
    const openRouterUrl = "https://openrouter.ai/api/v1/chat/completions";
    const openRouterResponse = await fetch(openRouterUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${openRouterApiKey}`,
        "Content-Type": "application/json",
        "HTTP-Referer": "https://budgetbuddy.app",
        "X-Title": "Budget Buddy",
      },
      body: JSON.stringify({
        model: model,
        messages: apiMessages,
        max_tokens: 500,
        temperature: 0.7,
      }),
    });

    if (!openRouterResponse.ok) {
      const errText = await openRouterResponse.text();
      console.error("OpenRouter API error response:", errText);
      throw new Error(`OpenRouter API error (${openRouterResponse.status}): ${errText}`);
    }

    const json = await openRouterResponse.json();
    const reply = json.choices?.[0]?.message?.content ?? "I couldn't generate a response. Please try again.";

    // 7. Save to ai_chat_history if user is logged in
    if (user && supabaseClient && message) {
      try {
        await supabaseClient.from("ai_chat_history").insert([
          { user_id: user.id, role: "user", content: message },
          { user_id: user.id, role: "assistant", content: reply },
        ]);
      } catch (e: any) {
        console.warn("Could not save to ai_chat_history:", e?.message || e);
      }
    }

    return new Response(
      JSON.stringify({ reply, model: json.model ?? model }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    console.error("Unhandled error in ai-coach function:", error);
    return new Response(
      JSON.stringify({
        error: error.message || "Internal server error",
        reply: "I'm having a temporary hiccup connecting to the coaching servers. Please try again in a moment! 🌟"
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
