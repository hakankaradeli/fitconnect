import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/accrual_view_model.dart';
import '../widgets/custom_back_button.dart';

class AdminPaymentView extends StatelessWidget {
  const AdminPaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AccrualViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Eğitmen Ödemeleri", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: const CustomBackButton(),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 10),
            const Text("Mert Hoca", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Güncel Hakediş: ${viewModel.totalBalance} Puan"),
            const SizedBox(height: 30),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: viewModel.totalBalance == 0 
                ? null 
                : () => _showPaymentConfirm(context, viewModel),
              child: const Text("ÖDEME YAPILDI OLARAK İŞARETLE"),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentConfirm(BuildContext context, AccrualViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ödeme Onayı"),
        content: const Text("Eğitmenin birikmiş hakedişi sıfırlanacak. Nakit/Havale ödemesini yaptınız mı?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              vm.processPayment();
              Navigator.pop(context);
            }, 
            child: const Text("Evet, Sıfırla")
          ),
        ],
      ),
    );
  }
}
