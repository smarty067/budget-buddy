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
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
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
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Gradient Graphic Banner ──
          Container(
            height: 90,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F5A3D),
                  Color(0xFF141A22),
                ],
              ),
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
                    color: AppColors.mint.withOpacity(0.2),
                  ),
                ),
                Icon(
                  item.icon,
                  color: AppColors.mint,
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
                    color: AppColors.mint.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.mint.withOpacity(0.3)),
                  ),
                  child: Text(
                    item.badge,
                    style: const TextStyle(
                      color: AppColors.mint,
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
                  style: const TextStyle(
                    color: Colors.white,
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
                    color: AppColors.onSurfaceVariantDark,
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
                        style: const TextStyle(
                          color: AppColors.mint,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.mint, size: 13),
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
