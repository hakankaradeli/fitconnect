import 'package:flutter/material.dart';
import '../models/accrual_model.dart';

class AccrualViewModel extends ChangeNotifier {
  // Eğitmenin bekleyen hakediş listesi
  List<AccrualEntry> _pendingAccruals = [];
  
  // Yönetici tarafından belirlenen saatlik ücret tarifesi (Örn: TL bazında)
  final Map<LessonType, double> _rates = {
    LessonType.pt1to1: 250.0,
    LessonType.ptDuo: 150.0, // Kişi başı veya toplam hakediş
    LessonType.reformerGroup: 100.0,
  };

  List<AccrualEntry> get pendingAccruals => _pendingAccruals;

  double get totalBalance => _pendingAccruals.fold(0, (sum, item) => sum + item.amount);

  // Ders tamamlandığında (QR okunduğunda) hakediş ekle
  void addLessonAccrual(String memberName, LessonType type) {
    final entry = AccrualEntry(
      id: DateTime.now().toString(),
      date: DateTime.now(),
      memberName: memberName,
      lessonType: type,
      amount: _rates[type] ?? 0.0,
    );
    _pendingAccruals.add(entry);
    notifyListeners();
  }

  // PRD Madde 6: Yönetici 'Ödeme Yapıldı' dediğinde sıfırlama
  Future<void> processPayment() async {
    // 1. Backend'e 'Bu kayıtları arşive taşı' isteği gönderilir
    await Future.delayed(const Duration(seconds: 1)); // Simülasyon
    
    // 2. Yerel listeyi temizle
    _pendingAccruals.clear();
    notifyListeners();
  }
}
