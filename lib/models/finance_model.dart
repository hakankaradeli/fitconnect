enum PaymentStatus { pending, paid, overdue }

class PaymentPlan {
  final int id;
  final String memberName;
  final double amount;
  final DateTime dueDate;
  PaymentStatus status;
  final int creditsToLoad;

  PaymentPlan({
    required this.id, 
    required this.memberName,
    required this.amount, 
    required this.dueDate, 
    required this.creditsToLoad,
    this.status = PaymentStatus.pending
  });

  factory PaymentPlan.fromJson(Map<String, dynamic> json) {
    PaymentStatus status;
    switch (json['status']) {
      case 'PAID': status = PaymentStatus.paid; break;
      case 'OVERDUE': status = PaymentStatus.overdue; break;
      default: status = PaymentStatus.pending;
    }
    
    return PaymentPlan(
      id: json['id'],
      memberName: json['member']['fullName'],
      amount: json['amount'].toDouble(),
      dueDate: DateTime.parse(json['dueDate']),
      creditsToLoad: json['creditsToLoad'],
      status: status,
    );
  }
}

class MemberBalance {
  int totalCredits;
  int usedCredits;
  
  int get netBalance => totalCredits - usedCredits;

  MemberBalance({
    required this.totalCredits,
    required this.usedCredits,
  });
}
