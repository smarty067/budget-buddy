#!/usr/bin/env node

/**
 * Budget Buddy Knowledge Base Ingestion Script (Node 18+)
 *
 * Reads user-facing markdown documents from docs/kb/*.md (skipping files starting with '_')
 * and sends them to the kb-ingest Edge Function for embedding and vector storage.
 *
 * Requirements:
 * - Environment variable KB_INGEST_URL (e.g. https://<project>.supabase.co/functions/v1/kb-ingest)
 * - Environment variable KB_INGEST_SECRET (shared secret matching remote function)
 *
 * Usage:
 *   node scripts/ingest-kb.mjs
 */

import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, basename, extname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const KB_DIR = join(__dirname, "..", "docs", "kb");

// 1. Read environment variables
const ingestUrl = (process.env.KB_INGEST_URL ?? "").trim();
const ingestSecret = (process.env.KB_INGEST_SECRET ?? "").trim();

if (!ingestUrl || !ingestSecret) {
  console.error("❌ Error: Missing required environment variables.");
  console.error("Please set KB_INGEST_URL and KB_INGEST_SECRET before running this script.");
  console.error("\nExample:");
  console.error("  $env:KB_INGEST_URL=\"https://<project-ref>.supabase.co/functions/v1/kb-ingest\"");
  console.error("  $env:KB_INGEST_SECRET=\"<your-secret>\"");
  console.error("  node scripts/ingest-kb.mjs\n");
  process.exit(1);
}

// 2. Discover .md files in docs/kb/ (skip any file starting with '_')
let files = [];
try {
  files = readdirSync(KB_DIR)
    .filter((f) => extname(f).toLowerCase() === ".md")
    .filter((f) => !basename(f).startsWith("_"));
} catch (err) {
  console.error(`❌ Failed to read directory ${KB_DIR}:`, err.message);
  process.exit(1);
}

if (files.length === 0) {
  console.warn("⚠️ No markdown files found to ingest in docs/kb/.");
  process.exit(0);
}

console.log(`Found ${files.length} knowledge base documents to ingest:`);
for (const file of files) {
  console.log(`  - ${file}`);
}

// 3. Read document contents
const docs = files.map((file) => {
  const fullPath = join(KB_DIR, file);
  const content = readFileSync(fullPath, "utf-8");
  return {
    source: file,
    content,
  };
});

// 4. Post documents to kb-ingest function (one document per request to respect edge compute limits)
console.log(`\nPosting documents to ${ingestUrl}...`);

let totalChunks = 0;
const processed = [];

for (const doc of docs) {
  try {
    const response = await fetch(ingestUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-ingest-secret": ingestSecret,
      },
      body: JSON.stringify({ docs: [doc] }),
    });

    const responseText = await response.text();
    let json;
    try {
      json = JSON.parse(responseText);
    } catch {
      json = null;
    }

    if (!response.ok) {
      console.error(`❌ Ingestion failed for ${doc.source} with HTTP ${response.status}:`);
      console.error(json?.error ?? responseText.slice(0, 300));
      process.exit(1);
    }

    const count = json?.chunks_inserted ?? 0;
    totalChunks += count;
    processed.push(doc.source);
    console.log(`  ✓ ${doc.source} (${count} chunks)`);
  } catch (err) {
    console.error(`❌ Network or request error while calling kb-ingest for ${doc.source}:`, err.message);
    process.exit(1);
  }
}

console.log("\n✅ Ingestion completed successfully!");
console.log(`   Sources processed: ${processed.length}`);
console.log(`   Total chunks created: ${totalChunks}`);

