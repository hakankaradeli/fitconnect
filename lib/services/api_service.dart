import 'package:flutter/foundation.dart';

class ApiService {
  static const String defaultCustomUrl = "https://api.ptfitconnect.com/api";

  final String? customUrl;
  String? token;
  String? refreshToken;

  ApiService({this.customUrl, this.token, this.refreshToken});

  String get baseUrl {
    final effectiveUrl = customUrl ?? defaultCustomUrl;
    if (effectiveUrl.trim().isNotEmpty) {
      var trimmed = effectiveUrl.trim().replaceAll(RegExp(r'https:///+'), 'https://').replaceAll(RegExp(r'http:///+'), 'http://');
      // Production modunda düz HTTP kullanımını engelle ve güvenli HTTPS'e yükselt
      if (kReleaseMode && trimmed.startsWith('http://')) {
        trimmed = trimmed.replaceFirst('http://', 'https://');
      }
      if (trimmed.endsWith('/api') || trimmed.endsWith('/api/')) {
        return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
      }
      return trimmed.endsWith('/') ? "${trimmed}api" : "$trimmed/api";
    }

    // Varsayılan fallback her zaman güvenli HTTPS olmalıdır
    return defaultCustomUrl;
  }

  Map<String, String> getHeaders() {
    Map<String, String> headers = {"Content-Type": "application/json"};
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }
}
