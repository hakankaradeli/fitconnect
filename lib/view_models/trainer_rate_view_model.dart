import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class TrainerRateViewModel extends ChangeNotifier {
  Map<String, double> _rates = {};
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, double> get rates => _rates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRates(int trainerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/trainer-rates/$trainerId"),
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _rates = {for (var item in data) item['lessonType']: item['amount'].toDouble()};
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = "Ücretler yüklenemedi.";
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Hata: $e";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRate({
    required int trainerId,
    required String lessonType,
    required double amount,
    required int gymId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/trainer-rates/$trainerId"),
        headers: ApiService.getHeaders(),
        body: jsonEncode({
          "lessonType": lessonType,
          "amount": amount,
          "gymId": gymId,
        }),
      );

      if (response.statusCode == 200) {
        _rates[lessonType] = amount;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
