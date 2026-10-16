import 'package:flutter_test/flutter_test.dart';
import 'package:budget_buddy/core/models/investment.dart';
import 'package:budget_buddy/core/models/investment_valuation_history.dart';
import 'package:budget_buddy/core/services/investment_valuation_service.dart';

void main() {
  group('InvestmentValuationHistory Model', () {
    test('serialization and deserialization', () {
      final now = DateTime(2026, 10, 16, 14, 30);
      final history = InvestmentValuationHistory(
        id: 'ivh_1',
        investmentId: 'inv_100',
        userId: 'user_xyz',
        previousValue: 50000.0,
        newValue: 55000.0,
        amountChanged: 5000.0,
        percentageChanged: 10.0,
        updateType: 'manual_growth',
        timestamp: now,
        note: 'Quarterly valuation increase',
      );

      final json = history.toJson();
      expect(json['id'], 'ivh_1');
      expect(json['investment_id'], 'inv_100');
      expect(json['previous_value'], 50000.0);
      expect(json['new_value'], 55000.0);
      expect(json['amount_changed'], 5000.0);
      expect(json['percentage_changed'], 10.0);
      expect(json['update_type'], 'manual_growth');
      expect(json['note'], 'Quarterly valuation increase');

      final deserialized = InvestmentValuationHistory.fromJson(json);
      expect(deserialized.id, history.id);
      expect(deserialized.investmentId, history.investmentId);
      expect(deserialized.previousValue, history.previousValue);
      expect(deserialized.newValue, history.newValue);
      expect(deserialized.amountChanged, history.amountChanged);
      expect(deserialized.percentageChanged, history.percentageChanged);
      expect(deserialized.updateType, history.updateType);
      expect(deserialized.note, history.note);
    });
  });

  group('Investment Valuation Calculations & Cost Basis Invariance', () {
    test('Growth calculation correctly increases value and computes percentages', () {
      final result = InvestmentValuationService.calculateGrowth(
        currentValue: 100000.0,
        growthAmount: 15000.0,
      );

      expect(result.newValue, 115000.0);
      expect(result.amountChange, 15000.0);
      expect(result.percentChange, closeTo(15.0, 0.01));
    });

    test('Decrease calculation correctly decreases value and caps at zero', () {
      final result = InvestmentValuationService.calculateDecrease(
        currentValue: 100000.0,
        decreaseAmount: 8000.0,
      );

      expect(result.newValue, 92000.0);
      expect(result.amountChange, -8000.0);
      expect(result.percentChange, closeTo(-8.0, 0.01));

      // Cannot go below zero
      final overDrop = InvestmentValuationService.calculateDecrease(
        currentValue: 5000.0,
        decreaseAmount: 10000.0,
      );
      expect(overDrop.newValue, 0.0);
    });

    test('calculateChangeFromNewValue calculates correct delta', () {
      final change = InvestmentValuationService.calculateChangeFromNewValue(
        previousValue: 80000.0,
        newValue: 100000.0,
      );

      expect(change.amountChange, 20000.0);
      expect(change.percentChange, closeTo(25.0, 0.01));
    });

    test('Unrealized Profit/Loss and Returns against cost basis', () {
      const costBasis = 100000.0;
      const marketValueGain = 125000.0;
      const marketValueLoss = 85000.0;

      // Gain scenario
      final profit = InvestmentValuationService.unrealizedProfitLoss(marketValueGain, costBasis);
      final returnPctGain = InvestmentValuationService.unrealizedReturnPercentage(marketValueGain, costBasis);
      expect(profit, 25000.0);
      expect(returnPctGain, closeTo(25.0, 0.01));

      // Loss scenario
      final loss = InvestmentValuationService.unrealizedProfitLoss(marketValueLoss, costBasis);
      final returnPctLoss = InvestmentValuationService.unrealizedReturnPercentage(marketValueLoss, costBasis);
      expect(loss, -15000.0);
      expect(returnPctLoss, closeTo(-15.0, 0.01));
    });

    test('Cost basis remains strictly unchanged when valuation updates', () {
      final initialInvestment = Investment(
        id: 'inv_1',
        name: 'Nifty 50 Index Fund',
        type: InvestmentType.mutualFund,
        investedAmount: 50000.0, // Cost basis
        currentValue: 50000.0,
        monthlyContribution: 5000.0,
        startDate: DateTime(2025, 1, 1),
      );

      // Simulate a valuation update
      const newMarketValue = 62000.0;
      final updatedInvestment = Investment(
        id: initialInvestment.id,
        name: initialInvestment.name,
        type: initialInvestment.type,
        investedAmount: initialInvestment.investedAmount, // preserved cost basis
        currentValue: newMarketValue,
        monthlyContribution: initialInvestment.monthlyContribution,
        startDate: initialInvestment.startDate,
      );

      // Verify cost basis invariant
      expect(updatedInvestment.investedAmount, 50000.0);
      expect(updatedInvestment.currentValue, 62000.0);
      expect(updatedInvestment.investedAmount, equals(initialInvestment.investedAmount));
      expect(updatedInvestment.currentValue, isNot(equals(initialInvestment.currentValue)));
      expect(updatedInvestment.returnPercentage, closeTo(24.0, 0.01));
    });
  });
}
