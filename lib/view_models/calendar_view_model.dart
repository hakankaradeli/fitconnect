import 'package:flutter/material.dart';
import 'dart:convert';
import '../repositories/booking_repository.dart';
import '../repositories/finance_repository.dart';
import '../models/booking_details_model.dart';
import '../models/slot_availability_model.dart';
import '../models/user_model.dart';

class CalendarViewModel extends ChangeNotifier {
  final BookingRepository _bookingRepository;
  final FinanceRepository _financeRepository;

  CalendarViewModel({
    required BookingRepository bookingRepository,
    required FinanceRepository financeRepository,
  })  : _bookingRepository = bookingRepository,
        _financeRepository = financeRepository;

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
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAvailableTrainers(int gymId, DateTime startTime) async {
    _isTrainersLoading = true;
    _availableTrainers = [];
    notifyListeners();

    try {
      _availableTrainers = await _bookingRepository.getAvailableTrainers(gymId, startTime);
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
      _availableSlots = await _bookingRepository.getAvailableSlots(trainerId, gymId, date);
    } catch (e) {
      debugPrint("Available slots error: $e");
    } finally {
      _isSlotsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBulkBookings({
    required int memberId,
    required int trainerId,
    required int gymId,
    required List<DateTime> startTimes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _bookingRepository.createBulkBookings(
        memberId: memberId,
        trainerId: trainerId,
        gymId: gymId,
        startTimes: startTimes,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['error'] ?? "Randevular oluşturulamadı";
      }
    } catch (e) {
      _errorMessage = "Sunucuya bağlanılamadı: $e";
      debugPrint("Bulk booking error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> fetchMemberHistory(int memberId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _memberHistory = await _bookingRepository.getMemberHistory(memberId);
    } catch (e) {
      debugPrint("History fetch error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refundBooking(int bookingId) async {
    try {
      final success = await _bookingRepository.refundBooking(bookingId);
      if (success) {
        return true;
      } else {
        _errorMessage = "İade işlemi başarısız";
        return false;
      }
    } catch (e) {
      debugPrint("Refund error: $e");
      _errorMessage = "Sunucuya bağlanılamadı.";
      return false;
    }
  }

  Future<bool> cancelAndRefundBooking(
    int bookingId, {
    int? memberId,
    int? cancelledById,
    String? reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      bool isRefundEndpointSuccess = false;
      try {
        isRefundEndpointSuccess = await _bookingRepository.refundBooking(bookingId);
      } catch (e) {
        debugPrint("Refund endpoint call error: $e");
      }

      if (!isRefundEndpointSuccess) {
        final rejectSuccess = await rejectBooking(
          bookingId,
          cancelledById: cancelledById,
          reason: reason ?? "Yönetici tarafından üyenin katılamadığı ders iptal edildi ve kredi iade edildi.",
        );
        if (!rejectSuccess) {
          _isLoading = false;
          notifyListeners();
          return false;
        }

        if (memberId != null) {
          try {
            final balance = await _financeRepository.getBalance(memberId);
            final int totalPurchased = balance.totalCredits;
            final int totalUsed = balance.usedCredits;

            final int newUsed = totalUsed > 0 ? totalUsed - 1 : 0;
            final int newTotal = totalUsed > 0 ? totalPurchased : totalPurchased + 1;

            await _financeRepository.updateMemberCredit(
              memberId: memberId,
              totalPurchased: newTotal,
              totalUsed: newUsed,
            );
          } catch (e) {
            debugPrint("Direct credit refund error: $e");
          }
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Cancel and refund error: $e");
      _errorMessage = "Sunucuya bağlanılamadı.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> proposeBookingChange(int bookingId, DateTime newTime) async {
    try {
      return await _bookingRepository.proposeChange(bookingId, newTime);
    } catch (e) {
      return false;
    }
  }

  Future<bool> approveBooking(int bookingId) async {
    try {
      return await _bookingRepository.approveBooking(bookingId);
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
      final response = await _bookingRepository.createBooking(
        memberId: memberId,
        trainerId: trainerId,
        gymId: gymId,
        startTime: startTime,
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
      return await _bookingRepository.rejectBooking(bookingId, cancelledById: cancelledById, reason: reason);
    } catch (e) {
      return false;
    }
  }

  Future<bool> changeBookingTrainer(int bookingId, int newTrainerId) async {
    try {
      return await _bookingRepository.changeTrainer(bookingId, newTrainerId);
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
      final response = await _bookingRepository.createBulkBookings(
        memberId: memberId,
        trainerId: trainerId,
        gymId: gymId,
        startTimes: startTimes,
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
      return await _bookingRepository.addPerformedExercises(bookingId, exercises);
    } catch (e) {
      debugPrint("Add exercises error: $e");
      return false;
    }
  }
}
