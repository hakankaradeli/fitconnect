import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/booking_details_model.dart';
import '../models/slot_availability_model.dart';
import '../models/user_model.dart';

class CalendarViewModel extends ChangeNotifier {
  List<BookingDetails> _memberHistory = [];
  List<SlotAvailability> _availableSlots = [];
  bool _isLoading = false;
  bool _isSlotsLoading = false;

  List<BookingDetails> get memberHistory => _memberHistory;
  List<SlotAvailability> get availableSlots => _availableSlots;
  List<UserModel> _availableTrainers = [];
  List<UserModel> get availableTrainers => _availableTrainers;

  bool get isLoading => _isLoading;
  bool get isSlotsLoading => _isSlotsLoading;
  bool _isTrainersLoading = false;
  bool get isTrainersLoading => _isTrainersLoading;

  Future<void> fetchAvailableTrainers(int gymId, DateTime startTime) async {
    _isTrainersLoading = true;
    _availableTrainers = [];
    notifyListeners();

    try {
      String format(DateTime dt) => dt.toIso8601String().split('.').first;
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/bookings/available-trainers?gymId=$gymId&startTime=${format(startTime)}"),
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _availableTrainers = data.map((json) => UserModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Available trainers error: $e");
    } finally {
      _isTrainersLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAvailableSlots(int trainerId, int gymId, DateTime date) async {
    _isSlotsLoading = true;
    _availableSlots = [];
    notifyListeners();

    try {
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/bookings/available-slots?trainerId=$trainerId&gymId=$gymId&date=$dateStr"),
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _availableSlots = data.map((json) => SlotAvailability.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Available slots error: $e");
    } finally {
      _isSlotsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMemberHistory(int memberId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/bookings/member-history/$memberId"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _memberHistory = data.map((json) => BookingDetails.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("History fetch error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> proposeBookingChange(int bookingId, DateTime newTime) async {
    try {
      final uri = Uri.parse("${ApiService.baseUrl}/bookings/propose/$bookingId")
          .replace(queryParameters: {"newStartTime": newTime.toIso8601String()});
      
      final response = await http.put(uri, headers: ApiService.getHeaders());
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> approveBooking(int bookingId) async {
    try {
      final response = await http.put(
        Uri.parse("${ApiService.baseUrl}/bookings/approve/$bookingId"),
        headers: ApiService.getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  String? validateBooking(DateTime selectedDate, bool hasFixedDay) {
    final now = DateTime.now();
    if (selectedDate.weekday == DateTime.sunday) {
      return "Pazar günleri salonumuz kapalıdır.";
    }
    if (selectedDate.hour < 7 || selectedDate.hour > 21) {
      return "Randevular sadece 07:00 - 21:00 saatleri arasındadır.";
    }
    if (!hasFixedDay) {
      final difference = selectedDate.difference(now);
      if (difference.inHours < 24) {
        return "Sabit saatiniz olmadığı için en geç 24 saat önceden randevu almalısınız.";
      }
    }
    return null;
  }

  bool checkCapacity(int currentCount) {
    return currentCount < 4;
  }

  bool canCancelFree(DateTime appointmentTime) {
    final now = DateTime.now();
    final difference = appointmentTime.difference(now);
    return difference.inHours >= 4;
  }

  Future<bool> createAppointment({
    required int memberId,
    required int trainerId,
    required int gymId,
    required DateTime startTime,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/bookings/create"),
        headers: ApiService.getHeaders(),
        body: jsonEncode({
          "memberId": memberId,
          "trainerId": trainerId,
          "gymId": gymId,
          "startTime": startTime.toIso8601String(),
        }),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw error['error'] ?? "Randevu alınamadı.";
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> rejectBooking(int bookingId, {int? cancelledById, String? reason}) async {
    try {
      final queryParams = {
        if (cancelledById != null) 'cancelledById': cancelledById.toString(),
        if (reason != null) 'reason': reason,
      };
      
      final uri = Uri.parse("${ApiService.baseUrl}/bookings/reject/$bookingId")
          .replace(queryParameters: queryParams);
          
      final response = await http.put(uri, headers: ApiService.getHeaders());
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changeBookingTrainer(int bookingId, int newTrainerId) async {
    try {
      final response = await http.put(
        Uri.parse("${ApiService.baseUrl}/bookings/change-trainer/$bookingId?newTrainerId=$newTrainerId"),
        headers: ApiService.getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createBulkAppointments({
    required int memberId,
    required int trainerId,
    required int gymId,
    required List<DateTime> startTimes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/bookings/create-bulk"),
        headers: ApiService.getHeaders(),
        body: jsonEncode({
          "memberId": memberId,
          "trainerId": trainerId,
          "gymId": gymId,
          "startTimes": startTimes.map((t) => t.toIso8601String()).toList(),
        }),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw error['error'] ?? "Randevular alınamadı.";
      }
    } catch (e) {
      rethrow;
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
