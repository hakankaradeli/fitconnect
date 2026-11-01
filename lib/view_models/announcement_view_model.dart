import 'package:flutter/material.dart';
import '../repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

class AnnouncementViewModel extends ChangeNotifier {
  final AnnouncementRepository _repository;

  AnnouncementViewModel({required AnnouncementRepository repository})
      : _repository = repository;

  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;

  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;

  Future<void> fetchAnnouncements(int gymId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _announcements = await _repository.getAnnouncements(gymId);
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
      final success = await _repository.createAnnouncement(
        gymId: gymId,
        title: title,
        content: content,
        imageUrl: imageUrl,
        targetRole: targetRole,
      );

      if (success) {
        await fetchAnnouncements(gymId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Create announcement error: $e");
      return false;
    }
  }

  void hideAnnouncementLocally(int id) {
    _announcements.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<bool> deleteAnnouncement(int id, int gymId) async {
    try {
      final success = await _repository.deleteAnnouncement(id);
      if (success) {
        await fetchAnnouncements(gymId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
