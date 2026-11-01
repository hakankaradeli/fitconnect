import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../utils/formatters.dart';
import 'qr_generator_screen.dart';
import 'trainer_schedule_view.dart';
import 'add_nutrition_view.dart';
import '../widgets/announcement_board.dart';
import '../login_screen.dart';
import '../user_qr_screen.dart';
import '../member/gym_card_screen.dart';
import '../admin/user_list_screen.dart' show UserListScreen;
import '../admin/trainer_list_screen.dart' show TrainerListScreen;
import '../admin/cancellation_reports_screen.dart';
import '../../utils/image_utils.dart';
import '../../view_models/login_view_model.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/trainer_schedule_view_model.dart';
import '../../view_models/notification_view_model.dart';
import '../../view_models/theme_view_model.dart';
import '../../view_models/accrual_view_model.dart';
import '../dashboard_router.dart';

class TrainerDashboard extends StatefulWidget {
  const TrainerDashboard({super.key});

  @override
  State<TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<TrainerDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null) {
        final trainerId = userData['userId'];
        final gymId = userData['gymId'] ?? 0;
        if (gymId > 0) {
          context.read<ThemeViewModel>().fetchGymBranding(gymId);
        }
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 1));
        context.read<TrainerScheduleViewModel>().fetchSchedule(trainerId, start, end);
        context.read<TrainerScheduleViewModel>().fetchPendingApprovals(trainerId);
        context.read<NotificationViewModel>().fetchNotifications(trainerId);
        context.read<AccrualViewModel>().fetchUnpaidDetails(trainerId);
        context.read<AccrualViewModel>().fetchTrainerStats(trainerId);
      }
    });
  }

  bool _hasPermission(Map<String, dynamic>? userData, String perm) {
    if (userData == null) return false;
    final role = userData['role'];
    if (role == 'ADMIN' || role == 'SUPER_ADMIN') return true;
    final List<dynamic> perms = userData['tempPermissions'] ?? [];
    return perms.contains(perm) || perms.contains("FULL_ADMIN_ACCESS");
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TrainerScheduleViewModel>();
    final userData = context.watch<LoginViewModel>().userData;

    final canManageUsers = _hasPermission(userData, "MANAGE_USERS");
    final canViewReports = _hasPermission(userData, "VIEW_REPORTS");

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
          if (canManageUsers || canViewReports)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.red),
              tooltip: "Yönetici Paneline Geç",
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardRouter(role: "ADMIN")));
              },
            ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.black87),
            tooltip: "Salon Kartı",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GymCardScreen())),
          ),
          _buildNotificationIcon(context),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<LoginViewModel>().logout();
              if (context.mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildModernGreeting(userData),
              const SizedBox(height: 16),
              _buildStatsHeader(),
              const SizedBox(height: 24),

              if (viewModel.pendingApprovals.isNotEmpty)
                _buildModernPendingBanner(context, viewModel, userData?['userId']),

              _buildMainActionCard(
                onPressed: () => _showStartSessionDialog(context),
                icon: Icons.qr_code_scanner_rounded,
                title: "Dersi Başlat",
                subtitle: "Üye QR kodunu okutarak dersi tamamla",
                color: Colors.green,
              ),

              const SizedBox(height: 16),

              _buildMainActionCard(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TrainerScheduleView())),
                icon: Icons.calendar_today_rounded,
                title: "Ders Programım",
                subtitle: "Haftalık ve aylık derslerini yönet",
                color: Colors.blue,
              ),

              const SizedBox(height: 16),

              _buildMainActionCard(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TrainerAddNutritionView())),
                icon: Icons.restaurant_menu_rounded,
                title: "Beslenme Programı Yaz",
                subtitle: "Atandığın üyeler için 60 günlük beslenme planı oluştur",
                color: Colors.teal,
              ),

              const SizedBox(height: 16),

              _buildMainActionCard(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GymCardScreen())),
                icon: Icons.fitness_center_rounded,
                title: "Salon Kartı & Eğitmen Kadrosu",
                subtitle: "Salon kurumsal bilgileri ve eğitmen branşları",
                color: const Color(0xFF1B6B55),
              ),

              const SizedBox(height: 24),

              const AnnouncementBoard(),

              if (canManageUsers || canViewReports) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardRouter(role: "ADMIN")));
                    },
                    icon: const Icon(Icons.admin_panel_settings_rounded, size: 22),
                    label: const Text("YÖNETİCİ PROFİLİNE GEÇ", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text("Yönetici Yetkileri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                const Divider(),
                const SizedBox(height: 12),

                if (canManageUsers) ...[
                  _buildAdminActionTile(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserListScreen())),
                    icon: Icons.people_alt_rounded,
                    label: "Üye Yönetimi",
                  ),
                  const SizedBox(height: 12),
                  _buildAdminActionTile(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TrainerListScreen())),
                    icon: Icons.engineering_rounded,
                    label: "Hoca Yönetimi",
                  ),
                ],

                if (canViewReports) ...[
                  const SizedBox(height: 12),
                  _buildAdminActionTile(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CancellationReportsScreen())),
                    icon: Icons.bar_chart_rounded,
                    label: "İptal Raporları",
                  ),
                ],
              ],
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final viewModel = context.watch<TrainerScheduleViewModel>();
    final accrualVM = context.watch<AccrualViewModel>();

    final today = DateTime.now();
    final todayLessonsCount = viewModel.bookings.where((b) {
      return b.startTime.year == today.year &&
             b.startTime.month == today.month &&
             b.startTime.day == today.day &&
             (b.status.toUpperCase() == 'ACTIVE' || b.status.toUpperCase() == 'PENDING');
    }).length;

    final double unpaidTotal = accrualVM.pendingAccruals.fold(0.0, (sum, a) => sum + a.amount);
    final String hakedisText = unpaidTotal > 0 ? "${unpaidTotal.toStringAsFixed(0)} Puan" : "0 Puan";
    final String rateText = accrualVM.averageRating > 0 ? accrualVM.averageRating.toStringAsFixed(1) : "0.0";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Bugün", "$todayLessonsCount Ders", Colors.blue),
          Container(width: 1, height: 36, color: Colors.grey.shade200),
          _buildStatItem("Hakediş", hakedisText, Colors.green),
          Container(width: 1, height: 36, color: Colors.grey.shade200),
          _buildStatItem("Puan", rateText, Colors.amber),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildModernGreeting(Map<String, dynamic>? userData) {
    final String? photoUrl = userData?['profileImageUrl'];
    final imageProvider = getProfileImageProvider(photoUrl);
    final themeVM = context.watch<ThemeViewModel>();
    final primaryColor = themeVM.primaryColor;

    return Row(
      children: [
        GestureDetector(
          onTap: () => _showProfileEditSheet(context, userData),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: primaryColor.withOpacity(0.1),
                backgroundImage: imageProvider,
                child: imageProvider == null ? Icon(Icons.person_rounded, size: 32, color: primaryColor) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.edit, size: 11, color: Colors.white),
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
              Text(
                "Hoş geldin, ${userData?['fullName'] ?? 'Eğitmen'}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.sports_rounded, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "Eğitmen Paneli • ${userData?['gymName'] ?? 'PtFitConnect'}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: primaryColor),
          tooltip: "Profil & Hesap Ayarları",
          onPressed: () => _showProfileEditSheet(context, userData),
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
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.green),
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
                decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.photo_library_rounded, color: Colors.teal),
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
        content: const Text("Eğitmen hesabınızı ve tüm verilerinizi kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
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
                    const SnackBar(content: Text("Eğitmen hesabınız ve tüm verileriniz kalıcı olarak silindi.")),
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
                          backgroundColor: Colors.green.withOpacity(0.1),
                          backgroundImage: avatarProvider,
                          child: avatarProvider == null
                              ? const Icon(Icons.person_rounded, size: 48, color: Colors.green)
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
                                backgroundColor: Colors.green.shade50,
                                foregroundColor: Colors.green,
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
                              initialDate: selectedBirthDate ?? DateTime(1995, 1, 1),
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
                        backgroundColor: Colors.green,
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
                            final error = context.read<UserViewModel>().errorMessage ?? "Profil güncellenemedi";
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text("GÜNCELLEMELERİ KAYDET", style: TextStyle(fontWeight: FontWeight.bold)),
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
                          "Eğitmen hesabınızı silmeniz durumunda tüm verileriniz ve hesabınız kalıcı olarak kaldırılacaktır.",
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

  Widget _buildMainActionCard({required VoidCallback onPressed, required IconData icon, required String title, required String subtitle, required Color color}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionTile({required VoidCallback onPressed, required IconData icon, required String label}) {
    return ListTile(
      onTap: onPressed,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.redAccent.withOpacity(0.05),
      leading: Icon(icon, color: Colors.redAccent),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    final unreadCount = context.watch<NotificationViewModel>().notifications.where((n) => !n.isRead).length;

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.black, size: 28),
          onPressed: () => _showNotifications(context),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text(
                unreadCount > 9 ? "9+" : "$unreadCount",
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          )
      ],
    );
  }

  void _showStartSessionDialog(BuildContext context) {
    final viewModel = context.read<TrainerScheduleViewModel>();
    final userData = context.read<LoginViewModel>().userData;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (dialogContext) => FutureBuilder(
        future: viewModel.fetchSchedule(userData?['userId'], start, end),
        builder: (context, snapshot) {
          final activeBookings = viewModel.bookings.where((b) => b.status == 'ACTIVE').toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.play_circle_fill_rounded, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text("Dersi Başlat", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 0,
                      color: Colors.green.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.green.shade200),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(dialogContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QrGeneratorScreen(bookingId: null),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Rezervasyonsuz QR Oluştur",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Üye okuttuğunda doğrudan 1 kredi düşer",
                                      style: TextStyle(fontSize: 11, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Colors.green),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Card(
                      elevation: 0,
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.blue.shade200),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(dialogContext);
                          _showDirectLessonMemberSelectDialog(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.person_search_rounded, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Üye Seçerek Başlat",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Listeden üye seçip anında başlatın",
                                      style: TextStyle(fontSize: 11, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Colors.blue),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    const Text(
                      "Bugünkü Randevulu Dersler",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),

                    if (viewModel.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (activeBookings.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Bugün için aktif randevulu ders bulunmuyor.",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeBookings.length,
                        itemBuilder: (context, index) {
                          final b = activeBookings[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.shade50,
                              child: const Icon(Icons.fitness_center_rounded, color: Colors.orange, size: 18),
                            ),
                            title: Text(b.memberName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(DateFormat('HH:mm').format(b.startTime), style: const TextStyle(fontSize: 11)),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => QrGeneratorScreen(bookingId: b.id)),
                                );
                              },
                              child: const Text("QR Aç", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Kapat"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDirectLessonMemberSelectDialog(BuildContext context) {
    final userData = context.read<LoginViewModel>().userData;
    final trainerId = userData?['userId'];
    final gymId = userData?['gymId'] ?? 0;

    if (trainerId == null) return;

    if (gymId > 0) {
      context.read<UserViewModel>().fetchUsers(gymId);
    }

    String searchQuery = "";

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final userVM = context.watch<UserViewModel>();
          final allMembers = userVM.users.where((u) => u.role == 'MEMBER' && u.isActive).toList();
          final filteredMembers = allMembers.where((u) {
            if (searchQuery.trim().isEmpty) return true;
            return u.fullName.toLowerCase().contains(searchQuery.toLowerCase().trim());
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.person_search_rounded, color: Colors.blue),
                SizedBox(width: 10),
                Text("Üye Seçerek Başlat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Üye ara...",
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (userVM.isLoading)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else if (filteredMembers.isEmpty)
                    const Expanded(
                      child: Center(child: Text("Uygun üye bulunamadı.", style: TextStyle(color: Colors.grey))),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: filteredMembers.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final member = filteredMembers[index];
                          final int? memberId = int.tryParse(member.id);
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Text(
                                member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : "Ü",
                                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(member.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(
                              member.assignedLessonType ?? "PT Bireysel",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: memberId == null
                                  ? null
                                  : () async {
                                      _confirmAndStartDirectLesson(dialogContext, trainerId, memberId, member.fullName);
                                    },
                              child: const Text("Başlat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Kapat"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmAndStartDirectLesson(BuildContext parentDialogContext, int trainerId, int memberId, String memberName) {
    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text("Ders Başlatılsın mı?"),
          ],
        ),
        content: Text(
          "$memberName ile rezervasyonsuz ders başlatılacak ve üyenin kredisinden 1 seans düşülecektir. Onaylıyor musunuz?",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(confirmContext);
              Navigator.pop(parentDialogContext);

              final result = await context.read<TrainerScheduleViewModel>().startDirectLesson(trainerId, memberId);

              if (mounted) {
                if (result['success'] == true) {
                  _loadData();
                  showDialog(
                    context: context,
                    builder: (successContext) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
                      content: Text(
                        result['message'] ?? "Ders başarıyla başlatıldı ve üyenin kredisinden 1 seans düşüldü! 🏋️‍♂️",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(successContext),
                          child: const Text("Tamam", style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? "Ders başlatılamadı."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Evet, Başlat", style: TextStyle(fontWeight: FontWeight.bold)),
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
                const Text("Bildirimler", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                ? const Center(child: Text("Bildirim yok."))
                : ListView.builder(
                    itemCount: vm.notifications.length,
                    itemBuilder: (context, index) {
                      final n = vm.notifications[index];
                      return ListTile(
                        leading: Icon(Icons.info_outline, color: n.isRead ? Colors.grey : Colors.blue),
                        title: Text(n.message, style: TextStyle(fontSize: 13, fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
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

  Widget _buildModernPendingBanner(BuildContext context, TrainerScheduleViewModel viewModel, int? trainerId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pending_actions_rounded, color: Colors.orange),
              const SizedBox(width: 10),
              Text("${viewModel.pendingApprovals.length} Yeni Onay Bekliyor",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          ...viewModel.pendingApprovals.take(2).map((b) => Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(b.memberName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(DateFormat('dd MMM HH:mm').format(b.startTime), style: const TextStyle(fontSize: 12)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => viewModel.approveBooking(b.id, trainerId!),
                    child: const Text("ONAYLA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      final success = await viewModel.rejectBooking(b.id, trainerId!);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Ders reddedildi ve yönetici onayına sevk edildi.")),
                        );
                      }
                    },
                    child: const Text("REDDET", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }
}
