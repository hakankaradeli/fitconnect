import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import '../../utils/image_utils.dart';
import '../../utils/formatters.dart';
import 'qr_scanner_screen.dart';
import 'booking_screen.dart';
import 'nutrition_view.dart';
import 'gym_card_screen.dart';
import 'widgets/survey_dialog.dart';
import '../widgets/announcement_board.dart';
import '../login_screen.dart';
import '../user_qr_screen.dart';
import '../../view_models/login_view_model.dart';
import '../../view_models/calendar_view_model.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/notification_view_model.dart';
import '../../view_models/theme_view_model.dart';
import '../../view_models/finance_view_model.dart';
import '../../models/booking_details_model.dart';
import '../widgets/table_time_picker.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null) {
        final userId = userData['userId'];
        final gymId = userData['gymId'] ?? 0;
        if (gymId > 0) {
          context.read<ThemeViewModel>().fetchGymBranding(gymId);
        }
        context.read<CalendarViewModel>().fetchMemberHistory(userId);
        context.read<NotificationViewModel>().fetchNotifications(userId);
        context.read<FinanceViewModel>().fetchBalance(userId);
        context.read<UserViewModel>().fetchUsers(userData['gymId']);

        final profile = await context.read<UserViewModel>().fetchProfile(userId);
        if (profile != null && mounted) {
          context.read<LoginViewModel>().updateUserData({
            'profileImageUrl': profile.profileImageUrl,
            'instagram': profile.instagram,
            'linkedin': profile.linkedin,
            'twitter': profile.twitter,
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loginVM = context.watch<LoginViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final userData = loginVM.userData;
    final calendarVM = context.watch<CalendarViewModel>();
    final proposedLessons = calendarVM.memberHistory.where((b) => b.status == 'PROPOSED').toList();
    final activeLessons = calendarVM.memberHistory.where((b) {
      final bool isPast = b.startTime.isBefore(DateTime.now());
      return (b.status.toUpperCase() == 'ACTIVE' || b.status.toUpperCase() == 'PENDING') && !isPast;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        centerTitle: true,
        title: GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const UserQrScreen()));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_2_rounded, color: Colors.indigo, size: 22),
                SizedBox(width: 6),
                Text("QR Kodum", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.black87, size: 24),
            tooltip: "Salon Kartı",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GymCardScreen())),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.black, size: 26),
                onPressed: () => _showNotifications(context),
              ),
              if (context.watch<NotificationViewModel>().notifications.any((n) => !n.isRead))
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                )
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black, size: 22),
            onPressed: () async {
              await context.read<LoginViewModel>().logout();
              if (context.mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (userData != null) {
            await context.read<CalendarViewModel>().fetchMemberHistory(userData['userId']);
            await context.read<NotificationViewModel>().fetchNotifications(userData['userId']);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _buildModernGreeting(userData),
              const SizedBox(height: 16),

              if (activeLessons.isNotEmpty) ...[
                _buildFirstActiveLessonCard(activeLessons.first),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScannerScreen())),
                      icon: Icons.qr_code_scanner_rounded,
                      label: "Dersi Başlat",
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionCard(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingScreen())),
                      icon: Icons.calendar_month_rounded,
                      label: "Randevu Al",
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              _buildWideActionCard(
                onPressed: () => _showProposedLessonsSheet(context, proposedLessons, userData),
                icon: Icons.auto_awesome_rounded,
                label: "Onay Bekleyen Dersler",
                count: proposedLessons.length,
                color: Colors.orange,
              ),

              const SizedBox(height: 10),

              _buildWideActionCard(
                onPressed: () => _showEditCancelSheet(context, activeLessons, userData),
                icon: Icons.edit_calendar_rounded,
                label: "Ders Değişikliği ve İptal",
                color: const Color(0xFFFF5252),
              ),

              const SizedBox(height: 10),

              _buildWideActionCard(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MemberNutritionView())),
                icon: Icons.restaurant_rounded,
                label: "Beslenme Planım",
                color: Colors.teal,
              ),

              const SizedBox(height: 10),

              _buildWideActionCard(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GymCardScreen())),
                icon: Icons.fitness_center_rounded,
                label: "Salon Kartı & Eğitmenlerimiz",
                color: const Color(0xFF1B6B55),
              ),

              const SizedBox(height: 20),

              const AnnouncementBoard(),

              const SizedBox(height: 20),

              _buildSectionHeader("Aktif Programım", activeLessons.length),
              const SizedBox(height: 12),
              if (activeLessons.isEmpty)
                _buildEmptyState("Planlanmış bir dersiniz bulunmuyor.")
              else
                ...activeLessons.map((b) => _buildModernLessonItem(context, b, false)).toList(),

              const SizedBox(height: 32),

              _buildSectionHeader("Geçmiş Derslerim", calendarVM.memberHistory.length - activeLessons.length),
              const SizedBox(height: 12),
              _buildPastLessonsList(calendarVM),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirstActiveLessonCard(BookingDetails nextLesson) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text("YAKLAŞAN DERSİNİZ", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade900,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScannerScreen())),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 14),
                label: const Text("BAŞLAT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            nextLesson.trainerName,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time_filled_rounded, color: Colors.white70, size: 15),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd MMMM EEEE, HH:mm', 'tr').format(nextLesson.startTime),
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernGreeting(Map<String, dynamic>? userData) {
    final String? photoUrl = userData?['profileImageUrl'];
    final imageProvider = getProfileImageProvider(photoUrl);
    final financeVM = context.watch<FinanceViewModel>();
    final int netCredits = financeVM.balance.netBalance;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showProfileEditSheet(context, userData),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(Icons.person_rounded, size: 34, color: Colors.blue)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_rounded, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Merhaba,", style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    Text(
                      userData?['fullName'] ?? "Üye",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -0.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: Colors.blueGrey),
                onPressed: () => _showProfileEditSheet(context, userData),
                tooltip: "Profil Düzenle",
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2575FC).withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "KALAN KREDİNİZ",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$netCredits Seans Kredi",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickProfileImage(BuildContext context, ImageSource source, Function(String base64) onImagePicked) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 350,
        maxHeight: 350,
        imageQuality: 60,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
        onImagePicked(base64Image);
      }
    } catch (e) {
      debugPrint("Pick image error: $e");
    }
  }

  void _showImageSourcePicker(BuildContext context, Function(String base64) onImagePicked) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bottomContext) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Profil Fotoğrafı Seç",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.blue),
              ),
              title: const Text("Kamera İle Çek", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Kameranızı kullanarak yeni fotoğraf çekin"),
              onTap: () {
                Navigator.pop(bottomContext);
                _pickProfileImage(context, ImageSource.camera, onImagePicked);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.purple.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.photo_library_rounded, color: Colors.purple),
              ),
              title: const Text("Galeriden Seç", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Telefon galerinizden bir fotoğraf seçin"),
              onTap: () {
                Navigator.pop(bottomContext);
                _pickProfileImage(context, ImageSource.gallery, onImagePicked);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, int? userId) {
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hesap Silme Onayı"),
        content: const Text("Hesabınızı ve tüm verilerinizi kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await context.read<UserViewModel>().deleteSelfAccount(userId);
              if (success && context.mounted) {
                await context.read<LoginViewModel>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Hesabınız ve tüm verileriniz kalıcı olarak silindi.")),
                  );
                }
              }
            },
            child: const Text("EVET, HESABIMI SİL"),
          ),
        ],
      ),
    );
  }

  void _showProfileEditSheet(BuildContext context, Map<String, dynamic>? userData) {
    final photoController = TextEditingController(text: userData?['profileImageUrl'] ?? '');

    String initialFullName = userData?['fullName'] ?? '';
    String initialFirstName = userData?['firstName'] ?? '';
    String initialLastName = userData?['lastName'] ?? '';
    if (initialFirstName.isEmpty && initialLastName.isEmpty && initialFullName.isNotEmpty) {
      final parts = initialFullName.split(' ');
      if (parts.length > 1) {
        initialFirstName = parts.sublist(0, parts.length - 1).join(' ');
        initialLastName = parts.last;
      } else {
        initialFirstName = initialFullName;
      }
    }

    final firstNameController = TextEditingController(text: initialFirstName);
    final lastNameController = TextEditingController(text: initialLastName);
    final phoneController = TextEditingController(text: formatPhoneNumber(userData?['phone']));
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    DateTime? selectedBirthDate = userData?['birthDate'] != null
        ? DateTime.tryParse(userData!['birthDate'])
        : null;
    String selectedGender = userData?['gender'] ?? 'OTHER';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final avatarProvider = getProfileImageProvider(photoController.text);
          return SafeArea(
            top: true,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Profil & Hesap Ayarları", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),

                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          backgroundImage: avatarProvider,
                          child: avatarProvider == null
                              ? const Icon(Icons.person_rounded, size: 48, color: Colors.blue)
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                _showImageSourcePicker(context, (base64Image) {
                                  setSheetState(() {
                                    photoController.text = base64Image;
                                  });
                                });
                              },
                              icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                              label: const Text("Fotoğraf Ekle / Değiştir"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade50,
                                foregroundColor: Colors.blue,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            if (photoController.text.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                tooltip: "Fotoğrafı Kaldır",
                                onPressed: () => setSheetState(() {
                                  photoController.clear();
                                }),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text("Kişisel Bilgiler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: firstNameController,
                          decoration: InputDecoration(
                            labelText: "Ad",
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: lastNameController,
                          decoration: InputDecoration(
                            labelText: "Soyad",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: userData?['email'] ?? ''),
                    decoration: InputDecoration(
                      labelText: "E-posta (Değiştirilemez)",
                      prefixIcon: const Icon(Icons.email_outlined),
                      fillColor: Colors.grey.shade100,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneInputFormatter()],
                    decoration: InputDecoration(
                      labelText: "Telefon Numarası",
                      hintText: "+90 5XX XXX XX XX",
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedBirthDate ?? DateTime(2000, 1, 1),
                              firstDate: DateTime(1940),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setSheetState(() => selectedBirthDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cake_outlined, color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    selectedBirthDate == null
                                        ? "Doğum Tarihi"
                                        : DateFormat('dd/MM/yyyy').format(selectedBirthDate!),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: selectedBirthDate == null ? Colors.grey.shade600 : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedGender,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: "ERKEK", child: Text("Erkek", style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: "KADIN", child: Text("Kadın", style: TextStyle(fontSize: 13))),
                                DropdownMenuItem(value: "OTHER", child: Text("Belirtmek İstemiyorum", style: TextStyle(fontSize: 12))),
                              ],
                              onChanged: (val) {
                                if (val != null) setSheetState(() => selectedGender = val);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_outline_rounded, color: Colors.orange),
                      title: const Text("Parola Değiştir", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange)),
                      children: [
                        const SizedBox(height: 8),
                        TextField(
                          controller: currentPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Mevcut Parola",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: newPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Yeni Parola",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        final userId = userData?['userId'];
                        if (userId != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Profil kaydediliyor...")),
                          );

                          final success = await context.read<UserViewModel>().updateProfile(
                            userId: userId,
                            firstName: firstNameController.text.trim().isEmpty ? null : firstNameController.text.trim(),
                            lastName: lastNameController.text.trim().isEmpty ? null : lastNameController.text.trim(),
                            phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                            birthDate: selectedBirthDate,
                            gender: selectedGender,
                            profileImageUrl: photoController.text.trim().isEmpty ? null : photoController.text.trim(),
                            currentPassword: currentPasswordController.text.isEmpty ? null : currentPasswordController.text,
                            newPassword: newPasswordController.text.isEmpty ? null : newPasswordController.text,
                          );

                          if (success && mounted) {
                            final updatedName = "${firstNameController.text.trim()} ${lastNameController.text.trim()}".trim();
                            context.read<LoginViewModel>().updateUserData({
                              'fullName': updatedName.isNotEmpty ? updatedName : (userData?['fullName'] ?? ''),
                              'firstName': firstNameController.text.trim(),
                              'lastName': lastNameController.text.trim(),
                              'phone': phoneController.text.trim(),
                              'birthDate': selectedBirthDate?.toIso8601String(),
                              'gender': selectedGender,
                              'profileImageUrl': photoController.text.trim().isEmpty ? null : photoController.text.trim(),
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Profil bilgileriniz ve ayarlarınız kaydedildi.")),
                            );
                          } else if (mounted) {
                            final errorMsg = context.read<UserViewModel>().errorMessage ?? "Profil kaydedilemedi.";
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMsg)),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text("KAYDET"),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text("Tehlikeli Bölge", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Hesabınızı silmeniz durumunda tüm verileriniz ve hesabınız kalıcı olarak kaldırılacaktır.",
                          style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _confirmDeleteAccount(context, userData?['userId']),
                            icon: const Icon(Icons.delete_forever_rounded),
                            label: const Text("Hesabımı Kalıcı Olarak Sil", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
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
    );
  }

  Widget _buildActionCard({required VoidCallback onPressed, required IconData icon, required String label, required Color color}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildWideActionCard({required VoidCallback onPressed, required IconData icon, required String label, int? count, required Color color}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            if (count != null && count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                child: Text("$count", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
          child: Text("$count", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
        ),
      ],
    );
  }

  Widget _buildModernLessonItem(BuildContext context, BookingDetails booking, bool isPast) {
    final bool isRealPast = booking.startTime.isBefore(DateTime.now());
    final bool isCompleted = booking.status.toUpperCase() == 'COMPLETED' || (booking.status.toUpperCase() == 'ACTIVE' && isRealPast);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: isRealPast ? () => _showLessonDetailsDialog(context, booking) : null,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isCompleted ? Colors.green : Colors.blue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(isCompleted ? Icons.check_circle_rounded : Icons.timer_rounded,
              color: isCompleted ? Colors.green : Colors.blue),
        ),
        title: Text(booking.trainerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(
          DateFormat('dd MMMM, HH:mm', 'tr').format(booking.startTime),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _buildPastLessonsList(CalendarViewModel calendarVM) {
    final past = calendarVM.memberHistory.where((b) {
      final bool isPast = b.startTime.isBefore(DateTime.now());
      return b.status.toUpperCase() == 'COMPLETED' || (b.status.toUpperCase() == 'ACTIVE' && isPast);
    }).toList();

    if (past.isEmpty) return _buildEmptyState("Geçmiş dersiniz bulunmuyor.");
    return Column(children: past.map((b) => _buildModernLessonItem(context, b, true)).toList());
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Center(child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 13))),
    );
  }

  void _showEditCancelSheet(BuildContext context, List<BookingDetails> lessons, Map<String, dynamic>? userData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Ders İşlemleri", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Expanded(
              child: lessons.isEmpty
                  ? const Center(child: Text("İşlem yapılabilecek aktif dersiniz yok."))
                  : ListView.builder(
                      itemCount: lessons.length,
                      itemBuilder: (context, index) {
                        return _buildEditCancelItem(context, lessons[index], userData);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditCancelItem(BuildContext context, BookingDetails booking, Map<String, dynamic>? userData) {
    final bool isPast = booking.startTime.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPast ? Colors.red.shade50 : Colors.white,
        border: Border.all(color: isPast ? Colors.red.shade200 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16)
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.trainerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(DateFormat('dd/MM HH:mm').format(booking.startTime), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                if (isPast)
                  const Text("GELMEDİ (NO-SHOW)", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (!isPast)
            IconButton(onPressed: () => _showEditBookingDialog(context, booking), icon: const Icon(Icons.access_time_rounded, color: Colors.orange)),

          IconButton(
            onPressed: () => _handleBookingCancel(context, booking),
            icon: const Icon(Icons.cancel_rounded, color: Colors.red)
          ),
        ],
      ),
    );
  }

  void _showProposedLessonsSheet(BuildContext context, List<BookingDetails> proposed, Map<String, dynamic>? userData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Yeni Ders Önerileri", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            if (proposed.isEmpty) const Text("Onay bekleyen ders yok.")
            else
              ...proposed.map((b) => ListTile(
                title: Text(b.trainerName),
                subtitle: Text(DateFormat('dd MMMM HH:mm').format(b.startTime)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () async {
                      final success = await context.read<CalendarViewModel>().approveBooking(b.id);
                      if (success && mounted) {
                        context.read<CalendarViewModel>().fetchMemberHistory(userData?['userId']);
                        Navigator.pop(context);
                      }
                    }),
                    IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () async {
                      final success = await context.read<CalendarViewModel>().rejectBooking(b.id, cancelledById: userData?['userId']);
                      if (success && mounted) {
                        context.read<CalendarViewModel>().fetchMemberHistory(userData?['userId']);
                        Navigator.pop(context);
                      }
                    }),
                  ],
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }

  void _showLessonDetailsDialog(BuildContext context, BookingDetails booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(booking.trainerName, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (booking.performedExercises.isEmpty)
              const Text("Antrenman notu girilmemiş.")
            else
              ...booking.performedExercises.map((e) => ListTile(
                dense: true,
                title: Text(e.exerciseName),
                subtitle: Text("${e.sets}x${e.reps}"),
                trailing: Text(e.weight ?? ""),
              )).toList(),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat"))],
      ),
    );
  }

  void _showEditBookingDialog(BuildContext context, BookingDetails booking) {
    DateTime selectedTime = booking.startTime;
    final calendarVM = context.read<CalendarViewModel>();
    final userData = context.read<LoginViewModel>().userData;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Ders Saatini Değiştir"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Yeni bir tarih ve saat seçin.", style: TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_rounded, color: Colors.blue),
                title: const Text("Ders Tarihi", style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(DateFormat('dd MMMM yyyy, EEEE', 'tr').format(selectedTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) {
                    setDialogState(() => selectedTime = DateTime(date.year, date.month, date.day, selectedTime.hour, selectedTime.minute));
                  }
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.table_chart_rounded, color: Colors.orange),
                title: const Text("Ders Saati (Tablodan Seçin)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(DateFormat('HH:mm').format(selectedTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                trailing: const Icon(Icons.access_time_rounded, size: 20, color: Colors.orange),
                onTap: () async {
                  final themeVM = context.read<ThemeViewModel>();
                  final openHour = int.tryParse(themeVM.openTime.split(':')[0]) ?? 7;
                  final closeHour = int.tryParse(themeVM.closeTime.split(':')[0]) ?? 22;

                  final time = await showTableTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedTime),
                    title: "Ders Saati Seçimi",
                    startHour: openHour,
                    endHour: closeHour > openHour ? (closeHour - 1) : closeHour,
                    isLessonBooking: true,
                  );
                  if (time != null) {
                    setDialogState(() => selectedTime = DateTime(selectedTime.year, selectedTime.month, selectedTime.day, time.hour, 0));
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                final success = await calendarVM.proposeBookingChange(booking.id, selectedTime);
                if (success && mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  calendarVM.fetchMemberHistory(userData?['userId']);
                }
              },
              child: const Text("TALEBİ GÖNDER"),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBookingCancel(BuildContext context, BookingDetails booking) {
    final calendarVM = context.read<CalendarViewModel>();
    final userData = context.read<LoginViewModel>().userData;
    bool isFree = calendarVM.canCancelFree(booking.startTime);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Dersi İptal Et"),
        content: Text(isFree ? "Bu dersi iptal etmek istediğinize emin misiniz? Krediniz iade edilecektir." : "İptal durumunda krediniz iade edilmeyecektir. Onaylıyor musunuz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              final success = await calendarVM.rejectBooking(booking.id, cancelledById: userData?['userId'], reason: "Üye tarafından iptal edildi");
              if (success && mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                calendarVM.fetchMemberHistory(userData?['userId']);
              }
            },
            child: const Text("İPTAL ET"),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    final vm = context.read<NotificationViewModel>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Bildirimler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (vm.notifications.isNotEmpty)
                  TextButton.icon(
                    onPressed: () async {
                      final userId = context.read<LoginViewModel>().userData?['userId'];
                      if (userId != null) {
                        await vm.deleteAllNotifications(userId);
                      }
                    },
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 18),
                    label: const Text("Tümünü Sil", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const Divider(),
            Expanded(
              child: vm.notifications.isEmpty
                ? const Center(child: Text("Henüz bildiriminiz yok."))
                : ListView.builder(
                    itemCount: vm.notifications.length,
                    itemBuilder: (context, index) {
                      final n = vm.notifications[index];
                      return ListTile(
                        leading: Icon(Icons.info_outline, color: n.isRead ? Colors.grey : Colors.blue),
                        title: Text(n.message, style: TextStyle(fontSize: 13, fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                        subtitle: Text(DateFormat('dd/MM HH:mm', 'tr').format(n.createdAt)),
                        trailing: n.isRead
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                onPressed: () async {
                                  await vm.deleteNotification(n.id);
                                },
                              )
                            : null,
                        onTap: () => vm.markAsRead(n.id),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
