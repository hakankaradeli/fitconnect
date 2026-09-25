import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class LoginViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;

  // Giriş yapma fonksiyonu
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _userData = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // 1. Token'ı servise kaydet
        ApiService.token = data['token'];

        // 2. Kullanıcı bilgilerini sakla
        _userData = data;
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['error'] ?? "Giriş başarısız!";
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

  void updateUserData(Map<String, dynamic> newData) {
    if (_userData != null) {
      _userData!.addAll(newData);
      notifyListeners();
    }
  }
}
