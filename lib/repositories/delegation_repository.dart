import '../services/api_result.dart';
import 'base_repository.dart';

class DelegationItem {
  final int id;
  final String trainerName;
  final String permission;
  final DateTime startTime;
  final DateTime endTime;

  DelegationItem({
    required this.id,
    required this.trainerName,
    required this.permission,
    required this.startTime,
    required this.endTime,
  });

  factory DelegationItem.fromJson(Map<String, dynamic> json) {
    return DelegationItem(
      id: json['id'],
      trainerName: json['trainer']['fullName'],
      permission: json['permission'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
    );
  }
}

class DelegationRepository extends BaseRepository {
  DelegationRepository({super.client, required super.apiService});

  Future<ApiResult<List<DelegationItem>>> getDelegationsResult(int gymId) async {
    return safeGet<List<DelegationItem>>(
      "delegations/gym/$gymId",
      parser: (json) {
        if (json is List) {
          return json.map((item) => DelegationItem.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <DelegationItem>[];
      },
    );
  }

  Future<List<DelegationItem>> getDelegations(int gymId) async {
    final result = await getDelegationsResult(gymId);
    return result.fold(
      onSuccess: (data) => data,
      onFailure: (msg, code) => throw Exception("Yetki devirleri yüklenemedi: $msg ($code)"),
    );
  }

  Future<ApiResult<bool>> grantPermissionResult({
    required int trainerId,
    required int gymId,
    required String permissionType,
    required DateTime start,
    required DateTime end,
  }) async {
    return safePost<bool>(
      "delegations/grant",
      body: {
        "trainerId": trainerId,
        "gymId": gymId,
        "permissionType": permissionType,
        "startTime": start.toIso8601String(),
        "endTime": end.toIso8601String(),
      },
      parser: (_) => true,
    );
  }

  Future<bool> grantPermission({
    required int trainerId,
    required int gymId,
    required String permissionType,
    required DateTime start,
    required DateTime end,
  }) async {
    final result = await grantPermissionResult(
      trainerId: trainerId,
      gymId: gymId,
      permissionType: permissionType,
      start: start,
      end: end,
    );
    return result.isSuccess;
  }

  Future<ApiResult<bool>> revokePermissionResult(int id) async {
    return safeDelete<bool>("delegations/$id", parser: (_) => true);
  }

  Future<bool> revokePermission(int id) async {
    final result = await revokePermissionResult(id);
    return result.isSuccess;
  }
}
