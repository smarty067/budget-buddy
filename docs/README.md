# Budget Buddy Documentation & Knowledge Base

This directory contains the knowledge base documents used by Budget Buddy's AI Coach and development team.

## Directory Structure
- `docs/kb/ai_coach.md`: Architecture, privacy guardrails, intent routing keywords, and context sections for the AI Coach.
- `docs/kb/loans.md`: Loans and EMI module details, schema, reducing-balance formulas, and user workflows.

## Re-Ingestion Instructions (Local Only)
To re-index or validate the knowledge base documents without deploying or pushing to databases:

1. **Verify markdown syntax:**
   ```bash
   # Check formatting and broken links
   npx markdownlint-cli "docs/kb/*.md"
   ```

2. **Run local parser dry-run:**
   ```bash
   # Dry-run parsing script
   node -e "console.log('Docs verified:', fs.readdirSync('docs/kb'))"
   ```

3. **Check changes:**
   ```bash
   git status docs/
   ```

