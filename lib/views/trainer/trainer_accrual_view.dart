import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/accrual_view_model.dart';

class TrainerAccrualView extends StatelessWidget {
  const TrainerAccrualView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AccrualViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Hakediş Raporum")),
      body: Column(
        children: [
          // Toplam Bakiye Kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            color: Colors.green.shade700,
            child: Column(
              children: [
                const Text("Bekleyen Toplam Hakediş", style: TextStyle(color: Colors.white70)),
                Text("${viewModel.totalBalance.toStringAsFixed(2)} TL", 
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(alignment: Alignment.centerLeft, child: Text("Ders Detayları", style: TextStyle(fontWeight: FontWeight.bold))),
          ),

          // Ders Listesi
          Expanded(
            child: ListView.builder(
              itemCount: viewModel.pendingAccruals.length,
              itemBuilder: (context, index) {
                final entry = viewModel.pendingAccruals[index];
                return ListTile(
                  leading: const Icon(Icons.fitness_center, color: Colors.green),
                  title: Text(entry.memberName),
                  subtitle: Text("${entry.lessonType.name} - ${entry.date.hour}:${entry.date.minute}"),
                  trailing: Text("+${entry.amount} TL", style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
