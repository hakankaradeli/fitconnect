import 'package:flutter/foundation.dart';

class ApiService {
  // ngrok adresi tanımlandı
  static const String _customUrl = "https://married-shudder-around.ngrok-free.dev/api";

  static String get baseUrl {
    // Özel bir adres girilmişse onu kullan
    if (_customUrl.trim().isNotEmpty) {
      final trimmed = _customUrl.trim();
      if (trimmed.endsWith('/api') || trimmed.endsWith('/api/')) {
        return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
      }
      return trimmed.endsWith('/') ? "${trimmed}api" : "$trimmed/api";
    }
    
    // Web (Chrome) üzerinde çalışıyorsa
    if (kIsWeb) {
      return "http://localhost:8080/api";
    }
    
    // Android Emülatör üzerinde çalışıyorsa
    return "http://10.0.2.2:8080/api";
  }

  // JWT Token'ı saklamak için
  static String? token;

  // Header hazırlayıcı
  static Map<String, String> getHeaders() {
    Map<String, String> headers = {"Content-Type": "application/json"};
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }
}
