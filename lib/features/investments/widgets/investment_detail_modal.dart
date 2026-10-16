import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/models/investment.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/investment_provider.dart';
import '../../../core/services/investment_service.dart';
import '../../../core/services/investment_valuation_service.dart';
import 'add_investment_sheet.dart';

/// Modal bottom sheet displaying detailed investment information,
/// complete valuation history audit trail, and options to record growth/decrease.
class InvestmentDetailModal extends ConsumerStatefulWidget {
  final Investment investment;

  const InvestmentDetailModal({super.key, required this.investment});

  @override
  ConsumerState<InvestmentDetailModal> createState() => _InvestmentDetailModalState();
}

class _InvestmentDetailModalState extends ConsumerState<InvestmentDetailModal> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  late Investment _currentInvestment;

  @override
  void initState() {
    super.initState();
    _currentInvestment = widget.investment;
  }

  void _showUpdateValuationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpdateValuationSheet(
        investment: _currentInvestment,
        onUpdated: (updatedInvestment) {
          setState(() {
            _currentInvestment = updatedInvestment;
          });
        },
      ),
    );
  }

  void _editInvestment() {
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddInvestmentSheet(existing: _currentInvestment),
    );
  }

  void _confirmDelete() {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text(
          'Delete Investment?',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove "${_currentInvestment.name}"? This action cannot be undone.',
          style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              final isGuest = ref.read(isGuestProvider);
              if (_currentInvestment.id != null) {
                await InvestmentService.deleteInvestment(_currentInvestment.id!, isGuest: isGuest);
                ref.invalidate(investmentsProvider);
              }
              if (mounted) {
                Navigator.pop(context); // Close details modal
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Investment deleted', style: TextStyle(color: colors.textPrimary)),
                    backgroundColor: colors.surface,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.lossRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final inv = _currentInvestment;
    final invId = inv.id ?? '';
    final historyAsync = ref.watch(investmentHistoryProvider(invId));

    final totalProfitLoss = inv.currentValue - inv.investedAmount;
    final isGain = totalProfitLoss >= 0;
    final returnPct = inv.investedAmount > 0 ? (totalProfitLoss / inv.investedAmount) * 100 : 0.0;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        border: Border(top: BorderSide(color: colors.surfaceBorder, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: colors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.chipBackground,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.pie_chart_outline_rounded, color: colors.accentMint, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.name,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.accentMint.withAlpha(30),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        inv.type.label,
                        style: TextStyle(
                          color: colors.accentMint,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: colors.textSecondary, size: 20),
                onPressed: _editInvestment,
                tooltip: 'Edit Asset Details',
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: colors.lossRed.withAlpha(200), size: 20),
                onPressed: _confirmDelete,
                tooltip: 'Delete Asset',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Main Valuation Summary Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: colors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT MARKET VALUE',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currencyFormat.format(inv.currentValue.round()),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isGain ? colors.gainGreen.withAlpha(35) : colors.lossRed.withAlpha(35),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGain ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            color: isGain ? colors.gainGreen : colors.lossRed,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${isGain ? '+' : ''}${returnPct.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: isGain ? colors.gainGreen : colors.lossRed,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(color: colors.surfaceBorder, height: 1),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetric('Invested (Cost Basis)', _currencyFormat.format(inv.investedAmount.round()), colors),
                    _buildMetric(
                      'Total Gain/Loss',
                      '${isGain ? '+' : ''}${_currencyFormat.format(totalProfitLoss.round())}',
                      colors,
                      highlightColor: isGain ? colors.gainGreen : colors.lossRed,
                    ),
                    _buildMetric('Monthly SIP', _currencyFormat.format(inv.monthlyContribution.round()), colors),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // "Update Valuation" Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showUpdateValuationSheet(context),
              icon: const Icon(Icons.trending_up_rounded, size: 18),
              label: const Text(
                'UPDATE VALUATION (GROWTH / DECREASE)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentMint,
                foregroundColor: colors.textOnGradient,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Section Header: Valuation History
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valuation History & Audit Trail',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: colors.textSecondary, size: 18),
                onPressed: () => ref.invalidate(investmentHistoryProvider(invId)),
                tooltip: 'Refresh history',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Valuation History List
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Failed to load history: $e', style: TextStyle(color: colors.lossRed)),
              ),
              data: (historyList) {
                if (historyList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off_rounded, color: colors.textSecondary.withAlpha(128), size: 40),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No valuation updates yet',
                            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "Update Valuation" above whenever your investment grows or drops to track NAV changes over time.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: historyList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = historyList[index];
                    final isPositive = item.amountChanged >= 0;
                    final changeColor = isPositive ? colors.gainGreen : colors.lossRed;

                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: colors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: colors.surfaceBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: changeColor.withAlpha(30),
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Text(
                                      _formatUpdateType(item.updateType),
                                      style: TextStyle(
                                        color: changeColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    _dateFormat.format(item.timestamp),
                                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                              Text(
                                '${isPositive ? '+' : ''}${_currencyFormat.format(item.amountChanged.round())} (${isPositive ? '+' : ''}${item.percentageChanged.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  color: changeColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Previous: ${_currencyFormat.format(item.previousValue.round())}',
                                style: TextStyle(color: colors.textSecondary, fontSize: 12),
                              ),
                              const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.grey),
                              Text(
                                'New: ${_currencyFormat.format(item.newValue.round())}',
                                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                            ],
                          ),
                          if (item.note != null && item.note!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Note: ${item.note}',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontStyle: FontStyle.italic,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, BudgetColors colors, {Color? highlightColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: highlightColor ?? colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _formatUpdateType(String type) {
    switch (type) {
      case 'manual_growth':
        return 'GROWTH';
      case 'manual_decrease':
        return 'DECREASE';
      case 'market_update':
        return 'MARKET UPDATE';
      case 'purchase':
        return 'ADDITIONAL PURCHASE';
      case 'sale':
        return 'PARTIAL SALE';
      default:
        return 'VALUATION';
    }
  }
}

/// Sheet to input valuation updates (growth, decrease, or absolute value).
class _UpdateValuationSheet extends ConsumerStatefulWidget {
  final Investment investment;
  final ValueChanged<Investment> onUpdated;

  const _UpdateValuationSheet({required this.investment, required this.onUpdated});

  @override
  ConsumerState<_UpdateValuationSheet> createState() => _UpdateValuationSheetState();
}

class _UpdateValuationSheetState extends ConsumerState<_UpdateValuationSheet> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  // Mode: 0: Growth (+), 1: Decrease (-), 2: Set Absolute New Value
  int _mode = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _inputAmount {
    return double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0.0;
  }

  double get _calculatedNewValue {
    final cur = widget.investment.currentValue;
    switch (_mode) {
      case 0:
        return cur + _inputAmount;
      case 1:
        return (cur - _inputAmount).clamp(0.0, double.infinity);
      case 2:
        return _inputAmount.clamp(0.0, double.infinity);
      default:
        return cur;
    }
  }

  double get _amountChanged {
    return _calculatedNewValue - widget.investment.currentValue;
  }

  double get _pctChanged {
    final cur = widget.investment.currentValue;
    if (cur <= 0) return 0.0;
    return (_amountChanged / cur) * 100;
  }

  String get _updateType {
    switch (_mode) {
      case 0:
        return 'manual_growth';
      case 1:
        return 'manual_decrease';
      default:
        return 'market_update';
    }
  }

  Future<void> _submit() async {
    if (_inputAmount <= 0 && _mode != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final isGuest = ref.read(isGuestProvider);

    final result = await InvestmentValuationService.updateValue(
      investment: widget.investment,
      newMarketValue: _calculatedNewValue,
      updateType: _updateType,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      isGuest: isGuest,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (result != null) {
        widget.onUpdated(result.investment);
        ref.invalidate(investmentsProvider);
        if (widget.investment.id != null) {
          ref.invalidate(investmentHistoryProvider(widget.investment.id!));
        }
        Navigator.pop(context); // close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Valuation updated to ${_currencyFormat.format(_calculatedNewValue.round())}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update valuation. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cur = widget.investment.currentValue;
    final isGain = _amountChanged >= 0;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        border: Border(top: BorderSide(color: colors.surfaceBorder, width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Record Valuation Update',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Update current market value. Original cost basis (${_currencyFormat.format(widget.investment.investedAmount.round())}) will remain unchanged.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.3),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Mode Selector Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: colors.surfaceBorder),
              ),
              child: Row(
                children: [
                  _buildModeTab('Growth (+)', 0, colors),
                  _buildModeTab('Decrease (-)', 1, colors),
                  _buildModeTab('New Total', 2, colors),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Amount Input Field
            Text(
              _mode == 0
                  ? 'Growth Amount (₹)'
                  : _mode == 1
                      ? 'Decrease Amount (₹)'
                      : 'New Market Value (₹)',
              style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(color: colors.accentMint, fontSize: 18, fontWeight: FontWeight.bold),
                hintText: _mode == 2 ? cur.toStringAsFixed(0) : '0',
                hintStyle: TextStyle(color: colors.textSecondary.withAlpha(100)),
                filled: true,
                fillColor: colors.surfaceSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: colors.surfaceBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: colors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: colors.accentMint, width: 1.5),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppSpacing.md),

            // Live Preview Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: _amountChanged != 0 ? (isGain ? colors.gainGreen.withAlpha(80) : colors.lossRed.withAlpha(80)) : colors.surfaceBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current Valuation:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                      Text(_currencyFormat.format(cur.round()), style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Updated Valuation:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                      Text(
                        _currencyFormat.format(_calculatedNewValue.round()),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Valuation Change:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                      Text(
                        '${isGain ? '+' : ''}${_currencyFormat.format(_amountChanged.round())} (${isGain ? '+' : ''}${_pctChanged.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          color: _amountChanged != 0 ? (isGain ? colors.gainGreen : colors.lossRed) : colors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Note / Reason Field
            Text('Reason / Note (Optional)', style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _noteController,
              style: TextStyle(color: colors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Monthly NAV growth, Market correction',
                hintStyle: TextStyle(color: colors.textSecondary.withAlpha(100), fontSize: 12),
                filled: true,
                fillColor: colors.surfaceSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: colors.surfaceBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: colors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: colors.accentMint, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Submit Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentMint,
                  foregroundColor: colors.textOnGradient,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'SAVE VALUATION UPDATE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(String label, int index, BudgetColors colors) {
    final isSelected = _mode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: isSelected ? colors.cardShadow : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? colors.accentMint : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
