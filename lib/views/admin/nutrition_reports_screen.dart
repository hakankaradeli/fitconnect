import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/nutrition_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../models/nutrition_model.dart';

class NutritionReportsScreen extends StatefulWidget {
  const NutritionReportsScreen({super.key});

  @override
  State<NutritionReportsScreen> createState() => _NutritionReportsScreenState();
}

class _NutritionReportsScreenState extends State<NutritionReportsScreen> {
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null) {
        context.read<NutritionViewModel>().fetchExpiredReports(userData['gymId']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nutritionVM = context.watch<NutritionViewModel>();
    final reports = nutritionVM.expiredReports;
    final userData = context.read<LoginViewModel>().userData;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Beslenme Planı Raporları", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: nutritionVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                if (userData != null) {
                  await nutritionVM.fetchExpiredReports(userData['gymId']);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("2 Ayda Bir Güncelleme Takibi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
                                const SizedBox(height: 2),
                                Text(
                                  "60 günlük süresi dolduğu halde eğitmeni tarafından henüz yenilenmeyen üyeler aşağıda listelenmektedir.",
                                  style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text("Geciken Beslenme Planları (${reports.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (reports.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: const Column(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
                            SizedBox(height: 12),
                            Text("Tüm Beslenme Planları Güncel!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 4),
                            Text("Geciken veya süresi dolan herhangi bir üye beslenme planı bulunmuyor.", style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    else
                      ...reports.map((item) => _buildReportTile(context, item)).toList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReportTile(BuildContext context, Map<String, dynamic> item) {
    final int delayDays = item['delayDays'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
          child: const Icon(Icons.restaurant_rounded, color: Colors.redAccent),
        ),
        title: Text(item['memberName'] ?? "Üye", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Eğitmen: ${item['trainerName'] ?? 'Atanmamış'}", style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text("Süre Dolumu: ${DateFormat('dd MMMM yyyy', 'tr').format(DateTime.parse(item['expiryDate']))}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(10)),
              child: Text(
                "$delayDays Gün Gecikti",
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
        onTap: () => _viewMemberPlanDetails(context, item['memberId'], item['memberName']),
      ),
    );
  }

  void _viewMemberPlanDetails(BuildContext context, int memberId, String memberName) async {
    final nutritionVM = context.read<NutritionViewModel>();
    final plan = await nutritionVM.fetchMemberPlan(memberId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("$memberName - Beslenme Planı", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: plan == null
              ? const Text("Üyenin aktif planı bulunmuyor.")
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            Text("${plan.dailyCalories} kcal / Gün", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text("P: ${plan.protein}g", style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text("C: ${plan.carbs}g", style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text("F: ${plan.fat}g", style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text("Öğün Listesi:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...plan.meals.map((meal) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text("• $meal", style: const TextStyle(fontSize: 13)),
                      )).toList(),
                    ],
                  ),
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat"))],
      ),
    );
  }
}
