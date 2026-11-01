import 'package:http/http.dart' as http;
import '../models/booking_details_model.dart';
import '../models/slot_availability_model.dart';
import '../models/user_model.dart';
import '../services/api_result.dart';
import 'base_repository.dart';

class BookingRepository extends BaseRepository {
  BookingRepository({super.client, required super.apiService});

  String _formatDateTime(DateTime dt) => dt.toIso8601String().split('.').first;

  Future<ApiResult<List<UserModel>>> getAvailableTrainersResult(int gymId, DateTime startTime) async {
    return safeGet<List<UserModel>>(
      "bookings/available-trainers",
      queryParameters: {
        "gymId": gymId.toString(),
        "startTime": _formatDateTime(startTime),
      },
      parser: (json) {
        if (json is List) {
          return json.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <UserModel>[];
      },
    );
  }

  Future<List<UserModel>> getAvailableTrainers(int gymId, DateTime startTime) async {
    final result = await getAvailableTrainersResult(gymId, startTime);
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<List<SlotAvailability>>> getAvailableSlotsResult(int trainerId, int gymId, DateTime date) async {
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return safeGet<List<SlotAvailability>>(
      "bookings/available-slots",
      queryParameters: {
        "trainerId": trainerId.toString(),
        "gymId": gymId.toString(),
        "date": dateStr,
      },
      parser: (json) {
        if (json is List) {
          return json.map((item) => SlotAvailability.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <SlotAvailability>[];
      },
    );
  }

  Future<List<SlotAvailability>> getAvailableSlots(int trainerId, int gymId, DateTime date) async {
    final result = await getAvailableSlotsResult(trainerId, gymId, date);
    return result.dataOrNull ?? [];
  }

  Future<http.Response> createBulkBookings({
    required int memberId,
    required int trainerId,
    required int gymId,
    required List<DateTime> startTimes,
  }) async {
    return await post(
      "bookings/create-bulk",
      body: {
        "memberId": memberId,
        "trainerId": trainerId,
        "gymId": gymId,
        "startTimes": startTimes.map((t) => t.toIso8601String()).toList(),
      },
    );
  }

  Future<http.Response> createBooking({
    required int memberId,
    required int trainerId,
    required int gymId,
    required DateTime startTime,
  }) async {
    return await post(
      "bookings/create",
      body: {
        "memberId": memberId,
        "trainerId": trainerId,
        "gymId": gymId,
        "startTime": startTime.toIso8601String(),
      },
    );
  }

  Future<ApiResult<List<BookingDetails>>> getMemberHistoryResult(int memberId) async {
    return safeGet<List<BookingDetails>>(
      "bookings/member-history/$memberId",
      parser: (json) {
        if (json is List) {
          return json.map((item) => BookingDetails.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <BookingDetails>[];
      },
    );
  }

  Future<List<BookingDetails>> getMemberHistory(int memberId) async {
    final result = await getMemberHistoryResult(memberId);
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<bool>> refundBookingResult(int bookingId) async {
    return safePut<bool>("bookings/refund/$bookingId", parser: (_) => true);
  }

  Future<bool> refundBooking(int bookingId) async {
    final result = await refundBookingResult(bookingId);
    return result.isSuccess;
  }

  Future<ApiResult<bool>> approveBookingResult(int bookingId) async {
    return safePut<bool>("bookings/approve/$bookingId", parser: (_) => true);
  }

  Future<bool> approveBooking(int bookingId) async {
    final result = await approveBookingResult(bookingId);
    return result.isSuccess;
  }

  Future<ApiResult<bool>> rejectBookingResult(int bookingId, {int? cancelledById, String? reason, bool? isDirectCancel}) async {
    final queryParams = {
      if (cancelledById != null) "cancelledById": cancelledById.toString(),
      if (reason != null && reason.isNotEmpty) "reason": reason,
      if (isDirectCancel != null) "isDirectCancel": isDirectCancel.toString(),
    };
    return safePut<bool>("bookings/reject/$bookingId", queryParameters: queryParams, parser: (_) => true);
  }

  Future<bool> rejectBooking(int bookingId, {int? cancelledById, String? reason, bool? isDirectCancel}) async {
    final result = await rejectBookingResult(bookingId, cancelledById: cancelledById, reason: reason, isDirectCancel: isDirectCancel);
    return result.isSuccess;
  }

  Future<ApiResult<bool>> proposeChangeResult(int bookingId, DateTime newTime) async {
    return safePut<bool>(
      "bookings/propose/$bookingId",
      queryParameters: {"newStartTime": newTime.toIso8601String()},
      parser: (_) => true,
    );
  }

  Future<bool> proposeChange(int bookingId, DateTime newTime) async {
    final result = await proposeChangeResult(bookingId, newTime);
    return result.isSuccess;
  }

  Future<ApiResult<bool>> changeTrainerResult(int bookingId, int newTrainerId) async {
    return safePut<bool>(
      "bookings/change-trainer/$bookingId",
      queryParameters: {"newTrainerId": newTrainerId.toString()},
      parser: (_) => true,
    );
  }

  Future<bool> changeTrainer(int bookingId, int newTrainerId) async {
    final result = await changeTrainerResult(bookingId, newTrainerId);
    return result.isSuccess;
  }

  Future<ApiResult<bool>> addPerformedExercisesResult(int bookingId, List<PerformedExercise> exercises) async {
    return safePost<bool>(
      "bookings/$bookingId/exercises",
      body: exercises.map((e) => e.toJson()).toList(),
      parser: (_) => true,
    );
  }

  Future<bool> addPerformedExercises(int bookingId, List<PerformedExercise> exercises) async {
    final result = await addPerformedExercisesResult(bookingId, exercises);
    return result.isSuccess;
  }

  Future<ApiResult<List<BookingDetails>>> getAdminPendingBookingsResult(int gymId) async {
    return safeGet<List<BookingDetails>>(
      "bookings/admin-pending/$gymId",
      parser: (json) {
        if (json is List) {
          return json.map((item) => BookingDetails.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <BookingDetails>[];
      },
    );
  }

  Future<List<BookingDetails>> getAdminPendingBookings(int gymId) async {
    final result = await getAdminPendingBookingsResult(gymId);
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<List<BookingDetails>>> getTrainerPendingApprovalsResult(int trainerId) async {
    return safeGet<List<BookingDetails>>(
      "bookings/trainer-pending/$trainerId",
      parser: (json) {
        if (json is List) {
          return json.map((item) => BookingDetails.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <BookingDetails>[];
      },
    );
  }

  Future<List<BookingDetails>> getTrainerPendingApprovals(int trainerId) async {
    final result = await getTrainerPendingApprovalsResult(trainerId);
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<bool>> trainerApproveResult(int bookingId) async {
    return safePut<bool>("bookings/trainer-approve/$bookingId", parser: (_) => true);
  }

  Future<bool> trainerApprove(int bookingId) async {
    final result = await trainerApproveResult(bookingId);
    return result.isSuccess;
  }

  Future<ApiResult<bool>> trainerRejectResult(int bookingId, {bool? isDirectCancel, String? reason}) async {
    final queryParams = {
      if (isDirectCancel != null) "isDirectCancel": isDirectCancel.toString(),
      if (reason != null && reason.isNotEmpty) "reason": reason,
    };
    return safePut<bool>("bookings/trainer-reject/$bookingId", queryParameters: queryParams, parser: (_) => true);
  }

  Future<bool> trainerReject(int bookingId, {bool? isDirectCancel, String? reason}) async {
    final result = await trainerRejectResult(bookingId, isDirectCancel: isDirectCancel, reason: reason);
    return result.isSuccess;
  }

  Future<ApiResult<List<BookingDetails>>> getTrainerScheduleResult(int trainerId, DateTime start, DateTime end) async {
    return safeGet<List<BookingDetails>>(
      "bookings/trainer-schedule/$trainerId",
      queryParameters: {
        "start": _formatDateTime(start),
        "end": _formatDateTime(end),
      },
      parser: (json) {
        if (json is List) {
          return json.map((item) => BookingDetails.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <BookingDetails>[];
      },
    );
  }

  Future<List<BookingDetails>> getTrainerSchedule(int trainerId, DateTime start, DateTime end) async {
    final result = await getTrainerScheduleResult(trainerId, start, end);
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<List<BookingDetails>>> getGymScheduleResult(int gymId, DateTime start, DateTime end) async {
    return safeGet<List<BookingDetails>>(
      "bookings/gym-schedule/$gymId",
      queryParameters: {
        "start": _formatDateTime(start),
        "end": _formatDateTime(end),
      },
      parser: (json) {
        if (json is List) {
          return json.map((item) => BookingDetails.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <BookingDetails>[];
      },
    );
  }

  Future<List<BookingDetails>> getGymSchedule(int gymId, DateTime start, DateTime end) async {
    final result = await getGymScheduleResult(gymId, start, end);
    return result.dataOrNull ?? [];
  }

  Future<ApiResult<Map<String, dynamic>?>> startDirectLessonResult(int trainerId, int memberId, String? lessonType) async {
    final queryParams = {
      "trainerId": trainerId.toString(),
      "memberId": memberId.toString(),
      if (lessonType != null && lessonType.isNotEmpty) "lessonType": lessonType,
    };
    return safePost<Map<String, dynamic>?>(
      "lessons/start-direct",
      queryParameters: queryParams,
      parser: (json) => json is Map ? Map<String, dynamic>.from(json) : null,
    );
  }

  Future<Map<String, dynamic>?> startDirectLesson(int trainerId, int memberId, String? lessonType) async {
    final result = await startDirectLessonResult(trainerId, memberId, lessonType);
    return result.dataOrNull;
  }

  Future<ApiResult<Map<String, dynamic>?>> checkBookingStatusResult(int bookingId) async {
    return safeGet<Map<String, dynamic>?>(
      "bookings/$bookingId",
      parser: (json) => json is Map ? Map<String, dynamic>.from(json) : null,
    );
  }

  Future<Map<String, dynamic>?> checkBookingStatus(int bookingId) async {
    final result = await checkBookingStatusResult(bookingId);
    return result.dataOrNull;
  }

  Future<ApiResult<Map<String, dynamic>?>> checkDirectLessonStatusResult(String trainerId, int since) async {
    return safeGet<Map<String, dynamic>?>(
      "lessons/latest-completed",
      queryParameters: {
        "trainerId": trainerId,
        "since": since.toString(),
      },
      parser: (json) => json is Map ? Map<String, dynamic>.from(json) : null,
    );
  }

  Future<Map<String, dynamic>?> checkDirectLessonStatus(String trainerId, int since) async {
    final result = await checkDirectLessonStatusResult(trainerId, since);
    return result.dataOrNull;
  }

  Future<http.Response> verifyQrLesson({int? bookingId, required String trainerId, int? memberId}) async {
    final queryParams = {
      "trainerId": trainerId,
      if (bookingId != null && bookingId > 0) "bookingId": bookingId.toString(),
      if (memberId != null && (bookingId == null || bookingId <= 0)) "memberId": memberId.toString(),
    };
    return await post("lessons/verify-qr", queryParameters: queryParams);
  }
}
