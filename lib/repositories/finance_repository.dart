import '../models/finance_model.dart';
import '../services/api_result.dart';
import 'base_repository.dart';

class FinanceRepository extends BaseRepository {
  FinanceRepository({super.client, required super.apiService});

  Future<ApiResult<MemberBalance>> getBalanceResult(int memberId) async {
    return safeGet<MemberBalance>(
      "finance/balance/$memberId",
      parser: (json) {
        if (json is Map) {
          return MemberBalance(
            totalCredits: json['totalPurchased'] ?? 0,
            usedCredits: json['totalUsed'] ?? 0,
          );
        }
        return MemberBalance(totalCredits: 0, usedCredits: 0);
      },
    );
  }

  Future<MemberBalance> getBalance(int memberId) async {
    final result = await getBalanceResult(memberId);
    return result.dataOrNull ?? MemberBalance(totalCredits: 0, usedCredits: 0);
  }

  Future<ApiResult<bool>> addCreditResult({
    required int memberId,
    required int amount,
    required double paymentAmount,
    double upfrontAmount = 0.0,
    required bool isPaid,
    DateTime? dueDate,
  }) async {
    final queryParams = {
      "amount": amount.toString(),
      "paymentAmount": paymentAmount.toString(),
      "upfrontAmount": upfrontAmount.toString(),
      "isPaid": isPaid.toString(),
      if (dueDate != null) "dueDate": dueDate.toIso8601String().split('T').first,
    };

    return safePost<bool>("finance/add-credit/$memberId", queryParameters: queryParams, parser: (_) => true);
  }

  Future<bool> addCredit({
    required int memberId,
    required int amount,
    required double paymentAmount,
    double upfrontAmount = 0.0,
    required bool isPaid,
    DateTime? dueDate,
  }) async {
    final result = await addCreditResult(
      memberId: memberId,
      amount: amount,
      paymentAmount: paymentAmount,
      upfrontAmount: upfrontAmount,
      isPaid: isPaid,
      dueDate: dueDate,
    );
    return result.isSuccess;
  }

  Future<ApiResult<bool>> updateMemberCreditResult({
    required int memberId,
    required int totalPurchased,
    required int totalUsed,
  }) async {
    return safePut<bool>(
      "finance/credit/$memberId",
      body: {
        "totalPurchased": totalPurchased,
        "totalUsed": totalUsed,
      },
      parser: (_) => true,
    );
  }

  Future<bool> updateMemberCredit({
    required int memberId,
    required int totalPurchased,
    required int totalUsed,
  }) async {
    final result = await updateMemberCreditResult(
      memberId: memberId,
      totalPurchased: totalPurchased,
      totalUsed: totalUsed,
    );
    return result.isSuccess;
  }

  Future<ApiResult<List<PaymentPlan>>> getAllInstallmentsResult(int gymId) async {
    return safeGet<List<PaymentPlan>>(
      "finance/installments/$gymId",
      parser: (json) {
        if (json is List) {
          return json.map((item) => PaymentPlan.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <PaymentPlan>[];
      },
    );
  }

  Future<List<PaymentPlan>> getAllInstallments(int gymId) async {
    final result = await getAllInstallmentsResult(gymId);
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<bool>> confirmPaymentResult(int installmentId) async {
    return safePost<bool>("finance/pay/$installmentId", parser: (_) => true);
  }

  Future<bool> confirmPayment(int installmentId) async {
    final result = await confirmPaymentResult(installmentId);
    return result.isSuccess;
  }
}
