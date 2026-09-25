import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/booking_details_model.dart';

class TrainerScheduleViewModel extends ChangeNotifier {
  List<BookingDetails> _bookings = [];
  List<BookingDetails> _pendingApprovals = [];
  List<BookingDetails> _adminPendingBookings = [];
  bool _isLoading = false;
  bool _isPendingLoading = false;
  String? _errorMessage;

  List<BookingDetails> get bookings => _bookings;
  List<BookingDetails> get pendingApprovals => _pendingApprovals;
  List<BookingDetails> get adminPendingBookings => _adminPendingBookings;
  bool get isLoading => _isLoading;
  bool get isPendingLoading => _isPendingLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAdminPendingBookings(int gymId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/bookings/admin-pending/$gymId"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _adminPendingBookings = data.map((json) => BookingDetails.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Fetch admin pending error: $e");
    }
  }

  Future<void> fetchPendingApprovals(int trainerId) async {
    _isPendingLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/bookings/trainer-pending/$trainerId"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _pendingApprovals = data.map((json) => BookingDetails.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Pending approvals error: $e");
    } finally {
      _isPendingLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveBooking(int bookingId, int trainerId) async {
    try {
      final response = await http.put(
        Uri.parse("${ApiService.baseUrl}/bookings/trainer-approve/$bookingId"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        fetchPendingApprovals(trainerId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectBooking(int bookingId, int trainerId, {String? reason}) async {
    try {
      String url = "${ApiService.baseUrl}/bookings/trainer-reject/$bookingId";
      if (reason != null && reason.isNotEmpty) {
        url += "?reason=${Uri.encodeComponent(reason)}";
      }
      final response = await http.put(
        Uri.parse(url),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        fetchPendingApprovals(trainerId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchSchedule(int trainerId, DateTime start, DateTime end) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Milisaniyeleri temizleyerek Spring Boot uyumlu ISO formatı oluştur (yyyy-MM-ddTHH:mm:ss)
      String format(DateTime dt) => dt.toIso8601String().split('.').first;

      final url = Uri.parse("${ApiService.baseUrl}/bookings/trainer-schedule/$trainerId").replace(
        queryParameters: {
          "start": format(start),
          "end": format(end),
        },
      );
      final response = await http.get(
        url,
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _bookings = data.map((json) => BookingDetails.fromJson(json)).toList();
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = "Program yüklenemedi: ${response.statusCode}";
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Hata: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPerformedExercises(int bookingId, List<PerformedExercise> exercises) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/bookings/$bookingId/exercises"),
        headers: ApiService.getHeaders(),
        body: jsonEncode(exercises.map((e) => e.toJson()).toList()),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Add exercises error: $e");
      return false;
    }
  }
}
