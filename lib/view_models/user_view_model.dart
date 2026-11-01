import 'package:flutter/material.dart';
import 'dart:convert';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';
import '../models/leave_record_model.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  UserViewModel({required UserRepository userRepository})
      : _userRepository = userRepository;

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
      _leaveHistory = await _userRepository.getLeaveHistory(trainerId);
    } catch (e) {
      debugPrint("Leave history error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelLeave(int leaveId) async {
    try {
      return await _userRepository.cancelLeave(leaveId);
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchUsers(int gymId) async {
    _isLoading = true;
    _errorMessage = null;
    _users = [];
    notifyListeners();

    try {
      _users = await _userRepository.getUsers(gymId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = "Hata: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDeletedUsers(int gymId) async {
    try {
      _deletedUsers = await _userRepository.getDeletedUsers(gymId);
      notifyListeners();
    } catch (e) {
      debugPrint("Deleted users error: $e");
    }
  }

  Future<double> getUnpaidAccrual(int trainerId) async {
    try {
      return await _userRepository.getUnpaidAccrual(trainerId);
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, dynamic>?> getTrainerStats(int trainerId) async {
    try {
      return await _userRepository.getTrainerStats(trainerId);
    } catch (e) {
      debugPrint("Get trainer stats error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> assignGymByQr({
    required int userId,
    required int gymId,
    String? role,
  }) async {
    try {
      final response = await _userRepository.assignGymByQr(userId, gymId, role: role);
      final bodyStr = response.body.trim();

      if (response.statusCode == 200 && bodyStr.isNotEmpty) {
        return jsonDecode(bodyStr) as Map<String, dynamic>;
      } else {
        if (bodyStr.isNotEmpty) {
          try {
            final error = jsonDecode(bodyStr);
            _errorMessage = error['error'] ?? error['message'] ?? "Salon kaydı ataması başarısız oldu (${response.statusCode}).";
          } catch (_) {
            _errorMessage = "Sunucu yanıt hatası (HTTP ${response.statusCode}): $bodyStr";
          }
        } else {
          _errorMessage = "Sunucudan yanıt alınamadı (HTTP ${response.statusCode}). Lütfen sunucu bağlantısını kontrol edin.";
        }
        notifyListeners();
        return null;
      }
    } catch (e) {
      debugPrint("Assign gym error: $e");
      _errorMessage = "Sunucu bağlantı hatası: $e";
      notifyListeners();
      return null;
    }
  }

  Future<void> markAccrualsPaid(int trainerId) async {
    try {
      await _userRepository.markAccrualsPaid(trainerId);
    } catch (e) {
      debugPrint("Pay accruals error: $e");
    }
  }

  Future<bool> createUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    required int gymId,
    int? trainerId,
    String? lessonType,
    List<String>? canTeach,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _userRepository.createUser({
        "fullName": fullName,
        "email": email,
        "phone": phone,
        "password": password,
        "role": role,
        "gymId": gymId,
        "trainerId": trainerId,
        "lessonType": lessonType,
        "canTeach": canTeach,
      });

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
      final response = await _userRepository.updateAssignment(
        memberId,
        trainerId: trainerId,
        lessonType: lessonType,
      );

      if (response.statusCode == 200) {
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
      final response = await _userRepository.updateCanTeach(trainerId, canTeach);
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
      final response = await _userRepository.deleteUser(
        userId,
        replacementTrainerId: replacementTrainerId,
      );
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
      final response = await _userRepository.toggleStatus(
        userId,
        replacementTrainerId: replacementTrainerId,
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

  Future<bool> setTrainerLeave({
    required int trainerId,
    required DateTime start,
    required DateTime end,
    int? replacementTrainerId,
  }) async {
    try {
      final response = await _userRepository.setLeave(
        trainerId: trainerId,
        start: start,
        end: end,
        replacementTrainerId: replacementTrainerId,
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

  Future<UserModel?> fetchProfile(int userId) async {
    try {
      return await _userRepository.getProfile(userId);
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

      final response = await _userRepository.updateProfile(userId, body);

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
      final success = await _userRepository.unfreezeMember(memberId);
      if (success) {
        final updatedUser = await _userRepository.getProfile(memberId);
        if (updatedUser != null) {
          int index = _users.indexWhere((u) => u.id == updatedUser.id);
          if (index != -1) {
            _users[index] = updatedUser;
            notifyListeners();
          }
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
      final response = await _userRepository.freezeMember(
        memberId: memberId,
        start: start,
        end: end,
        reason: reason,
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

  Future<bool> deleteSelfAccount(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _userRepository.selfDelete(userId);

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['error'] ?? "Hesap silinemedi";
      }
    } catch (e) {
      _errorMessage = "Sunucu hatası: $e";
      debugPrint("Self delete account error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }
}
