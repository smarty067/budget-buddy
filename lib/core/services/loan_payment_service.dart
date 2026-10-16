import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/emi_calculation.dart';
import '../models/loan_payment.dart';
import '../supabase_client.dart';
import 'session_service.dart';

/// Service for recording and retrieving loan EMI payments.
/// Handles both guest (Hive-local) and authenticated (Supabase + Hive cache) storage.
class LoanPaymentService {
  LoanPaymentService._();

  static const String _paymentsBoxName = 'local_loan_payments';
  static const String _adjustmentsBoxName = 'local_loan_adjustments';

  static Future<Box> _getPaymentsBox() async {
    if (Hive.isBoxOpen(_paymentsBoxName)) return Hive.box(_paymentsBoxName);
    return Hive.openBox(_paymentsBoxName);
  }

  static Future<Box> _getAdjustmentsBox() async {
    if (Hive.isBoxOpen(_adjustmentsBoxName)) return Hive.box(_adjustmentsBoxName);
    return Hive.openBox(_adjustmentsBoxName);
  }

  // ────────────────────────────────────────────────────────────────────────
  // PAYMENTS
  // ────────────────────────────────────────────────────────────────────────

  /// Returns all payment records for [loanId], sorted by emiNumber ascending.
  static Future<List<LoanPayment>> getPaymentsForLoan(
    String loanId, {
    bool isGuest = false,
  }) async {
    SessionService.recordActivity();
    final box = await _getPaymentsBox();

    // Read from local Hive
    final local = <LoanPayment>[];
    for (final raw in box.values) {
      if (raw is Map) {
        try {
          final map = Map<String, dynamic>.from(raw);
          if (map['loan_id'] == loanId) {
            local.add(LoanPayment.fromJson(map));
          }
        } catch (e) {
          debugPrint('[LoanPaymentService] parse error: $e');
        }
      }
    }

    if (isGuest || SupabaseClientHelper.currentUser == null) {
      local.sort((a, b) => a.emiNumber.compareTo(b.emiNumber));
      return List.unmodifiable(local);
    }

    // Cloud sync
    try {
      final response = await SupabaseClientHelper.client
          .from('loan_payments')
          .select()
          .eq('loan_id', loanId)
          .order('emi_number', ascending: true);

      final cloud = (response as List)
          .map((e) => LoanPayment.fromJson(e as Map<String, dynamic>))
          .toList();

      for (final p in cloud) {
        if (p.id != null) await box.put(p.id, p.toJson());
      }
      return cloud.isNotEmpty ? cloud : local;
    } catch (e) {
      debugPrint('[LoanPaymentService] Supabase read failed: $e');
      local.sort((a, b) => a.emiNumber.compareTo(b.emiNumber));
      return List.unmodifiable(local);
    }
  }

  /// Records a new EMI payment. Returns the saved payment or null on failure.
  /// Uses an idempotency key (loanId + emiNumber) to prevent duplicates.
  static Future<LoanPayment?> recordPayment(
    LoanPayment payment, {
    bool isGuest = false,
  }) async {
    SessionService.recordActivity();
    final box = await _getPaymentsBox();
    final userId = SupabaseClientHelper.currentUser?.id;

    // Idempotency: check if payment for this EMI number already exists
    final existing = await getPaymentsForLoan(payment.loanId, isGuest: isGuest);
    if (existing.any((p) => p.emiNumber == payment.emiNumber)) {
      debugPrint('[LoanPaymentService] Duplicate payment blocked for EMI #${payment.emiNumber}');
      return null; // signals duplicate
    }

    final id = payment.id ?? 'lpay_${DateTime.now().millisecondsSinceEpoch}';
    final toSave = LoanPayment(
      id: id,
      loanId: payment.loanId,
      userId: isGuest ? 'guest' : (userId ?? 'guest'),
      emiNumber: payment.emiNumber,
      amountPaid: payment.amountPaid,
      principalComponent: payment.principalComponent,
      interestComponent: payment.interestComponent,
      paymentDate: payment.paymentDate,
      status: payment.status,
      reference: payment.reference,
      note: payment.note,
      createdAt: DateTime.now(),
    );

    await box.put(id, toSave.toJson());

    if (!isGuest && userId != null) {
      try {
        final json = toSave.toJson()..['user_id'] = userId;
        final response = await SupabaseClientHelper.client
            .from('loan_payments')
            .insert(json)
            .select()
            .single();
        final cloud = LoanPayment.fromJson(response);
        await box.put(cloud.id ?? id, cloud.toJson());
        return cloud;
      } catch (e) {
        debugPrint('[LoanPaymentService] Cloud save failed, saved locally: $e');
      }
    }
    return toSave;
  }

  /// Deletes a payment record (with confirmation from caller).
  static Future<void> deletePayment(String paymentId, {bool isGuest = false}) async {
    final box = await _getPaymentsBox();
    await box.delete(paymentId);

    if (!isGuest && SupabaseClientHelper.currentUser != null) {
      try {
        await SupabaseClientHelper.client
            .from('loan_payments')
            .delete()
            .eq('id', paymentId);
      } catch (e) {
        debugPrint('[LoanPaymentService] Cloud delete error: $e');
      }
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // ADJUSTMENTS
  // ────────────────────────────────────────────────────────────────────────

  static Future<List<LoanAdjustment>> getAdjustmentsForLoan(
    String loanId, {
    bool isGuest = false,
  }) async {
    final box = await _getAdjustmentsBox();
    final local = <LoanAdjustment>[];

    for (final raw in box.values) {
      if (raw is Map) {
        try {
          final map = Map<String, dynamic>.from(raw);
          if (map['loan_id'] == loanId) {
            local.add(LoanAdjustment.fromJson(map));
          }
        } catch (e) {
          debugPrint('[LoanPaymentService] adj parse error: $e');
        }
      }
    }

    if (isGuest || SupabaseClientHelper.currentUser == null) {
      return List.unmodifiable(local);
    }

    try {
      final response = await SupabaseClientHelper.client
          .from('loan_adjustments')
          .select()
          .eq('loan_id', loanId)
          .order('date', ascending: false);

      final cloud = (response as List)
          .map((e) => LoanAdjustment.fromJson(e as Map<String, dynamic>))
          .toList();

      for (final a in cloud) {
        if (a.id != null) await box.put(a.id, a.toJson());
      }
      return cloud.isNotEmpty ? cloud : local;
    } catch (e) {
      debugPrint('[LoanPaymentService] Adj cloud read failed: $e');
      return List.unmodifiable(local);
    }
  }

  static Future<LoanAdjustment?> recordAdjustment(
    LoanAdjustment adjustment, {
    bool isGuest = false,
  }) async {
    SessionService.recordActivity();
    final box = await _getAdjustmentsBox();
    final userId = SupabaseClientHelper.currentUser?.id;

    final id = adjustment.id ?? 'ladj_${DateTime.now().millisecondsSinceEpoch}';
    final toSave = LoanAdjustment(
      id: id,
      loanId: adjustment.loanId,
      userId: isGuest ? 'guest' : (userId ?? 'guest'),
      adjustmentType: adjustment.adjustmentType,
      amount: adjustment.amount,
      note: adjustment.note,
      date: adjustment.date,
      createdAt: DateTime.now(),
    );

    await box.put(id, toSave.toJson());

    if (!isGuest && userId != null) {
      try {
        final json = toSave.toJson()..['user_id'] = userId;
        final response = await SupabaseClientHelper.client
            .from('loan_adjustments')
            .insert(json)
            .select()
            .single();
        final cloud = LoanAdjustment.fromJson(response);
        await box.put(cloud.id ?? id, cloud.toJson());
        return cloud;
      } catch (e) {
        debugPrint('[LoanPaymentService] Adj cloud save failed: $e');
      }
    }
    return toSave;
  }

  // ────────────────────────────────────────────────────────────────────────
  // FINANCIAL CALCULATIONS
  // ────────────────────────────────────────────────────────────────────────

  /// Calculates outstanding principal balance from the amortization schedule.
  ///
  /// For accuracy, we walk the amortization schedule month by month and subtract
  /// the principal component of each recorded payment. Adjustments (extra repayments)
  /// are also subtracted.
  ///
  /// Returns a [LoanSummary] object.
  static LoanSummary calculateSummary({
    required EmiCalculation loan,
    required List<LoanPayment> payments,
    required List<LoanAdjustment> adjustments,
  }) {
    final n = loan.tenureYears * 12;
    final r = (loan.interestRate / 12) / 100;

    // Build amortization schedule
    final schedule = <_AmortRow>[];
    double balance = loan.loanAmount;
    for (int month = 1; month <= n; month++) {
      final interest = balance * r;
      final principal = (r > 0)
          ? (loan.monthlyEmi - interest).clamp(0.0, balance)
          : (loan.monthlyEmi).clamp(0.0, balance);
      balance = (balance - principal).clamp(0.0, double.infinity);
      schedule.add(_AmortRow(month: month, principal: principal, interest: interest));
    }

    // Sum principal and interest from recorded payments
    double totalPrincipalRepaid = 0.0;
    double totalInterestPaid = 0.0;
    double totalAmountPaid = 0.0;

    for (final payment in payments) {
      totalPrincipalRepaid += payment.principalComponent;
      totalInterestPaid += payment.interestComponent;
      totalAmountPaid += payment.amountPaid;
    }

    // Extra principal repayments from adjustments
    double extraPrincipalRepaid = 0.0;
    for (final adj in adjustments) {
      if (adj.adjustmentType == 'extra_principal' || adj.adjustmentType == 'balance_correction') {
        extraPrincipalRepaid += adj.amount;
      }
    }

    final totalPrincipalFromAll = (totalPrincipalRepaid + extraPrincipalRepaid)
        .clamp(0.0, loan.loanAmount);

    final outstandingPrincipal =
        (loan.loanAmount - totalPrincipalFromAll).clamp(0.0, loan.loanAmount);

    final emisCompleted = payments.length;
    final emisRemaining = (n - emisCompleted).clamp(0, n);

    // Next due date: start date + payments made months + 1
    final startDate = loan.createdAt ?? DateTime.now();
    final nextDate = DateTime(
      startDate.year,
      startDate.month + emisCompleted + 1,
      startDate.day,
    );

    final progressPercent = loan.loanAmount > 0
        ? (totalPrincipalFromAll / loan.loanAmount).clamp(0.0, 1.0)
        : 0.0;

    final isFullyRepaid = outstandingPrincipal <= 0.01 || emisCompleted >= n;

    return LoanSummary(
      originalPrincipal: loan.loanAmount,
      totalPrincipalRepaid: totalPrincipalFromAll,
      totalInterestPaid: totalInterestPaid,
      totalAmountPaid: totalAmountPaid + extraPrincipalRepaid,
      outstandingPrincipal: outstandingPrincipal,
      emisCompleted: emisCompleted,
      emisRemaining: emisRemaining,
      totalEmis: n,
      nextEmiDate: isFullyRepaid ? null : nextDate,
      progressPercent: progressPercent,
      isFullyRepaid: isFullyRepaid,
      monthlyEmi: loan.monthlyEmi,
    );
  }

  /// Calculates principal and interest components for EMI number [emiNumber]
  /// based on the loan's amortization schedule.
  static ({double principal, double interest}) getPrincipalInterestForEmi({
    required EmiCalculation loan,
    required int emiNumber,
  }) {
    final n = loan.tenureYears * 12;
    final r = (loan.interestRate / 12) / 100;

    if (emiNumber < 1 || emiNumber > n) {
      return (principal: 0.0, interest: 0.0);
    }

    double balance = loan.loanAmount;
    double principal = 0.0;
    double interest = 0.0;

    for (int month = 1; month <= emiNumber; month++) {
      interest = balance * r;
      principal = (r > 0)
          ? (loan.monthlyEmi - interest).clamp(0.0, balance)
          : loan.monthlyEmi.clamp(0.0, balance);
      balance = (balance - principal).clamp(0.0, double.infinity);
    }

    return (principal: principal, interest: interest);
  }
}

class _AmortRow {
  final int month;
  final double principal;
  final double interest;
  const _AmortRow({required this.month, required this.principal, required this.interest});
}

/// Summary of a loan's current repayment state.
class LoanSummary {
  final double originalPrincipal;
  final double totalPrincipalRepaid;
  final double totalInterestPaid;
  final double totalAmountPaid;
  final double outstandingPrincipal;
  final int emisCompleted;
  final int emisRemaining;
  final int totalEmis;
  final DateTime? nextEmiDate;
  final double progressPercent;
  final bool isFullyRepaid;
  final double monthlyEmi;

  const LoanSummary({
    required this.originalPrincipal,
    required this.totalPrincipalRepaid,
    required this.totalInterestPaid,
    required this.totalAmountPaid,
    required this.outstandingPrincipal,
    required this.emisCompleted,
    required this.emisRemaining,
    required this.totalEmis,
    required this.nextEmiDate,
    required this.progressPercent,
    required this.isFullyRepaid,
    required this.monthlyEmi,
  });
}
