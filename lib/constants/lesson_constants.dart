class LessonConstants {
  static const String pt = "PT";
  static const String reformer = "Reformer Pilates";
  static const String yoga = "Yoga";

  static const List<String> ptTypes = [
    "PT Bireysel",
    "PT Duo",
  ];

  static const List<String> reformerTypes = [
    "Reformer Pilates Bireysel",
    "Reformer Pilates Duo",
    "Reformer Pilates 3 Kişi Grup",
    "Reformer Pilates 4 Kişi Grup",
    "Reformer Seansı Kapat",
  ];

  static const List<String> yogaTypes = [
    "Yoga",
  ];

  static const List<String> allTypes = [
    ...ptTypes,
    ...reformerTypes,
    ...yogaTypes,
  ];

  static String getCategory(String type) {
    if (ptTypes.contains(type)) return pt;
    if (reformerTypes.contains(type)) return reformer;
    if (yogaTypes.contains(type)) return yoga;
    return pt;
  }
}
