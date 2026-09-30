import 'dart:math';

class EmiCalculation {
  final String? id;
  final String? userId;
  final String title;
  final double loanAmount;
  final double interestRate; // Annual % (e.g. 9.5)
  final int tenureYears;
  final double monthlyEmi;
  final double totalInterest;
  final double totalPayment;
  final DateTime? createdAt;

  const EmiCalculation({
    this.id,
    this.userId,
    required this.title,
    required this.loanAmount,
    required this.interestRate,
    required this.tenureYears,
    required this.monthlyEmi,
    required this.totalInterest,
    required this.totalPayment,
    this.createdAt,
  });

  /// Calculate EMI formula: E = P * r * (1 + r)^n / ((1 + r)^n - 1)
  factory EmiCalculation.compute({
    String? id,
    String? userId,
    String title = 'Loan Calculation',
    required double loanAmount,
    required double interestRate,
    required int tenureYears,
    DateTime? createdAt,
  }) {
    final n = tenureYears * 12; // Total monthly installments
    final r = (interestRate / 12) / 100; // Monthly interest rate decimal

    double emi = 0.0;
    if (r > 0) {
      final powerFactor = pow(1 + r, n).toDouble();
      emi = (loanAmount * r * powerFactor) / (powerFactor - 1);
    } else {
      emi = loanAmount / n;
    }

    final totalPayment = emi * n;
    final totalInterest = totalPayment - loanAmount;

    return EmiCalculation(
      id: id,
      userId: userId,
      title: title,
      loanAmount: loanAmount,
      interestRate: interestRate,
      tenureYears: tenureYears,
      monthlyEmi: emi,
      totalInterest: totalInterest > 0 ? totalInterest : 0.0,
      totalPayment: totalPayment,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  factory EmiCalculation.fromJson(Map<String, dynamic> json) {
    return EmiCalculation(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      title: json['title'] as String? ?? 'Loan Calculation',
      loanAmount: (json['loan_amount'] as num?)?.toDouble() ?? 0.0,
      interestRate: (json['interest_rate'] as num?)?.toDouble() ?? 0.0,
      tenureYears: (json['tenure_years'] as num?)?.toInt() ?? 1,
      monthlyEmi: (json['monthly_emi'] as num?)?.toDouble() ?? 0.0,
      totalInterest: (json['total_interest'] as num?)?.toDouble() ?? 0.0,
      totalPayment: (json['total_payment'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'title': title,
      'loan_amount': loanAmount,
      'interest_rate': interestRate,
      'tenure_years': tenureYears,
      'monthly_emi': monthlyEmi,
      'total_interest': totalInterest,
      'total_payment': totalPayment,
    };
  }

  /// Generate full amortization schedule breakdown by year
  List<AmortizationYear> getAmortizationSchedule() {
    final n = tenureYears * 12;
    final r = (interestRate / 12) / 100;
    double balance = loanAmount;
    final List<AmortizationYear> schedule = [];

    double yearlyPrincipal = 0;
    double yearlyInterest = 0;

    for (int month = 1; month <= n; month++) {
      final interest = balance * r;
      final principal = monthlyEmi - interest;
      balance = (balance - principal) > 0 ? (balance - principal) : 0;

      yearlyPrincipal += principal;
      yearlyInterest += interest;

      if (month % 12 == 0 || month == n) {
        final yearNum = (month / 12).ceil();
        schedule.add(
          AmortizationYear(
            year: yearNum,
            principalPaid: yearlyPrincipal,
            interestPaid: yearlyInterest,
            totalPaid: yearlyPrincipal + yearlyInterest,
            remainingBalance: balance,
          ),
        );
        yearlyPrincipal = 0;
        yearlyInterest = 0;
      }
    }
    return schedule;
  }
}

class AmortizationYear {
  final int year;
  final double principalPaid;
  final double interestPaid;
  final double totalPaid;
  final double remainingBalance;

  const AmortizationYear({
    required this.year,
    required this.principalPaid,
    required this.interestPaid,
    required this.totalPaid,
    required this.remainingBalance,
  });
}
