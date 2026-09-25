import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/nutrition_view_model.dart';
import '../../view_models/login_view_model.dart';

class MemberNutritionView extends StatefulWidget {
  const MemberNutritionView({super.key});

  @override
  State<MemberNutritionView> createState() => _MemberNutritionViewState();
}

class _MemberNutritionViewState extends State<MemberNutritionView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null) {
        context.read<NutritionViewModel>().fetchMyPlan(userData['userId']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nutritionVM = context.watch<NutritionViewModel>();
    final plan = nutritionVM.activePlan;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Beslenme Planım", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: nutritionVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : plan == null
              ? _buildEmptyPlanState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMacroCard(plan.dailyCalories, plan.protein, plan.carbs, plan.fat),
                      const SizedBox(height: 24),
                      const Text("Günlük Öğün Listesi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (plan.meals.isEmpty)
                        const Text("Öğün detayları girilmemiş.", style: TextStyle(color: Colors.grey))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: plan.meals.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                  child: Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                ),
                                title: Text(plan.meals[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                      _buildExpiryInfo(plan.expiryDate),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyPlanState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text("Aktif Beslenme Planınız Yok", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "Eğitmeniniz henüz sizin için 2 aylık beslenme programı tanımlamamış.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryInfo(DateTime expiryDate) {
    final remainingDays = expiryDate.difference(DateTime.now()).inDays;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("2 Ayda Bir Güncelleme Periyodu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                Text(
                  remainingDays > 0
                      ? "Planınızın yenilenmesine $remainingDays gün kaldı (${DateFormat('dd MMMM yyyy', 'tr').format(expiryDate)})"
                      : "Planınızın 2 aylık süresi dolmuştur. Eğitmeniniz yenileyecektir.",
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(int cal, int p, int c, int f) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF00BCD4)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Text("$cal kcal", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
          const Text("Günlük Hedef Kalori", style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Divider(height: 30, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _macroInfo("Protein", "${p}g", Colors.white),
              _macroInfo("Karbonhidrat", "${c}g", Colors.white),
              _macroInfo("Yağ", "${f}g", Colors.white),
            ],
          )
        ],
      ),
    );
  }

  Widget _macroInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
