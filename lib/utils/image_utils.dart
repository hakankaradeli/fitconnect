import 'dart:convert';
import 'package:flutter/material.dart';

ImageProvider? getProfileImageProvider(String? photoUrl) {
  if (photoUrl == null || photoUrl.trim().isEmpty) return null;
  final trimmed = photoUrl.trim();
  if (trimmed.startsWith("data:image") && trimmed.contains("base64,")) {
    try {
      final base64Str = trimmed.split("base64,").last;
      final bytes = base64Decode(base64Str);
      return MemoryImage(bytes);
    } catch (e) {
      debugPrint("Image decode error: $e");
      return null;
    }
  }
  if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
    return NetworkImage(trimmed);
  }
  return null;
}

Widget getGymLogoWidget(String? logoUrl, {double height = 36, double width = 36, Color? fallbackColor}) {
  final Widget fallbackLogo = ClipRRect(
    borderRadius: BorderRadius.circular(height * 0.2),
    child: Image.asset(
      'assets/logo.png',
      height: height,
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (c, e, s) => Icon(Icons.fitness_center_rounded, size: height, color: fallbackColor ?? Colors.indigo),
    ),
  );

  if (logoUrl == null || logoUrl.trim().isEmpty) {
    return fallbackLogo;
  }
  final trimmed = logoUrl.trim();
  if (trimmed.startsWith("data:image") && trimmed.contains("base64,")) {
    try {
      final base64Str = trimmed.split("base64,").last;
      final bytes = base64Decode(base64Str);
      return ClipRRect(
        borderRadius: BorderRadius.circular(height * 0.2),
        child: Image.memory(bytes, height: height, width: width, fit: BoxFit.contain),
      );
    } catch (e) {
      return fallbackLogo;
    }
  }
  if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height * 0.2),
      child: Image.network(
        trimmed,
        height: height,
        width: width,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => fallbackLogo,
      ),
    );
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(height * 0.2),
    child: Image.asset(
      trimmed,
      height: height,
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (c, e, s) => fallbackLogo,
    ),
  );
}
