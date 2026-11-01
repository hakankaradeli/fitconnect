import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'user_list_screen.dart';
import 'trainer_list_screen.dart';
import 'cancellation_reports_screen.dart';
import 'delegation_screen.dart';
import 'payment_management_screen.dart';
import 'finance_report_screen.dart';
import 'expense_management_screen.dart';
import 'bulk_message_screen.dart';
import 'admin_weekly_schedule_screen.dart';
import '../../constants/lesson_constants.dart';
import 'nutrition_reports_screen.dart';
import '../login_screen.dart';
import '../member/gym_card_screen.dart';
import '../../utils/image_utils.dart';
import '../../utils/currency_utils.dart';
import '../dashboard_router.dart';
import '../../view_models/login_view_model.dart';
import '../../view_models/trainer_schedule_view_model.dart';
import '../../view_models/calendar_view_model.dart';
import '../../view_models/theme_view_model.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/report_view_model.dart';
import '../../view_models/finance_view_model.dart';
import '../../models/finance_model.dart';
import '../../models/gym_branding_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null) {
        final gymId = userData['gymId'];
        if (gymId != null && gymId > 0) {
          context.read<ThemeViewModel>().fetchGymBranding(gymId);
        }
        context.read<TrainerScheduleViewModel>().fetchAdminPendingBookings(gymId);
        context.read<UserViewModel>().fetchUsers(gymId);
        context.read<ReportViewModel>().fetchMonthlyReport(gymId, DateTime.now().month);
        context.read<FinanceViewModel>().fetchAllInstallments(gymId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduleVM = context.watch<TrainerScheduleViewModel>();
    final financeVM = context.watch<FinanceViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final userData = context.read<LoginViewModel>().userData;

    final today = DateTime.now();
    final todayDueInstallments = financeVM.installments.where((p) =>
      p.status != PaymentStatus.paid &&
      p.dueDate.year == today.year &&
      p.dueDate.month == today.month &&
      p.dueDate.day == today.day
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadDashboardData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGymBrandingHeader(context, themeVM, userData),
                  const SizedBox(height: 20),
                  _buildAdminStats(themeVM),
                  const SizedBox(height: 24),

                  if (todayDueInstallments.isNotEmpty)
                    _buildAdminTodayPaymentsBanner(context, todayDueInstallments),

                  if (scheduleVM.adminPendingBookings.isNotEmpty)
                    _buildAdminPendingBanner(context, scheduleVM, userData),

                  const Text("Hızlı Erişim", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth > 900 ? 7 : (constraints.maxWidth > 600 ? 5 : 3);
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.05,
                        children: [
                          _buildModernMenuCard(context, Icons.people_alt_rounded, "Üyeler", Colors.blue, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const UserListScreen()));
                          }),
                          _buildModernMenuCard(context, Icons.engineering_rounded, "Eğitmenler", Colors.green, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const TrainerListScreen()));
                          }),
                          _buildModernMenuCard(context, Icons.calendar_month_rounded, "Haftalık Program", Colors.teal, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminWeeklyScheduleScreen()));
                          }),
                          _buildModernMenuCard(context, Icons.payments_rounded, "Gelirler", Colors.orange, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentManagementScreen()));
                          }),
                          _buildModernMenuCard(context, Icons.account_balance_wallet_rounded, "Giderler", Colors.redAccent, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpenseManagementScreen()));
                          }),
                          _buildModernMenuCard(context, Icons.bar_chart_rounded, "Raporlar", Colors.purple, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const FinanceReportScreen()));
                          }),
                          _buildModernMenuCard(context, Icons.report_problem_rounded, "İptaller", Colors.redAccent, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const CancellationReportsScreen()));
                          }),
                          _buildModernMenuCard(context, Icons.admin_panel_settings_rounded, "Yetki Devri", Colors.teal, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const DelegationScreen()));
                          }),
                          _buildModernMenuCard(context, Icons.restaurant_rounded, "Beslenme Raporları", Colors.indigo, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const NutritionReportsScreen()));
                          }),
                          _buildModernMenuCard(context, Icons.palette_rounded, "Kurumsal Kimlik", Colors.deepOrange, () async {
                            final gymId = userData?['gymId'];
                            if (gymId != null && gymId > 0) {
                              await context.read<ThemeViewModel>().fetchGymBranding(gymId);
                            }
                            if (context.mounted) {
                              _showBrandingSettingsSheet(context, userData);
                            }
                          }),
                          _buildModernMenuCard(context, Icons.access_time_filled_rounded, "Çalışma Saatleri", Colors.blueGrey, () async {
                            final gymId = userData?['gymId'];
                            if (gymId != null && gymId > 0) {
                              await context.read<ThemeViewModel>().fetchGymBranding(gymId);
                            }
                            if (context.mounted) {
                              _showWorkingHoursSheet(context, userData);
                            }
                          }),
                          _buildModernMenuCard(context, Icons.campaign_rounded, "Toplu Mesaj", Colors.deepPurple, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const BulkMessageScreen()));
                          }),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  if (userData?['role'] == 'SUPER_ADMIN' || userData?['role'] == 'ADMIN' || (userData?['canTeach'] != null && (userData?['canTeach'] as List).isNotEmpty))
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardRouter(role: "TRAINER")));
                        },
                        icon: const Icon(Icons.fitness_center_rounded, size: 22),
                        label: const Text("EĞİTMEN PROFİLİNE GEÇ", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildAdminTodayPaymentsBanner(BuildContext context, List<PaymentPlan> installments) {
    final double totalAmount = installments.fold(0.0, (sum, p) => sum + p.amount);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: Colors.orange, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Bugün Ödemesi Olan Üyeler (${installments.length} Kişi • ${formatCurrency(totalAmount)})",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentManagementScreen()));
                },
                child: const Text("Tümünü Gör", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...installments.map((plan) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("• ${plan.memberName}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(formatCurrency(plan.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildAdminPendingBanner(BuildContext context, TrainerScheduleViewModel scheduleVM, Map<String, dynamic>? userData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, color: Colors.redAccent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "${scheduleVM.adminPendingBookings.length} Ders Yönetici Onayı Bekliyor",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...scheduleVM.adminPendingBookings.map((b) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 18, color: Colors.redAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b.memberName,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.engineering_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Reddeden Eğitmen: ${b.trainerName}",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(b.startTime),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final success = await context.read<CalendarViewModel>().approveBooking(b.id);
                          if (success && mounted) {
                            _loadDashboardData();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ders yönetici tarafından onaylandı.")));
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: const Text("ONAYLA", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final success = await context.read<CalendarViewModel>().rejectBooking(
                            b.id,
                            cancelledById: userData?['userId'],
                            reason: "Yönetici tarafından kesin iptal edildi"
                          );
                          if (success && mounted) {
                            _loadDashboardData();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ders kesin olarak iptal edildi.")));
                          }
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text("KESİN İPTAL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildGymBrandingHeader(BuildContext context, ThemeViewModel themeVM, Map<String, dynamic>? userData) {
    final String gymName = themeVM.gymName.isNotEmpty
        ? themeVM.gymName
        : (userData?['gymName']?.toString().isNotEmpty == true ? userData!['gymName'] : "CAT GYM");
    final Color primary = themeVM.primaryColor;

    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const GymCardScreen()));
                },
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E282A),
                    border: Border.all(color: primary, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: getGymLogoWidget(
                      themeVM.gymLogo,
                      width: 80,
                      height: 80,
                      fallbackColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                gymName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 0,
          top: 18,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.black87, size: 22),
              tooltip: "Çıkış Yap",
              onPressed: () async {
                await context.read<LoginViewModel>().logout();
                if (context.mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminStats(ThemeViewModel themeVM) {
    final userVM = context.watch<UserViewModel>();
    final reportVM = context.watch<ReportViewModel>();
    final financeVM = context.watch<FinanceViewModel>();
    final gymId = context.read<LoginViewModel>().userData?['gymId'];

    final activeMemberCount = userVM.users.where((u) {
      final bool isMember = u.role.toUpperCase() == 'MEMBER';
      final bool isActive = u.isActive ?? true;
      final bool matchesGym = gymId == null || u.gymId == null || u.gymId == gymId.toString();
      return isMember && isActive && matchesGym;
    }).length;

    final attendanceStats = reportVM.monthlyReport?['attendanceStats'];
    final int completedLessons = attendanceStats?['completedLessons'] ?? 0;
    final int todayLessons = attendanceStats?['todayLessons'] ?? 0;
    final int todayCompleted = attendanceStats?['todayCompletedLessons'] ?? 0;

    double revenueNum = 0.0;
    final paidInstallmentsSum = financeVM.installments
        .where((i) => i.status == PaymentStatus.paid)
        .fold(0.0, (sum, i) => sum + i.amount);

    if (paidInstallmentsSum > 0) {
      revenueNum = paidInstallmentsSum;
    } else {
      final dynamic reportVal = reportVM.monthlyReport?['financeSummary']?['totalRevenue'];
      revenueNum = reportVal != null ? (double.tryParse(reportVal.toString()) ?? 0.0) : 0.0;
    }

    final String revenueText = formatCurrency(revenueNum);

    final primary = themeVM.primaryColor;
    final secondary = themeVM.secondaryColor;
    final bool isGradient = themeVM.isGradient;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isGradient
              ? [primary, secondary]
              : [primary, primary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _buildStatBox("Aktif Üye", "$activeMemberCount", Colors.white)),
          Container(width: 1, height: 36, color: Colors.white24),
          Expanded(
            child: _buildStatBox(
              "Bugünkü Ders",
              todayLessons > 0 ? "$todayCompleted/$todayLessons Ders" : "$todayLessons Ders",
              Colors.white,
            ),
          ),
          Container(width: 1, height: 36, color: Colors.white24),
          Expanded(child: _buildStatBox("Yapılan Ders", "$completedLessons Ders", Colors.white)),
          Container(width: 1, height: 36, color: Colors.white24),
          Expanded(child: _buildStatBox("Gelir", revenueText, Colors.white)),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(color: color.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildModernMenuCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showBrandingSettingsSheet(BuildContext context, Map<String, dynamic>? userData) {
    final themeVM = context.read<ThemeViewModel>();
    final gymId = userData?['gymId'];

    final nameController = TextEditingController(text: themeVM.gymName.isNotEmpty ? themeVM.gymName : (userData?['gymName'] ?? ''));
    final addressController = TextEditingController(text: themeVM.address ?? '');
    final phoneController = TextEditingController(text: themeVM.phone ?? '');
    final instagramController = TextEditingController(text: themeVM.instagram ?? '');
    final emailController = TextEditingController(text: themeVM.email ?? '');
    final websiteController = TextEditingController(text: themeVM.website ?? '');
    final logoController = TextEditingController(text: (themeVM.gymLogo != null && themeVM.gymLogo!.isNotEmpty) ? themeVM.gymLogo! : (userData?['logoUrl'] ?? ''));
    String selectedColorHex = themeVM.branding?.primaryColorHex ?? userData?['primaryColor'] ?? '#1B6B55';
    String selectedSecondaryHex = themeVM.branding?.secondaryColorHex ?? (ThemeGradientPreset.findByHex(selectedColorHex)?.endHex ?? '#00BFA5');
    bool isGradient = themeVM.isGradient;
    String? selectedGradientId = ThemeGradientPreset.findByHex(selectedColorHex, endHex: selectedSecondaryHex)?.id ?? "emerald";
    final List<String> selectedOfferedGroups = List<String>.from(
      themeVM.offeredLessonGroups.isNotEmpty
          ? themeVM.offeredLessonGroups
          : (userData?['offeredLessonGroups'] is List
              ? List<String>.from(userData!['offeredLessonGroups'])
              : LessonConstants.mainGroups),
    );

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
        builder: (sheetContext, setSheetState) => Container(
          height: MediaQuery.of(sheetContext).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  const Icon(Icons.badge_rounded, color: Colors.indigo, size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Salon Kartı & Kurumsal Kimlik",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const Divider(height: 18),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Salon Logosu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: getGymLogoWidget(
                            logoController.text.trim().isNotEmpty
                                ? logoController.text.trim()
                                : themeVM.gymLogo,
                            height: 80,
                            width: 80,
                            fallbackColor: Colors.indigo,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
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
                              logoController.text = base64Logo;
                            });
                          }
                        },
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: const Text("Galeriden Logo Seç"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade50,
                          foregroundColor: Colors.indigo,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text("Salon Kartı İletişim Bilgileri", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),

                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Salon Adı",
                    hintText: "Örn: CAT GYM",
                    prefixIcon: const Icon(Icons.fitness_center_rounded, color: Colors.indigo, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "Salon Adresi",
                    hintText: "Mahalle, Cadde/Sokak, İlçe / İl",
                    prefixIcon: const Icon(Icons.location_on_rounded, color: Colors.indigo, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Telefon / WhatsApp Numarası",
                    hintText: "+90 532 000 00 00",
                    prefixIcon: const Icon(Icons.phone_rounded, color: Colors.indigo, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: instagramController,
                  decoration: InputDecoration(
                    labelText: "Instagram Hesabı",
                    hintText: "catgym_official",
                    prefixText: "@",
                    prefixIcon: const Icon(Icons.camera_alt_rounded, color: Colors.indigo, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "İletişim E-posta Adresi",
                    hintText: "info@catgym.com",
                    prefixIcon: const Icon(Icons.email_rounded, color: Colors.indigo, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: websiteController,
                  decoration: InputDecoration(
                    labelText: "Web Sitesi (Opsiyonel)",
                    hintText: "www.catgym.com",
                    prefixIcon: const Icon(Icons.language_rounded, color: Colors.indigo, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 24),
                const Text("Kurumsal Tema Rengi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                Icon(Icons.palette_outlined, size: 18, color: !isGradient ? Colors.indigo : Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Text(
                                  "Düz Renk",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: !isGradient ? FontWeight.bold : FontWeight.w600,
                                    color: !isGradient ? Colors.indigo : Colors.grey.shade600,
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
                                Icon(Icons.gradient_rounded, size: 18, color: isGradient ? Colors.indigo : Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Text(
                                  "Gradyan ✨",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isGradient ? FontWeight.bold : FontWeight.w600,
                                    color: isGradient ? Colors.indigo : Colors.grey.shade600,
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
                    spacing: 10,
                    runSpacing: 10,
                    children: presetColors.map((colorMap) {
                      final hex = colorMap['hex']!;
                      final isSelected = selectedColorHex.toUpperCase() == hex.toUpperCase();
                      final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));

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
                            color: isSelected ? Colors.indigo.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.indigo : Colors.grey.shade300,
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
                                  color: isSelected ? Colors.indigo.shade900 : Colors.black87,
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
                const Text("Salonunuzda Verilen Ders Grupları", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LessonConstants.mainGroups.map((group) {
                    final isSelected = selectedOfferedGroups.contains(group);
                    return FilterChip(
                      label: Text(group, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      selected: isSelected,
                      selectedColor: Colors.indigo.shade100,
                      onSelected: (val) {
                        setSheetState(() {
                          if (val) {
                            selectedOfferedGroups.add(group);
                          } else {
                            if (selectedOfferedGroups.length > 1) {
                              selectedOfferedGroups.remove(group);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      if (gymId != null) {
                        final success = await context.read<ThemeViewModel>().updateGymBranding(
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
                          logoUrl: logoController.text.trim(),
                          offeredLessonGroups: selectedOfferedGroups,
                        );

                        if (success && sheetContext.mounted) {
                          context.read<LoginViewModel>().updateUserData({
                            'gymName': nameController.text.trim(),
                            'primaryColor': selectedColorHex,
                            'secondaryColor': selectedSecondaryHex,
                            'isGradient': isGradient,
                            'logoUrl': logoController.text.trim(),
                            'offeredLessonGroups': selectedOfferedGroups,
                          });
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(content: Text("Salon kartı ve kurumsal kimlik bilgileri güncellendi.")),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text("KAYDET VE UYGULA"),
                  ),
                ),
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

  void _showWorkingHoursSheet(BuildContext context, Map<String, dynamic>? userData) {
    if (userData == null) return;

    final themeVM = context.read<ThemeViewModel>();

    List<int> selectedDays = themeVM.workingDays.split(',').map((e) => int.tryParse(e) ?? 1).toList();
    TimeOfDay openTime = TimeOfDay(
      hour: int.tryParse(themeVM.openTime.split(':')[0]) ?? 7,
      minute: int.tryParse(themeVM.openTime.split(':')[1]) ?? 0,
    );
    TimeOfDay closeTime = TimeOfDay(
      hour: int.tryParse(themeVM.closeTime.split(':')[0]) ?? 22,
      minute: int.tryParse(themeVM.closeTime.split(':')[1]) ?? 0,
    );
    final maxCancelController = TextEditingController(text: themeVM.maxCancellationsAllowed.toString());

    final weekdays = [
      {'val': 1, 'label': 'Pzt'},
      {'val': 2, 'label': 'Sal'},
      {'val': 3, 'label': 'Çar'},
      {'val': 4, 'label': 'Per'},
      {'val': 5, 'label': 'Cum'},
      {'val': 6, 'label': 'Cmt'},
      {'val': 7, 'label': 'Paz'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Container(
            height: MediaQuery.of(sheetContext).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
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
                    const Icon(Icons.schedule_rounded, color: Colors.blueGrey, size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Çalışma Saatleri & Kurallar",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Randevuların, çalışma günlerinin ve ders yakma kurallarının sınırlarını belirler.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const Divider(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text("Açık Olduğu Günler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: weekdays.map((w) {
                      final isSelected = selectedDays.contains(w['val']);
                      return FilterChip(
                        label: Text(w['label'] as String),
                        selected: isSelected,
                        selectedColor: Colors.blueGrey.shade100,
                        onSelected: (selected) {
                          setSheetState(() {
                            if (selected) {
                              selectedDays.add(w['val'] as int);
                            } else {
                              selectedDays.remove(w['val'] as int);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  const Text("Çalışma Saatleri", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Açılış Saati", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: openTime.hour,
                                  isExpanded: true,
                                  icon: const Icon(Icons.access_time_rounded, color: Colors.blueGrey, size: 20),
                                  items: List.generate(24, (index) {
                                    return DropdownMenuItem(
                                      value: index,
                                      child: Text("${index.toString().padLeft(2, '0')}:00", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    );
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setSheetState(() => openTime = TimeOfDay(hour: val, minute: 0));
                                    }
                                  },
                                ),
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
                            const Text("Kapanış Saati", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: closeTime.hour,
                                  isExpanded: true,
                                  icon: const Icon(Icons.access_time_rounded, color: Colors.blueGrey, size: 20),
                                  items: List.generate(24, (index) {
                                    return DropdownMenuItem(
                                      value: index,
                                      child: Text("${index.toString().padLeft(2, '0')}:00", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    );
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setSheetState(() => closeTime = TimeOfDay(hour: val, minute: 0));
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text("Ders Yakma & İptal Kotası", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: maxCancelController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Yoğun saatlerde izin verilen max iptal hakkı",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      if (selectedDays.isEmpty) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text("Lütfen en az 1 gün seçiniz.")));
                        return;
                      }

                      final daysStr = selectedDays.join(",");
                      final oTimeStr = "${openTime.hour.toString().padLeft(2, '0')}:${openTime.minute.toString().padLeft(2, '0')}";
                      final cTimeStr = "${closeTime.hour.toString().padLeft(2, '0')}:${closeTime.minute.toString().padLeft(2, '0')}";
                      final maxCancel = int.tryParse(maxCancelController.text.trim()) ?? 4;

                      final success = await themeVM.updateWorkingHours(
                        userData['gymId'],
                        daysStr,
                        oTimeStr,
                        cTimeStr,
                        maxCancel,
                      );

                      if (success && sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text("Salon kuralları ve çalışma saatleri başarıyla kaydedildi.")));
                      } else if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text("Hata oluştu.")));
                      }
                    },
                    child: const Text("KAYDET"),
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
}
