import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/nutrition_model.dart';

class NutritionViewModel extends ChangeNotifier {
  NutritionModel? _activePlan;
  List<dynamic> _expiredReports = [];
  bool _isLoading = false;
  String? _errorMessage;

  NutritionModel? get activePlan => _activePlan;
  List<dynamic> get expiredReports => _expiredReports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyPlan(int memberId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/nutrition/my-plan/$memberId"),
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _activePlan = NutritionModel.fromJson(data);
      } else {
        _activePlan = null;
      }
    } catch (e) {
      _errorMessage = "Beslenme planı alınamadı: $e";
      _activePlan = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignPlan({
    required int memberId,
    required int trainerId,
    required int dailyCalories,
    required int protein,
    required int carbs,
    required int fat,
    required List<String> meals,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = "${ApiService.baseUrl}/nutrition/assign?memberId=$memberId&trainerId=$trainerId";
      final response = await http.post(
        Uri.parse(url),
        headers: ApiService.getHeaders(),
        body: jsonEncode({
          "dailyCalories": dailyCalories,
          "protein": protein,
          "carbs": carbs,
          "fat": fat,
          "meals": meals,
        }),
      );

      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Assign plan error: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<NutritionModel?> fetchMemberPlan(int memberId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/nutrition/member-plan/$memberId"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _isLoading = false;
        notifyListeners();
        return NutritionModel.fromJson(data);
      }
    } catch (e) {
      debugPrint("Fetch member plan error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<void> fetchExpiredReports(int gymId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/nutrition/expired-reports/$gymId"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        _expiredReports = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Fetch expired nutrition reports error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
