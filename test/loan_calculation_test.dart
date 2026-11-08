import 'package:flutter_test/flutter_test.dart';
import 'package:budget_buddy/core/models/loan.dart';

void main() {
  group('Loan Outstanding Balance & Tenure Calculations', () {
    test('1. 0% interest loan uses straight-line formula without divide-by-zero', () {
      // Principal = ₹1,20,000, Tenure = 12 months, Rate = 0%, EMI = ₹10,000
      final startDate = DateTime(2026, 1, 1);
      final loan = Loan(
        id: 'test-loan-0pct',
        userId: 'user-1',
        name: 'No-Cost EMI Phone',
        principal: 120000.0,
        interestRate: 0.0, // 0% interest
        emiAmount: 10000.0,
        tenureMonths: 12,
        startDate: startDate,
        status: 'active',
      );

      // At month 0 (start date): full principal remains
      expect(loan.estimatedOutstandingAt(DateTime(2026, 1, 1)), 120000.0);
      expect(loan.remainingMonthsAt(DateTime(2026, 1, 1)), 12);

      // At month 5: 5 months elapsed, 5 * 10,000 paid = ₹70,000 remaining
      final asOf5Months = DateTime(2026, 6, 1);
      expect(loan.elapsedMonthsAt(asOf5Months), 5);
      expect(loan.remainingMonthsAt(asOf5Months), 7);
      expect(loan.estimatedOutstandingAt(asOf5Months), 70000.0);

      // At month 11: 11 * 10,000 paid = ₹10,000 remaining
      final asOf11Months = DateTime(2026, 12, 1);
      expect(loan.estimatedOutstandingAt(asOf11Months), 10000.0);
    });

    test('2. Normal loan (>0% interest) uses standard reducing-balance formula', () {
      // Principal = ₹1,00,000, Tenure = 12 months, Rate = 12% p.a., EMI = ₹8,885
      final startDate = DateTime(2026, 1, 1);
      final loan = Loan(
        id: 'test-loan-normal',
        userId: 'user-1',
        name: 'Personal Loan',
        principal: 100000.0,
        interestRate: 12.0, // 12% annual = 1% monthly
        emiAmount: 8885.0,
        tenureMonths: 12,
        startDate: startDate,
        status: 'active',
      );

      // At commencement: full principal
      expect(loan.estimatedOutstandingAt(DateTime(2026, 1, 1)), 100000.0);

      // After 3 months:
      // B = 100000 * (1.01)^3 - 8885 * ((1.01)^3 - 1) / 0.01
      // (1.01)^3 = 1.030301
      // 100000 * 1.030301 = 103030.1
      // 8885 * 3.0301 = 26922.4385
      // B ≈ 76107.66
      final asOf3Months = DateTime(2026, 4, 1);
      final outstanding3 = loan.estimatedOutstandingAt(asOf3Months);
      expect(outstanding3, greaterThan(75000.0));
      expect(outstanding3, lessThan(77000.0));
      expect(loan.remainingMonthsAt(asOf3Months), 9);

      // After 6 months: outstanding balance should be lower than month 3
      final asOf6Months = DateTime(2026, 7, 1);
      final outstanding6 = loan.estimatedOutstandingAt(asOf6Months);
      expect(outstanding6, lessThan(outstanding3));
      expect(loan.remainingMonthsAt(asOf6Months), 6);
    });

    test('3. Finished loan (months elapsed >= tenure) returns 0.0 outstanding', () {
      final startDate = DateTime(2025, 1, 1);
      final loan = Loan(
        id: 'test-loan-finished',
        userId: 'user-1',
        name: 'Car Loan',
        principal: 500000.0,
        interestRate: 9.5,
        emiAmount: 12500.0,
        tenureMonths: 24, // 24 months tenure
        startDate: startDate,
        status: 'active',
      );

      // Exactly at month 24: finished
      final atTenureEnd = DateTime(2027, 1, 1);
      expect(loan.elapsedMonthsAt(atTenureEnd), 24);
      expect(loan.remainingMonthsAt(atTenureEnd), 0);
      expect(loan.estimatedOutstandingAt(atTenureEnd), 0.0);

      // Well past tenure (month 30): finished
      final pastTenure = DateTime(2027, 7, 1);
      expect(loan.elapsedMonthsAt(pastTenure), 30);
      expect(loan.remainingMonthsAt(pastTenure), 0);
      expect(loan.estimatedOutstandingAt(pastTenure), 0.0);
    });

    test('4. Future start date (months elapsed < 0) returns full principal and tenure', () {
      // Loan starting 6 months in the future: July 2027
      final startDate = DateTime(2027, 7, 1);
      final loan = Loan(
        id: 'test-loan-future',
        userId: 'user-1',
        name: 'Upcoming Home Loan',
        principal: 2500000.0,
        interestRate: 8.5,
        emiAmount: 24000.0,
        tenureMonths: 180,
        startDate: startDate,
        status: 'active',
      );

      // Current evaluation date: Jan 2027 (before start date)
      final beforeStart = DateTime(2027, 1, 1);
      expect(loan.elapsedMonthsAt(beforeStart), 0);
      expect(loan.remainingMonthsAt(beforeStart), 180);
      expect(loan.estimatedOutstandingAt(beforeStart), 2500000.0);
    });

    test('5. Closed loan explicitly returns 0.0 outstanding regardless of tenure or elapsed time', () {
      final startDate = DateTime(2026, 1, 1);
      final closedLoan = Loan(
        id: 'test-loan-closed',
        userId: 'user-1',
        name: 'Prepaid Loan',
        principal: 200000.0,
        interestRate: 11.0,
        emiAmount: 18000.0,
        tenureMonths: 24,
        startDate: startDate,
        status: 'closed', // explicitly closed / paid off early
      );

      final midTenure = DateTime(2026, 6, 1);
      expect(closedLoan.isClosed, isTrue);
      expect(closedLoan.estimatedOutstandingAt(midTenure), 0.0);
      expect(closedLoan.remainingMonthsAt(midTenure), 0);
    });
  });
}

