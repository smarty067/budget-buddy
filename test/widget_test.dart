import 'package:flutter_test/flutter_test.dart';
import 'package:budget_buddy/core/models/transaction.dart';

void main() {
  group('Transaction Model Tests', () {
    test('Transaction parsing and helper methods', () {
      final now = DateTime.now();
      final tx = Transaction(
        id: '1',
        userId: 'user_123',
        categoryId: 'cat_abc',
        type: 'expense',
        amount: 250.50,
        note: 'Lunch with friends',
        transactionDate: now,
        createdAt: now,
        categoryName: 'Food',
        categoryIcon: 'restaurant',
      );

      expect(tx.id, '1');
      expect(tx.userId, 'user_123');
      expect(tx.isExpense, true);
      expect(tx.isIncome, false);
      expect(tx.amount, 250.50);

      final json = tx.toJson();
      expect(json['id'], '1');
      expect(json['amount'], 250.50);
      expect(json['type'], 'expense');
    });
  });
}
