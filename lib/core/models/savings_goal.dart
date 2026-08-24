/// Data model for a savings goal.
class SavingsGoal {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final DateTime createdAt;

  const SavingsGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.targetDate,
    required this.createdAt,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'target_date': targetDate?.toIso8601String().split('T')[0],
      };

  /// Progress as a fraction from 0.0 to 1.0.
  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  /// Progress as a percentage (0–100).
  int get progressPercent => (progress * 100).round();

  /// Remaining amount to reach the goal.
  double get remaining => (targetAmount - currentAmount).clamp(0, targetAmount);

  /// Whether the goal has been fully achieved.
  bool get isComplete => currentAmount >= targetAmount;

  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    DateTime? createdAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
