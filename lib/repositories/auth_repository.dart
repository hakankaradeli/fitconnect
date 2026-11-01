import 'package:http/http.dart' as http;
import '../services/api_result.dart';
import 'base_repository.dart';

class AuthRepository extends BaseRepository {
  AuthRepository({super.client, required super.apiService});

  void setTokens({String? token, String? refreshToken}) {
    apiService.token = token;
    if (refreshToken != null) {
      apiService.refreshToken = refreshToken;
    }
  }

  void setToken(String? token) {
    apiService.token = token;
  }

  bool get hasToken =>
      (apiService.token != null && apiService.token!.isNotEmpty) ||
      (apiService.refreshToken != null && apiService.refreshToken!.isNotEmpty);
  String? get currentToken => apiService.token;
  String? get currentRefreshToken => apiService.refreshToken;

  Future<ApiResult<Map<String, dynamic>>> refreshTokenResult(String refreshToken) async {
    return safePost<Map<String, dynamic>>(
      "auth/refresh",
      headers: {"Content-Type": "application/json"},
      body: {"refreshToken": refreshToken},
      parser: (json) => json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{},
      retryOnUnauthorized: false,
    );
  }

  Future<ApiResult<List<dynamic>>> getPublicGymsResult() async {
    return safeGet<List<dynamic>>(
      "auth/public-gyms",
      headers: {"Content-Type": "application/json"},
      parser: (json) => json is List ? json : <dynamic>[],
    );
  }

  Future<List<dynamic>> getPublicGyms() async {
    final result = await getPublicGymsResult();
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<Map<String, dynamic>>> registerResult({
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
    return safePost<Map<String, dynamic>>(
      "auth/register",
      headers: {"Content-Type": "application/json"},
      body: {
        "fullName": fullName,
        "email": email,
        "phone": phone,
        "password": password,
        "role": role,
        "gymId": (gymId != null && gymId > 0) ? gymId : null,
        "termsAccepted": termsAccepted,
        "healthDataConsentAccepted": healthDataConsentAccepted,
        "marketingConsentAccepted": marketingConsentAccepted,
      },
      parser: (json) => json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{},
    );
  }

  Future<http.Response> register({
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
    return await post(
      "auth/register",
      headers: {"Content-Type": "application/json"},
      body: {
        "fullName": fullName,
        "email": email,
        "phone": phone,
        "password": password,
        "role": role,
        "gymId": (gymId != null && gymId > 0) ? gymId : null,
        "termsAccepted": termsAccepted,
        "healthDataConsentAccepted": healthDataConsentAccepted,
        "marketingConsentAccepted": marketingConsentAccepted,
      },
    );
  }

  Future<ApiResult<Map<String, dynamic>>> loginResult(String email, String password) async {
    return safePost<Map<String, dynamic>>(
      "auth/login",
      headers: {"Content-Type": "application/json"},
      body: {"email": email, "password": password},
      parser: (json) => json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{},
    );
  }

  Future<http.Response> login(String email, String password) async {
    return await post(
      "auth/login",
      headers: {"Content-Type": "application/json"},
      body: {"email": email, "password": password},
    );
  }
}
