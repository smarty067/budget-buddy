import 'dart:math';

/// Domain model representing a user's Loan in Budget Buddy.
class Loan {
  final String id;
  final String userId;
  final String name;
  final double principal;
  final double interestRate; // Annual interest rate in %
  final double emiAmount;
  final int tenureMonths;
  final DateTime startDate;
  final String status; // 'active' or 'closed'
  final DateTime? createdAt;

  const Loan({
    required this.id,
    required this.userId,
    required this.name,
    required this.principal,
    required this.interestRate,
    required this.emiAmount,
    required this.tenureMonths,
    required this.startDate,
    this.status = 'active',
    this.createdAt,
  });

  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed';

  /// Number of months elapsed since start date relative to [asOf] (defaults to DateTime.now()).
  /// Returns 0 if start date is in the future.
  int elapsedMonthsAt([DateTime? asOf]) {
    final target = asOf ?? DateTime.now();
    final months = (target.year - startDate.year) * 12 + (target.month - startDate.month);
    return max(0, months);
  }

  /// Number of months elapsed since start date.
  int get elapsedMonths => elapsedMonthsAt();

  /// Number of tenure months remaining relative to [asOf].
  int remainingMonthsAt([DateTime? asOf]) {
    if (isClosed) return 0;
    final elapsed = elapsedMonthsAt(asOf);
    if (elapsed >= tenureMonths) return 0;
    return max(0, tenureMonths - elapsed);
  }

  /// Number of tenure months remaining.
  int get remainingMonths => remainingMonthsAt();

  /// Estimated outstanding balance relative to [asOf] (defaults to DateTime.now()):
  /// - If loan is closed: returns 0.0
  /// - If months elapsed < 0 (future start date) or 0: returns full principal
  /// - If months elapsed >= tenure: returns 0.0 (finished loan)
  /// - If 0% interest rate: uses straight-line reduction (no divide-by-zero)
  /// - If interest rate > 0: uses reducing-balance formula:
  ///   B = P * (1 + r)^m - EMI * ((1 + r)^m - 1) / r
  ///   where r = (annual interest rate / 12) / 100, m = months elapsed
  double estimatedOutstandingAt([DateTime? asOf]) {
    if (isClosed) return 0.0;

    final target = asOf ?? DateTime.now();
    // Raw month difference without clamping to detect future start dates
    final rawMonths = (target.year - startDate.year) * 12 + (target.month - startDate.month);

    // Future start date or commencement month: full principal remains
    if (rawMonths <= 0) return principal;

    // Completed tenure: loan is finished
    if (rawMonths >= tenureMonths) return 0.0;

    final m = rawMonths;
    final r = (interestRate / 12.0) / 100.0;

    // Straight-line deduction for 0% interest loans (no divide-by-zero)
    if (r == 0 || interestRate <= 0) {
      final monthlyDeduction = emiAmount > 0
          ? emiAmount
          : (tenureMonths > 0 ? principal / tenureMonths : 0.0);
      final balance = principal - (monthlyDeduction * m);
      return max(0.0, balance);
    }

    // Standard reducing balance formula
    final powFactor = pow(1.0 + r, m);
    final balance = (principal * powFactor) - (emiAmount * (powFactor - 1.0) / r);
    return max(0.0, balance);
  }

  /// Estimated outstanding balance.
  double get estimatedOutstanding => estimatedOutstandingAt();

  factory Loan.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) {
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return Loan(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      principal: (json['principal'] as num?)?.toDouble() ?? 0.0,
      interestRate: (json['interest_rate'] as num?)?.toDouble() ?? 0.0,
      emiAmount: (json['emi_amount'] as num?)?.toDouble() ?? 0.0,
      tenureMonths: (json['tenure_months'] as num?)?.toInt() ?? 0,
      startDate: parseDate(json['start_date']),
      status: json['status']?.toString() ?? 'active',
      createdAt: json['created_at'] != null ? parseDate(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final y = startDate.year.toString().padLeft(4, '0');
    final m = startDate.month.toString().padLeft(2, '0');
    final d = startDate.day.toString().padLeft(2, '0');
    final startDateStr = '$y-$m-$d';

    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'principal': principal,
      'interest_rate': interestRate,
      'emi_amount': emiAmount,
      'tenure_months': tenureMonths,
      'start_date': startDateStr,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Loan copyWith({
    String? id,
    String? userId,
    String? name,
    double? principal,
    double? interestRate,
    double? emiAmount,
    int? tenureMonths,
    DateTime? startDate,
    String? status,
    DateTime? createdAt,
  }) {
    return Loan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      principal: principal ?? this.principal,
      interestRate: interestRate ?? this.interestRate,
      emiAmount: emiAmount ?? this.emiAmount,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      startDate: startDate ?? this.startDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

