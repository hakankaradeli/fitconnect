import 'package:flutter/material.dart';
import '../repositories/nutrition_repository.dart';
import '../models/nutrition_model.dart';

class NutritionViewModel extends ChangeNotifier {
  final NutritionRepository _repository;

  NutritionViewModel({required NutritionRepository repository})
      : _repository = repository;

  NutritionModel? _activePlan;
  List<dynamic> _expiredReports = [];
  List<dynamic> _membersWithoutPlan = [];
  bool _isLoading = false;
  String? _errorMessage;

  NutritionModel? get activePlan => _activePlan;
  List<dynamic> get expiredReports => _expiredReports;
  List<dynamic> get membersWithoutPlan => _membersWithoutPlan;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyPlan(int memberId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activePlan = await _repository.getMyPlan(memberId);
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
      final success = await _repository.assignPlan(
        memberId: memberId,
        trainerId: trainerId,
        dailyCalories: dailyCalories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        meals: meals,
      );

      _isLoading = false;
      notifyListeners();
      return success;
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
      final plan = await _repository.getMemberPlan(memberId);
      _isLoading = false;
      notifyListeners();
      return plan;
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
      _expiredReports = await _repository.getExpiredReports(gymId);
    } catch (e) {
      debugPrint("Fetch expired nutrition reports error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMembersWithoutPlan(int gymId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _membersWithoutPlan = await _repository.getMembersWithoutPlan(gymId);
    } catch (e) {
      debugPrint("Fetch members without plan error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
