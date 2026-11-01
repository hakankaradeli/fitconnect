import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../view_models/theme_view_model.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../models/user_model.dart';
import '../../models/gym_branding_model.dart';
import '../../utils/image_utils.dart';
import '../../constants/lesson_constants.dart';

class GymCardScreen extends StatefulWidget {
  final int? gymId;
  const GymCardScreen({super.key, this.gymId});

  @override
  State<GymCardScreen> createState() => _GymCardScreenState();
}

class _GymCardScreenState extends State<GymCardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loginVM = context.read<LoginViewModel>();
      final effectiveGymId = widget.gymId ?? loginVM.userData?['gymId'] ?? 0;
      if (effectiveGymId > 0) {
        context.read<ThemeViewModel>().fetchGymBranding(effectiveGymId);
        context.read<UserViewModel>().fetchUsers(effectiveGymId);
      }
    });
  }

  Future<void> _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar("Bağlantı açılamadı: $url");
      }
    } catch (e) {
      _showSnackBar("Hata: $e");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showGymInfoDialog(ThemeViewModel themeVM) {
    final primaryColor = themeVM.primaryColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.fitness_center_rounded, color: primaryColor, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                themeVM.gymName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.schedule_rounded, "Çalışma Saatleri", "${themeVM.openTime} - ${themeVM.closeTime}", primaryColor),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today_rounded, "Çalışma Günleri", "Haftanın 6 Günü (Pzt - Cmt)", primaryColor),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.event_busy_rounded, "Maksimum İptal Hakkı", "${themeVM.maxCancellationsAllowed} Ders / Ay", primaryColor),
            if (themeVM.address != null && themeVM.address!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.location_on_outlined, "Adres", themeVM.address!, primaryColor),
            ],
            if (themeVM.phone != null && themeVM.phone!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.phone_rounded, "Telefon", themeVM.phone!, primaryColor),
            ],
            if (themeVM.email != null && themeVM.email!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.email_outlined, "E-posta", themeVM.email!, primaryColor),
            ],
            if (themeVM.website != null && themeVM.website!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.language_rounded, "Web Sitesi", themeVM.website!, primaryColor),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Kapat", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditGymCardSheet(BuildContext context, ThemeViewModel themeVM, int gymId) {
    final nameController = TextEditingController(text: themeVM.gymName);
    final addressController = TextEditingController(text: themeVM.address ?? '');
    final phoneController = TextEditingController(text: themeVM.phone ?? '');
    final instagramController = TextEditingController(text: themeVM.instagram ?? '');
    final emailController = TextEditingController(text: themeVM.email ?? '');
    final websiteController = TextEditingController(text: themeVM.website ?? '');
    String selectedColorHex = themeVM.branding?.primaryColorHex ?? '#1B6B55';
    String selectedSecondaryHex = themeVM.branding?.secondaryColorHex ?? (ThemeGradientPreset.findByHex(selectedColorHex)?.endHex ?? '#00BFA5');
    bool isGradient = themeVM.isGradient;
    String? selectedGradientId = ThemeGradientPreset.findByHex(selectedColorHex, endHex: selectedSecondaryHex)?.id ?? "emerald";
    String? localLogoBase64;
    bool isSaving = false;

    final List<Map<String, String>> presetColors = [
      {"name": "Yeşil", "hex": "#1B6B55"},
      {"name": "Lacivert", "hex": "#3F51B5"},
      {"name": "Mavi", "hex": "#2196F3"},
      {"name": "Kırmızı", "hex": "#E53935"},
      {"name": "Mor", "hex": "#9C27B0"},
      {"name": "Turuncu", "hex": "#FF9800"},
      {"name": "Koyu Gri", "hex": "#37474F"},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final activeThemeColor = themeVM.parseHexColor(selectedColorHex);

          return Container(
            height: MediaQuery.of(sheetContext).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: activeThemeColor, size: 28),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Salon Kartı Bilgilerini Düzenle",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 18),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1E282A),
                                  border: Border.all(color: activeThemeColor, width: 3),
                                ),
                                child: ClipOval(
                                  child: getGymLogoWidget(
                                    localLogoBase64 ?? themeVM.gymLogo,
                                    width: 86,
                                    height: 86,
                                    fallbackColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () async {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 400,
                                    maxHeight: 400,
                                    imageQuality: 80,
                                  );
                                  if (image != null) {
                                    final bytes = await image.readAsBytes();
                                    final base64Logo = "data:image/png;base64,${base64Encode(bytes)}";
                                    setSheetState(() {
                                      localLogoBase64 = base64Logo;
                                    });
                                  }
                                },
                                icon: Icon(Icons.photo_library_rounded, size: 18, color: activeThemeColor),
                                label: Text(
                                  "Galeriden Logo Seç",
                                  style: TextStyle(color: activeThemeColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildSheetTextField(
                          controller: nameController,
                          label: "Salon Adı",
                          hint: "Örn: CAT GYM",
                          icon: Icons.fitness_center_rounded,
                          primaryColor: activeThemeColor,
                        ),
                        const SizedBox(height: 12),

                        _buildSheetTextField(
                          controller: addressController,
                          label: "Salon Adresi",
                          hint: "Mahalle, Cadde/Sokak, İlçe / İl",
                          icon: Icons.location_on_rounded,
                          primaryColor: activeThemeColor,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),

                        _buildSheetTextField(
                          controller: phoneController,
                          label: "İletişim / WhatsApp Telefon Numarası",
                          hint: "+90 532 000 00 00",
                          icon: Icons.phone_rounded,
                          primaryColor: activeThemeColor,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),

                        _buildSheetTextField(
                          controller: instagramController,
                          label: "Instagram Hesabı",
                          hint: "catgym_official",
                          icon: Icons.camera_alt_rounded,
                          primaryColor: activeThemeColor,
                          prefixText: "@",
                        ),
                        const SizedBox(height: 12),

                        _buildSheetTextField(
                          controller: emailController,
                          label: "İletişim E-posta Adresi",
                          hint: "info@catgym.com",
                          icon: Icons.email_rounded,
                          primaryColor: activeThemeColor,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),

                        _buildSheetTextField(
                          controller: websiteController,
                          label: "Web Sitesi (Opsiyonel)",
                          hint: "www.catgym.com",
                          icon: Icons.language_rounded,
                          primaryColor: activeThemeColor,
                        ),

                        const SizedBox(height: 16),
                        const Text("Kurumsal Tema Rengi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 10),

                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setSheetState(() {
                                      isGradient = false;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      color: !isGradient ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: !isGradient
                                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.palette_outlined, size: 18, color: !isGradient ? activeThemeColor : Colors.grey.shade600),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Düz Renk",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: !isGradient ? FontWeight.bold : FontWeight.w600,
                                            color: !isGradient ? activeThemeColor : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setSheetState(() {
                                      isGradient = true;
                                      final currentPreset = ThemeGradientPreset.findByHex(selectedColorHex);
                                      if (currentPreset != null) {
                                        selectedGradientId = currentPreset.id;
                                        selectedSecondaryHex = currentPreset.endHex;
                                      } else {
                                        final defaultPreset = ThemeGradientPreset.presets.first;
                                        selectedGradientId = defaultPreset.id;
                                        selectedColorHex = defaultPreset.startHex;
                                        selectedSecondaryHex = defaultPreset.endHex;
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      color: isGradient ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: isGradient
                                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.gradient_rounded, size: 18, color: isGradient ? activeThemeColor : Colors.grey.shade600),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Gradyan ✨",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isGradient ? FontWeight.bold : FontWeight.w600,
                                            color: isGradient ? activeThemeColor : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (!isGradient) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: presetColors.map((colorMap) {
                              final hex = colorMap['hex']!;
                              final isSelected = selectedColorHex.toUpperCase() == hex.toUpperCase();
                              final color = themeVM.parseHexColor(hex);

                              return ChoiceChip(
                                label: Text(colorMap['name']!),
                                selected: isSelected,
                                avatar: CircleAvatar(backgroundColor: color, radius: 8),
                                selectedColor: color.withValues(alpha: 0.2),
                                onSelected: (val) {
                                  if (val) {
                                    setSheetState(() {
                                      selectedColorHex = hex;
                                      selectedSecondaryHex = hex;
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ] else ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ThemeGradientPreset.presets.map((preset) {
                              final isSelected = selectedGradientId == preset.id ||
                                  (selectedColorHex.toUpperCase() == preset.startHex.toUpperCase() &&
                                      selectedSecondaryHex.toUpperCase() == preset.endHex.toUpperCase());

                              return InkWell(
                                onTap: () {
                                  setSheetState(() {
                                    selectedGradientId = preset.id;
                                    selectedColorHex = preset.startHex;
                                    selectedSecondaryHex = preset.endHex;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? activeThemeColor.withValues(alpha: 0.1) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? activeThemeColor : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: preset.gradient,
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 1)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        preset.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? activeThemeColor : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 14),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isGradient
                                ? LinearGradient(
                                    colors: [
                                      themeVM.parseHexColor(selectedColorHex),
                                      themeVM.parseHexColor(selectedSecondaryHex),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: !isGradient ? themeVM.parseHexColor(selectedColorHex) : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: themeVM.parseHexColor(selectedColorHex).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.style_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isGradient ? "Gradyan Tema Önizleme" : "Düz Renk Önizleme",
                                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isGradient
                                          ? (ThemeGradientPreset.findByHex(selectedColorHex, endHex: selectedSecondaryHex)?.name ?? "Özel Gradyan")
                                          : "Seçili Tema Rengi",
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeThemeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  setSheetState(() => isSaving = true);
                                  final success = await themeVM.updateGymBranding(
                                    gymId,
                                    gymName: nameController.text.trim(),
                                    address: addressController.text.trim(),
                                    phone: phoneController.text.trim(),
                                    instagram: instagramController.text.trim().replaceAll('@', ''),
                                    email: emailController.text.trim(),
                                    website: websiteController.text.trim(),
                                    primaryColorHex: selectedColorHex,
                                    secondaryColorHex: selectedSecondaryHex,
                                    isGradient: isGradient,
                                    logoUrl: localLogoBase64 ?? themeVM.gymLogo,
                                  );
                                  setSheetState(() => isSaving = false);

                                  if (success && sheetContext.mounted) {
                                    context.read<LoginViewModel>().updateUserData({
                                      'gymName': nameController.text.trim(),
                                      'primaryColor': selectedColorHex,
                                      'secondaryColor': selectedSecondaryHex,
                                      'isGradient': isGradient,
                                      'logoUrl': localLogoBase64 ?? themeVM.gymLogo,
                                    });
                                    Navigator.pop(sheetContext);
                                    _showSnackBar("Salon kartı bilgileri ve tema rengi güncellendi! ✅");
                                  } else if (mounted) {
                                    _showSnackBar("Güncelleme başarısız oldu. Lütfen tekrar deneyin.");
                                  }
                                },
                          icon: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle_rounded),
                          label: Text(
                            isSaving ? "Kaydediliyor..." : "DEĞİŞİKLİKLERİ KAYDET",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSheetTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color primaryColor,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        filled: true,
        fillColor: const Color(0xFFF7FBF9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  List<String> _getMainBranches(List<String>? canTeach) {
    if (canTeach == null || canTeach.isEmpty) {
      return ["PT"];
    }

    final Set<String> groups = {};

    for (final raw in canTeach) {
      final item = raw.trim();
      final lower = item.toLowerCase();

      if (lower.contains("pilates") ||
          lower.contains("reformer") ||
          (LessonConstants.pilatesTypes.contains(item) &&
              !lower.contains("pt") &&
              !lower.contains("kick") &&
              !lower.contains("yoga"))) {
        groups.add("Pilates");
      } else if (lower.contains("kick") || lower.contains("boks") || lower.contains("box")) {
        groups.add("Kickboks");
      } else if (lower.contains("yoga")) {
        groups.add("Yoga");
      } else if (lower.contains("pt") ||
          lower.contains("personal") ||
          lower.contains("fitness") ||
          lower.contains("bireysel") ||
          lower.contains("duo")) {
        groups.add("PT");
      } else {
        final cat = LessonConstants.getCategory(item);
        if (cat == LessonConstants.pilates) {
          groups.add("Pilates");
        } else if (cat == LessonConstants.kickBoks) {
          groups.add("Kickboks");
        } else if (cat == LessonConstants.yoga) {
          groups.add("Yoga");
        } else {
          groups.add("PT");
        }
      }
    }

    if (groups.isEmpty) {
      return ["PT"];
    }

    const standardOrder = ["PT", "Pilates", "Kickboks", "Yoga"];
    final sorted = standardOrder.where((g) => groups.contains(g)).toList();
    for (final g in groups) {
      if (!sorted.contains(g)) {
        sorted.add(g);
      }
    }
    return sorted;
  }

  void _showTrainerLessonsSheet(BuildContext context, UserModel trainer, Color primaryColor) {
    final List<String> lessons = _getMainBranches(trainer.canTeach);

    final Color lightBg = Color.alphaBlend(primaryColor.withValues(alpha: 0.12), Colors.white);
    final Color borderTint = Color.alphaBlend(primaryColor.withValues(alpha: 0.28), Colors.white);
    final Color softBadgeBg = Color.alphaBlend(primaryColor.withValues(alpha: 0.08), Colors.white);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: lightBg,
                    child: trainer.profileImageUrl != null && trainer.profileImageUrl!.isNotEmpty
                        ? Image(
                            image: getProfileImageProvider(trainer.profileImageUrl)!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.person_rounded, size: 36, color: primaryColor),
                          )
                        : Icon(Icons.person_rounded, size: 36, color: primaryColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trainer.fullName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: softBadgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trainer.role == "ADMIN" ? "Baş Eğitmen & Yönetici" : "Eğitmen / Antrenör",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.sports_gymnastics_rounded, color: primaryColor, size: 22),
                const SizedBox(width: 8),
                const Text(
                  "Verdiği Dersler ve Branşlar",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: lessons.map((lesson) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderTint, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: lightBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getCategoryIcon(lesson),
                          size: 16,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lesson,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Kapat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains("pilates")) {
      return Icons.self_improvement_rounded;
    } else if (lower.contains("kick") || lower.contains("boks") || lower.contains("box")) {
      return Icons.sports_mma_rounded;
    } else if (lower.contains("yoga")) {
      return Icons.spa_rounded;
    } else {
      return Icons.fitness_center_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final userVM = context.watch<UserViewModel>();
    final loginVM = context.watch<LoginViewModel>();

    final userRole = loginVM.userData?['role'];
    final bool isAdmin = userRole == "ADMIN" || userRole == "SUPER_ADMIN";
    final effectiveGymId = widget.gymId ?? loginVM.userData?['gymId'] ?? 0;

    final Color primaryColor = themeVM.primaryColor;
    final Color secondaryColor = themeVM.secondaryColor;
    final bool isGradient = themeVM.isGradient;

    final Color gradTop = isGradient
        ? Color.alphaBlend(primaryColor.withValues(alpha: 0.22), Colors.white)
        : Color.alphaBlend(primaryColor.withValues(alpha: 0.18), Colors.white);
    final Color gradMid1 = isGradient
        ? Color.alphaBlend(Color.lerp(primaryColor, secondaryColor, 0.5)!.withValues(alpha: 0.12), Colors.white)
        : Color.alphaBlend(primaryColor.withValues(alpha: 0.08), Colors.white);
    final Color gradMid2 = isGradient
        ? Color.alphaBlend(secondaryColor.withValues(alpha: 0.04), Colors.white)
        : Color.alphaBlend(primaryColor.withValues(alpha: 0.02), Colors.white);

    final Color lightBg = Color.alphaBlend(primaryColor.withValues(alpha: 0.14), Colors.white);
    final Color softBadgeBg = Color.alphaBlend(primaryColor.withValues(alpha: 0.08), Colors.white);

    final trainers = userVM.users.where((u) => u.isTrainerOrCanTeach || u.role == 'TRAINER' || u.role == 'ADMIN').toList();

    final String gymName = themeVM.gymName.isNotEmpty ? themeVM.gymName : "CAT GYM";
    final String address = (themeVM.address != null && themeVM.address!.trim().isNotEmpty)
        ? themeVM.address!
        : "Şehit Osman Avcı Mahallesi, Malazgirt 1071 Cadde 50A-65, Etimesgut / Ankara";
    final String? phone = themeVM.phone;
    final String? instagram = themeVM.instagram;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradTop,
              gradMid1,
              gradMid2,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.25, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.black87),
                      ),
                    ),

                    const Text(
                      "Salon Kartı",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),

                    Row(
                      children: [
                        if (isAdmin) ...[
                          GestureDetector(
                            onTap: () => _showEditGymCardSheet(context, themeVM, effectiveGymId),
                            child: Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.edit_rounded, size: 20, color: primaryColor),
                            ),
                          ),
                        ],
                        GestureDetector(
                          onTap: () => _showGymInfoDialog(themeVM),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.info_outline_rounded, size: 22, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      Center(
                        child: Container(
                          width: 104,
                          height: 104,
                          padding: const EdgeInsets.all(3.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isGradient
                                ? LinearGradient(
                                    colors: [primaryColor, secondaryColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: !isGradient ? primaryColor : null,
                            boxShadow: [
                              BoxShadow(
                                color: (isGradient ? primaryColor : primaryColor).withValues(alpha: 0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1E282A),
                            ),
                            child: ClipOval(
                              child: getGymLogoWidget(
                                themeVM.gymLogo,
                                width: 96,
                                height: 96,
                                fallbackColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              gymName.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),

                            Text(
                              address,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.grey.shade700,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 14),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionIconButton(
                                  icon: Icons.phone_rounded,
                                  label: "Ara",
                                  color: const Color(0xFF2E7D32),
                                  bgColor: const Color(0xFFE8F5E9),
                                  onTap: () {
                                    if (phone != null && phone.isNotEmpty) {
                                      _launchExternalUrl("tel:$phone");
                                    } else {
                                      _showSnackBar("Salon telefon numarası bulunamadı.");
                                    }
                                  },
                                ),

                                _buildActionIconButton(
                                  icon: Icons.chat_rounded,
                                  label: "WhatsApp",
                                  color: const Color(0xFF25D366),
                                  bgColor: const Color(0xFFE8F8F0),
                                  onTap: () {
                                    final cleanPhone = (phone ?? "+905320000000").replaceAll(RegExp(r'[^0-9]'), '');
                                    _launchExternalUrl("https://wa.me/$cleanPhone");
                                  },
                                ),

                                _buildActionIconButton(
                                  icon: Icons.camera_alt_rounded,
                                  label: "Instagram",
                                  color: const Color(0xFFE1306C),
                                  bgColor: const Color(0xFFFDE8F0),
                                  onTap: () {
                                    final handle = (instagram != null && instagram.isNotEmpty)
                                        ? instagram.replaceAll('@', '')
                                        : "catgym_official";
                                    _launchExternalUrl("https://instagram.com/$handle");
                                  },
                                ),

                                _buildActionIconButton(
                                  icon: Icons.location_on_rounded,
                                  label: "Harita",
                                  color: const Color(0xFF1976D2),
                                  bgColor: const Color(0xFFE3F2FD),
                                  onTap: () {
                                    _launchExternalUrl("https://maps.google.com/?q=${Uri.encodeComponent(address)}");
                                  },
                                ),
                              ],
                            ),

                            if (isAdmin) ...[
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  side: BorderSide(color: primaryColor, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () => _showEditGymCardSheet(context, themeVM, effectiveGymId),
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                label: const Text(
                                  "Salon Bilgilerini Düzenle",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Eğitmen Kadromuz",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: lightBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${trainers.length} Eğitmen",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      if (userVM.isLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: CircularProgressIndicator(color: primaryColor)),
                        )
                      else if (trainers.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: Text(
                              "Kayıtlı eğitmen bilgisi bulunamadı.",
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: trainers.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final trainer = trainers[index];
                            final List<String> branches = _getMainBranches(trainer.canTeach);

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _showTrainerLessonsSheet(context, trainer, primaryColor),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.035),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          width: 58,
                                          height: 58,
                                          color: lightBg,
                                          child: trainer.profileImageUrl != null && trainer.profileImageUrl!.isNotEmpty
                                              ? Image(
                                                  image: getProfileImageProvider(trainer.profileImageUrl)!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Icon(
                                                    Icons.person_rounded,
                                                    size: 32,
                                                    color: primaryColor,
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.person_rounded,
                                                  size: 32,
                                                  color: primaryColor,
                                                ),
                                        ),
                                      ),

                                      const SizedBox(width: 14),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              trainer.fullName,
                                              style: const TextStyle(
                                                fontSize: 16.5,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              branches.join(" • "),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: softBadgeBg,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "Dersler",
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: primaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              size: 16,
                                              color: primaryColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
