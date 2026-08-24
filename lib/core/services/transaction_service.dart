import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../supabase_client.dart';

/// Service for transaction CRUD operations — routes to Supabase (cloud users)
/// or Hive (guest users) based on the [isGuest] flag.
class TransactionService {
  TransactionService._();

  static const _uuid = Uuid();
  static const _guestBoxName = 'guest_transactions';

  /// Create a new transaction.
  static Future<Map<String, dynamic>> create({
    required String categoryId,
    required String type, // 'expense' or 'income'
    required double amount,
    String? note,
    DateTime? transactionDate,
    String? categoryName,
    required bool isGuest,
  }) async {
    final now = DateTime.now();
    final dateStr =
        (transactionDate ?? now).toIso8601String().split('T')[0];

    if (isGuest) {
      final data = {
        'id': _uuid.v4(),
        'user_id': 'guest',
        'category_id': categoryId,
        'type': type,
        'amount': amount,
        'note': note,
        'transaction_date': dateStr,
        'created_at': now.toIso8601String(),
        'category_name': categoryName,
      };
      final box = await Hive.openBox(_guestBoxName);
      await box.put(data['id'], data);
      return data;
    }

    final data = {
      'user_id': SupabaseClientHelper.currentUser!.id,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'note': note,
      'transaction_date': dateStr,
    };

    final response = await SupabaseClientHelper.client
        .from('transactions')
        .insert(data)
        .select('*, categories(name, icon)')
        .single();
    return response;
  }

  /// Get all transactions for the current user, newest first.
  static Future<List<Map<String, dynamic>>> getAll({
    int limit = 50,
    int offset = 0,
    required bool isGuest,
  }) async {
    if (isGuest) {
      final box = await Hive.openBox(_guestBoxName);
      final all = box.values
          .cast<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      // Sort newest first
      all.sort((a, b) {
        final aDate = a['transaction_date'] as String? ?? '';
        final bDate = b['transaction_date'] as String? ?? '';
        return bDate.compareTo(aDate);
      });
      return all.skip(offset).take(limit).toList();
    }

    final response = await SupabaseClientHelper.client
        .from('transactions')
        .select('*, categories(name, icon)')
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get recent transactions (last N entries).
  static Future<List<Map<String, dynamic>>> getRecent({
    int limit = 10,
    required bool isGuest,
  }) async {
    return getAll(limit: limit, isGuest: isGuest);
  }

  /// Get transactions for a specific month.
  static Future<List<Map<String, dynamic>>> getByMonth({
    required int year,
    required int month,
    required bool isGuest,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // last day of month
    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];

    if (isGuest) {
      final box = await Hive.openBox(_guestBoxName);
      final all = box.values
          .cast<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return all.where((t) {
        final date = t['transaction_date'] as String? ?? '';
        return date.compareTo(startStr) >= 0 && date.compareTo(endStr) <= 0;
      }).toList()
        ..sort((a, b) {
          final aDate = a['transaction_date'] as String? ?? '';
          final bDate = b['transaction_date'] as String? ?? '';
          return bDate.compareTo(aDate);
        });
    }

    final response = await SupabaseClientHelper.client
        .from('transactions')
        .select('*, categories(name, icon)')
        .gte('transaction_date', startStr)
        .lte('transaction_date', endStr)
        .order('transaction_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Update an existing transaction.
  static Future<Map<String, dynamic>> update({
    required String id,
    String? categoryId,
    String? type,
    double? amount,
    String? note,
    DateTime? transactionDate,
    required bool isGuest,
  }) async {
    if (isGuest) {
      final box = await Hive.openBox(_guestBoxName);
      final existing = Map<String, dynamic>.from(box.get(id) as Map);
      if (categoryId != null) existing['category_id'] = categoryId;
      if (type != null) existing['type'] = type;
      if (amount != null) existing['amount'] = amount;
      if (note != null) existing['note'] = note;
      if (transactionDate != null) {
        existing['transaction_date'] =
            transactionDate.toIso8601String().split('T')[0];
      }
      await box.put(id, existing);
      return existing;
    }

    final data = <String, dynamic>{};
    if (categoryId != null) data['category_id'] = categoryId;
    if (type != null) data['type'] = type;
    if (amount != null) data['amount'] = amount;
    if (note != null) data['note'] = note;
    if (transactionDate != null) {
      data['transaction_date'] =
          transactionDate.toIso8601String().split('T')[0];
    }

    final response = await SupabaseClientHelper.client
        .from('transactions')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return response;
  }

  /// Delete a transaction by ID.
  static Future<void> delete({
    required String id,
    required bool isGuest,
  }) async {
    if (isGuest) {
      final box = await Hive.openBox(_guestBoxName);
      await box.delete(id);
      return;
    }
    await SupabaseClientHelper.client
        .from('transactions')
        .delete()
        .eq('id', id);
  }

  /// Get total spent/income for the current month.
  static Future<Map<String, double>> getCurrentMonthTotals({
    required bool isGuest,
  }) async {
    final now = DateTime.now();
    final transactions =
        await getByMonth(year: now.year, month: now.month, isGuest: isGuest);

    double totalExpense = 0;
    double totalIncome = 0;
    for (final t in transactions) {
      final amount = (t['amount'] as num).toDouble();
      if (t['type'] == 'expense') {
        totalExpense += amount;
      } else {
        totalIncome += amount;
      }
    }
    return {'expense': totalExpense, 'income': totalIncome};
  }
}
