import '../services/api_result.dart';
import 'base_repository.dart';

class GymRepository extends BaseRepository {
  GymRepository({super.client, required super.apiService});

  Future<ApiResult<Map<String, dynamic>?>> getBrandingResult(int gymId) async {
    return safeGet<Map<String, dynamic>?>(
      "gyms/branding/$gymId",
      parser: (json) => json is Map ? Map<String, dynamic>.from(json) : null,
    );
  }

  Future<Map<String, dynamic>?> getBranding(int gymId) async {
    final result = await getBrandingResult(gymId);
    return result.dataOrNull;
  }

  Future<ApiResult<bool>> updateBrandingResult(int gymId, Map<String, dynamic> body) async {
    return safePut<bool>("gyms/branding/$gymId", body: body, parser: (_) => true);
  }

  Future<bool> updateBranding(int gymId, Map<String, dynamic> body) async {
    final result = await updateBrandingResult(gymId, body);
    return result.isSuccess;
  }

  Future<ApiResult<bool>> updateWorkingHoursResult(
    int gymId,
    String days,
    String openTime,
    String closeTime,
    int maxCancellations,
  ) async {
    return safePut<bool>(
      "gyms/working-hours/$gymId",
      body: {
        "workingDays": days,
        "openTime": openTime,
        "closeTime": closeTime,
        "maxCancellations": maxCancellations,
      },
      parser: (_) => true,
    );
  }

  Future<bool> updateWorkingHours(
    int gymId,
    String days,
    String openTime,
    String closeTime,
    int maxCancellations,
  ) async {
    final result = await updateWorkingHoursResult(gymId, days, openTime, closeTime, maxCancellations);
    return result.isSuccess;
  }
}
