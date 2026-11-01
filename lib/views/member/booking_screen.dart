import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../view_models/calendar_view_model.dart';
import '../../view_models/login_view_model.dart';
import '../../view_models/user_view_model.dart';
import '../../models/user_model.dart';
import '../widgets/custom_back_button.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int? _selectedTrainerId;
  String? _selectedTrainerName;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userData = context.read<LoginViewModel>().userData;
      final userVM = context.read<UserViewModel>();

      if (userData != null) {
        setState(() {
          _selectedTrainerId = userData['assignedTrainer']?['id'];
          _selectedTrainerName = userData['assignedTrainer']?['fullName'];

          if (_selectedTrainerName == null) {
            _selectedTrainerName = "Eğitmen Atanmamış";
          }
        });

        userVM.fetchUsers(userData['gymId']);

        if (_selectedTrainerId != null) {
          _fetchSlots();
        }
      }
    });
  }

  void _fetchSlots() {
    if (_selectedTrainerId != null) {
      final gymId = context.read<LoginViewModel>().userData?['gymId'];
      context.read<CalendarViewModel>().fetchAvailableSlots(
        _selectedTrainerId!,
        gymId ?? 1,
        _selectedDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendarVM = context.watch<CalendarViewModel>();
    final userVM = context.watch<UserViewModel>();

    final trainers = userVM.users.where((u) {
      final isTrainer = u.isTrainerOrCanTeach;
      final isActive = u.isActive;

      bool isOnLeaveAtSelectedDate = false;
      if (u.leaveStart != null && u.leaveEnd != null) {
        final start = DateTime(u.leaveStart!.year, u.leaveStart!.month, u.leaveStart!.day);
        final end = DateTime(u.leaveEnd!.year, u.leaveEnd!.month, u.leaveEnd!.day, 23, 59);
        isOnLeaveAtSelectedDate = _selectedDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
                                 _selectedDate.isBefore(end.add(const Duration(seconds: 1)));
      }

      return isTrainer && isActive && !isOnLeaveAtSelectedDate;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Randevu Al", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: const CustomBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Eğitmeniniz", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                      Text(_selectedTrainerName ?? "Yükleniyor...",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                const Text("Tarih Seçin", style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(DateFormat('dd MMMM yyyy', 'tr').format(_selectedDate)),
                  onPressed: () async {
                    DateTime initial = _selectedDate;

                    bool isDateSelectable(DateTime val) {
                      if (val.weekday == DateTime.sunday) return false;
                      if (_selectedTrainerId != null) {
                        try {
                          final trainer = userVM.users.firstWhere((u) => int.parse(u.id) == _selectedTrainerId);
                          if (trainer.leaveStart != null && trainer.leaveEnd != null) {
                            final dayStart = DateTime(val.year, val.month, val.day);
                            final leaveStartDay = DateTime(trainer.leaveStart!.year, trainer.leaveStart!.month, trainer.leaveStart!.day);
                            final leaveEndDay = DateTime(trainer.leaveEnd!.year, trainer.leaveEnd!.month, trainer.leaveEnd!.day);
                            return dayStart.isBefore(leaveStartDay) || dayStart.isAfter(leaveEndDay);
                          }
                        } catch (e) {}
                      }
                      return true;
                    }

                    while (!isDateSelectable(initial)) {
                      initial = initial.add(const Duration(days: 1));
                    }

                    final date = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                      selectableDayPredicate: isDateSelectable,
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                      _fetchSlots();
                    }
                  },
                ),
              ],
            ),

            const Divider(),

            const Text("Müsait Saatler", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (calendarVM.isSlotsLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_selectedTrainerId == null)
              const Center(child: Text("Eğitmen bilgisi alınamadı"))
            else if (calendarVM.availableSlots.isEmpty)
              const Center(child: Text("Seçilen tarihte müsait ders bulunamadı."))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: calendarVM.availableSlots.length,
                itemBuilder: (context, index) {
                  final slot = calendarVM.availableSlots[index];
                  return InkWell(
                    onTap: slot.isAvailable ? () => _showConfirmDialog(slot.startTime) : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: slot.isAvailable ? Colors.blue.shade50 : Colors.grey.shade200,
                        border: Border.all(color: slot.isAvailable ? Colors.blue : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat('HH:mm').format(slot.startTime),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: slot.isAvailable ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 30),
            const Divider(),

            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.orange),
                title: const Text("Farklı bir eğitmen seçmek istiyorum",
                    style: TextStyle(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.w500)),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: DropdownButtonFormField<int>(
                      value: trainers.any((t) => int.parse(t.id) == _selectedTrainerId)
                          ? _selectedTrainerId
                          : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Eğitmen Değiştir",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: trainers.map((t) => DropdownMenuItem<int>(
                        value: int.parse(t.id),
                        child: Text(t.fullName)
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedTrainerId = val;
                          _selectedTrainerName = trainers.firstWhere((t) => t.id == val.toString()).fullName;
                        });
                        _fetchSlots();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(DateTime time) {
    final calendarVM = context.read<CalendarViewModel>();
    final loginVM = context.read<LoginViewModel>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Randevu Onayı"),
        content: Text("${_selectedTrainerName} ile ${DateFormat('dd MMMM HH:mm', 'tr').format(time)} randevusunu onaylıyor musunuz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              try {
                final success = await calendarVM.createAppointment(
                  memberId: loginVM.userData?['userId'],
                  trainerId: _selectedTrainerId!,
                  gymId: loginVM.userData?['gymId'],
                  startTime: time,
                );
                if (success && mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  calendarVM.fetchMemberHistory(loginVM.userData?['userId']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Randevunuz başarıyla oluşturuldu.")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
              }
            },
            child: const Text("Onayla"),
          ),
        ],
      ),
    );
  }
}
