import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'qr_generator_screen.dart';
import 'trainer_schedule_view.dart';
import 'add_nutrition_view.dart';
import '../widgets/announcement_board.dart';
import '../login_screen.dart';
import '../admin/user_list_screen.dart';
import '../admin/trainer_list_screen.dart';
import '../admin/cancellation_reports_screen.dart';
import '../../services/api_service.dart';
import '../../view_models/login_view_model.dart';
import '../../view_models/trainer_schedule_view_model.dart';
import '../../view_models/notification_view_model.dart';

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
        context.read<TrainerScheduleViewModel>().fetchPendingApprovals(userData['userId']);
        context.read<NotificationViewModel>().fetchNotifications(userData['userId']);
      }
    });
  }

  bool _hasPermission(Map<String, dynamic>? userData, String perm) {
    if (userData == null) return false;
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
        title: const Text("Eğitmen Paneli", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          _buildNotificationIcon(context),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
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
          _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

              const SizedBox(height: 24),

              const AnnouncementBoard(),

              if (canManageUsers || canViewReports) ...[
                const SizedBox(height: 32),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem("Bugün", "4 Ders", Colors.blue),
          Container(width: 1, height: 40, color: Colors.grey.shade100),
          _buildStatItem("Hakediş", "1.250 Puan", Colors.green),
          Container(width: 1, height: 40, color: Colors.grey.shade100),
          _buildStatItem("Puan", "4.9", Colors.amber),
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
    return Stack(
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
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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
      builder: (context) => FutureBuilder(
        future: viewModel.fetchSchedule(userData?['userId'], start, end),
        builder: (context, snapshot) {
          if (viewModel.isLoading) return const Center(child: CircularProgressIndicator());
          final activeBookings = viewModel.bookings.where((b) => b.status == 'ACTIVE').toList();
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text("Ders Seçin", style: TextStyle(fontWeight: FontWeight.bold)),
            content: activeBookings.isEmpty
              ? const Text("Bugün için aktif dersiniz bulunmuyor.")
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: activeBookings.length,
                    itemBuilder: (context, index) {
                      final b = activeBookings[index];
                      return ListTile(
                        title: Text(b.memberName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('HH:mm').format(b.startTime)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => QrGeneratorScreen(bookingId: b.id)));
                        },
                      );
                    },
                  ),
                ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat"))],
          );
        },
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
            const Text("Bildirimler", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      if (success && mounted) {
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
