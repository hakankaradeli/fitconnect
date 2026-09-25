import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/finance_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../models/finance_model.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  int? _selectedMonthFilter; // null = Tüm Aylar, 1..12

  final Map<int, String> _months = const {
    1: "Ocak", 2: "Şubat", 3: "Mart", 4: "Nisan", 5: "Mayıs", 6: "Haziran",
    7: "Temmuz", 8: "Ağustos", 9: "Eylül", 10: "Ekim", 11: "Kasım", 12: "Aralık"
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null) {
        context.read<FinanceViewModel>().fetchAllInstallments(userData['gymId']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FinanceViewModel>();
    final userData = context.read<LoginViewModel>().userData;

    final filteredPlans = _selectedMonthFilter == null
        ? viewModel.installments
        : viewModel.installments.where((p) => p.dueDate.month == _selectedMonthFilter).toList();

    // Yeni aydan eski aya doğru sıralama (Sondan başa)
    final sortedPlans = List<PaymentPlan>.from(filteredPlans)
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

    final groupedPlans = _groupPlansByMonth(sortedPlans);
    final totalIncome = filteredPlans.fold(0.0, (sum, p) => sum + (p.status == PaymentStatus.paid ? p.amount : 0));
    final totalPending = filteredPlans.fold(0.0, (sum, p) => sum + (p.status != PaymentStatus.paid ? p.amount : 0));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Gelir Yönetimi", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (userData != null) {
                  await viewModel.fetchAllInstallments(userData['gymId']);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(totalIncome, totalPending),
                    const SizedBox(height: 20),
                    _buildMonthFilterDropdown(),
                    const SizedBox(height: 20),
                    if (groupedPlans.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text("Seçilen dönemde gelir kaydı bulunmamaktadır.", style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ...groupedPlans.entries.map((entry) => _buildMonthGroup(context, entry.key, entry.value, userData?['gymId'])).toList(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  Map<String, List<PaymentPlan>> _groupPlansByMonth(List<PaymentPlan> plans) {
    final Map<String, List<PaymentPlan>> grouped = {};
    for (var plan in plans) {
      final key = DateFormat('MMMM yyyy', 'tr').format(plan.dueDate);
      grouped.putIfAbsent(key, () => []).add(plan);
    }
    return grouped;
  }

  Widget _buildSummaryCards(double income, double pending) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text("Tahsil Edilen", style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text("${income.toStringAsFixed(0)} TL", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.green.shade900)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pending_actions_rounded, color: Colors.orange, size: 18),
                    const SizedBox(width: 6),
                    Text("Bekleyen Borç", style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text("${pending.toStringAsFixed(0)} TL", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.orange.shade900)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedMonthFilter,
          isExpanded: true,
          icon: const Icon(Icons.calendar_month_rounded, color: Colors.blueGrey),
          hint: const Text("Tüm Aylar"),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text("Tüm Aylar")),
            ..._months.entries.map((e) => DropdownMenuItem<int?>(
              value: e.key,
              child: Text(e.value),
            )).toList(),
          ],
          onChanged: (val) => setState(() => _selectedMonthFilter = val),
        ),
      ),
    );
  }

  Widget _buildMonthGroup(BuildContext context, String monthName, List<PaymentPlan> plans, int? gymId) {
    final monthTotal = plans.fold(0.0, (sum, p) => sum + (p.status == PaymentStatus.paid ? p.amount : 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthName.toUpperCase(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  "Tahsilat: ${monthTotal.toStringAsFixed(0)} TL",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ],
          ),
        ),
        ...plans.map((plan) => _buildPaymentCard(context, plan, gymId)).toList(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentPlan plan, int? gymId) {
    final isPaid = plan.status == PaymentStatus.paid;
    final color = isPaid ? Colors.green : (plan.dueDate.isBefore(DateTime.now()) ? Colors.red : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(isPaid ? Icons.check_rounded : Icons.pending_actions_rounded, color: color),
        ),
        title: Text(plan.memberName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${plan.amount.toStringAsFixed(0)} TL | ${plan.creditsToLoad} Kredi", style: const TextStyle(fontWeight: FontWeight.w600)),
            Text("Vade: ${DateFormat('dd MMMM yyyy', 'tr').format(plan.dueDate)}", 
                style: TextStyle(fontSize: 12, color: plan.dueDate.isBefore(DateTime.now()) && !isPaid ? Colors.red : Colors.grey)),
          ],
        ),
        trailing: isPaid 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text("ÖDENDİ", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _confirmPayment(context, plan, gymId),
              child: const Text("ONAYLA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
      ),
    );
  }

  void _confirmPayment(BuildContext context, PaymentPlan plan, int? gymId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Ödeme Onayı"),
        content: Text("${plan.memberName} isimli üyeden ${plan.amount.toStringAsFixed(0)} TL tutarındaki ödeme alındı mı?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hayır")),
          TextButton(
            onPressed: () async {
              final success = await context.read<FinanceViewModel>().confirmPayment(plan.id, gymId!);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ödeme başarıyla onaylandı.")));
              }
            },
            child: const Text("Evet, Alındı", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
