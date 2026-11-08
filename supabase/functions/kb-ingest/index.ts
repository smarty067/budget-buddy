import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-ingest-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const JSON_HEADERS = { ...CORS_HEADERS, "Content-Type": "application/json" };

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: JSON_HEADERS,
  });
}

/** Parses markdown into section chunks split by `## ` headings. */
function splitMarkdownByHeadings(content: string, defaultSource: string): Array<{ title: string; content: string }> {
  const lines = content.split("\n");
  const chunks: Array<{ title: string; content: string }> = [];

  let currentTitle = "Overview";
  let currentLines: string[] = [];

  // Extract top-level `# Title` if present
  for (const line of lines) {
    if (line.startsWith("# ") && !line.startsWith("## ")) {
      const topTitle = line.replace(/^#\s+/, "").trim();
      if (topTitle) currentTitle = topTitle;
      break;
    }
  }

  for (const line of lines) {
    if (line.startsWith("## ")) {
      // Save previous section if it has meaningful content
      const body = currentLines.join("\n").trim();
      if (body) {
        chunks.push({ title: currentTitle, content: body });
      }
      currentTitle = line.replace(/^##\s+/, "").trim();
      currentLines = [];
    } else {
      currentLines.push(line);
    }
  }

  // Push remaining section
  const lastBody = currentLines.join("\n").trim();
  if (lastBody) {
    chunks.push({ title: currentTitle, content: lastBody });
  }

  // If no sections were extracted, fallback to single document chunk
  if (chunks.length === 0 && content.trim()) {
    chunks.push({ title: defaultSource, content: content.trim() });
  }

  return chunks;
}

serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    // 1. Authenticate via x-ingest-secret header
    const expectedSecret = (Deno.env.get("KB_INGEST_SECRET") ?? "").trim();
    if (!expectedSecret) {
      console.error("[kb-ingest] KB_INGEST_SECRET environment variable is not configured.");
      return jsonResponse({ error: "Ingest service not configured" }, 503);
    }

    const providedSecret = req.headers.get("x-ingest-secret")?.trim();
    if (!providedSecret || providedSecret !== expectedSecret) {
      return jsonResponse({ error: "Forbidden: invalid ingest secret" }, 403);
    }

    if (req.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405);
    }

    // 2. Parse request payload
    let payload: { docs?: unknown };
    try {
      payload = await req.json();
    } catch {
      return jsonResponse({ error: "Invalid JSON body" }, 400);
    }

    if (!payload || !Array.isArray(payload.docs) || payload.docs.length === 0) {
      return jsonResponse({ error: "Body must contain a non-empty 'docs' array" }, 400);
    }

    const docs = payload.docs as Array<{ source?: unknown; content?: unknown }>;

    // 3. Service role Supabase client for admin writes
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseUrl || !supabaseServiceKey) {
      return jsonResponse({ error: "Missing Supabase service configuration" }, 500);
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { persistSession: false },
    });

    // 4. Initialize embedding session with GTE-Small
    // @ts-ignore: Supabase.ai is injected in the Supabase Edge runtime
    const ai = (globalThis as any).Supabase?.ai;
    if (!ai?.Session) {
      console.error("[kb-ingest] Supabase.ai.Session is not available in this runtime");
      return jsonResponse({ error: "Embedding model unavailable in runtime" }, 500);
    }

    const session = new ai.Session("gte-small");

    let totalInserted = 0;
    const processedSources: string[] = [];

    // 5. Ingest each document
    for (const doc of docs) {
      const source = typeof doc.source === "string" ? doc.source.trim() : "";
      const rawContent = typeof doc.content === "string" ? doc.content : "";

      if (!source || !rawContent.trim()) {
        continue;
      }

      // Delete existing chunks for this source (idempotent replacement)
      const { error: deleteErr } = await supabase
        .from("kb_chunks")
        .delete()
        .eq("source", source);

      if (deleteErr) {
        console.error(`[kb-ingest] Failed to delete existing chunks for ${source}:`, deleteErr.message);
        return jsonResponse({ error: `Database error clearing ${source}: ${deleteErr.message}` }, 500);
      }

      // Split into ## sections
      const sections = splitMarkdownByHeadings(rawContent, source);
      const rowsToInsert: Array<{
        source: string;
        title: string;
        content: string;
        embedding: number[];
      }> = [];

      for (const sec of sections) {
        const textToEmbed = `${sec.title}\n${sec.content}`.slice(0, 2000);
        const embedding = await session.run(textToEmbed, {
          mean_pool: true,
          normalize: true,
        });

        rowsToInsert.push({
          source,
          title: sec.title,
          content: sec.content,
          embedding: Array.from(embedding),
        });
      }

      if (rowsToInsert.length > 0) {
        const { error: insertErr } = await supabase
          .from("kb_chunks")
          .insert(rowsToInsert);

        if (insertErr) {
          console.error(`[kb-ingest] Failed to insert chunks for ${source}:`, insertErr.message);
          return jsonResponse({ error: `Database error inserting ${source}: ${insertErr.message}` }, 500);
        }

        totalInserted += rowsToInsert.length;
        processedSources.push(source);
      }
    }

    return jsonResponse({
      success: true,
      sources_processed: processedSources,
      chunks_inserted: totalInserted,
    }, 200);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("[kb-ingest] Unhandled error:", msg);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});

