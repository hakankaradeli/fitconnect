import 'package:flutter/material.dart';
import '../repositories/report_repository.dart';

class ReportViewModel extends ChangeNotifier {
  final ReportRepository _repository;

  ReportViewModel({required ReportRepository repository})
      : _repository = repository;

  List<dynamic> _topCancelledMembers = [];
  List<dynamic> _topCancelledTrainersByOthers = [];
  List<dynamic> _topCancellingTrainers = [];
  List<dynamic> _dailyUnperformedReport = [];
  List<dynamic> _trainerComplaints = [];
  Map<String, dynamic>? _monthlyReport;
  bool _isLoading = false;

  List<dynamic> get topCancelledMembers => _topCancelledMembers;
  List<dynamic> get topCancelledTrainersByOthers => _topCancelledTrainersByOthers;
  List<dynamic> get topCancellingTrainers => _topCancellingTrainers;
  List<dynamic> get dailyUnperformedReport => _dailyUnperformedReport;
  List<dynamic> get trainerComplaints => _trainerComplaints;
  Map<String, dynamic>? get monthlyReport => _monthlyReport;
  bool get isLoading => _isLoading;

  Future<void> fetchCancellationReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.getCancellationReports();
      _topCancelledMembers = result.topCancelledMembers;
      _topCancelledTrainersByOthers = result.topCancelledTrainersByOthers;
      _topCancellingTrainers = result.topCancellingTrainers;
    } catch (e) {
      debugPrint("Report fetch error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMonthlyReport(int gymId, int month) async {
    _isLoading = true;
    notifyListeners();
    try {
      _monthlyReport = await _repository.getMonthlyReport(gymId, month);
    } catch (e) {
      debugPrint("Monthly report error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDailyUnperformedReport(int gymId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    await fetchUnperformedRangeReport(gymId, start, end);
  }

  Future<void> fetchUnperformedRangeReport(int gymId, DateTime start, DateTime end) async {
    _isLoading = true;
    notifyListeners();
    try {
      _dailyUnperformedReport = await _repository.getUnperformedRangeReport(gymId, start, end);
    } catch (e) {
      debugPrint("Fetch unperformed range error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTrainerComplaints(int gymId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _trainerComplaints = await _repository.getTrainerComplaints(gymId);
    } catch (e) {
      debugPrint("Fetch trainer complaints error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
