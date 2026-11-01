import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  LoginViewModel({required AuthRepository authRepository})
      : _authRepository = authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;
  List<dynamic> _publicGyms = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;
  List<dynamic> get publicGyms => _publicGyms;
  bool get isAuthenticated => _authRepository.hasToken;
  String? get userRole => _userData?['role']?.toString();

  Future<void> saveToken(String token, [String? refreshToken]) async {
    try {
      _authRepository.setTokens(token: token, refreshToken: refreshToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await prefs.setString('refresh_token', refreshToken);
      }
      if (_userData != null) {
        await prefs.setString('user_data', jsonEncode(_userData));
        if (_userData!['role'] != null) {
          await prefs.setString('user_role', _userData!['role'].toString());
        }
      }
    } catch (e) {
      debugPrint("Save token error: $e");
    }
  }

  Future<bool> loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final refreshToken = prefs.getString('refresh_token');
      if ((token != null && token.isNotEmpty) || (refreshToken != null && refreshToken.isNotEmpty)) {
        _authRepository.setTokens(token: token, refreshToken: refreshToken);
        final userDataJson = prefs.getString('user_data');
        if (userDataJson != null && userDataJson.isNotEmpty) {
          _userData = jsonDecode(userDataJson) as Map<String, dynamic>;
        }
        if (_userData == null || _userData!['role'] == null) {
          final savedRole = prefs.getString('user_role');
          if (savedRole != null && savedRole.isNotEmpty) {
            _userData = (_userData ?? <String, dynamic>{})..['role'] = savedRole;
          }
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Load token error: $e");
    }
    return false;
  }

  /// Access token süresi dolmuşsa refresh token ile otomatik yenilemeye çalışır.
  /// Başarılı olursa yeni token'ları kaydeder ve true döner.
  /// Refresh token da süresi dolmuşsa tüm token'ları temizler ve false döner.
  Future<bool> tryRefreshToken() async {
    try {
      final refreshToken = _authRepository.currentRefreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint("Refresh token bulunamadı, yenileme yapılamıyor.");
        return false;
      }

      final result = await _authRepository.refreshTokenResult(refreshToken);
      bool success = false;
      await result.fold(
        onSuccess: (data) async {
          final newToken = data['token']?.toString();
          final newRefreshToken = data['refreshToken']?.toString();
          if (newToken != null && newToken.isNotEmpty) {
            await saveToken(newToken, newRefreshToken);
            debugPrint("Token başarıyla yenilendi.");
            success = true;
          } else {
            debugPrint("Token yenileme yanıtında token bulunamadı.");
          }
        },
        onFailure: (message, statusCode) {
          debugPrint("Token yenileme başarısız: $message (HTTP $statusCode)");
          clearToken();
        },
      );
      return success;
    } catch (e) {
      debugPrint("Token yenileme hatası: $e");
      return false;
    }
  }

  Future<void> clearToken() async {
    try {
      _authRepository.setTokens(token: null, refreshToken: null);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_data');
      await prefs.remove('user_role');
    } catch (e) {
      debugPrint("Clear token error: $e");
    }
  }

  Future<void> logout() async {
    await clearToken();
    _userData = null;
    notifyListeners();
  }

  Future<List<dynamic>> fetchPublicGyms() async {
    try {
      _publicGyms = await _authRepository.getPublicGyms();
      notifyListeners();
      return _publicGyms;
    } catch (e) {
      debugPrint("Fetch public gyms error: $e");
    }
    return [];
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    int? gymId,
    bool termsAccepted = true,
    bool healthDataConsentAccepted = true,
    bool marketingConsentAccepted = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _userData = null;
    notifyListeners();

    final result = await _authRepository.registerResult(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      role: role,
      gymId: gymId,
      termsAccepted: termsAccepted,
      healthDataConsentAccepted: healthDataConsentAccepted,
      marketingConsentAccepted: marketingConsentAccepted,
    );

    return result.fold(
      onSuccess: (data) async {
        _userData = data;
        await saveToken(data['token'], data['refreshToken']);
        _isLoading = false;
        notifyListeners();
        return true;
      },
      onFailure: (message, _) {
        _errorMessage = message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _userData = null;
    notifyListeners();

    final result = await _authRepository.loginResult(email, password);

    return result.fold(
      onSuccess: (data) async {
        _userData = data;
        await saveToken(data['token'], data['refreshToken']);
        _isLoading = false;
        notifyListeners();
        return true;
      },
      onFailure: (message, _) {
        _errorMessage = message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
    );
  }

  void updateUserData(Map<String, dynamic> newData) async {
    if (_userData != null) {
      _userData!.addAll(newData);
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(_userData));
        if (_userData!['role'] != null) {
          await prefs.setString('user_role', _userData!['role'].toString());
        }
      } catch (e) {
        debugPrint("Update user data error: $e");
      }
    }
  }
}
