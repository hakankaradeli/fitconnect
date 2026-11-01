import 'package:flutter/material.dart';
import 'dart:convert';
import '../repositories/booking_repository.dart';

class MemberScannerViewModel extends ChangeNotifier {
  final BookingRepository _bookingRepository;

  MemberScannerViewModel({required BookingRepository bookingRepository})
      : _bookingRepository = bookingRepository;

  bool _isProcessing = false;
  String? _statusMessage;

  bool get isProcessing => _isProcessing;
  String? get statusMessage => _statusMessage;

  Future<bool> validateAndStartSession(String qrData, {int? memberId}) async {
    if (_isProcessing) return false;

    _isProcessing = true;
    _statusMessage = "Ders doğrulanıyor...";
    notifyListeners();

    try {
      final parts = qrData.split('|');
      if (parts[0] != "SESSION" || parts.length < 4) {
        throw "Geçersiz QR Kod!";
      }

      final trainerId = parts[1];
      final bookingIdStr = parts.length > 4 ? parts[4] : "";
      final bookingId = int.tryParse(bookingIdStr);

      final response = await _bookingRepository.verifyQrLesson(
        bookingId: bookingId,
        trainerId: trainerId,
        memberId: memberId,
      );

      debugPrint("MemberScanner: [verify-qr] -> Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
        _statusMessage = "Ders Başarıyla Tamamlandı!";
        _isProcessing = false;
        notifyListeners();
        return true;
      } else {
        String errorMsg;
        try {
          final error = jsonDecode(response.body);
          errorMsg = error['error'] ?? error['message'] ?? "Doğrulama başarısız (${response.statusCode})";
        } catch (_) {
          errorMsg = response.body.isNotEmpty
              ? response.body
              : "İşlem başarısız oldu (HTTP ${response.statusCode})";
        }
        throw errorMsg;
      }
    } catch (e) {
      debugPrint("MemberScanner Hatası: $e");
      _statusMessage = e.toString().replaceFirst("Exception: ", "");
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }
}
