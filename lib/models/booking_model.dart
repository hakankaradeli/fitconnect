class BookingSlot {
  final DateTime dateTime;
  int currentParticipants;
  final int maxCapacity = 4;

  BookingSlot({required this.dateTime, this.currentParticipants = 0});

  bool get isFull => currentParticipants >= maxCapacity;
}
