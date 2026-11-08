# Items to Verify (Internal Technical Backlog)

This document tracks features, policies, or technical assumptions that require further review before production release.

## 1. Automated Account Deletion for Authenticated Users
- **Current Code Behavior**: The app provides a "Clear Guest Data" button in Settings > Account that wipes local Hive boxes for guest sessions. However, for authenticated users, there is no self-serve "Delete Account" button in the Flutter UI.
- **Action Required**: Decide whether to implement a self-serve `supabase.rpc('delete_user_account')` function or provide a manual support email procedure in the Privacy Policy.

## 2. Remote AI Provider Zero Data Retention (ZDR)
- **Current Code Behavior**: The `ai-coach` Edge Function routes requests to OpenRouter models (`meta-llama/llama-3.3-70b-instruct` and `google/gemma-4-26b-a4b-it:free`).
- **Action Required**: Verify whether the OpenRouter account organization has Zero Data Retention (ZDR) contractually enforced, and ensure endpoints without ZDR certifications are disabled in production.

## 3. Multi-Currency Support Beyond INR
- **Current Code Behavior**: `user_profiles` stores a `currency` code (e.g. `INR`), but Flutter UI number formatting and symbols use hardcoded Indian Rupees (`₹`) and Lakh/Crore grouping (`#,##,###`).
- **Action Required**: Confirm if multi-currency (USD, EUR, GBP) is in scope for v1.

## 4. Supabase Vector Similarity Threshold
- **Current Code Behavior**: `match_kb_chunks` sets `min_similarity default 0.55`.
- **Action Required**: Benchmark retrieval recall and precision on user queries once knowledge base embeddings are generated with GTE-Small to fine-tune the similarity cutoff.

