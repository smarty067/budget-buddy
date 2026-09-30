import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../supabase_client.dart';

/// AI Coach service — calls the secure `ai-coach` Supabase Edge Function powered by OpenRouter.
/// Supports both authenticated users and guest users with local fallback.
class AiService {
  AiService._();

  /// Default OpenRouter model
  static const defaultModel = 'openai/gpt-4o-mini';

  /// Optional direct OpenRouter API key passed via `--dart-define=OPENROUTER_API_KEY=...`
  static const _envOpenRouterKey = String.fromEnvironment('OPENROUTER_API_KEY');

  /// Send a message to the AI Coach and get a response.
  static Future<String> sendMessage({
    required String message,
    String? quickPromptType,
    bool isGuest = false,
    List<Map<String, dynamic>> transactionContext = const [],
    List<Map<String, String>> conversationHistory = const [],
  }) async {
    // 1. Try invoking the Supabase Edge Function
    try {
      final response = await SupabaseClientHelper.client.functions.invoke(
        'ai-coach',
        body: {
          'message': message,
          'messages': conversationHistory,
          'quick_prompt_type': quickPromptType,
          'model': defaultModel,
          'transaction_context': transactionContext,
        },
      );

      if (response.status == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data['reply'] != null && (data['reply'] as String).isNotEmpty) {
            return data['reply'] as String;
          }
        }
      }
    } catch (e) {
      debugPrint('[AiService] Supabase Edge Function invoke failed: $e');
    }

    // 2. Direct OpenRouter fallback if API key is provided at build time
    if (_envOpenRouterKey.isNotEmpty) {
      try {
        return await _callOpenRouterDirect(
          message: message,
          conversationHistory: conversationHistory,
          transactionContext: transactionContext,
        );
      } catch (e) {
        debugPrint('[AiService] Direct OpenRouter fallback failed: $e');
      }
    }

    // 3. Graceful offline/mock response so the user experience is delightful even without cloud secrets
    return _generateLocalSmartAdvice(message, quickPromptType, transactionContext);
  }

  /// Direct OpenRouter API call for local testing or backup
  static Future<String> _callOpenRouterDirect({
    required String message,
    required List<Map<String, String>> conversationHistory,
    required List<Map<String, dynamic>> transactionContext,
  }) async {
    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

    final txText = _formatTransactions(transactionContext);
    final systemPrompt =
        'You are Budget Buddy, an empathetic and smart personal finance coach for users in India. '
        'Provide concise, actionable advice using ₹ and Indian financial terminology. '
        '${txText.isNotEmpty ? "\n\nUser Transactions:\n$txText" : ""}';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...conversationHistory,
      {'role': 'user', 'content': message},
    ];

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_envOpenRouterKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://budgetbuddy.app',
        'X-Title': 'Budget Buddy',
      },
      body: jsonEncode({
        'model': defaultModel,
        'messages': messages,
        'max_tokens': 450,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final reply = data['choices']?[0]?['message']?['content'] as String?;
      if (reply != null && reply.isNotEmpty) {
        return reply;
      }
    }
    throw Exception('OpenRouter response status: ${response.statusCode}');
  }

  static String _formatTransactions(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) return '';
    final buffer = StringBuffer();
    for (final t in transactions.take(15)) {
      final type = t['type'] ?? 'expense';
      final amount = t['amount'] ?? 0;
      final category =
          t['categories']?['name'] ?? t['category_name'] ?? 'General';
      final date = t['transaction_date'] ?? '';
      final note = t['note'] != null && t['note'].toString().isNotEmpty
          ? ' (${t['note']})'
          : '';
      buffer.writeln('- $type: ₹$amount for $category on $date$note');
    }
    return buffer.toString();
  }

  /// High-quality financial logic fallback when offline or before keys are set
  static String _generateLocalSmartAdvice(
    String message,
    String? quickPromptType,
    List<Map<String, dynamic>> transactions,
  ) {
    final lower = message.toLowerCase();

    if (quickPromptType == 'spending_analysis' || lower.contains('spend') || lower.contains('analysis')) {
      double totalExpense = 0;
      double totalIncome = 0;
      for (final t in transactions) {
        final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
        if (t['type'] == 'expense') totalExpense += amt;
        if (t['type'] == 'income') totalIncome += amt;
      }

      if (totalExpense > 0 || totalIncome > 0) {
        final savingsRate = totalIncome > 0
            ? (((totalIncome - totalExpense) / totalIncome) * 100).toStringAsFixed(1)
            : '0';
        return '📊 **Monthly Spending Overview**\n\n'
            '• **Total Inflow:** ₹${totalIncome.toStringAsFixed(0)}\n'
            '• **Total Outflow:** ₹${totalExpense.toStringAsFixed(0)}\n'
            '• **Estimated Savings Rate:** $savingsRate%\n\n'
            '💡 **Pro Tip:** Try following the **50/30/20 Rule** (50% Needs, 30% Wants, 20% Savings/Investments) to grow your wealth steadily!';
      }
      return '📊 **Spending Analysis Tip**\n\n'
          'To optimize your monthly budget:\n'
          '1. Categorize all fixed costs (Rent, EMIs, Utilities) under **Needs** (aim for < 50%).\n'
          '2. Cap discretionary dining & shopping to **30%**.\n'
          '3. Automatically funnel **20%** into an SIP or recurring deposit at the start of each month.';
    }

    if (quickPromptType == 'savings_tips' || lower.contains('save') || lower.contains('tips')) {
      return '💰 **Top 3 High-Impact Savings Habits:**\n\n'
          '1. **Pay Yourself First:** Automate transfers to a separate savings/mutual fund account on salary day.\n'
          '2. **The 48-Hour Rule:** Wait 48 hours before non-essential purchases above ₹1,500 to curb impulse buys.\n'
          '3. **Emergency Fund:** Keep 3 to 6 months of living expenses in an instant liquid fund or sweep FD.';
    }

    if (lower.contains('emi') || lower.contains('loan')) {
      return '🏦 **Smart Loan & EMI Strategy:**\n\n'
          '• Keep total monthly EMIs strictly under **40% of net monthly income**.\n'
          '• Making just **1 extra EMI payment per year** can reduce a 20-year home loan by 3-4 years and save lakhs in interest!\n'
          '• Check our built-in **EMI Calculator** in the menu to test repayment terms and interest rates.';
    }

    if (lower.contains('invest') || lower.contains('sip') || lower.contains('mutual fund') || lower.contains('gold')) {
      return '📈 **Investment Essentials for Indian Investors:**\n\n'
          '• **SIP in Nifty 50 / Large & Midcap Index:** Historically yields ~12-14% CAGR over 7+ years.\n'
          '• **PPF / EPF:** Tax-free interest (EEE status) and sovereign security.\n'
          '• **Gold / SGB:** Great hedge against inflation with 2.5% annual coupon.\n'
          '• Diversify across equity, debt, and emergency reserves!';
    }

    return '✨ **Welcome to Budget Buddy Coach!**\n\n'
        'I\'m ready to help analyze your finances, plan EMIs, or structure your monthly budget. '
        'You can ask me questions like:\n'
        '• *"How much should I invest in SIP every month?"*\n'
        '• *"Can I afford an EMI of ₹15,000?"*\n'
        '• *"How can I build an emergency fund quickly?"*';
  }

  /// Fetch chat history for the current user from Supabase.
  static Future<List<Map<String, dynamic>>> getChatHistory({
    int limit = 20,
  }) async {
    try {
      final response = await SupabaseClientHelper.client
          .from('ai_chat_history')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }
}
