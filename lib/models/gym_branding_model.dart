import 'package:flutter/material.dart';

class ThemeGradientPreset {
  final String id;
  final String name;
  final String startHex;
  final String endHex;

  const ThemeGradientPreset({
    required this.id,
    required this.name,
    required this.startHex,
    required this.endHex,
  });

  Color get startColor => _parseColor(startHex);
  Color get endColor => _parseColor(endHex);

  LinearGradient get gradient => LinearGradient(
    colors: [startColor, endColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color _parseColor(String hex) {
    var clean = hex.replaceAll('#', '').replaceAll('0x', '').trim();
    if (clean.length == 6) clean = "FF$clean";
    try {
      return Color(int.parse(clean, radix: 16));
    } catch (_) {
      return const Color(0xFF3F51B5);
    }
  }

  static const List<ThemeGradientPreset> presets = [
    ThemeGradientPreset(
      id: "emerald",
      name: "Zümrüt Yeşil",
      startHex: "#1B6B55",
      endHex: "#00BFA5",
    ),
    ThemeGradientPreset(
      id: "ocean",
      name: "Okyanus Mavi",
      startHex: "#1565C0",
      endHex: "#00E5FF",
    ),
    ThemeGradientPreset(
      id: "midnight",
      name: "Gece Yarısı",
      startHex: "#1A237E",
      endHex: "#3949AB",
    ),
    ThemeGradientPreset(
      id: "cyber",
      name: "Siber Mor",
      startHex: "#4A148C",
      endHex: "#7C4DFF",
    ),
    ThemeGradientPreset(
      id: "royal_violet",
      name: "Kraliyet Moru",
      startHex: "#7B1FA2",
      endHex: "#E040FB",
    ),
    ThemeGradientPreset(
      id: "fire_sunset",
      name: "Ateş & Güneş",
      startHex: "#C62828",
      endHex: "#FF9800",
    ),
    ThemeGradientPreset(
      id: "gold_amber",
      name: "Altın & Amber",
      startHex: "#E65100",
      endHex: "#FFD600",
    ),
    ThemeGradientPreset(
      id: "berry_rose",
      name: "Gül & Ahududu",
      startHex: "#880E4F",
      endHex: "#FF4081",
    ),
    ThemeGradientPreset(
      id: "carbon_stealth",
      name: "Karbon & Titanyum",
      startHex: "#263238",
      endHex: "#607D8B",
    ),
  ];

  static ThemeGradientPreset? findByHex(String startHex, {String? endHex}) {
    final cleanStart = startHex.toUpperCase();
    final cleanEnd = endHex?.toUpperCase();
    for (var p in presets) {
      if (p.startHex.toUpperCase() == cleanStart) {
        if (cleanEnd == null || p.endHex.toUpperCase() == cleanEnd) {
          return p;
        }
      }
    }
    return null;
  }
}

class GymBrandingModel {
  final String gymId;
  final String gymName;
  final String logoUrl;
  final String primaryColorHex;
  final String secondaryColorHex;
  final bool isGradient;
  final List<String> offeredLessonGroups;
  final String workingDays;
  final String openTime;
  final String closeTime;
  final int maxCancellationsAllowed;
  final String? address;
  final String? phone;
  final String? email;
  final String? instagram;
  final String? website;

  GymBrandingModel({
    required this.gymId,
    required this.gymName,
    required this.logoUrl,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    this.isGradient = false,
    this.offeredLessonGroups = const ["PT", "Pilates", "Kickboks", "Yoga"],
    this.workingDays = "1,2,3,4,5,6",
    this.openTime = "07:00",
    this.closeTime = "22:00",
    this.maxCancellationsAllowed = 4,
    this.address,
    this.phone,
    this.email,
    this.instagram,
    this.website,
  });

  int getColorFromHex() {
    String hex = primaryColorHex.replaceAll("#", "");
    if (hex.length == 6) hex = "FF$hex";
    return int.parse(hex, radix: 16);
  }
}
