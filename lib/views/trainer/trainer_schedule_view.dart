import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/trainer_schedule_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../models/booking_details_model.dart';
import '../../constants/exercise_library.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_back_button.dart';

class TrainerScheduleView extends StatefulWidget {
  final int? trainerId;
  const TrainerScheduleView({super.key, this.trainerId});

  @override
  State<TrainerScheduleView> createState() => _TrainerScheduleViewState();
}

class _TrainerScheduleViewState extends State<TrainerScheduleView> {
  DateTime _currentDate = DateTime.now();
  String _viewType = 'Günlük';

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
        title: const Text("Ders Programı", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: const CustomBackButton(),
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

        final bool isNoShow = booking.status == 'ACTIVE' && isPast;
        final bool isCompleted = booking.status == 'COMPLETED';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: isNoShow ? Colors.red.shade50 : Colors.white,
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
                Text("Durum: ${isNoShow ? 'Üye Derse Katılmadı' : (isCompleted ? 'Tamamlandı' : booking.statusText)}",
                     style: TextStyle(color: isNoShow ? Colors.red.shade800 : Colors.black87)),
                if (booking.performedExercises.isNotEmpty)
                  Text("${booking.performedExercises.length} çalışma girildi",
                      style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCompleted && !isNoShow && booking.status != 'CANCELLED')
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                    onPressed: () => _handleCancelBooking(context, booking),
                  ),
                Icon(
                  isCompleted ? Icons.check_circle : (isNoShow ? Icons.cancel_rounded : Icons.timer),
                  color: isCompleted ? Colors.green : (isNoShow ? Colors.red : Colors.orange),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleCancelBooking(BuildContext context, BookingDetails booking) async {
    final loginVM = context.read<LoginViewModel>();
    final isSuperAdmin = loginVM.userData?['role'] == 'SUPER_ADMIN';
    final isAdmin = loginVM.userData?['role'] == 'ADMIN' || isSuperAdmin;

    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yalnızca yöneticiler geçmiş olmayan dersleri buradan iptal edebilir.")),
      );
      return;
    }

    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Dersi İptal Et"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Bu dersi iptal etmek istediğinize emin misiniz? Lütfen iptal nedenini girin."),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "Örn: Üye mazeret bildirdi.",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen iptal nedeni girin.")));
                return;
              }
              Navigator.pop(ctx);
              final vm = context.read<TrainerScheduleViewModel>();
              final success = await vm.rejectBooking(booking.id, loginVM.userData!['userId'], reason: reasonController.text.trim(), isDirectCancel: true);
              if (success && mounted) {
                _loadSchedule();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ders başarıyla iptal edildi.")));
              }
            },
            child: const Text("İptal Et"),
          ),
        ],
      ),
    );
  }

  void _showExerciseSandwichMenu(
    BuildContext context,
    Function(String movement, String muscleGroup) onSelect
  ) {
    final searchController = TextEditingController();
    String searchQuery = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final searchResults = ExerciseLibrary.searchExercises(searchQuery);

          return Container(
            height: MediaQuery.of(sheetContext).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, color: Colors.indigo, size: 26),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Egzersiz Kütüphanesi Menüsü",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: searchController,
                  autofocus: searchQuery.isNotEmpty,
                  decoration: InputDecoration(
                    labelText: "Hareket veya Kas Grubu Ara",
                    hintText: "Örn: Bench Press, Biceps...",
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.indigo),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              setSheetState(() {
                                searchController.clear();
                                searchQuery = "";
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onChanged: (val) {
                    setSheetState(() => searchQuery = val);
                  },
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: searchQuery.trim().isNotEmpty
                      ? ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, idx) {
                            final item = searchResults[idx];
                            return ListTile(
                              leading: const Icon(Icons.fitness_center_rounded, color: Colors.indigo),
                              title: Text(item['movement']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Kas Grubu: ${item['category']!}"),
                              onTap: () {
                                onSelect(item['movement']!, item['category']!);
                                Navigator.pop(sheetContext);
                              },
                            );
                          },
                        )
                      : ListView.builder(
                          itemCount: ExerciseLibrary.library.keys.length,
                          itemBuilder: (context, idx) {
                            final category = ExerciseLibrary.library.keys.elementAt(idx);
                            final movements = ExerciseLibrary.library[category]!;

                            return ExpansionTile(
                              leading: const Icon(Icons.category_rounded, color: Colors.indigo),
                              title: Text(
                                category,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Text("${movements.length} Egzersiz"),
                              children: movements.map<Widget>((move) => ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                                leading: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.blue),
                                title: Text(move, style: const TextStyle(fontWeight: FontWeight.w600)),
                                onTap: () {
                                  onSelect(move, category);
                                  Navigator.pop(sheetContext);
                                },
                              )).toList(),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showExerciseLogDialog(BuildContext context, BookingDetails booking) {
    final List<PerformedExercise> tempExercises = List.from(booking.performedExercises);
    final nameController = TextEditingController();
    final muscleGroupController = TextEditingController();
    final weightController = TextEditingController();
    final setsController = TextEditingController();
    final repsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("${booking.memberName} - Antrenman Çalışma Girişi"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tempExercises.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade300)),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Eğitmenin antrenman sonrası çalışma bilgilerini doldurması zorunludur!",
                              style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: tempExercises.length,
                        itemBuilder: (context, idx) {
                          final ex = tempExercises[idx];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            child: ListTile(
                              dense: true,
                              title: Text(ex.exerciseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("${ex.muscleGroup != null ? '${ex.muscleGroup} • ' : ''}${ex.sets ?? '-'} Set x ${ex.reps ?? '-'} Tekrar | ${ex.weight ?? '-'}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () => setDialogState(() => tempExercises.removeAt(idx)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Text("Yeni Çalışma Ekle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),

                  InkWell(
                    onTap: () {
                      _showExerciseSandwichMenu(context, (movement, muscleGroup) {
                        setDialogState(() {
                          nameController.text = movement;
                          muscleGroupController.text = muscleGroup;
                        });
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: IgnorePointer(
                      child: TextField(
                        controller: muscleGroupController,
                        decoration: const InputDecoration(
                          labelText: "Çalıştırılan Kas Grubu (Kütüphaneden Seç)",
                          hintText: "Örn: Göğüs Egzersizleri",
                          prefixIcon: Icon(Icons.accessibility_new_rounded, color: Colors.indigo),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Hareket Adı",
                      hintText: "Örn: Bench Press",
                      prefixIcon: Icon(Icons.fitness_center_rounded, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final found = ExerciseLibrary.findMuscleGroup(val);
                      if (found.isNotEmpty) {
                        setDialogState(() {
                          muscleGroupController.text = found;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: repsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Tekrar",
                            hintText: "12",
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: setsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Set",
                            hintText: "4",
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: weightController,
                          decoration: const InputDecoration(
                            labelText: "Ağırlık",
                            hintText: "29 KG",
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          setDialogState(() {
                            final mg = muscleGroupController.text.trim().isNotEmpty
                                ? muscleGroupController.text.trim()
                                : ExerciseLibrary.findMuscleGroup(nameController.text.trim());

                            tempExercises.add(PerformedExercise(
                              exerciseName: nameController.text.trim(),
                              muscleGroup: mg,
                              weight: weightController.text.trim(),
                              sets: int.tryParse(setsController.text.trim()),
                              reps: int.tryParse(repsController.text.trim()),
                            ));
                            nameController.clear();
                            muscleGroupController.clear();
                            weightController.clear();
                            setsController.clear();
                            repsController.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text("Çalışmayı Listeye Ekle"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () async {
                if (tempExercises.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text("Eğitmenin antrenman sonrası çalışma bilgilerini doldurması zorunludur! Lütfen en az bir çalışma ekleyin."),
                    ),
                  );
                  return;
                }

                final vm = context.read<TrainerScheduleViewModel>();
                final success = await vm.addPerformedExercises(booking.id, tempExercises);
                if (success && mounted) {
                  Navigator.pop(context);
                  _loadSchedule();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Antrenman çalışma programı başarıyla kaydedildi.")),
                  );
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
