// Test suite for AI Coach Intent Router (20 test questions)
// Runs with: node test/ai_coach_intent_test.js

const GREETING_REGEX =
  /^\s*(hi|hello|hey|namaste|namaskara|kem cho|vanakkam|pranam|good (morning|afternoon|evening)|kya haal|sup|yo|hola)\b/i;

const LOANS_KEYWORDS = [
  "loan", "loans", "emi", "emis", "karz", "udhar", "udhār", "interest rate",
  "tenure", "borrow", "borrowing", "lending", "debt", "debts", "repay",
  "repayment", "prepayment", "pre-payment", "amortization", "car loan",
  "home loan", "personal loan", "bike loan", "gold loan", "credit card bill",
];

const BUDGETS_KEYWORDS = [
  "budget", "budgets", "allocated", "limit", "quota", "overbudget",
  "over-budget", "overspend", "overspent", "remaining budget", "budget limit",
  "bache paise", "budget bacha", "left in", "bache hue"
];

const GOALS_KEYWORDS = [
  "goal", "goals", "savings goal", "savings goals", "target", "targets",
  "save for", "saving for", "sapna", "bachat", "emergency fund", "nest egg",
];

const LAST_MONTH_KEYWORDS = [
  "last month", "pichle mahine", "pichla mahina", "previous month",
  "past month", "pichla", "last mo",
];

const THIS_MONTH_KEYWORDS = [
  "this month", "current month", "is mahine", "iss mahine", "aaj", "today",
  "spending", "spent", "kharcha", "kharch", "expense", "expenses", "income",
  "kamai", "salary", "tankhwah", "afford", "buy", "purchase",
  "phone", "gadget", "shopping", "cost", "can i", "should i buy", "le sakta",
  "kharid", "le lu",
];

const RECENT_KEYWORDS = [
  "recent", "transactions", "passbook", "statement", "latest",
  "last transaction", "aakhri transaction", "recent spends", "recent purchases",
];

const HOW_TO_KEYWORDS = [
  "how to", "how do i", "how can i", "kaise kare", "kaise karun",
  "help", "kya karu", "where is", "guide", "steps to", "add a budget",
  "add budget", "create budget", "add transaction", "save loan",
];

function matchesKeywords(text, keywords) {
  const lower = text.toLowerCase();
  return keywords.some((kw) => lower.includes(kw));
}

function isPureGreeting(text) {
  const trimmed = text.trim();
  const words = trimmed.split(/\s+/);
  return words.length <= 4 && GREETING_REGEX.test(trimmed);
}

function routeIntent(query) {
  const sections = new Set();
  const lower = query.toLowerCase();

  const isLoan = matchesKeywords(lower, LOANS_KEYWORDS);
  const isBudget = matchesKeywords(lower, BUDGETS_KEYWORDS);
  const isGoal = matchesKeywords(lower, GOALS_KEYWORDS);
  const isLastMonth = matchesKeywords(lower, LAST_MONTH_KEYWORDS);
  const isThisMonth = matchesKeywords(lower, THIS_MONTH_KEYWORDS);
  const isRecent = matchesKeywords(lower, RECENT_KEYWORDS);

  if (isLoan) {
    sections.add("loans");
    sections.add("profile");
  }

  if (isBudget) {
    sections.add("budgets");
    sections.add("month");
  }

  if (isGoal) {
    sections.add("goals");
    sections.add("profile");
  }

  if (isLastMonth) {
    sections.add("lastmonth");
    sections.add("profile");
  }

  // Add 'month' when question relates to current spends / income / affordability,
  // but if exclusively asking about last month without comparing, don't add month.
  if (isThisMonth) {
    const mentionsThisMonth =
      lower.includes("this month") ||
      lower.includes("is mahine") ||
      lower.includes("iss mahine") ||
      lower.includes("today") ||
      lower.includes("aaj") ||
      lower.includes("afford") ||
      lower.includes("buy") ||
      lower.includes("purchase");
    if (!isLastMonth || mentionsThisMonth) {
      sections.add("month");
      sections.add("profile");
    }
  }

  if (isRecent) {
    sections.add("recent");
  }

  return sections;
}

function resolveIntent(question, previousUserMessage = null) {
  const isGreeting = isPureGreeting(question);
  if (isGreeting) return [];

  let sections = routeIntent(question);
  const words = question.split(/\s+/).filter(Boolean);

  // Follow-up heuristic: if under 6 words with no match, use previous user message
  if (sections.size === 0 && words.length < 6 && previousUserMessage) {
    const followUp = routeIntent(previousUserMessage);
    for (const s of followUp) {
      sections.add(s);
    }
  }

  // Fallback for unmatched questions
  if (sections.size === 0) {
    sections = new Set(["profile", "month"]);
  }

  return Array.from(sections).sort();
}

// ──────────────────────────────────────────────────────────────
// 20 Test Questions Suite
// ──────────────────────────────────────────────────────────────
const testSuite = [
  {
    id: 1,
    question: "hi",
    expected: [],
    note: "Pure greeting -> data-free",
  },
  {
    id: 2,
    question: "can I afford a ₹15,000 phone",
    expected: ["month", "profile"],
    note: "Affordability check -> current month spends & profile income",
  },
  {
    id: 3,
    question: "how much EMI do I pay",
    expected: ["loans", "profile"],
    note: "Loan EMI inquiry -> loans & profile income",
  },
  {
    id: 4,
    question: "how do I add a budget",
    expected: ["budgets", "month"],
    note: "Budget setup how-to -> budgets & month",
  },
  {
    id: 5,
    question: "and last month?",
    prev: "can I afford a ₹15,000 phone",
    expected: ["lastmonth", "profile"],
    note: "Follow-up under 6 words for previous month comparison",
  },
  {
    id: 6,
    question: "what are my active loans and interest rates?",
    expected: ["loans", "profile"],
    note: "Direct loans inquiry",
  },
  {
    id: 7,
    question: "how much did I spend this month?",
    expected: ["month", "profile"],
    note: "Current month spending inquiry",
  },
  {
    id: 8,
    question: "pichle mahine kitna kharcha hua tha?",
    expected: ["lastmonth", "profile"],
    note: "Hinglish last month spending inquiry",
  },
  {
    id: 9,
    question: "am I over budget in Dining Out?",
    expected: ["budgets", "month"],
    note: "Category budget check",
  },
  {
    id: 10,
    question: "how much more do I need to save for my emergency fund goal?",
    expected: ["goals", "profile"],
    note: "Savings goal tracking",
  },
  {
    id: 11,
    question: "show my recent transactions",
    expected: ["recent"],
    note: "Recent transactions passbook",
  },
  {
    id: 12,
    question: "namaste! kya haal hai?",
    expected: [],
    note: "Hinglish pure greeting -> data-free",
  },
  {
    id: 13,
    question: "mera car loan ka EMI kitna bacha hai?",
    expected: ["loans", "profile"],
    note: "Hinglish loan EMI balance query",
  },
  {
    id: 14,
    question: "can I buy a laptop for ₹60,000?",
    expected: ["month", "profile"],
    note: "Affordability query",
  },
  {
    id: 15,
    question: "how to create a savings goal in the app",
    expected: ["goals", "profile"],
    note: "Goal how-to question",
  },
  {
    id: 16,
    question: "how much total debt do I have?",
    expected: ["loans", "profile"],
    note: "Total debt query -> loans",
  },
  {
    id: 17,
    question: "did I overspend on Groceries this month?",
    expected: ["budgets", "month", "profile"],
    validator: (actual) => actual.includes("budgets") && actual.includes("month"),
    note: "Overspend & budget limit check",
  },
  {
    id: 18,
    question: "what is my monthly salary and income?",
    expected: ["month", "profile"],
    note: "Income profile query",
  },
  {
    id: 19,
    question: "last transaction kya tha?",
    expected: ["recent"],
    note: "Recent transactions query",
  },
  {
    id: 20,
    question: "what about it?",
    prev: "how much EMI do I pay",
    expected: ["loans", "profile"],
    note: "Follow-up under 6 words with NO match -> adopts previous message context",
  },
];

console.log("==================================================");
console.log("Running AI Coach Intent Router 20-Question Test Suite");
console.log("==================================================\n");

let passed = 0;
let failed = 0;

for (const t of testSuite) {
  const actual = resolveIntent(t.question, t.prev ?? null);
  let isOk = false;

  if (t.validator) {
    isOk = t.validator(actual);
  } else {
    isOk =
      actual.length === t.expected.length &&
      actual.every((val, idx) => val === t.expected[idx]);
  }

  if (isOk) {
    passed++;
    console.log(`[PASS] Q${t.id}: "${t.question}" -> [${actual.join(", ")}]`);
  } else {
    failed++;
    console.error(`[FAIL] Q${t.id}: "${t.question}"`);
    console.error(`       Expected: [${t.expected.join(", ")}]`);
    console.error(`       Actual:   [${actual.join(", ")}]`);
  }
}

console.log("\n==================================================");
console.log(`Summary: ${passed}/20 PASSED, ${failed}/20 FAILED`);
console.log("==================================================");

if (failed > 0) {
  process.exit(1);
} else {
  console.log("All 20 intent tests passed successfully!");
}
