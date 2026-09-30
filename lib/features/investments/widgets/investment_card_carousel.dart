import 'package:flutter/material.dart';
import '../../../app/theme/design_tokens.dart';

class InvestmentCardItem {
  final String badge;
  final String title;
  final String subtitle;
  final String actionText;
  final IconData icon;
  final VoidCallback onTap;

  const InvestmentCardItem({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.icon,
    required this.onTap,
  });
}

class InvestmentCardCarousel extends StatelessWidget {
  final List<InvestmentCardItem> items;

  const InvestmentCardCarousel({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final item = items[index];
          return _InvestmentCard(item: item);
        },
      ),
    );
  }
}

class _InvestmentCard extends StatelessWidget {
  final InvestmentCardItem item;

  const _InvestmentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.surfaceBorder, width: 1.2),
        boxShadow: colors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Gradient Graphic Banner ──
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: colors.bannerGradient,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing circle behind icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.chipBackground,
                  ),
                ),
                Icon(
                  item.icon,
                  color: colors.accentMint,
                  size: 34,
                ),
              ],
            ),
          ),

          // ── Bottom Content ──
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.chipBackground,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: colors.chipBorder),
                  ),
                  child: Text(
                    item.badge,
                    style: TextStyle(
                      color: colors.accentMint,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Title
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                // Subtitle
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                // Action Link
                InkWell(
                  onTap: item.onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.actionText,
                        style: TextStyle(
                          color: colors.accentMint,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, color: colors.accentMint, size: 13),
                    ],
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
