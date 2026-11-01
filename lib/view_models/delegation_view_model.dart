import 'package:flutter/material.dart';
import '../repositories/delegation_repository.dart';

class Delegation {
  final int id;
  final String trainerName;
  final String permission;
  final DateTime startTime;
  final DateTime endTime;

  Delegation({
    required this.id,
    required this.trainerName,
    required this.permission,
    required this.startTime,
    required this.endTime,
  });

  factory Delegation.fromJson(Map<String, dynamic> json) {
    return Delegation(
      id: json['id'],
      trainerName: json['trainer']['fullName'],
      permission: json['permission'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
    );
  }

  factory Delegation.fromItem(DelegationItem item) {
    return Delegation(
      id: item.id,
      trainerName: item.trainerName,
      permission: item.permission,
      startTime: item.startTime,
      endTime: item.endTime,
    );
  }
}

class DelegationViewModel extends ChangeNotifier {
  final DelegationRepository _repository;

  DelegationViewModel({required DelegationRepository repository})
      : _repository = repository;

  List<Delegation> _delegations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Delegation> get delegations => _delegations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDelegations(int gymId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final items = await _repository.getDelegations(gymId);
      _delegations = items.map((i) => Delegation.fromItem(i)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> grantPermission({
    required int trainerId,
    required int gymId,
    required String permissionType,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final success = await _repository.grantPermission(
        trainerId: trainerId,
        gymId: gymId,
        permissionType: permissionType,
        start: start,
        end: end,
      );

      if (success) {
        fetchDelegations(gymId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> revokePermission(int id, int gymId) async {
    try {
      final success = await _repository.revokePermission(id);
      if (success) {
        fetchDelegations(gymId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
