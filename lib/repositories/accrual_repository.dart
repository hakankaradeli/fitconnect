import '../models/accrual_model.dart';
import '../services/api_result.dart';
import 'base_repository.dart';

class AccrualRepository extends BaseRepository {
  AccrualRepository({super.client, required super.apiService});

  Future<ApiResult<double>> getUnpaidAmountResult(int trainerId) async {
    return safeGet<double>(
      "accruals/unpaid/$trainerId",
      parser: (json) => (json is Map && json['amount'] != null)
          ? (json['amount'] as num).toDouble()
          : 0.0,
    );
  }

  Future<double> getUnpaidAmount(int trainerId) async {
    final result = await getUnpaidAmountResult(trainerId);
    return result.dataOrNull ?? 0.0;
  }

  Future<ApiResult<List<AccrualEntry>>> getUnpaidDetailsResult(int trainerId) async {
    return safeGet<List<AccrualEntry>>(
      "accruals/unpaid-details/$trainerId",
      parser: (json) {
        if (json is List) {
          return json.map((item) => AccrualEntry.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <AccrualEntry>[];
      },
    );
  }

  Future<List<AccrualEntry>> getUnpaidDetails(int trainerId) async {
    final result = await getUnpaidDetailsResult(trainerId);
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<Map<String, dynamic>>> getTrainerStatsResult(int trainerId) async {
    return safeGet<Map<String, dynamic>>(
      "accruals/stats/$trainerId",
      parser: (json) => json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> getTrainerStats(int trainerId) async {
    final result = await getTrainerStatsResult(trainerId);
    return result.dataOrNull ?? {};
  }

  Future<ApiResult<bool>> markAllAsPaidResult(int trainerId) async {
    return safePost<bool>(
      "accruals/pay-all/$trainerId",
      parser: (_) => true,
    );
  }

  Future<bool> markAllAsPaid(int trainerId) async {
    final result = await markAllAsPaidResult(trainerId);
    return result.isSuccess;
  }
}
