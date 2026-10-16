import 'package:flutter_test/flutter_test.dart';
import 'package:budget_buddy/core/models/emi_calculation.dart';
import 'package:budget_buddy/core/models/loan_payment.dart';
import 'package:budget_buddy/core/services/loan_payment_service.dart';

void main() {
  group('LoanPayment & LoanAdjustment Models', () {
    test('LoanPayment serialization and deserialization', () {
      final now = DateTime(2026, 10, 16, 12, 0);
      final payment = LoanPayment(
        id: 'lp_1',
        loanId: 'loan_123',
        userId: 'user_abc',
        emiNumber: 1,
        amountPaid: 25000.0,
        principalComponent: 18000.0,
        interestComponent: 7000.0,
        paymentDate: now,
        status: 'paid',
        reference: 'auto_debit',
        note: 'October EMI',
      );

      final json = payment.toJson();
      expect(json['id'], 'lp_1');
      expect(json['loan_id'], 'loan_123');
      expect(json['emi_number'], 1);
      expect(json['amount_paid'], 25000.0);
      expect(json['principal_component'], 18000.0);
      expect(json['interest_component'], 7000.0);
      expect(json['status'], 'paid');
      expect(json['reference'], 'auto_debit');
      expect(json['note'], 'October EMI');

      final deserialized = LoanPayment.fromJson(json);
      expect(deserialized.id, payment.id);
      expect(deserialized.loanId, payment.loanId);
      expect(deserialized.emiNumber, payment.emiNumber);
      expect(deserialized.amountPaid, payment.amountPaid);
      expect(deserialized.principalComponent, payment.principalComponent);
      expect(deserialized.interestComponent, payment.interestComponent);
      expect(deserialized.status, payment.status);
    });

    test('LoanAdjustment serialization and deserialization', () {
      final now = DateTime(2026, 10, 16, 12, 0);
      final adj = LoanAdjustment(
        id: 'adj_1',
        loanId: 'loan_123',
        userId: 'user_abc',
        amount: 50000.0,
        adjustmentType: 'extra_principal',
        note: 'Bonus payout prepayment',
        date: now,
      );

      final json = adj.toJson();
      expect(json['id'], 'adj_1');
      expect(json['amount'], 50000.0);
      expect(json['adjustment_type'], 'extra_principal');

      final deserialized = LoanAdjustment.fromJson(json);
      expect(deserialized.id, 'adj_1');
      expect(deserialized.amount, 50000.0);
      expect(deserialized.adjustmentType, 'extra_principal');
      expect(deserialized.note, 'Bonus payout prepayment');
    });
  });

  group('Amortization Decompose & Financial Calculations', () {
    const loan = EmiCalculation(
      id: 'test_loan',
      title: 'Home Loan',
      loanAmount: 1000000.0, // ₹10,00,000 (10 Lakhs)
      interestRate: 8.5,     // 8.5% p.a.
      tenureYears: 5,        // 5 Years (60 months)
      monthlyEmi: 20517.0,
      totalInterest: 231020.0,
      totalPayment: 1231020.0,
    );

    test('Month 1 principal and interest sum to monthly EMI', () {
      final m1 = LoanPaymentService.getPrincipalInterestForEmi(loan: loan, emiNumber: 1);
      expect(m1.principal + m1.interest, closeTo(loan.monthlyEmi, 1.0));
      // First month interest on 10 Lakhs at 8.5%/12 = 10,00,000 * 0.085 / 12 = ₹7,083.33
      expect(m1.interest, closeTo(7083.33, 5.0));
      expect(m1.principal, closeTo(loan.monthlyEmi - 7083.33, 5.0));
    });

    test('Later months have higher principal and lower interest', () {
      final m1 = LoanPaymentService.getPrincipalInterestForEmi(loan: loan, emiNumber: 1);
      final m30 = LoanPaymentService.getPrincipalInterestForEmi(loan: loan, emiNumber: 30);
      final m60 = LoanPaymentService.getPrincipalInterestForEmi(loan: loan, emiNumber: 60);

      expect(m30.principal, greaterThan(m1.principal));
      expect(m30.interest, lessThan(m1.interest));

      expect(m60.principal, greaterThan(m30.principal));
      expect(m60.interest, lessThan(m30.interest));
    });

    test('LoanSummary calculation with zero payments', () {
      final summary = LoanPaymentService.calculateSummary(
        loan: loan,
        payments: [],
        adjustments: [],
      );

      expect(summary.totalPrincipalRepaid, 0.0);
      expect(summary.totalInterestPaid, 0.0);
      expect(summary.outstandingPrincipal, closeTo(1000000.0, 1.0));
      expect(summary.emisCompleted, 0);
      expect(summary.emisRemaining, 60);
      expect(summary.isFullyRepaid, false);
      expect(summary.progressPercent, 0.0);
    });

    test('LoanSummary calculation with payments and adjustments', () {
      final p1 = LoanPayment(
        id: 'p1',
        loanId: 'test_loan',
        emiNumber: 1,
        amountPaid: 20517.0,
        principalComponent: 13433.0,
        interestComponent: 7084.0,
        paymentDate: DateTime.now(),
        status: 'paid',
      );

      final adj = LoanAdjustment(
        id: 'a1',
        loanId: 'test_loan',
        amount: 50000.0,
        adjustmentType: 'extra_principal',
        date: DateTime.now(),
      );

      final summary = LoanPaymentService.calculateSummary(
        loan: loan,
        payments: [p1],
        adjustments: [adj],
      );

      expect(summary.emisCompleted, 1);
      expect(summary.totalPrincipalRepaid, 13433.0 + 50000.0);
      expect(summary.totalInterestPaid, 7084.0);
      // Outstanding principal = 1,000,000 - 13,433 - 50,000 = 936,567
      expect(summary.outstandingPrincipal, closeTo(936567.0, 1.0));
      expect(summary.progressPercent, closeTo((13433 + 50000) / 1000000.0, 0.01));
      expect(summary.isFullyRepaid, false);
    });
  });
}
