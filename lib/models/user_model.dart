class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role; // ADMIN, TRAINER, MEMBER
  final String gymId;
  final String? phone;
  final String? token;
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

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.gymId,
    this.phone,
    this.token,
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
  });

  bool get hasDefinedLeave {
    return leaveStart != null && leaveEnd != null;
  }

  bool get isCurrentlyOnLeave {
    if (leaveStart == null || leaveEnd == null) return false;
    final now = DateTime.now();
    // Günü kapsayıp kapsamadığını kontrol et (Saat farklarını tolere etmek için)
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
      assignedTrainerId: json['assignedTrainer'] != null ? json['assignedTrainer']['id'].toString() : null,
      assignedTrainerName: json['assignedTrainer'] != null ? json['assignedTrainer']['fullName'] : null,
      assignedLessonType: json['assignedLessonType'],
      canTeach: json['canTeach'] != null ? List<String>.from(json['canTeach']) : null,
      isActive: json['isActive'] ?? true,
      isDeleted: json['isDeleted'] ?? false,
      leaveStart: json['leaveStart'] != null ? DateTime.parse(json['leaveStart']) : null,
      leaveEnd: json['leaveEnd'] != null ? DateTime.parse(json['leaveEnd']) : null,
      profileImageUrl: json['profileImageUrl'],
      instagram: json['instagram'],
      linkedin: json['linkedin'],
      twitter: json['twitter'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      gender: json['gender'],
    );
  }
}
