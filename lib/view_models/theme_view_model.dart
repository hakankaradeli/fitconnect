import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/gym_repository.dart';
import '../models/gym_branding_model.dart';

class ThemeViewModel extends ChangeNotifier {
  final GymRepository _gymRepository;

  ThemeViewModel({required GymRepository gymRepository})
      : _gymRepository = gymRepository {
    _loadTheme();
  }

  Color _primaryColor = const Color(0xFF3F51B5);
  Color _secondaryColor = const Color(0xFF5C6BC0);
  bool _isGradient = false;
  String? _gymLogo;
  String _gymName = "PtFitConnect";
  GymBrandingModel? _branding;

  String _address = "";
  String _phone = "";
  String _email = "";
  String _instagram = "";
  String _website = "";

  String _workingDays = "Pazartesi,Salı,Çarşamba,Perşembe,Cuma,Cumartesi,Pazar";
  String _openTime = "07:00";
  String _closeTime = "22:00";
  int _maxCancellationsAllowed = 3;

  List<String> _offeredLessonGroups = ["PT", "Pilates", "Kickboks", "Yoga"];

  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  bool get isGradient => _isGradient;
  String? get gymLogo => _gymLogo;
  String get gymName => _gymName;
  GymBrandingModel? get branding => _branding;

  String get address => _address;
  String get phone => _phone;
  String get email => _email;
  String get instagram => _instagram;
  String get website => _website;

  String get workingDays => _workingDays;
  String get openTime => _openTime;
  String get closeTime => _closeTime;
  int get maxCancellationsAllowed => _maxCancellationsAllowed;
  List<String> get offeredLessonGroups => _offeredLessonGroups;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrimary = prefs.getInt('primary_color');
    final savedSecondary = prefs.getInt('secondary_color');
    final savedIsGradient = prefs.getBool('is_gradient');
    final savedLogo = prefs.getString('gym_logo');
    final savedName = prefs.getString('gym_name');

    if (savedPrimary != null) {
      _primaryColor = Color(savedPrimary);
    }
    if (savedSecondary != null) {
      _secondaryColor = Color(savedSecondary);
    }
    if (savedIsGradient != null) {
      _isGradient = savedIsGradient;
    }
    if (savedLogo != null) {
      _gymLogo = savedLogo;
    }
    if (savedName != null) {
      _gymName = savedName;
    }
    notifyListeners();
  }

  Future<void> syncGymBranding(int gymId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIsGradient = prefs.getBool('gym_${gymId}_is_gradient');
      final savedSecondary = prefs.getString('gym_${gymId}_secondary_color');
      final savedGroups = prefs.getStringList('gym_${gymId}_offered_lesson_groups');
      final savedOpenTime = prefs.getString('gym_${gymId}_open_time');
      final savedCloseTime = prefs.getString('gym_${gymId}_close_time');

      final data = await _gymRepository.getBranding(gymId);
      if (data != null) {
        final primHex = data['primaryColor'] ?? "#3F51B5";
        final secHex = data['secondaryColor'] ?? savedSecondary ?? (ThemeGradientPreset.findByHex(primHex)?.endHex ?? primHex);
        final isGrad = data['isGradient'] == true || (savedIsGradient == true);
        final effectiveOpen = data['openTime'] ?? savedOpenTime ?? "07:00";
        final effectiveClose = data['closeTime'] ?? savedCloseTime ?? "22:00";

        if (data['openTime'] != null) {
          await prefs.setString('gym_${gymId}_open_time', data['openTime']);
        }
        if (data['closeTime'] != null) {
          await prefs.setString('gym_${gymId}_close_time', data['closeTime']);
        }
        await prefs.setBool('gym_${gymId}_is_gradient', isGrad);
        await prefs.setString('gym_${gymId}_secondary_color', secHex);

        List<String> groups;
        if (data['offeredLessonGroups'] != null && data['offeredLessonGroups'].toString().trim().isNotEmpty) {
          groups = data['offeredLessonGroups'].toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          await prefs.setStringList('gym_${gymId}_offered_lesson_groups', groups);
        } else if (savedGroups != null && savedGroups.isNotEmpty) {
          groups = savedGroups;
        } else {
          groups = const ["PT", "Pilates", "Kickboks", "Yoga"];
        }

        final branding = GymBrandingModel(
          gymId: gymId.toString(),
          gymName: data['gymName'] ?? "PtFitConnect",
          logoUrl: data['logoUrl'] ?? "",
          primaryColorHex: primHex,
          secondaryColorHex: secHex,
          isGradient: isGrad,
          offeredLessonGroups: groups,
          workingDays: data['workingDays'] ?? "Pazartesi,Salı,Çarşamba,Perşembe,Cuma,Cumartesi,Pazar",
          openTime: effectiveOpen,
          closeTime: effectiveClose,
          maxCancellationsAllowed: data['maxCancellationsAllowed'] ?? 3,
          address: data['address'] ?? "",
          phone: data['phone'] ?? "",
          email: data['email'] ?? "",
          instagram: data['instagram'] ?? "",
          website: data['website'] ?? "",
        );
        applyBranding(branding);
      } else {
        if (savedOpenTime != null) _openTime = savedOpenTime;
        if (savedCloseTime != null) _closeTime = savedCloseTime;
        if (savedIsGradient != null) _isGradient = savedIsGradient;
        if (savedSecondary != null) _secondaryColor = parseHexColor(savedSecondary);
        if (savedGroups != null && savedGroups.isNotEmpty) {
          _offeredLessonGroups = savedGroups;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Sync gym branding error: $e");
    }
  }

  Future<void> fetchGymBranding(int gymId) => syncGymBranding(gymId);

  void applyBranding(GymBrandingModel branding) {
    _branding = branding;
    _gymName = branding.gymName;
    _primaryColor = parseHexColor(branding.primaryColorHex);

    if (branding.secondaryColorHex.isNotEmpty) {
      _secondaryColor = parseHexColor(branding.secondaryColorHex);
    } else {
      final preset = ThemeGradientPreset.findByHex(branding.primaryColorHex);
      _secondaryColor = preset != null ? parseHexColor(preset.endHex) : _primaryColor;
    }

    _isGradient = branding.isGradient;
    _gymLogo = branding.logoUrl.isNotEmpty ? branding.logoUrl : null;

    _address = branding.address ?? "";
    _phone = branding.phone ?? "";
    _email = branding.email ?? "";
    _instagram = branding.instagram ?? "";
    _website = branding.website ?? "";

    _workingDays = branding.workingDays;
    _openTime = branding.openTime;
    _closeTime = branding.closeTime;
    _maxCancellationsAllowed = branding.maxCancellationsAllowed;
    _offeredLessonGroups = branding.offeredLessonGroups;

    notifyListeners();
  }

  void updateBranding(GymBrandingModel branding) => applyBranding(branding);

  Future<bool> updateGymBranding(
    int gymId, {
    String? gymName,
    String? address,
    String? phone,
    String? email,
    String? instagram,
    String? website,
    String? primaryColorHex,
    String? secondaryColorHex,
    bool? isGradient,
    String? logoUrl,
    List<String>? offeredLessonGroups,
  }) async {
    try {
      final Map<String, dynamic> body = {
        if (gymName != null && gymName.trim().isNotEmpty) "gymName": gymName.trim(),
        if (address != null) "address": address.trim(),
        if (phone != null) "phone": phone.trim(),
        if (email != null) "email": email.trim(),
        if (instagram != null) "instagram": instagram.trim(),
        if (website != null) "website": website.trim(),
        if (primaryColorHex != null && primaryColorHex.isNotEmpty) "primaryColor": primaryColorHex,
        if (secondaryColorHex != null && secondaryColorHex.isNotEmpty) "secondaryColor": secondaryColorHex,
        if (isGradient != null) "isGradient": isGradient,
        if (logoUrl != null && logoUrl.isNotEmpty) "logoUrl": logoUrl,
        if (offeredLessonGroups != null) "offeredLessonGroups": offeredLessonGroups.join(","),
      };

      final success = await _gymRepository.updateBranding(gymId, body);

      if (success) {
        if (gymName != null && gymName.trim().isNotEmpty) _gymName = gymName.trim();
        if (address != null) _address = address.trim();
        if (phone != null) _phone = phone.trim();
        if (email != null) _email = email.trim();
        if (instagram != null) _instagram = instagram.trim();
        if (website != null) _website = website.trim();
        if (primaryColorHex != null && primaryColorHex.isNotEmpty) {
          _primaryColor = parseHexColor(primaryColorHex);
        }
        if (secondaryColorHex != null && secondaryColorHex.isNotEmpty) {
          _secondaryColor = parseHexColor(secondaryColorHex);
        } else if (primaryColorHex != null) {
          _secondaryColor = _primaryColor;
        }
        if (isGradient != null) {
          _isGradient = isGradient;
        }
        if (logoUrl != null) {
          _gymLogo = logoUrl;
        }

        _branding = GymBrandingModel(
          gymId: gymId.toString(),
          gymName: _gymName,
          logoUrl: _gymLogo ?? '',
          primaryColorHex: primaryColorHex ?? _primaryColor.value.toRadixString(16),
          secondaryColorHex: secondaryColorHex ?? _secondaryColor.value.toRadixString(16),
          isGradient: _isGradient,
          offeredLessonGroups: _offeredLessonGroups,
          workingDays: _workingDays,
          openTime: _openTime,
          closeTime: _closeTime,
          maxCancellationsAllowed: _maxCancellationsAllowed,
          address: _address,
          phone: _phone,
          email: _email,
          instagram: _instagram,
          website: _website,
        );

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Update gym branding error: $e");
      return false;
    }
  }

  Future<bool> updateWorkingHours(int gymId, String days, String oTime, String cTime, int maxCancellations) async {
    try {
      final success = await _gymRepository.updateWorkingHours(gymId, days, oTime, cTime, maxCancellations);

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('gym_${gymId}_open_time', oTime);
        await prefs.setString('gym_${gymId}_close_time', cTime);

        _workingDays = days;
        _openTime = oTime;
        _closeTime = cTime;
        _maxCancellationsAllowed = maxCancellations;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Update working hours error: $e");
      return false;
    }
  }

  Color parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return const Color(0xFF3F51B5);
    }
  }

  static Color getContrastColor(Color background) {
    return background.computeLuminance() > 0.45 ? const Color(0xFF1E293B) : Colors.white;
  }

  Color get onPrimaryColor => getContrastColor(_primaryColor);

  Color get onSecondaryColor => getContrastColor(_secondaryColor);

  ThemeData get currentTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        primary: _primaryColor,
        secondary: _secondaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Color(0xFF1E293B)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
