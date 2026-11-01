import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';

/// AI Coach service — thin wrapper around the `ai-coach` Supabase Edge Function.
///
/// Security: The OpenRouter key is NEVER in this file or anywhere in the
/// Flutter codebase. It lives exclusively in Supabase Secrets on the server.
class AiCoachService {
  AiCoachService._();

  /// Invoke the ai-coach edge function with [question].
  ///
  /// Returns the assistant's answer string on success.
  /// Throws [AiCoachException] with a user-friendly message on error.
  static Future<String> ask(String question) async {
    try {
      final response = await SupabaseClientHelper.client.functions.invoke(
        'ai-coach',
        body: {'question': question},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Success path
        if (data['answer'] is String && (data['answer'] as String).isNotEmpty) {
          return data['answer'] as String;
        }
        // Server returned a structured error
        if (data['error'] is String) {
          throw AiCoachException(data['error'] as String);
        }
      }
      throw AiCoachException('AI is unavailable, please try again');
    } on FunctionException catch (e) {
      // Map HTTP status codes to user-facing messages
      final status = e.status ?? 0;
      if (status == 401) {
        throw AiCoachException('Please sign in again');
      } else if (status == 429) {
        throw AiCoachException(
            'Daily AI limit reached, try again tomorrow');
      } else if (status == 400) {
        // Surface server validation messages when available
        final detail = _extractError(e.details);
        throw AiCoachException(detail ?? 'Invalid request');
      }
      // 502, 503, or any other server-side error
      throw AiCoachException('AI is unavailable, please try again');
    } catch (e) {
      if (e is AiCoachException) rethrow;
      debugPrint('[AiCoachService] Unexpected error: $e');
      throw AiCoachException('AI is unavailable, please try again');
    }
  }

  /// Load the last [limit] chat messages for the current user (ascending).
  /// Returns an empty list if the user is not authenticated or the query fails.
  static Future<List<Map<String, dynamic>>> loadHistory({
    int limit = 30,
  }) async {
    try {
      final rows = await SupabaseClientHelper.client
          .from('ai_chat_history')
          .select('id, user_id, role, content, created_at')
          .order('created_at', ascending: false)
          .limit(limit);

      // Reverse so messages are oldest-first for display
      final list = List<Map<String, dynamic>>.from(rows);
      return list.reversed.toList();
    } catch (e) {
      debugPrint('[AiCoachService] loadHistory error: $e');
      return [];
    }
  }

  /// Delete all ai_chat_history rows belonging to the current user.
  /// Throws [AiCoachException] if the operation fails.
  static Future<void> clearHistory() async {
    try {
      final userId = SupabaseClientHelper.currentUser?.id;
      if (userId == null) return;
      await SupabaseClientHelper.client
          .from('ai_chat_history')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[AiCoachService] clearHistory error: $e');
      throw AiCoachException('Could not clear chat history. Please try again.');
    }
  }

  // ── Internal helpers ──

  static String? _extractError(dynamic details) {
    if (details is Map<String, dynamic> && details['error'] is String) {
      return details['error'] as String;
    }
    if (details is String && details.isNotEmpty) return details;
    return null;
  }
}

/// Typed exception for AI Coach errors with user-friendly messages.
class AiCoachException implements Exception {
  final String message;
  const AiCoachException(this.message);

  @override
  String toString() => message;
}
