enum LessonType { pt1to1, ptDuo, reformerGroup }

class AccrualEntry {
  final String id;
  final DateTime date;
  final String memberName;
  final LessonType lessonType;
  final double amount; // Eğitmenin o dersten kazandığı para

  AccrualEntry({
    required this.id,
    required this.date,
    required this.memberName,
    required this.lessonType,
    required this.amount,
  });
}
