import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/nutrition_view_model.dart';
import '../../view_models/user_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../widgets/custom_back_button.dart';

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
        final gymId = int.tryParse(userData['gymId']?.toString() ?? '0') ?? 0;
        if (gymId > 0) {
          context.read<UserViewModel>().fetchUsers(gymId);
        } else {
          debugPrint("TrainerAddNutritionView: gymId is missing or 0");
        }
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

  void _editMeal(int index) {
    final currentMeal = _meals[index];
    final editController = TextEditingController(text: currentMeal);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Öğünü Düzenle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Öğün içeriğini güncelleyin...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                setState(() {
                  _meals[index] = editController.text.trim();
                });
                Navigator.pop(dialogContext);
              }
            },
            child: const Text("KAYDET"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userVM = context.watch<UserViewModel>();
    final userData = context.read<LoginViewModel>().userData;
    final trainerId = userData?['userId']?.toString();

    final assignedMembers = userVM.users.where((u) => u.role == 'MEMBER' && u.isActive).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Beslenme Planı Tanımla", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const CustomBackButton(),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: userVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (userVM.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Colors.red.shade50,
                      child: Text(userVM.errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),
                  const Text("Üye Seçimi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedMemberId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: assignedMembers.isEmpty ? "Aktif üye bulunamadı (Önce üye atayın)" : "Beslenme planı yazılacak üyeyi seçin",
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    items: assignedMembers.map((m) {
                      final parsedId = int.tryParse(m.id.toString()) ?? 0;
                      return DropdownMenuItem<int>(
                        value: parsedId,
                        child: Text(m.fullName),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      setState(() {
                        _selectedMemberId = val;
                      });
                      if (val != null) {
                        final nutritionVM = context.read<NutritionViewModel>();
                        final plan = await nutritionVM.fetchMemberPlan(val);
                        if (plan != null && mounted) {
                          setState(() {
                            _caloriesController.text = plan.dailyCalories.toString();
                            _proteinController.text = plan.protein.toString();
                            _carbsController.text = plan.carbs.toString();
                            _fatController.text = plan.fat.toString();
                            _meals.clear();
                            _meals.addAll(plan.meals);
                          });
                        } else if (mounted) {
                          setState(() {
                            _caloriesController.clear();
                            _proteinController.clear();
                            _carbsController.clear();
                            _fatController.clear();
                            _meals.clear();
                          });
                        }
                      }
                    },
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                        tooltip: "Düzenle",
                        onPressed: () => _editMeal(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                        tooltip: "Sil",
                        onPressed: () => setState(() => _meals.removeAt(index)),
                      ),
                    ],
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

                  final parsedTrainerId = int.tryParse(trainerId?.toString() ?? '') ?? 1;

                  final success = await context.read<NutritionViewModel>().assignPlan(
                    memberId: _selectedMemberId!,
                    trainerId: parsedTrainerId,
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
