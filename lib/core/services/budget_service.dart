import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../supabase_client.dart';

/// Service for Budget and Savings Goal CRUD — routes to Supabase (cloud users)
/// or Hive (guest users) based on the [isGuest] flag.
class BudgetService {
  BudgetService._();

  static const _uuid = Uuid();

  // ── Budgets ──

  /// Create a new budget entry.
  static Future<Map<String, dynamic>> createBudget({
    required double amount,
    String? categoryId,
    DateTime? periodMonth,
    required bool isGuest,
  }) async {
    final now = DateTime.now();
    final period = periodMonth ?? DateTime(now.year, now.month, 1);
    final data = <String, dynamic>{
      'id': _uuid.v4(),
      'amount': amount,
      'category_id': categoryId,
      'period_month': period.toIso8601String().split('T')[0],
      'created_at': now.toIso8601String(),
    };

    if (isGuest) {
      final box = await Hive.openBox('guest_budgets');
      data['user_id'] = 'guest';
      await box.put(data['id'], data);
      return data;
    }

    data['user_id'] = SupabaseClientHelper.currentUser!.id;
    final response = await SupabaseClientHelper.client
        .from('budgets')
        .insert(data)
        .select()
        .single();
    return response;
  }

  /// Get all budgets for the current period.
  static Future<List<Map<String, dynamic>>> getBudgets({
    required bool isGuest,
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;
    final periodStr = DateTime(y, m, 1).toIso8601String().split('T')[0];

    if (isGuest) {
      final box = await Hive.openBox('guest_budgets');
      final all = box.values.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      return all
          .where((b) => b['period_month'] == periodStr)
          .toList();
    }

    final response = await SupabaseClientHelper.client
        .from('budgets')
        .select()
        .eq('period_month', periodStr)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Delete a budget by ID.
  static Future<void> deleteBudget({
    required String id,
    required bool isGuest,
  }) async {
    if (isGuest) {
      final box = await Hive.openBox('guest_budgets');
      await box.delete(id);
      return;
    }
    await SupabaseClientHelper.client.from('budgets').delete().eq('id', id);
  }

  // ── Savings Goals ──

  /// Create a new savings goal.
  static Future<Map<String, dynamic>> createGoal({
    required String title,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? targetDate,
    required bool isGuest,
  }) async {
    final now = DateTime.now();
    final data = <String, dynamic>{
      'id': _uuid.v4(),
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate?.toIso8601String().split('T')[0],
      'created_at': now.toIso8601String(),
    };

    if (isGuest) {
      final box = await Hive.openBox('guest_goals');
      data['user_id'] = 'guest';
      await box.put(data['id'], data);
      return data;
    }

    data['user_id'] = SupabaseClientHelper.currentUser!.id;
    final response = await SupabaseClientHelper.client
        .from('savings_goals')
        .insert(data)
        .select()
        .single();
    return response;
  }

  /// Get all savings goals.
  static Future<List<Map<String, dynamic>>> getGoals({
    required bool isGuest,
  }) async {
    if (isGuest) {
      final box = await Hive.openBox('guest_goals');
      return box.values.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    final response = await SupabaseClientHelper.client
        .from('savings_goals')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Update the saved amount for a goal.
  static Future<void> updateGoalAmount({
    required String id,
    required double currentAmount,
    required bool isGuest,
  }) async {
    if (isGuest) {
      final box = await Hive.openBox('guest_goals');
      final existing = Map<String, dynamic>.from(box.get(id) as Map);
      existing['current_amount'] = currentAmount;
      await box.put(id, existing);
      return;
    }
    await SupabaseClientHelper.client
        .from('savings_goals')
        .update({'current_amount': currentAmount})
        .eq('id', id);
  }

  /// Delete a savings goal by ID.
  static Future<void> deleteGoal({
    required String id,
    required bool isGuest,
  }) async {
    if (isGuest) {
      final box = await Hive.openBox('guest_goals');
      await box.delete(id);
      return;
    }
    await SupabaseClientHelper.client.from('savings_goals').delete().eq('id', id);
  }
}
