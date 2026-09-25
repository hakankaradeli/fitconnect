import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../utils/image_utils.dart';
import 'qr_scanner_screen.dart';
import 'booking_screen.dart';
import 'nutrition_view.dart';
import 'widgets/survey_dialog.dart';
import '../widgets/announcement_board.dart';
import '../login_screen.dart';
import '../../services/api_service.dart';
import '../../view_models/login_view_model.dart';
import '../../view_models/calendar_view_model.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/notification_view_model.dart';
import '../../models/booking_details_model.dart';

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
        context.read<CalendarViewModel>().fetchMemberHistory(userId);
        context.read<NotificationViewModel>().fetchNotifications(userId);
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
        title: const Text("FitConnect", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.black, size: 28),
                onPressed: () => _showNotifications(context),
              ),
              if (context.watch<NotificationViewModel>().notifications.any((n) => !n.isRead))
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 10,
                    height: 10,
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
            icon: const Icon(Icons.logout_rounded, color: Colors.black),
            onPressed: () {
              ApiService.token = null;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
          const SizedBox(width: 8),
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
              const SizedBox(height: 12),
              _buildModernGreeting(userData),
              const SizedBox(height: 20),
              _buildModernCreditCard(),
              const SizedBox(height: 24),

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
                  const SizedBox(width: 12),
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
              
              const SizedBox(height: 12),

              _buildWideActionCard(
                onPressed: () => _showProposedLessonsSheet(context, proposedLessons, userData),
                icon: Icons.auto_awesome_rounded,
                label: "Onay Bekleyen Dersler",
                count: proposedLessons.length,
                color: Colors.orange,
              ),
              
              const SizedBox(height: 12),

              _buildWideActionCard(
                onPressed: () => _showEditCancelSheet(context, activeLessons, userData),
                icon: Icons.edit_calendar_rounded,
                label: "Ders Değişikliği ve İptal",
                color: const Color(0xFFFF5252),
              ),

              const SizedBox(height: 12),

              _buildWideActionCard(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MemberNutritionView())),
                icon: Icons.restaurant_rounded,
                label: "Beslenme Planım",
                color: Colors.teal,
              ),

              const SizedBox(height: 24),
              
              const AnnouncementBoard(),
              
              const SizedBox(height: 24),
              
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

  Widget _buildModernGreeting(Map<String, dynamic>? userData) {
    final String? photoUrl = userData?['profileImageUrl'];
    final String? instagram = userData?['instagram'];
    final String? linkedin = userData?['linkedin'];
    final String? twitter = userData?['twitter'];
    final imageProvider = getProfileImageProvider(photoUrl);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showProfileEditSheet(context, userData),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(Icons.person_rounded, size: 36, color: Colors.blue)
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
                        child: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Merhaba,", style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    Text(userData?['fullName'] ?? "Üye", 
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -0.5)),
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
          if ((instagram != null && instagram.isNotEmpty) ||
              (linkedin != null && linkedin.isNotEmpty) ||
              (twitter != null && twitter.isNotEmpty)) ...[
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (instagram != null && instagram.isNotEmpty)
                  _buildSocialChip(Icons.camera_alt_rounded, "@${instagram.replaceFirst(RegExp(r'^@+'), '')}", Colors.purple),
                if (linkedin != null && linkedin.isNotEmpty)
                  _buildSocialChip(Icons.work_rounded, linkedin, Colors.blue.shade700),
                if (twitter != null && twitter.isNotEmpty)
                  _buildSocialChip(Icons.alternate_email_rounded, twitter.replaceFirst(RegExp(r'^@+'), ''), Colors.black),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSocialChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _showProfileEditSheet(BuildContext context, Map<String, dynamic>? userData) {
    final photoController = TextEditingController(text: userData?['profileImageUrl'] ?? '');
    
    // Ad & Soyad
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
    final phoneController = TextEditingController(text: userData?['phone'] ?? '');
    final instaController = TextEditingController(text: userData?['instagram'] ?? '');
    final linkedinController = TextEditingController(text: userData?['linkedin'] ?? '');
    final twitterController = TextEditingController(text: userData?['twitter'] ?? '');
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
          return Container(
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
                  
                  // Fotoğraf
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
                              onPressed: () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? image = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 350,
                                  maxHeight: 350,
                                  imageQuality: 60,
                                );
                                if (image != null) {
                                  final bytes = await image.readAsBytes();
                                  final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
                                  setSheetState(() {
                                    photoController.text = base64Image;
                                  });
                                }
                              },
                              icon: const Icon(Icons.photo_library_rounded, size: 18),
                              label: const Text("Galeriden Fotoğraf Seç"),
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

                  // Kişisel Bilgiler
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
                  
                  // E-posta (Salt Okunur)
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

                  // Telefon
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Telefon Numarası",
                      hintText: "+90 5XX XXX XX XX",
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Doğum Tarihi & Cinsiyet
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
                  const Text("Sosyal Medya", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: instaController,
                    decoration: InputDecoration(labelText: "Instagram Kullanıcı Adı", hintText: "kullanici_adi", prefixIcon: const Icon(Icons.camera_alt_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: linkedinController,
                    decoration: InputDecoration(labelText: "LinkedIn Kullanıcı Adı / Bağlantı", hintText: "kullanici-adi", prefixIcon: const Icon(Icons.work_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: twitterController,
                    decoration: InputDecoration(labelText: "Twitter / X Kullanıcı Adı", hintText: "kullanici_adi", prefixIcon: const Icon(Icons.alternate_email_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                  ),

                  const SizedBox(height: 20),
                  
                  // Parola Değiştirme
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
                            instagram: instaController.text.trim().isEmpty ? null : instaController.text.trim(),
                            linkedin: linkedinController.text.trim().isEmpty ? null : linkedinController.text.trim(),
                            twitter: twitterController.text.trim().isEmpty ? null : twitterController.text.trim(),
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
                              'instagram': instaController.text.trim().isEmpty ? null : instaController.text.trim(),
                              'linkedin': linkedinController.text.trim().isEmpty ? null : linkedinController.text.trim(),
                              'twitter': twitterController.text.trim().isEmpty ? null : twitterController.text.trim(),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernCreditCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF2575FC).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Kalan Kredi", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                Text("8 Seans", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildActionCard({required VoidCallback onPressed, required IconData icon, required String label, required Color color}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildWideActionCard({required VoidCallback onPressed, required IconData icon, required String label, int? count, required Color color}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            if (count != null && count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Text("$count", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
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
    final statusColor = _getStatusColor(booking.status);
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

  // --- DİĞER YARDIMCI METODLAR (Düzeltilmiş) ---

  void _showEditCancelSheet(BuildContext context, List<BookingDetails> lessons, Map<String, dynamic>? userData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ders İşlemleri", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            if (lessons.isEmpty)
              const Center(child: Text("İşlem yapılabilecek aktif dersiniz yok."))
            else
              ...lessons.map((b) => _buildEditCancelItem(context, b, userData)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditCancelItem(BuildContext context, BookingDetails booking, Map<String, dynamic>? userData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade100), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.trainerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(DateFormat('dd/MM HH:mm').format(booking.startTime), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(onPressed: () => _showEditBookingDialog(context, booking), icon: const Icon(Icons.access_time_rounded, color: Colors.orange)),
          IconButton(onPressed: () => _handleBookingCancel(context, booking), icon: const Icon(Icons.cancel_rounded, color: Colors.red)),
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
                title: Text(DateFormat('dd MMMM HH:mm', 'tr').format(selectedTime)),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(selectedTime));
                    if (time != null) {
                      setDialogState(() => selectedTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    }
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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED': return Colors.green;
      case 'ACTIVE': return Colors.blue;
      case 'PENDING': return Colors.orange;
      case 'PROPOSED': return Colors.deepPurple;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
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
            const Text("Bildirimler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
