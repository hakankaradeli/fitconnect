import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/accrual_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../widgets/custom_back_button.dart';

class TrainerAccrualView extends StatefulWidget {
  const TrainerAccrualView({super.key});

  @override
  State<TrainerAccrualView> createState() => _TrainerAccrualViewState();
}

class _TrainerAccrualViewState extends State<TrainerAccrualView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null && userData['userId'] != null) {
        context.read<AccrualViewModel>().fetchUnpaidDetails(userData['userId']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AccrualViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hakediş Raporum", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: const CustomBackButton(),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  color: Colors.green.shade700,
                  child: Column(
                    children: [
                      const Text("Bekleyen Toplam Hakediş", style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text(
                        "${viewModel.totalBalance.toStringAsFixed(2)} TL",
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Ders Detayları", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),

                Expanded(
                  child: viewModel.pendingAccruals.isEmpty
                      ? const Center(child: Text("Bekleyen hakediş bulunmamaktadır."))
                      : ListView.builder(
                          itemCount: viewModel.pendingAccruals.length,
                          itemBuilder: (context, index) {
                            final entry = viewModel.pendingAccruals[index];
                            final timeStr = DateFormat('dd.MM.yyyy HH:mm').format(entry.date);
                            return ListTile(
                              leading: const Icon(Icons.fitness_center, color: Colors.green),
                              title: Text(entry.memberName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("${entry.lessonType.name} - $timeStr"),
                              trailing: Text("+${entry.amount.toStringAsFixed(0)} TL",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
