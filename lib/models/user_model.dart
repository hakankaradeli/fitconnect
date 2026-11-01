class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String gymId;
  final String? phone;
  final String? token;
  final String? refreshToken;
  final String? assignedTrainerId;
  final String? assignedTrainerName;
  final String? assignedLessonType;
  final List<String>? canTeach;
  final bool isActive;
  final bool isDeleted;
  final DateTime? leaveStart;
  final DateTime? leaveEnd;
  final String? profileImageUrl;
  final String? instagram;
  final String? linkedin;
  final String? twitter;
  final String? firstName;
  final String? lastName;
  final DateTime? birthDate;
  final String? gender;

  final DateTime? freezeStart;
  final DateTime? freezeEnd;
  final String? freezeReason;
  final DateTime? createdAt;
  final DateTime? appRegistrationDate;
  final DateTime? gymRegistrationDate;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.gymId,
    this.phone,
    this.token,
    this.refreshToken,
    this.assignedTrainerId,
    this.assignedTrainerName,
    this.assignedLessonType,
    this.canTeach,
    this.isActive = true,
    this.isDeleted = false,
    this.leaveStart,
    this.leaveEnd,
    this.profileImageUrl,
    this.instagram,
    this.linkedin,
    this.twitter,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.gender,
    this.freezeStart,
    this.freezeEnd,
    this.freezeReason,
    this.createdAt,
    this.appRegistrationDate,
    this.gymRegistrationDate,
  });

  DateTime? get effectiveGymRegistrationDate => gymRegistrationDate ?? createdAt;
  DateTime? get effectiveAppRegistrationDate => appRegistrationDate ?? createdAt;

  bool get hasDefinedLeave {
    return leaveStart != null && leaveEnd != null;
  }

  bool get isTrainerOrCanTeach {
    return role == 'TRAINER' || role == 'ADMIN' || role == 'SUPER_ADMIN' || (canTeach != null && canTeach!.isNotEmpty);
  }

  bool get isFrozen {
    return freezeStart != null && freezeEnd != null;
  }

  bool get isCurrentlyFrozen {
    if (freezeStart == null || freezeEnd == null) return false;
    final now = DateTime.now();
    final start = DateTime(freezeStart!.year, freezeStart!.month, freezeStart!.day);
    final end = DateTime(freezeEnd!.year, freezeEnd!.month, freezeEnd!.day, 23, 59);
    return now.isAfter(start.subtract(const Duration(seconds: 1))) &&
           now.isBefore(end.add(const Duration(seconds: 1)));
  }

  bool get isCurrentlyOnLeave {
    if (leaveStart == null || leaveEnd == null) return false;
    final now = DateTime.now();

    final start = DateTime(leaveStart!.year, leaveStart!.month, leaveStart!.day);
    final end = DateTime(leaveEnd!.year, leaveEnd!.month, leaveEnd!.day, 23, 59);
    return now.isAfter(start.subtract(const Duration(seconds: 1))) &&
           now.isBefore(end.add(const Duration(seconds: 1)));
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      fullName: json['fullName'],
      email: json['email'],
      role: json['role'],
      gymId: json['gym'] != null ? json['gym']['id'].toString() : (json['gymId']?.toString() ?? ""),
      phone: json['phone'],
      token: json['token'],
      refreshToken: json['refreshToken'],
      assignedTrainerId: json['assignedTrainer'] != null ? json['assignedTrainer']['id'].toString() : null,
      assignedTrainerName: json['assignedTrainer'] != null ? json['assignedTrainer']['fullName'] : null,
      assignedLessonType: json['assignedLessonType'],
      canTeach: json['canTeach'] != null ? List<String>.from(json['canTeach']) : null,
      isActive: json['isActive'] ?? true,
      isDeleted: json['isDeleted'] ?? false,
      leaveStart: _parseDateTime(json['leaveStart']),
      leaveEnd: _parseDateTime(json['leaveEnd']),
      profileImageUrl: json['profileImageUrl'],
      instagram: json['instagram'],
      linkedin: json['linkedin'],
      twitter: json['twitter'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      birthDate: _parseDateTime(json['birthDate']),
      gender: json['gender'],
      freezeStart: _parseDateTime(json['freezeStart']),
      freezeEnd: _parseDateTime(json['freezeEnd']),
      freezeReason: json['freezeReason'],
      createdAt: _parseDateTime(json['createdAt']),
      appRegistrationDate: _parseDateTime(json['appRegistrationDate']),
      gymRegistrationDate: _parseDateTime(json['gymRegistrationDate']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is List && value.isNotEmpty) {
      final y = value.isNotEmpty ? (value[0] as num).toInt() : 2026;
      final m = value.length > 1 ? (value[1] as num).toInt() : 1;
      final d = value.length > 2 ? (value[2] as num).toInt() : 1;
      final h = value.length > 3 ? (value[3] as num).toInt() : 0;
      final min = value.length > 4 ? (value[4] as num).toInt() : 0;
      final s = value.length > 5 ? (value[5] as num).toInt() : 0;
      return DateTime(y, m, d, h, min, s);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return DateTime.tryParse(value.toString());
  }
}
