import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/theme/design_tokens.dart';
import '../../core/models/investment.dart';
import '../../core/providers/investment_provider.dart';
import '../emi_calculator/emi_calculator_screen.dart';
import 'widgets/add_investment_sheet.dart';
import 'widgets/investment_card_carousel.dart';
import 'widgets/radial_loan_gauge.dart';
import 'widgets/sip_calculator_sheet.dart';

/// Wealth, Loans & Investment Hub matching Reference Image 1.
class InvestmentsScreen extends ConsumerStatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  ConsumerState<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends ConsumerState<InvestmentsScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  void _openEmiCalculator() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmiCalculatorScreen()),
    );
  }

  void _openSipCalculator() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SipCalculatorSheet(),
    );
  }

  void _openAddInvestment({Investment? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddInvestmentSheet(existing: existing),
    );
  }

  void _showLoanDetailsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
          border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Loan Overview',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDetailRow('Original Principal', '₹3,50,000'),
            _buildDetailRow('Remaining Balance', '₹2,54,000'),
            _buildDetailRow('Monthly EMI', '₹6,250'),
            _buildDetailRow('Interest Rate', '9.2% p.a.'),
            _buildDetailRow('Tenure Completed', '8 of 65 Months'),
            _buildDetailRow('Next Auto-Debit', '01 Feb 2024'),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openEmiCalculator();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mint,
                  foregroundColor: AppColors.heroDarkText,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
                child: const Text('RECALCULATE / PLAN EMI', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.onSurfaceVariantDark, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final investmentSummary = ref.watch(investmentSummaryProvider);
    final investmentsAsync = ref.watch(investmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TOP BAR MATCHING REFERENCE 1 ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Menu Icon
                    IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                      onPressed: () {},
                    ),
                    // Center: Circular Brand Button
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16241E),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder, width: 1.2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_outward_rounded,
                          color: AppColors.mint,
                          size: 22,
                        ),
                      ),
                    ),
                    // Right: Notification Bell with Badge 26
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
                          onPressed: () {},
                        ),
                        Positioned(
                          right: 6,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.mint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '26',
                              style: TextStyle(
                                color: AppColors.heroDarkText,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // ── HERO RADIAL LOAN GAUGE ──
              RadialLoanGauge(
                balance: 254000,
                nextDueDate: '01 Feb 2024',
                currentInstallment: 8,
                totalInstallments: 65,
                onViewDetails: _showLoanDetailsModal,
                onSecondaryAction: _openEmiCalculator,
                secondaryActionLabel: 'CALCULATE EMI',
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── FINANCIAL PRODUCTS CAROUSEL ──
              InvestmentCardCarousel(
                items: [
                  InvestmentCardItem(
                    badge: 'HEALTH PLANS',
                    title: 'Get Health Insurance Paying ₹240/Month',
                    subtitle: 'Benefit Of Hospitalisation, Medicine And Other Upto ₹5,00,000',
                    actionText: 'LEARN MORE',
                    icon: Icons.health_and_safety_outlined,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Health protection calculator coming soon!')),
                      );
                    },
                  ),
                  InvestmentCardItem(
                    badge: 'SIP',
                    title: 'Get Assure 15% Hedge Funds & Index',
                    subtitle: 'Invest ₹15,000 Per Month For 15 Years To Build ₹1 Crore.',
                    actionText: 'CALCULATE SIP',
                    icon: Icons.trending_up_rounded,
                    onTap: _openSipCalculator,
                  ),
                  InvestmentCardItem(
                    badge: 'GOLD BONDS',
                    title: 'Sovereign Gold Bonds 2.5% + Capital Gains',
                    subtitle: 'Tax-free capital gains on redemption with RBI backing.',
                    actionText: 'EXPLORE GOLD',
                    icon: Icons.monetization_on_outlined,
                    onTap: () => _openAddInvestment(),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── PORTFOLIO & WEALTH TRACKER SECTION ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Investment Portfolio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openAddInvestment(),
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.mint, size: 18),
                      label: const Text(
                        'Add Asset',
                        style: TextStyle(color: AppColors.mint, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Portfolio Summary Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: AppColors.cardBorder, width: 1.2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL PORTFOLIO VALUE',
                                style: TextStyle(
                                  color: AppColors.onSurfaceVariantDark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currencyFormat.format(investmentSummary.totalCurrentValue.round()),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: investmentSummary.totalReturns >= 0
                                  ? AppColors.mint.withOpacity(0.15)
                                  : Colors.redAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Text(
                              '${investmentSummary.totalReturns >= 0 ? '+' : ''}${investmentSummary.overallReturnPercentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: investmentSummary.totalReturns >= 0 ? AppColors.mint : Colors.redAccent,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Divider(color: AppColors.cardBorder.withOpacity(0.7), height: 1),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPortfolioMiniStat(
                            'Invested',
                            _currencyFormat.format(investmentSummary.totalInvested.round()),
                          ),
                          _buildPortfolioMiniStat(
                            'Total Gains',
                            '+${_currencyFormat.format(investmentSummary.totalReturns.round())}',
                            highlight: true,
                          ),
                          _buildPortfolioMiniStat(
                            'Monthly SIP',
                            _currencyFormat.format(investmentSummary.totalMonthlySip.round()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Investments List
              investmentsAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CircularProgressIndicator())),
                error: (e, _) => const SizedBox(),
                data: (list) {
                  if (list.isEmpty) return const SizedBox();

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.mint.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.pie_chart_outline_rounded, color: AppColors.mint, size: 20),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.type.label} • Invested ${_currencyFormat.format(item.investedAmount.round())}',
                                    style: TextStyle(color: AppColors.onSurfaceVariantDark, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _currencyFormat.format(item.currentValue.round()),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '+${item.returnPercentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(color: AppColors.mint, fontWeight: FontWeight.w700, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioMiniStat(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.onSurfaceVariantDark, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppColors.mint : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
