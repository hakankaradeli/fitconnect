import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

class MemberScannerViewModel extends ChangeNotifier {
  bool _isProcessing = false;
  String? _statusMessage;

  bool get isProcessing => _isProcessing;
  String? get statusMessage => _statusMessage;

  // QR Kod okunduğunda çalışacak fonksiyon
  Future<bool> validateAndStartSession(String qrData) async {
    if (_isProcessing) return false;

    _isProcessing = true;
    _statusMessage = "Ders doğrulanıyor...";
    notifyListeners();

    try {
      // QR Verisini parçala: SESSION|trainerId|gymId|timestamp|bookingId
      final parts = qrData.split('|');
      if (parts[0] != "SESSION" || parts.length < 5) {
        throw "Geçersiz QR Kod!";
      }

      final trainerId = parts[1];
      final bookingId = parts[4];

      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/lessons/verify-qr?bookingId=$bookingId&trainerId=$trainerId"),
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        _statusMessage = "Ders Başarıyla Tamamlandı!";
        _isProcessing = false;
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw error['error'] ?? "Doğrulama başarısız.";
      }
    } catch (e) {
      _statusMessage = "Hata: $e";
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }
}
