import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/announcement_model.dart';

class AnnouncementViewModel extends ChangeNotifier {
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;

  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;

  Future<void> fetchAnnouncements(int gymId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/announcements/gym/$gymId"),
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _announcements = data.map((json) => AnnouncementModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Fetch announcements error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAnnouncement({
    required int gymId,
    required String title,
    required String content,
    String? imageUrl,
    String targetRole = "ALL",
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/announcements/create"),
        headers: ApiService.getHeaders(),
        body: jsonEncode({
          "gymId": gymId,
          "title": title,
          "content": content,
          "imageUrl": imageUrl,
          "targetRole": targetRole,
        }),
      );

      if (response.statusCode == 200) {
        await fetchAnnouncements(gymId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Create announcement error: $e");
      return false;
    }
  }

  Future<bool> deleteAnnouncement(int id, int gymId) async {
    try {
      final response = await http.delete(
        Uri.parse("${ApiService.baseUrl}/announcements/$id"),
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        await fetchAnnouncements(gymId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
