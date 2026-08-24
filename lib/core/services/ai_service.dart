import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../supabase_client.dart';

/// AI Coach service — calls the secure `ai-coach` Supabase Edge Function.
/// Falls back to a direct Gemini API call using a Dart-env API key during
/// local development if the Edge Function is unavailable.
class AiService {
  AiService._();

  /// The Gemini model to use for direct API calls.
  static const _model = 'gemini-1.5-flash';

  /// Dart environment key (passed via --dart-define=GEMINI_API_KEY=...).
  static const _envApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Send a message to the AI Coach and get a response.
  ///
  /// For authenticated users the call goes through the Supabase Edge Function
  /// which has its own server-side GEMINI_API_KEY. If the Edge Function is
  /// unreachable and a local API key was provided, we fall back to a direct
  /// HTTP POST to the Gemini REST API.
  ///
  /// Guest users will only get a response if [_envApiKey] is available.
  static Future<String> sendMessage({
    required String message,
    String? quickPromptType,
    bool isGuest = false,
    List<Map<String, dynamic>> transactionContext = const [],
  }) async {
    // ── Try Edge Function first (for authenticated users) ──
    if (!isGuest) {
      try {
        final response = await SupabaseClientHelper.client.functions.invoke(
          'ai-coach',
          body: {
            'message': message,
            'quick_prompt_type': quickPromptType,
          },
        );

        if (response.status == 200) {
          final data = response.data as Map<String, dynamic>;
          return data['reply'] as String? ?? 'No response from AI.';
        }
      } catch (e) {
        debugPrint('[AiService] Edge Function unavailable, trying fallback.');
      }
    }

    // ── Fallback: Direct Gemini API call with local key ──
    if (_envApiKey.isNotEmpty) {
      return _callGeminiDirect(
        message: message,
        transactionContext: transactionContext,
      );
    }

    // ── No key available ──
    if (isGuest) {
      return 'AI Coach requires an account to analyze your finances. '
          'Sign up to unlock personalized insights! 🔒';
    }

    return 'The AI Coach is being configured. '
        'Please try again in a moment. 🌟';
  }

  /// Direct Gemini REST API call — used as fallback only.
  static Future<String> _callGeminiDirect({
    required String message,
    List<Map<String, dynamic>> transactionContext = const [],
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_envApiKey',
    );

    // Build context from transactions
    final contextStr = transactionContext.isNotEmpty
        ? '\n\nUser\'s recent financial data:\n${_formatTransactions(transactionContext)}'
        : '';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text':
                  'You are Budget Buddy, a friendly personal finance AI coach for Indian users. '
                      'Provide concise, actionable advice. Use ₹ for currency. '
                      'Be encouraging and specific.$contextStr\n\nUser: $message',
            }
          ]
        }
      ],
      'generationConfig': {
        'maxOutputTokens': 512,
        'temperature': 0.7,
      },
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = json['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = (candidates[0]['content']?['parts'] as List?) ?? [];
          if (parts.isNotEmpty) {
            return parts[0]['text'] as String? ?? 'No response from AI.';
          }
        }
      }
    } catch (e) {
      debugPrint('[AiService] Direct Gemini call failed: $e');
    }

    return 'I\'m having trouble connecting right now. Please try again. 🌟';
  }

  static String _formatTransactions(List<Map<String, dynamic>> transactions) {
    final buffer = StringBuffer();
    for (final t in transactions.take(20)) {
      final type = t['type'] ?? 'expense';
      final amount = t['amount'] ?? 0;
      final category =
          t['categories']?['name'] ?? t['category_name'] ?? 'Other';
      final date = t['transaction_date'] ?? '';
      final note = t['note'] ?? '';
      buffer.writeln(
          '- $type: ₹$amount on $category ($date) ${note.isNotEmpty ? "— $note" : ""}');
    }
    return buffer.toString();
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
