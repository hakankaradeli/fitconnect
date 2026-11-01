import 'package:flutter/material.dart';
import '../repositories/trainer_rate_repository.dart';

class TrainerRateViewModel extends ChangeNotifier {
  final TrainerRateRepository _repository;

  TrainerRateViewModel({required TrainerRateRepository repository})
      : _repository = repository;

  Map<String, double> _rates = {};
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, double> get rates => _rates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRates(int trainerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _rates = await _repository.getRates(trainerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = "Hata: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRate({
    required int trainerId,
    required String lessonType,
    required double amount,
    required int gymId,
  }) async {
    try {
      final success = await _repository.updateRate(
        trainerId: trainerId,
        lessonType: lessonType,
        amount: amount,
        gymId: gymId,
      );

      if (success) {
        _rates[lessonType] = amount;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
