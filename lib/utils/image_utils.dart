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
