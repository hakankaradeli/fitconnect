import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

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
}

class DelegationViewModel extends ChangeNotifier {
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
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/delegations/gym/$gymId"),
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _delegations = data.map((json) => Delegation.fromJson(json)).toList();
      }
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
      final response = await http.post(
        Uri.parse("${ApiService.baseUrl}/delegations/grant"),
        headers: ApiService.getHeaders(),
        body: jsonEncode({
          "trainerId": trainerId,
          "gymId": gymId,
          "permissionType": permissionType,
          "startTime": start.toIso8601String(),
          "endTime": end.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
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
      final response = await http.delete(
        Uri.parse("${ApiService.baseUrl}/delegations/$id"),
        headers: ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        fetchDelegations(gymId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
