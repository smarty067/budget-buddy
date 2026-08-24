import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/design_tokens.dart';
import '../../shared/widgets/glass_card.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/data_providers.dart';
import '../../core/services/ai_service.dart';

/// Interactive AI Coach chat screen.
class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _ChatBubble {
  final String role;
  final String content;

  const _ChatBubble({required this.role, required this.content});
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;

  final List<_ChatBubble> _messages = [
    const _ChatBubble(
      role: 'assistant',
      content:
          'Hi there! 👋 I\'m your Budget Buddy AI Coach.\n\n'
          'I can help you with:\n'
          '• Analyzing your spending patterns\n'
          '• Suggesting budget adjustments\n'
          '• Answering questions like "Can I afford a new phone?"\n\n'
          'What would you like to know?',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({String? customText, String? quickPromptType}) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    if (customText == null) {
      _messageController.clear();
    }

    setState(() {
      _messages.add(_ChatBubble(role: 'user', content: text));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final isGuest = ref.read(isGuestProvider);
      final recentTransactions = ref.read(transactionsProvider).valueOrNull ?? [];

      final reply = await AiService.sendMessage(
        message: text,
        quickPromptType: quickPromptType,
        isGuest: isGuest,
        transactionContext: recentTransactions,
      );

      if (mounted) {
        setState(() {
          _messages.add(_ChatBubble(role: 'assistant', content: reply));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatBubble(
            role: 'assistant',
            content: 'Sorry, I couldn\'t process that right now. Please try again. 🌟',
          ));
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppAnimation.normal,
          curve: AppAnimation.defaultCurve,
        );
      }
    });
  }

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
      ),
      body: Column(
        children: [
          // Guest warning banner
          if (isGuest)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              color: theme.colorScheme.errorContainer.withAlpha(200),
              child: Row(
                children: [
                  Icon(Icons.lock_person_outlined, size: 18, color: theme.colorScheme.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Guest Mode: Insights are analyzed locally. Sign up for cloud backups! 🔒',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Quick Prompt Chips ──
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _QuickChip(
                  icon: Icons.analytics_outlined,
                  label: 'Analyze Spending',
                  onTap: () => _sendMessage(
                    customText: 'Analyze my spending trends for this month.',
                    quickPromptType: 'spending_analysis',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _QuickChip(
                  icon: Icons.savings_outlined,
                  label: 'Savings Advice',
                  onTap: () => _sendMessage(
                    customText: 'Give me tips to improve my savings rate.',
                    quickPromptType: 'savings_tips',
                  ),
                ),
              ],
            ),
          ),

          // ── Chat Messages ──
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                // Show typing indicator if it is the last item
                if (_isTyping && index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
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
                              'Budget Buddy is typing...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                final isUser = msg.role == 'user';

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: isUser
                        ? Container(
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
                            child: Text(
                              msg.content,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : GlassCard(
                            borderRadius: AppRadius.xl,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                      child: const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      'Budget Buddy',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  msg.content,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1, end: 0, duration: 300.ms);
              },
            ),
          ),

          // ── Input Bar ──
          Container(
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
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Ask your AI Coach...',
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
                  onPressed: () => _sendMessage(),
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.all(AppSpacing.md),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 16, color: theme.colorScheme.primary),
      label: Text(label),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
      ),
      side: BorderSide(color: theme.colorScheme.primary.withAlpha(77)),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.xlAll,
      ),
    );
  }
}
