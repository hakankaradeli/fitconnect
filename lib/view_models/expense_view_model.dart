import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/expense_model.dart';

class ExpenseViewModel extends ChangeNotifier {
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
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/expenses/gym/$gymId"),
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _expenses = data.map((json) => ExpenseModel.fromJson(json)).toList();
      }
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
      final body = {
        "gymId": gymId,
        "category": category,
        "title": title,
        "amount": amount,
        "expenseDate": "${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}",
        "trainerId": trainerId,
        "notes": notes,
      };

      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/expenses/create"),
        headers: ApiService.getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
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
      final response = await http.delete(
        Uri.parse("${ApiService.baseUrl}/expenses/$expenseId"),
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        await fetchExpenses(gymId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
