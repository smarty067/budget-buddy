import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    // Get user from token
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized access" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Parse request body
    const { message, quick_prompt_type } = await req.json();
    if (!message) {
      return new Response(
        JSON.stringify({ error: "Message is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Get GEMINI API key from Env
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiApiKey) {
      return new Response(
        JSON.stringify({ error: "AI service configuration missing" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Retrieve recent user transaction context to feed to Gemini
    const { data: transactions } = await supabaseClient
      .from("transactions")
      .select("amount, type, category_id, transaction_date, note, categories(name)")
      .order("transaction_date", { ascending: false })
      .limit(15);

    let transactionContext = "";
    if (transactions && transactions.length > 0) {
      transactionContext = "\n\nHere is the user's recent transaction history:\n" +
        transactions.map((t: any) => {
          const catName = t.categories?.name ?? "Other";
          return `- ${t.type.toUpperCase()}: ₹${t.amount} for ${catName} on ${t.transaction_date}${t.note ? ` (${t.note})` : ""}`;
        }).join("\n");
    }

    // 5. Call Gemini API
    const model = "gemini-1.5-flash";
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiApiKey}`;

    const prompt = `You are Budget Buddy, a premium financial coach. Provide concise, friendly financial advice tailored for Indian users using Rupee (₹).
Keep your answers brief, actionable, and formatted nicely. Avoid overly technical jargon.
Your response must be relevant to their query and transaction history.${transactionContext}

User query: ${message}`;

    const geminiResponse = await fetch(geminiUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { maxOutputTokens: 350, temperature: 0.7 }
      })
    });

    if (!geminiResponse.ok) {
      const errText = await geminiResponse.text();
      console.error("Gemini API error:", errText);
      throw new Error("Failed to generate AI response");
    }

    const geminiJson = await geminiResponse.json();
    const reply = geminiJson.candidates?.[0]?.content?.parts?.[0]?.text ?? "I couldn't process that request.";

    // 6. Log transaction/chat history (Optional, ignores if table not present)
    try {
      await supabaseClient.from("ai_chat_history").insert({
        user_id: user.id,
        user_message: message,
        ai_response: reply,
        quick_prompt_type: quick_prompt_type ?? null
      });
    } catch (e) {
      console.warn("Could not write to ai_chat_history table:", e.message);
    }

    return new Response(
      JSON.stringify({ reply }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
