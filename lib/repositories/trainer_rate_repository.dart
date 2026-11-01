import '../services/api_result.dart';
import 'base_repository.dart';

class TrainerRateRepository extends BaseRepository {
  TrainerRateRepository({super.client, required super.apiService});

  Future<ApiResult<Map<String, double>>> getRatesResult(int trainerId) async {
    return safeGet<Map<String, double>>(
      "trainer-rates/$trainerId",
      parser: (json) {
        if (json is List) {
          return {for (var item in json) item['lessonType'].toString(): (item['amount'] as num).toDouble()};
        }
        return <String, double>{};
      },
    );
  }

  Future<Map<String, double>> getRates(int trainerId) async {
    final result = await getRatesResult(trainerId);
    return result.fold(
      onSuccess: (data) => data,
      onFailure: (msg, code) => throw Exception("Ücretler yüklenemedi: $msg ($code)"),
    );
  }

  Future<ApiResult<bool>> updateRateResult({
    required int trainerId,
    required String lessonType,
    required double amount,
    required int gymId,
  }) async {
    return safePost<bool>(
      "trainer-rates/$trainerId",
      body: {
        "lessonType": lessonType,
        "amount": amount,
        "gymId": gymId,
      },
      parser: (_) => true,
    );
  }

  Future<bool> updateRate({
    required int trainerId,
    required String lessonType,
    required double amount,
    required int gymId,
  }) async {
    final result = await updateRateResult(
      trainerId: trainerId,
      lessonType: lessonType,
      amount: amount,
      gymId: gymId,
    );
    return result.isSuccess;
  }
}
