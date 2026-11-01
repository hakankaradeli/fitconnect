import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/delegation_view_model.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../widgets/table_time_picker.dart';
import '../widgets/custom_back_button.dart';

class DelegationScreen extends StatefulWidget {
  const DelegationScreen({super.key});

  @override
  State<DelegationScreen> createState() => _DelegationScreenState();
}

class _DelegationScreenState extends State<DelegationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null) {
        context.read<DelegationViewModel>().fetchDelegations(userData['gymId']);
        context.read<UserViewModel>().fetchUsers(userData['gymId']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DelegationViewModel>();
    final userData = context.read<LoginViewModel>().userData;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Geçici Yetki Ver", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: const CustomBackButton(
          color: Colors.white,
          backgroundColor: Color(0x33FFFFFF),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDelegationDialog(context),
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.delegations.length,
              itemBuilder: (context, index) {
                final del = viewModel.delegations[index];
                final isExpired = del.endTime.isBefore(DateTime.now());

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isExpired ? Colors.grey : Colors.green,
                      child: const Icon(Icons.security, color: Colors.white),
                    ),
                    title: Text(del.trainerName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Yetki: ${del.permission}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("${DateFormat('dd/MM HH:mm').format(del.startTime)} - ${DateFormat('dd/MM HH:mm').format(del.endTime)}"),
                        if (isExpired) const Text("SÜRESİ DOLDU", style: TextStyle(color: Colors.red, fontSize: 10)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final success = await viewModel.revokePermission(del.id, userData?['gymId']);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yetki geri alındı")));
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddDelegationDialog(BuildContext context) {
    final userVM = context.read<UserViewModel>();
    final trainers = userVM.users.where((u) => u.isTrainerOrCanTeach && u.isActive).toList();
    
    int? selectedTrainerId;
    String? selectedPermission;
    DateTime startTime = DateTime.now();
    DateTime endTime = DateTime.now().add(const Duration(hours: 24));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Yeni Yetki Tanımla"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: "Eğitmen Seçin"),
                  items: trainers.map((t) => DropdownMenuItem(value: int.parse(t.id), child: Text(t.fullName))).toList(),
                  onChanged: (val) => setDialogState(() => selectedTrainerId = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: "Yetki Türü"),
                  items: const [
                    DropdownMenuItem(value: "MANAGE_USERS", child: Text("Üye/Hoca Yönetimi")),
                    DropdownMenuItem(value: "MANAGE_SCHEDULE", child: Text("Ders Programı Yönetimi")),
                    DropdownMenuItem(value: "VIEW_REPORTS", child: Text("Raporları Görüntüleme")),
                    DropdownMenuItem(value: "FULL_ADMIN_ACCESS", child: Text("Tam Yönetici Yetkisi")),
                  ],
                  onChanged: (val) => setDialogState(() => selectedPermission = val),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text("Başlangıç", style: TextStyle(fontSize: 12)),
                  subtitle: Text(DateFormat('dd/MM HH:mm').format(startTime)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: startTime, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                    if (date != null && context.mounted) {
                      final time = await showTableTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(startTime),
                        title: "Başlangıç Saati Seçimi",
                        isLessonBooking: false,
                      );
                      if (time != null) {
                        setDialogState(() => startTime = DateTime(date.year, date.month, date.day, time.hour, 0));
                      }
                    }
                  },
                ),
                ListTile(
                  title: const Text("Bitiş", style: TextStyle(fontSize: 12)),
                  subtitle: Text(DateFormat('dd/MM HH:mm').format(endTime)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: endTime, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (date != null && context.mounted) {
                      final time = await showTableTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(endTime),
                        title: "Bitiş Saati Seçimi",
                        isLessonBooking: false,
                      );
                      if (time != null) {
                        setDialogState(() => endTime = DateTime(date.year, date.month, date.day, time.hour, 0));
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: (selectedTrainerId == null || selectedPermission == null)
                  ? null
                  : () async {
                      final loginVM = context.read<LoginViewModel>();
                      final success = await context.read<DelegationViewModel>().grantPermission(
                        trainerId: selectedTrainerId!,
                        gymId: loginVM.userData?['gymId'],
                        permissionType: selectedPermission!,
                        start: startTime,
                        end: endTime,
                      );
                      if (success && mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yetki başarıyla verildi")));
                      }
                    },
              child: const Text("KAYDET"),
            ),
          ],
        ),
      ),
    );
  }
}
