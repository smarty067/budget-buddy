import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/models/emi_calculation.dart';
import '../../../core/models/loan_payment.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/emi_provider.dart';
import '../../../core/services/loan_payment_service.dart';

/// Full loan detail screen showing payment history and summary.
class LoanDetailScreen extends ConsumerStatefulWidget {
  final EmiCalculation loan;

  const LoanDetailScreen({super.key, required this.loan});

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final loanId = widget.loan.id ?? '';
    final isGuest = ref.watch(isGuestProvider);

    final paymentsAsync = ref.watch(loanPaymentsProvider(loanId));
    final adjustmentsAsync = ref.watch(loanAdjustmentsProvider(loanId));
    final summaryAsync = ref.watch(loanSummaryProvider(loanId));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Loan Details',
          style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colors.surfaceBorder),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(loanPaymentsProvider(loanId));
            ref.invalidate(loanAdjustmentsProvider(loanId));
            ref.invalidate(loanSummaryProvider(loanId));
          },
          color: colors.accentMint,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Loan Info Card ──
                _buildLoanInfoCard(colors),

                const SizedBox(height: AppSpacing.lg),

                // ── Loan Summary Card ──
                summaryAsync.when(
                  data: (summary) => summary != null
                      ? _buildSummaryCard(colors, summary)
                      : _buildEmptySummaryCard(colors),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _buildEmptySummaryCard(colors),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Action Buttons ──
                summaryAsync.when(
                  data: (summary) {
                    final isFullyRepaid = summary?.isFullyRepaid ?? false;
                    return _buildActionButtons(colors, isGuest, summary, isFullyRepaid, loanId);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => _buildActionButtons(colors, isGuest, null, false, loanId),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Payment History ──
                Text(
                  'Payment History',
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.md),

                paymentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e', style: TextStyle(color: colors.lossRed)),
                  data: (payments) {
                    if (payments.isEmpty) {
                      return _buildEmptyPaymentsState(colors);
                    }
                    return Column(
                      children: payments
                          .map((p) => _buildPaymentTile(colors, p))
                          .toList(),
                    );
                  },
                ),

                // ── Adjustments ──
                adjustmentsAsync.when(
                  data: (adjustments) {
                    if (adjustments.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Balance Adjustments',
                          style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...adjustments.map((a) => _buildAdjustmentTile(colors, a)),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoanInfoCard(BudgetColors colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: colors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(color: colors.accentMint.withAlpha(64), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.loan.title,
            style: TextStyle(color: colors.textOnGradient, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _buildInfoStat(colors, 'Principal', _currencyFormat.format(widget.loan.loanAmount.round()))),
              Expanded(child: _buildInfoStat(colors, 'Monthly EMI', _currencyFormat.format(widget.loan.monthlyEmi.round()))),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _buildInfoStat(colors, 'Interest Rate', '${widget.loan.interestRate}% p.a.')),
              Expanded(child: _buildInfoStat(colors, 'Tenure', '${widget.loan.tenureYears} yrs (${widget.loan.tenureYears * 12} months)')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoStat(colors, 'Total Payable', _currencyFormat.format(widget.loan.totalPayment.round())),
        ],
      ),
    );
  }

  Widget _buildInfoStat(BudgetColors colors, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textOnGradient.withAlpha(180), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: colors.textOnGradient, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildSummaryCard(BudgetColors colors, LoanSummary summary) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.surfaceBorder),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Loan Progress', style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              if (summary.isFullyRepaid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.gainGreen.withAlpha(38),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text('PAID OFF ✓', style: TextStyle(color: colors.gainGreen, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: summary.progressPercent,
              backgroundColor: colors.surfaceBorder,
              valueColor: AlwaysStoppedAnimation<Color>(
                summary.isFullyRepaid ? colors.gainGreen : colors.accentMint,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${(summary.progressPercent * 100).toStringAsFixed(1)}% complete',
            style: TextStyle(color: colors.textSecondary, fontSize: 11),
          ),

          const SizedBox(height: AppSpacing.md),
          Divider(color: colors.surfaceBorder, height: 1),
          const SizedBox(height: AppSpacing.md),

          _buildSummaryRow(colors, 'Original Principal', _currencyFormat.format(summary.originalPrincipal.round())),
          _buildSummaryRow(colors, 'Total Paid', _currencyFormat.format(summary.totalAmountPaid.round()), highlight: true),
          _buildSummaryRow(colors, 'Principal Repaid (est.)', _currencyFormat.format(summary.totalPrincipalRepaid.round())),
          _buildSummaryRow(colors, 'Interest Paid', _currencyFormat.format(summary.totalInterestPaid.round())),
          Divider(color: colors.surfaceBorder, height: 20),
          _buildSummaryRow(
            colors,
            'Outstanding Balance (est.)',
            _currencyFormat.format(summary.outstandingPrincipal.round()),
            isOutstanding: true,
          ),
          _buildSummaryRow(colors, 'EMIs Completed', '${summary.emisCompleted} / ${summary.totalEmis}'),
          _buildSummaryRow(colors, 'EMIs Remaining', summary.emisRemaining.toString()),
          if (!summary.isFullyRepaid && summary.nextEmiDate != null)
            _buildSummaryRow(colors, 'Next EMI Due', _dateFormat.format(summary.nextEmiDate!)),

          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: AppRadius.smAll,
            ),
            child: Text(
              '⚠ Outstanding balance is an estimate. Contact your lender for the exact outstanding amount.',
              style: TextStyle(color: colors.textSecondary, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySummaryCard(BudgetColors colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Column(
        children: [
          _buildSummaryRow(colors, 'Monthly EMI', _currencyFormat.format(widget.loan.monthlyEmi.round())),
          _buildSummaryRow(colors, 'Total Installments', '${widget.loan.tenureYears * 12} months'),
          _buildSummaryRow(colors, 'Total Interest', _currencyFormat.format(widget.loan.totalInterest.round())),
          _buildSummaryRow(colors, 'Total Payable', _currencyFormat.format(widget.loan.totalPayment.round())),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BudgetColors colors, String label, String value,
      {bool highlight = false, bool isOutstanding = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: isOutstanding
                  ? colors.lossRed
                  : highlight
                      ? colors.gainGreen
                      : colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BudgetColors colors,
    bool isGuest,
    LoanSummary? summary,
    bool isFullyRepaid,
    String loanId,
  ) {
    return Column(
      children: [
        // Mark EMI as Paid
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isFullyRepaid
                ? null
                : () => _showMarkPaidDialog(colors, isGuest, summary, loanId),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: Text(isFullyRepaid ? 'LOAN FULLY REPAID ✓' : 'MARK EMI AS PAID'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFullyRepaid ? colors.gainGreen.withAlpha(100) : colors.accentMint,
              foregroundColor: colors.textOnGradient,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Adjust Balance
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAdjustBalanceDialog(colors, isGuest, loanId),
            icon: Icon(Icons.tune_rounded, color: colors.accentMint),
            label: Text('ADJUST LOAN BALANCE', style: TextStyle(color: colors.accentMint)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.accentMint.withAlpha(128)),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showMarkPaidDialog(
    BudgetColors colors,
    bool isGuest,
    LoanSummary? summary,
    String loanId,
  ) async {
    final nextEmiNumber = (summary?.emisCompleted ?? 0) + 1;
    final emiAmount = widget.loan.monthlyEmi;
    final amountController = TextEditingController(
        text: emiAmount.toStringAsFixed(0));
    final noteController = TextEditingController();
    final refController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isSubmitting = false;

    // Calculate principal/interest components for this EMI
    final components = LoanPaymentService.getPrincipalInterestForEmi(
      loan: widget.loan,
      emiNumber: nextEmiNumber,
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
          title: Text(
            'Mark EMI #$nextEmiNumber as Paid',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // EMI breakdown
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Column(
                    children: [
                      _dialogRow(colors, 'EMI Amount', _currencyFormat.format(emiAmount.round())),
                      _dialogRow(colors, 'Principal Component (est.)', _currencyFormat.format(components.principal.round())),
                      _dialogRow(colors, 'Interest Component (est.)', _currencyFormat.format(components.interest.round())),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Actual amount paid
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Actual Amount Paid (₹)',
                    prefixText: '₹ ',
                    labelStyle: TextStyle(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Payment Date', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  subtitle: Text(
                    _dateFormat.format(selectedDate),
                    style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                  trailing: Icon(Icons.calendar_today_outlined, color: colors.accentMint, size: 18),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                ),
                // Reference
                TextFormField(
                  controller: refController,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Transaction Reference (optional)',
                    labelStyle: TextStyle(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: noteController,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Note (optional)',
                    labelStyle: TextStyle(color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      final actualAmount =
                          double.tryParse(amountController.text.trim()) ?? emiAmount;

                      final payment = LoanPayment(
                        loanId: loanId,
                        emiNumber: nextEmiNumber,
                        amountPaid: actualAmount,
                        principalComponent: components.principal,
                        interestComponent: components.interest,
                        paymentDate: selectedDate,
                        status: 'paid',
                        reference: refController.text.trim().isEmpty
                            ? null
                            : refController.text.trim(),
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );

                      final saved = await LoanPaymentService.recordPayment(
                          payment,
                          isGuest: isGuest);

                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      if (!mounted) return;
                      setDialogState(() => isSubmitting = false);

                      if (saved == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('EMI #$nextEmiNumber already recorded. Duplicate prevented.'),
                            backgroundColor: Colors.orange.shade700,
                          ),
                        );
                      } else {
                        // Refresh all data
                        ref.invalidate(loanPaymentsProvider(loanId));
                        ref.invalidate(loanAdjustmentsProvider(loanId));
                        ref.invalidate(loanSummaryProvider(loanId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('EMI #$nextEmiNumber recorded successfully!'),
                            backgroundColor: colors.gainGreen,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentMint,
                foregroundColor: colors.textOnGradient,
              ),
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('CONFIRM PAYMENT'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAdjustBalanceDialog(
      BudgetColors colors, bool isGuest, String loanId) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedType = 'extra_principal';
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
          title: Text('Adjust Loan Balance',
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  dropdownColor: colors.surface,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Adjustment Type',
                    labelStyle: TextStyle(color: colors.textSecondary),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'extra_principal', child: Text('Extra Principal Repayment')),
                    DropdownMenuItem(value: 'balance_correction', child: Text('Balance Correction')),
                    DropdownMenuItem(value: 'other', child: Text('Other Adjustment')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    prefixText: '₹ ',
                    labelStyle: TextStyle(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: noteController,
                  maxLines: 2,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Reason / Note *',
                    labelStyle: TextStyle(color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final amount = double.tryParse(amountController.text.trim());
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid amount')),
                        );
                        return;
                      }
                      if (noteController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Please enter a reason')),
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);

                      final adj = LoanAdjustment(
                        loanId: loanId,
                        adjustmentType: selectedType,
                        amount: amount,
                        note: noteController.text.trim(),
                        date: DateTime.now(),
                      );

                      await LoanPaymentService.recordAdjustment(adj, isGuest: isGuest);

                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      if (!mounted) return;
                      ref.invalidate(loanSummaryProvider(loanId));
                      ref.invalidate(loanAdjustmentsProvider(loanId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Adjustment recorded.'),
                          backgroundColor: colors.gainGreen,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentMint,
                foregroundColor: colors.textOnGradient,
              ),
              child: isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('APPLY ADJUSTMENT'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTile(BudgetColors colors, LoanPayment payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.gainGreen.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${payment.emiNumber}',
                style: TextStyle(color: colors.gainGreen, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMI #${payment.emiNumber} — ${_dateFormat.format(payment.paymentDate)}',
                  style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Principal: ${_currencyFormat.format(payment.principalComponent.round())} | Interest: ${_currencyFormat.format(payment.interestComponent.round())}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
                if (payment.note != null)
                  Text(payment.note!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Text(
            _currencyFormat.format(payment.amountPaid.round()),
            style: TextStyle(color: colors.gainGreen, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentTile(BudgetColors colors, LoanAdjustment adj) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.accentMint.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.tune_rounded, color: colors.accentMint, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adj.adjustmentType.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                ),
                Text(_dateFormat.format(adj.date), style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                if (adj.note != null)
                  Text(adj.note!, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Text(
            _currencyFormat.format(adj.amount.round()),
            style: TextStyle(color: colors.accentMint, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPaymentsState(BudgetColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.surfaceBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: colors.textSecondary, size: 40),
          const SizedBox(height: AppSpacing.md),
          Text('No Payments Recorded', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text('Tap "Mark EMI as Paid" to record your first payment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _dialogRow(BudgetColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          Text(value, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
