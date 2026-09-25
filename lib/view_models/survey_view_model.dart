import 'package:flutter/material.dart';

class SurveyViewModel extends ChangeNotifier {
  double _rating = 0;
  bool _isSubmitting = false;

  double get rating => _rating;
  bool get isSubmitting => _isSubmitting;

  void setRating(double value) {
    _rating = value;
    notifyListeners();
  }

  Future<bool> submitSurvey(String comment) async {
    if (_rating == 0) return false;

    _isSubmitting = true;
    notifyListeners();

    // Backend Simülasyonu
    await Future.delayed(const Duration(seconds: 2));

    // Burada API'ye gönderilecek: "POST /api/surveys"
    
    _isSubmitting = false;
    _rating = 0; // Reset
    notifyListeners();
    return true;
  }
}
