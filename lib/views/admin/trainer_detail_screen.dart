import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../view_models/user_view_model.dart';
import '../../constants/lesson_constants.dart';
import '../trainer/trainer_schedule_view.dart';
import 'member_detail_screen.dart';
import 'trainer_rates_screen.dart';
import 'package:intl/intl.dart';

class TrainerDetailScreen extends StatefulWidget {
  final UserModel trainer;

  const TrainerDetailScreen({super.key, required this.trainer});

  @override
  State<TrainerDetailScreen> createState() => _TrainerDetailScreenState();
}

class _TrainerDetailScreenState extends State<TrainerDetailScreen> {
  late UserModel _currentTrainer;

  @override
  void initState() {
    super.initState();
    _currentTrainer = widget.trainer;
    _refreshTrainer();
  }

  void _refreshTrainer() {
    // Listeden en güncel halini bul
    final vm = context.read<UserViewModel>();
    try {
      setState(() {
        _currentTrainer = vm.users.firstWhere((u) => u.id == widget.trainer.id);
      });
    } catch (e) {
      // Bulunamazsa mevcutla devam et
    }
  }

  @override
  Widget build(BuildContext context) {
    final userVM = context.watch<UserViewModel>();
    // Eğer VM güncellendiyse yerel trainer bilgisini de tazele
    _refreshTrainer();

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTrainer.fullName),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildLeaveInfo(context), // İzin Bilgisi ve İptal Butonu
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
              children: [
                const Text("PT Ders Türleri:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: LessonConstants.ptTypes.map((type) => FilterChip(
                    label: Text(type, style: const TextStyle(fontSize: 12)),
                    selected: tempSelected.contains(type),
                    selectedColor: Colors.blue.shade100,
                    onSelected: (val) => setDialogState(() {
                      if (val) tempSelected.add(type); else tempSelected.remove(type);
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 12),

                const Text("Reformer Pilates Ders Türleri:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: LessonConstants.reformerTypes.map((type) => FilterChip(
                    label: Text(type, style: const TextStyle(fontSize: 12)),
                    selected: tempSelected.contains(type),
                    selectedColor: Colors.purple.shade100,
                    onSelected: (val) => setDialogState(() {
                      if (val) tempSelected.add(type); else tempSelected.remove(type);
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 12),

                const Text("Yoga Ders Türleri:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: LessonConstants.yogaTypes.map((type) => FilterChip(
                    label: Text(type, style: const TextStyle(fontSize: 12)),
                    selected: tempSelected.contains(type),
                    selectedColor: Colors.teal.shade100,
                    onSelected: (val) => setDialogState(() {
                      if (val) tempSelected.add(type); else tempSelected.remove(type);
                    }),
                  )).toList(),
                ),
              ],
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

    // Sadece şu anki veya gelecekteki izinleri gösterelim (Geçmiş izinler zaten modelde gelmeyebilir veya history'den bakılır)
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
              // LeaveRecord id'si lazım ama biz User üzerinden siliyoruz
              // Backend'e direkt userId ile iptal yeteneği ekleyelim veya mevcut history'den bulalım
              // Şimdilik history'deki en güncel aktif kaydı bulup iptal edelim
              await vm.fetchLeaveHistory(int.parse(_currentTrainer.id));
              final activeLeave = vm.leaveHistory.firstWhere((l) => l.status == 'ACTIVE', orElse: () => throw "Aktif izin bulunamadı");
              
              final success = await vm.cancelLeave(activeLeave.id);
              if (success && mounted) {
                Navigator.pop(dialogContext);
                await vm.fetchUsers(int.parse(_currentTrainer.gymId)); // Ana listeyi tazele
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

    // Ders türlerini ana grup başlığı bazında tekleştir (PT, Reformer Pilates, Yoga)
    final mainGroupCategories = (_currentTrainer.canTeach ?? [])
        .map((type) => LessonConstants.getCategory(type))
        .toSet()
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      color: Colors.green.withOpacity(0.1),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50, 
            backgroundColor: Colors.green,
            backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
            child: !hasPhoto ? const Icon(Icons.engineering, size: 50, color: Colors.white) : null,
          ),
          const SizedBox(height: 10),
          Text(_currentTrainer.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(_currentTrainer.email, style: const TextStyle(color: Colors.grey)),
          Text(_currentTrainer.phone ?? "Telefon yok", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              ...mainGroupCategories.map((group) => Chip(
                label: Text(group, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.green.withOpacity(0.15),
              )).toList(),
              if (_currentTrainer.instagram != null && _currentTrainer.instagram!.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.camera_alt, size: 16, color: Colors.purple),
                  label: Text("@${_currentTrainer.instagram}"),
                  backgroundColor: Colors.purple.withOpacity(0.1),
                ),
              if (_currentTrainer.linkedin != null && _currentTrainer.linkedin!.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.work, size: 16, color: Colors.blue),
                  label: Text(_currentTrainer.linkedin!),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
              if (_currentTrainer.twitter != null && _currentTrainer.twitter!.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.alternate_email, size: 16, color: Colors.black),
                  label: Text(_currentTrainer.twitter!.replaceFirst(RegExp(r'^@+'), '')),
                  backgroundColor: Colors.black.withOpacity(0.1),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    // Şimdilik örnek veri, normalde backend'den çekilmeli
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem("Toplam Ders", "42", Colors.blue),
            const VerticalDivider(),
            _statItem("Hakediş", "3.450 Puan", Colors.green),
            const VerticalDivider(),
            _statItem("Puan", "4.8", Colors.amber),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Verdiği Ders Grupları", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _distributionRow(LessonConstants.pt, "28 Ders", 0.6, Colors.blue),
          _distributionRow(LessonConstants.reformer, "10 Ders", 0.3, Colors.purple),
          _distributionRow(LessonConstants.yoga, "4 Ders", 0.1, Colors.teal),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text("Son Verdiği Dersler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text("Üye Adı Soyadı"),
              subtitle: Text(DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(DateTime.now().subtract(Duration(days: index)))),
              trailing: const Text("+250 Puan", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            );
          },
        ),
      ],
    );
  }
}
