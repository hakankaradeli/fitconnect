import 'package:flutter/material.dart';
import '../repositories/finance_repository.dart';
import '../models/finance_model.dart';

class FinanceViewModel extends ChangeNotifier {
  final FinanceRepository _repository;

  FinanceViewModel({required FinanceRepository repository})
      : _repository = repository;

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
      _balance = await _repository.getBalance(memberId);
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
    double upfrontAmount = 0.0,
    required bool isPaid,
    DateTime? dueDate,
  }) async {
    try {
      final success = await _repository.addCredit(
        memberId: memberId,
        amount: amount,
        paymentAmount: paymentAmount,
        upfrontAmount: upfrontAmount,
        isPaid: isPaid,
        dueDate: dueDate,
      );
      if (success) {
        await fetchBalance(memberId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMemberCredit({
    required int memberId,
    required int totalPurchased,
    required int totalUsed,
  }) async {
    try {
      final success = await _repository.updateMemberCredit(
        memberId: memberId,
        totalPurchased: totalPurchased,
        totalUsed: totalUsed,
      );
      if (success) {
        await fetchBalance(memberId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Update credit error: $e");
      return false;
    }
  }

  Future<void> fetchAllInstallments(int gymId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _installments = await _repository.getAllInstallments(gymId);
    } catch (e) {
      debugPrint("Installments fetch error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmPayment(int installmentId, int gymId) async {
    try {
      final success = await _repository.confirmPayment(installmentId);
      if (success) {
        await fetchAllInstallments(gymId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void spendCredit() {
    _balance.usedCredits += 1;
    notifyListeners();
  }

  void receivePayment(dynamic planId, int creditsToLoad) {
    final index = _installments.indexWhere((p) => p.id.toString() == planId.toString());
    if (index != -1) {
      _installments[index].status = PaymentStatus.paid;
      _balance.totalCredits += creditsToLoad;
      notifyListeners();
    }
  }

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
    debugPrint("WhatsApp API: Yarın ${plan.amount} TL ödemeniz bulunmaktadır.");
  }
}
