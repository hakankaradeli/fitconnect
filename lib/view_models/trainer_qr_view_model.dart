import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class TrainerQrViewModel extends ChangeNotifier {
  Timer? _timer;
  Timer? _statusCheckTimer;
  int _secondsRemaining = 20;
  String _qrData = "";
  bool _isSessionStarted = false;

  int get secondsRemaining => _secondsRemaining;
  String get qrData => _qrData;
  bool get isSessionStarted => _isSessionStarted;

  // QR kodunu oluştur ve sayacı başlat
  void startQrGenerator(String trainerId, String gymId, {int? bookingId}) {
    _isSessionStarted = false;
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

    // Eğer bookingId varsa üyenin QR okutup okutmadığını anlık sorgula
    if (bookingId != null) {
      _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        await _checkBookingStatus(bookingId);
      });
    }
  }

  Future<void> _checkBookingStatus(int bookingId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/bookings/$bookingId"),
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'COMPLETED') {
          _isSessionStarted = true;
          _statusCheckTimer?.cancel();
          _timer?.cancel();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Check booking status error: $e");
    }
  }

  void _generateNewData(String trainerId, String gymId, int? bookingId) {
    // Veri formatı: SESSION | TrainerID | GymID | Tam Zaman Damgası | BookingID
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    _qrData = "SESSION|$trainerId|$gymId|$timestamp|${bookingId ?? ""}";
  }

  void resetSessionStarted() {
    _isSessionStarted = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusCheckTimer?.cancel();
    super.dispose();
  }
}
