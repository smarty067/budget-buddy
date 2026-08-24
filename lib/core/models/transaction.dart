/// Data model for a financial transaction (expense or income).
class Transaction {
  final String id;
  final String userId;
  final String categoryId;
  final String type; // 'expense' or 'income'
  final double amount;
  final String? note;
  final DateTime transactionDate;
  final DateTime createdAt;

  // Joined fields from categories table
  final String? categoryName;
  final String? categoryIcon;

  const Transaction({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.type,
    required this.amount,
    this.note,
    required this.transactionDate,
    required this.createdAt,
    this.categoryName,
    this.categoryIcon,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final category = json['categories'] as Map<String, dynamic>?;
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      categoryName: category?['name'] as String?,
      categoryIcon: category?['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category_id': categoryId,
        'type': type,
        'amount': amount,
        'note': note,
        'transaction_date': transactionDate.toIso8601String().split('T')[0],
      };

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  Transaction copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? type,
    double? amount,
    String? note,
    DateTime? transactionDate,
    DateTime? createdAt,
    String? categoryName,
    String? categoryIcon,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
    );
  }
}
