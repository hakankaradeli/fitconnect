import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/super_admin_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../utils/formatters.dart';
import '../login_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<SuperAdminViewModel>();
      vm.fetchGyms();
      vm.fetchStats();
      vm.fetchUnassignedUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final saVM = context.watch<SuperAdminViewModel>();
    final stats = saVM.stats;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("SaaS Ana Yönetici", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_rounded, color: Colors.indigo),
            tooltip: "Şifre Değiştir",
            onPressed: () => _showChangePasswordDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        onPressed: () => _showAddGymSheet(context),
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text("YENİ SPOR SALONU EKLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: saVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await saVM.fetchGyms();
                await saVM.fetchStats();
                await saVM.fetchUnassignedUsers();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (saVM.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text(saVM.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                            IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.red), onPressed: _loadData),
                          ],
                        ),
                      ),
                    _buildStatsCard(stats),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () => _showAuditReportsSheet(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.indigo.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.indigo.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_user_rounded, color: Colors.indigo, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Yasal Denetim & IP/Cihaz Raporları",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Kayıt onayları, IP/Cihaz logları ve 200 günlük silinenler arşivi",
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.indigo),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (saVM.unassignedUsers.isNotEmpty) ...[
                      InkWell(
                        onTap: () => _showUnassignedUsersSheet(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amber.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_add_disabled_rounded, color: Colors.orange, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Salon Kaydı Olmayan Kullanıcılar",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "QR ile atanmayı bekleyen ${saVM.unassignedUsers.length} kullanıcı",
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${saVM.unassignedUsers.length}",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.orange),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text("Kayıtlı Spor Salonları (${saVM.gyms.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (saVM.gyms.isEmpty)
                      const Center(child: Text("Kayıtlı spor salonu bulunmamaktadır."))
                    else
                      ...saVM.gyms.map((gym) => _buildGymCard(context, gym)).toList(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  void _showUnassignedUsersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final saVM = sheetContext.watch<SuperAdminViewModel>();
        final users = saVM.unassignedUsers;

        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.person_add_disabled_rounded, color: Colors.orange, size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Salon Kaydı Olmayan Kullanıcılar (${users.length})",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              Expanded(
                child: users.isEmpty
                    ? const Center(child: Text("Salon kaydı olmayan kullanıcı bulunmuyor."))
                    : ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index] as Map<String, dynamic>;
                          return _buildUnassignedUserCard(context, user);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAuditReportsSheet(BuildContext context) {
    context.read<SuperAdminViewModel>().fetchAuditReports();
    String searchQuery = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final saVM = sheetContext.watch<SuperAdminViewModel>();
        final consentLogs = saVM.auditConsentLogs;
        final deletedArchives = saVM.auditDeletedArchives;

        final filteredConsent = consentLogs.where((log) {
          final query = searchQuery.toLowerCase().trim();
          if (query.isEmpty) return true;
          return (log['userEmail'] ?? '').toString().toLowerCase().contains(query) ||
                 (log['userFullName'] ?? '').toString().toLowerCase().contains(query) ||
                 (log['ipAddress'] ?? '').toString().toLowerCase().contains(query);
        }).toList();

        final filteredDeleted = deletedArchives.where((archive) {
          final query = searchQuery.toLowerCase().trim();
          if (query.isEmpty) return true;
          return (archive['userEmail'] ?? '').toString().toLowerCase().contains(query) ||
                 (archive['userFullName'] ?? '').toString().toLowerCase().contains(query) ||
                 (archive['deleteIpAddress'] ?? '').toString().toLowerCase().contains(query);
        }).toList();

        return DefaultTabController(
          length: 2,
          child: Container(
            height: MediaQuery.of(sheetContext).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Colors.indigo, size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Yasal Denetim & IP/Cihaz Raporları",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                StatefulBuilder(
                  builder: (context, setSearchState) {
                    return TextField(
                      decoration: InputDecoration(
                        labelText: "E-posta, İsim veya IP Adresi İle Ara",
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.indigo),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setSearchState(() {
                          searchQuery = val;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),

                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: Colors.indigo,
                  indicatorColor: Colors.indigo,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: [
                    Tab(text: "📋 Kayıt & İzin Logları (${filteredConsent.length})"),
                    Tab(text: "🗑️ 200 Günlük Silinenler (${filteredDeleted.length})"),
                  ],
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: TabBarView(
                    children: [
                      filteredConsent.isEmpty
                          ? const Center(child: Text("Kayıt logu bulunamadı."))
                          : ListView.builder(
                              itemCount: filteredConsent.length,
                              itemBuilder: (context, index) {
                                final log = filteredConsent[index] as Map<String, dynamic>;
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    dense: true,
                                    title: Text("${log['userFullName']} (${log['userEmail']})", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("🌐 IP: ${log['ipAddress']} • Cihaz: ${log['deviceInfo']}", style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                                        Text("🕒 Tarih: ${log['createdAt']}", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 4,
                                          children: [
                                            if (log['termsAccepted'] == true)
                                              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)), child: Text("Kullanım Koşulları ✓", style: TextStyle(fontSize: 9, color: Colors.green.shade800, fontWeight: FontWeight.bold))),
                                            if (log['healthDataConsentAccepted'] == true)
                                              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)), child: Text("Sağlık Açık Rıza ✓", style: TextStyle(fontSize: 9, color: Colors.purple.shade800, fontWeight: FontWeight.bold))),
                                            if (log['marketingConsentAccepted'] == true)
                                              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)), child: Text("İletişim İzni ✓", style: TextStyle(fontSize: 9, color: Colors.blue.shade800, fontWeight: FontWeight.bold))),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                      filteredDeleted.isEmpty
                          ? const Center(child: Text("Silinmiş hesap arşivi bulunamadı."))
                          : ListView.builder(
                              itemCount: filteredDeleted.length,
                              itemBuilder: (context, index) {
                                final archive = filteredDeleted[index] as Map<String, dynamic>;
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    dense: true,
                                    title: Text("${archive['userFullName']} (${archive['userEmail']})", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Rol: ${archive['role']} • Salon: ${archive['gymName']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                        Text("🌐 Silinme IP: ${archive['deleteIpAddress']} • Cihaz: ${archive['deleteDeviceInfo']}", style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                                        Text("🕒 Silinme Tarihi: ${archive['deletedAt']}", style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                                          child: Text("200 Günlük Saklama Bitiş Tarihi: ${archive['retentionPurgeDate']}", style: TextStyle(fontSize: 10, color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statBox("Toplam Salon", "${stats['totalGyms'] ?? 0}"),
          Container(width: 1, height: 40, color: Colors.white24),
          _statBox("Aktif Salon", "${stats['activeGyms'] ?? 0}"),
          Container(width: 1, height: 40, color: Colors.white24),
          _statBox("Toplam Kullanıcı", "${stats['totalUsers'] ?? 0}"),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildUnassignedUserCard(BuildContext context, Map<String, dynamic> user) {
    final String role = user['role'] ?? "MEMBER";
    final String roleText = role == "TRAINER" ? "Eğitmen / Antrenör" : "Spor Üyesi";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.amber.shade100,
            child: Icon(role == "TRAINER" ? Icons.sports_rounded : Icons.person_rounded, color: Colors.orange.shade800),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['fullName'] ?? "Kullanıcı", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("${user['email'] ?? ''} • ${formatPhoneNumber(user['phone'])}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(roleText, style: TextStyle(color: Colors.blue.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                      child: const Text("Salon Kaydı Yok", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            tooltip: "Kullanıcıyı Sil",
            onPressed: () => _confirmDeleteUnassignedUser(context, user),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUnassignedUser(BuildContext context, Map<String, dynamic> user) {
    final int userId = user['id'] is int
        ? user['id']
        : int.parse(user['id'].toString());
    final String fullName = user['fullName'] ?? 'Kullanıcı';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Kullanıcı Silme Onayı"),
        content: Text("$fullName isimli salon kaydı bulunmayan kullanıcı hesabını silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await context.read<SuperAdminViewModel>().deleteUnassignedUser(userId);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$fullName hesabı başarıyla silindi.")),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Kullanıcı silinirken bir hata oluştu.")),
                );
              }
            },
            child: const Text("EVET, SİL"),
          ),
        ],
      ),
    );
  }

  Widget _buildGymCard(BuildContext context, Map<String, dynamic> gym) {
    final bool isActive = gym['isActive'] ?? true;
    final String colorHex = gym['primaryColor'] ?? '#3F51B5';

    Color themeColor;
    try {
      themeColor = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      themeColor = Colors.indigo;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: themeColor.withOpacity(0.1),
                child: Icon(Icons.fitness_center_rounded, color: themeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gym['gymName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text("Yönetici: ${gym['adminEmail'] ?? 'Tanımsız'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text("Üye: ${gym['memberCount']} | Eğitmen: ${gym['trainerCount']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: (isActive ? Colors.green : Colors.red).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(isActive ? "AKTİF" : "PASİF", style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: isActive ? Colors.orange.shade800 : Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => context.read<SuperAdminViewModel>().toggleGymStatus(gym['gymId']),
                icon: Icon(isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded, size: 16),
                label: Text(isActive ? "Dondur" : "Aktifleştir", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  side: BorderSide(color: Colors.indigo.shade200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _showEditGymSheet(context, gym),
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: const Text("Düzenle", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _confirmDeleteGymDialog(context, gym),
                icon: const Icon(Icons.delete_outline_rounded, size: 15),
                label: const Text("Sil", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditGymSheet(BuildContext context, Map<String, dynamic> gym) {
    final gymNameController = TextEditingController(text: gym['gymName'] ?? '');
    final colorController = TextEditingController(text: gym['primaryColor'] ?? '#3F51B5');
    final addressController = TextEditingController(text: gym['address'] ?? '');
    final logoController = TextEditingController(text: gym['logoUrl'] ?? '');
    final adminNameController = TextEditingController(text: gym['adminFullName'] ?? '');
    final adminEmailController = TextEditingController(text: gym['adminEmail'] ?? '');
    final adminPasswordController = TextEditingController();
    final adminPhoneController = TextEditingController(text: gym['adminPhone'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  const Text("Salon Bilgilerini Düzenle", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Salon Bilgileri", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo)),
              const SizedBox(height: 8),
              TextField(
                controller: gymNameController,
                decoration: InputDecoration(labelText: "Spor Salonu Adı", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colorController,
                decoration: InputDecoration(labelText: "Kurumsal Hex Rengi", hintText: "#3F51B5", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: "Adres (Opsiyonel)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: logoController,
                decoration: InputDecoration(labelText: "Logo URL / Görsel", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 20),

              const Text("Salon Yöneticisi (Admin) Hesabı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo)),
              const SizedBox(height: 8),
              TextField(
                controller: adminNameController,
                decoration: InputDecoration(labelText: "Yönetici Ad Soyad", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adminEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: "Yönetici E-posta", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adminPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Yeni Şifre (Değiştirmek istemiyorsanız boş bırakın)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adminPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: "Yönetici Telefon", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
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
                    if (gymNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen salon adını girin.")));
                      return;
                    }

                    final success = await context.read<SuperAdminViewModel>().updateGym(
                      gymId: gym['gymId'],
                      gymName: gymNameController.text.trim(),
                      primaryColor: colorController.text.trim().isEmpty ? "#3F51B5" : colorController.text.trim(),
                      logoUrl: logoController.text.trim().isEmpty ? null : logoController.text.trim(),
                      address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                      adminFullName: adminNameController.text.trim().isEmpty ? null : adminNameController.text.trim(),
                      adminEmail: adminEmailController.text.trim().isEmpty ? null : adminEmailController.text.trim(),
                      adminPassword: adminPasswordController.text.trim().isEmpty ? null : adminPasswordController.text.trim(),
                      adminPhone: adminPhoneController.text.trim().isEmpty ? null : formatPhoneNumber(adminPhoneController.text.trim()),
                    );

                    if (success && mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Salon ve yönetici bilgileri güncellendi.")));
                    }
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text("GÜNCELLEMELERİ KAYDET"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteGymDialog(BuildContext context, Map<String, dynamic> gym) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Salonu Sil"),
        content: Text("${gym['gymName']} salonunu ve salona bağlı tüm üye/eğitmen verilerini silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final success = await context.read<SuperAdminViewModel>().deleteGym(gym['gymId']);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Salon ve bağlı verileri silindi.")));
              }
            },
            child: const Text("SİL"),
          ),
        ],
      ),
    );
  }

  void _showAddGymSheet(BuildContext context) {
    final gymNameController = TextEditingController();
    final colorController = TextEditingController(text: "#3F51B5");
    final addressController = TextEditingController();
    final adminNameController = TextEditingController();
    final adminEmailController = TextEditingController();
    final adminPasswordController = TextEditingController();
    final adminPhoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  const Text("Yeni Spor Salonu Tanıt", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Salon Bilgileri", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo)),
              const SizedBox(height: 8),
              TextField(
                controller: gymNameController,
                decoration: InputDecoration(labelText: "Spor Salonu Adı", hintText: "Örn: Gold Fitness Club", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colorController,
                decoration: InputDecoration(labelText: "Kurumsal Renk (Hex Kodu)", hintText: "#3F51B5", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: "Adres (Opsiyonel)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 20),

              const Text("Salon Yöneticisi (Admin) Hesabı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo)),
              const SizedBox(height: 8),
              TextField(
                controller: adminNameController,
                decoration: InputDecoration(labelText: "Yönetici Ad Soyad", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adminEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: "Yönetici E-posta", hintText: "admin@salondomain.com", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adminPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Yönetici Şifre", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adminPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: "Yönetici Telefon", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
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
                    if (gymNameController.text.trim().isEmpty ||
                        adminEmailController.text.trim().isEmpty ||
                        adminPasswordController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen zorunlu alanları doldurun.")));
                      return;
                    }

                    final success = await context.read<SuperAdminViewModel>().createGym(
                      gymName: gymNameController.text.trim(),
                      primaryColor: colorController.text.trim().isEmpty ? "#3F51B5" : colorController.text.trim(),
                      address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                      adminFullName: adminNameController.text.trim(),
                      adminEmail: adminEmailController.text.trim(),
                      adminPassword: adminPasswordController.text.trim(),
                      adminPhone: adminPhoneController.text.trim().isEmpty ? null : formatPhoneNumber(adminPhoneController.text.trim()),
                    );

                    if (success && mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yeni spor salonu ve yöneticisi oluşturuldu.")));
                    } else if (mounted) {
                      final errorMsg = context.read<SuperAdminViewModel>().errorMessage ?? "Hata oluştu.";
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
                    }
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text("SALONU OLUŞTUR VE YAYINLA"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;
    String? localError;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_reset_rounded, color: Colors.indigo, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Şifre Değiştir",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Süper yönetici hesabınızın şifresini güvenli bir şekilde güncelleyin.",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    if (localError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                localError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    TextFormField(
                      controller: currentPasswordCtrl,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: "Mevcut Şifre",
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Mevcut şifrenizi giriniz";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: newPasswordCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: "Yeni Şifre",
                        helperText: "En az 6 karakter",
                        prefixIcon: const Icon(Icons.key_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Yeni şifrenizi giriniz";
                        }
                        if (val.trim().length < 6) {
                          return "Şifre en az 6 karakter olmalıdır";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: confirmPasswordCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: "Yeni Şifre (Tekrar)",
                        prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Yeni şifrenizi tekrar giriniz";
                        }
                        if (val.trim() != newPasswordCtrl.text.trim()) {
                          return "Şifreler eşleşmiyor";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: const Text("İptal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          isSubmitting = true;
                          localError = null;
                        });

                        final saVM = context.read<SuperAdminViewModel>();
                        final err = await saVM.changePassword(
                          currentPasswordCtrl.text.trim(),
                          newPasswordCtrl.text.trim(),
                        );

                        if (!dialogCtx.mounted) return;

                        if (err == null) {
                          Navigator.pop(dialogCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Süper yönetici şifreniz başarıyla güncellendi."),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          setDialogState(() {
                            isSubmitting = false;
                            localError = err;
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("GÜNCELLE"),
              ),
            ],
          );
        },
      ),
    );
  }
}
