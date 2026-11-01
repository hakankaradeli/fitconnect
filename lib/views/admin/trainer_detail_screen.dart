import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../view_models/user_view_model.dart';
import '../../constants/lesson_constants.dart';
import '../trainer/trainer_schedule_view.dart';
import 'member_detail_screen.dart';
import 'trainer_rates_screen.dart';
import '../../utils/formatters.dart';
import '../../view_models/theme_view_model.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_back_button.dart';

class TrainerDetailScreen extends StatefulWidget {
  final UserModel trainer;

  const TrainerDetailScreen({super.key, required this.trainer});

  @override
  State<TrainerDetailScreen> createState() => _TrainerDetailScreenState();
}

class _TrainerDetailScreenState extends State<TrainerDetailScreen> {
  late UserModel _currentTrainer;
  Map<String, dynamic>? _trainerStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _currentTrainer = widget.trainer;
    _refreshTrainer();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final vm = context.read<UserViewModel>();
    final stats = await vm.getTrainerStats(int.parse(_currentTrainer.id));
    if (mounted) {
      setState(() {
        _trainerStats = stats;
        _isLoadingStats = false;
      });
    }
  }

  void _refreshTrainer() {
    final vm = context.read<UserViewModel>();
    try {
      setState(() {
        _currentTrainer = vm.users.firstWhere((u) => u.id == widget.trainer.id);
      });
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final userVM = context.watch<UserViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final primaryColor = themeVM.primaryColor;
    final onPrimary = themeVM.onPrimaryColor;

    _refreshTrainer();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentTrainer.fullName,
          style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: primaryColor.computeLuminance() > 0.45
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        leading: CustomBackButton(
          color: onPrimary,
          backgroundColor: onPrimary.withValues(alpha: 0.18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildLeaveInfo(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrainerScheduleView(trainerId: int.parse(_currentTrainer.id)),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_month, color: Colors.white),
                label: const Text("DERS PROGRAMINI GÖRÜNTÜLE", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrainerRatesScreen(trainer: _currentTrainer),
                    ),
                  );
                },
                icon: const Icon(Icons.payments, color: Colors.white),
                label: const Text("HAKEDİŞ TARİFELERİNİ DÜZENLE", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () => _showEditCanTeachDialog(context),
                icon: const Icon(Icons.tune_rounded, color: Colors.white),
                label: const Text("DERS TÜRLERİNİ DÜZENLE", style: TextStyle(color: Colors.white)),
              ),
            ),
            _buildStatsSection(),
            _buildAssignedMembers(context),
            _buildLessonDistribution(),
            _buildRecentLessons(),
          ],
        ),
      ),
    );
  }

  void _showEditCanTeachDialog(BuildContext context) {
    final userVM = context.read<UserViewModel>();
    final List<String> tempSelected = List<String>.from(_currentTrainer.canTeach ?? []);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("${_currentTrainer.fullName} - Ders Türleri"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: LessonConstants.mainGroups.map((group) {
                final subTypes = LessonConstants.getSubTypes(group);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$group Ders Türleri:", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: subTypes.map((type) => FilterChip(
                        label: Text(type, style: const TextStyle(fontSize: 12)),
                        selected: tempSelected.contains(type),
                        selectedColor: Colors.indigo.shade100,
                        onSelected: (val) => setDialogState(() {
                          if (val) tempSelected.add(type); else tempSelected.remove(type);
                        }),
                      )).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () async {
                final success = await userVM.updateTrainerCanTeach(
                  trainerId: int.parse(_currentTrainer.id),
                  canTeach: tempSelected,
                );
                if (success && mounted) {
                  Navigator.pop(context);
                  await userVM.fetchUsers(int.parse(_currentTrainer.gymId));
                  setState(() {
                    _currentTrainer = userVM.users.firstWhere((u) => u.id == _currentTrainer.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Eğitmen ders türleri güncellendi.")));
                }
              },
              child: const Text("KAYDET"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveInfo(BuildContext context) {
    if (!_currentTrainer.hasDefinedLeave) return const SizedBox();

    final bool isCurrentlyOnLeave = _currentTrainer.isCurrentlyOnLeave;
    final bool isFutureLeave = _currentTrainer.leaveStart!.isAfter(DateTime.now());

    if (!isCurrentlyOnLeave && !isFutureLeave) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.beach_access, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCurrentlyOnLeave ? "ŞU AN İZİNLİ" : "PLANLANMIŞ İZİN",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12),
                      ),
                      Text(
                        "${DateFormat('dd/MM/yyyy').format(_currentTrainer.leaveStart!)} - ${DateFormat('dd/MM/yyyy').format(_currentTrainer.leaveEnd!)}",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: () => _confirmCancelLeave(context),
              icon: const Icon(Icons.cancel, size: 18),
              label: const Text("İZNİ İPTAL ET VE ÇALIŞMAYA DÖNDÜR"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancelLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("İzni İptal Et"),
        content: const Text("Eğitmenin bu iznini iptal etmek ve onu tekrar aktif çalışmaya döndürmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final vm = context.read<UserViewModel>();

              await vm.fetchLeaveHistory(int.parse(_currentTrainer.id));
              final activeLeave = vm.leaveHistory.firstWhere((l) => l.status == 'ACTIVE', orElse: () => throw "Aktif izin bulunamadı");

              final success = await vm.cancelLeave(activeLeave.id);
              if (success && mounted) {
                Navigator.pop(dialogContext);
                await vm.fetchUsers(int.parse(_currentTrainer.gymId));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İzin başarıyla iptal edildi.")));
              }
            },
            child: const Text("ONAYLA", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedMembers(BuildContext context) {
    final userVM = context.watch<UserViewModel>();
    final assignedMembers = userVM.users
        .where((u) => u.role == 'MEMBER' && u.assignedTrainerId == _currentTrainer.id)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "Sabit Üyeleri (${assignedMembers.length})",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (assignedMembers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("Bu eğitmene atanmış sabit üye bulunmamaktadır.",
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: assignedMembers.length,
            itemBuilder: (context, index) {
              final member = assignedMembers[index];
              final hasPhoto = member.profileImageUrl != null && member.profileImageUrl!.trim().isNotEmpty;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  backgroundImage: hasPhoto ? NetworkImage(member.profileImageUrl!) : null,
                  child: !hasPhoto ? const Icon(Icons.person, color: Colors.green) : null,
                ),
                title: Text(member.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Ders: ${member.assignedLessonType ?? "Belirlenmemiş"}"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MemberDetailScreen(member: member),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final photoUrl = _currentTrainer.profileImageUrl;
    final hasPhoto = photoUrl != null && photoUrl.trim().isNotEmpty;

    final mainGroupCategories = (_currentTrainer.canTeach ?? [])
        .map((type) => LessonConstants.getCategory(type))
        .toSet()
        .toList();

    final themeVM = context.watch<ThemeViewModel>();
    final primaryColor = themeVM.primaryColor;

    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      color: primaryColor.withOpacity(0.1),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: primaryColor,
            backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
            child: !hasPhoto ? const Icon(Icons.engineering, size: 50, color: Colors.white) : null,
          ),
          const SizedBox(height: 10),
          Text(_currentTrainer.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(_currentTrainer.email, style: const TextStyle(color: Colors.grey)),
          Text(formatPhoneNumber(_currentTrainer.phone), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              ...mainGroupCategories.map((group) => Chip(
                label: Text(group, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.green.withOpacity(0.15),
              )).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final totalLessons = _trainerStats?['totalLessons'] ?? 0;
    final unpaidAmount = (_trainerStats?['unpaidAmount'] as num?)?.toDouble() ?? 0.0;
    final averageRating = (_trainerStats?['averageRating'] as num?)?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem("Toplam Ders", "$totalLessons", Colors.blue),
            const VerticalDivider(),
            _statItem("Hakediş", "${unpaidAmount.toStringAsFixed(0)} Puan", Colors.green),
            const VerticalDivider(),
            _statItem("Puan", averageRating.toStringAsFixed(1), Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildLessonDistribution() {
    final ptCount = _trainerStats?['ptCount'] ?? 0;
    final pilatesCount = _trainerStats?['pilatesCount'] ?? _trainerStats?['reformerCount'] ?? 0;
    final kickBoksCount = _trainerStats?['kickBoksCount'] ?? 0;
    final yogaCount = _trainerStats?['yogaCount'] ?? 0;
    final total = ptCount + pilatesCount + kickBoksCount + yogaCount;

    final ptRatio = total > 0 ? ptCount / total : 0.0;
    final pilatesRatio = total > 0 ? pilatesCount / total : 0.0;
    final kickBoksRatio = total > 0 ? kickBoksCount / total : 0.0;
    final yogaRatio = total > 0 ? yogaCount / total : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Verdiği Ders Grupları", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _distributionRow(LessonConstants.pt, "$ptCount Ders", ptRatio, Colors.blue),
          _distributionRow(LessonConstants.pilates, "$pilatesCount Ders", pilatesRatio, Colors.purple),
          _distributionRow(LessonConstants.kickBoks, "$kickBoksCount Ders", kickBoksRatio, Colors.redAccent),
          _distributionRow(LessonConstants.yoga, "$yogaCount Ders", yogaRatio, Colors.teal),
        ],
      ),
    );
  }

  Widget _distributionRow(String label, String count, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              Text(count, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: percent, color: color, backgroundColor: color.withOpacity(0.1)),
        ],
      ),
    );
  }

  Widget _buildRecentLessons() {
    final recentLessons = (_trainerStats?['recentLessons'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text("Son Verdiği Dersler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        if (recentLessons.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Henüz verilmiş bir ders bulunmuyor.", style: TextStyle(color: Colors.grey)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentLessons.length,
            itemBuilder: (context, index) {
              final lesson = recentLessons[index] as Map<String, dynamic>;
              final memberName = lesson['memberName'] ?? 'Üye';
              final amount = lesson['amount'] ?? 0;
              final dateStr = lesson['date'] as String?;
              DateTime? date;
              if (dateStr != null) {
                date = DateTime.tryParse(dateStr);
              }

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(memberName),
                subtitle: Text(date != null
                    ? DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(date)
                    : ''),
                trailing: Text("+$amount Puan", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              );
            },
          ),
      ],
    );
  }
}
