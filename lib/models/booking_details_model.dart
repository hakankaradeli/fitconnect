class PerformedExercise {
  final int? id;
  final String exerciseName;
  final int? sets;
  final int? reps;
  final String? weight;
  final String? notes;

  PerformedExercise({
    this.id,
    required this.exerciseName,
    this.sets,
    this.reps,
    this.weight,
    this.notes,
  });

  factory PerformedExercise.fromJson(Map<String, dynamic> json) {
    return PerformedExercise(
      id: json['id'],
      exerciseName: json['exerciseName'],
      sets: json['sets'],
      reps: json['reps'],
      weight: json['weight'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
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

  BookingDetails({
    required this.id,
    required this.memberName,
    required this.trainerName,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.performedExercises = const [],
  });

  factory BookingDetails.fromJson(Map<String, dynamic> json) {
    var list = json['performedExercises'] as List?;
    List<PerformedExercise> exercises = list != null 
        ? list.map((i) => PerformedExercise.fromJson(i)).toList() 
        : [];

    return BookingDetails(
      id: json['id'],
      memberName: json['member']['fullName'],
      trainerName: json['trainer']['fullName'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: json['status'],
      performedExercises: exercises,
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
