import '../services/api_result.dart';
import 'base_repository.dart';

class SurveyRepository extends BaseRepository {
  SurveyRepository({super.client, required super.apiService});

  Future<ApiResult<bool>> submitSurveyResult({
    int? bookingId,
    int? trainerId,
    int? memberId,
    required double rating,
    String? comment,
  }) async {
    final body = {
      if (bookingId != null) "bookingId": bookingId,
      if (trainerId != null) "trainerId": trainerId,
      if (memberId != null) "memberId": memberId,
      "rating": rating.round(),
      if (comment != null && comment.isNotEmpty) "comment": comment,
    };
    return safePost<bool>("surveys", body: body, parser: (_) => true);
  }

  Future<bool> submitSurvey({
    int? bookingId,
    int? trainerId,
    int? memberId,
    required double rating,
    String? comment,
  }) async {
    final result = await submitSurveyResult(
      bookingId: bookingId,
      trainerId: trainerId,
      memberId: memberId,
      rating: rating,
      comment: comment,
    );
    return result.isSuccess;
  }
}
