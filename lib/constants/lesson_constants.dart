class LessonConstants {
  static const String pt = "PT";
  static const String pilates = "Pilates";
  static const String kickBoks = "Kick Boks/Boks";
  static const String yoga = "Yoga";

  static const List<String> mainGroups = [
    pt,
    pilates,
    kickBoks,
    yoga,
  ];

  static const List<String> ptTypes = [
    "PT Bireysel",
    "PT Duo",
  ];

  static const List<String> pilatesTypes = [
    "Bireysel",
    "2 Kişi",
    "3 Kişi",
    "4 Kişi",
    "5 Kişi",
    "6 Kişi",
    "7 Kişi",
    "8 Kişi",
    "9 Kişi",
    "10 Kişi",
  ];

  static const List<String> kickBoksTypes = [
    "Kick Boks Bireysel",
    "Kick Boks Grup",
  ];

  static const List<String> yogaTypes = [
    "Yoga Bireysel",
    "Yoga Grup",
  ];

  static List<String> getSubTypes(String group) {
    switch (group) {
      case pt:
        return ptTypes;
      case pilates:
        return pilatesTypes;
      case kickBoks:
        return kickBoksTypes;
      case yoga:
        return yogaTypes;
      default:
        return ptTypes;
    }
  }

  static const List<String> allTypes = [
    ...ptTypes,
    ...pilatesTypes,
    ...kickBoksTypes,
    ...yogaTypes,
  ];

  static String getCategory(String type) {
    if (ptTypes.contains(type)) return pt;
    if (pilatesTypes.contains(type)) return pilates;
    if (kickBoksTypes.contains(type)) return kickBoks;
    if (yogaTypes.contains(type)) return yoga;
    return pt;
  }
}
