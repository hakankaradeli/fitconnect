import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/finance_model.dart';

class FinanceViewModel extends ChangeNotifier {
  MemberBalance _balance = MemberBalance(totalCredits: 0, usedCredits: 0);
  List<PaymentPlan> _installments = [];
  bool _isLoading = false;

  MemberBalance get balance => _balance;
  List<PaymentPlan> get installments => _installments;
  bool get isLoading => _isLoading;

  Future<void> fetchBalance(int memberId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/finance/balance/$memberId"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _balance = MemberBalance(
          totalCredits: data['totalPurchased'],
          usedCredits: data['totalUsed'],
        );
      }
    } catch (e) {
      debugPrint("Balance fetch error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCredit({
    required int memberId,
    required int amount,
    required double paymentAmount,
    required bool isPaid,
    DateTime? dueDate,
  }) async {
    try {
      String url = "${ApiService.baseUrl}/finance/add-credit/$memberId?amount=$amount&paymentAmount=$paymentAmount&isPaid=$isPaid";
      if (dueDate != null) {
        url += "&dueDate=${dueDate.toIso8601String().split('T').first}";
      }

      final response = await http.post(
        Uri.parse(url),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        await fetchBalance(memberId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchAllInstallments(int gymId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/finance/installments/$gymId"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _installments = data.map((json) => PaymentPlan.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Installments fetch error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmPayment(int installmentId, int gymId) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/finance/pay/$installmentId"),
        headers: ApiService.getHeaders(),
      );
      if (response.statusCode == 200) {
        await fetchAllInstallments(gymId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // PRD: Kredi Düşüm Kuralı (Her Seans = 1 Kredi)
  void spendCredit() {
    _balance.usedCredits += 1;
    notifyListeners();
  }

  // PRD: Ödeme gerçekleştiğinde krediyi yükle ve eksi bakiyeyi kapat
  void receivePayment(String planId, int creditsToLoad) {
    final index = _installments.indexWhere((p) => p.id == planId);
    if (index != -1) {
      _installments[index].status = PaymentStatus.paid;
      _balance.totalCredits += creditsToLoad; 
      // Not: netBalance otomatik olarak (total - used) şeklinde düzelecektir.
      notifyListeners();
    }
  }

  // T-1 Gün Hatırlatma Mantığı (Pseudo-code)
  void checkReminders() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    for (var plan in _installments) {
      if (plan.status == PaymentStatus.pending && 
          plan.dueDate.day == tomorrow.day) {
        _sendWhatsAppReminder(plan);
      }
    }
  }

  void _sendWhatsAppReminder(PaymentPlan plan) {
    print("WhatsApp API: Yarın ${plan.amount} TL ödemeniz bulunmaktadır.");
  }
}
