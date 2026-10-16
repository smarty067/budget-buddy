/// Model representing a single EMI/loan payment record.
class LoanPayment {
  final String? id;
  final String loanId;
  final String? userId;
  final int emiNumber;
  final double amountPaid;
  final double principalComponent;
  final double interestComponent;
  final DateTime paymentDate;
  final String status; // 'paid', 'partial', 'missed'
  final String? reference;
  final String? note;
  final DateTime? createdAt;

  const LoanPayment({
    this.id,
    required this.loanId,
    this.userId,
    required this.emiNumber,
    required this.amountPaid,
    required this.principalComponent,
    required this.interestComponent,
    required this.paymentDate,
    this.status = 'paid',
    this.reference,
    this.note,
    this.createdAt,
  });

  factory LoanPayment.fromJson(Map<String, dynamic> json) {
    return LoanPayment(
      id: json['id'] as String?,
      loanId: json['loan_id'] as String? ?? '',
      userId: json['user_id'] as String?,
      emiNumber: (json['emi_number'] as num?)?.toInt() ?? 0,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
      principalComponent: (json['principal_component'] as num?)?.toDouble() ?? 0.0,
      interestComponent: (json['interest_component'] as num?)?.toDouble() ?? 0.0,
      paymentDate: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? 'paid',
      reference: json['reference'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'loan_id': loanId,
      if (userId != null) 'user_id': userId,
      'emi_number': emiNumber,
      'amount_paid': amountPaid,
      'principal_component': principalComponent,
      'interest_component': interestComponent,
      'payment_date': paymentDate.toIso8601String().split('T').first,
      'status': status,
      if (reference != null) 'reference': reference,
      if (note != null) 'note': note,
    };
  }
}

/// Model representing a manual balance adjustment on a loan.
class LoanAdjustment {
  final String? id;
  final String loanId;
  final String? userId;
  final String adjustmentType; // 'extra_principal', 'balance_correction', 'other'
  final double amount;
  final String? note;
  final DateTime date;
  final DateTime? createdAt;

  const LoanAdjustment({
    this.id,
    required this.loanId,
    this.userId,
    required this.adjustmentType,
    required this.amount,
    this.note,
    required this.date,
    this.createdAt,
  });

  factory LoanAdjustment.fromJson(Map<String, dynamic> json) {
    return LoanAdjustment(
      id: json['id'] as String?,
      loanId: json['loan_id'] as String? ?? '',
      userId: json['user_id'] as String?,
      adjustmentType: json['adjustment_type'] as String? ?? 'other',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String?,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'loan_id': loanId,
      if (userId != null) 'user_id': userId,
      'adjustment_type': adjustmentType,
      'amount': amount,
      if (note != null) 'note': note,
      'date': date.toIso8601String().split('T').first,
    };
  }
}
