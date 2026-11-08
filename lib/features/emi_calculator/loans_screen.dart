import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/theme/design_tokens.dart';
import '../../core/models/loan.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/loan_provider.dart';
import '../../core/services/loan_service.dart';

/// Screen displaying the user's saved loans, allowing them to view
/// active & closed loans, mark a loan as closed, or delete a loan.
class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleStatus(Loan loan) async {
    final newStatus = loan.isActive ? 'closed' : 'active';
    final isGuest = ref.read(isGuestProvider);
    final colors = context.colors;

    final success = await LoanService.updateLoanStatus(
      loan.id,
      newStatus,
      isGuest: isGuest,
    );

    if (success) {
      ref.invalidate(loansProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'closed'
                  ? 'Loan marked as closed'
                  : 'Loan reopened as active',
              style: TextStyle(color: colors.textPrimary),
            ),
            backgroundColor: colors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: BorderSide(color: colors.surfaceBorder),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(Loan loan) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: colors.surfaceBorder),
        ),
        title: Text(
          'Delete Loan',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${loan.name}"? This action cannot be undone.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.lossRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final isGuest = ref.read(isGuestProvider);
      await LoanService.deleteLoan(loan.id, isGuest: isGuest);
      ref.invalidate(loansProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Loan deleted',
              style: TextStyle(color: colors.textPrimary),
            ),
            backgroundColor: colors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final loansAsync = ref.watch(loansProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Saved Loans',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.textSecondary),
            onPressed: () => ref.invalidate(loansProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.surfaceBorder),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: colors.accentMint,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              labelColor: colors.textOnGradient,
              unselectedLabelColor: colors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Closed'),
              ],
            ),
          ),
        ),
      ),
      body: loansAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.accentMint),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: colors.lossRed, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Failed to load loans',
                style: TextStyle(color: colors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: () => ref.invalidate(loansProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (loans) {
          final activeLoans = loans.where((l) => l.isActive).toList();
          final closedLoans = loans.where((l) => l.isClosed).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildLoansList(activeLoans, isActiveTab: true),
              _buildLoansList(closedLoans, isActiveTab: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoansList(List<Loan> loans, {required bool isActiveTab}) {
    final colors = context.colors;

    if (loans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActiveTab ? Icons.account_balance_outlined : Icons.check_circle_outline_rounded,
                size: 64,
                color: colors.textSecondary.withAlpha(120),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isActiveTab ? 'No active loans' : 'No closed loans',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isActiveTab
                    ? 'Calculate your EMI and tap "Save as loan" to start tracking.'
                    : 'Loans marked as closed will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: loans.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final loan = loans[index];
        return _buildLoanCard(loan);
      },
    );
  }

  Widget _buildLoanCard(Loan loan) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.surfaceBorder),
        boxShadow: colors.cardShadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name + Status Badge + Actions Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: colors.accentMint.withAlpha(25),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        Icons.account_balance_rounded,
                        color: colors.accentMint,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        loan.name,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: loan.isActive
                      ? colors.gainGreen.withAlpha(30)
                      : colors.textSecondary.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  loan.status.toUpperCase(),
                  style: TextStyle(
                    color: loan.isActive ? colors.gainGreen : colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: colors.textSecondary, size: 20),
                color: colors.surface,
                onSelected: (action) {
                  if (action == 'toggle') {
                    _toggleStatus(loan);
                  } else if (action == 'delete') {
                    _confirmDelete(loan);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          loan.isActive ? Icons.check_circle_outline : Icons.replay_rounded,
                          size: 18,
                          color: colors.textPrimary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(loan.isActive ? 'Mark as Closed' : 'Reopen as Active'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: colors.lossRed),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Delete Loan', style: TextStyle(color: colors.lossRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          // Core Metrics Grid
          Row(
            children: [
              Expanded(
                child: _metricCell(
                  label: 'Monthly EMI',
                  value: _currencyFormat.format(loan.emiAmount.round()),
                  valueColor: colors.accentMint,
                  isBold: true,
                ),
              ),
              Expanded(
                child: _metricCell(
                  label: 'Principal',
                  value: _currencyFormat.format(loan.principal.round()),
                  valueColor: colors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: _metricCell(
                  label: 'Interest Rate',
                  value: '${loan.interestRate}% p.a.',
                  valueColor: colors.textPrimary,
                ),
              ),
              Expanded(
                child: _metricCell(
                  label: 'Tenure',
                  value: '${loan.tenureMonths} mos (${(loan.tenureMonths / 12).toStringAsFixed(1)} yrs)',
                  valueColor: colors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: _metricCell(
                  label: 'Start Date',
                  value: _dateFormat.format(loan.startDate),
                  valueColor: colors.textSecondary,
                ),
              ),
              if (loan.isActive)
                Expanded(
                  child: _metricCell(
                    label: 'Est. Outstanding',
                    value: _currencyFormat.format(loan.estimatedOutstanding.round()),
                    valueColor: colors.lossRed,
                  ),
                )
              else
                Expanded(
                  child: _metricCell(
                    label: 'Status',
                    value: 'Paid Off',
                    valueColor: colors.gainGreen,
                  ),
                ),
            ],
          ),

          if (loan.isActive) ...[
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: loan.tenureMonths > 0
                  ? (loan.elapsedMonths / loan.tenureMonths).clamp(0.0, 1.0)
                  : 1.0,
              backgroundColor: colors.surfaceBorder,
              color: colors.accentMint,
              borderRadius: BorderRadius.circular(4),
              minHeight: 5,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${loan.elapsedMonths} months completed',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
                Text(
                  '${loan.remainingMonths} months left',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricCell({
    required String label,
    required String value,
    required Color valueColor,
    bool isBold = false,
  }) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
