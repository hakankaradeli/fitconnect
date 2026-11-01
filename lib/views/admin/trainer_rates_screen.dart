import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../view_models/trainer_rate_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../view_models/theme_view_model.dart';
import '../../constants/lesson_constants.dart';
import '../widgets/custom_back_button.dart';

class TrainerRatesScreen extends StatefulWidget {
  final UserModel trainer;

  const TrainerRatesScreen({super.key, required this.trainer});

  @override
  State<TrainerRatesScreen> createState() => _TrainerRatesScreenState();
}

class _TrainerRatesScreenState extends State<TrainerRatesScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final List<String> _allTypes = LessonConstants.allTypes;
  String _selectedGroup = LessonConstants.pt;

  @override
  void initState() {
    super.initState();
    for (var type in _allTypes) {
      _controllers[type] = TextEditingController();
    }
    _loadRates();
  }

  void _loadRates() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<TrainerRateViewModel>();
      await vm.fetchRates(int.parse(widget.trainer.id));
      for (var type in _allTypes) {
        if (vm.rates.containsKey(type)) {
          _controllers[type]?.text = vm.rates[type].toString();
        }
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    final viewModel = context.read<TrainerRateViewModel>();
    final gymId = context.read<LoginViewModel>().userData?['gymId'] ?? 1;
    int successCount = 0;

    for (var type in _allTypes) {
      final value = _controllers[type]?.text ?? "0";
      final amount = double.tryParse(value) ?? 0.0;

      bool success = await viewModel.updateRate(
        trainerId: int.parse(widget.trainer.id),
        lessonType: type,
        amount: amount,
        gymId: gymId,
      );
      if (success) successCount++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hakedişler kaydedildi.")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TrainerRateViewModel>();
    final themeVM = context.watch<ThemeViewModel>();
    final primaryColor = themeVM.primaryColor;
    final onPrimary = themeVM.onPrimaryColor;

    final subTypes = LessonConstants.getSubTypes(_selectedGroup);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.trainer.fullName} - Hakediş Puanları",
          style: TextStyle(color: onPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: primaryColor.computeLuminance() > 0.45
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        leading: CustomBackButton(
          color: onPrimary,
          backgroundColor: onPrimary.withValues(alpha: 0.18),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: viewModel.isLoading ? null : _saveAll,
          child: const Text(
            "TÜM DEĞİŞİKLİKLERİ KAYDET",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ana Ders Grubu Seçin:",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LessonConstants.mainGroups.map((group) {
                      final isSelected = _selectedGroup == group;
                      return ChoiceChip(
                        label: Text(
                          group,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedGroup = group);
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    "$_selectedGroup Alt Ders Hakediş Tarifleri",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  const SizedBox(height: 12),

                  ...subTypes.map((type) => _buildRateCard(type, primaryColor)).toList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildRateCard(String type, Color themeColor) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: themeColor.withOpacity(0.1),
          child: Icon(Icons.fitness_center_rounded, color: themeColor),
        ),
        title: Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: const Text("Ders başı hakediş puanı"),
        trailing: SizedBox(
          width: 110,
          child: TextField(
            controller: _controllers[type],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              hintText: "0.0",
              suffixText: " Puan",
            ),
          ),
        ),
      ),
    );
  }
}
