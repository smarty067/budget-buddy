import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/design_tokens.dart';
import '../../shared/widgets/glass_card.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/chat_message.dart';
import '../../core/services/ai_service.dart';

// ──────────────────────────────────────────────────────────────
// Suggestion chips shown when the chat is empty
// ──────────────────────────────────────────────────────────────

const _kSuggestions = [
  'Where am I overspending?',
  "What's left in my budgets?",
  'How is my savings goal going?',
  'Can I afford a ₹10,000 purchase?',
];

// ──────────────────────────────────────────────────────────────
// Internal view-model for a bubble (loaded from DB or sent live)
// ──────────────────────────────────────────────────────────────

enum _BubbleState { normal, error }

class _Bubble {
  final String role; // 'user' | 'assistant'
  final String content;
  final _BubbleState state;
  /// Original question to retry (only meaningful for error bubbles)
  final String? retryQuestion;

  const _Bubble({
    required this.role,
    required this.content,
    this.state = _BubbleState.normal,
    this.retryQuestion,
  });

  bool get isUser => role == 'user';
}

// ──────────────────────────────────────────────────────────────
// Screen
// ──────────────────────────────────────────────────────────────

/// Interactive AI Coach chat screen.
///
/// - Loads the last 30 messages from `ai_chat_history` on open.
/// - Calls the `ai-coach` Edge Function via [AiCoachService].
/// - Rate-limited to 30 questions/day on the server side.
/// - Shows suggestion chips when chat is empty.
/// - Supports retry on error, clear-chat with confirmation, and
///   a disclaimer banner.
class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  final List<_Bubble> _bubbles = [];
  bool _isLoading = false;   // AI call in progress
  bool _isHistoryLoading = true; // initial DB load
  bool _isSendDisabled = false;  // prevents double-send

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    setState(() => _isHistoryLoading = true);
    try {
      final rows = await AiCoachService.loadHistory(limit: 30);
      if (mounted) {
        setState(() {
          _bubbles.clear();
          for (final row in rows) {
            try {
              final msg = ChatMessage.fromJson(row);
              _bubbles.add(_Bubble(role: msg.role, content: msg.content));
            } catch (_) {}
          }
          _isHistoryLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _isHistoryLoading = false);
    }
  }

  // ── Sending ───────────────────────────────────────────────────

  Future<void> _send({String? overrideText}) async {
    if (_isSendDisabled || _isLoading) return;

    final text = (overrideText ?? _inputController.text).trim();
    if (text.isEmpty) return;

    _inputController.clear();

    setState(() {
      _bubbles.add(_Bubble(role: 'user', content: text));
      _isLoading = true;
      _isSendDisabled = true;
    });
    _scrollToBottom();

    try {
      final answer = await AiCoachService.ask(text);
      if (mounted) {
        setState(() {
          _bubbles.add(_Bubble(role: 'assistant', content: answer));
          _isLoading = false;
          _isSendDisabled = false;
        });
        _scrollToBottom();
      }
    } on AiCoachException catch (e) {
      if (mounted) {
        setState(() {
          _bubbles.add(_Bubble(
            role: 'assistant',
            content: e.message,
            state: _BubbleState.error,
            retryQuestion: text,
          ));
          _isLoading = false;
          _isSendDisabled = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _bubbles.add(_Bubble(
            role: 'assistant',
            content: 'AI is unavailable, please try again',
            state: _BubbleState.error,
            retryQuestion: text,
          ));
          _isLoading = false;
          _isSendDisabled = false;
        });
        _scrollToBottom();
      }
    }
  }

  // ── Clear chat ────────────────────────────────────────────────

  Future<void> _confirmAndClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear chat history?'),
        content: const Text(
          'This will permanently delete all your AI Coach messages. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await AiCoachService.clearHistory();
      if (mounted) {
        setState(() => _bubbles.clear());
      }
    } on AiCoachException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  // ── Scroll ────────────────────────────────────────────────────

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppAnimation.normal,
          curve: AppAnimation.defaultCurve,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isGuest = ref.watch(isGuestProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkPrimaryGradient
                    : AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('AI Coach'),
          ],
        ),
        actions: [
          if (!isGuest && _bubbles.isNotEmpty)
            IconButton(
              tooltip: 'Clear chat',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _confirmAndClear,
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Guest warning ──
          if (isGuest)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              color: theme.colorScheme.errorContainer.withAlpha(200),
              child: Row(
                children: [
                  Icon(Icons.lock_person_outlined,
                      size: 18, color: theme.colorScheme.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Sign in to use the AI Coach and save your chat history.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Disclaimer ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
            child: Text(
              '⚠️ AI can make mistakes. Check important numbers.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // ── Chat list ──
          Expanded(
            child: _isHistoryLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildChatList(theme, isDark),
          ),

          // ── Input bar ──
          _buildInputBar(theme, isDark, isGuest),
        ],
      ),
    );
  }

  Widget _buildChatList(ThemeData theme, bool isDark) {
    // Empty state: show suggestion chips
    final showSuggestions = _bubbles.isEmpty && !_isLoading;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Suggestion chips (shown only when chat is empty)
        if (showSuggestions) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Text(
              'Hi! 👋 I\'m your Budget Buddy AI Coach.\nTry one of these:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: _kSuggestions
                .map(
                  (s) => ActionChip(
                    label: Text(s),
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                    side: BorderSide(
                        color: theme.colorScheme.primary.withAlpha(77)),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.xlAll,
                    ),
                    onPressed: _isSendDisabled ? null : () => _send(overrideText: s),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // Message bubbles
        for (int i = 0; i < _bubbles.length; i++)
          _BubbleWidget(
            bubble: _bubbles[i],
            isDark: isDark,
            onRetry: (q) => _send(overrideText: q),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.08, end: 0, duration: 300.ms),

        // Typing indicator
        if (_isLoading)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: GlassCard(
                borderRadius: AppRadius.xl,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'Budget Buddy is thinking...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 200.ms),
      ],
    );
  }

  Widget _buildInputBar(ThemeData theme, bool isDark, bool isGuest) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.sm,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 51 : 13),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !isGuest,
              maxLength: 500,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              onSubmitted: _isSendDisabled ? null : (_) => _send(),
              decoration: InputDecoration(
                hintText: isGuest
                    ? 'Sign in to use AI Coach'
                    : 'Ask your AI Coach...',
                counterText: '', // hide the built-in counter
                border: OutlineInputBorder(
                  borderRadius: AppRadius.xlAll,
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withAlpha(77),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            onPressed: (isGuest || _isSendDisabled) ? null : _send,
            icon: const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              disabledBackgroundColor:
                  theme.colorScheme.onSurface.withAlpha(30),
              padding: const EdgeInsets.all(AppSpacing.md),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Bubble widget
// ──────────────────────────────────────────────────────────────

class _BubbleWidget extends StatelessWidget {
  final _Bubble bubble;
  final bool isDark;
  final void Function(String question) onRetry;

  const _BubbleWidget({
    required this.bubble,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = bubble.isUser;
    final isError = bubble.state == _BubbleState.error;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: isUser
            ? _UserBubble(theme: theme, text: bubble.content)
            : _AssistantBubble(
                theme: theme,
                isDark: isDark,
                text: bubble.content,
                isError: isError,
                retryQuestion: bubble.retryQuestion,
                onRetry: onRetry,
              ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final ThemeData theme;
  final String text;

  const _UserBubble({required this.theme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: SelectableText(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final String text;
  final bool isError;
  final String? retryQuestion;
  final void Function(String) onRetry;

  const _AssistantBubble({
    required this.theme,
    required this.isDark,
    required this.text,
    required this.isError,
    required this.onRetry,
    this.retryQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + label row
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.darkPrimaryGradient
                      : AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError
                      ? Icons.warning_amber_rounded
                      : Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Budget Buddy',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isError
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Message content
          SelectableText(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isError ? theme.colorScheme.error : null,
            ),
          ),
          // Retry button for error bubbles
          if (isError && retryQuestion != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => onRetry(retryQuestion!),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
