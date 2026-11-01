import '../models/notification_model.dart';
import '../services/api_result.dart';
import 'base_repository.dart';

class NotificationRepository extends BaseRepository {
  NotificationRepository({super.client, required super.apiService});

  Future<ApiResult<List<NotificationModel>>> getNotificationsResult(int userId) async {
    return safeGet<List<NotificationModel>>(
      "notifications/$userId",
      parser: (json) {
        if (json is List) {
          return json.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <NotificationModel>[];
      },
    );
  }

  Future<List<NotificationModel>> getNotifications(int userId) async {
    final result = await getNotificationsResult(userId);
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<bool>> markAsReadResult(int id) async {
    return safePut<bool>("notifications/mark-as-read/$id", parser: (_) => true);
  }

  Future<bool> markAsRead(int id) async {
    final result = await markAsReadResult(id);
    return result.isSuccess;
  }

  Future<ApiResult<bool>> deleteNotificationResult(int id) async {
    return safeDelete<bool>("notifications/$id", parser: (_) => true);
  }

  Future<bool> deleteNotification(int id) async {
    final result = await deleteNotificationResult(id);
    return result.isSuccess;
  }

  Future<ApiResult<bool>> deleteAllNotificationsResult(int userId) async {
    return safeDelete<bool>("notifications/all/$userId", parser: (_) => true);
  }

  Future<bool> deleteAllNotifications(int userId) async {
    final result = await deleteAllNotificationsResult(userId);
    return result.isSuccess;
  }

  Future<ApiResult<bool>> sendBulkNotificationResult({
    required int gymId,
    required String message,
    String? role,
  }) async {
    final queryParams = {
      "gymId": gymId.toString(),
      "message": message,
      if (role != null) "role": role,
    };
    return safePost<bool>("notifications/send-bulk", queryParameters: queryParams, parser: (_) => true);
  }

  Future<bool> sendBulkNotification({
    required int gymId,
    required String message,
    String? role,
  }) async {
    final result = await sendBulkNotificationResult(gymId: gymId, message: message, role: role);
    return result.isSuccess;
  }
}
