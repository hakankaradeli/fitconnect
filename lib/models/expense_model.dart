class ExpenseModel {
  final int id;
  final String category;
  final String title;
  final double amount;
  final DateTime expenseDate;
  final String? trainerName;
  final String? notes;

  ExpenseModel({
    required this.id,
    required this.category,
    required this.title,
    required this.amount,
    required this.expenseDate,
    this.trainerName,
    this.notes,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      category: json['category'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(json['expenseDate']),
      trainerName: json['trainer'] != null ? json['trainer']['fullName'] : null,
      notes: json['notes'],
    );
  }

  String get categoryText {
    switch (category) {
      case 'TRAINER_EARNINGS':
        return "Eğitmen Hakediş Ödemesi";
      case 'TRAINER_INSURANCE':
        return "Eğitmen Sigorta Primi";
      case 'TAX':
        return "Vergiler";
      case 'ELECTRICITY':
        return "Elektrik Faturası";
      case 'WATER':
        return "Su Faturası";
      case 'NATURAL_GAS':
        return "Doğalgaz Faturası";
      case 'RENT':
        return "Kira";
      case 'ACCOUNTANT':
        return "Muhasebeci Ücreti";
      case 'BAGKUR':
        return "Bağkur Primi";
      case 'OTHER':
        return "Diğer Gider";
      default:
        return category;
    }
  }
}
