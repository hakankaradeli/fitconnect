class BookingSlot {
  final DateTime dateTime;
  int currentParticipants;
  final int maxCapacity = 4; // PRD: Salon kapasite kısıtı

  BookingSlot({required this.dateTime, this.currentParticipants = 0});

  bool get isFull => currentParticipants >= maxCapacity;
}
