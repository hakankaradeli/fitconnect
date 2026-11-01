import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/leave_record_model.dart';
import '../services/api_result.dart';
import 'base_repository.dart';

class UserRepository extends BaseRepository {
  UserRepository({super.client, required super.apiService});

  Future<ApiResult<List<LeaveRecordModel>>> getLeaveHistoryResult(int trainerId) async {
    return safeGet<List<LeaveRecordModel>>(
      "users/leave-history/$trainerId",
      parser: (json) {
        if (json is List) {
          return json.map((j) => LeaveRecordModel.fromJson(j as Map<String, dynamic>)).toList();
        }
        return <LeaveRecordModel>[];
      },
    );
  }

  Future<List<LeaveRecordModel>> getLeaveHistory(int trainerId) async {
    final result = await getLeaveHistoryResult(trainerId);
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<bool>> cancelLeaveResult(int leaveId) async {
    return safeDelete<bool>("users/cancel-leave/$leaveId", parser: (_) => true);
  }

  Future<bool> cancelLeave(int leaveId) async {
    final result = await cancelLeaveResult(leaveId);
    return result.isSuccess;
  }

  Future<ApiResult<List<UserModel>>> getUsersResult(int gymId) async {
    return safeGet<List<UserModel>>(
      "users/list/$gymId",
      parser: (json) {
        if (json is List) {
          return json.map((item) {
            try {
              return UserModel.fromJson(item as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          }).where((u) => u != null).cast<UserModel>().toList();
        }
        return <UserModel>[];
      },
    );
  }

  Future<List<UserModel>> getUsers(int gymId) async {
    final result = await getUsersResult(gymId);
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<List<UserModel>>> getDeletedUsersResult(int gymId) async {
    return safeGet<List<UserModel>>(
      "users/deleted/$gymId",
      parser: (json) {
        if (json is List) {
          return json.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <UserModel>[];
      },
    );
  }

  Future<List<UserModel>> getDeletedUsers(int gymId) async {
    final result = await getDeletedUsersResult(gymId);
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<double>> getUnpaidAccrualResult(int trainerId) async {
    return safeGet<double>(
      "accruals/unpaid/$trainerId",
      parser: (json) {
        if (json is Map) {
          final val = json['amount'] ?? json['totalAmount'];
          if (val is num) return val.toDouble();
        }
        return 0.0;
      },
    );
  }

  Future<double> getUnpaidAccrual(int trainerId) async {
    final result = await getUnpaidAccrualResult(trainerId);
    return result.dataOrNull ?? 0.0;
  }

  Future<ApiResult<Map<String, dynamic>?>> getTrainerStatsResult(int trainerId) async {
    return safeGet<Map<String, dynamic>?>(
      "accruals/stats/$trainerId",
      parser: (json) => json is Map ? Map<String, dynamic>.from(json) : null,
    );
  }

  Future<Map<String, dynamic>?> getTrainerStats(int trainerId) async {
    final result = await getTrainerStatsResult(trainerId);
    return result.dataOrNull;
  }

  Future<ApiResult<bool>> assignGymByQrResult(int userId, int gymId, {String? role}) async {
    final queryParams = {
      "userId": userId.toString(),
      "gymId": gymId.toString(),
      if (role != null && role.isNotEmpty) "role": role,
    };
    return safePost<bool>("users/assign-gym-by-qr", queryParameters: queryParams, parser: (_) => true);
  }

  Future<http.Response> assignGymByQr(int userId, int gymId, {String? role}) async {
    final queryParams = {
      "userId": userId.toString(),
      "gymId": gymId.toString(),
      if (role != null && role.isNotEmpty) "role": role,
    };
    return await post("users/assign-gym-by-qr", queryParameters: queryParams);
  }

  Future<void> markAccrualsPaid(int trainerId) async {
    await post("accruals/pay-all/$trainerId");
  }

  Future<http.Response> createUser(Map<String, dynamic> body) async {
    return await post("users/create", body: body);
  }

  Future<http.Response> updateAssignment(int memberId, {int? trainerId, String? lessonType}) async {
    final queryParams = {
      if (trainerId != null) "trainerId": trainerId.toString(),
      if (lessonType != null && lessonType.isNotEmpty) "lessonType": lessonType,
    };
    return await put("users/update-assignment/$memberId", queryParameters: queryParams);
  }

  Future<http.Response> updateCanTeach(int trainerId, List<String> canTeach) async {
    return await put("users/update-can-teach/$trainerId", body: canTeach);
  }

  Future<http.Response> deleteUser(int userId, {int? replacementTrainerId}) async {
    final queryParams = {
      if (replacementTrainerId != null) "replacementTrainerId": replacementTrainerId.toString(),
    };
    return await delete("users/$userId", queryParameters: queryParams);
  }

  Future<http.Response> toggleStatus(int userId, {int? replacementTrainerId}) async {
    final queryParams = {
      if (replacementTrainerId != null) "replacementTrainerId": replacementTrainerId.toString(),
    };
    return await put("users/toggle-status/$userId", queryParameters: queryParams);
  }

  Future<http.Response> setLeave({
    required int trainerId,
    required DateTime start,
    required DateTime end,
    int? replacementTrainerId,
  }) async {
    String format(DateTime dt) => dt.toIso8601String().split('.').first;
    final queryParams = {
      "start": format(start),
      "end": format(end),
      if (replacementTrainerId != null) "replacementTrainerId": replacementTrainerId.toString(),
    };
    return await put("users/set-leave/$trainerId", queryParameters: queryParams);
  }

  Future<ApiResult<UserModel?>> getProfileResult(int userId) async {
    return safeGet<UserModel?>(
      "users/profile/$userId",
      parser: (json) => json is Map ? UserModel.fromJson(Map<String, dynamic>.from(json)) : null,
    );
  }

  Future<UserModel?> getProfile(int userId) async {
    final result = await getProfileResult(userId);
    return result.dataOrNull;
  }

  Future<http.Response> updateProfile(int userId, Map<String, dynamic> body) async {
    return await put("users/profile/$userId", body: body);
  }

  Future<ApiResult<bool>> unfreezeMemberResult(int memberId) async {
    return safePut<bool>("users/unfreeze-member/$memberId", parser: (_) => true);
  }

  Future<bool> unfreezeMember(int memberId) async {
    final result = await unfreezeMemberResult(memberId);
    return result.isSuccess;
  }

  Future<http.Response> freezeMember({
    required int memberId,
    required DateTime start,
    required DateTime end,
    String? reason,
  }) async {
    String format(DateTime dt) => dt.toIso8601String().split('T').first;
    final queryParams = {
      "start": format(start),
      "end": format(end),
      if (reason != null && reason.isNotEmpty) "reason": reason,
    };
    return await put("users/freeze-member/$memberId", queryParameters: queryParams);
  }

  Future<http.Response> selfDelete(int userId) async {
    return await delete("users/self-delete/$userId");
  }
}
