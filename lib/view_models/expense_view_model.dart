import 'package:flutter/material.dart';
import '../repositories/expense_repository.dart';
import '../models/expense_model.dart';

class ExpenseViewModel extends ChangeNotifier {
  final ExpenseRepository _repository;

  ExpenseViewModel({required ExpenseRepository repository})
      : _repository = repository;

  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalExpenses => _expenses.fold(0.0, (sum, item) => sum + item.amount);

  Future<void> fetchExpenses(int gymId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _expenses = await _repository.getExpenses(gymId);
    } catch (e) {
      debugPrint("Fetch expenses error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense({
    required int gymId,
    required String category,
    required String title,
    required double amount,
    required DateTime expenseDate,
    int? trainerId,
    String? notes,
  }) async {
    try {
      final success = await _repository.addExpense(
        gymId: gymId,
        category: category,
        title: title,
        amount: amount,
        expenseDate: expenseDate,
        trainerId: trainerId,
        notes: notes,
      );

      if (success) {
        await fetchExpenses(gymId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Add expense error: $e");
      return false;
    }
  }

  Future<bool> deleteExpense(int expenseId, int gymId) async {
    try {
      final success = await _repository.deleteExpense(expenseId);
      if (success) {
        await fetchExpenses(gymId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
