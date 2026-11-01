import '../models/nutrition_model.dart';
import '../services/api_result.dart';
import 'base_repository.dart';

class NutritionRepository extends BaseRepository {
  NutritionRepository({super.client, required super.apiService});

  Future<ApiResult<NutritionModel?>> getMyPlanResult(int memberId) async {
    return safeGet<NutritionModel?>(
      "nutrition/my-plan/$memberId",
      parser: (json) => json is Map ? NutritionModel.fromJson(Map<String, dynamic>.from(json)) : null,
    );
  }

  Future<NutritionModel?> getMyPlan(int memberId) async {
    final result = await getMyPlanResult(memberId);
    return result.dataOrNull;
  }

  Future<ApiResult<bool>> assignPlanResult({
    required int memberId,
    required int trainerId,
    required int dailyCalories,
    required int protein,
    required int carbs,
    required int fat,
    required List<String> meals,
  }) async {
    return safePost<bool>(
      "nutrition/assign",
      queryParameters: {
        "memberId": memberId.toString(),
        "trainerId": trainerId.toString(),
      },
      body: {
        "dailyCalories": dailyCalories,
        "protein": protein,
        "carbs": carbs,
        "fat": fat,
        "meals": meals,
      },
      parser: (_) => true,
    );
  }

  Future<bool> assignPlan({
    required int memberId,
    required int trainerId,
    required int dailyCalories,
    required int protein,
    required int carbs,
    required int fat,
    required List<String> meals,
  }) async {
    final result = await assignPlanResult(
      memberId: memberId,
      trainerId: trainerId,
      dailyCalories: dailyCalories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      meals: meals,
    );
    return result.isSuccess;
  }

  Future<ApiResult<NutritionModel?>> getMemberPlanResult(int memberId) async {
    return safeGet<NutritionModel?>(
      "nutrition/member-plan/$memberId",
      parser: (json) => json is Map ? NutritionModel.fromJson(Map<String, dynamic>.from(json)) : null,
    );
  }

  Future<NutritionModel?> getMemberPlan(int memberId) async {
    final result = await getMemberPlanResult(memberId);
    return result.dataOrNull;
  }

  Future<ApiResult<List<dynamic>>> getExpiredReportsResult(int gymId) async {
    return safeGet<List<dynamic>>(
      "nutrition/expired-reports/$gymId",
      parser: (json) => json is List ? json : <dynamic>[],
    );
  }

  Future<List<dynamic>> getExpiredReports(int gymId) async {
    final result = await getExpiredReportsResult(gymId);
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<List<dynamic>>> getMembersWithoutPlanResult(int gymId) async {
    return safeGet<List<dynamic>>(
      "nutrition/without-plan/$gymId",
      parser: (json) => json is List ? json : <dynamic>[],
    );
  }

  Future<List<dynamic>> getMembersWithoutPlan(int gymId) async {
    final result = await getMembersWithoutPlanResult(gymId);
    return result.dataOrNull ?? [];
  }
}
