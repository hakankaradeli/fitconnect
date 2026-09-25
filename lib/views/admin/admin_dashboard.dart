import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'user_list_screen.dart';
import 'trainer_list_screen.dart';
import 'cancellation_reports_screen.dart';
import 'delegation_screen.dart';
import 'payment_management_screen.dart';
import 'finance_report_screen.dart';
import 'expense_management_screen.dart';
import 'bulk_message_screen.dart';
import 'member_detail_screen.dart';
import 'nutrition_reports_screen.dart';
import '../login_screen.dart';
import '../../services/api_service.dart';
import '../../view_models/login_view_model.dart';
import '../../view_models/trainer_schedule_view_model.dart';
import '../../view_models/calendar_view_model.dart';
import '../../models/booking_details_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    _loadAdminPending();
  }

  void _loadAdminPending() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null) {
        context.read<TrainerScheduleViewModel>().fetchAdminPendingBookings(userData['gymId']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduleVM = context.watch<TrainerScheduleViewModel>();
    final userData = context.read<LoginViewModel>().userData;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Yönetici Paneli", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
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
          _loadAdminPending();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAdminStats(),
                  const SizedBox(height: 24),

                  if (scheduleVM.adminPendingBookings.isNotEmpty)
                    _buildAdminPendingBanner(context, scheduleVM, userData),

                  const Text("Hızlı Erişim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth > 900 ? 6 : (constraints.maxWidth > 600 ? 4 : 2);
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.0,
                        children: [
                          _buildModernMenuCard(context, Icons.people_alt_rounded, "Üyeler", Colors.blue, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const UserListScreen()));
                          }),
                          _buildModernMenuCard(context, Icons.engineering_rounded, "Eğitmenler", Colors.green, () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const TrainerListScreen()));
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
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildMessageButton(context),
                ],
              ),
            ),
          ),
        ),
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
                            _loadAdminPending();
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
                            _loadAdminPending();
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

  Widget _buildAdminStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF5252), Color(0xFFFF1744)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatBox("Aktif Üye", "124", Colors.white),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatBox("Bugün", "18 Ders", Colors.white),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStatBox("Gelir", "₺42K", Colors.white),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildModernMenuCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const BulkMessageScreen()));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.message_rounded, color: Colors.blueGrey, size: 20),
            ),
            const SizedBox(width: 16),
            const Text("Üyelere Toplu Mesaj Gönder", style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
