/// Data model for a budget (overall or per-category, per month).
class Budget {
  final String id;
  final String userId;
  final String? categoryId; // null = overall budget
  final double amount;
  final DateTime periodMonth; // first day of the budget month
  final DateTime createdAt;

  const Budget({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.amount,
    required this.periodMonth,
    required this.createdAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      periodMonth: DateTime.parse(json['period_month'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category_id': categoryId,
        'amount': amount,
        'period_month': periodMonth.toIso8601String().split('T')[0],
      };

  bool get isOverallBudget => categoryId == null;

  Budget copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    DateTime? periodMonth,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      periodMonth: periodMonth ?? this.periodMonth,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
