/// Model representing a historical valuation update for an investment.
class InvestmentValuationHistory {
  final String? id;
  final String investmentId;
  final String? userId;
  final double previousValue;
  final double newValue;
  final double amountChanged;
  final double percentageChanged;
  final String updateType; // 'manual_growth', 'manual_decrease', 'market_update', 'purchase', 'sale', 'other'
  final DateTime timestamp;
  final String? note;

  const InvestmentValuationHistory({
    this.id,
    required this.investmentId,
    this.userId,
    required this.previousValue,
    required this.newValue,
    required this.amountChanged,
    required this.percentageChanged,
    required this.updateType,
    required this.timestamp,
    this.note,
  });

  factory InvestmentValuationHistory.fromJson(Map<String, dynamic> json) {
    return InvestmentValuationHistory(
      id: json['id'] as String?,
      investmentId: json['investment_id'] as String? ?? '',
      userId: json['user_id'] as String?,
      previousValue: (json['previous_value'] as num?)?.toDouble() ?? 0.0,
      newValue: (json['new_value'] as num?)?.toDouble() ?? 0.0,
      amountChanged: (json['amount_changed'] as num?)?.toDouble() ?? 0.0,
      percentageChanged: (json['percentage_changed'] as num?)?.toDouble() ?? 0.0,
      updateType: json['update_type'] as String? ?? 'other',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'investment_id': investmentId,
      if (userId != null) 'user_id': userId,
      'previous_value': previousValue,
      'new_value': newValue,
      'amount_changed': amountChanged,
      'percentage_changed': percentageChanged,
      'update_type': updateType,
      'timestamp': timestamp.toIso8601String(),
      if (note != null) 'note': note,
    };
  }
}
