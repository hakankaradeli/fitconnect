import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/leave_record_model.dart';

class UserViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<UserModel> _users = [];
  List<UserModel> _deletedUsers = [];
  List<LeaveRecordModel> _leaveHistory = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get users => _users;
  List<UserModel> get deletedUsers => _deletedUsers;
  List<LeaveRecordModel> get leaveHistory => _leaveHistory;

  Future<void> fetchLeaveHistory(int trainerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/users/leave-history/$trainerId"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _leaveHistory = data.map((json) => LeaveRecordModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Leave history error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelLeave(int leaveId) async {
    try {
      final response = await http.delete(
        Uri.parse("${ApiService.baseUrl}/users/cancel-leave/$leaveId"),
        headers: ApiService.getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchUsers(int gymId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/users/list/$gymId"),
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _users = data.map((json) => UserModel.fromJson(json)).toList();
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = "Kullanıcı listesi yüklenemedi: ${response.statusCode}";
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Hata: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDeletedUsers(int gymId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/users/deleted/$gymId"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _deletedUsers = data.map((json) => UserModel.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Deleted users error: $e");
    }
  }

  Future<double> getUnpaidAccrual(int trainerId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/accruals/unpaid/$trainerId"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['amount'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> markAccrualsPaid(int trainerId) async {
    try {
      await http.post(
        Uri.parse("${ApiService.baseUrl}/accruals/pay-all/$trainerId"),
        headers: ApiService.getHeaders(),
      );
    } catch (e) {
      debugPrint("Pay accruals error: $e");
    }
  }

  Future<bool> createUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role, // "MEMBER" or "TRAINER"
    required int gymId,
    int? trainerId,
    String? lessonType,
    List<String>? canTeach,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/users/create"),
        headers: ApiService.getHeaders(),
        body: jsonEncode({
          "fullName": fullName,
          "email": email,
          "phone": phone,
          "password": password,
          "role": role,
          "gymId": gymId,
          "trainerId": trainerId,
          "lessonType": lessonType,
          "canTeach": canTeach,
        }),
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        if (response.body.isNotEmpty) {
          final errorData = jsonDecode(response.body);
          _errorMessage = errorData['error'] ?? "Üye oluşturulamadı!";
        } else {
          _errorMessage = "Sunucudan boş cevap döndü (Hata kodu: ${response.statusCode})";
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = "Sunucuya bağlanılamadı: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMemberAssignment({
    required int memberId,
    int? trainerId,
    String? lessonType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = {
        if (trainerId != null) "trainerId": trainerId.toString(),
        if (lessonType != null) "lessonType": lessonType,
      };

      final uri = Uri.parse("${ApiService.baseUrl}/users/update-assignment/$memberId")
          .replace(queryParameters: queryParams);

      final response = await http.put(
        uri,
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        // Bellekteki listeyi de güncelle
        final updatedUserJson = jsonDecode(response.body);
        final updatedUser = UserModel.fromJson(updatedUserJson);
        
        int index = _users.indexWhere((u) => u.id == updatedUser.id);
        if (index != -1) {
          _users[index] = updatedUser;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['error'] ?? "Güncelleme başarısız!";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = "Sunucuya bağlanılamadı: $e";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTrainerCanTeach({
    required int trainerId,
    required List<String> canTeach,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.put(
        Uri.parse("${ApiService.baseUrl}/users/update-can-teach/$trainerId"),
        headers: ApiService.getHeaders(),
        body: jsonEncode(canTeach),
      );
      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Update can teach error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> deleteUser(int userId, {int? replacementTrainerId}) async {
    try {
      final queryParams = {
        if (replacementTrainerId != null) "replacementTrainerId": replacementTrainerId.toString(),
      };
      final uri = Uri.parse("${ApiService.baseUrl}/users/$userId").replace(queryParameters: queryParams);
      
      final response = await http.delete(uri, headers: ApiService.getHeaders());
      if (response.statusCode == 200) {
        _users.removeWhere((u) => u.id == userId.toString());
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleUserStatus(int userId, {int? replacementTrainerId}) async {
    try {
      final queryParams = {
        if (replacementTrainerId != null) "replacementTrainerId": replacementTrainerId.toString(),
      };
      final uri = Uri.parse("${ApiService.baseUrl}/users/toggle-status/$userId").replace(queryParameters: queryParams);

      final response = await http.put(uri, headers: ApiService.getHeaders());
      if (response.statusCode == 200) {
        final updatedUserJson = jsonDecode(response.body);
        final updatedUser = UserModel.fromJson(updatedUserJson);
        int index = _users.indexWhere((u) => u.id == updatedUser.id);
        if (index != -1) {
          _users[index] = updatedUser;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setTrainerLeave({
    required int trainerId,
    required DateTime start,
    required DateTime end,
    int? replacementTrainerId,
  }) async {
    try {
      String format(DateTime dt) => dt.toIso8601String().split('.').first;
      
      final queryParams = {
        "start": format(start),
        "end": format(end),
        if (replacementTrainerId != null) "replacementTrainerId": replacementTrainerId.toString(),
      };
      
      final uri = Uri.parse("${ApiService.baseUrl}/users/set-leave/$trainerId").replace(queryParameters: queryParams);
      final response = await http.put(uri, headers: ApiService.getHeaders());
      
      if (response.statusCode == 200) {
        final updatedUserJson = jsonDecode(response.body);
        final updatedUser = UserModel.fromJson(updatedUserJson);
        int index = _users.indexWhere((u) => u.id == updatedUser.id);
        if (index != -1) {
          _users[index] = updatedUser;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<UserModel?> fetchProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/users/profile/$userId"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      }
    } catch (e) {
      debugPrint("Fetch profile error: $e");
    }
    return null;
  }

  Future<bool> updateProfile({
    required int userId,
    String? firstName,
    String? lastName,
    String? phone,
    DateTime? birthDate,
    String? gender,
    String? profileImageUrl,
    String? instagram,
    String? linkedin,
    String? twitter,
    String? currentPassword,
    String? newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final body = {
        "firstName": firstName,
        "lastName": lastName,
        "phone": phone,
        if (birthDate != null) "birthDate": "${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}",
        "gender": gender,
        "profileImageUrl": profileImageUrl,
        "instagram": instagram,
        "linkedin": linkedin,
        "twitter": twitter,
        "currentPassword": currentPassword,
        "newPassword": newPassword,
      };

      final response = await http.put(
        Uri.parse("${ApiService.baseUrl}/users/profile/$userId"),
        headers: ApiService.getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['error'] ?? "Profil güncellenemedi";
      }
    } catch (e) {
      _errorMessage = "Sunucu hatası: $e";
      debugPrint("Update profile error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> unfreezeMember(int memberId) async {
    try {
      final response = await http.put(
        Uri.parse("${ApiService.baseUrl}/users/unfreeze-member/$memberId"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        final updatedUserJson = jsonDecode(response.body);
        final updatedUser = UserModel.fromJson(updatedUserJson);
        int index = _users.indexWhere((u) => u.id == updatedUser.id);
        if (index != -1) {
          _users[index] = updatedUser;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> freezeMember({
    required int memberId,
    required DateTime start,
    required DateTime end,
    String? reason,
  }) async {
    try {
      String format(DateTime dt) => dt.toIso8601String().split('T').first;
      final queryParams = {
        "start": format(start),
        "end": format(end),
        if (reason != null && reason.isNotEmpty) "reason": reason,
      };

      final uri = Uri.parse("${ApiService.baseUrl}/users/freeze-member/$memberId").replace(queryParameters: queryParams);
      final response = await http.put(uri, headers: ApiService.getHeaders());

      if (response.statusCode == 200) {
        final updatedUserJson = jsonDecode(response.body);
        final updatedUser = UserModel.fromJson(updatedUserJson);
        int index = _users.indexWhere((u) => u.id == updatedUser.id);
        if (index != -1) {
          _users[index] = updatedUser;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
