import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/finance_view_model.dart';
import '../../models/finance_model.dart';

class FinanceSummaryView extends StatelessWidget {
  const FinanceSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    final financeVM = context.watch<FinanceViewModel>();
    final isNegative = financeVM.balance.netBalance < 0;

    return Scaffold(
      appBar: AppBar(title: const Text("Ödeme ve Kredi Takibi")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Bakiye Kartı
            Card(
              color: isNegative ? Colors.orange.shade50 : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(isNegative ? "AVANS (BORÇ) KULLANIMI" : "MEVCUT KREDİ"),
                    Text(
                      "${financeVM.balance.netBalance}",
                      style: TextStyle(
                        fontSize: 48, 
                        fontWeight: FontWeight.bold,
                        color: isNegative ? Colors.red : Colors.green
                      ),
                    ),
                    if (isNegative)
                      const Text("Ödeme yaptığınızda krediniz yüklenecektir.", 
                        style: TextStyle(fontSize: 12, color: Colors.red)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text("Taksit Planı", style: TextStyle(fontWeight: FontWeight.bold))),
            
            // Taksit Listesi
            Expanded(
              child: ListView.builder(
                itemCount: financeVM.installments.length,
                itemBuilder: (context, index) {
                  final plan = financeVM.installments[index];
                  return ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text("${plan.amount} TL"),
                    subtitle: Text("Vade: ${plan.dueDate.day}/${plan.dueDate.month}"),
                    trailing: plan.status == PaymentStatus.paid 
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Text("Bekliyor", style: TextStyle(color: Colors.orange)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
