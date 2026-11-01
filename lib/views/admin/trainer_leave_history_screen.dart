import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/user_view_model.dart';
import '../../models/user_model.dart';
import '../widgets/custom_back_button.dart';

class TrainerLeaveHistoryScreen extends StatefulWidget {
  final UserModel trainer;
  const TrainerLeaveHistoryScreen({super.key, required this.trainer});

  @override
  State<TrainerLeaveHistoryScreen> createState() => _TrainerLeaveHistoryScreenState();
}

class _TrainerLeaveHistoryScreenState extends State<TrainerLeaveHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserViewModel>().fetchLeaveHistory(int.parse(widget.trainer.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserViewModel>();
    final history = viewModel.leaveHistory;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.trainer.fullName} - İzin Geçmişi", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: const CustomBackButton(
          color: Colors.white,
          backgroundColor: Color(0x33FFFFFF),
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? const Center(child: Text("Kayıtlı izin bulunmamaktadır."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final leave = history[index];
                    final isCancelled = leave.status == 'CANCELLED';

                    return Card(
                      color: isCancelled ? Colors.grey.shade100 : null,
                      child: ListTile(
                        leading: Icon(
                          isCancelled ? Icons.cancel_outlined : Icons.beach_access,
                          color: isCancelled ? Colors.grey : Colors.blue,
                        ),
                        title: Text(
                          "${DateFormat('dd/MM/yyyy').format(leave.startDate)} - ${DateFormat('dd/MM/yyyy').format(leave.endDate)}",
                          style: TextStyle(
                            decoration: isCancelled ? TextDecoration.lineThrough : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Durum: ${isCancelled ? 'İPTAL EDİLDİ' : 'AKTİF'}"),
                            if (leave.replacementTrainerName != null)
                              Text("Yedek: ${leave.replacementTrainerName}"),
                          ],
                        ),
                        trailing: !isCancelled
                            ? IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                tooltip: "İzni İptal Et",
                                onPressed: () => _confirmCancel(context, leave.id),
                              )
                            : const Text("İPTAL EDİLDİ", style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ),
                    );
                  },
                ),
    );
  }

  void _confirmCancel(BuildContext context, int leaveId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("İzni İptal Et"),
        content: const Text("Planlanmış bu izni iptal etmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await context.read<UserViewModel>().cancelLeave(leaveId);
              if (success && mounted) {
                Navigator.pop(context);
                context.read<UserViewModel>().fetchLeaveHistory(int.parse(widget.trainer.id));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İzin başarıyla iptal edildi.")));
              }
            },
            child: const Text("İPTAL ET", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
