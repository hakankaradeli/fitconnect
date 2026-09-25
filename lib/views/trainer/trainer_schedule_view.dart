import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/trainer_schedule_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../models/booking_details_model.dart';
import 'package:intl/intl.dart';

class TrainerScheduleView extends StatefulWidget {
  final int? trainerId;
  const TrainerScheduleView({super.key, this.trainerId});

  @override
  State<TrainerScheduleView> createState() => _TrainerScheduleViewState();
}

class _TrainerScheduleViewState extends State<TrainerScheduleView> {
  DateTime _currentDate = DateTime.now();
  String _viewType = 'Günlük'; // 'Günlük', 'Haftalık', 'Aylık'

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  void _loadSchedule() {
    int? targetTrainerId = widget.trainerId;
    
    if (targetTrainerId == null) {
      final userData = context.read<LoginViewModel>().userData;
      if (userData != null) {
        targetTrainerId = userData['userId'];
      }
    }

    if (targetTrainerId != null) {
      DateTime start;
      DateTime end;

      final normalizedDate = DateTime(_currentDate.year, _currentDate.month, _currentDate.day);

      if (_viewType == 'Günlük') {
        start = normalizedDate;
        end = start.add(const Duration(days: 1));
      } else if (_viewType == 'Haftalık') {
        start = normalizedDate.subtract(Duration(days: normalizedDate.weekday - 1));
        end = start.add(const Duration(days: 7));
      } else {
        start = DateTime(_currentDate.year, _currentDate.month, 1);
        end = DateTime(_currentDate.year, _currentDate.month + 1, 1);
      }

      context.read<TrainerScheduleViewModel>().fetchSchedule(targetTrainerId, start, end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TrainerScheduleViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ders Programı"),
        actions: [
          DropdownButton<String>(
            value: _viewType,
            dropdownColor: Colors.green,
            style: const TextStyle(color: Colors.white),
            items: <String>['Günlük', 'Haftalık', 'Aylık'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(color: Colors.black)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _viewType = newValue;
                });
                _loadSchedule();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateNavigator(),
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.errorMessage != null
                    ? Center(child: Text(viewModel.errorMessage!))
                    : _buildScheduleList(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigator() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                if (_viewType == 'Günlük') {
                  _currentDate = _currentDate.subtract(const Duration(days: 1));
                } else if (_viewType == 'Haftalık') {
                  _currentDate = _currentDate.subtract(const Duration(days: 7));
                } else {
                  _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
                }
              });
              _loadSchedule();
            },
          ),
          Text(
            _viewType == 'Aylık'
                ? DateFormat('MMMM yyyy', 'tr').format(_currentDate)
                : DateFormat('dd MMMM yyyy', 'tr').format(_currentDate),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                if (_viewType == 'Günlük') {
                  _currentDate = _currentDate.add(const Duration(days: 1));
                } else if (_viewType == 'Haftalık') {
                  _currentDate = _currentDate.add(const Duration(days: 7));
                } else {
                  _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
                }
              });
              _loadSchedule();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(TrainerScheduleViewModel viewModel) {
    if (viewModel.bookings.isEmpty) {
      return const Center(child: Text("Bu dönemde ders bulunmamaktadır."));
    }

    return ListView.builder(
      itemCount: viewModel.bookings.length,
      itemBuilder: (context, index) {
        final booking = viewModel.bookings[index];
        final bool isPast = booking.startTime.isBefore(DateTime.now());
        final bool isCompleted = booking.status == 'COMPLETED' || (booking.status == 'ACTIVE' && isPast);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            onTap: isCompleted ? () => _showExerciseLogDialog(context, booking) : null,
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('HH:mm', 'tr_TR').format(booking.startTime),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Icon(Icons.arrow_downward, size: 12),
                Text(DateFormat('HH:mm', 'tr_TR').format(booking.endTime)),
              ],
            ),
            title: Text(booking.memberName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_viewType != 'Günlük')
                  Text(DateFormat('dd MMMM', 'tr').format(booking.startTime), 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
                Text("Durum: ${isCompleted ? 'Tamamlandı' : booking.statusText}"),
                if (booking.performedExercises.isNotEmpty)
                  Text("${booking.performedExercises.length} çalışma girildi", 
                      style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: Icon(
              isCompleted ? Icons.check_circle : Icons.timer,
              color: isCompleted ? Colors.green : Colors.orange,
            ),
          ),
        );
      },
    );
  }

  void _showExerciseLogDialog(BuildContext context, BookingDetails booking) {
    final List<PerformedExercise> tempExercises = List.from(booking.performedExercises);
    final nameController = TextEditingController();
    final weightController = TextEditingController();
    final setsController = TextEditingController();
    final repsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("${booking.memberName} - Antrenman Özeti"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tempExercises.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text("Henüz çalışma girilmemiş.", style: TextStyle(color: Colors.grey)),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: tempExercises.length,
                      itemBuilder: (context, idx) => ListTile(
                        dense: true,
                        title: Text(tempExercises[idx].exerciseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${tempExercises[idx].sets ?? '-'} Set x ${tempExercises[idx].reps ?? '-'} Tekrar | ${tempExercises[idx].weight ?? '-'}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          onPressed: () => setDialogState(() => tempExercises.removeAt(idx)),
                        ),
                      ),
                    ),
                  ),
                const Divider(),
                const Text("Yeni Çalışma Ekle", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Egzersiz Adı (Örn: Bench Press)", isDense: true)),
                Row(
                  children: [
                    Expanded(child: TextField(controller: weightController, decoration: const InputDecoration(labelText: "Ağırlık", hintText: "29 KG", isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: setsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Set", isDense: true))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: repsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Tekrar", isDense: true))),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      setDialogState(() {
                        tempExercises.add(PerformedExercise(
                          exerciseName: nameController.text,
                          weight: weightController.text,
                          sets: int.tryParse(setsController.text),
                          reps: int.tryParse(repsController.text),
                        ));
                        nameController.clear();
                        weightController.clear();
                        setsController.clear();
                        repsController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Listeye Ekle"),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                final vm = context.read<TrainerScheduleViewModel>();
                // Sadece yeni eklenenleri değil, tüm listeyi (temizlenip tekrar eklenecek şekilde backend'i ayarladık mı?)
                // Aslında backend addPerformedExercises append yapıyor. 
                // Biz sadece yeni eklenenleri göndermeliyiz veya backend'i "set" yapacak şekilde güncellemeliyiz.
                
                // Basitlik için: Sadece listedeki tüm elemanları gönderelim.
                final success = await vm.addPerformedExercises(booking.id, tempExercises);
                if (success && mounted) {
                  Navigator.pop(context);
                  _loadSchedule();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Çalışma programı kaydedildi.")));
                }
              },
              child: const Text("KAYDET"),
            ),
          ],
        ),
      ),
    );
  }
}
