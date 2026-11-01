enum LessonType { pt1to1, ptDuo, reformerGroup }

class AccrualEntry {
  final String id;
  final DateTime date;
  final String memberName;
  final LessonType lessonType;
  final double amount;

  AccrualEntry({
    required this.id,
    required this.date,
    required this.memberName,
    required this.lessonType,
    required this.amount,
  });

  factory AccrualEntry.fromJson(Map<String, dynamic> json) {
    LessonType type = LessonType.pt1to1;
    final typeStr = (json['lessonType'] ?? '').toString().toLowerCase();
    if (typeStr.contains('duo') || typeStr.contains('2')) {
      type = LessonType.ptDuo;
    } else if (typeStr.contains('reformer') || typeStr.contains('pilates')) {
      type = LessonType.reformerGroup;
    }

    DateTime parsedDate = DateTime.now();
    if (json['date'] != null) {
      parsedDate = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    }

    return AccrualEntry(
      id: json['id']?.toString() ?? '',
      date: parsedDate,
      memberName: json['memberName'] ?? '',
      lessonType: type,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'memberName': memberName,
    'lessonType': lessonType.name,
    'amount': amount,
  };
}
