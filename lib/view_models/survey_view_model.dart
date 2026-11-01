import 'package:flutter/material.dart';
import '../repositories/survey_repository.dart';

class SurveyViewModel extends ChangeNotifier {
  final SurveyRepository _repository;

  SurveyViewModel({required SurveyRepository repository})
      : _repository = repository;

  double _rating = 0;
  bool _isSubmitting = false;

  double get rating => _rating;
  bool get isSubmitting => _isSubmitting;

  void setRating(double value) {
    _rating = value;
    notifyListeners();
  }

  Future<bool> submitSurvey(String comment, {int? bookingId, int? trainerId, int? memberId}) async {
    if (_rating == 0) return false;

    _isSubmitting = true;
    notifyListeners();

    final result = await _repository.submitSurveyResult(
      bookingId: bookingId,
      trainerId: trainerId,
      memberId: memberId,
      rating: _rating,
      comment: comment.trim().isNotEmpty ? comment.trim() : null,
    );

    _isSubmitting = false;
    final success = result.isSuccess;
    if (success) {
      _rating = 0;
    }
    notifyListeners();
    return success;
  }
}
