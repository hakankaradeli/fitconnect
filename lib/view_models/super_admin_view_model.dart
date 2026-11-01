import 'package:flutter/material.dart';
import '../repositories/super_admin_repository.dart';

class SuperAdminViewModel extends ChangeNotifier {
  final SuperAdminRepository _repository;

  SuperAdminViewModel({required SuperAdminRepository repository})
      : _repository = repository;

  List<dynamic> _gyms = [];
  List<dynamic> _unassignedUsers = [];
  List<dynamic> _auditConsentLogs = [];
  List<dynamic> _auditDeletedArchives = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get gyms => _gyms;
  List<dynamic> get unassignedUsers => _unassignedUsers;
  List<dynamic> get auditConsentLogs => _auditConsentLogs;
  List<dynamic> get auditDeletedArchives => _auditDeletedArchives;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchGyms() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _gyms = await _repository.getGyms();
    } catch (e) {
      debugPrint("Fetch gyms error: $e");
      if (e is FormatException) {
        _errorMessage = "Sunucudan boş yanıt alındı.";
      } else {
        _errorMessage = "Sunucuya bağlanılamadı.";
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStats() async {
    try {
      final data = await _repository.getStats();
      if (data != null) {
        _stats = data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Fetch SaaS stats error: $e");
    }
  }

  Future<void> fetchUnassignedUsers() async {
    try {
      _unassignedUsers = await _repository.getUnassignedUsers();
      notifyListeners();
    } catch (e) {
      debugPrint("Fetch unassigned users error: $e");
    }
  }

  Future<void> fetchAuditReports() async {
    try {
      final data = await _repository.getAuditReports();
      _auditConsentLogs = (data['consentLogs'] as List<dynamic>?) ?? [];
      _auditDeletedArchives = (data['deletedArchives'] as List<dynamic>?) ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint("Fetch audit reports error: $e");
    }
  }

  Future<bool> deleteUnassignedUser(int userId) async {
    try {
      final success = await _repository.deleteUnassignedUser(userId);
      if (success) {
        await fetchUnassignedUsers();
        await fetchStats();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Delete unassigned user error: $e");
      return false;
    }
  }

  Future<bool> createGym({
    required String gymName,
    required String adminEmail,
    required String adminFullName,
    required String adminPassword,
    String? primaryColor,
    String? logoUrl,
    String? address,
    String? adminPhone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        "gymName": gymName,
        "primaryColor": primaryColor ?? "#3F51B5",
        "logoUrl": logoUrl,
        "address": address,
        "adminEmail": adminEmail,
        "adminFullName": adminFullName,
        "adminPassword": adminPassword,
        "adminPhone": adminPhone,
      };

      final success = await _repository.createGym(body);
      if (success) {
        await fetchGyms();
        await fetchStats();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Salon oluşturulamadı";
      }
    } catch (e) {
      _errorMessage = "Sunucu hatası: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> toggleGymStatus(int gymId) async {
    try {
      final success = await _repository.toggleGymStatus(gymId);
      if (success) {
        await fetchGyms();
        await fetchStats();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateGym({
    required int gymId,
    required String gymName,
    String? primaryColor,
    String? logoUrl,
    String? address,
    String? adminFullName,
    String? adminEmail,
    String? adminPassword,
    String? adminPhone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        "gymName": gymName,
        "primaryColor": primaryColor,
        "logoUrl": logoUrl,
        "address": address,
        "adminFullName": adminFullName,
        "adminEmail": adminEmail,
        "adminPassword": adminPassword,
        "adminPhone": adminPhone,
      };

      final success = await _repository.updateGym(gymId, body);
      if (success) {
        await fetchGyms();
        await fetchStats();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Güncelleme başarısız";
      }
    } catch (e) {
      _errorMessage = "Sunucu hatası: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> deleteGym(int gymId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _repository.deleteGym(gymId);
      if (success) {
        await fetchGyms();
        await fetchStats();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.changePasswordResult(currentPassword, newPassword);
      if (result.isSuccess) {
        return null;
      } else {
        return result.errorOrNull ?? "Şifre değiştirilemedi";
      }
    } catch (e) {
      return "Sunucu hatası: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
