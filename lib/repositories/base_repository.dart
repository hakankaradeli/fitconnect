import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/api_result.dart';

class BaseRepository {
  final http.Client _client;
  final ApiService _apiService;

  static Future<bool>? _refreshFuture;

  BaseRepository({http.Client? client, required ApiService apiService})
      : _client = client ?? http.Client(),
        _apiService = apiService;

  http.Client get client => _client;
  ApiService get apiService => _apiService;

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final fullUrl = "${_apiService.baseUrl}/$cleanPath";
    final uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = Map<String, String>.fromEntries(
        queryParameters.entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value.toString())),
      );
      return uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  Future<http.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final mergedHeaders = {..._apiService.getHeaders(), ...?headers};
    return await _client.get(uri, headers: mergedHeaders);
  }

  Future<http.Response> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final mergedHeaders = {..._apiService.getHeaders(), ...?headers};
    final encodedBody = body != null ? (body is String ? body : jsonEncode(body)) : null;
    return await _client.post(uri, headers: mergedHeaders, body: encodedBody);
  }

  Future<http.Response> put(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final mergedHeaders = {..._apiService.getHeaders(), ...?headers};
    final encodedBody = body != null ? (body is String ? body : jsonEncode(body)) : null;
    return await _client.put(uri, headers: mergedHeaders, body: encodedBody);
  }

  Future<http.Response> delete(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final mergedHeaders = {..._apiService.getHeaders(), ...?headers};
    final encodedBody = body != null ? (body is String ? body : jsonEncode(body)) : null;
    return await _client.delete(uri, headers: mergedHeaders, body: encodedBody);
  }

  Future<bool> _attemptTokenRefresh() async {
    if (_refreshFuture != null) {
      return await _refreshFuture!;
    }
    _refreshFuture = _performTokenRefresh();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _performTokenRefresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = _apiService.refreshToken ?? prefs.getString('refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final uri = Uri.parse("${_apiService.baseUrl}/auth/refresh");
      final response = await _client.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": refreshToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map && data['token'] != null) {
          final newAccessToken = data['token'].toString();
          final newRefreshToken = data['refreshToken']?.toString() ?? refreshToken;

          _apiService.token = newAccessToken;
          _apiService.refreshToken = newRefreshToken;

          await prefs.setString('jwt_token', newAccessToken);
          await prefs.setString('refresh_token', newRefreshToken);
          debugPrint("Access token başarıyla yenilendi.");
          return true;
        }
      } else {
        debugPrint("Token yenileme başarısız (HTTP ${response.statusCode})");
      }
    } catch (e) {
      debugPrint("Token yenileme hatası: $e");
    }
    return false;
  }

  Future<ApiResult<T>> safeRequest<T>(
    Future<http.Response> Function() request, {
    required T Function(dynamic json) parser,
    bool retryOnUnauthorized = true,
  }) async {
    try {
      final response = await request();

      if (response.statusCode == 401 && retryOnUnauthorized) {
        final refreshed = await _attemptTokenRefresh();
        if (refreshed) {
          return await safeRequest(request, parser: parser, retryOnUnauthorized: false);
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return ApiResult.success(parser(null), statusCode: response.statusCode);
        }
        final dynamic decoded = jsonDecode(response.body);
        return ApiResult.success(parser(decoded), statusCode: response.statusCode);
      } else {
        String errorMsg = "İşlem başarısız (HTTP ${response.statusCode})";
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson is Map) {
            errorMsg = errorJson['error']?.toString() ??
                errorJson['message']?.toString() ??
                errorMsg;
          }
        } catch (_) {
          if (response.body.isNotEmpty) {
            errorMsg = response.body;
          }
        }
        return ApiResult.failure(errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResult.failure("Bağlantı hatası: $e", error: e);
    }
  }

  Future<ApiResult<T>> safeGet<T>(
    String path, {
    required T Function(dynamic json) parser,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool retryOnUnauthorized = true,
  }) async {
    return safeRequest(
      () => get(path, queryParameters: queryParameters, headers: headers),
      parser: parser,
      retryOnUnauthorized: retryOnUnauthorized,
    );
  }

  Future<ApiResult<T>> safePost<T>(
    String path, {
    required T Function(dynamic json) parser,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool retryOnUnauthorized = true,
  }) async {
    return safeRequest(
      () => post(path, body: body, queryParameters: queryParameters, headers: headers),
      parser: parser,
      retryOnUnauthorized: retryOnUnauthorized,
    );
  }

  Future<ApiResult<T>> safePut<T>(
    String path, {
    required T Function(dynamic json) parser,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool retryOnUnauthorized = true,
  }) async {
    return safeRequest(
      () => put(path, body: body, queryParameters: queryParameters, headers: headers),
      parser: parser,
      retryOnUnauthorized: retryOnUnauthorized,
    );
  }

  Future<ApiResult<T>> safeDelete<T>(
    String path, {
    required T Function(dynamic json) parser,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool retryOnUnauthorized = true,
  }) async {
    return safeRequest(
      () => delete(path, body: body, queryParameters: queryParameters, headers: headers),
      parser: parser,
      retryOnUnauthorized: retryOnUnauthorized,
    );
  }
}
