import '../models/expense_model.dart';
import '../services/api_result.dart';
import 'base_repository.dart';

class ExpenseRepository extends BaseRepository {
  ExpenseRepository({super.client, required super.apiService});

  Future<ApiResult<List<ExpenseModel>>> getExpensesResult(int gymId) async {
    return safeGet<List<ExpenseModel>>(
      "expenses/gym/$gymId",
      parser: (json) {
        if (json is List) {
          return json.map((item) => ExpenseModel.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <ExpenseModel>[];
      },
    );
  }

  Future<List<ExpenseModel>> getExpenses(int gymId) async {
    final result = await getExpensesResult(gymId);
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<bool>> addExpenseResult({
    required int gymId,
    required String category,
    required String title,
    required double amount,
    required DateTime expenseDate,
    int? trainerId,
    String? notes,
  }) async {
    final body = {
      "gymId": gymId,
      "category": category,
      "title": title,
      "amount": amount,
      "expenseDate": "${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}",
      "trainerId": trainerId,
      "notes": notes,
    };

    return safePost<bool>("expenses/create", body: body, parser: (_) => true);
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
    final result = await addExpenseResult(
      gymId: gymId,
      category: category,
      title: title,
      amount: amount,
      expenseDate: expenseDate,
      trainerId: trainerId,
      notes: notes,
    );
    return result.isSuccess;
  }

  Future<ApiResult<bool>> deleteExpenseResult(int expenseId) async {
    return safeDelete<bool>("expenses/$expenseId", parser: (_) => true);
  }

  Future<bool> deleteExpense(int expenseId) async {
    final result = await deleteExpenseResult(expenseId);
    return result.isSuccess;
  }
}
