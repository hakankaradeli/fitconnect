import 'package:flutter/material.dart';
import '../models/gym_branding_model.dart';

class ThemeViewModel extends ChangeNotifier {
  // Varsayılan Tema (Giriş yapılmadan önce)
  Color _primaryColor = Colors.blue;
  String? _gymLogo; // Null olabilir
  String _gymName = "Gym Management";

  Color get primaryColor => _primaryColor;
  String? get gymLogo => _gymLogo;
  String get gymName => _gymName;

  // Giriş yapıldığında salon bilgilerine göre temayı güncelle
  void updateBranding(GymBrandingModel branding) {
    _primaryColor = Color(branding.getColorFromHex());
    _gymLogo = branding.logoUrl;
    _gymName = branding.gymName;
    
    notifyListeners(); // Tüm uygulama arayüzünü yeniden çizdirir
  }

  // Dinamik ThemeData üretici
  ThemeData get currentTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
