class GymBrandingModel {
  final String gymId;
  final String gymName;
  final String logoUrl;
  final String primaryColorHex; // Örn: "#FF5733"
  final String secondaryColorHex;

  GymBrandingModel({
    required this.gymId,
    required this.gymName,
    required this.logoUrl,
    required this.primaryColorHex,
    required this.secondaryColorHex,
  });

  // JSON'dan gelen Hex kodunu Flutter Color nesnesine çeviren yardımcı fonksiyon
  int getColorFromHex() {
    String hex = primaryColorHex.replaceAll("#", "");
    if (hex.length == 6) hex = "FF$hex"; // Alpha kanalı ekleme
    return int.parse(hex, radix: 16);
  }
}
