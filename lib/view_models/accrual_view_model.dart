import 'package:flutter/material.dart';
import '../models/accrual_model.dart';
import '../repositories/accrual_repository.dart';

class AccrualViewModel extends ChangeNotifier {
  final AccrualRepository _repository;

  AccrualViewModel({required AccrualRepository repository})
      : _repository = repository;

  bool _isLoading = false;
  String? _errorMessage;

  List<AccrualEntry> _pendingAccruals = [];

  double _unpaidAmount = 0.0;
  int _totalLessons = 0;
  double _averageRating = 0.0;
  int _ptCount = 0;
  int _reformerCount = 0;
  int _yogaCount = 0;
  List<dynamic> _recentLessons = [];

  final Map<LessonType, double> _rates = {
    LessonType.pt1to1: 250.0,
    LessonType.ptDuo: 150.0,
    LessonType.reformerGroup: 100.0,
  };

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<AccrualEntry> get pendingAccruals => _pendingAccruals;
  double get totalBalance => _unpaidAmount > 0
      ? _unpaidAmount
      : _pendingAccruals.fold(0.0, (sum, item) => sum + item.amount);
  double get averageRating => _averageRating;
  int get totalLessons => _totalLessons;
  int get ptCount => _ptCount;
  int get reformerCount => _reformerCount;
  int get yogaCount => _yogaCount;
  List<dynamic> get recentLessons => _recentLessons;

  Future<void> fetchUnpaidDetails(int trainerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final detailsResult = await _repository.getUnpaidDetailsResult(trainerId);
      detailsResult.fold(
        onSuccess: (data) => _pendingAccruals = data,
        onFailure: (msg, _) => _errorMessage = msg,
      );

      final amountResult = await _repository.getUnpaidAmountResult(trainerId);
      amountResult.fold(
        onSuccess: (data) => _unpaidAmount = data,
        onFailure: (msg, _) {
          _errorMessage ??= msg;
        },
      );
    } catch (e) {
      _errorMessage = "Hakediş detayları alınamadı: $e";
      debugPrint("[AccrualViewModel] Fetch unpaid details error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTrainerStats(int trainerId) async {
    try {
      final result = await _repository.getTrainerStatsResult(trainerId);
      result.fold(
        onSuccess: (stats) {
          if (stats.isNotEmpty) {
            _unpaidAmount = (stats['unpaidAmount'] as num?)?.toDouble() ?? 0.0;
            _totalLessons = (stats['totalLessons'] as num?)?.toInt() ?? 0;
            _averageRating = (stats['averageRating'] as num?)?.toDouble() ?? 0.0;
            _ptCount = (stats['ptCount'] as num?)?.toInt() ?? 0;
            _reformerCount = (stats['reformerCount'] as num?)?.toInt() ?? 0;
            _yogaCount = (stats['yogaCount'] as num?)?.toInt() ?? 0;
            _recentLessons = stats['recentLessons'] ?? [];
            notifyListeners();
          }
        },
        onFailure: (msg, _) {
          debugPrint("[AccrualViewModel] Fetch trainer stats error: $msg");
        },
      );
    } catch (e) {
      debugPrint("[AccrualViewModel] Fetch trainer stats error: $e");
    }
  }

  void addLessonAccrual(String memberName, LessonType type) {
    debugPrint("[AccrualViewModel] addLessonAccrual: '$memberName' ($type) için yerel hakediş kaydı eklendi.");
    final entry = AccrualEntry(
      id: DateTime.now().toString(),
      date: DateTime.now(),
      memberName: memberName,
      lessonType: type,
      amount: _rates[type] ?? 0.0,
    );
    _pendingAccruals.add(entry);
    notifyListeners();
  }

  Future<bool> processPayment([int? trainerId]) async {
    if (trainerId == null || trainerId <= 0) {
      _errorMessage = "Hata: Ödeme işlemi için geçerli bir eğitmen seçilmelidir.";
      debugPrint("[AccrualViewModel] HATA: trainerId belirtilmedi.");
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.markAllAsPaidResult(trainerId);
      final isSuccess = result.fold(
        onSuccess: (_) {
          _pendingAccruals.clear();
          _unpaidAmount = 0.0;
          return true;
        },
        onFailure: (msg, _) {
          _errorMessage = msg;
          return false;
        },
      );
      _isLoading = false;
      notifyListeners();
      return isSuccess;
    } catch (e) {
      _errorMessage = "Ödeme işlemi başarısız: $e";
      debugPrint("[AccrualViewModel] HATA: Ödeme işlemi başarısız: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
