import 'package:flutter/material.dart';
import '../repositories/notification_repository.dart';
import '../models/notification_model.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationViewModel({required NotificationRepository repository})
      : _repository = repository;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _repository.getNotifications(userId);
    } catch (e) {
      debugPrint("Notifications error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final success = await _repository.markAsRead(id);
      if (success) {
        final index = _notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          _notifications[index].isRead = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Mark as read error: $e");
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      final success = await _repository.deleteNotification(id);
      if (success) {
        _notifications.removeWhere((n) => n.id == id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Delete notification error: $e");
    }
  }

  Future<void> deleteAllNotifications(int userId) async {
    try {
      final success = await _repository.deleteAllNotifications(userId);
      if (success) {
        _notifications.clear();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Delete all notifications error: $e");
    }
  }

  Future<bool> sendBulkNotification({required int gymId, required String message, String? role}) async {
    try {
      return await _repository.sendBulkNotification(
        gymId: gymId,
        message: message,
        role: role,
      );
    } catch (e) {
      debugPrint("Send bulk error: $e");
      return false;
    }
  }
}
