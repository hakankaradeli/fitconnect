import '../models/announcement_model.dart';
import '../services/api_result.dart';
import 'base_repository.dart';

class AnnouncementRepository extends BaseRepository {
  AnnouncementRepository({super.client, required super.apiService});

  Future<ApiResult<List<AnnouncementModel>>> getAnnouncementsResult(int gymId) async {
    return safeGet<List<AnnouncementModel>>(
      "announcements/gym/$gymId",
      parser: (json) {
        if (json is List) {
          return json.map((item) => AnnouncementModel.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <AnnouncementModel>[];
      },
    );
  }

  Future<List<AnnouncementModel>> getAnnouncements(int gymId) async {
    final result = await getAnnouncementsResult(gymId);
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<bool>> createAnnouncementResult({
    required int gymId,
    required String title,
    required String content,
    String? imageUrl,
    String targetRole = "ALL",
  }) async {
    return safePost<bool>(
      "announcements/create",
      body: {
        "gymId": gymId,
        "title": title,
        "content": content,
        "imageUrl": imageUrl,
        "targetRole": targetRole,
      },
      parser: (_) => true,
    );
  }

  Future<bool> createAnnouncement({
    required int gymId,
    required String title,
    required String content,
    String? imageUrl,
    String targetRole = "ALL",
  }) async {
    final result = await createAnnouncementResult(
      gymId: gymId,
      title: title,
      content: content,
      imageUrl: imageUrl,
      targetRole: targetRole,
    );
    return result.isSuccess;
  }

  Future<ApiResult<bool>> deleteAnnouncementResult(int id) async {
    return safeDelete<bool>("announcements/$id", parser: (_) => true);
  }

  Future<bool> deleteAnnouncement(int id) async {
    final result = await deleteAnnouncementResult(id);
    return result.isSuccess;
  }
}
