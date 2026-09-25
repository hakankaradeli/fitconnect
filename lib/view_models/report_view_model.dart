import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class ReportViewModel extends ChangeNotifier {
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
      final base = ApiService.baseUrl;
      final headers = ApiService.getHeaders();

      final res1 = await http.get(Uri.parse("$base/bookings/reports/top-cancelled-members"), headers: headers);
      final res2 = await http.get(Uri.parse("$base/bookings/reports/top-cancelled-trainers-by-others"), headers: headers);
      final res3 = await http.get(Uri.parse("$base/bookings/reports/top-cancelling-trainers"), headers: headers);

      if (res1.statusCode == 200) _topCancelledMembers = jsonDecode(res1.body);
      if (res2.statusCode == 200) _topCancelledTrainersByOthers = jsonDecode(res2.body);
      if (res3.statusCode == 200) _topCancellingTrainers = jsonDecode(res3.body);

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
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/admin/reports/monthly?gymId=$gymId&month=$month"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        _monthlyReport = jsonDecode(response.body);
      }
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
      String format(DateTime dt) => dt.toIso8601String().split('.').first;
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/admin/reports/unperformed-range?gymId=$gymId&start=${format(start)}&end=${format(end)}"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        _dailyUnperformedReport = jsonDecode(response.body);
      }
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
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/admin/reports/trainer-complaints?gymId=$gymId"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        _trainerComplaints = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Fetch trainer complaints error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
