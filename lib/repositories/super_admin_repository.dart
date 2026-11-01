import '../services/api_result.dart';
import 'base_repository.dart';

class SuperAdminRepository extends BaseRepository {
  SuperAdminRepository({super.client, required super.apiService});

  Future<ApiResult<List<dynamic>>> getGymsResult() async {
    return safeGet<List<dynamic>>(
      "super-admin/gyms/list",
      parser: (json) => json is List ? json : <dynamic>[],
    );
  }

  Future<List<dynamic>> getGyms() async {
    final result = await getGymsResult();
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<Map<String, dynamic>?>> getStatsResult() async {
    return safeGet<Map<String, dynamic>?>(
      "super-admin/stats",
      parser: (json) => json is Map ? Map<String, dynamic>.from(json) : null,
    );
  }

  Future<Map<String, dynamic>?> getStats() async {
    final result = await getStatsResult();
    return result.dataOrNull;
  }

  Future<ApiResult<List<dynamic>>> getUnassignedUsersResult() async {
    return safeGet<List<dynamic>>(
      "super-admin/unassigned-users",
      parser: (json) => json is List ? json : <dynamic>[],
    );
  }

  Future<List<dynamic>> getUnassignedUsers() async {
    final result = await getUnassignedUsersResult();
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<Map<String, dynamic>>> getAuditReportsResult() async {
    return safeGet<Map<String, dynamic>>(
      "super-admin/audit-reports",
      parser: (json) => json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> getAuditReports() async {
    final result = await getAuditReportsResult();
    return result.dataOrNull ?? {};
  }

  Future<ApiResult<bool>> deleteUnassignedUserResult(int userId) async {
    return safeDelete<bool>("super-admin/users/$userId", parser: (_) => true);
  }

  Future<bool> deleteUnassignedUser(int userId) async {
    final result = await deleteUnassignedUserResult(userId);
    return result.isSuccess;
  }

  Future<ApiResult<bool>> createGymResult(Map<String, dynamic> body) async {
    return safePost<bool>("super-admin/gyms/create", body: body, parser: (_) => true);
  }

  Future<bool> createGym(Map<String, dynamic> body) async {
    final result = await createGymResult(body);
    return result.isSuccess;
  }

  Future<ApiResult<bool>> toggleGymStatusResult(int gymId) async {
    return safePut<bool>("super-admin/gyms/toggle-status/$gymId", parser: (_) => true);
  }

  Future<bool> toggleGymStatus(int gymId) async {
    final result = await toggleGymStatusResult(gymId);
    return result.isSuccess;
  }

  Future<ApiResult<bool>> updateGymResult(int gymId, Map<String, dynamic> body) async {
    return safePut<bool>("super-admin/gyms/$gymId", body: body, parser: (_) => true);
  }

  Future<bool> updateGym(int gymId, Map<String, dynamic> body) async {
    final result = await updateGymResult(gymId, body);
    return result.isSuccess;
  }

  Future<ApiResult<bool>> deleteGymResult(int gymId) async {
    return safeDelete<bool>("super-admin/gyms/$gymId", parser: (_) => true);
  }

  Future<bool> deleteGym(int gymId) async {
    final result = await deleteGymResult(gymId);
    return result.isSuccess;
  }

  Future<ApiResult<Map<String, dynamic>>> changePasswordResult(String currentPassword, String newPassword) async {
    return safePost<Map<String, dynamic>>(
      "super-admin/change-password",
      body: {
        "currentPassword": currentPassword,
        "newPassword": newPassword,
      },
      parser: (json) => json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{},
    );
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final result = await changePasswordResult(currentPassword, newPassword);
    return result.isSuccess;
  }
}
