import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/image_utils.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../models/user_model.dart';
import 'create_trainer_screen.dart';
import 'trainer_detail_screen.dart';
import 'trainer_leave_history_screen.dart';

class TrainerListScreen extends StatefulWidget {
  const TrainerListScreen({super.key});

  @override
  State<TrainerListScreen> createState() => _TrainerListScreenState();
}

class _TrainerListScreenState extends State<TrainerListScreen> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadTrainers() {
    final userData = context.read<LoginViewModel>().userData;
    if (userData != null) {
      context.read<UserViewModel>().fetchUsers(userData['gymId']);
      context.read<UserViewModel>().fetchDeletedUsers(userData['gymId']);
    }
  }

  Future<int?> _showReplacementDialog(List<UserModel> trainers, String title, {int? trainerId}) async {
    int? selectedId;
    double? unpaidAmount;
    bool isPaid = false;
    DateTime? futureDate;

    if (trainerId != null) {
      unpaidAmount = await context.read<UserViewModel>().getUnpaidAccrual(trainerId);
    }

    return await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (unpaidAmount != null && unpaidAmount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50, 
                      borderRadius: BorderRadius.circular(16), 
                      border: Border.all(color: Colors.amber.shade200)
                    ),
                    child: Column(
                      children: [
                        Text("Eğitmenin birikmiş hakedişi: ${unpaidAmount.toStringAsFixed(0)} Puan", 
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange)),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Ödendi Olarak İşaretle", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          value: isPaid,
                          onChanged: (val) => setDialogState(() => isPaid = val ?? false),
                        ),
                        if (!isPaid)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(futureDate == null ? "İleri Ödeme Tarihi Seç" : "Tarih: ${DateFormat('dd MMMM', 'tr').format(futureDate!)}"),
                            trailing: const Icon(Icons.calendar_today_rounded, size: 18),
                            onTap: () async {
                              final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                              if (date != null) setDialogState(() => futureDate = date);
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text("Eğitmenin üzerindeki dersler ve üyeler hangi eğitmene devredilsin?", style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Yeni Eğitmeni Seçin", 
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))
                  ),
                  items: trainers.map<DropdownMenuItem<int>>((t) => DropdownMenuItem(value: int.parse(t.id), child: Text(t.fullName))).toList(),
                  onChanged: (val) => setDialogState(() => selectedId = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: (selectedId == null) ? null : () async {
                if (isPaid && trainerId != null) {
                  await context.read<UserViewModel>().markAccrualsPaid(trainerId);
                }
                Navigator.pop(context, selectedId);
              },
              child: const Text("DEVRET VE DEVAM ET"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLeaveDialog(UserModel trainer, List<UserModel> otherTrainers) async {
    DateTimeRange? selectedRange;
    int? selectedId;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Eğitmen İzin Tanımla", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(selectedRange == null 
                    ? "İzin Tarih Aralığı Seçin" 
                    : "${DateFormat('dd/MM').format(selectedRange!.start)} - ${DateFormat('dd/MM').format(selectedRange!.end)}"),
                trailing: const Icon(Icons.date_range_rounded, color: Colors.blue),
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (range != null) setDialogState(() => selectedRange = range);
                },
              ),
              const SizedBox(height: 16),
              const Text("İzinli dönemdeki dersler kime devredilsin?", style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                items: otherTrainers.map<DropdownMenuItem<int>>((t) => DropdownMenuItem(value: int.parse(t.id), child: Text(t.fullName))).toList(),
                onChanged: (val) => setDialogState(() => selectedId = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: (selectedRange == null || selectedId == null) ? null : () async {
                final success = await context.read<UserViewModel>().setTrainerLeave(
                  trainerId: int.parse(trainer.id),
                  start: selectedRange!.start,
                  end: selectedRange!.end.add(const Duration(hours: 23, minutes: 59)),
                  replacementTrainerId: selectedId,
                );
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İzin tanımlandı ve dersler devredildi.")));
                }
              },
              child: const Text("KAYDET VE DEVRET"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserViewModel>();
    final trainers = viewModel.users.where((u) => u.role == 'TRAINER').toList();
    final deletedTrainers = viewModel.deletedUsers.where((u) => u.role == 'TRAINER').toList();
    
    final otherActiveTrainers = (UserModel current) => trainers
        .where((t) => t.id != current.id && t.isActive)
        .toList();

    final filteredTrainers = trainers
        .where((u) => u.fullName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: _searchQuery.isEmpty 
            ? const Text("Eğitmenler", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)) 
            : TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(hintText: "Eğitmen ara...", border: InputBorder.none),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Aktif/Pasif"),
              Tab(text: "Silinmişler"),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(_searchQuery.isEmpty ? Icons.search_rounded : Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _searchQuery = "";
                  _searchController.clear();
                });
              },
            )
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.green,
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateTrainerScreen()));
            _loadTrainers();
          },
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text("YENİ HOCA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: TabBarView(
          children: [
            _buildActiveList(viewModel, filteredTrainers, otherActiveTrainers),
            _buildDeletedList(viewModel, deletedTrainers),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveList(UserViewModel viewModel, List<UserModel> filteredTrainers, Function otherActiveTrainers) {
    if (viewModel.isLoading) return const Center(child: CircularProgressIndicator());
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTrainers.length,
      itemBuilder: (context, index) {
        final user = filteredTrainers[index];
        final bool isOnLeave = user.isCurrentlyOnLeave;
        final bool hasFutureLeave = user.hasDefinedLeave && !isOnLeave;
        final imageProvider = getProfileImageProvider(user.profileImageUrl);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: (!user.isActive ? Colors.red : (isOnLeave ? Colors.blue : Colors.green)).withOpacity(0.1),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(Icons.engineering_rounded, color: !user.isActive ? Colors.red : (isOnLeave ? Colors.blue : Colors.green))
                  : null,
            ),
            title: Text(
              user.fullName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: user.isActive ? Colors.black87 : Colors.grey,
                decoration: user.isActive ? null : TextDecoration.lineThrough,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                _buildStatusBadge(user, isOnLeave, hasFutureLeave),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              onSelected: (val) async {
                if (val == 'status') {
                  int? replacementId;
                  if (user.isActive) {
                    replacementId = await _showReplacementDialog(otherActiveTrainers(user), "Eğitmeni Pasife Al", trainerId: int.parse(user.id));
                    if (replacementId == null) return;
                  }
                  await viewModel.toggleUserStatus(int.parse(user.id), replacementTrainerId: replacementId);
                } else if (val == 'leave') {
                  await _showLeaveDialog(user, otherActiveTrainers(user));
                } else if (val == 'leave_history') {
                  if (!mounted) return;
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TrainerLeaveHistoryScreen(trainer: user)));
                } else if (val == 'delete') {
                  final replacementId = await _showReplacementDialog(otherActiveTrainers(user), "Eğitmeni Sil", trainerId: int.parse(user.id));
                  if (replacementId == null) return;

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text("Eğitmeni Sil"),
                      content: const Text("Bu eğitmeni silmek istediğinize emin misiniz? Veriler devredilecektir."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("SİL VE DEVRET", style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await viewModel.deleteUser(int.parse(user.id), replacementTrainerId: replacementId);
                    _loadTrainers();
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'status', child: Row(children: [Icon(user.isActive ? Icons.block_rounded : Icons.check_circle_rounded, size: 18), const SizedBox(width: 8), Text(user.isActive ? "Pasife Al" : "Aktifleştir")])),
                const PopupMenuItem(value: 'leave', child: Row(children: [Icon(Icons.beach_access_rounded, size: 18), const SizedBox(width: 8), Text("İzin Tanımla")])),
                const PopupMenuItem(value: 'leave_history', child: Row(children: [Icon(Icons.history_rounded, size: 18), const SizedBox(width: 8), Text("İzin Geçmişi")])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), const SizedBox(width: 8), Text("Sil", style: TextStyle(color: Colors.red))])),
              ],
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => TrainerDetailScreen(trainer: user)));
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(UserModel user, bool isOnLeave, bool hasFutureLeave) {
    String text = "AKTİF";
    Color color = Colors.green;

    if (!user.isActive) {
      text = "PASİF";
      color = Colors.red;
    } else if (isOnLeave) {
      text = "İZİNLİ (${DateFormat('dd/MM').format(user.leaveStart!)})";
      color = Colors.blue;
    } else if (hasFutureLeave) {
      text = "PLANLI İZİN (${DateFormat('dd/MM').format(user.leaveStart!)})";
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDeletedList(UserViewModel viewModel, List<UserModel> deleted) {
    if (deleted.isEmpty) return const Center(child: Text("Silinmiş eğitmen bulunamadı."));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deleted.length,
      itemBuilder: (context, index) {
        final user = deleted[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.delete_sweep_rounded, color: Colors.white)),
            title: Text(user.fullName, style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.bold)),
            subtitle: Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        );
      },
    );
  }
}
