import 'package:flutter/material.dart';
import '../repositories/booking_repository.dart';
import '../models/booking_details_model.dart';

class TrainerScheduleViewModel extends ChangeNotifier {
  final BookingRepository _bookingRepository;

  TrainerScheduleViewModel({required BookingRepository bookingRepository})
      : _bookingRepository = bookingRepository;

  List<BookingDetails> _bookings = [];
  List<BookingDetails> _pendingApprovals = [];
  List<BookingDetails> _adminPendingBookings = [];
  List<BookingDetails> _gymWeeklyBookings = [];
  bool _isLoading = false;
  bool _isPendingLoading = false;
  String? _errorMessage;

  List<BookingDetails> get bookings => _bookings;
  List<BookingDetails> get pendingApprovals => _pendingApprovals;
  List<BookingDetails> get adminPendingBookings => _adminPendingBookings;
  List<BookingDetails> get gymWeeklyBookings => _gymWeeklyBookings;
  bool get isLoading => _isLoading;
  bool get isPendingLoading => _isPendingLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAdminPendingBookings(int gymId) async {
    try {
      _adminPendingBookings = await _bookingRepository.getAdminPendingBookings(gymId);
      notifyListeners();
    } catch (e) {
      debugPrint("Fetch admin pending error: $e");
    }
  }

  Future<void> fetchPendingApprovals(int trainerId) async {
    _isPendingLoading = true;
    notifyListeners();
    try {
      _pendingApprovals = await _bookingRepository.getTrainerPendingApprovals(trainerId);
    } catch (e) {
      debugPrint("Pending approvals error: $e");
    } finally {
      _isPendingLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveBooking(int bookingId, int trainerId) async {
    try {
      final success = await _bookingRepository.trainerApprove(bookingId);
      if (success) {
        fetchPendingApprovals(trainerId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectBooking(int bookingId, int trainerId, {String? reason, bool isDirectCancel = false}) async {
    try {
      final success = await _bookingRepository.trainerReject(
        bookingId,
        reason: reason,
        isDirectCancel: isDirectCancel,
      );
      if (success) {
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
      _bookings = await _bookingRepository.getTrainerSchedule(trainerId, start, end);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = "Hata: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchGymSchedule(int gymId, DateTime start, DateTime end) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _gymWeeklyBookings = await _bookingRepository.getGymSchedule(gymId, start, end);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = "Hata: $e";
      _isLoading = false;
      notifyListeners();
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

  Future<Map<String, dynamic>> startDirectLesson(int trainerId, int memberId, {String? lessonType}) async {
    try {
      final result = await _bookingRepository.startDirectLesson(trainerId, memberId, lessonType);
      if (result != null) {
        return {"success": true, "message": result['message'] ?? "Ders başarıyla başlatıldı!"};
      }
      return {"success": false, "message": "Ders başlatılamadı."};
    } catch (e) {
      return {"success": false, "message": "Hata: $e"};
    }
  }
}
