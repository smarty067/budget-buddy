# Privacy Policy (Template)

<!-- TODO: Legal review required for regulatory compliance (DPDP Act, GDPR) -->

## 1. Information We Collect
Budget Buddy collects only the information necessary to provide personal budgeting and coaching services:
- **Profile Information**: Email address (for authenticated accounts), stated monthly income, preferred currency, and language preference.
- **Financial Records**: Transactions (amount, category, date, and optional note), monthly budget allowances, savings targets, and saved loan details (principal, interest rate, tenure, EMI, and start date).
- **AI Chat History**: User questions asked to the AI Coach and the coach's replies.
- **Usage Metrics**: Daily question counts used to enforce fair usage limits.

Budget Buddy **does NOT** collect or access:
- Bank account numbers, IFSC codes, netbanking passwords, or UPI PINs.
- Bank SMS notifications, OTPs, or text messages.
- Credit scores, PAN numbers, or Aadhaar numbers.

## 2. How Your Data Is Stored
- **Guest Mode**: All transactions, budgets, goals, and loans remain stored locally on your device using encrypted local cache. No data is transmitted to remote database servers.
- **Authenticated Accounts**: Data is synchronized to a dedicated cloud database (Supabase) protected by Row Level Security (RLS). Under RLS, only your authenticated account can read, write, or modify your personal data.

## 3. How Data Is Used by the AI Coach
When you ask the AI Coach a question:
- The system looks up only the data sections necessary to answer that specific query.
- Your question and the relevant context are sent over an encrypted HTTPS connection to an AI model provider (such as OpenRouter) to generate the response.
- **Zero Data Retention**: The AI Coach operates without persistent prompt logging.
<!-- TODO: Verify and attach provider-specific Zero Data Retention (ZDR) policy agreement -->

## 4. How to Clear Chat History
You can delete your conversation history with the AI Coach at any time:
1. Open the **AI Coach** screen.
2. Tap the **Clear Chat** icon in the top app bar.
3. Confirm by tapping **Clear**. All messages in your conversation history will be permanently deleted.

## 5. Account Deletion and Data Retention
<!-- TODO: Verify whether full automated cloud account deletion is exposed in the app UI or handled via email -->
- Guest users can delete all local data immediately by navigating to **Settings > Account > Clear Guest Data**.
- Authenticated users can request deletion of their account and all associated cloud records by contacting support.

## 6. Contact Information
For privacy inquiries, data deletion requests, or support:
<!-- TODO: Set support contact email address -->
support@budgetbuddy.app

