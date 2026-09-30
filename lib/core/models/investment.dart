import 'dart:math';

enum InvestmentType {
  sip('SIP / Mutual Fund', 'sip'),
  mutualFund('Mutual Funds', 'mutual_fund'),
  stocks('Stocks & Equity', 'stocks'),
  gold('Gold / SGB', 'gold'),
  fd('Fixed Deposit', 'fd'),
  ppf('PPF / EPF', 'ppf'),
  crypto('Crypto', 'crypto'),
  realEstate('Real Estate', 'real_estate'),
  other('Other Assets', 'other');

  final String label;
  final String code;
  const InvestmentType(this.label, this.code);

  static InvestmentType fromCode(String code) {
    return InvestmentType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => InvestmentType.other,
    );
  }
}

class Investment {
  final String? id;
  final String? userId;
  final String name;
  final InvestmentType type;
  final double investedAmount;
  final double currentValue;
  final double expectedReturnRate;
  final double monthlyContribution;
  final DateTime startDate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Investment({
    this.id,
    this.userId,
    required this.name,
    required this.type,
    required this.investedAmount,
    required this.currentValue,
    this.expectedReturnRate = 12.0,
    this.monthlyContribution = 0.0,
    required this.startDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  double get absoluteReturn => currentValue - investedAmount;
  double get returnPercentage =>
      investedAmount > 0 ? ((currentValue - investedAmount) / investedAmount) * 100 : 0.0;

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      name: json['name'] as String? ?? 'Investment',
      type: InvestmentType.fromCode(json['type'] as String? ?? 'sip'),
      investedAmount: (json['invested_amount'] as num?)?.toDouble() ?? 0.0,
      currentValue: (json['current_value'] as num?)?.toDouble() ?? 0.0,
      expectedReturnRate: (json['expected_return_rate'] as num?)?.toDouble() ?? 12.0,
      monthlyContribution: (json['monthly_contribution'] as num?)?.toDouble() ?? 0.0,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'type': type.code,
      'invested_amount': investedAmount,
      'current_value': currentValue,
      'expected_return_rate': expectedReturnRate,
      'monthly_contribution': monthlyContribution,
      'start_date': startDate.toIso8601String().split('T').first,
      if (notes != null) 'notes': notes,
    };
  }

  /// Helper to project future SIP returns:
  /// M = P * ({[1 + i]^n - 1} / i) * (1 + i)
  static Map<String, double> calculateSipReturns({
    required double monthlyInvestment,
    required double annualRate,
    required int years,
  }) {
    final i = (annualRate / 12) / 100;
    final n = years * 12;

    final totalInvested = monthlyInvestment * n;
    double futureValue = 0.0;
    if (i > 0) {
      final compFactor = pow(1 + i, n).toDouble();
      futureValue = monthlyInvestment * ((compFactor - 1) / i) * (1 + i);
    } else {
      futureValue = totalInvested;
    }

    final estimatedReturns = futureValue - totalInvested;
    return {
      'totalInvested': totalInvested,
      'estimatedReturns': estimatedReturns > 0 ? estimatedReturns : 0.0,
      'totalValue': futureValue,
    };
  }
}
