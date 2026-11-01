class PerformedExercise {
  final int? id;
  final String exerciseName;
  final String? muscleGroup;
  final int? sets;
  final int? reps;
  final String? weight;
  final String? notes;

  PerformedExercise({
    this.id,
    required this.exerciseName,
    this.muscleGroup,
    this.sets,
    this.reps,
    this.weight,
    this.notes,
  });

  factory PerformedExercise.fromJson(Map<String, dynamic> json) {
    return PerformedExercise(
      id: json['id'],
      exerciseName: json['exerciseName'] ?? '',
      muscleGroup: json['muscleGroup'],
      sets: json['sets'],
      reps: json['reps'],
      weight: json['weight'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'muscleGroup': muscleGroup,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'notes': notes,
    };
  }
}

class BookingDetails {
  final int id;
  final String memberName;
  final String trainerName;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final List<PerformedExercise> performedExercises;
  final int? trainerId;
  final int? memberId;
  final String? trainerPhone;
  final String? memberPhone;

  BookingDetails({
    required this.id,
    required this.memberName,
    required this.trainerName,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.performedExercises = const [],
    this.trainerId,
    this.memberId,
    this.trainerPhone,
    this.memberPhone,
  });

  factory BookingDetails.fromJson(Map<String, dynamic> json) {
    var list = json['performedExercises'] as List?;
    List<PerformedExercise> exercises = list != null 
        ? list.map((i) => PerformedExercise.fromJson(i)).toList() 
        : [];

    final memberMap = json['member'];
    final trainerMap = json['trainer'];

    return BookingDetails(
      id: json['id'],
      memberName: memberMap is Map ? (memberMap['fullName'] ?? '') : (json['memberName'] ?? ''),
      trainerName: trainerMap is Map ? (trainerMap['fullName'] ?? '') : (json['trainerName'] ?? ''),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: json['status'] ?? 'ACTIVE',
      performedExercises: exercises,
      trainerId: trainerMap is Map ? (trainerMap['id'] is int ? trainerMap['id'] : int.tryParse(trainerMap['id']?.toString() ?? '')) : null,
      memberId: memberMap is Map ? (memberMap['id'] is int ? memberMap['id'] : int.tryParse(memberMap['id']?.toString() ?? '')) : null,
      trainerPhone: trainerMap is Map ? trainerMap['phone'] : null,
      memberPhone: memberMap is Map ? memberMap['phone'] : null,
    );
  }

  String get statusText {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return "Onay Bekliyor";
      case 'PENDING_ADMIN_APPROVAL':
        return "Yönetici Onayı Bekliyor";
      case 'ACTIVE':
        return "Aktif";
      case 'PROPOSED':
        return "Öneri Gönderildi";
      case 'COMPLETED':
        return "Tamamlandı";
      case 'CANCELLED':
        return "İptal Edildi";
      case 'NO_SHOW':
        return "Üye Derse Katılmadı";
      default:
        return status;
    }
  }
}
