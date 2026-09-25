import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/nutrition_view_model.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../models/user_model.dart';

class TrainerAddNutritionView extends StatefulWidget {
  const TrainerAddNutritionView({super.key});

  @override
  State<TrainerAddNutritionView> createState() => _TrainerAddNutritionViewState();
}

class _TrainerAddNutritionViewState extends State<TrainerAddNutritionView> {
  int? _selectedMemberId;
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _mealController = TextEditingController();
  final List<String> _meals = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null) {
        context.read<UserViewModel>().fetchUsers(userData['gymId']);
      }
    });
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _mealController.dispose();
    super.dispose();
  }

  void _addMeal() {
    if (_mealController.text.trim().isNotEmpty) {
      setState(() {
        _meals.add(_mealController.text.trim());
        _mealController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userVM = context.watch<UserViewModel>();
    final userData = context.read<LoginViewModel>().userData;
    final trainerId = userData?['userId'];

    // Üyeleri çek: Öncelikle bu eğitmene atanmış aktif üyeler, yoksa salonun tüm aktif üyeleri
    final trainerMembers = userVM.users
        .where((u) => u.role == 'MEMBER' && u.isActive && u.assignedTrainerId == trainerId?.toString())
        .toList();

    final allGymMembers = userVM.users
        .where((u) => u.role == 'MEMBER' && u.isActive)
        .toList();

    final assignedMembers = trainerMembers.isNotEmpty ? trainerMembers : allGymMembers;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Beslenme Planı Tanımla", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: userVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Üye Seçimi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedMemberId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: assignedMembers.isEmpty ? "Aktif üye bulunamadı" : "Beslenme planı yazılacak üyeyi seçin",
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: assignedMembers.map((m) => DropdownMenuItem(value: int.parse(m.id), child: Text(m.fullName))).toList(),
                    onChanged: (val) => setState(() => _selectedMemberId = val),
                  ),
                  const SizedBox(height: 20),

            const Text("Günlük Makro Hedefleri", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Günlük Kalori (kcal)",
                hintText: "Örn: 2200",
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _proteinController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Protein (g)",
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _carbsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Karbonhidrat (g)",
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fatController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Yağ (g)",
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text("Öğün Listesi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mealController,
                    decoration: InputDecoration(
                      hintText: "Örn: Sabah: 3 Yumurta + 50g Yulaf",
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(14)),
                  onPressed: _addMeal,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _meals.length,
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  dense: true,
                  title: Text(_meals[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    onPressed: () => setState(() => _meals.removeAt(index)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Kayıt edildikten sonra beslenme planı 2 ay (60 gün) boyunca üyenin ekranında aktif olacaktır.",
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSaving ? null : () async {
                  if (_selectedMemberId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bir üye seçin.")));
                    return;
                  }

                  final cal = int.tryParse(_caloriesController.text) ?? 0;
                  final p = int.tryParse(_proteinController.text) ?? 0;
                  final c = int.tryParse(_carbsController.text) ?? 0;
                  final f = int.tryParse(_fatController.text) ?? 0;

                  if (cal == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen geçerli bir kalori değeri girin.")));
                    return;
                  }

                  setState(() => _isSaving = true);
                  final success = await context.read<NutritionViewModel>().assignPlan(
                    memberId: _selectedMemberId!,
                    trainerId: trainerId!,
                    dailyCalories: cal,
                    protein: p,
                    carbs: c,
                    fat: f,
                    meals: _meals,
                  );

                  if (mounted) {
                    setState(() => _isSaving = false);
                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Beslenme planı 60 günlük periyot için kaydedildi.")));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plan kaydedilemedi.")));
                    }
                  }
                },
                icon: const Icon(Icons.send_rounded),
                label: Text(_isSaving ? "Kaydediliyor..." : "PLANI YAYINLA (60 GÜN)"),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
