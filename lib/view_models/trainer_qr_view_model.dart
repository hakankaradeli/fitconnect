import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/booking_repository.dart';

class TrainerQrViewModel extends ChangeNotifier {
  final BookingRepository _bookingRepository;

  TrainerQrViewModel({required BookingRepository bookingRepository})
      : _bookingRepository = bookingRepository;

  Timer? _timer;
  Timer? _statusCheckTimer;
  int _secondsRemaining = 20;
  String _qrData = "";
  bool _isSessionStarted = false;
  String? _completedMemberName;

  int get secondsRemaining => _secondsRemaining;
  String get qrData => _qrData;
  bool get isSessionStarted => _isSessionStarted;
  String? get completedMemberName => _completedMemberName;

  void startQrGenerator(String trainerId, String gymId, {int? bookingId}) {
    _isSessionStarted = false;
    _completedMemberName = null;
    _generateNewData(trainerId, gymId, bookingId);

    _timer?.cancel();
    _statusCheckTimer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        _generateNewData(trainerId, gymId, bookingId);
        _secondsRemaining = 20;
      } else {
        _secondsRemaining--;
      }
      notifyListeners();
    });

    final startTimestamp = DateTime.now().millisecondsSinceEpoch - 5000;

    if (bookingId != null) {
      _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        await _checkBookingStatus(bookingId);
      });
    } else {
      _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        await _checkDirectLessonStatus(trainerId, startTimestamp);
      });
    }
  }

  Future<void> _checkBookingStatus(int bookingId) async {
    try {
      final data = await _bookingRepository.checkBookingStatus(bookingId);
      if (data != null && data['status'] == 'COMPLETED') {
        _isSessionStarted = true;
        _completedMemberName = data['member'] != null ? data['member']['fullName'] : null;
        _statusCheckTimer?.cancel();
        _timer?.cancel();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Check booking status error: $e");
    }
  }

  Future<void> _checkDirectLessonStatus(String trainerId, int startTimestamp) async {
    try {
      final data = await _bookingRepository.checkDirectLessonStatus(trainerId, startTimestamp);
      if (data != null && data['completed'] == true) {
        _isSessionStarted = true;
        _completedMemberName = data['memberName'];
        _statusCheckTimer?.cancel();
        _timer?.cancel();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Check direct lesson status error: $e");
    }
  }

  void _generateNewData(String trainerId, String gymId, int? bookingId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    _qrData = "SESSION|$trainerId|$gymId|$timestamp|${bookingId ?? ""}";
  }

  void resetSessionStarted() {
    _isSessionStarted = false;
    _completedMemberName = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusCheckTimer?.cancel();
    super.dispose();
  }
}
