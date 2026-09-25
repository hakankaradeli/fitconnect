class LeaveRecordModel {
  final int id;
  final DateTime startDate;
  final DateTime endDate;
  final String? replacementTrainerName;
  final String status;
  final DateTime createdAt;

  LeaveRecordModel({
    required this.id,
    required this.startDate,
    required this.endDate,
    this.replacementTrainerName,
    required this.status,
    required this.createdAt,
  });

  factory LeaveRecordModel.fromJson(Map<String, dynamic> json) {
    return LeaveRecordModel(
      id: json['id'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      replacementTrainerName: json['replacementTrainer'] != null ? json['replacementTrainer']['fullName'] : null,
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
