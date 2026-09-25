import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../view_models/trainer_rate_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../constants/lesson_constants.dart';

class TrainerRatesScreen extends StatefulWidget {
  final UserModel trainer;

  const TrainerRatesScreen({super.key, required this.trainer});

  @override
  State<TrainerRatesScreen> createState() => _TrainerRatesScreenState();
}

class _TrainerRatesScreenState extends State<TrainerRatesScreen> {
  final Map<String, TextEditingController> _controllers = {};

  final List<String> _allTypes = LessonConstants.allTypes;

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
        SnackBar(content: Text("$successCount hakediş puanı başarıyla kaydedildi.")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TrainerRateViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.trainer.fullName} - Hakediş Puanları"),
        backgroundColor: Colors.redAccent,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: viewModel.isLoading ? null : _saveAll,
          child: const Text("TÜM DEĞİŞİKLİKLERİ KAYDET", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("PT Hakediş Puanları", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 8),
                  ...LessonConstants.ptTypes.map((type) => _buildRateCard(type, Colors.blue)).toList(),

                  const SizedBox(height: 24),
                  const Text("Reformer Pilates Hakediş Puanları", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                  const SizedBox(height: 8),
                  ...LessonConstants.reformerTypes.map((type) => _buildRateCard(type, Colors.purple)).toList(),

                  const SizedBox(height: 24),
                  const Text("Yoga Hakediş Puanları", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 8),
                  ...LessonConstants.yogaTypes.map((type) => _buildRateCard(type, Colors.teal)).toList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildRateCard(String type, Color themeColor) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(Icons.fitness_center_rounded, color: themeColor),
        title: Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Ders başı hakediş (Puan)"),
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
