import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/notification_model.dart';

class NotificationViewModel extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/notifications/$userId"),
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Notifications error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await http.put(
        Uri.parse("${ApiService.baseUrl}/notifications/mark-as-read/$id"),
        headers: ApiService.getHeaders(),
      );
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].isRead = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Mark as read error: $e");
    }
  }

  Future<bool> sendBulkNotification({required int gymId, required String message, String? role}) async {
    try {
      String url = "${ApiService.baseUrl}/notifications/send-bulk?gymId=$gymId&message=${Uri.encodeComponent(message)}";
      if (role != null) url += "&role=$role";

      final response = await http.post(
        Uri.parse(url),
        headers: ApiService.getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Send bulk error: $e");
      return false;
    }
  }
}
