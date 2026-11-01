class NutritionModel {
  final int dailyCalories;
  final int protein;
  final int carbs;
  final int fat;
  final List<String> meals;
  final DateTime updatedAt;
  final DateTime expiryDate;

  NutritionModel({
    required this.dailyCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.meals,
    required this.updatedAt,
    required this.expiryDate,
  });

  factory NutritionModel.fromJson(Map<String, dynamic> json) {
    return NutritionModel(
      dailyCalories: json['dailyCalories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fat: json['fat'] ?? 0,
      meals: List<String>.from(json['meals'] ?? []),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      expiryDate: DateTime.parse(json['expiryDate'] ?? DateTime.now().add(const Duration(days: 60)).toIso8601String()),
    );
  }
}
