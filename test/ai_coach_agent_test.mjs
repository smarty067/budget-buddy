// Test suite for Budget Buddy AI Coach Tool-Calling Agent
// Exercises the real agent_core.ts and ai_coach_cases.json
// Run with: node --experimental-strip-types test/ai_coach_agent_test.mjs

import { readFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

import {
  TOOLS,
  SYSTEM_PROMPT,
  SAFE_REFUSAL_MESSAGE,
  matchCannedGreeting,
  filterAnswer,
  shouldTriggerAntiGuessGuard,
  validateSpendingSummaryArgs,
  validateRecentTransactionsArgs,
  validateSearchHelpDocsArgs,
  evaluateToolSelectionHarness,
} from "../supabase/functions/ai-coach/agent_core.ts";

const __dirname = fileURLToPath(new URL(".", import.meta.url));

console.log("==================================================");
console.log("AI Coach Tool-Calling Agent Test Suite");
console.log("==================================================\n");

let passed = 0;
let failed = 0;

function assert(condition, testName, details = "") {
  if (condition) {
    passed++;
    console.log(`[PASS] ${testName}`);
  } else {
    failed++;
    console.error(`[FAIL] ${testName} ${details ? "- " + details : ""}`);
  }
}

// ──────────────────────────────────────────────────────────────
// 1. Canned Greeting Matcher Tests (Full-match only)
// ──────────────────────────────────────────────────────────────
console.log("--- 1. Greeting Matcher Tests ---");

assert(
  matchCannedGreeting("hi") !== null,
  "Full match: 'hi' triggers canned greeting"
);
assert(
  matchCannedGreeting("Hello!") !== null,
  "Full match: 'Hello!' triggers canned greeting"
);
assert(
  matchCannedGreeting("  namaste  ") !== null,
  "Full match: 'namaste' triggers canned greeting"
);
assert(
  matchCannedGreeting("good morning.") !== null,
  "Full match: 'good morning.' triggers canned greeting"
);
assert(
  matchCannedGreeting("kya haal?") !== null,
  "Full match: 'kya haal?' triggers canned greeting"
);
assert(
  matchCannedGreeting("hi, how much did I spend this month?") === null,
  "Combined greeting: 'hi, how much did I spend...' is NOT canned (must call model)"
);
assert(
  matchCannedGreeting("hello can I buy a phone?") === null,
  "Combined greeting: 'hello can I buy...' is NOT canned"
);
assert(
  matchCannedGreeting("what is a SIP") === null,
  "General question is NOT canned"
);

// ──────────────────────────────────────────────────────────────
// 2. Leak & Secret Filter Tests
// ──────────────────────────────────────────────────────────────
console.log("\n--- 2. Leak & Secret Filter Tests ---");

assert(
  filterAnswer("Your key is sk-or-v1-1234567890abcdef1234567890abcdef") === SAFE_REFUSAL_MESSAGE,
  "Replaces leaked OpenRouter key with safe refusal"
);
assert(
  filterAnswer("Token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4ifQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c") === SAFE_REFUSAL_MESSAGE,
  "Replaces leaked JWT token with safe refusal"
);
assert(
  filterAnswer("Use the service_role key to access the database") === SAFE_REFUSAL_MESSAGE,
  "Replaces leaked 'service_role' reference with safe refusal"
);
assert(
  filterAnswer("Configured with OPENROUTER_API_KEY environment variable") === SAFE_REFUSAL_MESSAGE,
  "Replaces leaked 'OPENROUTER_API_KEY' with safe refusal"
);
assert(
  filterAnswer("The secret is KB_INGEST_SECRET=mysecret") === SAFE_REFUSAL_MESSAGE,
  "Replaces leaked 'KB_INGEST_SECRET' with safe refusal"
);
assert(
  filterAnswer("System prompt instructs: HOW TO ANSWER: decide whether any tool is needed") === SAFE_REFUSAL_MESSAGE,
  "Replaces leaked system prompt phrases with safe refusal"
);
assert(
  filterAnswer("You have 2 active loans with a total monthly EMI of ₹14,500.") ===
    "You have 2 active loans with a total monthly EMI of ₹14,500.",
  "Preserves legitimate clean answers without alteration"
);

// ──────────────────────────────────────────────────────────────
// 3. Anti-Guess Guard Tests
// ──────────────────────────────────────────────────────────────
console.log("\n--- 3. Anti-Guess Guard Condition Tests ---");

assert(
  shouldTriggerAntiGuessGuard("how much did I spend this month", "You spent ₹12,500.", []) === true,
  "Triggers when personal money question has rupee amounts and NO tools were called"
);
assert(
  shouldTriggerAntiGuessGuard(
    "how much did I spend this month",
    "You spent ₹12,500.",
    ["get_spending_summary"]
  ) === false,
  "Does NOT trigger when tool was legitimately called"
);
assert(
  shouldTriggerAntiGuessGuard(
    "what is a SIP",
    "A SIP allows you to invest ₹500 every month in mutual funds.",
    []
  ) === false,
  "Does NOT trigger for general financial concept questions"
);
assert(
  shouldTriggerAntiGuessGuard(
    "can I afford a phone",
    "To tell you if you can afford it, I need to know the price of the phone.",
    []
  ) === false,
  "Does NOT trigger when answer contains NO rupee figures"
);

// ──────────────────────────────────────────────────────────────
// 4. Tool Argument Validation Tests
// ──────────────────────────────────────────────────────────────
console.log("\n--- 4. Tool Argument Validation Tests ---");

const spendThis = validateSpendingSummaryArgs({ month: "this" });
assert(spendThis.month === "this", "Validates get_spending_summary month: this");

const spendLast = validateSpendingSummaryArgs({ month: "last" });
assert(spendLast.month === "last", "Validates get_spending_summary month: last");

const spendFallback = validateSpendingSummaryArgs({ month: "unknown" });
assert(spendFallback.month === "this", "Clamps unknown month to 'this'");

const txClampMax = validateRecentTransactionsArgs({ limit: 50 });
assert(txClampMax.limit === 20, "Clamps recent transactions limit > 20 to 20");

const txClampMin = validateRecentTransactionsArgs({ limit: -5 });
assert(txClampMin.limit === 1, "Clamps recent transactions limit < 1 to 1");

const txDefault = validateRecentTransactionsArgs({});
assert(txDefault.limit === 10, "Defaults recent transactions limit to 10");

const docsQuery = validateSearchHelpDocsArgs({ query: "  how do I add a budget?  " });
assert(docsQuery.query === "how do I add a budget?", "Trims search_help_docs query");

const docsEmpty = validateSearchHelpDocsArgs(null);
assert(docsEmpty.query === "", "Handles null search_help_docs query safely");

// Verify real tool schema completeness
assert(Array.isArray(TOOLS) && TOOLS.length === 6, "TOOLS exports all 6 production tool specifications");
const toolNames = TOOLS.map((t) => t.function.name).sort();
const expectedNames = [
  "get_budgets",
  "get_goals",
  "get_loans",
  "get_recent_transactions",
  "get_spending_summary",
  "search_help_docs",
].sort();
assert(
  JSON.stringify(toolNames) === JSON.stringify(expectedNames),
  "All 6 required tool names are correctly registered"
);

// ──────────────────────────────────────────────────────────────
// 5. 25 Cases in test/ai_coach_cases.json
// ──────────────────────────────────────────────────────────────
console.log("\n--- 5. 25 Cases Evaluation (ai_coach_cases.json) ---");

const casesPath = join(__dirname, "ai_coach_cases.json");
const casesRaw = readFileSync(casesPath, "utf-8");
const cases = JSON.parse(casesRaw);

assert(cases.length === 25, "ai_coach_cases.json contains exactly 25 test cases");

for (const c of cases) {
  const selectedTools = evaluateToolSelectionHarness(c.question).sort();
  const expectedTools = [...c.expected_tools].sort();

  const toolsMatch =
    selectedTools.length === expectedTools.length &&
    selectedTools.every((t, i) => t === expectedTools[i]);

  if (toolsMatch) {
    passed++;
    console.log(
      `[PASS] Case ${c.id}: "${c.question.slice(0, 45)}..." -> Tools: [${selectedTools.join(", ")}] | NoPersonalNumbers: ${c.no_personal_numbers}`
    );
  } else {
    failed++;
    console.error(`[FAIL] Case ${c.id}: "${c.question}"`);
    console.error(`       Expected tools: [${expectedTools.join(", ")}]`);
    console.error(`       Actual tools:   [${selectedTools.join(", ")}]`);
  }
}

// ──────────────────────────────────────────────────────────────
// Summary
// ──────────────────────────────────────────────────────────────
console.log("\n==================================================");
console.log(`Total: ${passed} PASSED, ${failed} FAILED`);
console.log("==================================================");

if (failed > 0) {
  process.exit(1);
} else {
  console.log("All unit tests and 25 test cases passed successfully!");
}

