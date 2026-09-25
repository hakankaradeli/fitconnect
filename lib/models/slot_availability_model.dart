class SlotAvailability {
  final DateTime startTime;
  final bool isAvailable;
  final String? reason;
  final int currentParticipants;

  SlotAvailability({
    required this.startTime,
    required this.isAvailable,
    this.reason,
    this.currentParticipants = 0,
  });

  factory SlotAvailability.fromJson(Map<String, dynamic> json) {
    return SlotAvailability(
      startTime: DateTime.parse(json['startTime']),
      isAvailable: json['isAvailable'],
      reason: json['reason'],
      currentParticipants: json['currentParticipants'] ?? 0,
    );
  }
}
