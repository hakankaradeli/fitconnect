import '../services/api_result.dart';
import 'base_repository.dart';

class CancellationReportsResult {
  final List<dynamic> topCancelledMembers;
  final List<dynamic> topCancelledTrainersByOthers;
  final List<dynamic> topCancellingTrainers;

  CancellationReportsResult({
    required this.topCancelledMembers,
    required this.topCancelledTrainersByOthers,
    required this.topCancellingTrainers,
  });
}

class ReportRepository extends BaseRepository {
  ReportRepository({super.client, required super.apiService});

  Future<ApiResult<CancellationReportsResult>> getCancellationReportsResult() async {
    final res1 = await safeGet<List<dynamic>>("bookings/reports/top-cancelled-members", parser: (j) => j is List ? j : []);
    final res2 = await safeGet<List<dynamic>>("bookings/reports/top-cancelled-trainers-by-others", parser: (j) => j is List ? j : []);
    final res3 = await safeGet<List<dynamic>>("bookings/reports/top-cancelling-trainers", parser: (j) => j is List ? j : []);

    return ApiResult.success(
      CancellationReportsResult(
        topCancelledMembers: res1.dataOrNull ?? [],
        topCancelledTrainersByOthers: res2.dataOrNull ?? [],
        topCancellingTrainers: res3.dataOrNull ?? [],
      ),
    );
  }

  Future<CancellationReportsResult> getCancellationReports() async {
    final result = await getCancellationReportsResult();
    return result.dataOrNull ??
        CancellationReportsResult(
          topCancelledMembers: [],
          topCancelledTrainersByOthers: [],
          topCancellingTrainers: [],
        );
  }

  Future<ApiResult<Map<String, dynamic>?>> getMonthlyReportResult(int gymId, int month) async {
    return safeGet<Map<String, dynamic>?>(
      "admin/reports/monthly",
      queryParameters: {"gymId": gymId.toString(), "month": month.toString()},
      parser: (json) => json is Map ? Map<String, dynamic>.from(json) : null,
    );
  }

  Future<Map<String, dynamic>?> getMonthlyReport(int gymId, int month) async {
    final result = await getMonthlyReportResult(gymId, month);
    return result.dataOrNull;
  }

  Future<ApiResult<List<dynamic>>> getUnperformedRangeReportResult(int gymId, DateTime start, DateTime end) async {
    String format(DateTime dt) => dt.toIso8601String().split('.').first;
    return safeGet<List<dynamic>>(
      "admin/reports/unperformed-range",
      queryParameters: {
        "gymId": gymId.toString(),
        "start": format(start),
        "end": format(end),
      },
      parser: (json) => json is List ? json : <dynamic>[],
    );
  }

  Future<List<dynamic>> getUnperformedRangeReport(int gymId, DateTime start, DateTime end) async {
    final result = await getUnperformedRangeReportResult(gymId, start, end);
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<List<dynamic>>> getTrainerComplaintsResult(int gymId) async {
    return safeGet<List<dynamic>>(
      "admin/reports/trainer-complaints",
      queryParameters: {"gymId": gymId.toString()},
      parser: (json) => json is List ? json : <dynamic>[],
    );
  }

  Future<List<dynamic>> getTrainerComplaints(int gymId) async {
    final result = await getTrainerComplaintsResult(gymId);
    return result.dataOrNull ?? [];
  }
}
